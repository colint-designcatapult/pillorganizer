import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget> tabs;

  const CustomTabBar(
      {Key? key,
      required this.currentIndex,
      required this.onTabSelected,
      required this.tabs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0).r,
        border: Border.all(color: const Color(0xFFBFD2DB), width: 4.w),
        color: const Color(0xFF206B8B),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs,
          ),
        ),
      ),
    );
  }
}
