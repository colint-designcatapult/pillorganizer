import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/addNewPill/add_new_pills.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddNewPillModal extends StatefulWidget {
  const AddNewPillModal({super.key, required this.onAdd});

  final VoidCallback onAdd;
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
        () => widget.onAdd());
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
                Text(AppLocalizations.of(context)!.addNew,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white))
              ],
            ),
            onPressed: () => {
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
                        return StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return ChangeNotifierProvider<NewMedicationProvider>(
                              create: (context) => newMedicationProvider,
                              builder: (context, _) => MedicationModal(
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
                                        ? const MedicationCardEntry()
                                        : AddNewPills(
                                            onAddMedicationClick: () =>
                                                setState(() {
                                              showNewMedications = true;
                                            }),
                                          ),
                                  ));
                        });
                      }).whenComplete(() {
                    setState(() {
                      showNewMedications = false;
                    });
                  }),
                }));
  }
}

class IndexNewPills extends StatelessWidget {
  final VoidCallback onAdd;
  const IndexNewPills({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final newMedicationProvider = NewMedicationProvider(
        Provider.of<SelectedDeviceProvider>(context, listen: false)
            .device!
            .deviceID,
        () => onAdd);

    return GestureDetector(
      onTap: () => {
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
                return ChangeNotifierProvider<NewMedicationProvider>(
                    create: (context) => newMedicationProvider,
                    builder: (context, _) => MedicationModal(
                        onBack: () => Navigator.of(context).pop(),
                        onNext: true,
                        child: const MedicationCardEntry()));
              });
            })
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF8F8FA),
        ),
        child: DottedBorder(
          borderType: BorderType.RRect,
          color: Theme.of(context).primaryColor,
          strokeWidth: 2,
          dashPattern: const <double>[4, 4],
          radius: const Radius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.addPills,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicationModal extends StatelessWidget {
  final VoidCallback onBack;
  final bool? onNext;
  final int? medicationID;
  final Widget child;
  static const navFooterHeight = 72.0;

  const MedicationModal(
      {super.key,
      required this.onBack,
      this.onNext,
      this.medicationID,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Stack(children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: medicationID != null
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: [
                    if (medicationID != null)
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            Provider.of<NewMedicationProvider>(context,
                                    listen: false)
                                .delete(context);
                          }),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 32,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200), child: child),
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
                            Text(AppLocalizations.of(context)!.back,
                                style: Theme.of(context).textTheme.bodyMedium),
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
                                color: Provider.of<NewMedicationProvider>(
                                            context,
                                            listen: false)
                                        .canComplete()
                                    ? Theme.of(context).primaryColor
                                    : const Color(0xFF7FA9BB),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    medicationID != null
                                        ? PhosphorIcons.check
                                        : PhosphorIcons.plus,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                      medicationID != null
                                          ? AppLocalizations.of(context)!.save
                                          : AppLocalizations.of(context)!
                                              .addToList,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ));
                      })),
                  ],
                ),
              )),
        ]));
  }
}
