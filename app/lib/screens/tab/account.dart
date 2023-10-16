import 'package:app/provider/medication_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../../provider/authentication_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFBFD2DB),
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: 75),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Account Settings',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 32),
                        )),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(children: [
                        Row(
                          children: [
                            SquareButton(
                              color: const Color(0xFF7A2C2C),
                              icon: PhosphorIcons.power_fill,
                              label: "Sign Out",
                              onPressed: () {
                                Provider.of<AuthenticationProvider>(context,
                                        listen: false)
                                    .signOut(context);
                              },
                            )
                          ],
                        )
                      ]),
                    )
                  ]))),
        ));
  }
}

class SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const SquareButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.color = const Color(0xFF043C4D)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(
              Radius.circular(4.0)), // Rounded square border radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 56.0,
              color: color,
            ),
            SizedBox(height: 20.0),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: color,
                    ))
          ],
        ),
      ),
    );
  }
}
