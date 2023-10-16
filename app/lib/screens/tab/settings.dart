import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: SafeArea(
        child: Center(
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
