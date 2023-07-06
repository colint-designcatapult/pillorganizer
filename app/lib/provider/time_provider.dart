import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MinuteBasedTimeProvider extends ChangeNotifier
    implements ReassembleHandler  {
  late DateTime _value;
  DateTime get value => _value;
  late Timer _timer;

  MinuteBasedTimeProvider() {
    _scheduleOnMinute();
  }

  void _tick() {
    _value = DateTime.now();
    notifyListeners();
  }

  void _scheduleOnMinute() {
    _value = DateTime.now();
    var nextMinute = DateTime(_value.year, _value.month, _value.day,
        _value.hour, _value.minute + 1);
    _timer = Timer(nextMinute.difference(_value), () {
     _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _tick();
      });
    });
    notifyListeners();
  }

  @override
  void reassemble() {
    _timer.cancel();
    _scheduleOnMinute();
  }

}