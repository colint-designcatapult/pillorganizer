import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProvisionError {
  static const String authGenericLoginError = "authGenericLoginError";
  static const String authFailedError = "authFailedError";
}

String authErrorMessage(BuildContext context, String authError) {
  switch (authError) {
    case ProvisionError.authGenericLoginError:
      return AppLocalizations.of(context)!.genericLoginError;
    case ProvisionError.authFailedError:
      return AppLocalizations.of(context)!.authError;
    default:
      return AppLocalizations.of(context)!.genericError;
  }
}
