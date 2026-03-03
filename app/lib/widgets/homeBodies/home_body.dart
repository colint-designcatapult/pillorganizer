import 'package:app/provider/time_provider.dart';
import 'package:app/widgets/dose_period_area.dart';
import 'package:app/widgets/pillbox/pill_box.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeBody extends ConsumerWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minuteBasedTime = ref.watch(minuteBasedTimeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(40.0).r,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Builder(
                    builder: (context) {
                      return Text(
                        AppLocalizations.of(context)!.localeName == 'fr'
                            ? DateFormat('EEEE, d MMMM', 'fr')
                                .format(minuteBasedTime)
                            : DateFormat('EEEE, d MMMM', 'en')
                                .format(minuteBasedTime),
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(child: Pillbox()),
              DosePeriodArea(),
            ],
          ),
        ),
      ),
    );
  }
}
