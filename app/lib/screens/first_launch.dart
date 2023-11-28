import 'dart:async';

import 'package:app/navigation/provision_navigator.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    const double topPadding = 120;
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
              padding: const EdgeInsets.only(top: topPadding),
              child: Text(
                AppLocalizations.of(context)!.appName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 34),
            Image.asset(
              'lib/assets/main-icon.png',
            ),
            Padding(
                padding: const EdgeInsets.only(
                    bottom: bottomPadding,
                    left: edgePadding,
                    right: edgePadding),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .welcomeCabinetLong,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(color: Colors.white)))),
                          Padding(
                            padding: const EdgeInsets.only(top: 32, bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: buttonHeight,
                              child: OutlinedButton(
                                  onPressed: () {
                                    _startOOBE();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .deviceNewSetup,
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
                            height: buttonHeight,
                            child: OutlinedButton(
                                onPressed: () {
                                  _login();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
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
      Navigator.of(context).pushNamedAndRemoveUntil("/index", (route) => false);
    }
    return status;
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

  void _startOOBE() {
    startProvisioning(context);
  }

  void _login() {
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (context) => const LoginPage()).then((bool? result) {
      if (result != null) {
        _handleAuthSuccess(result);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
