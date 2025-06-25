import 'package:app/provider/device_provider.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/missing_permission_info_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../api/provision.dart';
import '../../provider/provision_provider.dart';
import '../../provider/selected_device_provider.dart';
import '../../widgets/wizard.dart';
import 'provision.dart';

class ProvisionConnectingPage extends StatelessWidget {
  const ProvisionConnectingPage({super.key});

  static Route<ProvisionConnectingPage> route(context, state) =>
      platformPageRoute(
          context: context, builder: (_) => const ProvisionConnectingPage());

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(1, 3);

    void initConnection() {
      Provider.of<ProvisionProvider>(context, listen: false)
          .finalize(context)
          .then((value) {
        if (value.stage == ProvisionStage.complete) {
          Provider.of<DeviceProvider>(context, listen: false).refresh();
          Provider.of<SelectedDeviceProvider>(context, listen: false)
              .selectDeviceByID(value.deviceID!);
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/name_new_device?id=${value.deviceID}', (route) => false);
        }
      });
    }

    initConnection();
    return Selector<ProvisionProvider, Tuple2<ProvisionStage, Object?>>(
        selector: (_, prov) => Tuple2(prov.state.stage, prov.state.error),
        builder: (_, data, __) {
          return WizardStep(
            height: data.item2 != null ? null : 400.h,
            provisionningProgress: provisionningProgress,
            title: _buildTitle(data, context),
            subtext: _buildSubtitle(data, context),
            footer: _buildFooter(context, data, initConnection),
            onBackPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
            child: _buildBody(context, data),
          );
        });
  }

  Widget? _buildFooter(context, data, retryAction) {
    if (data.item1 == ProvisionStage.failed ||
        data.item1 == ProvisionStage.missingPermissions ||
        data.item2 != null) {
      return PlatformElevatedButton(
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14.0.h),
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
    } else if (data.item1 == ProvisionStage.complete) {
      return PlatformElevatedButton(
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(vertical: 14.0.h),
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

  Widget _buildBody(context, data) {
    if (data.item1 == ProvisionStage.missingPermissions) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: MissingPermissionInfoBox(),
              )));
    }
    if (data.item1 == ProvisionStage.failed || data.item2 != null) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: data.item2),
              )));
    } else {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Consumer<ProvisionProvider>(builder: (_, prov, child) {
              if (prov.state.stage == ProvisionStage.complete) {
                return Container();
              } else if (prov.state.stage == ProvisionStage.finalizing) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(32.r)),
                        child: LinearProgressIndicator(
                          value: prov.state.progress,
                          semanticsLabel:
                              AppLocalizations.of(context)!.progress,
                          minHeight: 12.h,
                        )),
                    SizedBox(height: 14.h),
                    Text(
                        '${AppLocalizations.of(context)!.estimatedTime} ${(prov.state.completionETA?.inMinutes ?? 0) + 1} min.')
                  ],
                );
              } else {
                return Container();
              }
            }),
          ));
    }
    /*if(state.stage == ProvisionStage.complete) {
      return Container();
    } else if(state.stage == ProvisionStage.finalizing) {

    } else {
      return ErrorInfoBox(error: state.error);
    }*/
  }

  String _buildTitle(data, context) {
    if (data.item1 == ProvisionStage.missingPermissions) {
      return AppLocalizations.of(context)!.provMissingPermission;
    } else if (data.item2 != null) {
      return AppLocalizations.of(context)!.connectionProblem;
    } else if (data.item1 == ProvisionStage.finalizing) {
      return AppLocalizations.of(context)!.finishingSetup;
    } else if (data.item1 == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupComplete;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String? _buildSubtitle(data, context) {
    if (data.item1 == ProvisionStage.missingPermissions) {
      return null;
    } else if (data.item2 != null) {
      return AppLocalizations.of(context)!.connectionProblemSubtitle;
    } else if (data.item1 == ProvisionStage.finalizing) {
      return AppLocalizations.of(context)!.finishingSetupSubtitle;
    } else if (data.item1 == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupCompleteSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }
}
