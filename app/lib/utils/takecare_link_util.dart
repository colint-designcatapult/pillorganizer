import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/deep_link_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TakecareLinkUtil {
  TakecareLinkUtil._();

  static Future<String> handlePostAuthNavigation(BuildContext context) async {
    final deepLinkProvider =
        Provider.of<DeepLinkProvider>(context, listen: false);

    if (!_hasPendingTakecareLink(deepLinkProvider)) {
      return '/index';
    }

    final isAlreadyLinked = await _checkIfUserIsLinkedToTakecare(context);

    _clearDeepLink(deepLinkProvider, clearPatientId: isAlreadyLinked);

    return isAlreadyLinked ? '/index' : '/patient_confirmation';
  }

  static Future<void> handleDeepLinkInApp(BuildContext context) async {
    final deepLinkProvider =
        Provider.of<DeepLinkProvider>(context, listen: false);

    if (!_hasPendingTakecareLink(deepLinkProvider)) {
      return;
    }

    final isAlreadyLinked = await _checkIfUserIsLinkedToTakecare(context);

    _clearDeepLink(deepLinkProvider, clearPatientId: isAlreadyLinked);

    if (!isAlreadyLinked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/patient_confirmation', (route) => false);
      });
    }
  }

  static bool _hasPendingTakecareLink(DeepLinkProvider deepLinkProvider) {
    return deepLinkProvider.hasPendingNavigation &&
        deepLinkProvider.hasPatientId;
  }

  static Future<bool> _checkIfUserIsLinkedToTakecare(
      BuildContext context) async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    return authProvider.currentUser?.isLinkedToTakecare ?? false;
  }

  static void _clearDeepLink(DeepLinkProvider deepLinkProvider,
      {required bool clearPatientId}) {
    deepLinkProvider.clearPendingNavigation();
    if (clearPatientId) {
      deepLinkProvider.clearPatientId();
    }
  }
}
