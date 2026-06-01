import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ble_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final BleService _bleService = BleService();
  late StreamSubscription<ConnectionStatus> _statusSub;
  ConnectionStatus _status = ConnectionStatus.connecting;

  @override
  void initState() {
    super.initState();
    _status = _bleService.currentStatus;
    _statusSub = _bleService.statusStream.listen((status) {
      setState(() => _status = status);
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XIAO Relay — Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () => _bleService.disconnect(),
            tooltip: 'Disconnect',
          ),
        ],
      ),
      body: Center(child: _buildStatusWidget()),
    );
  }

  Widget _buildStatusWidget() {
    switch (_status) {
      case ConnectionStatus.connecting:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting...', style: TextStyle(fontSize: 18)),
          ],
        );
      case ConnectionStatus.connected:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('Connected', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Relay control ready (Sprint 4)', style: TextStyle(color: Colors.grey)),
          ],
        );
      case ConnectionStatus.disconnected:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Disconnected', style: TextStyle(fontSize: 18)),
          ],
        );
      case ConnectionStatus.error:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text('Connection failed', style: TextStyle(fontSize: 18)),
          ],
        );
    }
  }
}
