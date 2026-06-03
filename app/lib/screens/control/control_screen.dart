import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../models/relay_state.dart';
import '../../services/ble_service.dart';

class ControlScreen extends StatefulWidget {
  final BleService? bleService;

  const ControlScreen({super.key, this.bleService});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

enum _ScreenState { loading, ready, toggling, disconnected, error }

class _ControlScreenState extends State<ControlScreen> {
  late final BleService _bleService;
  late StreamSubscription<ConnectionStatus> _statusSub;
  StreamSubscription<RelayState>? _relayStateSub;
  StreamSubscription<int>? _timerSub;
  _ScreenState _screenState = _ScreenState.loading;
  RelayState _relayState = RelayState.unknown;
  RelayState? _stateBeforeDisconnect;
  String? _errorMessage;
  int _timerRemaining = 0;
  int _selectedTimerMinutes = 0;
  int? _timerRemainingAtDisconnect;
  DateTime? _disconnectedAt;

  static const List<int> timerOptions = [0, 1, 5, 10, 30, 60, 120, 360];

  @override
  void initState() {
    super.initState();
    _bleService = widget.bleService ?? BleService();

    _statusSub = _bleService.statusStream.listen(_onConnectionStatusChanged);
    _relayStateSub = _bleService.relayStateStream.listen(_onRelayStateNotified);
    _timerSub = _bleService.timerRemainingStream.listen(_onTimerRemaining);

    if (_bleService.currentStatus == ConnectionStatus.connected) {
      _readInitialState();
    } else if (_bleService.currentStatus == ConnectionStatus.disconnected ||
        _bleService.currentStatus == ConnectionStatus.error) {
      _screenState = _ScreenState.disconnected;
    }
  }

  void _onRelayStateNotified(RelayState state) {
    if (!mounted) return;
    setState(() {
      _relayState = state;
      if (state == RelayState.off) _timerRemaining = 0;
      _screenState = _ScreenState.ready;
    });
  }

  void _onTimerRemaining(int remaining) {
    if (!mounted) return;
    setState(() => _timerRemaining = remaining);
    if (remaining == 0 && _relayState == RelayState.on) {
      _showTimerExpiredNotice();
    }
  }

  void _showTimerExpiredNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timer expired — relay turned OFF'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onConnectionStatusChanged(ConnectionStatus status) {
    if (!mounted) return;
    switch (status) {
      case ConnectionStatus.connected:
        if (_screenState == _ScreenState.loading) {
          _readInitialState();
        } else if (_screenState == _ScreenState.disconnected) {
          _readStateAfterReconnect();
        }
        break;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        _stateBeforeDisconnect = _relayState;
        _timerRemainingAtDisconnect = _timerRemaining;
        _disconnectedAt = DateTime.now();
        setState(() => _screenState = _ScreenState.disconnected);
        break;
      case ConnectionStatus.connecting:
        break;
    }
  }

  Future<void> _readInitialState() async {
    final state = await _bleService.readRelayState();
    if (!mounted) return;
    final remaining = await _bleService.readTimerRemaining();
    if (!mounted) return;
    setState(() {
      _relayState = state;
      _timerRemaining = remaining;
      _screenState = _ScreenState.ready;
    });
  }

  Future<void> _readStateAfterReconnect() async {
    final state = await _bleService.readRelayState();
    if (!mounted) return;
    final remaining = await _bleService.readTimerRemaining();
    if (!mounted) return;
    final uptime = await _bleService.readUptime();
    if (!mounted) return;
    setState(() {
      _relayState = state;
      _timerRemaining = remaining;
      _screenState = _ScreenState.ready;
    });
    if (uptime < 30 && state == RelayState.off) {
      _showDeviceRestartedNotice();
    } else if (_stateBeforeDisconnect == RelayState.on && state == RelayState.off) {
      _showTimerExpiredDuringDisconnect();
    } else {
      _checkTimerDrift(remaining);
    }
    _stateBeforeDisconnect = null;
    _timerRemainingAtDisconnect = null;
    _disconnectedAt = null;
  }

  void _checkTimerDrift(int currentRemaining) {
    if (_timerRemainingAtDisconnect == null || _disconnectedAt == null) return;
    if (_timerRemainingAtDisconnect == 0) return;

    final elapsed = DateTime.now().difference(_disconnectedAt!).inSeconds;
    final expectedRemaining = _timerRemainingAtDisconnect! - elapsed;
    if (expectedRemaining <= 0) return;

    final drift = (currentRemaining - expectedRemaining).abs();
    if (drift > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer drift detected: ${drift}s off expected'),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDeviceRestartedNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device restarted — relay OFF (safety)'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showTimerExpiredDuringDisconnect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Relay was turned OFF by timer while disconnected'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _toggleRelay() async {
    if (_screenState != _ScreenState.ready) return;

    Vibration.vibrate(duration: 50, amplitude: 128);
    final targetOn = _relayState != RelayState.on;

    setState(() => _screenState = _ScreenState.toggling);

    final success = await _bleService.writeRelay(targetOn);
    if (!mounted) return;

    if (!success) {
      setState(() {
        _screenState = _ScreenState.ready;
        _errorMessage = 'Failed to send relay command';
      });
      _showError(_errorMessage!);
      return;
    }

    if (targetOn && _selectedTimerMinutes > 0) {
      await _bleService.writeTimerDuration(_selectedTimerMinutes * 60);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (_screenState == _ScreenState.toggling) {
      final newState = await _bleService.readRelayState();
      if (!mounted) return;
      setState(() {
        _relayState = newState;
        _screenState = _ScreenState.ready;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    _relayStateSub?.cancel();
    _statusSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIP Relay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () => _bleService.disconnect(),
            tooltip: 'Disconnect',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    switch (_screenState) {
      case _ScreenState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Reading relay state...', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      case _ScreenState.disconnected:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_disabled, size: 80,
                  color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Disconnected',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Device running autonomously',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.search),
                label: const Text('Back to scanner'),
              ),
            ],
          ),
        );
      case _ScreenState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 80, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Unknown error',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
              ),
            ],
          ),
        );
      case _ScreenState.ready:
      case _ScreenState.toggling:
        return _buildRelayControl();
    }
  }

  Widget _buildRelayControl() {
    final isOn = _relayState == RelayState.on;
    final isToggling = _screenState == _ScreenState.toggling;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isOn
        ? const Color(0xFF4CAF50)
        : colorScheme.onSurfaceVariant;
    final buttonSize = MediaQuery.of(context).size.width * 0.45;
    final clampedSize = buttonSize.clamp(120.0, 200.0);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBanner(isOn),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: clampedSize + 16,
                height: clampedSize + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isOn ? 0.4 : 0.1),
                      blurRadius: isOn ? 24 : 8,
                      spreadRadius: isOn ? 4 : 0,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: clampedSize,
                  height: clampedSize,
                  child: ElevatedButton(
                    onPressed: isToggling ? null : _toggleRelay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: isOn ? 12 : 4,
                      shadowColor: accentColor.withValues(alpha: 0.5),
                    ),
                    child: isToggling
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            Icons.power_settings_new,
                            size: clampedSize * 0.4,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: isOn
                          ? [BoxShadow(
                              color: accentColor.withValues(alpha: 0.6),
                              blurRadius: 8,
                            )]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildTimerSection(isOn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection(bool isOn) {
    final colorScheme = Theme.of(context).colorScheme;
    final timerColor = isOn && _timerRemaining > 0
        ? colorScheme.tertiary
        : colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 20, color: timerColor),
                const SizedBox(width: 8),
                Text('Timer',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    )),
                const Spacer(),
                if (isOn && _timerRemaining > 0)
                  Text(
                    _formatTime(_timerRemaining),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedTimerMinutes,
              decoration: InputDecoration(
                labelText: 'Auto-off timer',
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              dropdownColor: colorScheme.surfaceContainer,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              items: timerOptions.map((minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(minutes == 0 ? 'No timer (10 min max)' : '$minutes min'),
                );
              }).toList(),
              onChanged: isOn ? null : (value) {
                if (value != null) setState(() => _selectedTimerMinutes = value);
              },
            ),
            if (isOn && _timerRemaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _selectedTimerMinutes > 0
                        ? _timerRemaining / (_selectedTimerMinutes * 60)
                        : _timerRemaining / 600,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusBanner(bool isOn) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth_connected,
              color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
