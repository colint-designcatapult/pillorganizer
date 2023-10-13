import 'package:app/provider/medication_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PillsScreen extends StatelessWidget {
  const PillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFC3D1DA),
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: 75),
              child: Column(children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 24),
                          child: Text(
                            'My Pills',
                            style: TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      AddNewPillModal(),
                    ]),
                const SizedBox(height: 32),
                Expanded(child:
                    Consumer<MedicationsProvider>(builder: (context, prov, _) {
                  return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(mainAxisSize: MainAxisSize.max, children: [
                        ...prov.value!
                            .map((e) => MedicationCard(med: e))
                            .toList(growable: false)
                      ]));
                })),
                const SizedBox(height: 72),
              ])),
        ));
  }
}
