import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/addNewPill/add_new_pills.dart';
import 'package:app/widgets/addNewPill/new_medications.dart';
import 'package:provider/provider.dart';

class AddNewPillModal extends StatefulWidget {
  const AddNewPillModal({super.key});

  @override
  _AddNewPillModalState createState() => _AddNewPillModalState();
}

class _AddNewPillModalState extends State<AddNewPillModal> {
  bool showNewMedications = false;

  @override
  Widget build(BuildContext context) {
    final newMedicationProvider = NewMedicationProvider(
      Provider.of<SelectedDeviceProvider>(context, listen: false)
          .device!
          .deviceID,
    );
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size(170, 72),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    bottomLeft: Radius.circular(40)))),
        child: Row(
          children: [
            const Icon(Icons.add, size: 24, color: Colors.white),
            const SizedBox(
              width: 8,
            ),
            Text('Add new',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white))
          ],
        ),
        onPressed: () {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFFFBFCFF),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              builder: (context) {
                return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                  return NewMedicationModal(
                    newMedicationProvider: newMedicationProvider,
                    onBack: () => {
                      if (showNewMedications)
                        {
                          setState(() {
                            showNewMedications = false;
                          })
                        }
                      else
                        {Navigator.of(context).pop()}
                    },
                    onNext: showNewMedications,
                    child: showNewMedications
                        ? const NewMedications()
                        : AddNewPills(
                            onAddMedicationClick: () => setState(() {
                              showNewMedications = true;
                            }),
                          ),
                  );
                });
              }).whenComplete(() {
            setState(() {
              showNewMedications = false;
            });
          });
        },
      ),
    );
  }
}

class NewMedicationModal extends StatelessWidget {
  final NewMedicationProvider newMedicationProvider;
  final VoidCallback onBack;
  final bool? onNext;
  final Widget child;
  static const navFooterHeight = 72.0;

  const NewMedicationModal(
      {super.key,
      required this.newMedicationProvider,
      required this.onBack,
      this.onNext,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NewMedicationProvider>.value(
        value: newMedicationProvider,
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Stack(children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 32,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: child),
                  ),
                ],
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: navFooterHeight,
                    color: const Color(0xFFFBFCFF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onBack,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text('Back',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                        if (onNext == true)
                          Expanded(child: Consumer<NewMedicationProvider>(
                              builder: (context, provider, child) {
                            return GestureDetector(
                              onTap: () {
                                if (provider.canComplete()) {
                                  provider.complete(context);
                                }
                              },
                              child: Container(
                                height: navFooterHeight,
                                decoration: BoxDecoration(
                                  color: provider.canComplete()
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFF7FA9BB),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(32),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text('Add to list',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ),
                            );
                          })),
                      ],
                    ),
                  )),
            ])));
  }
}
