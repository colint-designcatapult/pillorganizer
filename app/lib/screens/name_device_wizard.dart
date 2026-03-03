import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NameDeviceWizard extends ConsumerStatefulWidget {
  final int? deviceId;

  const NameDeviceWizard({super.key, this.deviceId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NameDeviceWizard();
}

class _NameDeviceWizard extends ConsumerState<NameDeviceWizard> {
  final _textController = TextEditingController();
  final String _initialDeviceName = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.deviceId != null) {
        ref.read(activeDeviceProvider.notifier).selectDeviceByID(widget.deviceId!);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provisionningProgress = ProvisionningProgress(2, 1);
    final deviceListState = ref.watch(deviceListProvider);
    final isUpdatingName = deviceListState.maybeWhen(
      data: (_) => false, // Or some other way to track name update
      orElse: () => false,
    );
    // Note: We might need a separate state for isUpdatingName if it's not in the deviceListProvider.
    // Assuming for now it's false unless we find where it's tracked.

    return WizardStep(
      height: 394.h,
      provisionningProgress: provisionningProgress,
      title: AppLocalizations.of(context)!.nameDeviceTitle,
      subtext: AppLocalizations.of(context)!.nameDeviceSubtext,
      canGoNext: true,
      isLoading: isUpdatingName,
      onBackPressed: () => Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (route) => false),
      onNextPressed: isUpdatingName ? null : _handleNextStep,
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
  }

  Future<void> _handleNextStep() async {
    final activeDevice = ref.read(activeDeviceProvider);

    if (_textController.text.isNotEmpty &&
        _textController.text != _initialDeviceName) {
      if (activeDevice != null) {
        await ref.read(deviceListProvider.notifier).updateDeviceName(
            activeDevice.deviceID, _textController.text);
      }
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/post_setup', (route) => false);
    }
  }
}
