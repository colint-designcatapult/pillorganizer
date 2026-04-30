import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/medication_history_provider.dart';

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
  late TextEditingController _monthController;
  late TextEditingController _dayController;
  late TextEditingController _yearController;

  String? _monthError;
  String? _dayError;
  String? _yearError;

  bool _isDayEnabled = false;
  bool _isYearEnabled = false;

  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController();
    _dayController = TextEditingController();
    _yearController = TextEditingController(text: _currentYear.toString());

    // Load initial current month history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicationHistoryProvider(widget.deviceId).notifier).loadCurrentMonth();
    });
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool _isValidMonth(String value) {
    if (value.isEmpty) return false;
    final month = int.tryParse(value);
    return month != null && month >= 1 && month <= 12;
  }

  bool _isValidDay(String value, int month) {
    if (value.isEmpty) return false;
    final day = int.tryParse(value);
    if (day == null || day < 1) return false;

    final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    
    // Check for leap year
    if (month == 2 && _currentYear % 4 == 0 && (_currentYear % 100 != 0 || _currentYear % 400 == 0)) {
      return day <= 29;
    }
    
    return day <= daysInMonth[month - 1];
  }

  bool _isValidYear(String value) {
    if (value.isEmpty || value.length < 4) return false;
    final year = int.tryParse(value);
    return year != null && year >= 2026 && year <= _currentYear;
  }

  void _onMonthChanged(String value) {
    setState(() {
      _monthError = null;
      _dayController.clear();
      _yearController.text = _currentYear.toString();
      _isDayEnabled = false;
      _isYearEnabled = false;

      if (value.isNotEmpty && !_isValidMonth(value)) {
        _monthError = 'Month must be between 1 and 12';
      }

      if (_isValidMonth(value)) {
        _isDayEnabled = true;
      }
    });
  }

  void _onDayChanged(String value) {
    setState(() {
      _dayError = null;
      _yearController.text = _currentYear.toString();
      _isYearEnabled = false;

      if (value.isNotEmpty) {
        final month = int.tryParse(_monthController.text);
        if (month != null && !_isValidDay(value, month)) {
          _dayError = 'Invalid day for the selected month';
        }
      }

      if (_isValidMonth(_monthController.text) && _isValidDay(value, int.parse(_monthController.text))) {
        _isYearEnabled = true;
      }
    });
  }

  void _onYearChanged(String value) {
    setState(() {
      _yearError = null;

      if (value.length == 4) {
        if (!_isValidYear(value)) {
          _yearError = 'Invalid year';
        }
      }
    });
  }

  bool _isFormValid() {
    return _isValidMonth(_monthController.text) &&
        _isValidDay(_dayController.text, int.parse(_monthController.text)) &&
        _isValidYear(_yearController.text) &&
        _monthError == null &&
        _dayError == null &&
        _yearError == null;
  }

  void _submitDate() {
    if (_isFormValid()) {
      final month = int.parse(_monthController.text);
      final day = int.parse(_dayController.text);
      final year = int.parse(_yearController.text);

      // Trigger the data load
      ref.read(medicationHistoryProvider(widget.deviceId).notifier)
          .loadMonth(year, month, day: day);

      // Close the date entry dialog
      Navigator.of(context).pop();

      // Clear the form for next use
      _monthController.clear();
      _dayController.clear();
      _yearController.text = _currentYear.toString();
      setState(() {
        _isDayEnabled = false;
        _isYearEnabled = false;
        _monthError = null;
        _dayError = null;
        _yearError = null;
      });
    }
  }

  void _clearDate() {
    ref.read(medicationHistoryProvider(widget.deviceId).notifier).clearDate();
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
                          'Enter Date',
                          onPressed: _showDateEntryForm,
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
            final doseDate = (dose.scheduledTime ?? dose.resolvedTime);
            return doseDate.day == selectedDay;
          })
          .toList();
    } else {
      // When showing current month: limit to 50 results
      filteredHistory = history.take(50).toList();
    }

    if (filteredHistory.isEmpty) {
      return Center(child: Text('No medication history found'));
    }

    // Group history by date
    final groupedByDate = <String, List<DoseHistoryDto>>{};
    for (var dose in filteredHistory) {
      final dateKey = DateFormat('MMMM d, yyyy').format(dose.scheduledTime ?? dose.resolvedTime);
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
            ...doses.map((dose) {
              final doseTime = DateFormat('h:mm a').format(dose.scheduledTime ?? dose.resolvedTime);
              final status = dose.finalStatus;

              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      doseTime,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: status == 'TAKEN'
                            ? Colors.green
                            : status == 'MISSED'
                                ? Colors.red
                                : Colors.orange,
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

  void _showDateEntryForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter Date',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Month', style: TextStyle(fontSize: 12.sp)),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _monthController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 2,
                                  onChanged: (value) {
                                    _onMonthChanged(value);
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'MM',
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Day', style: TextStyle(fontSize: 12.sp)),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _dayController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 2,
                                  enabled: _isDayEnabled,
                                  onChanged: (value) {
                                    _onDayChanged(value);
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'DD',
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                    filled: !_isDayEnabled,
                                    fillColor: !_isDayEnabled ? Colors.grey[200] : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Year', style: TextStyle(fontSize: 12.sp)),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _yearController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  enabled: _isYearEnabled,
                                  onChanged: (value) {
                                    _onYearChanged(value);
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'YYYY',
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                    filled: !_isYearEnabled,
                                    fillColor: !_isYearEnabled ? Colors.grey[200] : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (_monthError != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _monthError!,
                            style: TextStyle(color: Colors.red, fontSize: 12.sp),
                          ),
                        ),
                      if (_dayError != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _dayError!,
                            style: TextStyle(color: Colors.red, fontSize: 12.sp),
                          ),
                        ),
                      if (_yearError != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _yearError!,
                            style: TextStyle(color: Colors.red, fontSize: 12.sp),
                          ),
                        ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF206B8B),
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isFormValid() ? _submitDate : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid() ? Color(0xFF206B8B) : Colors.grey[300],
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                            ),
                            child: Text(
                              'Enter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
