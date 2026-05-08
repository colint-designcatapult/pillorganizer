// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accountSettings => 'Paramètres du compte';

  @override
  String get addMedications => 'Ajouter des médicaments';

  @override
  String get addMedicationsSubtitle =>
      'Entrer votre posologie pour que votre cabiNET puisse vous envoyer des rappels.';

  @override
  String get appName => 'CabiNET';

  @override
  String get addNew => 'Ajouter';

  @override
  String get addNewDevice => 'Ajouter un nouvel appareil';

  @override
  String get addNewDeviceSection => 'Ajouter un nouvel appareil';

  @override
  String get addNewDeviceSubtitle =>
      'Sélectionnez la façon dont vous voulez ajouter un nouvel appareil';

  @override
  String get addPills => 'Ajouter des pilules';

  @override
  String get addPillsError =>
      'Une erreur s\'est produite lors de la tentative d\'ajout de pilules. Vous pouvez toujours ajouter des pilules après l\'intégration';

  @override
  String get addPillManually => 'Ajouter manuellement';

  @override
  String get addToList => 'Ajouter à la liste';

  @override
  String get alreadyRegistered => 'Déjà inscrit';

  @override
  String get authConnectionError =>
      'Assurez-vous que vous êtes connecté à Internet et réessayez';

  @override
  String get authError => 'Authentification échouée';

  @override
  String get automatic => 'Automatique';

  @override
  String get back => 'Retour';

  @override
  String get batteryLevel => 'Niveau de la batterie';

  @override
  String get bluetoothConnected => 'Bluetooth connecté';

  @override
  String get bluetoothConnecting => 'Recherche de l\'appareil...';

  @override
  String get bluetoothDisconnected => 'Bluetooth déconnecté';

  @override
  String get bluetoothMissingPermissions => 'Connexion impossible';

  @override
  String get changeDeviceName => 'Changer le nom de l\'appareil';

  @override
  String get changeDeviceNamePrompt =>
      'Veuillez entrer ci-dessous le nouveau nom désiré pour l\'appareil:';

  @override
  String get changeEmail => 'Changer l\'adresse courriel';

  @override
  String get changeEmailSubtitle =>
      'Veuillez saisir votre couriel actuel afin d\'en créer un nouveau.';

  @override
  String get changeName => 'Changer le nom';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Veuillez saisir votre mot de passe actuel afin d\'en créer un nouveau.';

  @override
  String get changeLanguage => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get validTimeError => 'Veuillez entrer une heure valide';

  @override
  String get cancel => 'Annuler';

  @override
  String get am => 'am';

  @override
  String get pm => 'pm';

  @override
  String get color => 'Couleur';

  @override
  String get confirmNewPassword => 'Confirmer le mot de passe';

  @override
  String get connectNewDevice => 'Connecter un nouvel appareil';

  @override
  String get connectionProblem => 'Problème de connexion';

  @override
  String get connectionProblemSubtitle =>
      'Un problème est survenu pendant la configuration de votre pilulier';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createAccountSubtitle =>
      'Créer un compte pour accéder à vos données en tout temps';

  @override
  String get createAnAccount => 'Créer un compte';

  @override
  String get current => 'Actuel';

  @override
  String get currentEmail => 'Adresse courriel actuelle';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get delete => 'Effacer';

  @override
  String get deleteMedication => 'Effacer le médicament';

  @override
  String get deleteMedicationConfirmation =>
      'Êtes-vous certains de vouloir supprimer ce médicament?';

  @override
  String get deviceInfo => 'Information de l\'appareil';

  @override
  String get deviceInfoSubtitle =>
      'Voici un aperçu de l\'état de connexion de votre appareil.';

  @override
  String get deviceName => 'Nom de l\'appareil';

  @override
  String get nameDeviceHint => 'Nom du pilulier';

  @override
  String get deviceNameRequired => 'Un nom est requis';

  @override
  String get deviceNewSetup => 'Configurer un nouvel appareil';

  @override
  String get deviceSetup => 'Configuration de l\'appareil';

  @override
  String get dontHaveAccountAlready => 'Vous n\'avez pas encore de compte?';

  @override
  String get doseTakeAt => 'Statut - En attente';

  @override
  String doseTakenAt(Object time) {
    return 'Prise à $time';
  }

  @override
  String get doseTakeNow => 'Prendre maintenant';

  @override
  String doseTodayAt(Object time) {
    return ' - Aujourd\'hui à $time';
  }

  @override
  String get doseRefill => 'Pas remplis';

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
  String get edit => 'Modifier';

  @override
  String get editMedication => 'Modifier médicament';

  @override
  String get editSchedule => 'Modifier l\'horaire';

  @override
  String get email => 'Adresse courriel';

  @override
  String get emailChangedSuccess => 'Le courriel a été changé avec succès';

  @override
  String get emailChangedIdentical =>
      'Le nouveau courriel ne peut pas être le même que l\'ancien';

  @override
  String get emailNotValid => 'Cette adresse courriel n\'est pas valide';

  @override
  String get emailRequired => 'Entrer une adresse courriel';

  @override
  String get enterRecoveryCode =>
      'Entrez votre code de récupération à 6 chiffres :';

  @override
  String get errorPromptTryAgain => 'Réessayer';

  @override
  String get errorTriedToManyTimes =>
      'Vous avez essayé le code trop de fois. Veuillez patienter quelques minutes avant de réessayer.';

  @override
  String get estimatedTime => 'Heure estimée:';

  @override
  String get everyday => 'À chaque jour';

  @override
  String get exitApplication => 'Se déconnecter de la session invité';

  @override
  String get exitApplicationSubtitle =>
      'Cette action entraînera la perte des données du compte! Pensez à créer un compte pour y revenir facilement plus tard.';

  @override
  String get faq => 'FAQ';

  @override
  String get finishingSetup => 'Terminer la configuration';

  @override
  String get finishingSetupSubtitle =>
      'Veuillez attendre quelques minutes pendant que nous terminons la configuration de votre pilulier';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get friday => 'Vendredi';

  @override
  String get genericCancel => 'Annuler';

  @override
  String get genericContinue => 'Continuer';

  @override
  String get genericCompleteAction => 'Terminer';

  @override
  String get genericError => 'Erreur';

  @override
  String genericErrorInfoText(Object errorText) {
    return '### Conseils de dépannage\nNous sommes désolés que vous rencontriez des difficultés pour configurer votre pilulier. Essayez les conseils de dépannage suivants et réessayez :\n- Tous les voyants du pilulier doivent être *verts clignotants*. Si votre organiseur ne clignote pas en vert, appuyez et maintenez enfoncé le **bouton de réinitialisation** pendant 3 secondes (voir le manuel pour plus de détails).\n- Si votre organiseur ne clignote toujours pas en vert, assurez-vous que le câble d\'alimentation fourni est correctement branché. S\'il est déjà branché, essayez de le débrancher puis de le rebrancher.\n- Si votre téléphone vous demande si vous souhaitez vous connecter à un appareil, acceptez.\n- Si votre téléphone vous demande l\'autorisation d\'accéder à Bluetooth ou à votre position, acceptez. \n\n**Détails de l\'erreur**\n\n *\$$errorText*';
  }

  @override
  String get genericLoginError =>
      'L\'adresse courriel ou le mot de passe est incorrect';

  @override
  String get genericOK => 'OK';

  @override
  String genericProblem(Object problem) {
    return 'Un problème est survenu: $problem';
  }

  @override
  String get genericTimezone => 'Fuseau horaire';

  @override
  String get genericToday => ' - Aujourd\'hui';

  @override
  String get genericTryAgain => 'Réessayer';

  @override
  String get homeDisconnectedTitle => 'Pilulier déconnecté';

  @override
  String get homeDisconnectedSubtext =>
      'Veuillez vous assurer que votre pilulier est alimenté et à proximité.';

  @override
  String get homeEmpyTite => 'Le pilulier est vide';

  @override
  String get homeEmptySubtextOwner =>
      'Il semble qu\'il n\'y ait actuellement aucune ordonnance active dans votre pilulier. Veuillez ajouter de nouveaux médicaments ci-dessous.';

  @override
  String get homeEmptySubtextCaregiver =>
      'Il semble qu\'il n\'y ait actuellement aucune ordonnance active dans votre pilulier.';

  @override
  String get homeEmptySubtextCaregiverContact =>
      'Veuillez contacter le responsable du pilulier pour ajouter des pilules.';

  @override
  String get homeNoMedTodayTitle => 'Plus de pilules pour aujourd\'hui';

  @override
  String get homeNoMedTodaySubtitle =>
      'Revenez demain pour voir vos prochaines doses ou modifier l\'horaire.';

  @override
  String get haveAccountAlready => 'Vous avez déjà un compte?';

  @override
  String get invalidEmailFormat => 'Format d\'adresse courriel invalide';

  @override
  String get inviteCollaborators => 'Inviter des collaborateurs';

  @override
  String get inviteCollaboratorsDescription =>
      'Pour inviter des membres avec accès en lecture seule à votre pilulier, saisissez leur adresse courriel ci-dessous.';

  @override
  String get joinExistingDevice => 'Rejoindre un appareil existant';

  @override
  String get joinDeviceTitle => 'Comment rejoindre un appareil';

  @override
  String get joinDeviceSubtext =>
      'Pour rejoindre un appareil existant, demandez à l\'utilisateur principal de vous inviter en utilisant votre adresse courriel affichée ci-dessous.';

  @override
  String get loadingState => 'Chargement ...';

  @override
  String get manageDevices => 'Gérer les appareils';

  @override
  String get manual => 'Manuel';

  @override
  String missedAt(Object time) {
    return 'Manqué à $time';
  }

  @override
  String get missingPermissionInfoTextAndroid =>
      'Assurez-vous que le Bluetooth est activé et que les autorisations **Localisation** et **Appareils à proximité** sont également autorisées.';

  @override
  String get missingPermissionInfoTextIos =>
      'Pour configurer l\'appareil, assurez-vous que : \n- Bluetooth est activé \n- Bluetooth est activé dans les paramètres \n- *Autoriser une nouvelle connexion* dans Bluethooth est coché';

  @override
  String get missingBlePermissionTextIos =>
      'Autorisation manquante: l\'autorisation Bluetooth doit être activée';

  @override
  String get missingBlePermissionTextAndroid =>
      'Autorisations manquantes: l\'autorisation de Localisation, Bluetooth et Appareils à proximité doivent être activées';

  @override
  String get modifyExistingPillOrganiser => 'Modifier un pilulier existant';

  @override
  String get monday => 'Lundi';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get myDevices => 'Mes appareils';

  @override
  String get myPills => 'Mes pilules';

  @override
  String get name => 'Nom';

  @override
  String get nameDevice => 'Nommer l\'appareil';

  @override
  String get nameDeviceTitle => 'Nommer votre pilulier';

  @override
  String get nameDeviceSubtext =>
      'Comment souhaitez-vous appeler votre pilulier ? C\'est le nom que verront vos collaborateurs.';

  @override
  String get newEmail => 'Nouvelle adresse courriel';

  @override
  String get newMedication => 'Nouveau médicament';

  @override
  String get newMedicationSubtitle =>
      'Entrer les détails du nouveau médicament pour une reconnaissance et une gestion faciles.';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get next => 'Suivant';

  @override
  String get noDeviceDescription =>
      'C\'est ici que vous verrez toutes les informations sur votre pilulier.\n\nAjoutez un appareil maintenant pour commencer !';

  @override
  String get noMedicationLeft =>
      'Il ne reste plus de médicaments pour aujourd\'hui, revenez demain ou mettez à jour votre horaire.';

  @override
  String get noMedicationScheduled => 'No medication scheduled for today';

  @override
  String get noneTakenYet => 'None taken yet';

  @override
  String get noneScheduled => 'None scheduled';

  @override
  String get noticeDisconnected => 'Appareil déconnecté?';

  @override
  String get noticeDisconnectedSubtitle =>
      'Veuillez vous assurer que votre pilulier est allumé et a proximité.';

  @override
  String get noticeDisconnectedAction => 'Reconnexion';

  @override
  String get noticePhoneDisconnected => 'Service déconnecté';

  @override
  String get noticePhoneDisconnectedSubtitle =>
      'Votre téléphone ne peut pas se connecter à notre service. Veuillez vérifier votre connexion Internet.';

  @override
  String get noticePhoneDisconnectedAction => 'Réessayer';

  @override
  String get noticeEmpty => 'Pilulier vide?';

  @override
  String get noticeEmptySubtitle =>
      'Commençons la semaine en remplissant votre pilulier.';

  @override
  String get noticeEmptyAction => 'Remplir';

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
  String get noticeNoTimezone => 'Fuseau horaire non configuré';

  @override
  String get noticeNoTimezoneSubtitle =>
      'Votre appareil n\'a pas de fuseau horaire configuré.';

  @override
  String get noticeNoTimezoneAction => 'Configurer le fuseau horaire';

  @override
  String get noticeUnknownError => 'Erreur de l\'appareil';

  @override
  String get noticeUnknownErrorSubtitle =>
      'Une erreur inattendue s\'est produite sur l\'appareil.';

  @override
  String get noticeUnknownErrorAction => 'Réessayer';

  @override
  String get noticeNoMeds => 'Vous n\'avez entré aucun médicament.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationPreferences => 'Préférences de notification';

  @override
  String get notificationReminder => 'Envoyer des rappels sur votre téléphone';

  @override
  String get takeNowNotifications => 'Take now reminders';

  @override
  String get takenNotifications => 'Taken confirmations';

  @override
  String get missedNotifications => 'Missed dose alerts';

  @override
  String get notSignedIn => 'Pas connecté';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get or => 'ou';

  @override
  String get otherDevices => 'Autres appareils';

  @override
  String get past => 'Past';

  @override
  String get password => 'Mot de passe';

  @override
  String get patientIdentityConfirmation =>
      'Veuillez saisir vos informations ci-dessous pour confirmer votre identité';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get selectDateOfBirth => 'Sélectionnez votre date de naissance';

  @override
  String get pleaseEnterFirstName => 'Veuillez saisir votre prénom';

  @override
  String get pleaseEnterLastName => 'Veuillez saisir votre nom de famille';

  @override
  String get pleaseSelectDateOfBirth =>
      'Veuillez sélectionner votre date de naissance';

  @override
  String get verifyAccount => 'Vérifier le compte';

  @override
  String get verificationSuccessful => 'Vérification réussie';

  @override
  String get accountLinkedSuccessfully => 'Votre compte a été lié avec succès';

  @override
  String get verificationFailed => 'Échec de la vérification';

  @override
  String get invalidInformationProvided =>
      'Les informations fournies ne correspondent pas à nos dossiers. Veuillez vérifier vos détails et réessayer.';

  @override
  String get passwordChangedSuccess =>
      'Le mot de passe a été changé avec succès';

  @override
  String get passwordChangedIdentical =>
      'Le nouveau mot de passe ne peut pas être le même que l\'ancien';

  @override
  String get passwordLengthValidation =>
      'Les mots de passe doivent comporter entre 6 et 32 ​​caractères';

  @override
  String get passwordNotMatching => 'Passwords do not match';

  @override
  String get passwordRecovery => 'Récupération de mot de passe';

  @override
  String get passwordRecoverySubtitle =>
      'Veuillez saisir le code que vous avez reçu afin de créer un nouveau mot de passe.';

  @override
  String get passwordRequired => 'Entrez votre mot de passe';

  @override
  String get pillsOverview =>
      'Voici un aperçu rapide de toutes les pilules que vous avez ajoutées.';

  @override
  String get postSetupSubtitle =>
      'Effectuez ces dernières étapes pour configurer votre pilulier..';

  @override
  String get preferences => 'Préférences';

  @override
  String get progress => 'Progrès';

  @override
  String get provConConnecting => 'Connexion Bluetooth';

  @override
  String get provConSearching => 'Recherche bluetooth';

  @override
  String get provConConnectingSubtitle =>
      'Votre téléphone se connecte à votre pilulier. Gardez votre téléphone à proximité.';

  @override
  String get provConSelectingSubtitle =>
      'Sélectionnez votre appareil Bluetooth dans la liste ci-dessous.';

  @override
  String get provConSearchingSubtitle =>
      'Tenez votre téléphone près de votre pilulier pendant que votre téléphone le recherche.';

  @override
  String provEnterWifiPassword(Object wifi) {
    return 'Entrer votre mot de passe pour $wifi';
  }

  @override
  String get provErrConGeneric => 'Problème de connexion';

  @override
  String get provErrConGenericSubtitle =>
      'Un problème est survenu lors de la connexion à votre pilulier.';

  @override
  String get provErrorServerUrl => 'Impossible de définir l\'URL du serveur';

  @override
  String get provErrorOobKey => 'Impossible de définir la clé oob';

  @override
  String get provErrorSerialNumber => 'Could not get serial number';

  @override
  String get provErrorDeviceOffline =>
      'L\'appareil ne c\'est pas mis en ligne après 2 minutes';

  @override
  String get provErrorContextGone => 'Contexte perdu';

  @override
  String get provErrorPasswordIncorrect => 'Mot de passe incorrect.';

  @override
  String get provErrorNoDevicesFound =>
      'Aucun appareil trouvé après 5 tentatives';

  @override
  String get provMissingPermission => 'Autorisations manquantes';

  @override
  String get provRescanBluetooth => 'Nouveaux scan Bluetooth';

  @override
  String get provRescanWifi => 'Nouveau scan de réseau';

  @override
  String get provSelectWifi => 'Connexion sans fil';

  @override
  String get provSelectWifiSubtitle =>
      'Sélectionnez votre réseau Wi-Fi dans la liste ci-dessous. Votre pilulier sera connecté à celui que vous aurez choisi:';

  @override
  String get quickSwitch => 'Changement rapide';

  @override
  String get quickSwitchSubText => 'Passez rapidement à un autre pilulier';

  @override
  String get quickSwitchNewDevice => 'Connecter un nouvel appareil';

  @override
  String get quickSwitchExistingDevice => 'Rejoindre un appareil existant';

  @override
  String get recoveryLinkWaiting =>
      'Si vous n\'avez toujours pas reçu de courriel veuillez cliquer sur le lien pour un envoyer un de nouveau.';

  @override
  String get registerEmailExistingError =>
      'Un compte existe déjà pour cette adresse courriel. Pour récupérer vos données, veuillez vous déconnecter, puis vous reconnecter avec le compte existant et ajouter les appareils.';

  @override
  String registerError(Object error) {
    return 'Un problème est survenu lors de votre inscription: $error';
  }

  @override
  String get reminders => 'Rappels';

  @override
  String get remindersSubtitle =>
      'Configurez des rappels pour vous assurer de rester sur la bonne voie avec votre posologie.';

  @override
  String get removal => 'Suppression';

  @override
  String get remove => 'Retirer';

  @override
  String get removeDevice => 'Supprimer l\'appareil';

  @override
  String get removingDevice => 'Retirer l\'appareil';

  @override
  String get removingDeviceConfirmation =>
      'Êtes-vous certains ? Pour y accéder à nouveau, vous devrez le configurer à nouveau.';

  @override
  String get saturday => 'Samedi';

  @override
  String get save => 'Sauvegarder';

  @override
  String get searchTimezones => 'Recherche de fuseau horaire';

  @override
  String get selectAColor => 'Sélectionner une couleur';

  @override
  String get selectManualTimezone =>
      'Sélectionner manuellement le fuseau horaire :';

  @override
  String get setToCurrentTimezone => 'Définir à mon fuseau horaire actuel';

  @override
  String get sendRecoveryLink => 'Envoyer le lien de récupération';

  @override
  String get sendRecoveryLinkSubtitle =>
      'Cliquez ci-dessous pour que le lien de récupération soit envoyé à votre adresse courriel.';

  @override
  String get sendRecoveryLinkSubtitleWithEmail =>
      'Cliquez ci-dessous pour recevoir le lien de récupération par e-mail.';

  @override
  String get setMedicationTime =>
      'Veuillez définir les heures de médicamentation dans les paramètres de l\'appareil';

  @override
  String get setTime => 'Définir l\'heure';

  @override
  String get settings => 'Paramètres';

  @override
  String get setupComplete => 'Configuration terminée';

  @override
  String get setupCompleteSubtitle => 'Votre pilulier est prêt à être utilisé.';

  @override
  String get shape => 'Forme';

  @override
  String get share => 'Partager';

  @override
  String get signInAction => 'Se connecter';

  @override
  String get signInOrCreateAccountAction => 'Se connecter ou créer un compte';

  @override
  String get signInConfirm => 'Connectez-vous';

  @override
  String get signInPrompt => 'Veuillez vous connecter';

  @override
  String signInError(Object error) {
    return 'Un problème est survenu lors de votre connexion: $error';
  }

  @override
  String get signInBackSubtitle =>
      'Content de te revoir! Connectez-vous à votre compte s\'il vous plaît.';

  @override
  String get signingOut => 'Déconnection';

  @override
  String get signingOutSubtitle =>
      'Êtes-vous certain de vouloir vous déconnecter?';

  @override
  String get signInSubtitle =>
      'Connectez-vous à votre compte pour une meilleure expérience.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle => 'Êtes-vous sûr de vouloir supprimer définitivement votre compte? Cette action est irréversible. Vos informations personnelles seront supprimées, mais les données de santé anonymisées seront conservées à des fins de recherche.';

  @override
  String get deleteAccountConfirm => 'Supprimer le compte';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get skip => 'Sauter';

  @override
  String get step => 'ÉTAPE';

  @override
  String get sunday => 'Dimanche';

  @override
  String get switchDevice => 'Changer d\'appareil';

  @override
  String get switchPillOrganizers => 'Changer de pilulier';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabPills => 'Mes pilules';

  @override
  String get tabSettings => 'Appareils';

  @override
  String get tabAccount => 'Compte';

  @override
  String get thursday => 'Jeudi';

  @override
  String get time => 'Heure';

  @override
  String get todayMedicationTitle => 'Today\'s Medication';

  @override
  String get timeSetup => 'Configuration de l\'horaire:';

  @override
  String get timeSetupSubtitle =>
      'Sélectionnez l\'heure à laquelle vous souhaitez qu\'on vous rappelle de prendre vos pilules.';

  @override
  String get timezone => 'Fuseau Horaire:';

  @override
  String get timezoneSubtitle =>
      'Sélectionnez le fuseau horaire que votre pilulier doit utiliser.';

  @override
  String get tuesday => 'Mardi';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get validationWrongCode =>
      'Vous avez entré un mauvais code, veuillez réessayer.';

  @override
  String get viewOnly => 'Lecture seulement';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get welcome => 'Bienvenue!';

  @override
  String get welcomeCabinet => 'Bienvenue à CabiNET!';

  @override
  String get welcomeCabinetLong => 'Bienvenue à CabiNET!';

  @override
  String get wirelessConnected => 'Connecté sans fil';

  @override
  String get wirelessDisconnected => 'Déconnecté sans fil';

  @override
  String get commandSent =>
      'Commande envoyée. Les modifications prendront effet dans les 15 prochaines minutes.';

  @override
  String commandFailed(Object error) {
    return 'Échec de l\'envoi de la commande : $error';
  }

  @override
  String get commandMarkTaken => 'Pris';

  @override
  String get commandMarkReset => 'Réinitialiser';

  @override
  String get commandReloadComplete => 'Terminer le rechargement';

  @override
  String get commandReloadStart => 'Démarrer le rechargement';

  @override
  String get commandReloadInitiate => 'Lancer le rechargement';

  @override
  String get peopleWithAccess => 'Personnes ayant accès';

  @override
  String get primaryUser => 'Utilisateur principal';

  @override
  String get revokeAccess => 'Révoquer l\'accès';

  @override
  String revokeAccessConfirmation(String name) {
    return 'Êtes-vous sûr de vouloir révoquer l\'accès de $name? Cette personne ne pourra plus consulter les données de cet appareil.';
  }

  @override
  String get revoke => 'Révoquer';

  @override
  String get transferPrimaryUser => 'Transférer l\'utilisateur principal';

  @override
  String get transferPrimaryUserDescription =>
      'Sélectionnez la personne à qui vous souhaitez transférer le statut d\'utilisateur principal. Elle aura alors le contrôle total de l\'horaire de l\'appareil.';

  @override
  String transferPrimaryUserConfirmation(String name) {
    return 'Êtes-vous sûr de vouloir transférer le statut d\'utilisateur principal à $name? Vous perdrez la possibilité de modifier l\'horaire de l\'appareil.';
  }

  @override
  String get transfer => 'Transférer';

  @override
  String get errorLoadingCaregivers =>
      'Impossible de charger la liste d\'accès. Veuillez réessayer.';

  @override
  String get caregiverName => 'Nom de l\'aidant';

  @override
  String get enterCaregiverName => 'Saisissez un nom pour cet aidant';

  @override
  String get inviteByEmail => 'Inviter par courriel';

  @override
  String get sendInvite => 'Envoyer l\'invitation';

  @override
  String get caregiverInvited => 'Aidant invité avec succès.';

  @override
  String get errorInvitingCaregiver =>
      'Échec de l\'invitation. Veuillez vérifier que le courriel est enregistré.';

  @override
  String get enterCaregiverEmail =>
      'Saisissez l\'adresse courriel de l\'aidant';

  @override
  String get yourEmail => 'Votre courriel';
}
