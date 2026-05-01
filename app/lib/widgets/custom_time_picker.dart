import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
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
  late String _initialHourDisplay;
  late String _initialMinuteDisplay;

  @override
  void initState() {
    super.initState();
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();

    // Store initial display values (current schedule)
    _initialHourDisplay = _formatHourForDisplay(widget.initialTime.hour);
    _initialMinuteDisplay = widget.initialTime.minute.toString().padLeft(2, '0');

    // Initialize controllers as empty (will show placeholder)
    _hourController = TextEditingController();
    _minuteController = TextEditingController();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  /// Format hour for 12-hour display
  String _formatHourForDisplay(int hour) {
    if (hour == 0) return '12';
    if (hour > 12) return (hour - 12).toString();
    return hour.toString();
  }

  /// Validate time inputs - both fields must be valid
  bool _isTimeValid() {
    return _isHourValid() && _isMinuteValid();
  }

  TimeOfDay? _getValidatedTime() {
    try {
      final hour = int.parse(_hourController.text);
      final minute = int.parse(_minuteController.text);

      // Final validation
      if (!_isHourValid() || !_isMinuteValid()) {
        return null;
      }

      int finalHour = hour;

      if (widget.isAM) {
        finalHour = hour == 12 ? 0 : hour;
      } else {
        finalHour = hour == 12 ? 12 : hour + 12;
      }

      return TimeOfDay(hour: finalHour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  void _updateValidation() {
    setState(() {
      // Show error only for invalid 2-digit entries
      bool hourErrorNeeded = _hourController.text.length == 2 && !_isHourValid();
      bool minuteErrorNeeded = _minuteController.text.length == 2 && !_isMinuteValid();

      if (hourErrorNeeded || minuteErrorNeeded) {
        _errorMessage = AppLocalizations.of(context)!.validTimeError;
      } else {
        _errorMessage = null;
      }
    });
  }

  bool _isHourValid() {
    String text = _hourController.text;
    if (text.isEmpty) return false;
    
    try {
      final hour = int.parse(text);
      // Single digit: 1-9 are valid (0 is not valid but no error shown)
      if (text.length == 1) {
        return hour >= 1 && hour <= 9;
      }
      // Two digits: 01-12 are valid
      if (text.length == 2) {
        return hour >= 1 && hour <= 12;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool _isMinuteValid() {
    String text = _minuteController.text;
    if (text.isEmpty) return false;
    
    try {
      final minute = int.parse(text);
      // Single digit: 1-9 are valid (0 is not valid but no error shown)
      if (text.length == 1) {
        return minute >= 1 && minute <= 9;
      }
      // Two digits: 00-59 are valid
      if (text.length == 2) {
        return minute >= 0 && minute <= 59;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _onHourChanged(String value) {
    _updateValidation();
  }

  void _onMinuteChanged(String value) {
    _updateValidation();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    // Determine if save button should be enabled
    final isSaveEnabled = _isTimeValid();

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
                      hintText: _initialHourDisplay,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                      ),
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
                    enabled: _isHourValid(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    onChanged: _onMinuteChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: _initialMinuteDisplay,
                      hintStyle: TextStyle(
                        color: _isHourValid() ? Colors.grey[400] : Colors.grey[600],
                        fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                      ),
                      filled: true,
                      fillColor: _isHourValid() ? const Color(0xFFF1F5F6) : Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
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
                    onPressed: isSaveEnabled
                        ? () {
                            final time = _getValidatedTime();
                            if (time != null) {
                              Navigator.of(context).pop(time);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaveEnabled
                          ? const Color(0xFF206B8B)
                          : Colors.grey[300],
                      foregroundColor:
                          isSaveEnabled ? Colors.white : Colors.grey,
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
