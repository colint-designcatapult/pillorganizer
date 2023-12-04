import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBarItem extends StatelessWidget {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomTabBarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(top: 8.h),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSelected
                  ? KeyedSubtree(
                      key: const ValueKey<int>(1),
                      child: selectedIcon,
                    )
                  : KeyedSubtree(
                      key: const ValueKey<int>(0),
                      child: icon,
                    ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Opacity(
                opacity: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14)),
                  child: AnimatedContainer(
                    curve: Curves.easeIn,
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 54.w : 0.0,
                    height: 4.h,
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(isSelected ? 0 : 2.0),
                        color: const Color(0xFFBFD2DB)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
