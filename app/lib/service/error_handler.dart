import 'package:app/api/api.dart';
import 'package:app/service/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

void loginHandleError(context, err) {
  if (err is ProblemJsonException) {
    showErrorDialog(
        context, AppLocalizations.of(context)!.genericProblem(err.problem));
  } else {
    showErrorDialog(
        context,
        AppLocalizations.of(context)!
            .signInError(authErrorMessage(context, err.toString())));
  }
}

void registerHandleError(context, err) {
  if (err is ProblemJsonException) {
    showErrorDialog(
        context, AppLocalizations.of(context)!.genericProblem(err.problem));
  } else {
    showErrorDialog(
        context,
        AppLocalizations.of(context)!
            .registerError(authErrorMessage(context, err.toString())));
  }
}

Future<void> passwordHandleError(context, err) async {
  if (err is ProblemJsonException) {
    showErrorDialog(
        context, AppLocalizations.of(context)!.genericProblem(err.problem));
  } else {
    showErrorDialog(
        context, AppLocalizations.of(context)!.genericProblem(err.toString()));
  }
}

Future<void> showErrorDialog(BuildContext context, String message) {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            content: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            actions: [
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.genericOK),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]);
      });
}
