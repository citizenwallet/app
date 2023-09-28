import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';

class ProfileQRBadge extends StatelessWidget {
  final ProfileV1? profile;

  final String profileLink;
  final bool loading;
  final bool showQRCode;

  final Function(String) handleCopy;

  const ProfileQRBadge({
    Key? key,
    this.profile,
    this.profileLink = '',
    this.loading = false,
    this.showQRCode = false,
    required this.handleCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final hasNoProfile = profile == null;

    return SizedBox(
      height: width,
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: ThemeColors.white.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              (loading || hasNoProfile) ? 20 : 40,
            ),
            margin: const EdgeInsets.only(top: 80),
            child: AnimatedOpacity(
              opacity: showQRCode ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: QR(
                data: profileLink,
                size: width - 140,
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: loading
                ? const PulsingContainer(
                    height: 100,
                    width: 100,
                    borderRadius: 50,
                  )
                : ProfileCircle(
                    size: 100,
                    imageUrl: profile?.imageMedium,
                    borderColor: ThemeColors.subtle,
                  ),
          ),
          if (!hasNoProfile && !loading)
            Positioned(
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                    ),
                    child: Text(
                      '@${profile?.username ?? ''}',
                      style: TextStyle(
                        color: ThemeColors.black.resolveFrom(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
