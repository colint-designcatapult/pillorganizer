import 'package:app/main.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/amplify_service.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LaunchPageLogin extends ConsumerStatefulWidget {
  const LaunchPageLogin({Key? key}) : super(key: key);

  static Route<LaunchPageLogin> route(context) {
    return MaterialPageRoute(
        builder: (_) {
          return const LaunchPageLogin();
        });
  }

  @override
  ConsumerState<LaunchPageLogin> createState() => _LaunchPageLoginState();
}

class _LaunchPageLoginState extends ConsumerState<LaunchPageLogin> {
  Future<bool>? _checkAuthFuture;
  Future<void>? _loginFuture;
  bool _isLoading = false;
  final AmplifyService _amplifyService = AmplifyService();

  @override
  Widget build(BuildContext context) {
    var topSize = MediaQuery.of(context).viewPadding.top + 55;

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: Stack(
        children: [
          KeyboardDismissWrapper(
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
                              "Create an account",
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
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x80000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formComponent() {
    return BasicFormContainer(
      subtitleText: AppLocalizations.of(context)!.signInBackSubtitle,
      buttonText: "Sign In",
      onSubmit: _signInWithAmplify,
      future: _loginFuture,
      children: [],
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (!status) {
      if (mounted) setState(() => _isLoading = false);
      return false;
    }
    // If the user manually tapped Sign In while the auto-check was running,
    // _loginFuture is already set. Don't navigate — let _performSignIn handle it.
    if (_loginFuture == null) {
      await _handleSuccessfulLogin();
      if (mounted) setState(() => _isLoading = false);
    }
    return true;
  }

  bool _handleAuthFailure(dynamic err) {
    if (err is Exception) {
      setState(() {
        _isLoading = false;
        _checkAuthFuture = Future.error(err);
      });
      return false;
    } else {
      print('Unhandled error type: $err');
      if (mounted) setState(() => _isLoading = false);
      return false;
    }
  }

  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Guard: don't start a background Amplify fetchAuthSession if sign-in
      // via signInWithWebUI is already in flight. Concurrent Amplify auth
      // operations can cause the SDK to auto sign-out after sign-in completes.
      if (_loginFuture != null) return;
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

  void _signInWithAmplify() {
    setState(() {
      _isLoading = true;
      _loginFuture = _performSignIn();
    });
  }

  Future<void> _performSignIn() async {
    try {
      final isSignedIn = await _amplifyService.signInWithWebUI();
      if (isSignedIn) {
        await _handleSuccessfulLogin();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    final route = await TakecareLinkUtil.handlePostAuthNavigation(context, ref);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
