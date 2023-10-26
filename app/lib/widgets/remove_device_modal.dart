import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RemoveDeviceDialog extends StatefulWidget {
  const RemoveDeviceDialog({super.key});

  @override
  State<StatefulWidget> createState() => _RemoveDeviceDialog();
}

class _RemoveDeviceDialog extends State<RemoveDeviceDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(PhosphorIcons.x_bold),
                    color: const Color(0XFF101828),
                  ),
                ],
              ),
              const Icon(
                PhosphorIcons.warning,
                color: Color(0XFF7A2C2C),
                size: 48,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.removingDevice,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(
                      0XFF7A2C2C,
                    ),
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.removingDeviceConfirmation,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0XFF667085)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF206B8B),
                            width: 1.0,
                          ),
                        ),
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.back,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF206B8B)),
                            ))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      print("Remove device");
                    },
                    child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A2C2C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7A2C2C),
                            width: 1.0,
                          ),
                        ),
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(AppLocalizations.of(context)!.remove,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                    )))),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
