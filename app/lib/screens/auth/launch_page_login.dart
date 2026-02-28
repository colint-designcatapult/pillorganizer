import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app/main.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class LaunchPageLogin extends StatefulWidget {
  const LaunchPageLogin({Key? key}) : super(key: key);

  static Route<LaunchPageLogin> route(context) {
    return platformPageRoute(
        context: context,
        builder: (_) {
          return const LaunchPageLogin();
        });
  }

  @override
  State<LaunchPageLogin> createState() => _LaunchPageLoginState();
}

class _LaunchPageLoginState extends State<LaunchPageLogin> {
  Future<bool>? _checkAuthFuture;
  Future<void>? _loginFuture;

  @override
  Widget build(BuildContext context) {
    var topSize = MediaQuery.of(context).viewPadding.top + 55;

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: KeyboardDismissWrapper(
          child: SingleChildScrollView(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
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
                              AppLocalizations.of(context)!.signInAction,
                              textAlign: TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 32.h),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: _formComponent()),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            AppLocalizations.of(context)!
                                .dontHaveAccountAlready,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 8.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              _signInWithAmplify();
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0).r,
                              ),
                              backgroundColor: const Color(0xFFBFD2DB),
                              minimumSize: Size(double.infinity, 48.h),
                              // Make it full width
                              side: const BorderSide(
                                color: Color(0xff206B8B), // Change border color
                              ),
                            ),
                            child: Text(
                              "Make an account with Amplify",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: const Color(0xff445860))
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )))),
    );
  }

  Widget _formComponent() {
    return BasicFormContainer(
      subtitleText: AppLocalizations.of(context)!.signInBackSubtitle,
      buttonText: "Sign In with Amplify",
      onSubmit: _signInWithAmplify,
      future: _loginFuture,
      children: [],
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      _handleSuccessfulLogin();
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

  void _signInWithAmplify() {
    setState(() {
      _loginFuture = _performSignIn();
    });
  }

  Future<void> _performSignIn() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI();
      safePrint('Sign in result: $result');
      if (result.isSignedIn) {
        _handleSuccessfulLogin();
      }
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
    }
  }

  void _handleSuccessfulLogin() async {
    final route = await TakecareLinkUtil.handlePostAuthNavigation(context);
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
