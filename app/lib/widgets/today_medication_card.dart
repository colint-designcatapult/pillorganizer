import 'package:app/apiv2/models/device.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/provider/device_provider.dart';
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
            AppLocalizations.of(context)!.noMedicationScheduled,
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
            color: Colors.black,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        if (isPast || dose.status == BinStatus.take_now)
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
        SizedBox(width: 8.w),
        _buildDoseCommandButton(context, dose),
      ],
    );
  }

  Widget _buildDoseCommandButton(BuildContext context, TodayDose dose) {
    // If dose is taken, show reset button. If pending/take_now/missed, show taken button.
    if (dose.status == BinStatus.taken) {
      return _DoseCommandButton(
        label: AppLocalizations.of(context)!.commandMarkReset,
        icon: Icons.undo,
        color: Colors.grey,
        binId: dose.binId,
        isTaken: false,
      );
    } else if (dose.status == BinStatus.pending ||
        dose.status == BinStatus.take_now ||
        dose.status == BinStatus.missed ||
        dose.status == BinStatus.noRecord) {
      return _DoseCommandButton(
        label: AppLocalizations.of(context)!.commandMarkTaken,
        icon: Icons.check,
        color: Colors.green,
        binId: dose.binId,
        isTaken: true,
      );
    }
    return const SizedBox.shrink();
  }

  String _getDoseStatusText(BuildContext context, BinStatus status) {
    switch (status) {
      case BinStatus.taken:
        return AppLocalizations.of(context)!.doseStatusTaken;
      case BinStatus.missed:
        return AppLocalizations.of(context)!.doseStatusMissed;
      case BinStatus.take_now:
        return AppLocalizations.of(context)!.doseStatusTakeNow;
      case BinStatus.pending:
        return AppLocalizations.of(context)!.doseStatusPending;
      default:
        return AppLocalizations.of(context)!.doseStatusNoRecord;
    }
  }

  Color _getDoseStatusColor(BinStatus status) {
    switch (status) {
      case BinStatus.taken:
      case BinStatus.take_now:
        return Colors.green;
      case BinStatus.missed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DoseCommandButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int binId;
  final bool isTaken;

  const _DoseCommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.binId,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    if (activeDevice == null || !activeDevice.primaryUser) return const SizedBox.shrink();

    return SizedBox(
      height: 28.h,
      child: TextButton.icon(
        onPressed: () => _sendCommand(context, ref, activeDevice.id),
        icon: Icon(icon, size: 14.h, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _sendCommand(BuildContext context, WidgetRef ref, String deviceId) async {
    try {
      if (isTaken) {
        await ref.read(deviceListProvider.notifier).sendBinTakenCommand(deviceId, binId);
      } else {
        await ref.read(deviceListProvider.notifier).sendBinResetCommand(deviceId, binId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commandSent)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commandFailed(e.toString()))),
        );
      }
    }
  }
}
