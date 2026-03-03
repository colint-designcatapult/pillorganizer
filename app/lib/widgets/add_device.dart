import 'package:app/screens/provisioning/join_device_screen.dart';
import 'package:app/screens/provisioning/provision.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const double _titleSubtitleSpacing = 8.0;
const double _subtitleContentSpacing = 16.0;

class AddDevice extends StatelessWidget {
  final double titleSize;

  const AddDevice({
    super.key,
    this.titleSize = 16.0,
  });

  void _startProvisioning(BuildContext context) {
    Navigator.of(context).push(ProvisionPage.route(context));
  }

  void _handleJoinExistingDevice(BuildContext context) {
    Navigator.of(context).push(JoinDevicePage.route(context));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.addNewDeviceSection,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: titleSize.h,
              ),
        ),
        SizedBox(height: _titleSubtitleSpacing.h),
        Text(
          AppLocalizations.of(context)!.addNewDeviceSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: _subtitleContentSpacing.h),
        _buildDeviceButtons(context),
      ],
    );
  }

  Widget _buildDeviceButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _startProvisioning(context),
            style: ButtonStyle(
              side: WidgetStateProperty.all<BorderSide>(
                const BorderSide(
                  color: Color(0xFFBFD2DB),
                  width: 2.0,
                ),
              ),
              shape: WidgetStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0).r,
                ),
              ),
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.connectNewDevice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleJoinExistingDevice(context),
            style: ButtonStyle(
              side: WidgetStateProperty.all<BorderSide>(
                const BorderSide(
                  color: Color(0xFFBFD2DB),
                  width: 2.0,
                ),
              ),
              shape: WidgetStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0).r,
                ),
              ),
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.joinExistingDevice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
