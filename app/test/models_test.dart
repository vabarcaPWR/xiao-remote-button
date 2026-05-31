import 'package:flutter_test/flutter_test.dart';
import 'package:xiao_remote_button/models/relay_state.dart';
import 'package:xiao_remote_button/models/relay_device.dart';

void main() {
  group('RelayState', () {
    test('has expected values', () {
      expect(RelayState.values.length, 3);
      expect(RelayState.on, isNotNull);
      expect(RelayState.off, isNotNull);
      expect(RelayState.unknown, isNotNull);
    });
  });

  group('RelayDevice', () {
    test('creates with required fields', () {
      const device = RelayDevice(id: 'AA:BB:CC:DD:EE:FF', name: 'xiao-relay', rssi: -55);

      expect(device.id, 'AA:BB:CC:DD:EE:FF');
      expect(device.name, 'xiao-relay');
      expect(device.rssi, -55);
    });
  });
}
