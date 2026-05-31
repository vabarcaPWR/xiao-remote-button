import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/relay_device.dart';
import 'ble_constants.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<RelayDevice>> scan({Duration timeout = const Duration(seconds: 5)}) {
    final controller = StreamController<List<RelayDevice>>();

    FlutterBluePlus.startScan(
      withServices: [BleConstants.relayServiceUuid],
      timeout: timeout,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .map((r) => RelayDevice(
                id: r.device.remoteId.str,
                name: r.device.platformName.isNotEmpty
                    ? r.device.platformName
                    : 'Unknown',
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
