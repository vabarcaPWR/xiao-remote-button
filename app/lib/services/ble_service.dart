import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/relay_device.dart';
import '../models/relay_state.dart';
import 'ble_constants.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _stateNotifySub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _cmdCharacteristic;
  BluetoothCharacteristic? _stateCharacteristic;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _currentStatus;

  final _relayStateController = StreamController<RelayState>.broadcast();
  Stream<RelayState> get relayStateStream => _relayStateController.stream;

  Stream<List<RelayDevice>> scan({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final controller = StreamController<List<RelayDevice>>();

    FlutterBluePlus.startScan(timeout: timeout);

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (controller.isClosed) return;
      final devices = results
          .where(
            (r) =>
                r.device.platformName == BleConstants.deviceName ||
                r.advertisementData.serviceUuids.contains(
                  BleConstants.relayServiceUuid,
                ),
          )
          .map(
            (r) => RelayDevice(
              id: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Unknown',
              rssi: r.rssi,
            ),
          )
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
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
        license: License.nonprofit,
      );

      _connectedDevice = device;

      _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((state) {
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

      await _subscribeToStateNotifications();

      _setStatus(ConnectionStatus.connected);
    } catch (e) {
      _connectedDevice = null;
      _setStatus(ConnectionStatus.error);
    }
  }

  Future<void> _subscribeToStateNotifications() async {
    if (_stateCharacteristic == null) return;
    try {
      await _stateCharacteristic!.setNotifyValue(true);
      _stateNotifySub = _stateCharacteristic!.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          final state = value[0] == 0x01 ? RelayState.on : RelayState.off;
          _relayStateController.add(state);
        }
      });
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _connectionSub?.cancel();
    _connectionSub = null;
    _stateNotifySub?.cancel();
    _stateNotifySub = null;
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _onDisconnected() {
    _stateNotifySub?.cancel();
    _stateNotifySub = null;
    _connectedDevice = null;
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _setStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<bool> writeRelay(bool on) async {
    if (_cmdCharacteristic == null) return false;
    try {
      await _cmdCharacteristic!.write([
        on ? 0x01 : 0x00,
      ], withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<RelayState> readRelayState() async {
    if (_stateCharacteristic == null) return RelayState.unknown;
    try {
      final value = await _stateCharacteristic!.read();
      if (value.isNotEmpty && value[0] == 0x01) return RelayState.on;
      return RelayState.off;
    } catch (e) {
      return RelayState.unknown;
    }
  }

  void dispose() {
    stopScan();
    _connectionSub?.cancel();
    _stateNotifySub?.cancel();
    _statusController.close();
    _relayStateController.close();
  }
}
