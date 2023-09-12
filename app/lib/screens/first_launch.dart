import 'dart:async';

import 'package:app/api/auth.dart';
import 'package:app/screens/auth/login.dart';
import 'package:app/screens/index.dart';
import 'package:app/screens/provision.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
    const double topPadding = 120;
    const double bottomPadding = 80;
    const double buttonHeight = 42;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: topPadding),
              child: Text(
                'CabiNET',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
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
                                      'Welcome to CabiNET! Choose between the options below:',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
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
                                  child: Text('Set up a new device',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
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
                                child: Text('Sign in',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
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
        ),
      ),
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      Navigator.of(context).pushReplacement(IndexPage.route(context));
    }
    return status;
  }

  bool _handleAuthFailure(Exception err) {
    setState(() {
      _checkAuthFuture = Future.error(err);
    });
    return false;
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
    showMaterialModalBottomSheet<bool>(
        context: context,
        builder: (context) => LoginPage()).then((bool? result) {
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
