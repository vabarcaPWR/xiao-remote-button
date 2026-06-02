import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/relay_device.dart';
import '../../services/ble_service.dart';
import '../control/control_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const _lastDeviceKey = 'last_device_id';
  static const _lastDeviceNameKey = 'last_device_name';

  final BleService _bleService = BleService();
  List<RelayDevice> _devices = [];
  bool _scanning = false;
  bool _autoConnecting = false;
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
    _tryAutoConnect();
  }

  @override
  void dispose() {
    _adapterSubscription?.cancel();
    _bleService.stopScan();
    super.dispose();
  }

  Future<void> _tryAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_lastDeviceKey);
    if (savedId == null) return;

    setState(() => _autoConnecting = true);

    _bleService.connect(savedId);
    _navigateToControl();
  }

  Future<void> _saveDevice(RelayDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, device.id);
    await prefs.setString(_lastDeviceNameKey, device.name);
  }

  Future<void> _forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastDeviceKey);
    await prefs.remove(_lastDeviceNameKey);
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

  void _connectToDevice(RelayDevice device) {
    _bleService.stopScan();
    _saveDevice(device);
    _bleService.connect(device.id);
    _navigateToControl();
  }

  void _navigateToControl() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ControlScreen()),
    ).then((_) {
      setState(() => _autoConnecting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XIAO Relay — Scanner'),
        actions: [
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.getString(_lastDeviceKey) != null) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Forget saved device',
                  onPressed: () async {
                    await _forgetDevice();
                    setState(() {});
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _autoConnecting ? _buildAutoConnecting() : _buildBody(),
      floatingActionButton: _autoConnecting
          ? null
          : FloatingActionButton(
              onPressed: _scanning ? null : _startScan,
              child: Icon(_scanning ? Icons.bluetooth_searching : Icons.search),
            ),
    );
  }

  Widget _buildAutoConnecting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to saved device...'),
        ],
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
          onTap: () => _connectToDevice(device),
        );
      },
    );
  }
}
