import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_provider.g.dart';

@riverpod
class ScrollNotifier extends _$ScrollNotifier {
  late ScrollController _controller;
  
  @override
  ScrollController build() {
    _controller = ScrollController();
    ref.onDispose(() => _controller.dispose());
    return _controller;
  }

  void scrollToTop() {
    if (_controller.hasClients) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
