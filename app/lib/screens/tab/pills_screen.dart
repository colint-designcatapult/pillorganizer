import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PillsScreen extends StatefulWidget {
  const PillsScreen({super.key});

  @override
  State<PillsScreen> createState() => _PillsScreenState();
}

class _PillsScreenState extends State<PillsScreen> {
  void _addNewPillUpdate() {
    final medicationsProvider = context.read<MedicationsProvider>();
    medicationsProvider.update(
        Provider.of<SelectedDeviceProvider>(context, listen: false).device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFBFD2DB),
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: 75),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 24),
                          child: Text(
                            'My Pills',
                            style: TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      if (Provider.of<SelectedDeviceProvider>(context,
                                  listen: false)
                              .device !=
                          null)
                        AddNewPillModal(onAdd: () => _addNewPillUpdate()),
                    ]),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.purple,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.white,
                        ],
                        stops: <double>[0.0, 0.1, 0.9, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstOut,
                    child: Consumer<MedicationsProvider>(
                      builder: (context, prov, _) {
                        if (prov.value == null) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 40),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: prov.value!.length,
                          itemBuilder: (context, index) {
                            return MedicationCard(med: prov.value![index]);
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 72),
              ])),
        ));
  }
}
