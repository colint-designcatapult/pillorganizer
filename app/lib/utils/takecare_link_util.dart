import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/deep_link_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TakecareLinkUtil {
  TakecareLinkUtil._();

  static Future<String> handlePostAuthNavigation(BuildContext context, WidgetRef ref) async {
    final deepLinkState = ref.read(deepLinkProvider);

    if (!_hasPendingTakecareLink(deepLinkState)) {
      return '/index';
    }

    final isAlreadyLinked = await _checkIfUserIsLinkedToTakecare(context, ref);

    _clearDeepLink(ref, clearPatientId: isAlreadyLinked);

    return isAlreadyLinked ? '/index' : '/patient_confirmation';
  }

  static Future<void> handleDeepLinkInApp(BuildContext context, WidgetRef ref) async {
    final deepLinkState = ref.read(deepLinkProvider);

    if (!_hasPendingTakecareLink(deepLinkState)) {
      return;
    }

    final isAlreadyLinked = await _checkIfUserIsLinkedToTakecare(context, ref);

    _clearDeepLink(ref, clearPatientId: isAlreadyLinked);

    if (!isAlreadyLinked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/patient_confirmation', (route) => false);
      });
    }
  }

  static bool _hasPendingTakecareLink(DeepLinkState state) {
    return state.pendingNavigation &&
        state.patientId != null;
  }

  static Future<bool> _checkIfUserIsLinkedToTakecare(
      BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    await authNotifier.checkAuthStatus();
    return ref.read(authenticationProvider)?.isLinkedToTakecare ?? false;
  }

  static void _clearDeepLink(WidgetRef ref,
      {required bool clearPatientId}) {
    ref.read(deepLinkProvider.notifier).setPendingNavigation(false);
    if (clearPatientId) {
      ref.read(deepLinkProvider.notifier).clearPatientId();
    }
  }
}
