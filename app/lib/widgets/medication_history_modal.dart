import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/medication_history_provider.dart';
import 'package:app/provider/schedule_provider.dart';

class MedicationHistoryModal extends ConsumerStatefulWidget {
  final String deviceId;

  const MedicationHistoryModal({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<MedicationHistoryModal> createState() =>
      _MedicationHistoryModalState();
}

class _MedicationHistoryModalState extends ConsumerState<MedicationHistoryModal> {
  /// Converts UTC time to device's timezone
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
  void initState() {
    super.initState();
    // Load initial current month history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicationHistoryProvider(widget.deviceId).notifier).loadCurrentMonth();
    });
  }

  void _clearDate() {
    ref.read(medicationHistoryProvider(widget.deviceId).notifier).clearDate();
  }

  void _showCalendarDialog() {
    ref.read(medicationHistoryProvider(widget.deviceId).notifier).openCalendarDialog();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CalendarDialog(deviceId: widget.deviceId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(medicationHistoryProvider(widget.deviceId));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: 24.sp),
                    ),
                  ),
                ),
                // Buttons row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildButton(
                          'Select Date',
                          onPressed: _showCalendarDialog,
                          isBlue: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildButton(
                          'Clear Date',
                          onPressed: historyState.isDateSelected ? _clearDate : null,
                          isBlue: historyState.isDateSelected,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // History header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    historyState.isDateSelected
                        ? 'Selected Date (${historyState.selectedMonth}/${historyState.selectedDay}/${historyState.selectedYear})'
                        : 'This Month',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // History content
                Expanded(
                  child: historyState.isLoading
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : historyState.error != null
                          ? Center(
                              child: Text(historyState.error!),
                            )
                          : historyState.history == null ||
                                  historyState.history!.isEmpty
                              ? Center(
                                  child: Text('No medication history found'),
                                )
                              : _buildHistoryList(historyState.history!),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, {required VoidCallback? onPressed, required bool isBlue}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey[300] : (isBlue ? Color(0xFF206B8B) : Colors.white),
        foregroundColor: onPressed == null ? Colors.grey : (isBlue ? Colors.white : Colors.black),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Text(label, style: TextStyle(fontSize: 14.sp)),
    );
  }

  Widget _buildHistoryList(List<DoseHistoryDto> history) {
    final state = ref.watch(medicationHistoryProvider(widget.deviceId));

    // Filter and limit history based on view mode
    List<DoseHistoryDto> filteredHistory = history;

    if (state.isDateSelected && state.selectedDay != null) {
      // When a specific day is selected: filter to that day, show all results
      final selectedDay = state.selectedDay!;
      filteredHistory = history
          .where((dose) {
            // Get device timezone for date comparison
            final scheduleAsync = ref.watch(scheduleProvider);
            final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
            final doseDeviceTime = convertToDeviceTimezone(dose.scheduledTime ?? dose.resolvedTime, timezoneIana);
            return doseDeviceTime.day == selectedDay;
          })
          .toList();
    } else {
      // When showing current month: limit to 50 results
      filteredHistory = history.take(50).toList();
    }

    if (filteredHistory.isEmpty) {
      return Center(child: Text('No medication history found'));
    }

    // Group history by date (using device timezone)
    final groupedByDate = <String, List<DoseHistoryDto>>{};
    // Get device timezone
    final scheduleAsync = ref.watch(scheduleProvider);
    final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
    
    for (var dose in filteredHistory) {
      final doseDeviceTime = convertToDeviceTimezone(dose.scheduledTime ?? dose.resolvedTime, timezoneIana);
      final dateKey = DateFormat('MMMM d, yyyy').format(doseDeviceTime);
      groupedByDate.putIfAbsent(dateKey, () => []).add(dose);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: groupedByDate.length,
      itemBuilder: (context, index) {
        final dateKey = groupedByDate.keys.elementAt(index);
        final doses = groupedByDate[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateKey,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            ...doses.reversed.map((dose) {
              final doseDateTime = dose.scheduledTime ?? dose.resolvedTime;
              // Get device timezone for time conversion
              final scheduleAsync = ref.watch(scheduleProvider);
              final timezoneIana = scheduleAsync.value?.effectiveTimezoneIana;
              final doseDeviceTime = convertToDeviceTimezone(doseDateTime, timezoneIana);
              final doseTime = DateFormat('h:mm a').format(doseDeviceTime);
              final status = dose.finalStatus;
              
              // Determine display text and color based on status
              String displayStatus;
              Color statusColor;
              
              if (status == 'TAKEN') {
                displayStatus = 'TAKEN';
                statusColor = Colors.green;
              } else if (status == 'MISSED') {
                displayStatus = 'MISSED';
                statusColor = Colors.red;
              } else if (status == 'TAKE_NOW') {
                displayStatus = 'TAKE NOW';
                statusColor = Colors.green;
              } else {
                displayStatus = status;
                statusColor = Colors.grey;
              }
              
              final statusBackgroundColor = statusColor.withOpacity(0.15);

              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Text(
                      doseTime,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    SizedBox(width: 32.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: statusBackgroundColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 12.h),
          ],
        );
      },
    );
  }
}

// Separate Calendar Dialog Widget
class _CalendarDialog extends ConsumerWidget {
  final String deviceId;

  const _CalendarDialog({required this.deviceId});

  bool _isCurrentMonth(MedicationHistoryState historyState) {
    final now = DateTime.now();
    return historyState.calendarViewYear == now.year && historyState.calendarViewMonth == now.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(medicationHistoryProvider(deviceId));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar widget
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildCalendarWidget(historyState, context, ref),
              ),
            ),
            SizedBox(height: 24.h),
            // Cancel button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF206B8B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWidget(
    MedicationHistoryState historyState,
    BuildContext context,
    WidgetRef ref,
  ) {
    final now = DateTime.now();
    final focusedDay = DateTime(historyState.calendarViewYear, historyState.calendarViewMonth);

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Month navigation header
            SizedBox(
              height: 56.h,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF206B8B),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: historyState.isLoadingCalendarMonth
                        ? null
                        : () => ref
                            .read(medicationHistoryProvider(deviceId).notifier)
                            .goToPreviousMonth(),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(focusedDay),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _isCurrentMonth(historyState) ? Colors.grey[600] : Colors.white,
                    ),
                    onPressed: (historyState.isLoadingCalendarMonth || _isCurrentMonth(historyState))
                        ? null
                        : () => ref
                            .read(medicationHistoryProvider(deviceId).notifier)
                            .goToNextMonth(),
                  ),
                ],
              ),
            ),
            ),
            SizedBox(height: 13.h),
            // Calendar - fixed height to accommodate 6 weeks
            SizedBox(
              height: 380.h,
              child: historyState.isLoadingCalendarMonth
                  ? Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TableCalendar(
                      focusedDay: focusedDay,
                      firstDay: DateTime(2000),
                      lastDay: DateTime(now.year, now.month + 1, 0),
                      calendarFormat: CalendarFormat.month,
                      availableGestures: AvailableGestures.none,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (historyState.daysWithDataInMonth.contains(selectedDay.day)) {
                          ref
                              .read(medicationHistoryProvider(deviceId).notifier)
                              .selectDateFromCalendar(selectedDay);
                          Navigator.of(context).pop();
                        }
                      },
                      enabledDayPredicate: (day) {
                        // Only enable days that are in the current month view AND have data
                        return day.month == focusedDay.month &&
                            day.year == focusedDay.year &&
                            historyState.daysWithDataInMonth.contains(day.day);
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF206B8B),
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        disabledTextStyle: TextStyle(
                          color: Colors.grey[400],
                        ),
                        weekendTextStyle: TextStyle(
                          color: Color(0xFF206B8B),
                          fontWeight: FontWeight.w600,
                        ),
                        defaultTextStyle: TextStyle(
                          color: Color(0xFF206B8B),
                          fontWeight: FontWeight.w600,
                        ),
                        outsideTextStyle: TextStyle(
                          color: Colors.grey[400],
                        ),
                        markerDecoration: BoxDecoration(
                          color: Color(0xFF206B8B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: false,
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      eventLoader: (day) {
                        // Show markers on days with data
                        return historyState.daysWithDataInMonth.contains(day.day) ? [day] : [];
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
