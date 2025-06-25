import 'package:app/provider/device_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NameDeviceWizard extends StatefulWidget {
  final int? deviceId;

  const NameDeviceWizard({Key? key, this.deviceId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NameDeviceWizard();
}

class _NameDeviceWizard extends State<NameDeviceWizard> {
  final _formKey = GlobalKey<FormState>();
  String? deviceName;

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(2, 1);
    final selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);
    if (widget.deviceId != null) {
      selectedDeviceProvider.selectDeviceByID(widget.deviceId!);
    }

    return Consumer2<ScheduleProvider, SelectedDeviceProvider>(
      builder: (context, scheduleProvider, selectedDeviceProvider, child) {
        return WizardStep(
            height: 375.h,
            provisionningProgress: provisionningProgress,
            title: AppLocalizations.of(context)!.nameDeviceTitle,
            subtext: AppLocalizations.of(context)!.nameDeviceSubtext,
            onBackPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false),
            onNextPressed: () => handleNextStep(),
            canGoNext: true,
            child: Expanded(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: _renameDevice(context),
            )));
      },
    );
  }

  Widget _renameDevice(BuildContext context) {
    return Form(
        key: _formKey,
        child: BasicPageTextFormField(
          labelText: AppLocalizations.of(context)!.nameDeviceHint,
          onSaved: (val) => deviceName = val,
        ));
  }

  Future<void> handleNextStep() async {
    _formKey.currentState?.save();

    var selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);

    if (deviceName!.isNotEmpty) {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.updateDeviceName(
          selectedDeviceProvider.device!.deviceID, deviceName!);
    }

    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/post_setup', (route) => false);
  }
}
