// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get viewContract => 'View Contract';

  @override
  String get confirm => 'Confirm';

  @override
  String get welcomeCitizen => 'Welcome, citizen!';

  @override
  String get aWalletForYourCommunity => 'This is your new wallet, where you can store, send and receive the tokens of your community.';

  @override
  String get createNewAccount => 'Create new Account';

  @override
  String get scanFromCommunity => 'Scan a QR code from your community';

  @override
  String get or => 'OR';

  @override
  String get browseCommunities => 'Browse Communities';

  @override
  String get recoverfrombackup => 'Recover from backup';

  @override
  String get recoverIndividualAccountFromaPrivatekey => 'Recover Individual Account from a private key';

  @override
  String get createNewAccountMsg => 'Create a profile to make it easier for people to send you tokens.';

  @override
  String get settingsScrApp => 'App';

  @override
  String get createaprofile => 'Create a profile';

  @override
  String get edit => 'Edit';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get about => 'About';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get inappsounds => 'In-app sounds';

  @override
  String viewOn(Object name) {
    return 'View On $name';
  }

  @override
  String get accounts => 'Accounts';

  @override
  String get account => 'Account';

  @override
  String get cards => 'Cards';

  @override
  String get yourContactsWillAppearHere => 'Your contacts will appear here';

  @override
  String get accountsAndroidBackupsuseAndroid => 'Backups use Android Auto Backup and follow your device\\\'s backup settings automatically.';

  @override
  String get accountsAndroidIfYouInstalltheAppAgain => 'If you install the app again on another device which shares the same Google account, the encrypted backup will be used to restore your accounts.';

  @override
  String get accountsAndroidYouraccounts => 'Your accounts and your account backups are generated and owned by you.';

  @override
  String get accountsAndroidManuallyExported => 'They can be manually exported at any time.';

  @override
  String get accountsApYouraccountsarebackedup => 'Your accounts are backed up to your iPhone\\\'s Keychain and follow your backup settings automatically.';

  @override
  String get accountsApSyncthisiPhone => 'Enabling \"Sync this iPhone\" will ensure that your iPhone\\\'s keychain gets backed up to iCloud.';

  @override
  String get accountsApYoucancheck => 'You can check if syncing is enabled in your Settings app by going to: Apple ID > iCloud > Passwords and Keychain.';

  @override
  String get accountsApYouraccounts => 'Your accounts and your account backups are generated and owned by you.';

  @override
  String get accountsApTheycanbe => 'They can be manually exported at any time.';

  @override
  String get initialAddress => 'Initial Address:';

  @override
  String get notifications => 'Notifications';

  @override
  String get backup => 'Backup';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get clearDataAndBackups => 'Clear data & backups';

  @override
  String get replaceExistingBackup => 'Replace existing backup';

  @override
  String get replace => 'Replace';

  @override
  String get androidBackupTexlineOne => 'There is already a backup on your Google Drive account from different credentials.';

  @override
  String get androidBackupTexlineTwo => 'Are you sure you want to replace it?';

  @override
  String get appResetTexlineOne => 'Are you sure you want to delete everything?';

  @override
  String get appResetTexlineTwo => 'This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get endToEndEncryption => 'End-to-end encryption';

  @override
  String get endToEndEncryptionSub => 'Backups are always end-to-end encrypted.';

  @override
  String get accountsSubLableOne => 'All your accounts are automatically backed up to your device\'s keychain and synced with your iCloud keychain.';

  @override
  String accountsSubLableLastBackUp(Object lastBackup) {
    return 'Your accounts are backed up to your Google Drive account. Last backup: $lastBackup.';
  }

  @override
  String get accountsSubLableLastBackUpSecond => 'Back up your accounts to your Google Drive account.';

  @override
  String get auto => 'auto';

  @override
  String varsion(Object buildNumber, Object version) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get transactionDetais => 'Transaction details';

  @override
  String get transactionID => 'Transaction ID';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get reply => 'Reply';

  @override
  String get sendAgain => 'Send again';

  @override
  String get voucherCreating => 'Creating voucher...';

  @override
  String get voucherFunding => 'Funding voucher...';

  @override
  String get voucherRedeemed => 'Voucher redeemed';

  @override
  String get voucherCreated => 'Voucher created';

  @override
  String get voucherCreateFailed => 'Voucher creation failed';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get minted => 'Minted';

  @override
  String get noDescription => 'no description';

  @override
  String get preparingWallet => 'Preparing wallet...';

  @override
  String get transactions => 'Transaction history';

  @override
  String get citizenWallet => 'Citizen Wallet';

  @override
  String get aWlletRorYourCommunity => 'A wallet for your community';

  @override
  String get openingYourWallet => 'Opening your wallet...';

  @override
  String get continueText => 'Continue';

  @override
  String get copied => 'Copied';

  @override
  String get copyText => 'Copy';

  @override
  String get backupDate => 'Backup date: ';

  @override
  String get decryptBackup => 'Decrypt backup';

  @override
  String get googleDriveAccount => 'Google Drive account: ';

  @override
  String get noKeysFoundTryManually => 'No keys found, try entering manually.';

  @override
  String get getEncryptionKeyFromYourPasswordManager => 'Get encryption key from your Password Manager';

  @override
  String get invalidKeyEncryptionKey => 'Invalid key encryption key.';

  @override
  String get enterEncryptionKeyManually => 'Enter encryption key manually';

  @override
  String get enterEncryptionKey => 'Enter encryption key';

  @override
  String get encryptionKey => 'Encryption key';

  @override
  String get loading => 'Loading';

  @override
  String get joinCommunity => 'Join Community';

  @override
  String get importText => 'Import';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get hello => 'Hello';

  @override
  String get thisIsYourWallet => 'This is your wallet.';

  @override
  String get itLivesInTheLinkOfThisPage => 'It lives in the link of this page.';

  @override
  String get itIsUniqueToYouAndYourCommunity => 'It is unique to you and your community.';

  @override
  String get keepYourLink => 'Keep your link private to make sure only you have access to this wallet.';

  @override
  String get send => 'Send';

  @override
  String get sending => 'Sending';

  @override
  String get swipeToMint => 'Swipe to mint';

  @override
  String get swipeToSend => 'Swipe to send';

  @override
  String get swipeToConfirm => 'Swipe to confirm';

  @override
  String get receive => 'Receive';

  @override
  String get request => 'Request';

  @override
  String get retry => 'Retry';

  @override
  String get searchUserAndAddress => 'Search user or paste address';

  @override
  String get sendViaLink => 'Send via link';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get sendToNFCTag => 'Send to an NFC tag';

  @override
  String get mint => 'Mint';

  @override
  String get vouchers => 'Vouchers';

  @override
  String get noBackupFound => 'No backup found';

  @override
  String get selectAnotherAccount => 'Select another account';

  @override
  String get recoverIndividualAccount => 'Recover individual account from a private key';

  @override
  String get restoreAllAccountsGoogleDrive => 'Restore all accounts from Google Drive';

  @override
  String get infoActionLayoutDescription => 'You will be asked to log in to your Google account. We will only request access to this app\\\'s folder in your Google Drive.';

  @override
  String get connectYourGoogleDriveAccount => 'Connect your Google Drive Account';

  @override
  String get recoverIndividualAccountPrivateKey => 'Recover individual account from a private key';

  @override
  String get create => 'Create';

  @override
  String get username => 'Username';

  @override
  String get enterAUsername => 'Enter a username';

  @override
  String get pleasePickAUsername => 'Please pick a username.';

  @override
  String get thisUsernameIsAlreadyTaken => 'This username is already taken.';

  @override
  String get name => 'Name';

  @override
  String get enterAName => 'Enter a name';

  @override
  String get enterDescription => 'Enter a description\n\n\n';

  @override
  String get failedSaveProfile => 'Failed to save profile.';

  @override
  String get fetchingExistingProfile => 'Fetching existing profile...';

  @override
  String get uploadingNewProfile => 'Uploading new profile...';

  @override
  String get almostDone => 'Almost done...';

  @override
  String get saving => 'Saving...';

  @override
  String get save => 'Save';

  @override
  String get language => 'Language';

  @override
  String get saveWallet => 'Save Wallet';

  @override
  String get saveText1 => 'Don\'t lose your wallet! Bookmark this page or save its unique address that contains your private key in a safe place.';

  @override
  String get gettheapp => 'Alternatively, you can download the Citizen Wallet app and import your wallet there.';

  @override
  String get appstorebadge => 'app store badge';

  @override
  String get googleplaybadge => 'google play badge';

  @override
  String get opentheapp => 'Once installed, you can import your web wallet in the app.';

  @override
  String get open => 'Import in the app';

  @override
  String get copyyouruniquewalletURL => 'Copy your unique wallet URL';

  @override
  String get emailtoyourselfyourwalleturl => 'Email to yourself your wallet url';

  @override
  String get shareText1 => 'Get someone else to scan this QR code.';

  @override
  String get shareText2 => 'If they don\'t already have one, it will create a new Citizen Wallet on their device.';

  @override
  String get editname => 'Edit name';

  @override
  String get export => 'Export';

  @override
  String get cancel => 'Cancel';

  @override
  String get enteraccountname => 'Enter account name';

  @override
  String get exportAccount => 'Export Account';

  @override
  String get deleteaccount => 'Delete account';

  @override
  String get deleteaccountMsg1 => 'Are you sure you want to delete this account?';

  @override
  String get deleteaccountMsg2 => 'This action cannot be undone.';

  @override
  String get profileText1 => 'It looks like you don\'t have a profile yet.';

  @override
  String get share => 'Share link';

  @override
  String get cancelRefund => 'Cancel & Refund';

  @override
  String get returnFunds => 'Return Funds';

  @override
  String get returnVoucher => 'Return Voucher';

  @override
  String get returnVoucherMsg => 'will be returned to your wallet.';

  @override
  String get deleteVoucher => 'Delete Voucher';

  @override
  String get deleteVoucherMsg => 'This will remove the voucher from the list.';

  @override
  String get wallet => 'Wallet';

  @override
  String get voucherAmount => 'Voucher Amount';

  @override
  String get enteramount => 'Enter amount';

  @override
  String get vouchericon => 'voucher icon';

  @override
  String get vouchersMsg => 'Your vouchers will appear here';

  @override
  String get createVoucher => 'Create Voucher';

  @override
  String get returnText => 'Return';

  @override
  String get redeemed => 'redeemed';

  @override
  String get issued => 'issued';

  @override
  String get communities => 'Communities';

  @override
  String get invalidlink => 'Invalid link';

  @override
  String get unabltohandlelink => 'Unable to handle link';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get to => 'To';

  @override
  String get minting => 'Minting';

  @override
  String get externalWallet => 'External Wallet';

  @override
  String get resetQRCode => 'Reset QR Code';

  @override
  String get amount => 'Amount';

  @override
  String get descriptionMsg => 'Add a description';

  @override
  String get clear => 'Clear';

  @override
  String get done => 'Done';

  @override
  String get settings => 'Settings';

  @override
  String get sent => 'Sent';

  @override
  String failedSend(Object currencyName) {
    return 'Failed to send $currencyName.';
  }

  @override
  String failedMint(Object currencyName) {
    return 'Failed to mint $currencyName.';
  }

  @override
  String get onText => 'on';

  @override
  String get invalidQRCode => 'Invalid QR Code';

  @override
  String get enterManually => 'Enter Manually';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get max => 'max';

  @override
  String get insufficientFunds => 'Insufficient funds.';

  @override
  String currentBalance(Object formattedBalance) {
    return 'Current balance: $formattedBalance';
  }

  @override
  String get sendDescription => 'Add a description\n\n\n';

  @override
  String get chooseRecipient => 'Choose Recipient';

  @override
  String get createdBy => 'Created by';

  @override
  String get redeem => 'Redeem';

  @override
  String get voucher => 'Voucher';

  @override
  String get createVoucherText => 'Create a voucher which anyone can redeem for the amount shown above.';

  @override
  String get emptyBalanceText1 => 'This voucher has already been redeemed.';

  @override
  String get emptyBalanceText2 => 'Redeem this voucher to your account.';

  @override
  String get tapToScan => 'Tap to scan';

  @override
  String get communityCurrentlyOffline => 'Community currently offline';

  @override
  String get topup => 'Top Up';

  @override
  String get close => 'Close';

  @override
  String get more => 'More';

  @override
  String get start => 'Start';

  @override
  String get connecting => 'Connecting';

  @override
  String get accountNotFound => 'Account not found';
}
