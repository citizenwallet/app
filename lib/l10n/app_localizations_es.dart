// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get viewContract => 'Ver contrato';

  @override
  String get confirm => 'Confirmar';

  @override
  String get welcomeCitizen => '¡Bienvenido, ciudadano!';

  @override
  String get aWalletForYourCommunity => 'Esta es tu nueva billetera, donde puedes almacenar, enviar y recibir los tokens de tu comunidad.';

  @override
  String get createNewAccount => 'Crear nueva cuenta';

  @override
  String get scanFromCommunity => 'Escanea un código QR de tu comunidad';

  @override
  String get or => 'O';

  @override
  String get browseCommunities => 'Explorar comunidades';

  @override
  String get recoverfrombackup => 'Recuperar desde copia de seguridad';

  @override
  String get recoverIndividualAccountFromaPrivatekey => 'Recuperar cuenta individual desde una clave privada';

  @override
  String get createNewAccountMsg => 'Crea un perfil para facilitar que las personas te envíen tokens.';

  @override
  String get settingsScrApp => 'Aplicación';

  @override
  String get createaprofile => 'Crear un perfil';

  @override
  String get edit => 'Editar';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get about => 'Acerca de';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get inappsounds => 'Sonidos en la aplicación';

  @override
  String viewOn(Object name) {
    return 'Ver en $name';
  }

  @override
  String get accounts => 'Cuentas';

  @override
  String get account => 'Cuenta';

  @override
  String get cards => 'Tarjetas';

  @override
  String get yourContactsWillAppearHere => 'Tus contactos aparecerán aquí';

  @override
  String get accountsAndroidBackupsuseAndroid => 'Las copias de seguridad usan la copia automática de Android y siguen la configuración de respaldo de tu dispositivo automáticamente.';

  @override
  String get accountsAndroidIfYouInstalltheAppAgain => 'Si instalas la aplicación nuevamente en otro dispositivo que comparta la misma cuenta de Google, se usará la copia de seguridad cifrada para restaurar tus cuentas.';

  @override
  String get accountsAndroidYouraccounts => 'Tus cuentas y las copias de seguridad de tus cuentas son generadas y poseídas por ti.';

  @override
  String get accountsAndroidManuallyExported => 'Pueden ser exportadas manualmente en cualquier momento.';

  @override
  String get accountsApYouraccountsarebackedup => 'Tus cuentas están respaldadas en el llavero de tu iPhone y siguen tu configuración de respaldo automáticamente.';

  @override
  String get accountsApSyncthisiPhone => 'Habilitar \"Sincronizar este iPhone\" asegurará que el llavero de tu iPhone se respalde en iCloud.';

  @override
  String get accountsApYoucancheck => 'Puedes verificar si la sincronización está habilitada en la aplicación Configuración yendo a: ID de Apple > iCloud > Contraseñas y Llavero.';

  @override
  String get accountsApYouraccounts => 'Tus cuentas y las copias de seguridad de tus cuentas son generadas y poseídas por ti.';

  @override
  String get accountsApTheycanbe => 'Pueden ser exportadas manualmente en cualquier momento.';

  @override
  String get initialAddress => 'Dirección inicial:';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get clearDataAndBackups => 'Borrar datos y copias de seguridad';

  @override
  String get replaceExistingBackup => 'Reemplazar copia de seguridad existente';

  @override
  String get replace => 'Reemplazar';

  @override
  String get androidBackupTexlineOne => 'Ya existe una copia de seguridad en tu cuenta de Google Drive con diferentes credenciales.';

  @override
  String get androidBackupTexlineTwo => '¿Estás seguro de que quieres reemplazarla?';

  @override
  String get appResetTexlineOne => '¿Estás seguro de que quieres borrar todo?';

  @override
  String get appResetTexlineTwo => 'Esta acción no se puede deshacer.';

  @override
  String get delete => 'Eliminar';

  @override
  String get endToEndEncryption => 'Cifrado de extremo a extremo';

  @override
  String get endToEndEncryptionSub => 'Las copias de seguridad siempre están cifradas de extremo a extremo.';

  @override
  String get accountsSubLableOne => 'Todas tus cuentas se respaldan automáticamente en el llavero de tu dispositivo y se sincronizan con tu llavero de iCloud.';

  @override
  String accountsSubLableLastBackUp(Object lastBackup) {
    return 'Tus cuentas están respaldadas en tu cuenta de Google Drive. Última copia de seguridad: $lastBackup.';
  }

  @override
  String get accountsSubLableLastBackUpSecond => 'Respalda tus cuentas en tu cuenta de Google Drive.';

  @override
  String get auto => 'automático';

  @override
  String varsion(Object buildNumber, Object version) {
    return 'Versión $version ($buildNumber)';
  }

  @override
  String get transactionDetais => 'Detalles de la transacción';

  @override
  String get transactionID => 'ID de la transacción';

  @override
  String get date => 'Fecha';

  @override
  String get description => 'Descripción';

  @override
  String get reply => 'Responder';

  @override
  String get sendAgain => 'Enviar de nuevo';

  @override
  String get voucherCreating => 'Creando vale...';

  @override
  String get voucherFunding => 'Financiando vale...';

  @override
  String get voucherRedeemed => 'Vale canjeado';

  @override
  String get voucherCreated => 'Vale creado';

  @override
  String get voucherCreateFailed => 'Falló la creación del vale';

  @override
  String get anonymous => 'Anónimo';

  @override
  String get minted => 'Acuñado';

  @override
  String get noDescription => 'sin descripción';

  @override
  String get preparingWallet => 'Preparando billetera...';

  @override
  String get transactions => 'Historial de transacciones';

  @override
  String get citizenWallet => 'Billetera Ciudadana';

  @override
  String get aWlletRorYourCommunity => 'Una billetera para tu comunidad';

  @override
  String get openingYourWallet => 'Abriendo tu billetera...';

  @override
  String get continueText => 'Continuar';

  @override
  String get copied => 'Copiado';

  @override
  String get copyText => 'Copiar';

  @override
  String get backupDate => 'Fecha de copia de seguridad: ';

  @override
  String get decryptBackup => 'Descifrar copia de seguridad';

  @override
  String get googleDriveAccount => 'Cuenta de Google Drive: ';

  @override
  String get noKeysFoundTryManually => 'No se encontraron claves, intenta ingresar manualmente.';

  @override
  String get getEncryptionKeyFromYourPasswordManager => 'Obtén la clave de cifrado desde tu administrador de contraseñas';

  @override
  String get invalidKeyEncryptionKey => 'Clave de cifrado inválida.';

  @override
  String get enterEncryptionKeyManually => 'Ingresa la clave de cifrado manualmente';

  @override
  String get enterEncryptionKey => 'Ingresa la clave de cifrado';

  @override
  String get encryptionKey => 'Clave de cifrado';

  @override
  String get loading => 'Cargando';

  @override
  String get joinCommunity => 'Unirse a la comunidad';

  @override
  String get importText => 'Importar';

  @override
  String get selectAccount => 'Seleccionar cuenta';

  @override
  String get hello => 'Hola';

  @override
  String get thisIsYourWallet => 'Esta es tu billetera.';

  @override
  String get itLivesInTheLinkOfThisPage => 'Vive en el enlace de esta página.';

  @override
  String get itIsUniqueToYouAndYourCommunity => 'Es único para ti y tu comunidad.';

  @override
  String get keepYourLink => 'Mantén tu enlace privado para asegurarte de que solo tú tengas acceso a esta billetera.';

  @override
  String get send => 'Enviar';

  @override
  String get sending => 'Enviando';

  @override
  String get swipeToMint => 'Desliza para acuñar';

  @override
  String get swipeToSend => 'Desliza para enviar';

  @override
  String get swipeToConfirm => 'Desliza para confirmar';

  @override
  String get receive => 'Recibir';

  @override
  String get request => 'Solicitar';

  @override
  String get retry => 'Reintentar';

  @override
  String get searchUserAndAddress => 'Busca un usuario o pega una dirección';

  @override
  String get sendViaLink => 'Enviar por enlace';

  @override
  String get scanQRCode => 'Escanear código QR';

  @override
  String get sendToNFCTag => 'Enviar a una etiqueta NFC';

  @override
  String get mint => 'Acuñar';

  @override
  String get vouchers => 'Vales';

  @override
  String get noBackupFound => 'No se encontró copia de seguridad';

  @override
  String get selectAnotherAccount => 'Seleccionar otra cuenta';

  @override
  String get recoverIndividualAccount => 'Recuperar cuenta individual desde una clave privada';

  @override
  String get restoreAllAccountsGoogleDrive => 'Restaurar todas las cuentas desde Google Drive';

  @override
  String get infoActionLayoutDescription => 'Se te pedirá que inicies sesión en tu cuenta de Google. Solo solicitaremos acceso a la carpeta de esta aplicación en tu Google Drive.';

  @override
  String get connectYourGoogleDriveAccount => 'Conecta tu cuenta de Google Drive';

  @override
  String get recoverIndividualAccountPrivateKey => 'Recuperar cuenta individual desde una clave privada';

  @override
  String get create => 'Crear';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get enterAUsername => 'Ingresa un nombre de usuario';

  @override
  String get pleasePickAUsername => 'Por favor, elige un nombre de usuario.';

  @override
  String get thisUsernameIsAlreadyTaken => 'Este nombre de usuario ya está tomado.';

  @override
  String get name => 'Nombre';

  @override
  String get enterAName => 'Ingresa un nombre';

  @override
  String get enterDescription => 'Ingresa una descripción\n\n\n';

  @override
  String get failedSaveProfile => 'No se pudo guardar el perfil.';

  @override
  String get fetchingExistingProfile => 'Obteniendo perfil existente...';

  @override
  String get uploadingNewProfile => 'Subiendo nuevo perfil...';

  @override
  String get almostDone => 'Casi listo...';

  @override
  String get saving => 'Guardando...';

  @override
  String get save => 'Guardar';

  @override
  String get language => 'Idioma';

  @override
  String get saveWallet => 'Guardar billetera';

  @override
  String get saveText1 => '¡No pierdas tu billetera! Marca esta página como favorita o guarda su dirección única que contiene tu clave privada en un lugar seguro.';

  @override
  String get gettheapp => 'Alternativamente, puedes descargar la aplicación Citizen Wallet e importar tu billetera allí.';

  @override
  String get appstorebadge => 'insignia de la tienda de aplicaciones';

  @override
  String get googleplaybadge => 'insignia de Google Play';

  @override
  String get opentheapp => 'Una vez instalada, puedes importar tu billetera web en la aplicación.';

  @override
  String get open => 'Importar en la aplicación';

  @override
  String get copyyouruniquewalletURL => 'Copia la URL única de tu billetera';

  @override
  String get emailtoyourselfyourwalleturl => 'Envía por correo a ti mismo la URL de tu billetera';

  @override
  String get shareText1 => 'Pide a alguien más que escanee este código QR.';

  @override
  String get shareText2 => 'Si no tienen una, se creará una nueva Billetera Ciudadana en su dispositivo.';

  @override
  String get editname => 'Editar nombre';

  @override
  String get export => 'Exportar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get enteraccountname => 'Ingresa el nombre de la cuenta';

  @override
  String get exportAccount => 'Exportar cuenta';

  @override
  String get deleteaccount => 'Eliminar cuenta';

  @override
  String get deleteaccountMsg1 => '¿Estás seguro de que quieres eliminar esta cuenta?';

  @override
  String get deleteaccountMsg2 => 'Esta acción no se puede deshacer.';

  @override
  String get profileText1 => 'Parece que aún no tienes un perfil.';

  @override
  String get share => 'Compartir enlace';

  @override
  String get cancelRefund => 'Cancelar y reembolsar';

  @override
  String get returnFunds => 'Devolver fondos';

  @override
  String get returnVoucher => 'Devolver vale';

  @override
  String get returnVoucherMsg => 'será devuelto a tu billetera.';

  @override
  String get deleteVoucher => 'Eliminar vale';

  @override
  String get deleteVoucherMsg => 'Esto eliminará el vale de la lista.';

  @override
  String get wallet => 'Billetera';

  @override
  String get voucherAmount => 'Monto del vale';

  @override
  String get enteramount => 'Ingresa el monto';

  @override
  String get vouchericon => 'ícono de vale';

  @override
  String get vouchersMsg => 'Tus vales aparecerán aquí';

  @override
  String get createVoucher => 'Crear vale';

  @override
  String get returnText => 'Devolver';

  @override
  String get redeemed => 'canjeado';

  @override
  String get issued => 'emitido';

  @override
  String get communities => 'Comunidades';

  @override
  String get invalidlink => 'Enlace inválido';

  @override
  String get unabltohandlelink => 'No se puede manejar el enlace';

  @override
  String get dismiss => 'Descartar';

  @override
  String get to => 'A';

  @override
  String get minting => 'Acuñando';

  @override
  String get externalWallet => 'Billetera externa';

  @override
  String get resetQRCode => 'Restablecer código QR';

  @override
  String get amount => 'Monto';

  @override
  String get descriptionMsg => 'Agregar una descripción';

  @override
  String get clear => 'Borrar';

  @override
  String get done => 'Hecho';

  @override
  String get settings => 'Configuraciones';

  @override
  String get sent => 'Enviado';

  @override
  String failedSend(Object currencyName) {
    return 'No se pudo enviar $currencyName.';
  }

  @override
  String failedMint(Object currencyName) {
    return 'No se pudo acuñar $currencyName.';
  }

  @override
  String get onText => 'en';

  @override
  String get invalidQRCode => 'Código QR inválido';

  @override
  String get enterManually => 'Ingresar manualmente';

  @override
  String get scanAgain => 'Escanear de nuevo';

  @override
  String get max => 'máx';

  @override
  String get insufficientFunds => 'Fondos insuficientes.';

  @override
  String currentBalance(Object formattedBalance) {
    return 'Saldo actual: $formattedBalance';
  }

  @override
  String get sendDescription => 'Agregar una descripción\n\n\n';

  @override
  String get chooseRecipient => 'Elegir destinatario';

  @override
  String get createdBy => 'Creado por';

  @override
  String get redeem => 'Canjear';

  @override
  String get voucher => 'Vale';

  @override
  String get createVoucherText => 'Crea un vale que cualquiera pueda canjear por el monto mostrado arriba.';

  @override
  String get emptyBalanceText1 => 'Este vale ya ha sido canjeado.';

  @override
  String get emptyBalanceText2 => 'Canjea este vale en tu cuenta.';

  @override
  String get tapToScan => 'Toca para escanear';

  @override
  String get communityCurrentlyOffline => 'Comunidad actualmente fuera de línea';

  @override
  String get topup => 'Recargar';

  @override
  String get close => 'Cerrar';

  @override
  String get more => 'Más';

  @override
  String get start => 'Iniciar';

  @override
  String get connecting => 'Conectando';

  @override
  String get accountNotFound => 'Cuenta no encontrada';
}
