import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<T?> showPlatformModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  double? closeProgressThreshold,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  Curve? previousRouteAnimationCurve,
  bool useRootNavigator = false,
  bool bounce = true,
  bool? isDismissible,
  bool enableDrag = true,
  Duration? duration,
  RouteSettings? settings,
  Color? transitionBackgroundColor,
  BoxShadow? shadow,
}) async {
  if(Platform.isIOS) {
    return showCupertinoModalBottomSheet(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      closeProgressThreshold: closeProgressThreshold,
      shape: shape,
      clipBehavior: clipBehavior,
      barrierColor: barrierColor,
      expand: expand,
      secondAnimation: secondAnimation,
      animationCurve: animationCurve,
      previousRouteAnimationCurve: previousRouteAnimationCurve,
      useRootNavigator: useRootNavigator,
      bounce: bounce,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      duration: duration,
      settings: settings,
      transitionBackgroundColor: transitionBackgroundColor,
      shadow: shadow
    );
  } else {
    return showMaterialModalBottomSheet(
        context: context,
        builder: builder,
        backgroundColor: backgroundColor,
        elevation: elevation,
        closeProgressThreshold: closeProgressThreshold,
        shape: shape,
        clipBehavior: clipBehavior,
        barrierColor: barrierColor,
        expand: expand,
        secondAnimation: secondAnimation,
        animationCurve: animationCurve,
        useRootNavigator: useRootNavigator,
        bounce: bounce,
        enableDrag: enableDrag,
        duration: duration,
        settings: settings,
    );
  }
}