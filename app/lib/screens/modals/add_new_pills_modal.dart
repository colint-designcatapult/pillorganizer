import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/addNewPill/add_new_pills.dart';
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:app/widgets/button_icon_text.dart';
import 'package:app/widgets/generic_yes_no_modal.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

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
                minimumSize: Size(170.w, 72.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(40).r,
                        bottomLeft: const Radius.circular(40).r))),
            child: Row(
              children: [
                Icon(Icons.add, size: 24.h, color: Colors.white),
                SizedBox(
                  width: 8.w,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(16).r,
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
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
    return GestureDetector(
      onTap: () => {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFFFBFCFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16).r,
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            builder: (context) {
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return ChangeNotifierProvider<NewMedicationProvider>(
                    create: (context) => NewMedicationProvider(
                        Provider.of<SelectedDeviceProvider>(context,
                                listen: false)
                            .device!
                            .deviceID,
                        () => onAdd),
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
          options: RoundedRectDottedBorderOptions(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
            dashPattern: const <double>[4, 4],
            radius: const Radius.circular(8).r,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add),
                SizedBox(width: 4.w),
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
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: medicationID != null
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: [
                    if (medicationID != null)
                      Padding(
                          padding: const EdgeInsets.only(left: 8).w,
                          child: ButtonIconText(
                              text: AppLocalizations.of(context)!.delete,
                              iconData: PhosphorIconsRegular.trashSimple,
                              onPressed: () => deleteMedication(context))),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 32.h,
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
                height: 72.h,
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
                            Icon(
                              Icons.arrow_back,
                              size: 24.h,
                            ),
                            SizedBox(
                              width: 8.w,
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
                              height: 72.h,
                              decoration: BoxDecoration(
                                color: Provider.of<NewMedicationProvider>(
                                            context,
                                            listen: false)
                                        .canComplete()
                                    ? Theme.of(context).primaryColor
                                    : const Color(0xFF7FA9BB),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(32).r,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    medicationID != null
                                        ? PhosphorIconsRegular.check
                                        : PhosphorIconsRegular.plus,
                                    size: 24.h,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 8.w,
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

  void deleteMedication(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GenericYesNoModal(
          icon: PhosphorIconsFill.power,
          title: AppLocalizations.of(context)!.deleteMedication,
          subtitle: AppLocalizations.of(context)!.deleteMedicationConfirmation,
          saveWidgetText: AppLocalizations.of(context)!.delete,
          saveWidgetAction: () {
            Provider.of<NewMedicationProvider>(context, listen: false)
                .delete(context);
            Navigator.of(context).pop();
          }),
    );
  }
}
