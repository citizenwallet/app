import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileChip extends StatelessWidget {
  final ProfileV1? selectedProfile;
  final String? selectedAddress;
  final void Function()? handleDeSelect;

  const ProfileChip({
    super.key,
    this.selectedProfile,
    this.selectedAddress,
    this.handleDeSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colors
            .surfaceBackgroundSubtle
            .resolveFrom(context),
        borderRadius: const BorderRadius.all(
          Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileCircle(
            size: 40,
            imageUrl: selectedProfile?.imageSmall,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedProfile != null && selectedProfile!.name.isNotEmpty
                      ? selectedProfile?.name ??
                          AppLocalizations.of(context)!.anonymous
                      : AppLocalizations.of(context)!.anonymous,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colors
                        .surfaceText
                        .resolveFrom(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
                Text(
                  selectedAddress ??
                      (selectedProfile != null
                          ? '@${selectedProfile!.username}'
                          : ''),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colors
                        .surfaceText
                        .resolveFrom(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (handleDeSelect != null)
            CupertinoButton(
              padding: const EdgeInsets.all(0),
              onPressed: handleDeSelect,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color:
                    Theme.of(context).colors.surfaceSubtle.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }
}
