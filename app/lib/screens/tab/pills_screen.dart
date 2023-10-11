import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:flutter/material.dart';

class PillsScreen extends StatelessWidget {
  const PillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Color(0xFFC3D1DA),
        body: SafeArea(
          child: Column(children: [
            Center(
              child: Text(
                'My Pills',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AddNewPillModal()
          ]),
        ));
  }
}
