import 'package:app/main.dart';
import 'package:app/provider/deep_link_provider.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PatientConfirmationPage extends StatefulWidget {
  const PatientConfirmationPage({Key? key}) : super(key: key);

  @override
  State<PatientConfirmationPage> createState() =>
      _PatientConfirmationPageState();
}

class _PatientConfirmationPageState extends State<PatientConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final deepLinkProvider =
          Provider.of<DeepLinkProvider>(context, listen: false);

      if (deepLinkProvider.patientId == null) {
        throw Exception('No patient ID available');
      }

      String birthDateString = '';
      if (_selectedDateOfBirth != null) {
        birthDateString =
            '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}';
      }

      await deepLinkProvider.validateAndLinkTakecarePatient(
        patientId: deepLinkProvider.patientId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: birthDateString,
      );

      if (mounted) {
        await _showSuccessDialog();
      }
    } catch (error) {
      if (mounted) {
        await _showGenericErrorDialog();
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary, size: 48),
          title: Text(AppLocalizations.of(context)!.verificationSuccessful),
          content: Text(
            AppLocalizations.of(context)!.accountLinkedSuccessfully,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final deepLinkProvider =
                      Provider.of<DeepLinkProvider>(context, listen: false);
                  deepLinkProvider.clearPatientId();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/index', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  AppLocalizations.of(context)!.genericContinue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGenericErrorDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.error,
              color: Theme.of(context).colorScheme.error, size: 48),
          title: Text(AppLocalizations.of(context)!.verificationFailed),
          content: Text(
            AppLocalizations.of(context)!.invalidInformationProvided,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  AppLocalizations.of(context)!.genericOK,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeepLinkProvider>(
      builder: (context, deepLinkProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFBFD2DB),
          body: KeyboardDismissWrapper(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 100.h),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        AppLocalizations.of(context)!.welcomeCabinet,
                        textAlign: TextAlign.left,
                        softWrap: true,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 32.h),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Material(
                        elevation: 4,
                        shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                        borderRadius: BorderRadius.all(Radius.circular(12.r)),
                        child: Container(
                          padding: EdgeInsets.all(20.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.r)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .patientIdentityConfirmation,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.firstName,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterFirstName;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.lastName,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterLastName;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dateOfBirthController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .dateOfBirth,
                                    border: const OutlineInputBorder(),
                                    prefixIcon:
                                        const Icon(Icons.calendar_today),
                                    suffixIcon:
                                        const Icon(Icons.arrow_drop_down),
                                    hintText: AppLocalizations.of(context)!
                                        .selectDateOfBirth,
                                  ),
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDateOfBirth ??
                                          DateTime.now().subtract(const Duration(
                                              days: 365 *
                                                  25)), // Use selected date or default to 25 years ago
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDateOfBirth = picked;
                                        _dateOfBirthController.text =
                                            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (_selectedDateOfBirth == null) {
                                      return AppLocalizations.of(context)!
                                          .pleaseSelectDateOfBirth;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                Consumer<DeepLinkProvider>(
                                  builder: (context, deepLinkProvider, child) {
                                    return ElevatedButton(
                                      onPressed: deepLinkProvider.isValidating
                                          ? null
                                          : _verifyAccount,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: deepLinkProvider.isValidating
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              AppLocalizations.of(context)!
                                                  .verifyAccount,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Consumer<DeepLinkProvider>(
                                  builder: (context, deepLinkProvider, child) {
                                    return OutlinedButton(
                                      onPressed: deepLinkProvider.isValidating
                                          ? null
                                          : () {
                                              deepLinkProvider.clearPatientId();
                                              Navigator.of(context)
                                                  .pushNamedAndRemoveUntil(
                                                      '/index',
                                                      (route) => false);
                                            },
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .genericCancel,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
