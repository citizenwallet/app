// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get viewContract => 'Voir le contrat';

  @override
  String get confirm => 'Confirmer';

  @override
  String get welcomeCitizen => 'Welcome, citizen!';

  @override
  String get aWalletForYourCommunity =>
      'Ceci est votre nouveau portefeuille, où vous pouvez stocker, envoyer et recevoir les jetons de votre communauté.';

  @override
  String get createNewAccount => 'Créer un nouveau compte';

  @override
  String get scanFromCommunity => 'Scannez un code QR de votre communauté';

  @override
  String get or => 'OU';

  @override
  String get browseCommunities => 'Parcourir les communautés';

  @override
  String get recoverfrombackup => 'Récupérer à partir d\'une sauvegarde';

  @override
  String get recoverIndividualAccountFromaPrivatekey =>
      'Récupérer un compte individuel à partir d\'une clé privée';

  @override
  String get createNewAccountMsg =>
      'Créez un profil pour faciliter l\'envoi de jetons vers vous.';

  @override
  String get settingsScrApp => 'Application';

  @override
  String get createaprofile => 'Créer un profil';

  @override
  String get edit => 'Modifier';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get about => 'À propos';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get inappsounds => 'Sons dans l\'application';

  @override
  String viewOn(Object name) {
    return 'Voir sur $name';
  }

  @override
  String get accounts => 'Comptes';

  @override
  String get account => 'Compte';

  @override
  String get cards => 'Cartes';

  @override
  String get yourContactsWillAppearHere => 'Vos contacts apparaîtront ici';

  @override
  String get accountsAndroidBackupsuseAndroid =>
      'Les sauvegardes utilisent la sauvegarde automatique Android et suivent les paramètres de sauvegarde de votre appareil automatiquement.';

  @override
  String get accountsAndroidIfYouInstalltheAppAgain =>
      'Si vous installez l\'application de nouveau sur un autre appareil utilisant le même compte Google, la sauvegarde chiffrée sera utilisée pour restaurer vos comptes.';

  @override
  String get accountsAndroidYouraccounts =>
      'Vos comptes et les sauvegardes de vos comptes vous appartiennent.';

  @override
  String get accountsAndroidManuallyExported =>
      'Ils peuvent être exportés manuellement à tout moment.';

  @override
  String get accountsApYouraccountsarebackedup =>
      'Vos comptes sont sauvegardés dans le trousseau de votre iPhone et suivent vos paramètres de sauvegarde automatiquement.';

  @override
  String get accountsApSyncthisiPhone =>
      'Activer \"Synchroniser cet iPhone\" garantira que le trousseau de votre iPhone soit sauvegardé sur iCloud.';

  @override
  String get accountsApYoucancheck =>
      'Vous pouvez vérifier si la synchronisation est activée dans votre application Paramètres en allant à : Identifiant Apple > iCloud > Mots de passe et trousseau.';

  @override
  String get accountsApYouraccounts =>
      'Vos comptes et les sauvegardes de vos comptes sont générés et vous appartiennent.';

  @override
  String get accountsApTheycanbe =>
      'Ils peuvent être exportés manuellement à tout moment.';

  @override
  String get initialAddress => 'Adresse initiale';

  @override
  String get notifications => 'Notifications';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get clearDataAndBackups => 'Effacer les données et les sauvegardes';

  @override
  String get replaceExistingBackup => 'Remplacer la sauvegarde existante';

  @override
  String get replace => 'Remplacer';

  @override
  String get androidBackupTexlineOne =>
      'Il existe déjà une sauvegarde dans votre compte Google Drive à partir de différents identifiants.';

  @override
  String get androidBackupTexlineTwo =>
      'Êtes-vous sûr de vouloir la remplacer?';

  @override
  String get appResetTexlineOne => 'Êtes-vous sûr de vouloir tout supprimer?';

  @override
  String get appResetTexlineTwo => 'Cette action ne peut pas être annulée.';

  @override
  String get delete => 'Supprimer';

  @override
  String get endToEndEncryption => 'Chiffrement de bout en bout';

  @override
  String get endToEndEncryptionSub =>
      'Les sauvegardes sont toujours chiffrées de bout en bout.';

  @override
  String get accountsSubLableOne =>
      'Tous vos comptes sont automatiquement sauvegardés dans le trousseau de votre appareil et synchronisés avec votre trousseau iCloud.';

  @override
  String accountsSubLableLastBackUp(Object lastBackup) {
    return 'Vos comptes sont sauvegardés sur votre compte Google Drive. Dernière sauvegarde : $lastBackup.';
  }

  @override
  String get accountsSubLableLastBackUpSecond =>
      'Sauvegardez vos comptes sur votre compte Google Drive.';

  @override
  String get auto => 'auto';

  @override
  String varsion(Object buildNumber, Object version) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get transactionDetais => 'Détails de la transaction';

  @override
  String get transactionID => 'ID de transaction';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get reply => 'Répondre';

  @override
  String get sendAgain => 'Envoyer à nouveau';

  @override
  String get voucherCreating => 'Création du bon...';

  @override
  String get voucherFunding => 'Financement du bon...';

  @override
  String get voucherRedeemed => 'Bon échangé';

  @override
  String get voucherCreated => 'Bon créé';

  @override
  String get voucherCreateFailed => 'Échec de la création du bon';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get minted => 'Émis';

  @override
  String get noDescription => 'pas de description';

  @override
  String get preparingWallet => 'Préparation du portefeuille...';

  @override
  String get transactions => 'Historique des transactions';

  @override
  String get citizenWallet => 'Citizen Wallet';

  @override
  String get aWlletRorYourCommunity => 'Un portefeuille pour votre communauté';

  @override
  String get openingYourWallet => 'Ouverture de votre portefeuille...';

  @override
  String get continueText => 'Continuer';

  @override
  String get copied => 'Copié';

  @override
  String get copyText => 'Copier';

  @override
  String get backupDate => 'Date de sauvegarde :';

  @override
  String get decryptBackup => 'Déchiffrer la sauvegarde';

  @override
  String get googleDriveAccount => 'Compte Google Drive :';

  @override
  String get noKeysFoundTryManually =>
      'Aucune clé trouvée, essayez manuellement.';

  @override
  String get getEncryptionKeyFromYourPasswordManager =>
      'Obtenir la clé de chiffrement de votre gestionnaire de mots de passe';

  @override
  String get invalidKeyEncryptionKey => 'Clé de chiffrement invalide.';

  @override
  String get enterEncryptionKeyManually =>
      'Entrer la clé de chiffrement manuellement';

  @override
  String get enterEncryptionKey => 'Entrer la clé de chiffrement';

  @override
  String get encryptionKey => 'Clé de chiffrement';

  @override
  String get loading => 'Chargement';

  @override
  String get joinCommunity => 'Rejoindre la communauté';

  @override
  String get importText => 'Importer';

  @override
  String get selectAccount => 'Sélectionner un compte';

  @override
  String get hello => 'Bonjour';

  @override
  String get thisIsYourWallet => 'Ceci est votre portefeuille.';

  @override
  String get itLivesInTheLinkOfThisPage =>
      'Il se trouve dans le lien de cette page.';

  @override
  String get itIsUniqueToYouAndYourCommunity =>
      'Il est unique pour vous et votre communauté.';

  @override
  String get keepYourLink =>
      'Gardez votre lien privé pour vous assurer que vous seul avez accès à ce portefeuille.';

  @override
  String get send => 'Envoyer';

  @override
  String get sending => 'Envoi';

  @override
  String get swipeToMint => 'Balayez pour émettre';

  @override
  String get swipeToSend => 'Balayez pour envoyer';

  @override
  String get swipeToConfirm => 'Balayez pour confirmer';

  @override
  String get receive => 'Recevoir';

  @override
  String get request => 'Demander';

  @override
  String get retry => 'Réessayer';

  @override
  String get searchUserAndAddress => 'Adresse ou nom d\'utilisateur';

  @override
  String get sendViaLink => 'Envoyer un lien';

  @override
  String get scanQRCode => 'Scanner un code QR';

  @override
  String get sendToNFCTag => 'Envoyer sur une carte NFC';

  @override
  String get mint => 'Émettre';

  @override
  String get vouchers => 'Bons';

  @override
  String get noBackupFound => 'Aucune sauvegarde trouvée';

  @override
  String get selectAnotherAccount => 'Sélectionner un autre compte';

  @override
  String get recoverIndividualAccount =>
      'Récupérer un compte individuel à partir d\'une clé privée';

  @override
  String get restoreAllAccountsGoogleDrive =>
      'Restaurer tous les comptes depuis Google Drive';

  @override
  String get infoActionLayoutDescription =>
      'Vous devrez vous connecter à votre compte Google. Nous demanderons uniquement l\'accès au dossier de cette application dans votre Google Drive.';

  @override
  String get connectYourGoogleDriveAccount =>
      'Connecter votre compte Google Drive';

  @override
  String get recoverIndividualAccountPrivateKey =>
      'Récupérer un compte individuel à partir d\'une clé privée';

  @override
  String get create => 'Créer';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get enterAUsername => 'Entrez un nom d\'utilisateur';

  @override
  String get pleasePickAUsername => 'Veuillez choisir un nom d\'utilisateur.';

  @override
  String get thisUsernameIsAlreadyTaken =>
      'Ce nom d\'utilisateur est déjà pris.';

  @override
  String get name => 'Nom';

  @override
  String get enterAName => 'Entrez un nom';

  @override
  String get enterDescription => 'Entrez une description';

  @override
  String get failedSaveProfile => 'Échec de l\'enregistrement du profil.';

  @override
  String get fetchingExistingProfile => 'Récupération du profil existant...';

  @override
  String get uploadingNewProfile => 'Téléchargement du nouveau profil...';

  @override
  String get almostDone => 'Presque terminé...';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get save => 'Enregistrer';

  @override
  String get language => 'Langue';

  @override
  String get saveWallet => 'Enregistrer le portefeuille';

  @override
  String get saveText1 =>
      'Ne perdez pas votre portefeuille ! Mettez cette page en favori ou sauvegardez son adresse unique contenant votre clé privée dans un endroit sûr.';

  @override
  String get gettheapp =>
      'Vous pouvez également télécharger l\'application et y importer votre portefeuille.';

  @override
  String get appstorebadge => 'badge App Store';

  @override
  String get googleplaybadge => 'badge Google Play';

  @override
  String get opentheapp =>
      'Une fois installée, vous pouvez importer votre portefeuille.';

  @override
  String get open => 'Importer dans l\'appplication';

  @override
  String get copyyouruniquewalletURL =>
      'Copiez l\'URL unique de votre portefeuille';

  @override
  String get emailtoyourselfyourwalleturl =>
      'Envoyez-vous par courriel l\'URL de votre portefeuille';

  @override
  String get shareText1 => 'Faites scanner ce code QR par quelqu\'un d\'autre.';

  @override
  String get shareText2 =>
      'S\'ils n\'en ont pas déjà un, cela créera un nouveau portefeuille Citoyen sur leur appareil.';

  @override
  String get editname => 'Modifier le nom';

  @override
  String get export => 'Exporter';

  @override
  String get cancel => 'Annuler';

  @override
  String get enteraccountname => 'Entrer le nom du compte';

  @override
  String get exportAccount => 'Exporter le compte';

  @override
  String get deleteaccount => 'Supprimer le compte';

  @override
  String get deleteaccountMsg1 =>
      'Êtes-vous sûr de vouloir supprimer ce compte ?';

  @override
  String get deleteaccountMsg2 => 'Cette action ne peut pas être annulée.';

  @override
  String get profileText1 => 'Il semble que vous n\'ayez pas encore de profil.';

  @override
  String get share => 'Partager le lien';

  @override
  String get cancelRefund => 'Annuler et rembourser';

  @override
  String get returnFunds => 'Rendre les fonds';

  @override
  String get returnVoucher => 'Rendre le bon';

  @override
  String get returnVoucherMsg => 'sera retourné à votre portefeuille.';

  @override
  String get deleteVoucher => 'Supprimer le bon';

  @override
  String get deleteVoucherMsg => 'Cela retirera le bon de la liste.';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get voucherAmount => 'Montant du bon';

  @override
  String get enteramount => 'Entrer le montant';

  @override
  String get vouchericon => 'icône de bon';

  @override
  String get vouchersMsg => 'Vos bons apparaîtront ici';

  @override
  String get createVoucher => 'Créer un bon';

  @override
  String get returnText => 'Retour';

  @override
  String get redeemed => 'échangé';

  @override
  String get issued => 'émis';

  @override
  String get communities => 'Communautés';

  @override
  String get invalidlink => 'Lien invalide';

  @override
  String get unabltohandlelink => 'Impossible de gérer le lien';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get to => 'À';

  @override
  String get minting => 'Frappe';

  @override
  String get externalWallet => 'Portefeuille externe';

  @override
  String get resetQRCode => 'Réinitialiser le code QR';

  @override
  String get amount => 'Montant';

  @override
  String get descriptionMsg => 'Ajouter une description';

  @override
  String get clear => 'Effacer';

  @override
  String get done => 'OK';

  @override
  String get settings => 'Paramètres';

  @override
  String get sent => 'Envoyé';

  @override
  String failedSend(Object currencyName) {
    return 'Échec de l\'envoi de $currencyName.';
  }

  @override
  String failedMint(Object currencyName) {
    return 'Échec de l\'émission de $currencyName.';
  }

  @override
  String get onText => 'sur';

  @override
  String get invalidQRCode => 'Code QR invalide';

  @override
  String get enterManually => 'Entrer manuellement';

  @override
  String get scanAgain => 'Scanner à nouveau';

  @override
  String get max => 'max';

  @override
  String get insufficientFunds => 'Fonds insuffisants.';

  @override
  String currentBalance(Object formattedBalance) {
    return 'Current balance: $formattedBalance';
  }

  @override
  String get sendDescription => 'Ajouter une description\n\n\n';

  @override
  String get chooseRecipient => 'Choisir un destinataire';

  @override
  String get createdBy => 'Créé par';

  @override
  String get redeem => 'Accepter';

  @override
  String get voucher => 'Bon';

  @override
  String get createVoucherText =>
      'Créer un bon échangeable contre le montant indiqué ci-dessus.';

  @override
  String get emptyBalanceText1 => 'Ce bon a déjà été utilisé.';

  @override
  String get emptyBalanceText2 => 'Échangez ce bon sur votre compte.';

  @override
  String get tapToScan => 'Scannez votre carte';

  @override
  String get communityCurrentlyOffline => 'Communauté actuellement hors ligne';

  @override
  String get topup => 'Recharger';

  @override
  String get close => 'Fermer';

  @override
  String get more => 'Plus';

  @override
  String get start => 'Commencer';

  @override
  String get connecting => 'Connexion';

  @override
  String get accountNotFound => 'Compte non trouvé';
}
