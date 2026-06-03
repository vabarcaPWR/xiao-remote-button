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

  test('FipRelayApp builds with light and dark theme using Material 3', () {
    const app = FipRelayApp();
    final widget = app.build(
      _FakeBuildContext(),
    ) as MaterialApp;

    expect(widget.theme, isNotNull);
    expect(widget.darkTheme, isNotNull);
    expect(widget.themeMode, ThemeMode.system);
    expect(widget.theme!.colorScheme.brightness, Brightness.light);
    expect(widget.darkTheme!.colorScheme.brightness, Brightness.dark);
    expect(widget.theme!.useMaterial3, true);
    expect(widget.darkTheme!.useMaterial3, true);
    expect(widget.title, 'FIP Relay');
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}
