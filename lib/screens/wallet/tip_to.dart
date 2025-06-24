// import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/profile/profile_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class TipToScreen extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic? profilesLogic;

  final bool isMinting;
  final bool isTip;

  const TipToScreen({
    super.key,
    required this.walletLogic,
    this.profilesLogic,
    this.isMinting = false,
    this.isTip = false,
  });

  @override
  State<TipToScreen> createState() => _TipToScreenState();
}

class _TipToScreenState extends State<TipToScreen> {
  final nameFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late void Function() debouncedAddressUpdate;

  @override
  void initState() {
    super.initState();
    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      final walletLogic = widget.walletLogic;

      onLoad();

      debouncedAddressUpdate = debounce(
        walletLogic.updateAddress,
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    _scrollController.dispose();

    final walletLogic = widget.walletLogic;
    walletLogic.clearAddressController();

    super.dispose();
  }

  void onLoad() async {
    final walletLogic = widget.walletLogic;
    final profilesLogic = widget.profilesLogic;

    profilesLogic?.allProfiles();
    walletLogic.updateAddress();

    nameFocusNode.requestFocus();
  }

  void handleThrottledUpdateAddress(String value) {
    final profilesLogic = widget.profilesLogic;

    debouncedAddressUpdate();
    profilesLogic?.searchProfile(value);
  }

  void handleAddressFieldSubmitted(String value) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleSelectProfile(BuildContext context, ProfileV1? profile) async {
    if (profile == null) {
      return;
    }

    final walletLogic = widget.walletLogic;
    final profilesLogic = widget.profilesLogic;

    profilesLogic?.selectProfile(profile);
    walletLogic.updateAddress(override: true);
    FocusManager.instance.primaryFocus?.unfocus();

    if (!context.mounted) {
      return;
    }

    context.pop(profile.account);
  }

  void handleDismissSelection() async {
    final walletLogic = widget.walletLogic;
    widget.profilesLogic?.deSelectProfile();

    walletLogic.clearAddressController();
    walletLogic.updateAddress();

    nameFocusNode.requestFocus();
  }

  void handleScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void clearSearch() {
    final profilesLogic = widget.profilesLogic;
    profilesLogic?.clearSearch(notify: false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final walletLogic = widget.walletLogic;

    final invalidAddress = context.select(
      (WalletState state) => state.invalidAddress,
    );

    final config = context.select(
      (WalletState state) => state.config,
    );

    final hasAddress = context.select(
      (WalletState state) => state.hasAddress,
    );

    final searchLoading = context.select(
      (ProfilesState state) => state.searchLoading,
    );

    final profileSuggestions = context.select(selectProfileSuggestions);

    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );

    final bool noAccountFound = profileSuggestions.isEmpty &&
        walletLogic.addressController.value.text.isNotEmpty &&
        !isEthAddress(walletLogic.addressController.value.text);

    return Container(
      height: height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          bottom: false,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  5,
                  0,
                  5,
                  10,
                ),
                child: Header(
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => context.pop(),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: Theme.of(context)
                          .colors
                          .touchable
                          .resolveFrom(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          floating: false,
                          delegate: PersistentHeaderDelegate(
                            expandedHeight: 80,
                            minHeight: 50,
                            builder: (context, shrink) => GestureDetector(
                              onTap: handleScrollToTop,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 110,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.5, 1.0],
                                          colors: [
                                            Theme.of(context)
                                                .colors
                                                .uiBackgroundAlt
                                                .resolveFrom(context),
                                            Theme.of(context)
                                                .colors
                                                .uiBackgroundAlt
                                                .resolveFrom(context)
                                                .withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selectedProfile != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: ProfileChip(
                                        selectedProfile: selectedProfile,
                                        handleDeSelect: handleDismissSelection,
                                      ),
                                    ),
                                  if (selectedProfile == null)
                                    Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: CupertinoTextField(
                                          controller:
                                              walletLogic.addressController,
                                          placeholder:
                                              AppLocalizations.of(context)!
                                                  .searchUserAndAddress,
                                          maxLines: 1,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          focusNode: nameFocusNode,
                                          textInputAction: TextInputAction.done,
                                          onChanged:
                                              handleThrottledUpdateAddress,
                                          decoration: invalidAddress
                                              ? BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .subtle
                                                      .resolveFrom(context),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colors
                                                        .danger,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                )
                                              : BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .subtle
                                                      .resolveFrom(context),
                                                  border: Border.all(
                                                    color: hasAddress
                                                        ? Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context)
                                                        : Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                          prefix: const SizedBox(
                                            width: 10,
                                          ),
                                          suffix: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                10,
                                                0,
                                                20,
                                                0,
                                              ),
                                              child: searchLoading
                                                  ? SizedBox(
                                                      height: 20,
                                                      width: 24,
                                                      child:
                                                          CupertinoActivityIndicator(
                                                        color: Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context),
                                                      ),
                                                    )
                                                  : Icon(
                                                      CupertinoIcons.search,
                                                      color: Theme.of(context)
                                                          .colors
                                                          .primary
                                                          .resolveFrom(context),
                                                    ),
                                            ),
                                          ),
                                          onSubmitted:
                                              handleAddressFieldSubmitted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (noAccountFound)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
                                    color: Theme.of(context)
                                        .colors
                                        .subtleEmphasis
                                        .resolveFrom(context),
                                    size: 100,
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .accountNotFound,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colors
                                          .subtleSolid
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!noAccountFound)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: profileSuggestions.length,
                              (context, index) {
                                final profile = profileSuggestions[index];

                                return Padding(
                                  key: Key(profile.account),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                  child: ProfileRow(
                                    profile: profile,
                                    loading: false,
                                    onTap: () =>
                                        handleSelectProfile(context, profile),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context)
                                  .withOpacity(0.0),
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!invalidAddress && hasAddress)
                      Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Button(
                              text: AppLocalizations.of(context)!.done,
                              labelColor: Theme.of(context)
                                  .colors
                                  .white
                                  .resolveFrom(context),
                              onPressed: () =>
                                  handleSelectProfile(context, selectedProfile),
                              minWidth: 200,
                              maxWidth: width - 60,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
