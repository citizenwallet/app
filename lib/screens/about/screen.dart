import 'package:citizenwallet/state/theme/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

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
    final theme = context.select((ThemeState state) => state.cupertinoTheme);

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          FutureBuilder(
            future: rootBundle.loadString('assets/about/about.md'),
            builder: (context, AsyncSnapshot<String> snapshot) => snapshot
                    .hasData
                ? Markdown(
                    key: const Key('about-markdown'),
                    selectable: true,
                    softLineBreak: true,
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(10, 80 + safePadding, 10, 10),
                    onTapLink: onTapLink,
                    styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme),
                    data: snapshot.data ?? '',
                  )
                : Center(
                    child: CupertinoActivityIndicator(
                      color:
                          Theme.of(context).colors.subtle.resolveFrom(context),
                    ),
                  ),
          ),
          Header(
            blur: true,
            transparent: true,
            showBackButton: true,
            title: AppLocalizations.of(context)!.about,
            safePadding: safePadding,
          ),
        ],
      ),
    );
  }
}
