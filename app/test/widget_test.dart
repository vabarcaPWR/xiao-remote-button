import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fip_remote_button/main.dart';

void main() {
  testWidgets('App widget creates MaterialApp with correct title', (
    WidgetTester tester,
  ) async {
    const app = FipRelayApp();
    expect(app, isA<FipRelayApp>());
  });

  test('FipRelayApp builds with light and dark theme', () {
    const app = FipRelayApp();
    final widget = app.build(
      _FakeBuildContext(),
    ) as MaterialApp;

    expect(widget.theme, isNotNull);
    expect(widget.darkTheme, isNotNull);
    expect(widget.themeMode, ThemeMode.system);
    expect(widget.theme!.brightness, Brightness.light);
    expect(widget.darkTheme!.brightness, Brightness.dark);
    expect(widget.title, 'FIP Relay');
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}
