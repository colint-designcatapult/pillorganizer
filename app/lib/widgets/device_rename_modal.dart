import 'package:app/api/device.dart';
import 'package:app/main.dart';
import 'package:app/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../provider/selected_device_provider.dart';
import 'basic_page.dart';

class ChangeDeviceNameDialog extends StatefulWidget {
  final DeviceUser? device;

  const ChangeDeviceNameDialog({super.key, this.device});

  @override
  State<StatefulWidget> createState() => _ChangeDeviceNameDialogState();
}

class _ChangeDeviceNameDialogState extends State<ChangeDeviceNameDialog> {
  final _formKey = GlobalKey<FormState>();
  bool enableOK = false;
  String? value;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: KeyboardDismissWrapper(
          child: Form(
        key: _formKey,
        child: FormSubmitCallback(
          callback: _onSubmit,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12).r,
            ),
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        PhosphorIconsBold.x,
                        size: 20.h,
                      ),
                      color: const Color(0XFF101828),
                    ),
                  ],
                ),
                Icon(
                  PhosphorIconsRegular.hardDrives,
                  size: 48.h,
                ),
                SizedBox(height: 8.h),
                Text(
                  AppLocalizations.of(context)!.changeDeviceName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                  child: Text(
                    AppLocalizations.of(context)!.changeDeviceNamePrompt,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                  child: BasicPageTextFormField(
                      labelText: widget.device?.name ??
                          Provider.of<SelectedDeviceProvider>(context,
                                  listen: false)
                              .device
                              ?.name ??
                          AppLocalizations.of(context)!.deviceName,
                      onChanged: (newName) {
                        value = newName;
                      },
                      onFieldSubmitted: (newName) => (value = newName),
                      validator: Validatorless.required(
                          AppLocalizations.of(context)!.deviceNameRequired)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 24.h),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12).r,
                              border: Border.all(
                                color: const Color(0xFF206B8B),
                                width: 1.w,
                              ),
                            ),
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.genericCancel,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                          color: const Color(0xFF206B8B)),
                                ))),
                      )),
                      SizedBox(width: 12.w),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          _onSubmit();
                        },
                        child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF206B8B),
                              borderRadius: BorderRadius.circular(12).r,
                              border: Border.all(
                                color: const Color(0xFF206B8B),
                                width: 1.w,
                              ),
                            ),
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(AppLocalizations.of(context)!.save,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                        )))),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _save().then((value) => Navigator.of(context).pop());
    }
  }

  Future<void> _save() async {
    if (value != null) {
      final deviceToUpdate = widget.device ??
          Provider.of<SelectedDeviceProvider>(context, listen: false).device;

      if (deviceToUpdate != null) {
        final deviceProvider =
            Provider.of<DeviceProvider>(context, listen: false);
        await deviceProvider.updateDeviceName(deviceToUpdate.deviceID, value!);
      }
    }
  }
}
