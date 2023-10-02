import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
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

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({
    Key? key,
  }) : super(key: key);

  @override
  EditProfileModalState createState() => EditProfileModalState();
}

class EditProfileModalState extends State<EditProfileModal> {
  final UsernameFormatter usernameFormatter = UsernameFormatter();
  final NameFormatter nameFormatter = NameFormatter();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  late ProfileLogic _logic;

  late Debounce debouncedHandleUsernameUpdate;
  late Debounce debouncedHandleNameUpdate;
  late Debounce debouncedHandleDescriptionUpdate;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);

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

    HapticFeedback.lightImpact();

    final wallet = context.read<WalletState>().wallet;

    final success = await _logic.save(
      ProfileV1(
        account: wallet?.account ?? '',
      ),
      image,
    );

    if (!success) {
      return;
    }

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleUpdate() async {
    final navigator = GoRouter.of(context);

    HapticFeedback.lightImpact();

    final wallet = context.read<WalletState>().wallet;

    final success = await _logic.update(
      ProfileV1(
        account: wallet?.account ?? '',
      ),
    );

    if (!success) {
      return;
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: hasProfile ? 'Edit' : 'Create',
                actionButton: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: ThemeColors.touchable.resolveFrom(context),
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
                                        borderColor: ThemeColors.subtle,
                                      )
                                    : ProfileCircle(
                                        size: 160,
                                        imageUrl: image,
                                        borderColor: ThemeColors.subtle,
                                      ),
                                CupertinoButton(
                                  onPressed: handleSelectPhoto,
                                  padding: const EdgeInsets.all(0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ThemeColors.backgroundTransparent
                                          .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    height: 160,
                                    width: 160,
                                    child: Center(
                                      child: Icon(
                                        CupertinoIcons.photo,
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Username',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: usernameController,
                              placeholder: 'Enter a username',
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
                                        color: ThemeColors.danger,
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
                                        color: ThemeColors.border
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
                                            color: ThemeColors.subtle
                                                .resolveFrom(context),
                                          )
                                        : Icon(
                                            CupertinoIcons.at,
                                            size: 16,
                                            color: ThemeColors.text
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
                                        ? "Please pick a username."
                                        : "This username is already taken.",
                                    style: TextStyle(
                                      color: ThemeColors.danger
                                          .resolveFrom(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Name',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: nameController,
                              placeholder: 'Enter a name',
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
                                  color:
                                      ThemeColors.border.resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                              onSubmitted: (_) {
                                descriptionFocusNode.requestFocus();
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Description',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: descriptionController,
                              placeholder: 'Enter a description',
                              minLines: 4,
                              maxLines: 8,
                              maxLength: 200,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.newline,
                              onChanged: handleDescriptionUpdate,
                              focusNode: descriptionFocusNode,
                              decoration: BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color:
                                      ThemeColors.border.resolveFrom(context),
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
                                    color: ThemeColors.subtleEmphasis
                                        .resolveFrom(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 60),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   crossAxisAlignment: CrossAxisAlignment.center,
                            //   children: [
                            //     loading
                            //         ? CupertinoActivityIndicator(
                            //             color: ThemeColors.subtle
                            //                 .resolveFrom(context),
                            //           )
                            //         : Button(
                            //             text: 'Save',
                            //             color: ThemeColors.surfacePrimary
                            //                 .resolveFrom(context),
                            //             labelColor: ThemeColors.black,
                            //             onPressed: isInvalid
                            //                 ? null
                            //                 : editingImage == null ||
                            //                         editingImageExt == null
                            //                     ? () => handleUpdate()
                            //                     : () => handleSave(editingImage,
                            //                         editingImageExt),
                            //           ),
                            //   ],
                            // ),
                            const SizedBox(height: 10),
                            if (!loading && error)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Failed to save profile.",
                                    style: TextStyle(
                                      color: ThemeColors.danger
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
                                  color:
                                      ThemeColors.subtle.resolveFrom(context),
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
                                        'Fetching existing profile...',
                                      ProfileUpdateState.uploading =>
                                        'Uploading new profile...',
                                      ProfileUpdateState.fetching =>
                                        'Almost done...',
                                      _ => 'Saving...',
                                    },
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: ThemeColors.subtleText
                                          .resolveFrom(context),
                                    ),
                                  )
                                ],
                                if (!loading)
                                  Button(
                                    text: 'Save',
                                    color: ThemeColors.surfacePrimary
                                        .resolveFrom(context),
                                    labelColor: ThemeColors.black,
                                    onPressed: isInvalid
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
