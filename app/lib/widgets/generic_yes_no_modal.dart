import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(
                      PhosphorIconsBold.x,
                      size: 24.h,
                      color: const Color(0XFF101828),
                    )),
              ),
              Column(
                children: [
                  Icon(
                    icon,
                    size: 48.h,
                    color: const Color(0xFF7A2C2C),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0).w,
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: const Color(0xFF7A2C2C)),
                  )),
              SizedBox(height: 8.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: <Widget>[
                  Expanded(
                      child: GestureDetector(
                    onTap:
                        cancelWidgetAction ?? () => Navigator.of(context).pop(),
                    child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF206B8B),
                            width: 1.w,
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
                  SizedBox(width: 12.w),
                  Expanded(
                      child: GestureDetector(
                    onTap: saveWidgetAction,
                    child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A2C2C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7A2C2C),
                            width: 1.w,
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
