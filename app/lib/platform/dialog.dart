import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

Future<void> showAlertDialog(BuildContext context, String message) {
  return showPlatformDialog(
      context: context,
      builder: (context) {
        return PlatformAlertDialog(
            content: Center(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              PlatformDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]);
      });
}
