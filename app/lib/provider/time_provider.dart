import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_provider.g.dart';

@riverpod
class MinuteBasedTime extends _$MinuteBasedTime {
  late Timer _timer;

  @override
  DateTime build() {
    _scheduleOnMinute();
    
    // Cleanup on dispose
    ref.onDispose(() => _timer.cancel());
    
    return DateTime.now();
  }

  void _scheduleOnMinute() {
    final now = DateTime.now();
    var nextMinute = DateTime(
        now.year, now.month, now.day, now.hour, now.minute + 1);
    
    _timer = Timer(nextMinute.difference(now), () {
      state = DateTime.now();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        state = DateTime.now();
      });
    });
  }
}
