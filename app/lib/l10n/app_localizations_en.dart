// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get addMedications => 'Add Medications';

  @override
  String get addMedicationsSubtitle =>
      'Enter in the medications you take so your pill organizer can remind you.';

  @override
  String get appName => 'CabiNET';

  @override
  String get addNew => 'Add new';

  @override
  String get addNewDevice => 'Add new device';

  @override
  String get addNewDeviceSection => 'Add a new device';

  @override
  String get addNewDeviceSubtitle =>
      'Select the way you want to add a new device';

  @override
  String get addPills => 'Add Pills';

  @override
  String get addPillsError =>
      'An error occured trying to add pills, you can still add pills after the onboarding';

  @override
  String get addPillManually => 'Add Pill Manually';

  @override
  String get addToList => 'Add to list';

  @override
  String get alreadyRegistered => 'Already registered';

  @override
  String get authConnectionError =>
      'Make sure you are connected to the internet and try again';

  @override
  String get authError => 'Authentication failed';

  @override
  String get automatic => 'Automatic';

  @override
  String get back => 'Back';

  @override
  String get batteryLevel => 'Battery Level';

  @override
  String get bluetoothConnected => 'Bluetooth connected';

  @override
  String get bluetoothConnecting => 'Scanning bluetooth...';

  @override
  String get bluetoothDisconnected => 'Bluetooth disconnected';

  @override
  String get bluetoothMissingPermissions => 'Unable to connect';

  @override
  String get changeDeviceName => 'Change device name';

  @override
  String get changeDeviceNamePrompt =>
      'Please enter the desired new device name right below:';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get changeEmailSubtitle =>
      'Please enter your current email in order to set up a new one.';

  @override
  String get changeName => 'Change Name';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'Please enter your current password in order to set up a new one.';

  @override
  String get changeLanguage => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get validTimeError => 'Please enter a valid time';

  @override
  String get cancel => 'Cancel';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get color => 'Color';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get connectNewDevice => 'Connect a new device';

  @override
  String get connectionProblem => 'Connection Problem';

  @override
  String get connectionProblemSubtitle =>
      'There was a problem setting up your pill organizer.';

  @override
  String get createAccount => 'Create account';

  @override
  String get createAccountSubtitle =>
      'Create an account in order to access your data anytime, anywhere.';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get current => 'Current';

  @override
  String get currentEmail => 'Current Email';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get delete => 'Delete';

  @override
  String get deleteMedication => 'Delete Medication';

  @override
  String get deleteMedicationConfirmation =>
      'Are you sure you want to delete this medication?';

  @override
  String get deviceInfo => 'Device Information';

  @override
  String get deviceInfoSubtitle =>
      'Here\'s an overview of your device connection status.';

  @override
  String get deviceName => 'Device name';

  @override
  String get nameDeviceHint => 'Pill organiser name';

  @override
  String get deviceNameRequired => 'A device name is required';

  @override
  String get deviceNewSetup => 'Set up a new device';

  @override
  String get deviceSetup => 'Device Setup';

  @override
  String get dontHaveAccountAlready => 'Don\'t already have an account?';

  @override
  String get doseTakeAt => 'Status - Awaiting';

  @override
  String doseTakenAt(Object time) {
    return 'Taken at $time';
  }

  @override
  String get doseTakeNow => 'Take now';

  @override
  String doseTodayAt(Object time) {
    return ' - Today at $time';
  }

  @override
  String get doseRefill => 'Not filled';

  @override
  String get doseStatusMissed => 'MISSED';

  @override
  String get doseStatusNoRecord => 'NO RECORD';

  @override
  String get doseStatusPending => 'Pending';

  @override
  String get doseStatusTaken => 'TAKEN';

  @override
  String get doseStatusTakeNow => 'TAKE NOW';

  @override
  String get doseStatusUnknown => 'Unknown';

  @override
  String get dosesCompleted => 'completed';

  @override
  String get dosesTakenLabel => 'taken';

  @override
  String get dosesRemaining => 'remaining';

  @override
  String get edit => 'Edit';

  @override
  String get editMedication => 'Edit medication';

  @override
  String get editSchedule => 'Edit Schedule';

  @override
  String get email => 'Email';

  @override
  String get emailChangedSuccess => 'Email changed successfully';

  @override
  String get emailChangedIdentical =>
      'New email cannot be the same as the old one';

  @override
  String get emailNotValid => 'Not a valid email';

  @override
  String get emailRequired => 'Enter an email';

  @override
  String get enterRecoveryCode => 'Enter your 6-digit recovery code:';

  @override
  String get errorPromptTryAgain => 'Try Again';

  @override
  String get errorTriedToManyTimes =>
      'You have tried the code too many times. Please wait a few minutes before trying again.';

  @override
  String get estimatedTime => 'Estimated time:';

  @override
  String get everyday => 'Everyday';

  @override
  String get exitApplication => 'Log out of Guest Session';

  @override
  String get exitApplicationSubtitle =>
      'Action will result in the account to be lost! Consider creating an account to easily return later.';

  @override
  String get faq => 'FAQ';

  @override
  String get finishingSetup => 'Finishing Setup';

  @override
  String get finishingSetupSubtitle =>
      'Please wait a few minutes for your pill organizer to finish initial setup.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get friday => 'Friday';

  @override
  String get genericCancel => 'Cancel';

  @override
  String get genericContinue => 'Continue';

  @override
  String get genericCompleteAction => 'Complete';

  @override
  String get genericError => 'Error';

  @override
  String genericErrorInfoText(Object errorText) {
    return '### Troubleshooting Tips\nWe\'re sorry you are having trouble setting up your pill organizer. Try the following troubleshooting tips and try again:\n- All lights on the pill organizer should be *flashing green*. If your organizer is not flashing green, press and hold the **reset button** for 3 seconds (see manual for details).\n - If your organizer is still not flashing green, ensure the included power cable is properly plugged in. If it is already plugged in, try unplugging it and plugging it back in.\n- If your phone asks you if you\'d like to pair to a device, accept.\n- If your phone prompts you for permission to access Bluetooth or your location, accept. \n\n**Error Details**\n\n *$errorText*';
  }

  @override
  String get genericLoginError => 'The email or password is incorrect';

  @override
  String get genericOK => 'OK';

  @override
  String genericProblem(Object problem) {
    return 'There was a problem: $problem';
  }

  @override
  String get genericTimezone => 'Time Zone';

  @override
  String get genericToday => ' - Today';

  @override
  String get genericTryAgain => 'Try Again';

  @override
  String get homeDisconnectedTitle => 'Pill organizer disconnected';

  @override
  String get homeDisconnectedSubtext =>
      'Please ensure that your pill organizer is powered and nearby.';

  @override
  String get homeEmpyTite => 'Pill organizer empty';

  @override
  String get homeEmptySubtextOwner =>
      'It appears that there is currently no active prescription in your pill organizer. Please add new pills below.';

  @override
  String get homeEmptySubtextCaregiver =>
      'It appears that there is currently no active prescription in your pill organizer.';

  @override
  String get homeEmptySubtextCaregiverContact =>
      'Please contact pill organiser manager to add Pills.';

  @override
  String get homeNoMedTodayTitle => 'No more pills scheduled for today';

  @override
  String get homeNoMedTodaySubtitle =>
      'Come back tomorrow to see your next doses, or edit schedule time.';

  @override
  String get haveAccountAlready => 'Already have an account?';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get inviteCollaborators => 'Invite collaborators';

  @override
  String get inviteCollaboratorsDescription =>
      'To invite members with view-only access to your pill organiser, tap below to generate a code. The code will be valid for 10 minutes only.';

  @override
  String get joinExistingDevice => 'Join an existing device';

  @override
  String get joinDeviceTitle => 'Enter code';

  @override
  String get joinDeviceSubtext =>
      'The administrator of a pill organiser should have sent you a security code number to join access. Enter below:';

  @override
  String get joinDeviceErrorExpired =>
      'This code has expired. Please contact the administrator of the pillbox in question.';

  @override
  String get joinDeviceConfirmationTitle => 'All set';

  @override
  String joinDeviceConfirmationSubtext(Object deviceName) {
    return 'You are invited to join ‘$deviceName’ with a view-only access.';
  }

  @override
  String get loadingState => 'Loading ...';

  @override
  String get manageDevices => 'Manage devices';

  @override
  String get manual => 'Manual';

  @override
  String missedAt(Object time) {
    return 'Missed at $time';
  }

  @override
  String get missingPermissionInfoTextAndroid =>
      'Make sure bluetooth is turned on and also the **Location** and **Nearby devices** permissions are enabled';

  @override
  String get missingPermissionInfoTextIos =>
      'To setup the device, make sure that : \n- Bluetooth is turned on \n- Bluetooth is enabled in the settings \n- *Authorize a new connection* in Bluethooth is checked';

  @override
  String get missingBlePermissionTextIos =>
      'Missing Permission: the Bluetooth permission need to be enabled';

  @override
  String get missingBlePermissionTextAndroid =>
      'Missing Permission: the Location, Bluetooth and Scan permission needs to be enabled';

  @override
  String get modifyExistingPillOrganiser => 'Modify an existing pill organiser';

  @override
  String get monday => 'Monday';

  @override
  String get myAccount => 'My Account';

  @override
  String get myDevices => 'My Devices';

  @override
  String get myPills => 'My Pills';

  @override
  String get name => 'Name';

  @override
  String get nameDevice => 'Name device';

  @override
  String get nameDeviceTitle => 'Name your pill organizer';

  @override
  String get nameDeviceSubtext =>
      'How do you wish to call your pill organiser? This is the name your collaborators will see.';

  @override
  String get newEmail => 'New Email';

  @override
  String get newMedication => 'New Medication';

  @override
  String get newMedicationSubtitle =>
      'Enter the new medication details for easy recognition and management.';

  @override
  String get newPassword => 'New Password';

  @override
  String get next => 'Next';

  @override
  String get noDeviceDescription =>
      'This is where you’ll see all the information about your pillbox.\n\nAdd a device now to start!';

  @override
  String get noMedicationLeft =>
      'There is no medications left for today, come back tomorrow or update your schedule.';

  @override
  String get noMedicationScheduled => 'No medication scheduled for today';

  @override
  String get noneTakenYet => 'None taken yet';

  @override
  String get noneScheduled => 'None scheduled';

  @override
  String get noticeDisconnected => 'Device disconnected ?';

  @override
  String get noticeDisconnectedSubtitle =>
      'Please ensure your pill organizer is powered and nearby.';

  @override
  String get noticeDisconnectedAction => 'Reconnect';

  @override
  String get noticePhoneDisconnected => 'Service disconnected';

  @override
  String get noticePhoneDisconnectedSubtitle =>
      'Your phone cannot connect to our service. Please check your internet connection.';

  @override
  String get noticePhoneDisconnectedAction => 'Retry';

  @override
  String get noticeEmpty => 'Organizer Empty?';

  @override
  String get noticeEmptySubtitle =>
      'Let\'s kickstart the week by refilling your organizer.';

  @override
  String get noticeEmptyAction => 'Fill Now';

  @override
  String get noticeNeedsReload => 'Reload Required';

  @override
  String get noticeNeedsReloadSubtitle =>
      'Medication must be reloaded on your device. Please open a bin to initiate reload.';

  @override
  String get noticeNeedsReloadAction => 'Reload Now';

  @override
  String get noticeNoSchedule => 'No Schedule Found';

  @override
  String get noticeNoScheduleSubtitle =>
      'Your device does not have a medication schedule.';

  @override
  String get noticeNoScheduleAction => 'Set Schedule';

  @override
  String get noticeStateCorrupted => 'Device State Corrupt';

  @override
  String get noticeStateCorruptedSubtitle =>
      'The internal state of your device is corrupted.';

  @override
  String get noticeStateCorruptedAction => 'Reset Device';

  @override
  String get noticeNoRtcTime => 'Device Clock Error';

  @override
  String get noticeNoRtcTimeSubtitle =>
      'The device clock is not set correctly.';

  @override
  String get noticeNoRtcTimeAction => 'Sync Time';

  @override
  String get noticeNoTimezone => 'No Timezone Configured';

  @override
  String get noticeNoTimezoneSubtitle =>
      'Your device does not have a timezone configured.';

  @override
  String get noticeNoTimezoneAction => 'Set Schedule';

  @override
  String get noticeUnknownError => 'Device Error';

  @override
  String get noticeUnknownErrorSubtitle =>
      'An unexpected error has occurred on the device.';

  @override
  String get noticeUnknownErrorAction => 'Retry';

  @override
  String get noticeNoMeds => 'You don\'t have any medications entered.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get notificationReminder =>
      'Send reminder notifications to your phone';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get openSettings => 'Open settings';

  @override
  String get or => 'or';

  @override
  String get otherDevices => 'Other Devices';

  @override
  String get past => 'Past';

  @override
  String get password => 'Password';

  @override
  String get patientIdentityConfirmation =>
      'Please enter your information below to confirm your identity';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get selectDateOfBirth => 'Select your date of birth';

  @override
  String get pleaseEnterFirstName => 'Please enter your first name';

  @override
  String get pleaseEnterLastName => 'Please enter your last name';

  @override
  String get pleaseSelectDateOfBirth => 'Please select your date of birth';

  @override
  String get verifyAccount => 'Verify Account';

  @override
  String get verificationSuccessful => 'Verification Successful';

  @override
  String get accountLinkedSuccessfully =>
      'Your account has been successfully linked';

  @override
  String get verificationFailed => 'Verification Failed';

  @override
  String get invalidInformationProvided =>
      'The information provided does not match our records. Please verify your details and try again.';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get passwordChangedIdentical =>
      'New password cannot be the same as the old one';

  @override
  String get passwordLengthValidation =>
      'Passwords must be between 6 and 32 characters';

  @override
  String get passwordNotMatching => 'Passwords do not match';

  @override
  String get passwordRecovery => 'Password Recovery';

  @override
  String get passwordRecoverySubtitle =>
      'Please enter the code you received in order to set up a new password.';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get pillsOverview =>
      'Here\'s a quick overview of all the pills you\'ve added.';

  @override
  String get postSetupSubtitle =>
      'Complete these final steps to set up your pill organizer.';

  @override
  String get preferences => 'Preferences';

  @override
  String get progress => 'Progress';

  @override
  String get provConConnecting => 'Bluetooth Connection';

  @override
  String get provConSearching => 'Searching bluetooth';

  @override
  String get provConConnectingSubtitle =>
      'Your phone is connecting to your pill organizer. Keep your phone close.';

  @override
  String get provConSelectingSubtitle =>
      'Select your Bluetooth device from the list below.';

  @override
  String get provConSearchingSubtitle =>
      'Hold your phone close to your pill organizer as your phone searches it.';

  @override
  String provEnterWifiPassword(Object wifi) {
    return 'Enter password for $wifi';
  }

  @override
  String get provErrConGeneric => 'Connection Problem';

  @override
  String get provErrConGenericSubtitle =>
      'There was a problem connecting to your pill organizer.';

  @override
  String get provErrorServerUrl => 'Could not set server url';

  @override
  String get provErrorOobKey => 'Could not set oob key';

  @override
  String get provErrorSerialNumber => 'Could not get serial number';

  @override
  String get provErrorDeviceOffline =>
      'Device didn\'t come online after 2 minutes';

  @override
  String get provErrorContextGone => 'Context gone';

  @override
  String get provErrorPasswordIncorrect => 'Password incorrect';

  @override
  String get provErrorNoDevicesFound => 'No devices found after 5 attempts';

  @override
  String get provMissingPermission => 'Missing Permissions';

  @override
  String get provRescanBluetooth => 'Rescan Bluetooth';

  @override
  String get provRescanWifi => 'Rescan Networks';

  @override
  String get provSelectWifi => 'Wireless connection';

  @override
  String get provSelectWifiSubtitle =>
      'Select your Wi-Fi network from the list below. Your pill organizer will be connected to the one you choose:';

  @override
  String get quickSwitch => 'Quick Switch';

  @override
  String get quickSwitchSubText => 'Quickly switch to another pill organiser';

  @override
  String get quickSwitchNewDevice => 'Connect a new device';

  @override
  String get quickSwitchExistingDevice => 'Join an existing device';

  @override
  String get recoveryLinkWaiting =>
      'If you still have not received an email please click on the link to send one again.';

  @override
  String get registerEmailExistingError =>
      'An account already exists for this email address. To retrieve your data, please log out and log back in with the existing account and add the devices.';

  @override
  String registerError(Object error) {
    return 'There was a problem registering you in: $error';
  }

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersSubtitle =>
      'Set up reminders to ensure you stay on track with your medication schedule.';

  @override
  String get removal => 'Removal';

  @override
  String get remove => 'Remove';

  @override
  String get removeDevice => 'Remove device';

  @override
  String get removingDevice => 'Removing Device';

  @override
  String get removingDeviceConfirmation =>
      'Are you sure ? To access it again, you\'ll need to set it up again.';

  @override
  String get saturday => 'Saturday';

  @override
  String get save => 'Save';

  @override
  String get searchTimezones => 'Search time zones';

  @override
  String get selectAColor => 'Select a color';

  @override
  String get selectManualTimezone => 'Select manual time zone:';

  @override
  String get setToCurrentTimezone => 'Set to my current timezone';

  @override
  String get sendRecoveryLink => 'Send Recovery Link';

  @override
  String get sendRecoveryLinkSubtitle =>
      'Click below to have the recovery link sent to your email.';

  @override
  String get sendRecoveryLinkSubtitleWithEmail =>
      'Click below to have the recovery link sent to your email.';

  @override
  String get setMedicationTime =>
      'Please set medication times in device settings';

  @override
  String get setTime => 'Set time';

  @override
  String get settings => 'Settings';

  @override
  String get setupComplete => 'Setup Complete';

  @override
  String get setupCompleteSubtitle =>
      'Your pill organizer will be ready to use after restarting.';

  @override
  String get shape => 'Shape';

  @override
  String get share => 'Share';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signInOrCreateAccountAction => 'Sign In or Create Account';

  @override
  String get signInConfirm => 'Sign In';

  @override
  String get signInPrompt => 'Sign In';

  @override
  String signInError(Object error) {
    return 'There was a problem signing you in: $error';
  }

  @override
  String get signInBackSubtitle =>
      'Welcome back! Please Sign In to your account.';

  @override
  String get signingOut => 'Signing Out';

  @override
  String get signingOutSubtitle => 'Are you sure you want to sign out?';

  @override
  String get signInSubtitle => 'Sign In to your account for better experience.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get skip => 'Skip';

  @override
  String get step => 'STEP';

  @override
  String get sunday => 'Sunday';

  @override
  String get switchDevice => 'Switch device';

  @override
  String get switchPillOrganizers => 'Switch Pill Organizers';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPills => 'My pills';

  @override
  String get tabSettings => 'My devices';

  @override
  String get tabAccount => 'Account';

  @override
  String get thursday => 'Thursday';

  @override
  String get time => 'Time';

  @override
  String get todayMedicationTitle => 'Today\'s Medication';

  @override
  String get timeSetup => 'Time Setup:';

  @override
  String get timeSetupSubtitle =>
      'Select the time when you\'d like to be reminded to take your pills.';

  @override
  String get timezone => 'Timezone:';

  @override
  String get timezoneSubtitle =>
      'Select the time zone your pill organizer should use.';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get validationWrongCode =>
      'You have entered the wrong code, please try again.';

  @override
  String get viewOnly => 'View-only';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeCabinet => 'Welcome to CabiNET!';

  @override
  String get welcomeCabinetLong => 'Welcome to CabiNET!';

  @override
  String get wirelessConnected => 'Wireless connected';

  @override
  String get wirelessDisconnected => 'Wireless disconnected';

  @override
  String get generateCode => 'Generate a new code';

  @override
  String get codeExpiresIn => 'This code will expire in';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied to clipboard';

  @override
  String get errorGenerateCode => 'Error generating code. Please try again.';

  @override
  String get commandSent =>
      'Command sent. Changes will take effect within 15 minutes.';

  @override
  String commandFailed(Object error) {
    return 'Failed to send command: $error';
  }

  @override
  String get commandMarkTaken => 'Mark as Taken';

  @override
  String get commandMarkReset => 'Reset';

  @override
  String get commandReloadComplete => 'Complete Reload';

  @override
  String get commandReloadStart => 'Start Reload';

  @override
  String get commandReloadInitiate => 'Initiate Reload';

  @override
  String get peopleWithAccess => 'People with access';

  @override
  String get primaryUser => 'Primary User';

  @override
  String get revokeAccess => 'Revoke Access';

  @override
  String revokeAccessConfirmation(String name) {
    return 'Are you sure you want to revoke access for $name? They will no longer be able to view this device\'s data.';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String get transferPrimaryUser => 'Transfer Primary User';

  @override
  String get transferPrimaryUserDescription =>
      'Select the person you want to transfer primary user status to. This will give them full control over the device schedule.';

  @override
  String transferPrimaryUserConfirmation(String name) {
    return 'Are you sure you want to transfer primary user status to $name? You will lose the ability to modify the device schedule.';
  }

  @override
  String get transfer => 'Transfer';

  @override
  String get errorLoadingCaregivers =>
      'Unable to load access list. Please try again.';

  @override
  String get caregiverName => 'Caregiver Name';

  @override
  String get enterCaregiverName => 'Enter a name for this caregiver';
}
