import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileRow extends StatelessWidget {
  final ProfileV1? profile;
  final bool loading;
  final bool active;
  final double size;
  final double fontSize;
  final void Function()? onTap;

  const ProfileRow({
    super.key,
    this.profile,
    this.loading = false,
    this.active = false,
    this.size = 60,
    this.fontSize = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: active
            ? Border.all(
                width: 2,
                color: Theme.of(context)
                    .colors
                    .subtleEmphasis
                    .resolveFrom(context),
              )
            : null,
        borderRadius: const BorderRadius.all(
          Radius.circular(8.0),
        ),
      ),
      child: CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ProfileCircle(
              size: size,
              backgroundColor:
                  Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
              imageUrl: profile?.imageSmall,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name != null && profile!.name.isNotEmpty
                        ? profile!.name
                        : AppLocalizations.of(context)!.anonymous,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colors.text.resolveFrom(context),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: Text(
                      '@${profile?.username ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context)
                            .colors
                            .subtleText
                            .resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
