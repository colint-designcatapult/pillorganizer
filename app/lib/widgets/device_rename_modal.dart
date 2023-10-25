import 'package:app/api/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/selected_device_provider.dart';
import 'basic_page.dart';

class ChangeDeviceNameDialog extends StatefulWidget {
  const ChangeDeviceNameDialog({super.key});

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
      insetPadding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: FormSubmitCallback(
          callback: _onSubmit,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
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
                      icon: const Icon(PhosphorIcons.x_bold),
                      color: const Color(0XFF101828),
                    ),
                  ],
                ),
                const Icon(
                  PhosphorIcons.hard_drives,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.changeDeviceName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    AppLocalizations.of(context)!.changeDeviceNamePrompt,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: BasicPageTextFormField(
                      labelText: Provider.of<SelectedDeviceProvider>(context,
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF206B8B),
                                width: 1.0,
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
                      const SizedBox(width: 12),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          _onSubmit();
                        },
                        child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF206B8B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF206B8B),
                                width: 1.0,
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
      ),
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
      await Provider.of<SelectedDeviceProvider>(context, listen: false)
          .updateName(value!)
          .then((value) =>
              Provider.of<DeviceListProvider>(context, listen: false)
                  .refresh());
    }
  }
}
