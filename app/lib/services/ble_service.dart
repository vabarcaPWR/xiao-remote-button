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
  StreamSubscription<List<int>>? _timerNotifySub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _cmdCharacteristic;
  BluetoothCharacteristic? _stateCharacteristic;
  BluetoothCharacteristic? _timerDurationCharacteristic;
  BluetoothCharacteristic? _timerRemainingCharacteristic;
  BluetoothCharacteristic? _uptimeCharacteristic;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _currentStatus;

  final _relayStateController = StreamController<RelayState>.broadcast();
  Stream<RelayState> get relayStateStream => _relayStateController.stream;

  final _timerRemainingController = StreamController<int>.broadcast();
  Stream<int> get timerRemainingStream => _timerRemainingController.stream;

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
        } else if (c.uuid == BleConstants.timerDurationUuid) {
          _timerDurationCharacteristic = c;
        } else if (c.uuid == BleConstants.timerRemainingUuid) {
          _timerRemainingCharacteristic = c;
        } else if (c.uuid == BleConstants.uptimeUuid) {
          _uptimeCharacteristic = c;
        }
      }

      await _subscribeToStateNotifications();
      await _subscribeToTimerNotifications();

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

  Future<void> _subscribeToTimerNotifications() async {
    if (_timerRemainingCharacteristic == null) return;
    try {
      await _timerRemainingCharacteristic!.setNotifyValue(true);
      _timerNotifySub =
          _timerRemainingCharacteristic!.onValueReceived.listen((value) {
        if (value.length >= 2) {
          final remaining = value[0] | (value[1] << 8);
          _timerRemainingController.add(remaining);
        }
      });
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _connectionSub?.cancel();
    _connectionSub = null;
    _stateNotifySub?.cancel();
    _stateNotifySub = null;
    _timerNotifySub?.cancel();
    _timerNotifySub = null;
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _timerDurationCharacteristic = null;
    _timerRemainingCharacteristic = null;
    _uptimeCharacteristic = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void _onDisconnected() {
    _stateNotifySub?.cancel();
    _stateNotifySub = null;
    _timerNotifySub?.cancel();
    _timerNotifySub = null;
    _connectedDevice = null;
    _cmdCharacteristic = null;
    _stateCharacteristic = null;
    _timerDurationCharacteristic = null;
    _timerRemainingCharacteristic = null;
    _uptimeCharacteristic = null;
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

  Future<bool> writeTimerDuration(int seconds) async {
    if (_timerDurationCharacteristic == null) return false;
    try {
      final low = seconds & 0xFF;
      final high = (seconds >> 8) & 0xFF;
      await _timerDurationCharacteristic!.write([low, high],
          withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> readTimerRemaining() async {
    if (_timerRemainingCharacteristic == null) return 0;
    try {
      final value = await _timerRemainingCharacteristic!.read();
      if (value.length >= 2) return value[0] | (value[1] << 8);
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> readUptime() async {
    if (_uptimeCharacteristic == null) return 0;
    try {
      final value = await _uptimeCharacteristic!.read();
      if (value.length >= 4) {
        return value[0] | (value[1] << 8) | (value[2] << 16) | (value[3] << 24);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void dispose() {
    stopScan();
    _connectionSub?.cancel();
    _stateNotifySub?.cancel();
    _timerNotifySub?.cancel();
    _statusController.close();
    _relayStateController.close();
    _timerRemainingController.close();
  }
}
