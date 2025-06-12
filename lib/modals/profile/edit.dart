import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/loaders/progress_bar.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({
    super.key,
  });

  @override
  EditProfileModalState createState() => EditProfileModalState();
}

class EditProfileModalState extends State<EditProfileModal> {
  final UsernameFormatter usernameFormatter = UsernameFormatter();
  final NameFormatter nameFormatter = NameFormatter();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  late ProfileLogic _logic;
  late WalletLogic _walletLogic;
  late NotificationsLogic _notificationsLogic;

  late Debounce debouncedHandleUsernameUpdate;
  late Debounce debouncedHandleNameUpdate;
  late Debounce debouncedHandleDescriptionUpdate;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);
    _notificationsLogic = NotificationsLogic(context);
    _walletLogic = WalletLogic(context, _notificationsLogic);

    debouncedHandleUsernameUpdate = debounce(
      (String username) {
        _logic.checkUsername(username);
      },
      const Duration(milliseconds: 500),
    );

    debouncedHandleNameUpdate = debounce(
      (String username) {
        _logic.updateNameErrorState(username);
      },
      const Duration(milliseconds: 250),
    );

    debouncedHandleDescriptionUpdate = debounce(
      (String username) {
        _logic.updateDescriptionText(username);
      },
      const Duration(milliseconds: 250),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _logic.startEdit();
  }

  @override
  void dispose() {
    debouncedHandleUsernameUpdate.cancel();
    debouncedHandleNameUpdate.cancel();
    debouncedHandleDescriptionUpdate.cancel();
    _logic.resetEdit();
    super.dispose();
  }

  void handleUsernameUpdate(String username) {
    debouncedHandleUsernameUpdate([username]);
  }

  void handleNameUpdate(String name) {
    debouncedHandleNameUpdate([name]);
  }

  void handleDescriptionUpdate(String desc) {
    debouncedHandleDescriptionUpdate([desc]);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.lightImpact();
  }

  void handleSave(Uint8List? image) async {
    final navigator = GoRouter.of(context);

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();

    final wallet = context.read<WalletState>().wallet;
    final newName = context.read<ProfileState>().nameController.value.text;

    if (wallet == null) {
      return;
    }

    final success = await _logic.save(
      ProfileV1(
        account: wallet.account,
      ),
      image,
    );

    if (!success) {
      return;
    }

    if (newName.isNotEmpty) {
      await _walletLogic.editWallet(wallet.account, wallet.alias, newName);
    }

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleUpdate() async {
    final navigator = GoRouter.of(context);

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();

    final wallet = context.read<WalletState>().wallet;
    final newName = context.read<ProfileState>().nameController.value.text;

    if (wallet == null) {
      return;
    }

    final success = await _logic.update(
      ProfileV1(
        account: wallet.account,
      ),
    );

    if (!success) {
      return;
    }

    if (newName.isNotEmpty) {
      await _walletLogic.editWallet(wallet.account, wallet.alias, newName);
    }

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleSelectPhoto() {
    HapticFeedback.lightImpact();

    _logic.selectPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((ProfileState state) => state.loading);
    final error = context.select((ProfileState state) => state.error);

    final ready = context.select((WalletState state) => state.ready);
    final readyLoading =
        context.select((WalletState state) => state.readyLoading);

    final config = context.select((WalletState state) => state.config);

    final updateState =
        context.select((ProfileState state) => state.updateState);

    final image = context.select((ProfileState state) => state.image);
    final editingImage =
        context.select((ProfileState state) => state.editingImage);

    final usernameController = context.watch<ProfileState>().usernameController;
    final usernameLoading =
        context.select((ProfileState state) => state.usernameLoading);
    final usernameError =
        context.select((ProfileState state) => state.usernameError);

    final nameController = context.watch<ProfileState>().nameController;

    final descriptionController =
        context.watch<ProfileState>().descriptionController;
    final descriptionEditText =
        context.select((ProfileState state) => state.descriptionEdit);

    final username = context.select((ProfileState state) => state.username);
    final hasProfile = username.isNotEmpty;

    final isInvalid = usernameError || usernameController.value.text == '';

    final disableSave = config?.online == false || isInvalid;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: hasProfile
                    ? AppLocalizations.of(context)!.edit
                    : AppLocalizations.of(context)!.create,
                actionButton: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color:
                        Theme.of(context).colors.touchable.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ListView(
                          controller: ModalScrollController.of(context),
                          physics: const ScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                editingImage != null
                                    ? ProfileCircle(
                                        size: 160,
                                        imageBytes: editingImage,
                                        borderColor:
                                            Theme.of(context).colors.subtle,
                                      )
                                    : ProfileCircle(
                                        size: 160,
                                        imageUrl: image,
                                        borderColor:
                                            Theme.of(context).colors.subtle,
                                      ),
                                CupertinoButton(
                                  onPressed: handleSelectPhoto,
                                  padding: const EdgeInsets.all(0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colors
                                          .backgroundTransparent
                                          .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    height: 160,
                                    width: 160,
                                    child: Center(
                                      child: Icon(
                                        CupertinoIcons.photo,
                                        color: Theme.of(context)
                                            .colors
                                            .text
                                            .resolveFrom(context),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)!.username,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: usernameController,
                              placeholder:
                                  AppLocalizations.of(context)!.enterAUsername,
                              maxLines: 1,
                              maxLength: 30,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              onChanged: handleUsernameUpdate,
                              inputFormatters: [
                                usernameFormatter,
                              ],
                              decoration: usernameError
                                  ? BoxDecoration(
                                      color: const CupertinoDynamicColor
                                          .withBrightness(
                                        color: CupertinoColors.white,
                                        darkColor: CupertinoColors.black,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context).colors.danger,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(5.0)),
                                    )
                                  : BoxDecoration(
                                      color: const CupertinoDynamicColor
                                          .withBrightness(
                                        color: CupertinoColors.white,
                                        darkColor: CupertinoColors.black,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colors
                                            .border
                                            .resolveFrom(context),
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(5.0)),
                                    ),
                              prefix: SizedBox(
                                height: 30,
                                width: 30,
                                child: Center(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: usernameLoading
                                        ? CupertinoActivityIndicator(
                                            color: Theme.of(context)
                                                .colors
                                                .subtle
                                                .resolveFrom(context),
                                          )
                                        : Icon(
                                            CupertinoIcons.at,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colors
                                                .text
                                                .resolveFrom(context),
                                          ),
                                  ),
                                ),
                              ),
                              onSubmitted: (_) {
                                nameFocusNode.requestFocus();
                              },
                            ),
                            const SizedBox(height: 10),
                            if (usernameError)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    usernameController.value.text == ''
                                        ? AppLocalizations.of(context)!
                                            .pleasePickAUsername
                                        : AppLocalizations.of(context)!
                                            .thisUsernameIsAlreadyTaken,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colors
                                          .danger
                                          .resolveFrom(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)!.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: nameController,
                              placeholder:
                                  AppLocalizations.of(context)!.enterAName,
                              maxLines: 1,
                              maxLength: 50,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              onChanged: handleNameUpdate,
                              inputFormatters: [
                                nameFormatter,
                              ],
                              focusNode: nameFocusNode,
                              decoration: BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colors
                                      .border
                                      .resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                              onSubmitted: (_) {
                                descriptionFocusNode.requestFocus();
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)!.description,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: descriptionController,
                              placeholder: AppLocalizations.of(context)!
                                  .enterDescription, // hack to align to top
                              minLines: 4,
                              maxLines: 8,
                              maxLength: 200,
                              autocorrect: false,
                              enableSuggestions: false,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              onChanged: handleDescriptionUpdate,
                              focusNode: descriptionFocusNode,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colors
                                      .border
                                      .resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${descriptionEditText.length} / 200',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .subtleEmphasis
                                        .resolveFrom(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 60),
                            const SizedBox(height: 10),
                            if (!loading && error)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .failedSaveProfile,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colors
                                          .danger
                                          .resolveFrom(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        width: width,
                        child: BlurryChild(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context)
                                      .colors
                                      .subtle
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              children: [
                                if (loading) ...[
                                  SizedBox(
                                    height: 25,
                                    child: Center(
                                      child: ProgressBar(
                                        updateState.progress,
                                        width: width - 40,
                                        height: 16,
                                        borderRadius: 8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    switch (updateState) {
                                      ProfileUpdateState.existing =>
                                        AppLocalizations.of(context)!
                                            .fetchingExistingProfile,
                                      ProfileUpdateState.uploading =>
                                        AppLocalizations.of(context)!
                                            .uploadingNewProfile,
                                      ProfileUpdateState.fetching =>
                                        AppLocalizations.of(context)!
                                            .almostDone,
                                      _ => AppLocalizations.of(context)!.saving,
                                    },
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colors
                                          .subtleText
                                          .resolveFrom(context),
                                    ),
                                  )
                                ],
                                if (!loading && !readyLoading && ready)
                                  Button(
                                    text: AppLocalizations.of(context)!.save,
                                    color: Theme.of(context)
                                        .colors
                                        .primary
                                        .resolveFrom(context),
                                    labelColor: Theme.of(context).colors.black,
                                    onPressed: disableSave
                                        ? null
                                        : hasProfile && editingImage == null
                                            ? () => handleUpdate()
                                            : () => handleSave(
                                                  editingImage,
                                                ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
