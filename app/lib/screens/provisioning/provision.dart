import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/provider/provision_provider.dart';
import 'package:app/screens/provisioning/wifi_select_screen.dart';
import 'package:app/widgets/missing_permission_info_box.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../service/provisioning_service.dart';

class ErrorInfoBox extends StatefulWidget {
  const ErrorInfoBox({super.key, required this.error});

  final Object? error;

  @override
  State<StatefulWidget> createState() => _ErrorInfoBoxState();
}

class _ErrorInfoBoxState extends State<ErrorInfoBox> {
  @override
  Widget build(BuildContext context) {
    final errorStr = widget.error?.toString() ?? '';
    final localizedError = provErrorMessage(context, errorStr);
    
    // If localizedError is the generic fallback, show the actual error string
    final displayError = (localizedError == AppLocalizations.of(context)!.genericError && errorStr.isNotEmpty)
        ? errorStr
        : localizedError;

    return Text(
      displayError,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

class ProvisionPage extends ConsumerStatefulWidget {
  const ProvisionPage({super.key});

  static Route<ProvisionPage> route(context) => MaterialPageRoute(
      builder: (_) => const ProvisionPage());

  @override
  ConsumerState<ProvisionPage> createState() => _ProvisionPageState();
}

class _ProvisionPageState extends ConsumerState<ProvisionPage>
    with TickerProviderStateMixin {
  bool scanningWifi = false;
  bool timeoutTryAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(provisionProvider);
      _startScanningBluetooth();
    });
  }

  Future<void> _startScanningBluetooth() async {
    final prov = ref.read(provisionProvider.notifier);
    final state = ref.read(provisionProvider);

    if (state.deviceName == null) {
      prov.scanBluetooth().then((_) {
        final newState = ref.read(provisionProvider);
        if (newState.deviceName != null && mounted) {
          Navigator.of(context)
              .pushReplacement(ProvisionSelectWifiPage.route(context, newState));
        }
      }).timeout(const Duration(seconds: 25), onTimeout: () {
        setState(() {
          timeoutTryAgain = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisionProvider);
    ProvisionningProgress provisionningProgress = ProvisionningProgress(1, 1);

    return ScreenUtilWrapper(
      child: WizardStep(
        height: state.error != null ||
            state.stage == ProvisionStage.missingPermissions
            ? null
            : state.stage == ProvisionStage.select_ble
            ? 600.h
            : 400.h,
        provisionningProgress: provisionningProgress,
        title: _buildTitle(state),
        subtext: _buildSubtitle(state),
        onBackPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        footer: state.error != null ||
            timeoutTryAgain ||
            state.stage == ProvisionStage.missingPermissions
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: ElevatedButton(
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
            onPressed: () async {
              setState(() {
                timeoutTryAgain = false;
              });
              ref.read(provisionProvider.notifier).rescanBluetooth();
            },
          ),
        ) : null,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ProvisionState state) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: MissingPermissionInfoBox(),
              )));
    } else if (state.error != null) {
      return Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ErrorInfoBox(error: state.error),
              )));
    } else if (state.stage == ProvisionStage.scanning_ble) {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
                borderRadius: BorderRadius.all(const Radius.circular(32).r),
                child: LinearProgressIndicator(
                  value: state.progress,
                  semanticsLabel: AppLocalizations.of(context)!.progress,
                  minHeight: 12.h,
                )),
          ));
    } else if (state.stage == ProvisionStage.select_ble && !scanningWifi) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ...state.bluetoothList
                    .map((e) => _buildBleCard(context, e))
                    .toList(growable: false),
                TextButton(
                  onPressed: () {
                    ref.read(provisionProvider.notifier).rescanBluetooth();
                  },
                  child:
                  Text(AppLocalizations.of(context)!.provRescanBluetooth),
                ),
                SizedBox(
                  height: 35.h,
                )
              ],
            )),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildBleCard(context, String entry) {
    Widget? subtitle;

    return Padding(
        padding: const EdgeInsets.only(bottom: 8).h,
        child: Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(entry),
            subtitle: subtitle,
            onTap: () {
              setState(() {
                scanningWifi = true;
              });
              ref.read(provisionProvider.notifier).selectBluetooth(entry).then((_) {
                final newState = ref.read(provisionProvider);
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                      ProvisionSelectWifiPage.route(context, newState));
                }
              });
            },
          ),
        ));
  }

  String _buildTitle(ProvisionState state) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return AppLocalizations.of(context)!.provMissingPermission;
    } else if (state.error != null) {
      return AppLocalizations.of(context)!.provErrConGeneric;
    } else if (state.stage == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearching;
    } else if (state.stage == ProvisionStage.scanning_wifi ||
        state.stage == ProvisionStage.fetchingSerial ||
        scanningWifi) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else if (state.stage == ProvisionStage.select_ble) {
      return AppLocalizations.of(context)!.provConConnecting;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }

  String? _buildSubtitle(ProvisionState state) {
    if (state.stage == ProvisionStage.missingPermissions) {
      return null;
    } else if (state.error != null) {
      return AppLocalizations.of(context)!.provErrConGenericSubtitle;
    } else if (state.stage == ProvisionStage.scanning_ble) {
      return AppLocalizations.of(context)!.provConSearchingSubtitle;
    } else if (state.stage == ProvisionStage.scanning_wifi ||
        state.stage == ProvisionStage.fetchingSerial ||
        scanningWifi) {
      return AppLocalizations.of(context)!.provConConnectingSubtitle;
    } else if (state.stage == ProvisionStage.select_ble) {
      return AppLocalizations.of(context)!.provConSelectingSubtitle;
    } else {
      return AppLocalizations.of(context)!.genericError;
    }
  }
}
