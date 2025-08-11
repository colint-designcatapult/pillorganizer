import 'dart:async';

import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/auth/launch_page_login.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class FirstLaunchPage extends StatefulWidget {
  const FirstLaunchPage({super.key});

  @override
  State<StatefulWidget> createState() => _FirstLaunchPageState();
}

class _FirstLaunchPageState extends State<FirstLaunchPage> {
  Future<bool>? _checkAuthFuture;

  @override
  Widget build(BuildContext context) {
    const double edgePadding = 24;
    const double topPadding = 100;
    const double bottomPadding = 80;
    const double buttonHeight = 48;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: topPadding).h,
              child: Text(
                AppLocalizations.of(context)!.appName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 450.h,
              child: Image.asset(
                'lib/assets/main-icon.png',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(
                        bottom: bottomPadding,
                        left: edgePadding,
                        right: edgePadding)
                    .w,
                child: FutureBuilder<bool>(
                  future: _checkAuthFuture,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.hasData ||
                        snapshot.hasError ||
                        snapshot.connectionState == ConnectionState.done) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Center(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 20)
                                          .w,
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .welcomeCabinetLong,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(color: Colors.white)))),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 32, bottom: 24).h,
                            child: SizedBox(
                              width: double.infinity,
                              height: buttonHeight.h,
                              child: OutlinedButton(
                                  onPressed: () {
                                    _handleCreateAccount();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.0).r,
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .createAnAccount,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor))),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: buttonHeight.h,
                            child: OutlinedButton(
                                onPressed: () {
                                  _login();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0).r,
                                  ),
                                  side: const BorderSide(
                                      width: 1.0, color: Colors.white),
                                ),
                                child: Text(
                                    AppLocalizations.of(context)!.signInAction,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(color: Colors.white))),
                          ),
                        ],
                      );
                    } else {
                      return const CircularProgressIndicator(
                        color: Colors.white,
                      );
                    }
                  },
                ))
          ],
        )),
      ),
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      _handleSuccessfulAuth();
    }
    return status;
  }

  void _handleSuccessfulAuth() async {
    final route = await TakecareLinkUtil.handlePostAuthNavigation(context);
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  bool _handleAuthFailure(dynamic err) {
    if (err is Exception) {
      setState(() {
        _checkAuthFuture = Future.error(err);
      });
      return false;
    } else {
      print('Unhandled error type: $err');
      return false;
    }
  }

  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        var future = Provider.of<AuthenticationProvider>(context, listen: false)
            .checkAuthStatus()
            .then((value) => _handleAuthSuccess(value))
            .catchError((err) => _handleAuthFailure(err));

        setState(() {
          _checkAuthFuture = future;
        });
      } on Exception catch (e) {
        _handleAuthFailure(e);
      }
    });
  }

  void _handleCreateAccount() {
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/register', (route) => false);
  }

  void _login() {
    Navigator.of(context).push(LaunchPageLogin.route(context));
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
