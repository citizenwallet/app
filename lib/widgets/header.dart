import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class Header extends StatefulWidget {
  final String title;
  final String? subTitle;
  final Widget? subTitleWidget;
  final Widget? actionButton;
  final bool manualBack;
  final bool transparent;

  const Header({
    super.key,
    required this.title,
    this.subTitleWidget,
    this.subTitle,
    this.actionButton,
    this.manualBack = false,
    this.transparent = false,
  });

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  bool _canPop = false;
  late GoRouter router;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      router = GoRouter.of(context);

      _canPop = router.canPop();

      router.addListener(updatePop);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    router = GoRouter.of(context);
  }

  @override
  void dispose() {
    router.removeListener(updatePop);
    super.dispose();
  }

  void updatePop() {
    setState(() {
      _canPop = router.canPop();
    });
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.transparent
            ? ThemeColors.transparent.resolveFrom(context)
            : ThemeColors.uiBackground.resolveFrom(context),
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
              if (_canPop && !widget.manualBack)
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: const Icon(
                    CupertinoIcons.back,
                  ),
                ),
              Expanded(
                child: Text(
                  widget.title,
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
                  child: widget.actionButton,
                ),
              ),
            ],
          ),
          if (widget.subTitleWidget != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                child: widget.subTitleWidget,
              ),
            ),
          if (widget.subTitle != null && widget.subTitle!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                child: Text(
                  widget.subTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
