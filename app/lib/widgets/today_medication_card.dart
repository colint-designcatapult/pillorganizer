import 'package:app/apiv2/models/device.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/today_medication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TodayMedicationCard extends ConsumerWidget {
  const TodayMedicationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show the card if a device is connected
    final activeDevice = ref.watch(activeDeviceProvider);
    if (activeDevice == null) {
      return SizedBox.shrink();
    }

    // Watch for loading state (same as Pillbox pattern)
    final deviceStateAsync = ref.watch(deviceStateProvider);
    // Watch for the computed medication data
    final medicationStatus = ref.watch(todayMedicationStatusProvider);

    return deviceStateAsync.when(
      loading: () => _buildLoadingCard(context),
      error: (e, st) => _buildErrorCard(context),
      data: (_) => _buildCard(context, medicationStatus),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.errorPromptTryAgain,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, TodayMedicationStatus status) {
    if (status.totalDosesScheduled == 0) {
      return _buildNoMedicationPlanned(context);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppLocalizations.of(context)!.todayMedicationTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),

          // Summary line
          _buildSummary(context, status),
          SizedBox(height: 16.h),

          // Upcoming section
          _buildSection(
            context,
            title: AppLocalizations.of(context)!.upcoming,
            doses: status.upcomingDoses,
            isPast: false,
          ),
          SizedBox(height: 12.h),

          // Past section
          _buildSection(
            context,
            title: AppLocalizations.of(context)!.past,
            doses: status.pastDoses,
            isPast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNoMedicationPlanned(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.todayMedicationTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.noMedicationLeft,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, TodayMedicationStatus status) {
    // Only TAKEN doses count as taken
    final taken = status.dosesTaken;
    // Only upcoming doses are remaining
    final remaining = status.upcomingDoses.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$taken/${status.totalDosesScheduled}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF206B8B),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.dosesTakenLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              Text(
                AppLocalizations.of(context)!.dosesRemaining,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            ),
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<TodayDose> doses,
    required bool isPast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        if (doses.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              isPast
                  ? AppLocalizations.of(context)!.noneTakenYet
                  : AppLocalizations.of(context)!.noneScheduled,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Column(
            children: doses.map((dose) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: _buildDoseItem(context, dose, isPast),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDoseItem(BuildContext context, TodayDose dose, bool isPast) {
    final timeStr = DateFormat('h:mm a').format(dose.scheduledTime);
    final statusText = _getDoseStatusText(context, dose.status);
    final statusColor = _getDoseStatusColor(dose.status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            timeStr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (isPast)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _getDoseStatusText(BuildContext context, BinStatus status) {
    switch (status) {
      case BinStatus.taken:
        return AppLocalizations.of(context)!.doseStatusTaken;
      case BinStatus.missed:
        return AppLocalizations.of(context)!.doseStatusMissed;
      case BinStatus.pending:
      case BinStatus.take_now:
        return AppLocalizations.of(context)!.doseStatusPending;
      default:
        return AppLocalizations.of(context)!.doseStatusNoRecord;
    }
  }

  Color _getDoseStatusColor(BinStatus status) {
    switch (status) {
      case BinStatus.taken:
        return Colors.green;
      case BinStatus.missed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
