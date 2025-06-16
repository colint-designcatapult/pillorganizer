import 'package:app/api/device.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class JoinDevicePage extends StatefulWidget {
  const JoinDevicePage({super.key});

  static Route<JoinDevicePage> route(BuildContext context) => platformPageRoute(
      context: context, builder: (_) => const JoinDevicePage());

  @override
  _JoinDevicePageState createState() => _JoinDevicePageState();
}

class _JoinDevicePageState extends State<JoinDevicePage> {
  bool showCodeStep = true;
  bool codeInError = false;
  bool canProceed = false;
  String joinedDeviceName = '';

  void onValidateDigitCode(BuildContext context, String code) {
    var caregiverProvider =
        Provider.of<CaregiverProvider>(context, listen: false);

    caregiverProvider.validateCaregiverCode(code: code).then((_) {
      Provider.of<DeviceListProvider>(context, listen: false).refresh();
      setState(() {
        showCodeStep = false;
        canProceed = true;
      });
    }).catchError((error) {
      setState(() {
        codeInError = true;
        canProceed = false;
      });
    });
  }

  Widget _securityCodeSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.joinDeviceTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Text(AppLocalizations.of(context)!.joinDeviceSubtext,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5))),
        SixDigitCodeInput(
            onSubmitted: (code) => onValidateDigitCode(context, code),
            inError: codeInError),
        if (codeInError)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(AppLocalizations.of(context)!.joinDeviceErrorExpired,
                  style:
                      const TextStyle(color: Color(0xff9A2D25), fontSize: 14)))
      ],
    );
  }

  Widget _confirmationSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.joinDeviceConfirmationTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
                AppLocalizations.of(context)!
                    .joinDeviceConfirmationSubtext(joinedDeviceName),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFBFD2DB),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 24.w, top: 100.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.joinPageTitle,
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 32.h),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Material(
                      elevation: 4,
                      shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                      borderRadius: BorderRadius.all(Radius.circular(12.r)),
                      child: Container(
                        padding: EdgeInsets.all(20.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12.r)),
                        ),
                        child: showCodeStep
                            ? _securityCodeSection()
                            : _confirmationSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 72.h,
          color: Theme.of(context).secondaryHeaderColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 24.h,
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Text(AppLocalizations.of(context)!.back,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () =>
                        canProceed ? Navigator.of(context).pop() : null,
                    child: Container(
                      height: 72.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(32).r,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.next,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)
                                  .copyWith(
                                      color: canProceed
                                          ? Colors.white
                                          : const Color(0xffBED4D8))),
                          SizedBox(
                            width: 8.w,
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 24.h,
                            color: canProceed
                                ? Colors.white
                                : const Color(0xffBED4D8),
                          ),
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ));
  }
}
