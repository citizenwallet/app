import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';

class WalletRow extends StatelessWidget {
  final CWWallet wallet;
  final bool isSelected;
  final void Function()? onTap;
  final void Function()? onMore;

  const WalletRow(
    this.wallet, {
    super.key,
    this.isSelected = false,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        key: super.key,
        children: [
          Container(
            key: super.key,
            margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            height: 84,
            decoration: BoxDecoration(
              color: ThemeColors.subtle.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 2,
                color: isSelected
                    ? ThemeColors.primary.resolveFrom(context)
                    : ThemeColors.uiBackgroundAlt.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                const ProfileCircle(
                  size: 50,
                  imageUrl: 'assets/icons/profile.svg',
                  backgroundColor: ThemeColors.white,
                  borderColor: ThemeColors.subtle,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      wallet.account.isEmpty
                          ? const PulsingContainer(
                              height: 14,
                              width: 100,
                            )
                          : Text(
                              formatHexAddress(wallet.account),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color:
                                    ThemeColors.subtleText.resolveFrom(context),
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
        ],
      ),
    );
  }
}
