import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class ScreenDescription extends StatelessWidget {
  final double topPadding;
  final Widget? title;
  final Widget heading;
  final Widget image;
  final Widget? action;

  const ScreenDescription({
    super.key,
    this.topPadding = 15,
    this.title,
    required this.heading,
    required this.image,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          color: Theme.of(context).colors.background.resolveFrom(context),
          child: ListView(
            scrollDirection: Axis.vertical,
            padding:
                EdgeInsets.fromLTRB(15, topPadding < 0 ? 0 : topPadding, 15, 0),
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
                  child: title,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
                child: heading,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
                child: image,
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                  child: action,
                ),
            ],
          )),
    );
  }
}
