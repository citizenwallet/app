import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';

class ProfileBadge extends StatelessWidget {
  final ProfileV1? profile;
  final bool loading;
  final void Function()? onTap;

  const ProfileBadge({
    Key? key,
    this.profile,
    this.loading = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onTap,
      padding: const EdgeInsets.all(0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!loading && profile != null)
            ProfileCircle(
              size: 80,
              imageUrl: profile!.imageSmall,
            ),
          if (loading)
            const PulsingContainer(
              height: 80,
              width: 80,
              borderRadius: 40,
            ),
          if (!loading && profile != null)
            Positioned(
              bottom: 2,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      ThemeColors.backgroundTransparent75.resolveFrom(context),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                  border: Border.all(
                    color: ThemeColors.subtle.resolveFrom(context),
                  ),
                ),
                constraints: const BoxConstraints(
                  maxWidth: 80,
                ),
                padding: const EdgeInsets.all(4),
                child: Text(
                  '@${profile!.name}',
                  style: TextStyle(
                      fontSize: 12,
                      color: ThemeColors.text.resolveFrom(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (loading)
            const Positioned(
              bottom: 2,
              child: PulsingContainer(
                height: 14,
                width: 80,
                borderRadius: 10,
              ),
            ),
        ],
      ),
    );
  }
}
