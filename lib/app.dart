import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

class ImpressionVaultApp extends StatelessWidget {
  const ImpressionVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impression Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7C6B)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
