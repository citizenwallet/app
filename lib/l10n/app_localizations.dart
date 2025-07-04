import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

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
    Locale('es'),
    Locale('fr'),
    Locale('nl')
  ];

  /// No description provided for @viewContract.
  ///
  /// In en, this message translates to:
  /// **'View Contract'**
  String get viewContract;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @confirmActionSub.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm this action?'**
  String get confirmActionSub;

  /// No description provided for @welcomeCitizen.
  ///
  /// In en, this message translates to:
  /// **'Welcome, citizen!'**
  String get welcomeCitizen;

  /// No description provided for @aWalletForYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'This is your new wallet, where you can store, send and receive the tokens of your community.'**
  String get aWalletForYourCommunity;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new Account'**
  String get createNewAccount;

  /// No description provided for @scanFromCommunity.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code from your community'**
  String get scanFromCommunity;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @browseCommunities.
  ///
  /// In en, this message translates to:
  /// **'Browse Communities'**
  String get browseCommunities;

  /// No description provided for @recoverfrombackup.
  ///
  /// In en, this message translates to:
  /// **'Recover from backup'**
  String get recoverfrombackup;

  /// No description provided for @recoverIndividualAccountFromaPrivatekey.
  ///
  /// In en, this message translates to:
  /// **'Recover Individual Account from a private key'**
  String get recoverIndividualAccountFromaPrivatekey;

  /// No description provided for @createNewAccountMsg.
  ///
  /// In en, this message translates to:
  /// **'Create a profile to make it easier for people to send you tokens.'**
  String get createNewAccountMsg;

  /// No description provided for @settingsScrApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsScrApp;

  /// No description provided for @createaprofile.
  ///
  /// In en, this message translates to:
  /// **'Create a profile'**
  String get createaprofile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @inappsounds.
  ///
  /// In en, this message translates to:
  /// **'In-app sounds'**
  String get inappsounds;

  /// No description provided for @viewOn.
  ///
  /// In en, this message translates to:
  /// **'View On {name}'**
  String viewOn(Object name);

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @yourContactsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your contacts will appear here'**
  String get yourContactsWillAppearHere;

  /// No description provided for @accountsAndroidBackupsuseAndroid.
  ///
  /// In en, this message translates to:
  /// **'Backups use Android Auto Backup and follow your device\\\'s backup settings automatically.'**
  String get accountsAndroidBackupsuseAndroid;

  /// No description provided for @accountsAndroidIfYouInstalltheAppAgain.
  ///
  /// In en, this message translates to:
  /// **'If you install the app again on another device which shares the same Google account, the encrypted backup will be used to restore your accounts.'**
  String get accountsAndroidIfYouInstalltheAppAgain;

  /// No description provided for @accountsAndroidYouraccounts.
  ///
  /// In en, this message translates to:
  /// **'Your accounts and your account backups are generated and owned by you.'**
  String get accountsAndroidYouraccounts;

  /// No description provided for @accountsAndroidManuallyExported.
  ///
  /// In en, this message translates to:
  /// **'They can be manually exported at any time.'**
  String get accountsAndroidManuallyExported;

  /// No description provided for @accountsApYouraccountsarebackedup.
  ///
  /// In en, this message translates to:
  /// **'Your accounts are backed up to your iPhone\\\'s Keychain and follow your backup settings automatically.'**
  String get accountsApYouraccountsarebackedup;

  /// No description provided for @accountsApSyncthisiPhone.
  ///
  /// In en, this message translates to:
  /// **'Enabling \"Sync this iPhone\" will ensure that your iPhone\\\'s keychain gets backed up to iCloud.'**
  String get accountsApSyncthisiPhone;

  /// No description provided for @accountsApYoucancheck.
  ///
  /// In en, this message translates to:
  /// **'You can check if syncing is enabled in your Settings app by going to: Apple ID > iCloud > Passwords and Keychain.'**
  String get accountsApYoucancheck;

  /// No description provided for @accountsApYouraccounts.
  ///
  /// In en, this message translates to:
  /// **'Your accounts and your account backups are generated and owned by you.'**
  String get accountsApYouraccounts;

  /// No description provided for @accountsApTheycanbe.
  ///
  /// In en, this message translates to:
  /// **'They can be manually exported at any time.'**
  String get accountsApTheycanbe;

  /// No description provided for @initialAddress.
  ///
  /// In en, this message translates to:
  /// **'Initial Address:'**
  String get initialAddress;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @clearDataAndBackups.
  ///
  /// In en, this message translates to:
  /// **'Clear data & backups'**
  String get clearDataAndBackups;

  /// No description provided for @replaceExistingBackup.
  ///
  /// In en, this message translates to:
  /// **'Replace existing backup'**
  String get replaceExistingBackup;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @androidBackupTexlineOne.
  ///
  /// In en, this message translates to:
  /// **'There is already a backup on your Google Drive account from different credentials.'**
  String get androidBackupTexlineOne;

  /// No description provided for @androidBackupTexlineTwo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to replace it?'**
  String get androidBackupTexlineTwo;

  /// No description provided for @appResetTexlineOne.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete everything?'**
  String get appResetTexlineOne;

  /// No description provided for @appResetTexlineTwo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get appResetTexlineTwo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @endToEndEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption'**
  String get endToEndEncryption;

  /// No description provided for @endToEndEncryptionSub.
  ///
  /// In en, this message translates to:
  /// **'Backups are always end-to-end encrypted.'**
  String get endToEndEncryptionSub;

  /// No description provided for @accountsSubLableOne.
  ///
  /// In en, this message translates to:
  /// **'All your accounts are automatically backed up to your device\'s keychain and synced with your iCloud keychain.'**
  String get accountsSubLableOne;

  /// No description provided for @accountsSubLableLastBackUp.
  ///
  /// In en, this message translates to:
  /// **'Your accounts are backed up to your Google Drive account. Last backup: {lastBackup}.'**
  String accountsSubLableLastBackUp(Object lastBackup);

  /// No description provided for @accountsSubLableLastBackUpSecond.
  ///
  /// In en, this message translates to:
  /// **'Back up your accounts to your Google Drive account.'**
  String get accountsSubLableLastBackUpSecond;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get auto;

  /// No description provided for @varsion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String varsion(Object buildNumber, Object version);

  /// No description provided for @transactionDetais.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetais;

  /// No description provided for @transactionID.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionID;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sendAgain;

  /// No description provided for @voucherCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating voucher...'**
  String get voucherCreating;

  /// No description provided for @voucherFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding voucher...'**
  String get voucherFunding;

  /// No description provided for @voucherRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher redeemed'**
  String get voucherRedeemed;

  /// No description provided for @voucherCreated.
  ///
  /// In en, this message translates to:
  /// **'Voucher created'**
  String get voucherCreated;

  /// No description provided for @voucherCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Voucher creation failed'**
  String get voucherCreateFailed;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @minted.
  ///
  /// In en, this message translates to:
  /// **'Minted'**
  String get minted;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'no description'**
  String get noDescription;

  /// No description provided for @preparingWallet.
  ///
  /// In en, this message translates to:
  /// **'Preparing wallet...'**
  String get preparingWallet;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get transactions;

  /// No description provided for @citizenWallet.
  ///
  /// In en, this message translates to:
  /// **'Citizen Wallet'**
  String get citizenWallet;

  /// No description provided for @aWlletRorYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'A wallet for your community'**
  String get aWlletRorYourCommunity;

  /// No description provided for @openingYourWallet.
  ///
  /// In en, this message translates to:
  /// **'Opening your wallet...'**
  String get openingYourWallet;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyText;

  /// No description provided for @backupDate.
  ///
  /// In en, this message translates to:
  /// **'Backup date: '**
  String get backupDate;

  /// No description provided for @decryptBackup.
  ///
  /// In en, this message translates to:
  /// **'Decrypt backup'**
  String get decryptBackup;

  /// No description provided for @googleDriveAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Drive account: '**
  String get googleDriveAccount;

  /// No description provided for @noKeysFoundTryManually.
  ///
  /// In en, this message translates to:
  /// **'No keys found, try entering manually.'**
  String get noKeysFoundTryManually;

  /// No description provided for @getEncryptionKeyFromYourPasswordManager.
  ///
  /// In en, this message translates to:
  /// **'Get encryption key from your Password Manager'**
  String get getEncryptionKeyFromYourPasswordManager;

  /// No description provided for @invalidKeyEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid key encryption key.'**
  String get invalidKeyEncryptionKey;

  /// No description provided for @enterEncryptionKeyManually.
  ///
  /// In en, this message translates to:
  /// **'Enter encryption key manually'**
  String get enterEncryptionKeyManually;

  /// No description provided for @enterEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Enter encryption key'**
  String get enterEncryptionKey;

  /// No description provided for @encryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Encryption key'**
  String get encryptionKey;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get joinCommunity;

  /// No description provided for @importText.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importText;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @thisIsYourWallet.
  ///
  /// In en, this message translates to:
  /// **'This is your wallet.'**
  String get thisIsYourWallet;

  /// No description provided for @itLivesInTheLinkOfThisPage.
  ///
  /// In en, this message translates to:
  /// **'It lives in the link of this page.'**
  String get itLivesInTheLinkOfThisPage;

  /// No description provided for @itIsUniqueToYouAndYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'It is unique to you and your community.'**
  String get itIsUniqueToYouAndYourCommunity;

  /// No description provided for @keepYourLink.
  ///
  /// In en, this message translates to:
  /// **'Keep your link private to make sure only you have access to this wallet.'**
  String get keepYourLink;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @swipeToMint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to mint'**
  String get swipeToMint;

  /// No description provided for @swipeToSend.
  ///
  /// In en, this message translates to:
  /// **'Swipe to send'**
  String get swipeToSend;

  /// No description provided for @swipeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Swipe to confirm'**
  String get swipeToConfirm;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @searchUserAndAddress.
  ///
  /// In en, this message translates to:
  /// **'Search user or paste address'**
  String get searchUserAndAddress;

  /// No description provided for @sendViaLink.
  ///
  /// In en, this message translates to:
  /// **'Send via link'**
  String get sendViaLink;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @sendToNFCTag.
  ///
  /// In en, this message translates to:
  /// **'Send to an NFC tag'**
  String get sendToNFCTag;

  /// No description provided for @mint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get mint;

  /// No description provided for @vouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get vouchers;

  /// No description provided for @noBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No backup found'**
  String get noBackupFound;

  /// No description provided for @selectAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Select another account'**
  String get selectAnotherAccount;

  /// No description provided for @recoverIndividualAccount.
  ///
  /// In en, this message translates to:
  /// **'Recover individual account from a private key'**
  String get recoverIndividualAccount;

  /// No description provided for @restoreAllAccountsGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore all accounts from Google Drive'**
  String get restoreAllAccountsGoogleDrive;

  /// No description provided for @infoActionLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'You will be asked to log in to your Google account. We will only request access to this app\\\'s folder in your Google Drive.'**
  String get infoActionLayoutDescription;

  /// No description provided for @connectYourGoogleDriveAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google Drive Account'**
  String get connectYourGoogleDriveAccount;

  /// No description provided for @recoverIndividualAccountPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Recover individual account from a private key'**
  String get recoverIndividualAccountPrivateKey;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterAUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get enterAUsername;

  /// No description provided for @pleasePickAUsername.
  ///
  /// In en, this message translates to:
  /// **'Please pick a username.'**
  String get pleasePickAUsername;

  /// No description provided for @thisUsernameIsAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get thisUsernameIsAlreadyTaken;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter a description\n\n\n'**
  String get enterDescription;

  /// No description provided for @failedSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile.'**
  String get failedSaveProfile;

  /// No description provided for @fetchingExistingProfile.
  ///
  /// In en, this message translates to:
  /// **'Fetching existing profile...'**
  String get fetchingExistingProfile;

  /// No description provided for @uploadingNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Uploading new profile...'**
  String get uploadingNewProfile;

  /// No description provided for @almostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done...'**
  String get almostDone;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @saveWallet.
  ///
  /// In en, this message translates to:
  /// **'Save Wallet'**
  String get saveWallet;

  /// No description provided for @saveText1.
  ///
  /// In en, this message translates to:
  /// **'Don\'t lose your wallet! Bookmark this page or save its unique address that contains your private key in a safe place.'**
  String get saveText1;

  /// No description provided for @gettheapp.
  ///
  /// In en, this message translates to:
  /// **'Alternatively, you can download the Citizen Wallet app and import your wallet there.'**
  String get gettheapp;

  /// No description provided for @appstorebadge.
  ///
  /// In en, this message translates to:
  /// **'app store badge'**
  String get appstorebadge;

  /// No description provided for @googleplaybadge.
  ///
  /// In en, this message translates to:
  /// **'google play badge'**
  String get googleplaybadge;

  /// No description provided for @opentheapp.
  ///
  /// In en, this message translates to:
  /// **'Once installed, you can import your web wallet in the app.'**
  String get opentheapp;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Import in the app'**
  String get open;

  /// No description provided for @copyyouruniquewalletURL.
  ///
  /// In en, this message translates to:
  /// **'Copy your unique wallet URL'**
  String get copyyouruniquewalletURL;

  /// No description provided for @emailtoyourselfyourwalleturl.
  ///
  /// In en, this message translates to:
  /// **'Email to yourself your wallet url'**
  String get emailtoyourselfyourwalleturl;

  /// No description provided for @shareText1.
  ///
  /// In en, this message translates to:
  /// **'Get someone else to scan this QR code.'**
  String get shareText1;

  /// No description provided for @shareText2.
  ///
  /// In en, this message translates to:
  /// **'If they don\'t already have one, it will create a new Citizen Wallet on their device.'**
  String get shareText2;

  /// No description provided for @editname.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editname;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enteraccountname.
  ///
  /// In en, this message translates to:
  /// **'Enter account name'**
  String get enteraccountname;

  /// No description provided for @exportAccount.
  ///
  /// In en, this message translates to:
  /// **'Export Account'**
  String get exportAccount;

  /// No description provided for @deleteaccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteaccount;

  /// No description provided for @deleteaccountMsg1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get deleteaccountMsg1;

  /// No description provided for @deleteaccountMsg2.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteaccountMsg2;

  /// No description provided for @profileText1.
  ///
  /// In en, this message translates to:
  /// **'It looks like you don\'t have a profile yet.'**
  String get profileText1;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get share;

  /// No description provided for @cancelRefund.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Refund'**
  String get cancelRefund;

  /// No description provided for @returnFunds.
  ///
  /// In en, this message translates to:
  /// **'Return Funds'**
  String get returnFunds;

  /// No description provided for @returnVoucher.
  ///
  /// In en, this message translates to:
  /// **'Return Voucher'**
  String get returnVoucher;

  /// No description provided for @returnVoucherMsg.
  ///
  /// In en, this message translates to:
  /// **'will be returned to your wallet.'**
  String get returnVoucherMsg;

  /// No description provided for @deleteVoucher.
  ///
  /// In en, this message translates to:
  /// **'Delete Voucher'**
  String get deleteVoucher;

  /// No description provided for @deleteVoucherMsg.
  ///
  /// In en, this message translates to:
  /// **'This will remove the voucher from the list.'**
  String get deleteVoucherMsg;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @voucherAmount.
  ///
  /// In en, this message translates to:
  /// **'Voucher Amount'**
  String get voucherAmount;

  /// No description provided for @enteramount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enteramount;

  /// No description provided for @vouchericon.
  ///
  /// In en, this message translates to:
  /// **'voucher icon'**
  String get vouchericon;

  /// No description provided for @vouchersMsg.
  ///
  /// In en, this message translates to:
  /// **'Your vouchers will appear here'**
  String get vouchersMsg;

  /// No description provided for @createVoucher.
  ///
  /// In en, this message translates to:
  /// **'Create Voucher'**
  String get createVoucher;

  /// No description provided for @returnText.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnText;

  /// No description provided for @redeemed.
  ///
  /// In en, this message translates to:
  /// **'redeemed'**
  String get redeemed;

  /// No description provided for @issued.
  ///
  /// In en, this message translates to:
  /// **'issued'**
  String get issued;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @invalidlink.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get invalidlink;

  /// No description provided for @unabltohandlelink.
  ///
  /// In en, this message translates to:
  /// **'Unable to handle link'**
  String get unabltohandlelink;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @minting.
  ///
  /// In en, this message translates to:
  /// **'Minting'**
  String get minting;

  /// No description provided for @externalWallet.
  ///
  /// In en, this message translates to:
  /// **'External Wallet'**
  String get externalWallet;

  /// No description provided for @resetQRCode.
  ///
  /// In en, this message translates to:
  /// **'Reset QR Code'**
  String get resetQRCode;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @descriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get descriptionMsg;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @failedSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send {currencyName}.'**
  String failedSend(Object currencyName);

  /// No description provided for @failedMint.
  ///
  /// In en, this message translates to:
  /// **'Failed to mint {currencyName}.'**
  String failedMint(Object currencyName);

  /// No description provided for @onText.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get onText;

  /// No description provided for @invalidQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get invalidQRCode;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'max'**
  String get max;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds.'**
  String get insufficientFunds;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {formattedBalance}'**
  String currentBalance(Object formattedBalance);

  /// No description provided for @sendDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a description\n\n\n'**
  String get sendDescription;

  /// No description provided for @chooseRecipient.
  ///
  /// In en, this message translates to:
  /// **'Choose Recipient'**
  String get chooseRecipient;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// No description provided for @voucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get voucher;

  /// No description provided for @createVoucherText.
  ///
  /// In en, this message translates to:
  /// **'Create a voucher which anyone can redeem for the amount shown above.'**
  String get createVoucherText;

  /// No description provided for @emptyBalanceText1.
  ///
  /// In en, this message translates to:
  /// **'This voucher has already been redeemed.'**
  String get emptyBalanceText1;

  /// No description provided for @emptyBalanceText2.
  ///
  /// In en, this message translates to:
  /// **'Redeem this voucher to your account.'**
  String get emptyBalanceText2;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan'**
  String get tapToScan;

  /// No description provided for @communityCurrentlyOffline.
  ///
  /// In en, this message translates to:
  /// **'Community currently offline'**
  String get communityCurrentlyOffline;

  /// No description provided for @topup.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get topup;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFound;
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
      <String>['en', 'es', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
