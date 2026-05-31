import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/relay_device.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<RelayDevice>> scan({Duration timeout = const Duration(seconds: 5)}) {
    final controller = StreamController<List<RelayDevice>>();

    FlutterBluePlus.startScan(timeout: timeout);

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => RelayDevice(
                id: r.device.remoteId.str,
                name: r.device.platformName,
                rssi: r.rssi,
              ))
          .toList();
      controller.add(devices);
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        controller.close();
      }
    });

    return controller.stream;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void dispose() {
    stopScan();
  }
}
