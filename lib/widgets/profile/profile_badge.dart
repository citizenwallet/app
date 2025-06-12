import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class ProfileBadge extends StatelessWidget {
  final ProfileV1? profile;
  final bool loading;
  final double size;
  final double fontSize;
  final double? borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final void Function()? onTap;

  const ProfileBadge({
    super.key,
    this.profile,
    this.loading = false,
    this.size = 80,
    this.fontSize = 12,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onTap,
      padding: const EdgeInsets.all(0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!loading)
            ProfileCircle(
              size: size,
              borderWidth: borderWidth,
              borderColor: borderColor,
              backgroundColor: backgroundColor,
              imageUrl: profile == null
                  ? null
                  : size < 128
                      ? profile!.imageSmall
                      : size < 256
                          ? profile!.imageMedium
                          : profile!.image,
            ),
          if (loading)
            PulsingContainer(
              height: size,
              width: size,
              borderRadius: size / 2,
            ),
          if (!loading && profile != null)
            Positioned(
              bottom: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colors
                      .backgroundTransparent75
                      .resolveFrom(context),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colors.subtle.resolveFrom(context),
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: size,
                ),
                padding: const EdgeInsets.all(4),
                child: Text(
                  profile!.name.isNotEmpty
                      ? profile!.name
                      : profile!.username.isNotEmpty
                          ? '@${profile!.username}'
                          : AppLocalizations.of(context)!.anonymous,
                  style: TextStyle(
                      fontSize: fontSize,
                      color:
                          Theme.of(context).colors.text.resolveFrom(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (loading)
            Positioned(
              bottom: 2,
              child: PulsingContainer(
                height: 14,
                width: size,
                borderRadius: 10,
              ),
            ),
        ],
      ),
    );
  }
}
