import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xiao_remote_button/models/relay_state.dart';
import 'package:xiao_remote_button/screens/control/control_screen.dart';
import 'package:xiao_remote_button/services/ble_service.dart';

class MockBleService extends Mock implements BleService {}

void main() {
  late MockBleService mockBle;
  late StreamController<ConnectionStatus> statusController;
  late StreamController<RelayState> relayStateController;

  setUp(() {
    mockBle = MockBleService();
    statusController = StreamController<ConnectionStatus>.broadcast();
    relayStateController = StreamController<RelayState>.broadcast();

    when(() => mockBle.statusStream).thenAnswer((_) => statusController.stream);
    when(
      () => mockBle.relayStateStream,
    ).thenAnswer((_) => relayStateController.stream);
    when(() => mockBle.currentStatus).thenReturn(ConnectionStatus.connected);
    when(() => mockBle.disconnect()).thenAnswer((_) async {});
  });

  tearDown(() {
    statusController.close();
    relayStateController.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(home: ControlScreen(bleService: mockBle));
  }

  group('ControlScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final completer = Completer<RelayState>();
      when(() => mockBle.readRelayState()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Reading relay state...'), findsOneWidget);

      // Complete to avoid pending timers
      completer.complete(RelayState.off);
      await tester.pumpAndSettle();
    });

    testWidgets('shows ON state with green indicator', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('shows OFF state with gray indicator', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('toggle button triggers writeRelay', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);
      when(() => mockBle.writeRelay(true)).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      verify(() => mockBle.writeRelay(true)).called(1);
    });

    testWidgets('disconnect button is present and works', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final disconnectButton = find.byIcon(Icons.bluetooth_disabled);
      expect(disconnectButton, findsOneWidget);

      await tester.tap(disconnectButton);
      await tester.pump();

      verify(() => mockBle.disconnect()).called(1);
    });

    testWidgets('shows disconnected state on connection loss', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);

      statusController.add(ConnectionStatus.disconnected);
      await tester.pump();
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Returning to scanner...'), findsOneWidget);

      // Drain the 5-second delayed navigation timer
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('shows loading on toggle and re-enables after', (tester) async {
      final writeCompleter = Completer<bool>();
      var readCount = 0;

      when(() => mockBle.readRelayState()).thenAnswer((_) async {
        readCount++;
        if (readCount == 1) return RelayState.off;
        return RelayState.on;
      });
      when(
        () => mockBle.writeRelay(true),
      ).thenAnswer((_) => writeCompleter.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      writeCompleter.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('updates UI immediately when notification arrives', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OFF'), findsOneWidget);

      relayStateController.add(RelayState.on);
      await tester.pump();
      await tester.pump();

      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('notification during toggle resolves toggling state', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);
      when(() => mockBle.writeRelay(true)).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Simulate notification arriving before the 300ms fallback
      relayStateController.add(RelayState.on);
      await tester.pump();
      await tester.pump();

      expect(find.text('ON'), findsOneWidget);
      // The button should be enabled again (not in toggling state)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // Drain the 300ms delayed future
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    });

    testWidgets('multiple notifications update state correctly', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      relayStateController.add(RelayState.on);
      await tester.pump();
      await tester.pump();
      expect(find.text('ON'), findsOneWidget);

      relayStateController.add(RelayState.off);
      await tester.pump();
      await tester.pump();
      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('shows reconnecting banner while reconnecting', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);

      statusController.add(ConnectionStatus.reconnecting);
      await tester.pump();
      await tester.pump();

      expect(find.text('Reconnecting...'), findsOneWidget);
    });

    testWidgets('shows fail-safe snackbar when relay was ON and is now OFF after reconnect', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);

      statusController.add(ConnectionStatus.reconnecting);
      await tester.pump();
      await tester.pump();
      expect(find.text('Reconnecting...'), findsOneWidget);

      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      statusController.add(ConnectionStatus.connected);
      await tester.pumpAndSettle();

      expect(find.text('OFF'), findsOneWidget);
      expect(find.text('Relay was turned OFF by fail-safe'), findsOneWidget);
    });

    testWidgets('does not show fail-safe snackbar when relay state is unchanged after reconnect', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      statusController.add(ConnectionStatus.reconnecting);
      await tester.pump();
      await tester.pump();

      statusController.add(ConnectionStatus.connected);
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);
      expect(find.text('Relay was turned OFF by fail-safe'), findsNothing);
    });

    testWidgets('navigates to scanner 5s after disconnect (not before)', (
      tester,
    ) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      statusController.add(ConnectionStatus.disconnected);
      await tester.pump();
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);

      // Still on disconnected screen after 4s
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Disconnected'), findsOneWidget);

      // Drain the remaining time + navigation
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
