import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'today_medication_provider.g.dart';

/// Represents a single dose scheduled for today, either upcoming or past.
class TodayDose {
  final int binId;
  final DateTime scheduledTime;
  final BinStatus status;
  final List<int> medicationIds;
  final String? takenAtTime;

  const TodayDose({
    required this.binId,
    required this.scheduledTime,
    required this.status,
    required this.medicationIds,
    this.takenAtTime,
  });

  /// Returns true if this dose is in the past.
  /// Past doses are those with status: TAKEN, MISSED, DISABLED, or noRecord
  /// (i.e., any dose that has already been processed or is no longer active)
  bool isPast() {
    return status == BinStatus.taken || 
           status == BinStatus.missed || 
           status == BinStatus.disabled || 
           status == BinStatus.noRecord;
  }

  /// Returns true if this dose is upcoming.
  /// Upcoming doses are those with status: PENDING or take_now
  /// (i.e., doses that still need to be taken)
  bool isUpcoming() {
    return status == BinStatus.pending || status == BinStatus.take_now;
  }
}

/// Represents the medication status for today, separated into upcoming and past doses.
class TodayMedicationStatus {
  final List<TodayDose> upcomingDoses;
  final List<TodayDose> pastDoses;
  final int totalDosesScheduled;

  const TodayMedicationStatus({
    required this.upcomingDoses,
    required this.pastDoses,
    required this.totalDosesScheduled,
  });

  /// Count of doses that have been taken.
  int get dosesTaken =>
      pastDoses.where((d) => d.status == BinStatus.taken).length;

  /// Count of doses that have been missed.
  int get dosesMissed =>
      pastDoses.where((d) => d.status == BinStatus.missed).length;

  /// Summary text showing completed doses (e.g., "2/2 doses taken today").
  String getSummary() {
    final completedCount = dosesTaken + dosesMissed;
    return '$completedCount/$totalDosesScheduled doses completed today';
  }
}

/// Provider that computes today's medication status from device state bins.
/// Automatically filters for today's doses and separates them into upcoming/past.
@riverpod
TodayMedicationStatus todayMedicationStatus(ref) {
  final now = ref.watch(minuteBasedTimeProvider);
  final deviceStateAsync = ref.watch(deviceStateProvider);
  final activeDevice = ref.watch(activeDeviceProvider);
  final scheduleAsync = ref.watch(scheduleProvider);

  // Return empty status if no device connected
  if (activeDevice == null) {
    return const TodayMedicationStatus(
      upcomingDoses: [],
      pastDoses: [],
      totalDosesScheduled: 0,
    );
  }

  // Get the actual DeviceState from the AsyncValue (same as Pillbox pattern)
  final deviceState = deviceStateAsync.value;

  if (deviceState == null || deviceState.bins.isEmpty) {
    return const TodayMedicationStatus(
      upcomingDoses: [],
      pastDoses: [],
      totalDosesScheduled: 0,
    );
  }

  // Get the device's timezone from the schedule
  final schedule = scheduleAsync.value;
  final timezoneIana = schedule?.effectiveTimezoneIana;

  // Helper to convert UTC time to device's timezone
  DateTime convertToDeviceTimezone(DateTime utcTime) {
    if (timezoneIana == null || timezoneIana.isEmpty) {
      return utcTime.toLocal();
    }
    try {
      final timezone = tz.getLocation(timezoneIana);
      final tzDateTime = tz.TZDateTime.from(utcTime, timezone);
      return DateTime(
        tzDateTime.year,
        tzDateTime.month,
        tzDateTime.day,
        tzDateTime.hour,
        tzDateTime.minute,
        tzDateTime.second,
        tzDateTime.millisecond,
      );
    } catch (e) {
      print('[TodayMedicationStatus] Failed to lookup timezone $timezoneIana: $e');
      return utcTime.toLocal();
    }
  }

  // Convert current time to device's timezone for consistent date comparison
  final nowInDeviceTimezone = convertToDeviceTimezone(now);
  
  final todayDoses = deviceState.bins
      .where((bin) => bin.scheduledTime != null && _isToday(bin.scheduledTime!, nowInDeviceTimezone))
      .map((bin) {
        // Convert UTC time to device's timezone
        final localScheduledTime = convertToDeviceTimezone(bin.scheduledTime!);
        return TodayDose(
          binId: bin.id,
          scheduledTime: localScheduledTime,
          status: bin.status,
          medicationIds: const [],
          takenAtTime: null,
        );
      })
      .toList();

  // Sort by scheduled time
  final sortedDoses = List<TodayDose>.from(todayDoses)
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  // Separate into upcoming and past based on status
  final upcomingDoses = sortedDoses.where((dose) => dose.isUpcoming()).toList();
  final pastDoses = sortedDoses.where((dose) => dose.isPast()).toList();

  return TodayMedicationStatus(
    upcomingDoses: upcomingDoses,
    pastDoses: pastDoses,
    totalDosesScheduled: todayDoses.length,
  );
}

/// Helper to check if a DateTime is today
bool _isToday(DateTime date, DateTime now) {
  return date.year == now.year && date.month == now.month && date.day == now.day;
}
