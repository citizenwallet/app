// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get viewContract => 'Contract bekijken';

  @override
  String get confirm => 'Bevestig';

  @override
  String get welcomeCitizen => 'Welcome, citizen!';

  @override
  String get aWalletForYourCommunity =>
      'Dit is je nieuwe wallet, waar je de tokens van je gemeenschap kunt opslaan, verzenden en ontvangen.';

  @override
  String get createNewAccount => 'Creëer een nieuwe account';

  @override
  String get scanFromCommunity => 'Een QR-code scannen vanuit je gemeenschap';

  @override
  String get or => 'OF';

  @override
  String get browseCommunities => 'Gemeenschappen doorbladeren';

  @override
  String get recoverfrombackup => 'herstel account van backup';

  @override
  String get recoverIndividualAccountFromaPrivatekey =>
      'Herstel een individuele account via een private key.';

  @override
  String get createNewAccountMsg =>
      'Creëer een profiel zodat mensen gemakkelijk tokens kunnen sturen naar uw gebruikersnaam.';

  @override
  String get settingsScrApp => 'App';

  @override
  String get createaprofile => 'Creëer een profiel';

  @override
  String get edit => 'Bewerk';

  @override
  String get darkMode => 'Donkere modus';

  @override
  String get about => 'Over ons';

  @override
  String get pushNotifications => 'Push-meldingen';

  @override
  String get inappsounds => 'In-app geluiden';

  @override
  String viewOn(Object name) {
    return 'Weergeven op $name';
  }

  @override
  String get accounts => 'Accounts';

  @override
  String get account => 'Account';

  @override
  String get cards => 'Kaarten';

  @override
  String get yourContactsWillAppearHere =>
      'Uw contactpersonen verschijnen hier';

  @override
  String get accountsAndroidBackupsuseAndroid =>
      'Back-ups maken gebruik van Android Auto Backup en volgen automatisch de back-upinstellingen van je toestel.';

  @override
  String get accountsAndroidIfYouInstalltheAppAgain =>
      'Als je de app opnieuw installeert op een ander apparaat met hetzelfde Google-account, wordt de versleutelde back-up gebruikt om je accounts te herstellen.';

  @override
  String get accountsAndroidYouraccounts =>
      'Uw accounts en back-ups worden door u aangemaakt en zijn volledig uw eigendom. ';

  @override
  String get accountsAndroidManuallyExported =>
      'Ze kunnen op elk moment handmatig worden geëxporteerd.';

  @override
  String get accountsApYouraccountsarebackedup =>
      'Van je accounts wordt een back-up gemaakt in de Keychain van je iPhone en ze volgen automatisch je iCloud back-upinstellingen.';

  @override
  String get accountsApSyncthisiPhone =>
      'Als je \"Sync this iPhone\" inschakelt, wordt er een back-up van je keychain van je iPhone gemaakt in iCloud. ';

  @override
  String get accountsApYoucancheck =>
      'Je kunt controleren of synchronisatie is ingeschakeld in je Instellingen door te gaan naar: Apple ID > iCloud > Wachtwoorden en Keychain. ';

  @override
  String get accountsApYouraccounts =>
      'Uw accounts en back-ups van uw accounts worden door u aangemaakt en zijn volledig uw eigendom. ';

  @override
  String get accountsApTheycanbe =>
      'Ze kunnen op elk moment handmatig worden geëxporteerd.';

  @override
  String get initialAddress => 'Initieel Adres:';

  @override
  String get notifications => 'Notificaties';

  @override
  String get backup => 'Backup';

  @override
  String get dangerZone => 'Gevaren zone';

  @override
  String get clearDataAndBackups => 'Verwijder data & backups';

  @override
  String get replaceExistingBackup => 'Vervang huidge backup';

  @override
  String get replace => 'Vervang';

  @override
  String get androidBackupTexlineOne =>
      'Er is al een back-up op je Google Drive-account gelinkt met een andere account';

  @override
  String get androidBackupTexlineTwo =>
      'Weet je zeker dat je deze wilt vervangen?';

  @override
  String get appResetTexlineOne =>
      'Weet je zeker dat je alles wilt verwijderen?';

  @override
  String get appResetTexlineTwo =>
      'Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get delete => 'Verwijder';

  @override
  String get endToEndEncryption => 'End-to-end encryptie';

  @override
  String get endToEndEncryptionSub =>
      'Back-ups zijn altijd end-to-end versleuteld.';

  @override
  String get accountsSubLableOne =>
      'Van al je accounts wordt automatisch een back-up gemaakt in de sleutelhanger van je apparaat en ze worden gesynchroniseerd met je iCloud-Keychain.';

  @override
  String accountsSubLableLastBackUp(Object lastBackup) {
    return 'Van je accounts wordt een back-up gemaakt op je Google Drive-account. Laatste back-up: $lastBackup.';
  }

  @override
  String get accountsSubLableLastBackUpSecond =>
      'Maak nu een back-up van je accounts op je Google Drive-account.';

  @override
  String get auto => 'auto';

  @override
  String varsion(Object buildNumber, Object version) {
    return 'Versie $version ($buildNumber)';
  }

  @override
  String get transactionDetais => 'Transactie details';

  @override
  String get transactionID => 'Transactie ID';

  @override
  String get date => 'Datum';

  @override
  String get description => 'Beschrijving';

  @override
  String get reply => 'Antwoord';

  @override
  String get sendAgain => 'Verstuur opnieuw';

  @override
  String get voucherCreating => 'Voucher creëren...';

  @override
  String get voucherFunding => 'Voucher financieren...';

  @override
  String get voucherRedeemed => 'Voucher geclaimd';

  @override
  String get voucherCreated => 'Voucher gecreëerd';

  @override
  String get voucherCreateFailed => 'Voucher creatie mislukt';

  @override
  String get anonymous => 'Anoniem';

  @override
  String get minted => 'Minted';

  @override
  String get noDescription => 'Geen beschrijving';

  @override
  String get preparingWallet => 'Wallet wordt geïnitialiseerd...';

  @override
  String get transactions => 'Transactiegeschiedenis';

  @override
  String get citizenWallet => 'Citizen Wallet';

  @override
  String get aWlletRorYourCommunity => 'Een wallet voor jouw gemeenschap';

  @override
  String get openingYourWallet => 'Wallet openen...';

  @override
  String get continueText => 'Ga verder';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get copyText => 'Kopieer';

  @override
  String get backupDate => 'Backup datum: ';

  @override
  String get decryptBackup => 'Decrypteer backup';

  @override
  String get googleDriveAccount => 'Google Drive account: ';

  @override
  String get noKeysFoundTryManually =>
      'Geen account-keys gevonden, probeer handmatig in te voeren.';

  @override
  String get getEncryptionKeyFromYourPasswordManager =>
      'Haal de coderingssleutel op uit uw Password Manager';

  @override
  String get invalidKeyEncryptionKey => 'Ongeldige coderingssleutel.';

  @override
  String get enterEncryptionKeyManually =>
      'Coderingssleutel handmatig invoeren';

  @override
  String get enterEncryptionKey => 'Encryptie key invoeren';

  @override
  String get encryptionKey => 'Encryptie key';

  @override
  String get loading => 'Bezig met laden';

  @override
  String get joinCommunity => 'Lid worden';

  @override
  String get importText => 'Importeer';

  @override
  String get selectAccount => 'Selecteer Account';

  @override
  String get hello => 'Hello';

  @override
  String get thisIsYourWallet => 'Dit is jouw wallet.';

  @override
  String get itLivesInTheLinkOfThisPage =>
      'Je wallet gegevens zitten in de link van deze pagina.';

  @override
  String get itIsUniqueToYouAndYourCommunity =>
      'Het is uniek voor jou en je gemeenschap.';

  @override
  String get keepYourLink =>
      'Houd je link privé om ervoor te zorgen dat alleen jij toegang hebt tot deze wallet.';

  @override
  String get send => 'Verstuur';

  @override
  String get sending => 'Versturen';

  @override
  String get swipeToMint => 'Swipe om te minten';

  @override
  String get swipeToSend => 'Swipe om te versturen';

  @override
  String get swipeToConfirm => 'Swipe om te bevestigen';

  @override
  String get receive => 'Ontvang';

  @override
  String get request => 'Aanvraag';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get searchUserAndAddress => 'Zoek gebruiker of plak adres';

  @override
  String get sendViaLink => 'Verstuur via link';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get sendToNFCTag => 'Verstuur naar een NFC-tag';

  @override
  String get mint => 'Mint';

  @override
  String get vouchers => 'Vouchers';

  @override
  String get noBackupFound => 'Geen backup gevonden';

  @override
  String get selectAnotherAccount => 'Selecteer een andere account';

  @override
  String get recoverIndividualAccount =>
      'Individuele account herstellen met een private key';

  @override
  String get restoreAllAccountsGoogleDrive =>
      'Alle accounts herstellen via Google Drive';

  @override
  String get infoActionLayoutDescription =>
      'Je wordt gevraagd om in te loggen op je Google account. We vragen alleen toegang tot de map van deze app in je Google Drive.';

  @override
  String get connectYourGoogleDriveAccount =>
      'Verbind met je Google Drive Account';

  @override
  String get recoverIndividualAccountPrivateKey =>
      'Herstel individuele account via een private key';

  @override
  String get create => 'Creëer';

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get enterAUsername => 'Voer een gebruikersnaam in';

  @override
  String get pleasePickAUsername => 'Kies een gebruikersnaam.';

  @override
  String get thisUsernameIsAlreadyTaken =>
      'Deze gebruikersnaam wordt reeds gebruikt.';

  @override
  String get name => 'Naam';

  @override
  String get enterAName => 'Kies een naam';

  @override
  String get enterDescription => 'Kies een beschrijving\n\n\n';

  @override
  String get failedSaveProfile =>
      'Het is niet gelukt om het profiel op te slaan.';

  @override
  String get fetchingExistingProfile => 'Bestaand profiel ophalen';

  @override
  String get uploadingNewProfile => 'Nieuw profiel uploaden...';

  @override
  String get almostDone => 'Bijna klaar...';

  @override
  String get saving => 'Opslaan...';

  @override
  String get save => 'Opslaan';

  @override
  String get language => 'Taal';

  @override
  String get saveWallet => 'Wallet opslaan';

  @override
  String get saveText1 =>
      'Verlies je wallet niet! Bookmark deze pagina of bewaar het unieke adres met je private key op een veilige plek.';

  @override
  String get gettheapp => 'De app downloaden';

  @override
  String get appstorebadge => 'app store badge';

  @override
  String get googleplaybadge => 'google play badge';

  @override
  String get opentheapp => 'Open de app';

  @override
  String get open => 'Open';

  @override
  String get copyyouruniquewalletURL => 'Kopieer je unieke wallet link';

  @override
  String get emailtoyourselfyourwalleturl => 'Email je wallet link naar jezelf';

  @override
  String get shareText1 => 'Laat iemand anders deze QR-code scannen. ';

  @override
  String get shareText2 =>
      'Indien ze nog geen wallet hebben, wordt er een nieuwe Citizen Wallet aangemaakt op hun apparaat.';

  @override
  String get editname => 'Naam wijzigen';

  @override
  String get export => 'Exporteer';

  @override
  String get cancel => 'Annuleer';

  @override
  String get enteraccountname => 'Account naam ingeven';

  @override
  String get exportAccount => 'Exporteer Account';

  @override
  String get deleteaccount => 'Verwijder account';

  @override
  String get deleteaccountMsg1 =>
      'Weet je zeker dat je deze account wilt verwijderen?';

  @override
  String get deleteaccountMsg2 =>
      'Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get profileText1 => 'Het lijkt erop dat je nog geen profiel hebt. ';

  @override
  String get share => 'Deel link';

  @override
  String get cancelRefund => 'Annuleer & Terugbetaling';

  @override
  String get returnFunds => 'Retourneer tokens';

  @override
  String get returnVoucher => 'Cancel voucher';

  @override
  String get returnVoucherMsg => 'wordt teruggestort in je wallet';

  @override
  String get deleteVoucher => 'Verwijder Voucher';

  @override
  String get deleteVoucherMsg =>
      'Hierdoor wordt de voucher uit de lijst verwijderd.';

  @override
  String get wallet => 'Wallet';

  @override
  String get voucherAmount => 'Voucher bedrag';

  @override
  String get enteramount => 'Geef bedrag in';

  @override
  String get vouchericon => 'voucher icon';

  @override
  String get vouchersMsg => 'Je vouchers verschijnen hier';

  @override
  String get createVoucher => 'Creëer Voucher';

  @override
  String get returnText => 'Terug';

  @override
  String get redeemed => 'geclaimd';

  @override
  String get issued => 'gecreëerd';

  @override
  String get communities => 'Gemeenschappen';

  @override
  String get invalidlink => 'Ongeldige link';

  @override
  String get unabltohandlelink => 'Kan link niet verwerken';

  @override
  String get dismiss => 'Annuleer';

  @override
  String get to => 'naar NL';

  @override
  String get minting => 'Minting';

  @override
  String get externalWallet => 'Externe Wallet';

  @override
  String get resetQRCode => 'Reset QR Code';

  @override
  String get amount => 'Bedrag';

  @override
  String get descriptionMsg => 'Voeg beschrijving toe';

  @override
  String get clear => 'Wis';

  @override
  String get done => 'Gereed';

  @override
  String get settings => 'Settings';

  @override
  String get sent => 'Verzonden';

  @override
  String failedSend(Object currencyName) {
    return 'Verzenden van $currencyName is niet gelukt.';
  }

  @override
  String failedMint(Object currencyName) {
    return 'Minten van $currencyName is niet gelukt.';
  }

  @override
  String get onText => 'op';

  @override
  String get invalidQRCode => 'Ongeldige QR Code';

  @override
  String get enterManually => 'Handmatig invoeren';

  @override
  String get scanAgain => 'Scan opnieuw';

  @override
  String get max => 'max';

  @override
  String get insufficientFunds => 'Onvoldoende fondsen.';

  @override
  String currentBalance(Object formattedBalance) {
    return 'Huidige balans: $formattedBalance';
  }

  @override
  String get sendDescription => 'Beschrijving toevoegen\n\n\n';

  @override
  String get chooseRecipient => 'Kies ontvanger';

  @override
  String get createdBy => 'Gedaan door';

  @override
  String get redeem => 'Claim';

  @override
  String get voucher => 'Voucher';

  @override
  String get createVoucherText =>
      'Maak een voucher die iedereen kan claimen voor het bovenstaande bedrag.';

  @override
  String get emptyBalanceText1 => 'Deze bon is al ingewisseld.';

  @override
  String get emptyBalanceText2 => 'Claim deze voucher op je account';

  @override
  String get tapToScan => 'Tik om te scannen';

  @override
  String get communityCurrentlyOffline => 'Gemeenschap momenteel offline';

  @override
  String get topup => 'Opwaarderen';

  @override
  String get close => 'Sluiten';

  @override
  String get more => 'Meer';

  @override
  String get start => 'Start';

  @override
  String get connecting => 'Verbinding maken';

  @override
  String get accountNotFound => 'Account niet gevonden';
}
