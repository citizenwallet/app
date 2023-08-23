import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/profile/profile_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  final String title = 'Contacts';

  const ContactsScreen({Key? key}) : super(key: key);

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<ContactsScreen> {
  final ScrollController _scrollController = ScrollController();

  late ProfilesLogic profilesLogic;

  @override
  void initState() {
    super.initState();

    profilesLogic = ProfilesLogic(context);

    WidgetsBinding.instance.addObserver(profilesLogic);

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    profilesLogic.dispose();

    WidgetsBinding.instance.removeObserver(profilesLogic);

    super.dispose();
  }

  void onLoad() async {
    await profilesLogic.loadProfiles();

    // _scrollController.animateTo(
    //   60,
    //   duration: const Duration(milliseconds: 250),
    //   curve: Curves.easeInOut,
    // );
  }

  void handleSelectProfile(ProfileV1 profile) {
    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (_) => ProfileModal(
        account: profile.account,
        readonly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    final profileList =
        context.select((ProfilesState state) => state.profileList);
    final loading =
        context.select((ProfilesState state) => state.profileListLoading);

    final noContacts = profileList.isEmpty;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            controller: _scrollController,
            scrollBehavior: const CupertinoScrollBehavior(),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: PersistentHeaderDelegate(
                  expandedHeight: safePadding + 60,
                  minHeight: safePadding + 60,
                  builder: (context, shrink) => BlurryChild(
                    child: Container(
                      color: ThemeColors.transparent,
                    ),
                  ),
                ),
              ),
              if (noContacts && !loading)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/contacts.svg',
                        semanticsLabel: 'contacts icon',
                        height: 200,
                        width: 200,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Your contacts will appear here',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.normal,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!noContacts)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: profileList.length,
                    (context, index) {
                      final profile = profileList[index];

                      return Padding(
                        key: Key(profile.account),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: ProfileRow(
                          profile: profile,
                          loading: false,
                          onTap: () => handleSelectProfile(profile),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          SafeArea(
            child: Header(
              transparent: true,
              color: ThemeColors.transparent,
              title: widget.title,
            ),
          ),
        ],
      ),
    );
  }
}
