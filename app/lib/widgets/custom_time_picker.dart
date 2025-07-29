import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final bool isAM;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    required this.isAM,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocusNode;
  late FocusNode _minuteFocusNode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();

    _hourController = TextEditingController();
    _minuteController = TextEditingController(
        text: widget.initialTime.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  TimeOfDay? _getValidatedTime() {
    try {
      final hour = int.parse(_hourController.text);
      final minute = int.parse(_minuteController.text);
      final localizations = AppLocalizations.of(context)!;

      if (minute < 0 || minute > 59) return null;

      int finalHour = hour;

      if (localizations.localeName != 'fr') {
        if (hour < 1 || hour > 12) return null;

        if (widget.isAM) {
          finalHour = hour == 12 ? 0 : hour;
        } else {
          finalHour = hour == 12 ? 12 : hour + 12;
        }
      } else {
        if (hour < 0 || hour > 23) return null;

        if (widget.isAM) {
          if (hour > 11) return null;
        } else {
          if (hour < 12) return null;
        }

        finalHour = hour;
      }

      return TimeOfDay(hour: finalHour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  void _onHourChanged(String value) {
    if (value.length == 2) {
      _minuteFocusNode.requestFocus();
    }
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _onMinuteChanged(String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_hourController.text.isEmpty) {
      int displayHour = widget.initialTime.hour;

      if (localizations.localeName != 'fr') {
        if (displayHour == 0) {
          displayHour = 12;
        } else if (displayHour > 12) {
          displayHour = displayHour - 12;
        }
      }

      _hourController.text = displayHour.toString().padLeft(2, '0');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isAM ? localizations.am : localizations.pm,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(width: 12.w),
                  SvgPicture.asset(
                    widget.isAM
                        ? 'lib/assets/SVG/DEV_SYM_AM.svg'
                        : 'lib/assets/SVG/DEV_SYM_PM.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    onChanged: _onHourChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: widget.initialTime.hour.toString(),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF206B8B),
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    ":",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _minuteController,
                    focusNode: _minuteFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    onChanged: _onMinuteChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: widget.initialTime.minute.toString(),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF206B8B),
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 8.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      localizations.cancel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final time = _getValidatedTime();
                      if (time != null) {
                        Navigator.of(context).pop(time);
                      } else {
                        setState(() {
                          _errorMessage = localizations.validTimeError;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF206B8B),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      localizations.save,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
