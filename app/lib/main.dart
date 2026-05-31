import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const XiaoRelayApp());
}

class XiaoRelayApp extends StatelessWidget {
  const XiaoRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XIAO Relay',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<ScanResult> _results = [];
  bool _scanning = false;

  void _startScan() {
    setState(() {
      _results = [];
      _scanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() => _results = results);
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() => _scanning = scanning);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XIAO Relay — Scanner')),
      body: _results.isEmpty
          ? Center(
              child: _scanning
                  ? const CircularProgressIndicator()
                  : const Text('Tap scan to find devices'),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return ListTile(
                  title: Text(
                    result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Unknown',
                  ),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: Text('${result.rssi} dBm'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanning ? null : _startScan,
        child: Icon(_scanning ? Icons.bluetooth_searching : Icons.search),
      ),
    );
  }
}
