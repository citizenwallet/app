import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WalletRow extends StatefulWidget {
  final CWWallet wallet;
  final bool isSelected;
  final bool bottomBorder;
  final Map<String, CommunityConfig> communities;
  final Map<String, ProfileItem> profiles;
  final void Function()? onTap;
  final void Function()? onMore;
  final void Function()? onProfileEdit;
  final void Function(String)? onLoadProfile;

  const WalletRow(
    this.wallet, {
    super.key,
    this.isSelected = false,
    this.bottomBorder = true,
    this.communities = const {},
    this.profiles = const {},
    this.onTap,
    this.onMore,
    this.onProfileEdit,
    this.onLoadProfile,
  });

  @override
  WalletRowState createState() => WalletRowState();
}

class WalletRowState extends State<WalletRow> {
  @override
  void didUpdateWidget(WalletRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onLoadProfile != null &&
        oldWidget.wallet.account != widget.wallet.account &&
        widget.wallet.account.isNotEmpty) {
      widget.onLoadProfile!(widget.wallet.account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final isSelected = widget.isSelected;
    final bottomBorder = widget.bottomBorder;
    final communities = widget.communities;
    final profiles = widget.profiles;
    final onTap = widget.onTap;
    final onMore = widget.onMore;
    final onProfileEdit = widget.onProfileEdit;

    final community = communities[wallet.alias];
    final profile =
        wallet.account.isEmpty ? null : profiles[wallet.account]?.profile;

    final Widget child = Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          height: 84,
          decoration: BoxDecoration(
            color: isSelected
                ? ThemeColors.primary.resolveFrom(context).withOpacity(0.1)
                : ThemeColors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 54,
                width: 54,
                child: Stack(
                  children: [
                    ProfileCircle(
                      size: 50,
                      imageUrl: profile?.imageSmall,
                      borderWidth: 2,
                      borderColor: community != null
                          ? Color(community.theme.primary)
                          : ThemeColors.transparent,
                    ),
                    if (community != null && community.logo != '')
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ProfileCircle(
                          size: 30,
                          imageUrl: community.logo,
                          borderColor: ThemeColors.transparent,
                          backgroundColor: ThemeColors.white,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name != null && profile!.name.isNotEmpty
                          ? profile.name
                          : wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: ThemeColors.text.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 1),
                    if (profile != null)
                      Text(
                        '@${profile.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: ThemeColors.subtleText.resolveFrom(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              if (onMore != null)
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: onMore,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: ThemeColors.touchable.resolveFrom(context),
                  ),
                ),
              if (onProfileEdit != null)
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: onProfileEdit,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: ThemeColors.surfacePrimary
                          .resolveFrom(context)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: ThemeColors.primary.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.pencil,
                          color: ThemeColors.primary.resolveFrom(context),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        if (wallet.locked)
          Positioned(
            top: 18,
            right: 4,
            child: Icon(
              CupertinoIcons.lock,
              size: 18,
              color: ThemeColors.text.resolveFrom(context),
            ),
          ),
        if (bottomBorder)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Divider(
              color: ThemeColors.subtle.resolveFrom(context),
              height: 1,
            ),
          )
      ],
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}
