
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ScrollProvider extends ChangeNotifier implements ReassembleHandler  {
  ScrollController _controller = ScrollController();
  ScrollController get controller => _controller;
  double _value = 0.0;
  double get value => _value;

  ScrollProvider() {
    _addListener();
  }

  void _addListener() {
    _controller.addListener(_scrollEvent);
  }

  void _scrollEvent() {
    _value = _controller.offset;
    notifyListeners();
  }

  @override
  void reassemble() {
    _controller.removeListener(_scrollEvent);
    _addListener();
  }
}