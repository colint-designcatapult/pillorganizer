import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ButtonIcon extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDisabled;

  const ButtonIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124.w,
      height: 72.h,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          primary: isDisabled ? Colors.grey : Colors.white,
          onPrimary: const Color(0xFF5796A9),
          side: BorderSide(
            color: isDisabled ? Colors.grey[700]! : const Color(0xFF5796A9),
            width: 2.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0).r,
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
