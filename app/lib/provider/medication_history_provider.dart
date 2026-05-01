import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:timezone/timezone.dart' as tz;

part 'medication_history_provider.g.dart';

class MedicationHistoryState {
  final List<DoseHistoryDto>? history;
  final bool isLoading;
  final String? error;
  final bool isDateSelected;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;
  final int calendarViewYear;
  final int calendarViewMonth;
  final Set<int> daysWithDataInMonth;
  final bool isLoadingCalendarMonth;

  MedicationHistoryState({
    this.history,
    this.isLoading = false,
    this.error,
    this.isDateSelected = false,
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
    this.calendarViewYear = 0,
    this.calendarViewMonth = 0,
    this.daysWithDataInMonth = const {},
    this.isLoadingCalendarMonth = false,
  });

  MedicationHistoryState copyWith({
    List<DoseHistoryDto>? history,
    bool? isLoading,
    String? error,
    bool? isDateSelected,
    int? selectedYear,
    int? selectedMonth,
    int? selectedDay,
    int? calendarViewYear,
    int? calendarViewMonth,
    Set<int>? daysWithDataInMonth,
    bool? isLoadingCalendarMonth,
  }) {
    return MedicationHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDateSelected: isDateSelected ?? this.isDateSelected,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      calendarViewYear: calendarViewYear ?? this.calendarViewYear,
      calendarViewMonth: calendarViewMonth ?? this.calendarViewMonth,
      daysWithDataInMonth: daysWithDataInMonth ?? this.daysWithDataInMonth,
      isLoadingCalendarMonth: isLoadingCalendarMonth ?? this.isLoadingCalendarMonth,
    );
  }
}

@riverpod
class MedicationHistory extends _$MedicationHistory {
  static const int debounceDelayMs = 750;
  Timer? _debounceTimer;

  /// Converts UTC time to device's timezone (matching todayMedicationProvider approach)
  DateTime convertToDeviceTimezone(DateTime utcTime, String? timezoneIana) {
    if (timezoneIana == null || timezoneIana.isEmpty) {
      return utcTime.toLocal();
    }
    try {
      final timezone = tz.getLocation(timezoneIana);
      final tzDateTime = tz.TZDateTime.from(utcTime, timezone);
      return tzDateTime;
    } catch (e) {
      return utcTime.toLocal();
    }
  }

  @override
  MedicationHistoryState build(String deviceId) {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    });
    final now = DateTime.now();
    // Initialize with current month data visible, calendar hidden.
    // Load current month data on initialization
    Future.microtask(() => loadCurrentMonth());
    return MedicationHistoryState(
      calendarViewYear: now.year,
      calendarViewMonth: now.month,
    );
  }

  Future<void> loadCurrentMonth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get device's timezone from schedule
      final scheduleAsync = ref.watch(scheduleProvider);
      final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
      
      // Get current time in device timezone
      final now = DateTime.now().toUtc();
      final nowInDeviceTimezone = convertToDeviceTimezone(now, timezoneIana);
      
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: nowInDeviceTimezone.year,
        month: nowInDeviceTimezone.month,
      );
      state = state.copyWith(
        history: history,
        isLoading: false,
        isDateSelected: false,
        selectedYear: null,
        selectedMonth: null,
        selectedDay: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load medication history: ${e.toString()}',
      );
    }
  }

  Future<void> loadMonth(int year, int month, {int? day}) async {
    // Update selected date immediately for UI consistency
    state = state.copyWith(
      isLoading: true,
      error: null,
      isDateSelected: day != null,
      selectedYear: year,
      selectedMonth: month,
      selectedDay: day,
    );
    try {
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: year,
        month: month,
      );
      state = state.copyWith(
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load medication history for selected date: ${e.toString()}',
      );
    }
  }

  void clearDate() {
    loadCurrentMonth();
  }

  Future<void> loadCalendarMonth(int year, int month) async {
    state = state.copyWith(
      isLoadingCalendarMonth: true,
      calendarViewYear: year,
      calendarViewMonth: month,
    );
    try {
      // Get device's timezone from schedule
      final scheduleAsync = ref.watch(scheduleProvider);
      final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
      
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: year,
        month: month,
      );

      // Extract available days from the history (using device timezone)
      final Set<int> availableDays = history
          .map((item) {
            final utcTime = item.scheduledTime ?? item.resolvedTime;
            final deviceTime = convertToDeviceTimezone(utcTime, timezoneIana);
            return deviceTime;
          })
          .where((deviceTime) => deviceTime.year == year && deviceTime.month == month)
          .map((deviceTime) => deviceTime.day)
          .toSet();
      state = state.copyWith(
        daysWithDataInMonth: availableDays,
        isLoadingCalendarMonth: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCalendarMonth: false,
        daysWithDataInMonth: const {},
      );
    }
  }

  void selectDateFromCalendar(DateTime selectedDate) {
    loadMonth(selectedDate.year, selectedDate.month, day: selectedDate.day);
  }

  void goToNextMonth() {
    // Get device's timezone from schedule
    final scheduleAsync = ref.watch(scheduleProvider);
    final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
    
    final now = DateTime.now().toUtc();
    final nowInDeviceTimezone = convertToDeviceTimezone(now, timezoneIana);
    
    int newYear = state.calendarViewYear;
    int newMonth = state.calendarViewMonth + 1;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    // Don't allow navigation beyond current month
    if (newYear > nowInDeviceTimezone.year || (newYear == nowInDeviceTimezone.year && newMonth > nowInDeviceTimezone.month)) {
      return;
    }
    _updateMonthWithDebounce(newYear, newMonth);
  }

  void goToPreviousMonth() {
    int newYear = state.calendarViewYear;
    int newMonth = state.calendarViewMonth - 1;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    _updateMonthWithDebounce(newYear, newMonth);
  }

  void _updateMonthWithDebounce(int year, int month) {
    // Get device's timezone from schedule for month change
    final scheduleAsync = ref.watch(scheduleProvider);
    final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
    
    // Check month boundary in device timezone (not phone timezone)
    final now = DateTime.now().toUtc();
    final nowInDeviceTimezone = convertToDeviceTimezone(now, timezoneIana);
    
    // Don't allow navigation beyond current month
    if (year > nowInDeviceTimezone.year || (year == nowInDeviceTimezone.year && month > nowInDeviceTimezone.month)) {
      return;
    }
    
    // Update UI immediately and clear previous month's days
    state = state.copyWith(
      calendarViewYear: year,
      calendarViewMonth: month,
      daysWithDataInMonth: const {},
    );

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Schedule data load after debounce delay
    _debounceTimer = Timer(Duration(milliseconds: debounceDelayMs), () {
      loadCalendarMonth(year, month);
    });
  }

  void openCalendarDialog() {
    // Ensure calendar data is loaded for current month view
    if (state.daysWithDataInMonth.isEmpty && !state.isLoadingCalendarMonth) {
      loadCalendarMonth(state.calendarViewYear, state.calendarViewMonth);
    }

  }
}
