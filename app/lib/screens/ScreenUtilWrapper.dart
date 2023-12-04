import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScreenUtilWrapper extends StatelessWidget {
  final Widget child;

  const ScreenUtilWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(393, 852), // design size
      builder: (BuildContext context, Widget? child) {
        return this.child; // Use the passed child widget
      },
    );
  }
}
