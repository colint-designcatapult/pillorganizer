import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/tenant_providers.dart';

part 'medication_history_provider.g.dart';

class MedicationHistoryState {
  final List<DoseHistoryDto>? history;
  final bool isLoading;
  final String? error;
  final bool isDateSelected;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;

  MedicationHistoryState({
    this.history,
    this.isLoading = false,
    this.error,
    this.isDateSelected = false,
    this.selectedYear,
    this.selectedMonth,
    this.selectedDay,
  });

  MedicationHistoryState copyWith({
    List<DoseHistoryDto>? history,
    bool? isLoading,
    String? error,
    bool? isDateSelected,
    int? selectedYear,
    int? selectedMonth,
    int? selectedDay,
  }) {
    return MedicationHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDateSelected: isDateSelected ?? this.isDateSelected,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

@riverpod
class MedicationHistory extends _$MedicationHistory {
  @override
  MedicationHistoryState build(String deviceId) {
    return MedicationHistoryState();
  }

  Future<void> loadCurrentMonth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final apiClient = ref.watch(activeTenantClientProvider);
      if (apiClient == null) {
        throw Exception('No active tenant client available');
      }
      final urlCall = 'Device: $deviceId, Year: ${now.year}, Month: ${now.month}';
      print('DEBUG: Making API call: $urlCall');
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: now.year,
        month: now.month,
      );
      print('DEBUG: Received ${history.length} records from API');
      state = state.copyWith(
        history: history,
        isLoading: false,
        isDateSelected: false,
        selectedYear: null,
        selectedMonth: null,
        selectedDay: null,
      );
    } catch (e, st) {
      print('DEBUG: Error loading medication history: $e');
      print('DEBUG: Stack trace: $st');
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
      final urlCall = 'Device: $deviceId, Year: $year, Month: $month, Day: $day';
      print('DEBUG: Making API call: $urlCall');
      final history = await apiClient.getAdherenceHistory(
        deviceId,
        year: year,
        month: month,
      );
      print('DEBUG: Received ${history.length} records from API for specific date');
      state = state.copyWith(
        history: history,
        isLoading: false,
        isDateSelected: day != null,
        selectedYear: year,
        selectedMonth: month,
        selectedDay: day,
      );
    } catch (e, st) {
      print('DEBUG: Error loading medication history for specific date: $e');
      print('DEBUG: Stack trace: $st');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load medication history for selected date: ${e.toString()}',
      );
    }
  }

  void clearDate() {
    loadCurrentMonth();
  }
}
