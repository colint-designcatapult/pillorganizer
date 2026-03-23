import 'package:app/screens/provisioning/join_device_screen.dart';
import 'package:app/screens/provisioning/provision_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeNoDeviceBody extends ConsumerWidget {
  const HomeNoDeviceBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var date = DateTime.now();

    void handleConnectNewDevice() {
      Navigator.of(context).push(ProvisionFlowPage.route());
    }

    void handleJoinExistingDevice() {
      Navigator.of(context).push(JoinDevicePage.route(context));
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              AppLocalizations.of(context)!.localeName == 'fr'
                  ? DateFormat('EEEE, d MMMM', 'fr').format(date)
                  : DateFormat('EEEE, d MMMM', 'en').format(date),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(AppLocalizations.of(context)!.noDeviceDescription,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            OutlinedButton(
                onPressed: () => handleConnectNewDevice(),
                style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(
                      color:
                          Color(0xff8BCAE5), // Change border color to #8BCAE5
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    backgroundColor: const Color(0xFFFFFFFF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withAlpha(127)),
                child: Text(
                  AppLocalizations.of(context)!.quickSwitchNewDevice,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xff206B8B))
                      .copyWith(fontWeight: FontWeight.w600),
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: OutlinedButton(
                  onPressed: () => handleJoinExistingDevice(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0).r,
                    ),
                    backgroundColor: const Color(0xff206B8B),
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(
                      color: Color(0xff206B8B),
                    ),
                  ),
                  child: Text(
                      AppLocalizations.of(context)!.quickSwitchExistingDevice,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                ))
          ]),
        ),
      ),
    );
  }
}
