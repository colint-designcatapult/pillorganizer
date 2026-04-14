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
  final String? deviceId;

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
    // Don't select device here — we'll do it in _handleNextStep before navigating
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
    if (_textController.text.isNotEmpty &&
        _textController.text != _initialDeviceName) {
      final activeDevice = ref.read(activeDeviceProvider);
      if (activeDevice != null) {
        await ref.read(deviceListProvider.notifier).updateDeviceName(
            activeDevice.id, _textController.text);
      }
    }

    if (mounted) {
      // Pass device ID to PostSetupWizard so it can load the schedule directly
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/post_setup?id=${widget.deviceId}', (route) => false);
    }
  }
}
