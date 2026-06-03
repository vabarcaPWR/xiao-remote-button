import 'package:flutter/material.dart';
import 'screens/scanner/scanner_screen.dart';

void main() {
  runApp(const FipRelayApp());
}

class FipRelayApp extends StatelessWidget {
  const FipRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIP Relay',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const ScannerScreen(),
    );
  }
}
