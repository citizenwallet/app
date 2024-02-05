import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class InfoActionLayout extends StatelessWidget {
  final String? headerTitle;
  final bool showBackButton;
  final String? title;
  final String? icon;
  final String? description;
  final Widget? descriptionWidget;
  final bool loading;

  final String? primaryActionErrorText;
  final String? primaryActionText;
  final String? secondaryActionErrorText;
  final String? secondaryActionText;

  final void Function()? onPrimaryAction;
  final void Function()? onSecondaryAction;

  const InfoActionLayout({
    super.key,
    this.headerTitle,
    this.showBackButton = true,
    this.title,
    this.icon,
    this.description,
    this.descriptionWidget,
    this.loading = false,
    this.primaryActionErrorText,
    this.primaryActionText,
    this.secondaryActionErrorText,
    this.secondaryActionText,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;

    return Flex(
      direction: Axis.vertical,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomScrollView(
                scrollBehavior: const CupertinoScrollBehavior(),
                slivers: [
                  SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Header(
                            transparent: true,
                            color: ThemeColors.transparent,
                            title: headerTitle,
                            showBackButton: showBackButton,
                          ),
                          const SizedBox(height: 20),
                          if (title != null) ...[
                            Text(
                              title!,
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                          ],
                          if (icon != null) ...[
                            SizedBox(
                              height: 240,
                              width: 240,
                              child: Center(
                                  child: SvgPicture.asset(
                                icon!,
                                semanticsLabel: 'Citizen Wallet Icon',
                                height: 300,
                              )),
                            ),
                            const SizedBox(height: 30),
                          ],
                          if (description != null) ...[
                            Text(
                              description!,
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                          ],
                          if (descriptionWidget != null) ...[
                            descriptionWidget!,
                            const SizedBox(height: 60),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
                    border: Border(
                      top: BorderSide(
                        color: ThemeColors.subtle.resolveFrom(context),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: safeBottomPadding + 20,
                  ),
                  child: loading
                      ? CupertinoActivityIndicator(
                          color: ThemeColors.subtle.resolveFrom(context),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (primaryActionErrorText != null) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: Text(
                                  primaryActionErrorText!,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.danger.resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (onPrimaryAction != null) ...[
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  maxHeight: 88,
                                  minWidth: 200,
                                  maxWidth: 320,
                                ),
                                child: Button(
                                  text: primaryActionText ?? 'Primary Action',
                                  onPressed: onPrimaryAction,
                                  minWidth: 200,
                                  maxWidth: 320,
                                ),
                              ),
                            ],
                            if (onPrimaryAction != null &&
                                onSecondaryAction != null) ...[
                              const SizedBox(height: 30),
                              Container(
                                height: 1,
                                width: 200,
                                color: ThemeColors.subtle.resolveFrom(context),
                              ),
                              const SizedBox(height: 5),
                            ],
                            if (secondaryActionErrorText != null) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: Text(
                                  secondaryActionErrorText!,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.danger.resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (onSecondaryAction != null) ...[
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  maxHeight: 88,
                                  minWidth: 200,
                                  maxWidth: 320,
                                ),
                                child: CupertinoButton(
                                  onPressed: onSecondaryAction,
                                  child: Text(
                                    secondaryActionText ?? 'Secondary Action',
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
