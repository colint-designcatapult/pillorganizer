import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:app/provider/schedule_provider.dart';

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

/// Provider that returns the current time converted to the device's timezone.
/// Uses the device's effectiveTimezoneIana from the schedule for accurate timezone conversion.
@riverpod
DateTime deviceCurrentTime(ref) {
  final now = ref.watch(minuteBasedTimeProvider);
  final scheduleAsync = ref.watch(scheduleProvider);
  
  // Get the device's timezone from the schedule
  final schedule = scheduleAsync.value;
  final timezoneIana = schedule?.effectiveTimezoneIana;

  // Convert current time to device's timezone
  return _convertUtcToDeviceTimezone(now, timezoneIana);
}

/// Helper: Convert UTC time to device's timezone using IANA timezone name
DateTime _convertUtcToDeviceTimezone(DateTime utcTime, String? timezoneIana) {
  if (timezoneIana == null || timezoneIana.isEmpty) {
    // If no timezone, treat as local time
    return utcTime.toLocal();
  }

  try {
    // Look up the timezone location from IANA name
    final timezone = tz.getLocation(timezoneIana);
    
    // Create TZDateTime from UTC DateTime and return it directly so the
    // timezone-aware instant/offset are preserved.
    final tzDateTime = tz.TZDateTime.from(utcTime, timezone);
    return tzDateTime;
  } catch (e) {
    // If timezone lookup fails, fall back to local time
    print('[deviceCurrentTime] Failed to lookup timezone $timezoneIana: $e');
    return utcTime.toLocal();
  }
}
