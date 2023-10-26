import 'package:app/api/device.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../api/provision.dart';
import '../../provider/provision_provider.dart';
import '../../provider/selected_device_provider.dart';
import '../../widgets/wizard.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          Provider.of<DeviceListProvider>(context, listen: false).refresh();
          Provider.of<SelectedDeviceProvider>(context, listen: false)
              .selectDeviceByID(value.deviceID!);
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil('/post_setup', (route) => false);
        }
      });
    }

    initConnection();
    return Selector<ProvisionProvider, Tuple2<ProvisionStage, Object?>>(
        selector: (_, prov) => Tuple2(prov.state.stage, prov.state.error),
        builder: (_, data, __) {
          return WizardStep(
            height: data.item2 != null ? null : 400,
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
    if (data.item1 == ProvisionStage.failed || data.item2 != null) {
      return PlatformElevatedButton(
        child: Text(AppLocalizations.of(context)!.genericTryAgain),
        onPressed: () {
          retryAction();
        },
      );
    } else if (data.item1 == ProvisionStage.complete) {
      return PlatformElevatedButton(
        child: Text(AppLocalizations.of(context)!.genericCompleteAction),
        onPressed: () {
          //Navigator.of(context).pushReplacement(TodayPage.route(context));
        },
      );
    }
    return null;
  }

  Widget _buildBody(context, data) {
    if (data.item1 == ProvisionStage.failed || data.item2 != null) {
      return Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: data.item2),
              )));
    } else {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Consumer<ProvisionProvider>(builder: (_, prov, child) {
              if (prov.state.stage == ProvisionStage.complete) {
                return Container();
              } else if (prov.state.stage == ProvisionStage.finalizing) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(32)),
                        child: LinearProgressIndicator(
                          value: prov.state.progress,
                          semanticsLabel:
                              AppLocalizations.of(context)!.progress,
                          minHeight: 12,
                        )),
                    const SizedBox(height: 14),
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
    if (data.item2 != null) {
      return AppLocalizations.of(context)!.connectionProblem;
    } else if (data.item1 == ProvisionStage.finalizing) {
      return AppLocalizations.of(context)!.finishingSetup;
    } else if (data.item1 == ProvisionStage.complete) {
      return AppLocalizations.of(context)!.setupComplete;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String _buildSubtitle(data, context) {
    if (data.item2 != null) {
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
