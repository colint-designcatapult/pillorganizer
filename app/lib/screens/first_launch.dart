import 'dart:async';

import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/amplify_service.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FirstLaunchPage extends ConsumerStatefulWidget {
  const FirstLaunchPage({super.key});

  @override
  ConsumerState<FirstLaunchPage> createState() => _FirstLaunchPageState();
}

class _FirstLaunchPageState extends ConsumerState<FirstLaunchPage> {
  Future<bool>? _checkAuthFuture;
  bool _isLoading = false;
  final AmplifyService _amplifyService = AmplifyService();

  @override
  Widget build(BuildContext context) {
    const double edgePadding = 24;
    const double topPadding = 100;
    const double bottomPadding = 80;
    const double buttonHeight = 48;
    final localizations = AppLocalizations.of(context)!;
    final signInOrCreateAccountLabel =
        '${localizations.signInAction} ${localizations.or} ${localizations.createAccount}';

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
        Center(
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: topPadding).h,
              child: Text(
                localizations.appName,
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
                                      localizations.welcomeCabinetLong,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(color: Colors.white)))),
                          Padding(
                            padding: const EdgeInsets.only(top: 32).h,
                            child: SizedBox(
                              width: double.infinity,
                              height: buttonHeight.h,
                              child: OutlinedButton(
                                  onPressed: () {
                                    _signInWithAmplify();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.0).r,
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Text(
                                      signInOrCreateAccountLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor))),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ))
          ],
        )),
        ),
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x80000000),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ]),
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      _handleSuccessfulAuth();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
    return status;
  }

  void _handleSuccessfulAuth() async {
    if (!mounted) return;
    final route = await TakecareLinkUtil.handlePostAuthNavigation(context, ref);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  bool _handleAuthFailure(dynamic err) {
    if (err is Exception) {
      if (mounted) setState(() {
        _isLoading = false;
        _checkAuthFuture = Future.error(err);
      });
      return false;
    } else {
      if (mounted) setState(() => _isLoading = false);
      return false;
    }
  }

  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      try {
        setState(() => _isLoading = true);
        var future = ref.read(authenticationProvider.notifier)
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

  void _signInWithAmplify() async {
    setState(() => _isLoading = true);
    try {
      final isSignedIn = await _amplifyService.signInWithWebUI();
      if (isSignedIn && mounted) {
        _handleSuccessfulAuth();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
