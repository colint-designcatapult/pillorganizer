import 'package:app/provider/time_provider.dart';
import 'package:app/widgets/dose_period_area.dart';
import 'package:app/widgets/pillbox/pill_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
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
                  child: Consumer<MinuteBasedTimeProvider>(
                    builder: (context, minuteProvider, child) {
                      return Text(
                        AppLocalizations.of(context)!.localeName == 'fr'
                            ? DateFormat('EEEE, d MMMM', 'fr')
                                .format(minuteProvider.value)
                            : DateFormat('EEEE, d MMMM', 'en')
                                .format(minuteProvider.value),
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    },
                  ),
                ),
              ),
              // TEMPORARY DEBUG: Show patient ID from deep link
              // SliverToBoxAdapter(
              //   child: Consumer<DeepLinkProvider>(
              //     builder: (context, deepLinkProvider, child) {
              //       if (deepLinkProvider.hasPatientId) {
              //         return Container(
              //           margin: EdgeInsets.only(bottom: 16.h),
              //           padding: EdgeInsets.all(16.w),
              //           decoration: BoxDecoration(
              //             color: Colors.green.withOpacity(0.1),
              //             borderRadius: BorderRadius.circular(8.r),
              //             border: Border.all(color: Colors.green, width: 2),
              //           ),
              //           child: Row(
              //             children: [
              //               const Icon(Icons.check_circle, color: Colors.green),
              //               SizedBox(width: 8.w),
              //               Expanded(
              //                 child: Text(
              //                   '🎉 Deep Link Success!\nPatient ID: ${deepLinkProvider.patientId}',
              //                   style: TextStyle(
              //                     color: Colors.green[800],
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               ),
              //               IconButton(
              //                 onPressed: () {
              //                   deepLinkProvider.clearPatientId();
              //                 },
              //                 icon:
              //                     const Icon(Icons.close, color: Colors.green),
              //               ),
              //             ],
              //           ),
              //         );
              //       }
              //       return const SizedBox.shrink();
              //     },
              //   ),
              // ),
              const SliverToBoxAdapter(child: Pillbox()),
              const DosePeriodArea(),
            ],
          ),
        ),
      ),
    );
  }
}
