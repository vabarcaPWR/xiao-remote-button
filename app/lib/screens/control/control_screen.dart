import 'dart:async';
import 'package:flutter/material.dart';
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
    }
    _stateBeforeDisconnect = null;
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
        title: const Text('XIAO Relay'),
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
              const Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Disconnected', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'Device running autonomously',
                style: TextStyle(color: Colors.grey),
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
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(fontSize: 16),
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
    final buttonColor = isOn ? Colors.green : Colors.grey.shade600;
    final buttonSize = MediaQuery.of(context).size.width * 0.45;
    final clampedSize = buttonSize.clamp(120.0, 200.0);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBanner(isOn),
            const SizedBox(height: 24),
            SizedBox(
              width: clampedSize,
              height: clampedSize,
              child: ElevatedButton(
                onPressed: isToggling ? null : _toggleRelay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  elevation: 8,
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
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isOn ? Colors.green : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTimerSection(isOn),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection(bool isOn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer, size: 20),
              const SizedBox(width: 8),
              const Text('Timer', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (isOn && _timerRemaining > 0)
                Text(
                  _formatTime(_timerRemaining),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedTimerMinutes,
            decoration: const InputDecoration(
              labelText: 'Auto-off timer',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
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
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: _selectedTimerMinutes > 0
                    ? _timerRemaining / (_selectedTimerMinutes * 60)
                    : _timerRemaining / 600,
                backgroundColor: Colors.grey.shade300,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusBanner(bool isOn) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth_connected, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
