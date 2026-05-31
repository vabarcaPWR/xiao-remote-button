import 'package:flutter/material.dart';
import '../../models/relay_device.dart';
import '../../services/ble_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final BleService _bleService = BleService();
  List<RelayDevice> _devices = [];
  bool _scanning = false;

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _devices = [];
      _scanning = true;
    });

    _bleService.scan().listen(
      (devices) => setState(() => _devices = devices),
      onDone: () => setState(() => _scanning = false),
      onError: (_) => setState(() => _scanning = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XIAO Relay — Scanner')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanning ? null : _startScan,
        child: Icon(_scanning ? Icons.bluetooth_searching : Icons.search),
      ),
    );
  }

  Widget _buildBody() {
    if (_scanning && _devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_scanning && _devices.isEmpty) {
      return const Center(
        child: Text('Tap scan to find devices', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name),
          subtitle: Text(device.id),
          trailing: Text('${device.rssi} dBm'),
          onTap: () {
            // TODO: Sprint 3 — connect to device
          },
        );
      },
    );
  }
}
