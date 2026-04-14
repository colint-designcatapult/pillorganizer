import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
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
    final hasUpdatedName = _textController.text.isNotEmpty &&
        _textController.text != _initialDeviceName;

    if (widget.deviceId != null) {
      setState(() => _isWaitingForDevice = true);
      await _waitForDeviceInList(widget.deviceId!);
      await ref
          .read(activeDeviceProvider.notifier)
          .selectDeviceByID(widget.deviceId!);
      if (mounted) {
        setState(() => _isWaitingForDevice = false);
      }

      if (hasUpdatedName) {
        await ref.read(deviceListProvider.notifier).updateDeviceName(
            widget.deviceId!, _textController.text);
      }
    } else if (hasUpdatedName) {
      final activeDevice = ref.read(activeDeviceProvider);
      if (activeDevice != null) {
        await ref.read(deviceListProvider.notifier).updateDeviceName(
            activeDevice.id, _textController.text);
      }
    }

    if (mounted) {
      final route = widget.deviceId != null
          ? '/post_setup?id=${widget.deviceId}'
          : '/post_setup';
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(route, (route) => false);
    }
  }

  Future<void> _waitForDeviceInList(String deviceId, {int maxRetries = 30}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await ref.read(deviceListProvider.notifier).refresh();
        final devices = ref.read(deviceListProvider).value ?? [];
        final deviceExists = devices.any((d) => d.id == deviceId);
        if (deviceExists) return;
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        // Continue trying
      }
    }
  }
}
