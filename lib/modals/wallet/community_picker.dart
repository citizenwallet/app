import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/state/communities/logic.dart';
import 'package:citizenwallet/state/communities/selectors.dart';
import 'package:citizenwallet/state/communities/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/communities/community_row.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityPickerModal extends StatefulWidget {
  const CommunityPickerModal({Key? key}) : super(key: key);

  @override
  State<CommunityPickerModal> createState() => _CommunityPickerModalState();
}

class _CommunityPickerModalState extends State<CommunityPickerModal> {
  late CommunitiesLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = CommunitiesLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // fetch things here

      onLoad();
    });
  }

  void onLoad() async {
    _logic.silentFetchCommunities();
  }

  Future<void> handleRefresh() async {
    HapticFeedback.heavyImpact();

    await _logic.silentFetchCommunities();

    HapticFeedback.lightImpact();
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCommunitySelect(Config config) {
    GoRouter.of(context).pop(config.community.alias);
  }

  void handleCommunityInfo(String url) {
    final Uri uri = Uri.parse(url);

    launchUrl(uri, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final communities = context.select(selectVisibleCommunities);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.black,
        child: SafeArea(
          minimum: const EdgeInsets.only(top: 20),
          bottom: false,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: '',
                transparent: true,
                actionButton: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: ThemeColors.touchable.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: ScrollController(),
                  scrollBehavior: const CupertinoScrollBehavior(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      floating: false,
                      delegate: PersistentHeaderDelegate(
                        minHeight: height * 0.2,
                        expandedHeight: height * 0.45,
                        builder: (context, shrink) {
                          return Container(
                            color: ThemeColors.black,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/community_background.jpg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Communities',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color: ThemeColors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    CupertinoSliverRefreshControl(
                      onRefresh: handleRefresh,
                      builder: (
                        context,
                        mode,
                        pulledExtent,
                        refreshTriggerPullDistance,
                        refreshIndicatorExtent,
                      ) =>
                          SafeArea(
                        child: Container(
                          color: ThemeColors.black,
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: CupertinoSliverRefreshControl
                              .buildRefreshIndicator(
                            context,
                            mode,
                            pulledExtent,
                            refreshTriggerPullDistance,
                            refreshIndicatorExtent,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 24,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: communities.length,
                        (context, index) => CommunityRow(
                          config: communities[index],
                          onTap: handleCommunitySelect,
                          onInfoTap: handleCommunityInfo,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 60,
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
