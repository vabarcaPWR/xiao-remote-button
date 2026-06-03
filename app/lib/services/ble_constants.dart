import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConstants {
  BleConstants._();

  /// Custom Relay Service UUID: 00001523-1212-efde-1523-785feabcd123
  static final Guid relayServiceUuid =
      Guid('00001523-1212-efde-1523-785feabcd123');

  /// Relay Command characteristic (Write)
  static final Guid relayCommandUuid =
      Guid('00001524-1212-efde-1523-785feabcd123');

  /// Relay State characteristic (Read + Notify)
  static final Guid relayStateUuid =
      Guid('00001525-1212-efde-1523-785feabcd123');

  /// Timer Duration characteristic (Write, uint16 LE, seconds)
  static final Guid timerDurationUuid =
      Guid('00001526-1212-efde-1523-785feabcd123');

  /// Timer Remaining characteristic (Read + Notify, uint16 LE, seconds)
  static final Guid timerRemainingUuid =
      Guid('00001527-1212-efde-1523-785feabcd123');

  /// Device Uptime characteristic (Read, uint32 LE, seconds)
  static final Guid uptimeUuid =
      Guid('00001528-1212-efde-1523-785feabcd123');

  /// Device advertised name
  static const String deviceName = 'FIP-relay';
}
