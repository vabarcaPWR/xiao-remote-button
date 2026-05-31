import 'package:flutter/material.dart';
import 'screens/scanner/scanner_screen.dart';

void main() {
  runApp(const XiaoRelayApp());
}

class XiaoRelayApp extends StatelessWidget {
  const XiaoRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XIAO Relay',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}
