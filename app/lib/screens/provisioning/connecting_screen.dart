import 'package:app/provider/provision_provider.dart';
import 'package:app/widgets/missing_permission_info_box.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/provisioning_service.dart';
import '../../widgets/wizard.dart';
import 'provision.dart';

class ProvisionConnectingPage extends ConsumerWidget {
  const ProvisionConnectingPage({super.key});

  static Route<ProvisionConnectingPage> route(context, state) =>
      MaterialPageRoute(
          builder: (_) => const ProvisionConnectingPage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provisionStateProvider);
    ProvisionningProgress provisionningProgress = ProvisionningProgress(1, 3);

    void initConnection() {
      ref.read(provisionStateProvider.notifier)
          .finalize(context)
          .then((value) {
        if (value.stage == ProvisionStage.complete) {
          // Assuming these providers are also refactored to Riverpod or accessible via ref
          // ref.read(deviceProvider.notifier).refresh();
          // ref.read(selectedDeviceProvider.notifier).selectDeviceByID(value.deviceID!);
          
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/name_new_device?id=${value.deviceID}', (route) => false);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.stage == ProvisionStage.finalizing) {
         initConnection();
      }
    });

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
          //Navigator.of(context).pushReplacement(TodayPage.route(context));
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
              } else if (state.stage == ProvisionStage.finalizing) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(32.r)),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          semanticsLabel:
                              AppLocalizations.of(context)!.progress,
                          minHeight: 12.h,
                        )),
                    SizedBox(height: 14.h),
                    Text(
                        '${AppLocalizations.of(context)!.estimatedTime} ${(state.completionETA?.inMinutes ?? 0) + 1} min.')
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
    } else if (state.stage == ProvisionStage.finalizing) {
      return AppLocalizations.of(context)!.finishingSetup;
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
    } else if (state.stage == ProvisionStage.finalizing) {
      return AppLocalizations.of(context)!.finishingSetupSubtitle;
    } else if (state.stage == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupCompleteSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }
}
