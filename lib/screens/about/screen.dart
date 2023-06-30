import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  void onTapLink(String text, String? href, String title) {
    if (href == null) {
      return;
    }
    final Uri url = Uri.parse(href);

    launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final theme = context.select((AppState state) => state.theme);

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          FutureBuilder(
            future: rootBundle.loadString('assets/about/about.md'),
            builder: (context, AsyncSnapshot<String> snapshot) => snapshot
                    .hasData
                ? Markdown(
                    selectable: true,
                    softLineBreak: true,
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(10, 40 + safePadding, 10, 10),
                    onTapLink: onTapLink,
                    styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme),
                    data: snapshot.data ?? '',
                  )
                : Center(
                    child: CupertinoActivityIndicator(
                      color: ThemeColors.subtle.resolveFrom(context),
                    ),
                  ),
          ),
          Header(
            blur: true,
            transparent: true,
            showBackButton: true,
            title: 'About',
            safePadding: safePadding,
          ),
        ],
      ),
    );
  }
}
