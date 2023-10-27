import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GenericYesNoModal extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String saveWidgetText;
  final VoidCallback saveWidgetAction;
  final String? cancelWidgetText;
  final VoidCallback? cancelWidgetAction;
  const GenericYesNoModal({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.saveWidgetText,
    required this.saveWidgetAction,
    this.cancelWidgetText,
    this.cancelWidgetAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: const EdgeInsets.all(16),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      PhosphorIcons.x_bold,
                      size: 24,
                      color: Color(0XFF101828),
                    )),
              ),
              Column(
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: const Color(0xFF7A2C2C),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: const Color(0xFF7A2C2C)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Expanded(
                      child: GestureDetector(
                    onTap:
                        cancelWidgetAction ?? () => Navigator.of(context).pop(),
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
                                cancelWidgetText ??
                                    AppLocalizations.of(context)!.back,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                        color: const Color(0xFF206B8B))))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                    onTap: saveWidgetAction,
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
                            child: Text(saveWidgetText,
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
        ));
  }
}
