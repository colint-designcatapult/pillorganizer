import 'package:app/provider/provision_provider.dart';
import 'package:app/widgets/missing_permission_info_box.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/provisioning_service.dart';
import '../../widgets/wizard.dart';
import 'provision.dart';

class ProvisionConnectingPage extends ConsumerStatefulWidget {
  const ProvisionConnectingPage({super.key});

  static Route<ProvisionConnectingPage> route(context, state) =>
      MaterialPageRoute(
          builder: (_) => const ProvisionConnectingPage());

  @override
  ConsumerState<ProvisionConnectingPage> createState() =>
      _ProvisionConnectingPageState();
}

class _ProvisionConnectingPageState
    extends ConsumerState<ProvisionConnectingPage> {
  bool _connectionStarted = false;
  bool _navigatingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(provisionProvider);
      if (state.stage == ProvisionStage.select_wifi && !_connectionStarted) {
        _connectionStarted = true;
        _initConnection(state);
      }
    });
  }

  void _initConnection(state) {
    if (state.ssid != null && state.wifiPassword != null) {
      ref.read(provisionProvider.notifier)
          .provisionWifi(ssid: state.ssid!, password: state.wifiPassword!)
          .then((_) {
        if (!mounted) return;
        final newState = ref.read(provisionProvider);
        if (newState.stage == ProvisionStage.complete) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/name_new_device?id=${newState.deviceID}', (route) => false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final state = ref.watch(provisionProvider);
    final ProvisionningProgress provisionningProgress = ProvisionningProgress(
      state.stage == ProvisionStage.complete ? 3 : 2,
      3,
    );

    // When the device restarts (WiFi fail, fleet fail, timeout) go back to My Devices
    ref.listen(provisionProvider, (previous, next) {
      if (next.stage == ProvisionStage.scanning_ble &&
          previous?.stage != ProvisionStage.scanning_ble &&
          mounted &&
          !_navigatingBack) {
        _navigatingBack = true;
        final message = next.error?.toString() ??
            'Your device is restarting. Please start provisioning again.';
        // Show dialog while context is still valid; pop to My Devices from OK button
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Setup failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // dismiss dialog
                  Navigator.of(context, rootNavigator: true).pop(); // go back to My Devices
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    void initConnection() {
      final currentState = ref.read(provisionProvider);
      _initConnection(currentState);
    }

    return WizardStep(
      height: state.error != null ? null : 400.h,
      provisionningProgress: provisionningProgress,
      title: _buildTitle(state, context),
      subtext: _buildSubtitle(state, context),
      footer: _buildFooter(context, state, initConnection),
      onBackPressed: () =>
          Navigator.of(context, rootNavigator: true).pop(),
      child: _buildBody(context, state, ref),
    );
  }

  Widget? _buildFooter(context, ProvisionState state, retryAction) {
    if (state.stage == ProvisionStage.failed ||
        state.stage == ProvisionStage.missingPermissions ||
        state.error != null) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 14.0.h),
        ),
        child: Text(
          AppLocalizations.of(context)!.genericTryAgain,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(color: Colors.white),
        ),
        onPressed: () {
          retryAction();
        },
      );
    } else if (state.stage == ProvisionStage.complete) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 14.0.h),
        ),
        child: Text(
          AppLocalizations.of(context)!.genericCompleteAction,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(color: Colors.white),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    }
    return null;
  }

  Widget _buildBody(context, ProvisionState state, WidgetRef ref) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: MissingPermissionInfoBox(),
              )));
    }
    if (state.stage == ProvisionStage.failed || state.error != null) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: state.error),
              )));
    } else {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Builder(builder: (context) {
              if (state.stage == ProvisionStage.complete) {
                return const SizedBox.shrink();
              } else if (state.stage == ProvisionStage.provisioning_wifi ||
                  state.stage == ProvisionStage.verifying_wifi ||
                  state.stage == ProvisionStage.fleet_provisioning) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(32.r)),
                        child: LinearProgressIndicator(
                          value: state.stage == ProvisionStage.fleet_provisioning
                              ? state.progress
                              : null, // indeterminate for wifi steps
                          semanticsLabel:
                              AppLocalizations.of(context)!.progress,
                          minHeight: 12.h,
                        )),
                    if (state.stage == ProvisionStage.provisioning_wifi) ...[  
                      SizedBox(height: 14.h),
                      Text(
                          '${AppLocalizations.of(context)!.estimatedTime} ${(state.completionETA?.inMinutes ?? 0) + 1} min.')
                    ],
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ));
    }
  }

  String _buildTitle(ProvisionState state, BuildContext context) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return AppLocalizations.of(context)!.provMissingPermission;
    } else if (state.error != null) {
      return AppLocalizations.of(context)!.connectionProblem;
    } else if (state.stage == ProvisionStage.provisioning_wifi) {
      return AppLocalizations.of(context)!.finishingSetup;
    } else if (state.stage == ProvisionStage.verifying_wifi) {
      return 'Connecting to WiFi...';
    } else if (state.stage == ProvisionStage.fleet_provisioning) {
      return 'Registering device...';
    } else if (state.stage == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupComplete;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String? _buildSubtitle(ProvisionState state, BuildContext context) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return null;
    } else if (state.error != null) {
      return AppLocalizations.of(context)!.connectionProblemSubtitle;
    } else if (state.stage == ProvisionStage.provisioning_wifi) {
      return AppLocalizations.of(context)!.finishingSetupSubtitle;
    } else if (state.stage == ProvisionStage.verifying_wifi) {
      return 'Waiting for the device to join the network...';
    } else if (state.stage == ProvisionStage.fleet_provisioning) {
      return 'Connecting to cloud and setting up your device. This may take a moment.';
    } else if (state.stage == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupCompleteSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }
}
