import 'package:flutter/material.dart';
import 'theme/honey_theme.dart';
import 'screens/auth_screen.dart';
export 'screens/shell_screen.dart' show HoneyChainShell, UserRole;

void main() {
  runApp(const HoneyChainApp());
}

class HoneyChainApp extends StatelessWidget {
  const HoneyChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoneyChain — KVIC Blockchain Provenance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthScreen(),
    );
  }
}
