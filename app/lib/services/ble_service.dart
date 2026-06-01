import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/relay_device.dart';
import 'ble_constants.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _cmdCharacteristic;
  BluetoothCharacteristic? _stateCharacteristic;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _currentStatus;

  Stream<List<RelayDevice>> scan({Duration timeout = const Duration(seconds: 5)}) {
    final controller = StreamController<List<RelayDevice>>();

    FlutterBluePlus.startScan(
      withServices: [BleConstants.relayServiceUuid],
      timeout: timeout,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (controller.isClosed) return;
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
      if (!scanning && !controller.isClosed) {
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

  Future<void> connect(String deviceId) async {
    _setStatus(ConnectionStatus.connecting);

    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10), license: License.nonprofit);

      _connectedDevice = device;

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      final services = await device.discoverServices();
      final relayService = services.firstWhere(
        (s) => s.uuid == BleConstants.relayServiceUuid,
        orElse: () => throw Exception('Relay service not found'),
      );

      for (final c in relayService.characteristics) {
        if (c.uuid == BleConstants.relayCommandUuid) {
          _cmdCharacteristic = c;
        } else if (c.uuid == BleConstants.relayStateUuid) {
          _stateCharacteristic = c;
        }
      }

      _setStatus(ConnectionStatus.connected);
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _connectedDevice = null;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _onDisconnected() {
    _connectedDevice = null;
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _setStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    stopScan();
    _statusController.close();
  }
}
