import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/widgets/dose_period_area.dart';
import 'package:app/widgets/medication_history_modal.dart';
import 'package:app/widgets/pillbox/pill_box.dart';
import 'package:app/widgets/today_medication_card.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../provider/device_error_provider.dart';

class HomeBody extends ConsumerWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceTime = ref.watch(deviceCurrentTimeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(40.0).r,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Builder(
                    builder: (context) {
                      final localeName = AppLocalizations.of(context)!.localeName;
                      final dateStr = localeName == 'fr'
                          ? DateFormat('EEEE, d MMMM', 'fr').format(deviceTime)
                          : DateFormat('EEEE, d MMMM', 'en').format(deviceTime);

                      final timeStr = DateFormat.jm(localeName).format(deviceTime);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            timeStr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(child: Pillbox()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: const TodayMedicationCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 120.h),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final selectedDevice = ref.watch(activeDeviceProvider);
                      final deviceStateAsync = ref.watch(deviceStateProvider);
                      final deviceError = ref.watch(deviceErrorProvider);
                      
                      if (selectedDevice == null) {
                        return const SizedBox.shrink();
                      }
                      
                      final isLoading = deviceStateAsync.isLoading;
                      final isDisconnected = deviceError == DeviceError.disconnected;
                      final isDisabled = isLoading || isDisconnected;
                      
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDisabled ? Colors.grey[400] : const Color(0xFF206B8B),
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: isDisabled ? null : () {
                            showDialog(
                              context: context,
                              builder: (_) => MedicationHistoryModal(
                                deviceId: selectedDevice.id,
                              ),
                            );
                          },
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : Text(
                                  'Device Medication History',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
