import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/service/provisioning_service.dart';

import '../service/provisioning_service.dart';

class NameDeviceWizard extends ConsumerStatefulWidget {
  final String? deviceId;

  const NameDeviceWizard({super.key, this.deviceId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NameDeviceWizard();
}

class _NameDeviceWizard extends ConsumerState<NameDeviceWizard> {
  final _textController = TextEditingController();
  final String _initialDeviceName = '';
  bool _isWaitingForDevice = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to trigger rebuild for button state
    _textController.addListener(() {
      setState(() {});
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
      data: (_) => false,
      orElse: () => false,
    );

    // Enable Next button only when nickname is provided
    final hasNickname = _textController.text.isNotEmpty;

    return WizardStep(
      height: 394.h,
      provisionningProgress: provisionningProgress,
      title: AppLocalizations.of(context)!.nameDeviceTitle,
      subtext: AppLocalizations.of(context)!.nameDeviceSubtext,
      canGoNext: hasNickname,
      isLoading: isUpdatingName || _isWaitingForDevice,
      onBackPressed: () => Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (route) => false),
      onNextPressed: (isUpdatingName || _isWaitingForDevice || !hasNickname) ? null : _handleNextStep,
      onSkipPressed: null,
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
    print('[NameDeviceWizard] _handleNextStep() called');
    
    if (!mounted) {
      print('[NameDeviceWizard] Widget not mounted, aborting');
      return;
    }
    
    final hasUpdatedName = _textController.text.isNotEmpty &&
        _textController.text != _initialDeviceName;

    if (widget.deviceId != null) {
      print('[NameDeviceWizard] deviceId is present: ${widget.deviceId}');
      setState(() => _isWaitingForDevice = true);
      
      // Try to update device name if user provided one
      if (hasUpdatedName) {
        try {
          print('[NameDeviceWizard] Attempting to update device name to: ${_textController.text}');
          await ref.read(deviceListProvider.notifier).updateDeviceName(
              widget.deviceId!, _textController.text);
          print('[NameDeviceWizard] Device name updated successfully');
        } catch (e) {
          print('[NameDeviceWizard] Could not update device name: $e');
          if (mounted) {
            setState(() => _isWaitingForDevice = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.noticeUnknownErrorSubtitle)),
            );
          }
          return;
        }
      } else {
        print('[NameDeviceWizard] No name change, skipping update');
      }
      
      if (mounted) {
        setState(() => _isWaitingForDevice = false);
      }
    }

    if (mounted) {
      final route = widget.deviceId != null
          ? '/post_setup?id=${widget.deviceId}'
          : '/post_setup';
      print('[NameDeviceWizard] Navigating to: $route');
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(route, (route) => false);
    }
  }
}
