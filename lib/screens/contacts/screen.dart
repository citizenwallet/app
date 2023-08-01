import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class ContactsScreen extends StatefulWidget {
  final String title = 'Contacts';

  const ContactsScreen({Key? key}) : super(key: key);

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<ContactsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    const noContacts = true;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (noContacts)
            CustomScrollView(
              controller: _scrollController,
              scrollBehavior: const CupertinoScrollBehavior(),
              slivers: [
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
              ],
            ),
          Header(
            blur: true,
            transparent: true,
            title: widget.title,
            safePadding: safePadding,
          ),
        ],
      ),
    );
  }
}
