import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/service/time_service.dart';

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
  final bool showCalendar;

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
    this.showCalendar = true,
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
    bool? showCalendar,
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
      showCalendar: showCalendar ?? this.showCalendar,
    );
  }
}

@riverpod
class MedicationHistory extends _$MedicationHistory {
  static const int debounceDelayMs = 750;
  Timer? _debounceTimer;

  @override
  MedicationHistoryState build(String deviceId) {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    });
    final now = DateTime.now();
    // Initialize with current month data visible, calendar hidden.
    // Loading is triggered explicitly by the UI/caller when needed.
    return MedicationHistoryState(
      calendarViewYear: now.year,
      calendarViewMonth: now.month,
      showCalendar: false,
    );
  }

  Future<void> loadCurrentMonth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: now.year,
        month: now.month,
      );
      state = state.copyWith(
        history: history,
        isLoading: false,
        isDateSelected: false,
        selectedYear: null,
        selectedMonth: null,
        selectedDay: null,
      );
    } catch (e, st) {

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load medication history: ${e.toString()}',
      );
    }
  }

  Future<void> loadMonth(int year, int month, {int? day}) async {
    state = state.copyWith(isLoading: true, error: null);
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
        isDateSelected: day != null,
        selectedYear: year,
        selectedMonth: month,
        selectedDay: day,
      );
    } catch (e, st) {

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
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: year,
        month: month,
      );

      // Extract available days from the history, but only keep dates that
      // still belong to the requested calendar month after conversion.
      final TimeService timeService = TimeService();
      final Set<int> availableDays = history
          .map((item) => timeService.timeToLocal(item.scheduledTime ?? item.resolvedTime))
          .where((localTime) => localTime.year == year && localTime.month == month)
          .map((localTime) => localTime.day)
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
    final now = DateTime.now();
    int newYear = state.calendarViewYear;
    int newMonth = state.calendarViewMonth + 1;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    // Don't allow navigation beyond current month
    if (newYear > now.year || (newYear == now.year && newMonth > now.month)) {
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
    state = state.copyWith(showCalendar: true);
  }
}
