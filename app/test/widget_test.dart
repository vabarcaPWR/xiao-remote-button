import 'package:flutter_test/flutter_test.dart';
import 'package:xiao_remote_button/main.dart';

void main() {
  testWidgets('App launches with scanner screen', (WidgetTester tester) async {
    await tester.pumpWidget(const XiaoRelayApp());
    expect(find.text('XIAO Relay — Scanner'), findsOneWidget);
  });
}
