import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class Header extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget? actionButton;

  const Header({
    super.key,
    required this.title,
    this.subTitle,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.uiBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(color: ThemeColors.border.resolveFrom(context)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (router.canPop())
                GestureDetector(
                  onTap: () => GoRouter.of(context).pop(),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 15, 10),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: Icon(
                          CupertinoIcons.back,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 60.0,
                width: 60.0,
                child: Center(
                  child: actionButton,
                ),
              ),
            ],
          ),
          if (subTitle != null && subTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
              child: Text(
                subTitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
