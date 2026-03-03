import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PillsScreen extends ConsumerStatefulWidget {
  const PillsScreen({super.key});

  @override
  ConsumerState<PillsScreen> createState() => _PillsScreenState();
}

class _PillsScreenState extends ConsumerState<PillsScreen> {
  void _addNewPillUpdate() {
    ref.invalidate(medicationsProvider);
    ref.invalidate(deviceStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final medications = ref.watch(medicationsProvider);
    final activeDevice = ref.watch(activeDeviceProvider);

    return Scaffold(
        backgroundColor: const Color(0xFFBFD2DB),
        body: SafeArea(
          child: Padding(
              padding: EdgeInsets.only(top: 75.h),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 24).w,
                          child: Text(
                            AppLocalizations.of(context)!.myPills,
                            style: TextStyle(
                              fontSize: 32.h,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      if (activeDevice != null)
                        AddNewPillModal(
                            deviceID: activeDevice.deviceID,
                            onComplete: () => _addNewPillUpdate()),
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
                    child: medications.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!.noticeNoMeds,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 40.h),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            return MedicationCard(med: list[index]);
                          },
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                          child: Text(err.toString())),
                    ),
                  ),
                ),
                SizedBox(height: 72.h),
              ])),
        ));
  }
}
