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

enum _ScreenState { loading, ready, toggling, reconnecting, disconnected, error }

class _ControlScreenState extends State<ControlScreen> {
  late final BleService _bleService;
  late StreamSubscription<ConnectionStatus> _statusSub;
  StreamSubscription<RelayState>? _relayStateSub;
  _ScreenState _screenState = _ScreenState.loading;
  RelayState _relayState = RelayState.unknown;
  RelayState? _stateBeforeReconnect;
  String? _errorMessage;
  Timer? _navigateBackTimer;

  static const Duration _navigateBackDelay = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _bleService = widget.bleService ?? BleService();

    _statusSub = _bleService.statusStream.listen(_onConnectionStatusChanged);
    _relayStateSub = _bleService.relayStateStream.listen(_onRelayStateNotified);

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
      _screenState = _ScreenState.ready;
    });
  }

  void _onConnectionStatusChanged(ConnectionStatus status) {
    if (!mounted) return;
    switch (status) {
      case ConnectionStatus.connected:
        if (_screenState == _ScreenState.reconnecting ||
            _screenState == _ScreenState.loading) {
          _readStateAfterReconnect();
        }
        break;
      case ConnectionStatus.reconnecting:
        _stateBeforeReconnect = _relayState;
        setState(() => _screenState = _ScreenState.reconnecting);
        break;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        setState(() => _screenState = _ScreenState.disconnected);
        _navigateBackTimer?.cancel();
        _navigateBackTimer = Timer(_navigateBackDelay, () {
          if (mounted) Navigator.of(context).pop();
        });
        break;
      case ConnectionStatus.connecting:
        break;
    }
  }

  Future<void> _readInitialState() async {
    final state = await _bleService.readRelayState();
    if (!mounted) return;
    setState(() {
      _relayState = state;
      _screenState = _ScreenState.ready;
    });
  }

  Future<void> _readStateAfterReconnect() async {
    final state = await _bleService.readRelayState();
    if (!mounted) return;
    final previous = _stateBeforeReconnect;
    _stateBeforeReconnect = null;
    setState(() {
      _relayState = state;
      _screenState = _ScreenState.ready;
    });
    if (previous == RelayState.on && state == RelayState.off) {
      _showFailSafeNotice();
    }
  }

  void _showFailSafeNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Relay was turned OFF by fail-safe'),
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

    // Wait briefly for a notification to arrive and update state.
    // If no notification arrives (e.g. notify not supported), fall back to read.
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
    _navigateBackTimer?.cancel();
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
      case _ScreenState.reconnecting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Icon(Icons.bluetooth_searching, size: 64, color: Colors.orange),
              SizedBox(height: 8),
              Text('Reconnecting...', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      case _ScreenState.disconnected:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Disconnected', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(
                'Returning to scanner...',
                style: TextStyle(color: Colors.grey),
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBanner(isOn),
          const SizedBox(height: 40),
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
          const SizedBox(height: 24),
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
        ],
      ),
    );
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
