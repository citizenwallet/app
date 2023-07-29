import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';

class ProfileChip extends StatelessWidget {
  final ProfileV1 selectedProfile;
  final void Function()? handleDeSelect;

  const ProfileChip({
    Key? key,
    required this.selectedProfile,
    this.handleDeSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: ThemeColors.surfaceBackgroundSubtle.resolveFrom(context),
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
            imageUrl: selectedProfile.imageSmall,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedProfile.name,
                  style: TextStyle(
                    color: ThemeColors.surfaceText.resolveFrom(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
                Text(
                  '@${selectedProfile.username}',
                  style: TextStyle(
                    color: ThemeColors.surfaceText.resolveFrom(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(0),
            onPressed: handleDeSelect,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: ThemeColors.surfaceSubtle.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
