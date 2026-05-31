import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConstants {
  BleConstants._();

  /// Custom Relay Service UUID: 00001523-1212-efde-1523-785feabcd123
  static final Guid relayServiceUuid =
      Guid('00001523-1212-efde-1523-785feabcd123');

  /// Device advertised name
  static const String deviceName = 'xiao-relay';
}
