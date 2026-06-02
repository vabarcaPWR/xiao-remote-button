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

  late StreamController<int> timerRemainingController;

  setUp(() {
    mockBle = MockBleService();
    statusController = StreamController<ConnectionStatus>.broadcast();
    relayStateController = StreamController<RelayState>.broadcast();
    timerRemainingController = StreamController<int>.broadcast();

    when(() => mockBle.statusStream).thenAnswer((_) => statusController.stream);
    when(
      () => mockBle.relayStateStream,
    ).thenAnswer((_) => relayStateController.stream);
    when(
      () => mockBle.timerRemainingStream,
    ).thenAnswer((_) => timerRemainingController.stream);
    when(() => mockBle.currentStatus).thenReturn(ConnectionStatus.connected);
    when(() => mockBle.disconnect()).thenAnswer((_) async {});
    when(() => mockBle.readTimerRemaining()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    statusController.close();
    relayStateController.close();
    timerRemainingController.close();
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

    testWidgets('shows disconnected state with autonomous message', (tester) async {
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
      expect(find.text('Device running autonomously'), findsOneWidget);
    });

    testWidgets('shows back to scanner button on disconnect', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      statusController.add(ConnectionStatus.disconnected);
      await tester.pump();
      await tester.pump();

      expect(find.text('Back to scanner'), findsOneWidget);
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

      relayStateController.add(RelayState.on);
      await tester.pump();
      await tester.pump();

      expect(find.text('ON'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

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

    testWidgets('reconnects and reads state when connected again', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      statusController.add(ConnectionStatus.disconnected);
      await tester.pump();
      await tester.pump();
      expect(find.text('Disconnected'), findsOneWidget);

      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      statusController.add(ConnectionStatus.connected);
      await tester.pumpAndSettle();

      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('shows timer section on control screen', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.off);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Auto-off timer'), findsOneWidget);
    });

    testWidgets('shows countdown when timer is running', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);
      when(() => mockBle.readTimerRemaining()).thenAnswer((_) async => 125);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('02:05'), findsOneWidget);
    });

    testWidgets('timer remaining updates via notify stream', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      timerRemainingController.add(90);
      await tester.pump();
      await tester.pump();

      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('shows timer expired snackbar when remaining hits 0', (tester) async {
      when(
        () => mockBle.readRelayState(),
      ).thenAnswer((_) async => RelayState.on);
      when(() => mockBle.readTimerRemaining()).thenAnswer((_) async => 5);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      timerRemainingController.add(0);
      await tester.pump();
      await tester.pump();

      expect(find.text('Timer expired — relay turned OFF'), findsOneWidget);
    });
  });
}
