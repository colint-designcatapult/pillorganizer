import 'package:app/provider/device_provider.dart';
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
  final _textController = TextEditingController();
  String _initialDeviceName = '';

  @override
  void initState() {
    super.initState();

    _populateDeviceName();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.deviceId != null) {
        final selectedDeviceProvider =
            Provider.of<SelectedDeviceProvider>(context, listen: false);
        selectedDeviceProvider.selectDeviceByID(widget.deviceId!);
      }
    });
  }

  void _populateDeviceName() {
    final selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);
    if (selectedDeviceProvider.device != null) {
      final currentName = selectedDeviceProvider.device!.name;
      _textController.text = currentName;
      _initialDeviceName = currentName;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provisionningProgress = ProvisionningProgress(2, 1);

    return Consumer2<SelectedDeviceProvider, DeviceProvider>(
      builder: (context, selectedDeviceProvider, deviceProvider, child) {
        return WizardStep(
          height: 394.h,
          provisionningProgress: provisionningProgress,
          title: AppLocalizations.of(context)!.nameDeviceTitle,
          subtext: AppLocalizations.of(context)!.nameDeviceSubtext,
          canGoNext: true,
          isLoading: deviceProvider.isUpdatingName,
          onBackPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false),
          onNextPressed: deviceProvider.isUpdatingName ? null : _handleNextStep,
          onSkipPressed: _handleNextStep,
          child: Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
              child: BasicPageTextFormField(
                controller: _textController,
                paddingBottom: 0.h,
                labelText: AppLocalizations.of(context)!.nameDeviceHint,
                onFieldSubmitted: (_) => _handleNextStep(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleNextStep() async {
    final selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);

    if (_textController.text.isNotEmpty &&
        _textController.text != _initialDeviceName) {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.updateDeviceName(
          selectedDeviceProvider.device!.deviceID, _textController.text);
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/post_setup', (route) => false);
    }
  }
}
