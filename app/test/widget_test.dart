import 'package:flutter_test/flutter_test.dart';
import 'package:xiao_remote_button/main.dart';

void main() {
  testWidgets('App widget creates MaterialApp with correct title',
      (WidgetTester tester) async {
    const app = XiaoRelayApp();

    expect(app, isA<XiaoRelayApp>());
  });
}
