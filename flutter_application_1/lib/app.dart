import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}