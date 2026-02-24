import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

class AuthError {
  static const String authGenericLoginError = "authGenericLoginError";
  static const String authRegisterEmailExistingError =
      "authRegisterEmailExistingError";
  static const String authConnectionError = "authConnectionError";
  static const String authFailedError = "authFailedError";
  static const String authAlreadyRegistered = "authAlreadyRegistered";
  static const String authGenericError = "authGenericError";
}

String authErrorMessage(BuildContext context, String authError) {
  switch (authError) {
    case AuthError.authGenericLoginError:
      return AppLocalizations.of(context)!.genericLoginError;
    case AuthError.authRegisterEmailExistingError:
      return AppLocalizations.of(context)!.registerEmailExistingError;
    case AuthError.authFailedError:
      return AppLocalizations.of(context)!.authError;
    case AuthError.authConnectionError:
      return AppLocalizations.of(context)!.authConnectionError;
    case AuthError.authAlreadyRegistered:
      return AppLocalizations.of(context)!.alreadyRegistered;
    default:
      return AppLocalizations.of(context)!.genericError;
  }
}
