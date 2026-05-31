import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  String? _error;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  @override
  void initState() {
    super.initState();
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        setState(() => _error = 'Bluetooth is turned off. Please enable it.');
      } else if (state == BluetoothAdapterState.on && _error != null) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _adapterSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _devices = [];
      _scanning = true;
      _error = null;
    });

    try {
      _bleService.scan().listen(
        (devices) => setState(() => _devices = devices),
        onDone: () => setState(() => _scanning = false),
        onError: (e) => setState(() {
          _scanning = false;
          _error = 'Scan failed: $e';
        }),
      );
    } catch (e) {
      setState(() {
        _scanning = false;
        _error = 'Cannot start scan: $e';
      });
    }
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
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startScan,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_scanning && _devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for xiao-relay...'),
          ],
        ),
      );
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
