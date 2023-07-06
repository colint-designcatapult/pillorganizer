
import 'package:app/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final Widget Function(BuildContext, bool) builder;
  final bool loading;
  const ShimmerPlaceholder({
    super.key,
    required this.builder,
    this.loading = false
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: loading ? Shimmer.fromColors(
        key: ValueKey<bool>(loading),
        baseColor: Color(0xFF053C4D),
        highlightColor: Color(0xFF06425B),
        child: builder(context, loading),
      ) : builder(context, loading),
    );
  }
  
}


class RefreshablePlaceholder<T> extends StatelessWidget {
  final RefreshableValueNotifier<T> notifier;
  final Widget Function(BuildContext, RefreshableValueNotifier<T>, bool) builder;
  final bool preferData;
  const RefreshablePlaceholder({
    super.key,
    required this.notifier,
    required this.builder,
    this.preferData = false
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      builder: (context, loading) {
        return builder(context, notifier, loading);
      },
      loading: preferData ? notifier.value == null : notifier.loading
    );
  }

}