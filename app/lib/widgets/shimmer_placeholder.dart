import 'package:app/api/api.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final Widget Function(BuildContext, bool) builder;
  final bool loading;
  final Color? baseColor;
  final Color? highlightColor;
  final ShimmerDirection? direction;

  const ShimmerPlaceholder(
      {super.key,
      required this.builder,
      this.baseColor,
      this.highlightColor,
      this.loading = false,
      this.direction});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: loading
          ? Shimmer.fromColors(
              key: ValueKey<bool>(loading),
              baseColor: baseColor ?? Theme.of(context).colorScheme.primary,
              highlightColor: highlightColor ?? const Color(0xff2680A6),
              direction: direction ?? ShimmerDirection.ltr,
              child: builder(context, loading))
          : builder(context, loading),
    );
  }
}

class RefreshablePlaceholder<T> extends StatelessWidget {
  final RefreshableValueNotifier<T> notifier;
  final Widget Function(BuildContext, RefreshableValueNotifier<T>, bool)
      builder;
  final bool preferData;
  const RefreshablePlaceholder(
      {super.key,
      required this.notifier,
      required this.builder,
      this.preferData = false});

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
        builder: (context, loading) {
          return builder(context, notifier, loading);
        },
        loading: preferData ? notifier.value == null : notifier.loading);
  }
}
