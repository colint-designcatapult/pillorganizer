import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @addMedications.
  ///
  /// In en, this message translates to:
  /// **'Add Medications'**
  String get addMedications;

  /// No description provided for @addMedicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter in the medications you take so your pill organizer can remind you.'**
  String get addMedicationsSubtitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CabiNET'**
  String get appName;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// No description provided for @addNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Add new device'**
  String get addNewDevice;

  /// No description provided for @addNewDeviceSection.
  ///
  /// In en, this message translates to:
  /// **'Add a new device'**
  String get addNewDeviceSection;

  /// No description provided for @addNewDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the way you want to add a new device'**
  String get addNewDeviceSubtitle;

  /// No description provided for @addPills.
  ///
  /// In en, this message translates to:
  /// **'Add Pills'**
  String get addPills;

  /// No description provided for @addPillsError.
  ///
  /// In en, this message translates to:
  /// **'An error occured trying to add pills, you can still add pills after the onboarding'**
  String get addPillsError;

  /// No description provided for @addPillManually.
  ///
  /// In en, this message translates to:
  /// **'Add Pill Manually'**
  String get addPillManually;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addToList;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already registered'**
  String get alreadyRegistered;

  /// No description provided for @authConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Make sure you are connected to the internet and try again'**
  String get authConnectionError;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authError;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery Level'**
  String get batteryLevel;

  /// No description provided for @bluetoothConnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connected'**
  String get bluetoothConnected;

  /// No description provided for @bluetoothConnecting.
  ///
  /// In en, this message translates to:
  /// **'Scanning bluetooth...'**
  String get bluetoothConnecting;

  /// No description provided for @bluetoothDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth disconnected'**
  String get bluetoothDisconnected;

  /// No description provided for @bluetoothMissingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get bluetoothMissingPermissions;

  /// No description provided for @changeDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Change device name'**
  String get changeDeviceName;

  /// No description provided for @changeDeviceNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter the desired new device name right below:'**
  String get changeDeviceNamePrompt;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current email in order to set up a new one.'**
  String get changeEmailSubtitle;

  /// No description provided for @changeName.
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeName;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password in order to set up a new one.'**
  String get changePasswordSubtitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @validTimeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid time'**
  String get validTimeError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @connectNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect a new device'**
  String get connectNewDevice;

  /// No description provided for @connectionProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection Problem'**
  String get connectionProblem;

  /// No description provided for @connectionProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There was a problem setting up your pill organizer.'**
  String get connectionProblemSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account in order to access your data anytime, anywhere.'**
  String get createAccountSubtitle;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @currentEmail.
  ///
  /// In en, this message translates to:
  /// **'Current Email'**
  String get currentEmail;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// No description provided for @deleteMedicationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteMedicationConfirmation;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInfo;

  /// No description provided for @deviceInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s an overview of your device connection status.'**
  String get deviceInfoSubtitle;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @nameDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Pill organiser name'**
  String get nameDeviceHint;

  /// No description provided for @deviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A device name is required'**
  String get deviceNameRequired;

  /// No description provided for @deviceNewSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up a new device'**
  String get deviceNewSetup;

  /// No description provided for @deviceSetup.
  ///
  /// In en, this message translates to:
  /// **'Device Setup'**
  String get deviceSetup;

  /// No description provided for @dontHaveAccountAlready.
  ///
  /// In en, this message translates to:
  /// **'Don\'t already have an account?'**
  String get dontHaveAccountAlready;

  /// No description provided for @doseTakeAt.
  ///
  /// In en, this message translates to:
  /// **'Status - Awaiting'**
  String get doseTakeAt;

  /// No description provided for @doseTakenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken at {time}'**
  String doseTakenAt(Object time);

  /// No description provided for @doseTakeNow.
  ///
  /// In en, this message translates to:
  /// **'Take now'**
  String get doseTakeNow;

  /// No description provided for @doseTodayAt.
  ///
  /// In en, this message translates to:
  /// **' - Today at {time}'**
  String doseTodayAt(Object time);

  /// No description provided for @doseRefill.
  ///
  /// In en, this message translates to:
  /// **'Not filled'**
  String get doseRefill;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get editMedication;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email changed successfully'**
  String get emailChangedSuccess;

  /// No description provided for @emailChangedIdentical.
  ///
  /// In en, this message translates to:
  /// **'New email cannot be the same as the old one'**
  String get emailChangedIdentical;

  /// No description provided for @emailNotValid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid email'**
  String get emailNotValid;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an email'**
  String get emailRequired;

  /// No description provided for @enterRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit recovery code:'**
  String get enterRecoveryCode;

  /// No description provided for @errorPromptTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get errorPromptTryAgain;

  /// No description provided for @errorTriedToManyTimes.
  ///
  /// In en, this message translates to:
  /// **'You have tried the code too many times. Please wait a few minutes before trying again.'**
  String get errorTriedToManyTimes;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated time:'**
  String get estimatedTime;

  /// No description provided for @everyday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get everyday;

  /// No description provided for @exitApplication.
  ///
  /// In en, this message translates to:
  /// **'Log out of Guest Session'**
  String get exitApplication;

  /// No description provided for @exitApplicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Action will result in the account to be lost! Consider creating an account to easily return later.'**
  String get exitApplicationSubtitle;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @finishingSetup.
  ///
  /// In en, this message translates to:
  /// **'Finishing Setup'**
  String get finishingSetup;

  /// No description provided for @finishingSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait a few minutes for your pill organizer to finish initial setup.'**
  String get finishingSetupSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @genericCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get genericCancel;

  /// No description provided for @genericContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get genericContinue;

  /// No description provided for @genericCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get genericCompleteAction;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get genericError;

  /// No description provided for @genericErrorInfoText.
  ///
  /// In en, this message translates to:
  /// **'### Troubleshooting Tips\nWe\'re sorry you are having trouble setting up your pill organizer. Try the following troubleshooting tips and try again:\n- All lights on the pill organizer should be *flashing green*. If your organizer is not flashing green, press and hold the **reset button** for 3 seconds (see manual for details).\n - If your organizer is still not flashing green, ensure the included power cable is properly plugged in. If it is already plugged in, try unplugging it and plugging it back in.\n- If your phone asks you if you\'d like to pair to a device, accept.\n- If your phone prompts you for permission to access Bluetooth or your location, accept. \n\n**Error Details**\n\n *{errorText}*'**
  String genericErrorInfoText(Object errorText);

  /// No description provided for @genericLoginError.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect'**
  String get genericLoginError;

  /// No description provided for @genericOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get genericOK;

  /// No description provided for @genericProblem.
  ///
  /// In en, this message translates to:
  /// **'There was a problem: {problem}'**
  String genericProblem(Object problem);

  /// No description provided for @genericTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get genericTimezone;

  /// No description provided for @genericToday.
  ///
  /// In en, this message translates to:
  /// **' - Today'**
  String get genericToday;

  /// No description provided for @genericTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get genericTryAgain;

  /// No description provided for @homeDisconnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pill organizer disconnected'**
  String get homeDisconnectedTitle;

  /// No description provided for @homeDisconnectedSubtext.
  ///
  /// In en, this message translates to:
  /// **'Please ensure that your pill organizer is powered and nearby.'**
  String get homeDisconnectedSubtext;

  /// No description provided for @homeEmpyTite.
  ///
  /// In en, this message translates to:
  /// **'Pill organizer empty'**
  String get homeEmpyTite;

  /// No description provided for @homeEmptySubtextOwner.
  ///
  /// In en, this message translates to:
  /// **'It appears that there is currently no active prescription in your pill organizer. Please add new pills below.'**
  String get homeEmptySubtextOwner;

  /// No description provided for @homeEmptySubtextCaregiver.
  ///
  /// In en, this message translates to:
  /// **'It appears that there is currently no active prescription in your pill organizer.'**
  String get homeEmptySubtextCaregiver;

  /// No description provided for @homeEmptySubtextCaregiverContact.
  ///
  /// In en, this message translates to:
  /// **'Please contact pill organiser manager to add Pills.'**
  String get homeEmptySubtextCaregiverContact;

  /// No description provided for @homeNoMedTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No more pills scheduled for today'**
  String get homeNoMedTodayTitle;

  /// No description provided for @homeNoMedTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow to see your next doses, or edit schedule time.'**
  String get homeNoMedTodaySubtitle;

  /// No description provided for @haveAccountAlready.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountAlready;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @inviteCollaborators.
  ///
  /// In en, this message translates to:
  /// **'Invite collaborators'**
  String get inviteCollaborators;

  /// No description provided for @inviteCollaboratorsDescription.
  ///
  /// In en, this message translates to:
  /// **'To invite members with view-only access to your pill organiser, tap below to generate a code. The code will be valid for 10 minutes only.'**
  String get inviteCollaboratorsDescription;

  /// No description provided for @joinExistingDevice.
  ///
  /// In en, this message translates to:
  /// **'Join an existing device'**
  String get joinExistingDevice;

  /// No description provided for @joinDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get joinDeviceTitle;

  /// No description provided for @joinDeviceSubtext.
  ///
  /// In en, this message translates to:
  /// **'The administrator of a pill organiser should have sent you a security code number to join access. Enter below:'**
  String get joinDeviceSubtext;

  /// No description provided for @joinDeviceErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Please contact the administrator of the pillbox in question.'**
  String get joinDeviceErrorExpired;

  /// No description provided for @joinDeviceConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get joinDeviceConfirmationTitle;

  /// No description provided for @joinDeviceConfirmationSubtext.
  ///
  /// In en, this message translates to:
  /// **'You are invited to join ‘{deviceName}’ with a view-only access.'**
  String joinDeviceConfirmationSubtext(Object deviceName);

  /// No description provided for @loadingState.
  ///
  /// In en, this message translates to:
  /// **'Loading ...'**
  String get loadingState;

  /// No description provided for @manageDevices.
  ///
  /// In en, this message translates to:
  /// **'Manage devices'**
  String get manageDevices;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @missedAt.
  ///
  /// In en, this message translates to:
  /// **'Missed at {time}'**
  String missedAt(Object time);

  /// No description provided for @missingPermissionInfoTextAndroid.
  ///
  /// In en, this message translates to:
  /// **'Make sure bluetooth is turned on and also the **Location** and **Nearby devices** permissions are enabled'**
  String get missingPermissionInfoTextAndroid;

  /// No description provided for @missingPermissionInfoTextIos.
  ///
  /// In en, this message translates to:
  /// **'To setup the device, make sure that : \n- Bluetooth is turned on \n- Bluetooth is enabled in the settings \n- *Authorize a new connection* in Bluethooth is checked'**
  String get missingPermissionInfoTextIos;

  /// No description provided for @missingBlePermissionTextIos.
  ///
  /// In en, this message translates to:
  /// **'Missing Permission: the Bluetooth permission need to be enabled'**
  String get missingBlePermissionTextIos;

  /// No description provided for @missingBlePermissionTextAndroid.
  ///
  /// In en, this message translates to:
  /// **'Missing Permission: the Location, Bluetooth and Scan permission needs to be enabled'**
  String get missingBlePermissionTextAndroid;

  /// No description provided for @modifyExistingPillOrganiser.
  ///
  /// In en, this message translates to:
  /// **'Modify an existing pill organiser'**
  String get modifyExistingPillOrganiser;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @myDevices.
  ///
  /// In en, this message translates to:
  /// **'My Devices'**
  String get myDevices;

  /// No description provided for @myPills.
  ///
  /// In en, this message translates to:
  /// **'My Pills'**
  String get myPills;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameDevice.
  ///
  /// In en, this message translates to:
  /// **'Name device'**
  String get nameDevice;

  /// No description provided for @nameDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Name your pill organizer'**
  String get nameDeviceTitle;

  /// No description provided for @nameDeviceSubtext.
  ///
  /// In en, this message translates to:
  /// **'How do you wish to call your pill organiser? This is the name your collaborators will see.'**
  String get nameDeviceSubtext;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get newEmail;

  /// No description provided for @newMedication.
  ///
  /// In en, this message translates to:
  /// **'New Medication'**
  String get newMedication;

  /// No description provided for @newMedicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the new medication details for easy recognition and management.'**
  String get newMedicationSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'This is where you’ll see all the information about your pillbox.\n\nAdd a device now to start!'**
  String get noDeviceDescription;

  /// No description provided for @noMedicationLeft.
  ///
  /// In en, this message translates to:
  /// **'There is no medications left for today, come back tomorrow or update your schedule.'**
  String get noMedicationLeft;

  /// No description provided for @noticeDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected ?'**
  String get noticeDisconnected;

  /// No description provided for @noticeDisconnectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your pill organizer is powered and nearby.'**
  String get noticeDisconnectedSubtitle;

  /// No description provided for @noticeDisconnectedAction.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get noticeDisconnectedAction;

  /// No description provided for @noticePhoneDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Service disconnected'**
  String get noticePhoneDisconnected;

  /// No description provided for @noticePhoneDisconnectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone cannot connect to our service. Please check your internet connection.'**
  String get noticePhoneDisconnectedSubtitle;

  /// No description provided for @noticePhoneDisconnectedAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get noticePhoneDisconnectedAction;

  /// No description provided for @noticeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Organizer Empty?'**
  String get noticeEmpty;

  /// No description provided for @noticeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s kickstart the week by refilling your organizer.'**
  String get noticeEmptySubtitle;

  /// No description provided for @noticeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Fill Now'**
  String get noticeEmptyAction;

  /// No description provided for @noticeNeedsReload.
  ///
  /// In en, this message translates to:
  /// **'Reload Required'**
  String get noticeNeedsReload;

  /// No description provided for @noticeNeedsReloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your device state needs to be re-synchronized.'**
  String get noticeNeedsReloadSubtitle;

  /// No description provided for @noticeNeedsReloadAction.
  ///
  /// In en, this message translates to:
  /// **'Reload Now'**
  String get noticeNeedsReloadAction;

  /// No description provided for @noticeNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'No Schedule Found'**
  String get noticeNoSchedule;

  /// No description provided for @noticeNoScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your device does not have a medication schedule.'**
  String get noticeNoScheduleSubtitle;

  /// No description provided for @noticeNoScheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Set Schedule'**
  String get noticeNoScheduleAction;

  /// No description provided for @noticeStateCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Device State Corrupt'**
  String get noticeStateCorrupted;

  /// No description provided for @noticeStateCorruptedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The internal state of your device is corrupted.'**
  String get noticeStateCorruptedSubtitle;

  /// No description provided for @noticeStateCorruptedAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Device'**
  String get noticeStateCorruptedAction;

  /// No description provided for @noticeNoRtcTime.
  ///
  /// In en, this message translates to:
  /// **'Device Clock Error'**
  String get noticeNoRtcTime;

  /// No description provided for @noticeNoRtcTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The device clock is not set correctly.'**
  String get noticeNoRtcTimeSubtitle;

  /// No description provided for @noticeNoRtcTimeAction.
  ///
  /// In en, this message translates to:
  /// **'Sync Time'**
  String get noticeNoRtcTimeAction;

  /// No description provided for @noticeNoTimezone.
  ///
  /// In en, this message translates to:
  /// **'No Timezone Configured'**
  String get noticeNoTimezone;

  /// No description provided for @noticeNoTimezoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your device does not have a timezone configured.'**
  String get noticeNoTimezoneSubtitle;

  /// No description provided for @noticeNoTimezoneAction.
  ///
  /// In en, this message translates to:
  /// **'Set Schedule'**
  String get noticeNoTimezoneAction;
  /// No description provided for @noticeUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Device Error'**
  String get noticeUnknownError;

  /// No description provided for @noticeUnknownErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error has occurred on the device.'**
  String get noticeUnknownErrorSubtitle;

  /// No description provided for @noticeUnknownErrorAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get noticeUnknownErrorAction;

  /// No description provided for @noticeNoMeds.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any medications entered.'**
  String get noticeNoMeds;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @notificationReminder.
  ///
  /// In en, this message translates to:
  /// **'Send reminder notifications to your phone'**
  String get notificationReminder;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @otherDevices.
  ///
  /// In en, this message translates to:
  /// **'Other Devices'**
  String get otherDevices;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @patientIdentityConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your information below to confirm your identity'**
  String get patientIdentityConfirmation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseSelectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get pleaseSelectDateOfBirth;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccount;

  /// No description provided for @verificationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Verification Successful'**
  String get verificationSuccessful;

  /// No description provided for @accountLinkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully linked'**
  String get accountLinkedSuccessfully;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// No description provided for @invalidInformationProvided.
  ///
  /// In en, this message translates to:
  /// **'The information provided does not match our records. Please verify your details and try again.'**
  String get invalidInformationProvided;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @passwordChangedIdentical.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be the same as the old one'**
  String get passwordChangedIdentical;

  /// No description provided for @passwordLengthValidation.
  ///
  /// In en, this message translates to:
  /// **'Passwords must be between 6 and 32 characters'**
  String get passwordLengthValidation;

  /// No description provided for @passwordNotMatching.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordNotMatching;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// No description provided for @passwordRecoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code you received in order to set up a new password.'**
  String get passwordRecoverySubtitle;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @pillsOverview.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick overview of all the pills you\'ve added.'**
  String get pillsOverview;

  /// No description provided for @postSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete these final steps to set up your pill organizer.'**
  String get postSetupSubtitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @provConConnecting.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connection'**
  String get provConConnecting;

  /// No description provided for @provConSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching bluetooth'**
  String get provConSearching;

  /// No description provided for @provConConnectingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone is connecting to your pill organizer. Keep your phone close.'**
  String get provConConnectingSubtitle;

  /// No description provided for @provConSelectingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your Bluetooth device from the list below.'**
  String get provConSelectingSubtitle;

  /// No description provided for @provConSearchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to your pill organizer as your phone searches it.'**
  String get provConSearchingSubtitle;

  /// No description provided for @provEnterWifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password for {wifi}'**
  String provEnterWifiPassword(Object wifi);

  /// No description provided for @provErrConGeneric.
  ///
  /// In en, this message translates to:
  /// **'Connection Problem'**
  String get provErrConGeneric;

  /// No description provided for @provErrConGenericSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There was a problem connecting to your pill organizer.'**
  String get provErrConGenericSubtitle;

  /// No description provided for @provErrorServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not set server url'**
  String get provErrorServerUrl;

  /// No description provided for @provErrorOobKey.
  ///
  /// In en, this message translates to:
  /// **'Could not set oob key'**
  String get provErrorOobKey;

  /// No description provided for @provErrorSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Could not get serial number'**
  String get provErrorSerialNumber;

  /// No description provided for @provErrorDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Device didn\'t come online after 2 minutes'**
  String get provErrorDeviceOffline;

  /// No description provided for @provErrorContextGone.
  ///
  /// In en, this message translates to:
  /// **'Context gone'**
  String get provErrorContextGone;

  /// No description provided for @provErrorPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Password incorrect'**
  String get provErrorPasswordIncorrect;

  /// No description provided for @provErrorNoDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found after 5 attempts'**
  String get provErrorNoDevicesFound;

  /// No description provided for @provMissingPermission.
  ///
  /// In en, this message translates to:
  /// **'Missing Permissions'**
  String get provMissingPermission;

  /// No description provided for @provRescanBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Rescan Bluetooth'**
  String get provRescanBluetooth;

  /// No description provided for @provRescanWifi.
  ///
  /// In en, this message translates to:
  /// **'Rescan Networks'**
  String get provRescanWifi;

  /// No description provided for @provSelectWifi.
  ///
  /// In en, this message translates to:
  /// **'Wireless connection'**
  String get provSelectWifi;

  /// No description provided for @provSelectWifiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your Wi-Fi network from the list below. Your pill organizer will be connected to the one you choose:'**
  String get provSelectWifiSubtitle;

  /// No description provided for @quickSwitch.
  ///
  /// In en, this message translates to:
  /// **'Quick Switch'**
  String get quickSwitch;

  /// No description provided for @quickSwitchSubText.
  ///
  /// In en, this message translates to:
  /// **'Quickly switch to another pill organiser'**
  String get quickSwitchSubText;

  /// No description provided for @quickSwitchNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect a new device'**
  String get quickSwitchNewDevice;

  /// No description provided for @quickSwitchExistingDevice.
  ///
  /// In en, this message translates to:
  /// **'Join an existing device'**
  String get quickSwitchExistingDevice;

  /// No description provided for @recoveryLinkWaiting.
  ///
  /// In en, this message translates to:
  /// **'If you still have not received an email please click on the link to send one again.'**
  String get recoveryLinkWaiting;

  /// No description provided for @registerEmailExistingError.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email address. To retrieve your data, please log out and log back in with the existing account and add the devices.'**
  String get registerEmailExistingError;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'There was a problem registering you in: {error}'**
  String registerError(Object error);

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up reminders to ensure you stay on track with your medication schedule.'**
  String get remindersSubtitle;

  /// No description provided for @removal.
  ///
  /// In en, this message translates to:
  /// **'Removal'**
  String get removal;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDevice;

  /// No description provided for @removingDevice.
  ///
  /// In en, this message translates to:
  /// **'Removing Device'**
  String get removingDevice;

  /// No description provided for @removingDeviceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure ? To access it again, you\'ll need to set it up again.'**
  String get removingDeviceConfirmation;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searchTimezones.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get searchTimezones;

  /// No description provided for @selectAColor.
  ///
  /// In en, this message translates to:
  /// **'Select a color'**
  String get selectAColor;

  /// No description provided for @selectManualTimezone.
  ///
  /// In en, this message translates to:
  /// **'Select manual time zone:'**
  String get selectManualTimezone;

  /// No description provided for @setToCurrentTimezone.
  ///
  /// In en, this message translates to:
  /// **'Set to my current timezone'**
  String get setToCurrentTimezone;

  /// No description provided for @sendRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Link'**
  String get sendRecoveryLink;

  /// No description provided for @sendRecoveryLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Click below to have the recovery link sent to your email.'**
  String get sendRecoveryLinkSubtitle;

  /// No description provided for @sendRecoveryLinkSubtitleWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Click below to have the recovery link sent to your email.'**
  String get sendRecoveryLinkSubtitleWithEmail;

  /// No description provided for @setMedicationTime.
  ///
  /// In en, this message translates to:
  /// **'Please set medication times in device settings'**
  String get setMedicationTime;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @setupComplete.
  ///
  /// In en, this message translates to:
  /// **'Setup Complete'**
  String get setupComplete;

  /// No description provided for @setupCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your pill organizer will be ready to use after restarting.'**
  String get setupCompleteSubtitle;

  /// No description provided for @shape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get shape;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @signInConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInConfirm;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInPrompt;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'There was a problem signing you in: {error}'**
  String signInError(Object error);

  /// No description provided for @signInBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please Sign In to your account.'**
  String get signInBackSubtitle;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing Out'**
  String get signingOut;

  /// No description provided for @signingOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signingOutSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In to your account for better experience.'**
  String get signInSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'STEP'**
  String get step;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @switchDevice.
  ///
  /// In en, this message translates to:
  /// **'Switch device'**
  String get switchDevice;

  /// No description provided for @switchPillOrganizers.
  ///
  /// In en, this message translates to:
  /// **'Switch Pill Organizers'**
  String get switchPillOrganizers;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabPills.
  ///
  /// In en, this message translates to:
  /// **'My pills'**
  String get tabPills;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get tabSettings;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @timeSetup.
  ///
  /// In en, this message translates to:
  /// **'Time Setup:'**
  String get timeSetup;

  /// No description provided for @timeSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the time when you\'d like to be reminded to take your pills.'**
  String get timeSetupSubtitle;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone:'**
  String get timezone;

  /// No description provided for @timezoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the time zone your pill organizer should use.'**
  String get timezoneSubtitle;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @validationWrongCode.
  ///
  /// In en, this message translates to:
  /// **'You have entered the wrong code, please try again.'**
  String get validationWrongCode;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View-only'**
  String get viewOnly;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @welcomeCabinet.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CabiNET!'**
  String get welcomeCabinet;

  /// No description provided for @welcomeCabinetLong.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CabiNET!\n Choose between the options below:'**
  String get welcomeCabinetLong;

  /// No description provided for @wirelessConnected.
  ///
  /// In en, this message translates to:
  /// **'Wireless connected'**
  String get wirelessConnected;

  /// No description provided for @wirelessDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Wireless disconnected'**
  String get wirelessDisconnected;

  /// No description provided for @generateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate a new code'**
  String get generateCode;

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'This code will expire in'**
  String get codeExpiresIn;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @errorGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Error generating code. Please try again.'**
  String get errorGenerateCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
