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

  @override
  ConsumerState<ProvisionConnectingPage> createState() =>
      _ProvisionConnectingPageState();
}

class _ProvisionConnectingPageState
    extends ConsumerState<ProvisionConnectingPage> {
  bool _navigatingBack = false;

  @override
  void initState() {
    super.initState();
  }

  void _initConnection(ProvisionState state) {
    if (state.ssid != null && state.wifiPassword != null) {
      ref.read(provisionProvider.notifier)
          .provisionWifi(ssid: state.ssid!, password: state.wifiPassword!);
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final state = ref.watch(provisionProvider);
    final ProvisionningProgress provisionningProgress = ProvisionningProgress(
      1,
      3
    );

    // Navigation listener
    ref.listen(provisionProvider, (previous, next) {
      if (!mounted) return;

      // Handle setup complete
      if (next is ProvisionStateComplete && previous is! ProvisionStateComplete) {
        if (next.mode == ProvisionMode.wifiReconfigure || next.mode == ProvisionMode.transferDevice) {
          // Navigate back to main screen, skip name/post-setup wizard
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/index', (route) => false);
          return;
        }
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/name_new_device?id=${next.claim?.deviceId}', (route) => false);
        return;
      }

    });

    void initConnection() {
      final currentState = ref.read(provisionProvider);
      _initConnection(currentState);
    }

    return WizardStep(
      height: state.errorMessage != null ? null : 400.h,
      provisionningProgress: provisionningProgress,
      title: _buildTitle(state, context),
      subtext: _buildSubtitle(state, context),
      footer: _buildFooter(context, state, initConnection),
      onBackPressed: () {
        ref.read(provisionProvider.notifier).cancelProvisioning();
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: _buildBody(context, state, ref),
    );
  }

  Widget? _buildFooter(BuildContext context, ProvisionState state, VoidCallback retryAction) {
    if (state is ProvisionStateFailed ||
        state is ProvisionStateMissingPermissions ||
        state.errorMessage != null) {
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
    } else if (state is ProvisionStateComplete) {
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
          if (state.mode == ProvisionMode.wifiReconfigure || state.mode == ProvisionMode.transferDevice) {
            final message = state.mode == ProvisionMode.wifiReconfigure
                ? AppLocalizations.of(context)!.wifiReconfigureSuccess
                : AppLocalizations.of(context)!.transferDeviceSuccess;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    }
    return null;
  }

  Widget _buildBody(BuildContext context, ProvisionState state, WidgetRef ref) {
    if (state is ProvisionStateMissingPermissions) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: MissingPermissionInfoBox(),
              )));
    }
    if (state is ProvisionStateFailed || state.errorMessage != null) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: state.errorMessage),
              )));
    } else {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Builder(builder: (context) {
              if (state is ProvisionStateComplete) {
                return const SizedBox.shrink();
              } else if (state is ProvisionStateProvisioningWifi) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(32.r)),
                        child: LinearProgressIndicator(
                          value: null, // indeterminate for wifi steps
                          semanticsLabel:
                              AppLocalizations.of(context)!.progress,
                          minHeight: 12.h,
                        )),
                    if (state is ProvisionStateProvisioningWifi) ...[  
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
    if (state is ProvisionStateMissingPermissions) {
      return AppLocalizations.of(context)!.provMissingPermission;
    } else if (state.errorMessage != null) {
      return AppLocalizations.of(context)!.connectionProblem;
    } else if (state is ProvisionStateProvisioningWifi) {
      return AppLocalizations.of(context)!.finishingSetup;
    } else if (state is ProvisionStateComplete) {
      return AppLocalizations.of(context)!.setupComplete;
    } else if (state is ProvisionStateScanningBle || state is ProvisionStateSelectBle) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else if (state is ProvisionStateScanningWifi || state is ProvisionStateFetchingSerial || state is ProvisionStateSelectWifi) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String? _buildSubtitle(ProvisionState state, BuildContext context) {
    if (state is ProvisionStateMissingPermissions) {
      return null;
    } else if (state.errorMessage != null) {
      return AppLocalizations.of(context)!.connectionProblemSubtitle;
    } else if (state is ProvisionStateProvisioningWifi) {
      return AppLocalizations.of(context)!.finishingSetupSubtitle;
    } else if (state is ProvisionStateComplete) {
      return AppLocalizations.of(context)!.setupCompleteSubtitle;
    } else if (state is ProvisionStateScanningBle || state is ProvisionStateSelectBle || state is ProvisionStateScanningWifi || state is ProvisionStateFetchingSerial || state is ProvisionStateSelectWifi) {
      return AppLocalizations.of(context)!.provConConnectingSubtitle;
    } else {
      return null;
    }
  }
}
