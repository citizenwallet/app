import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class SlideToComplete extends StatefulWidget {
  final Widget child;
  final String completionLabel;
  final double width;
  final double childWidth;
  final bool isComplete;
  final bool enabled;
  final void Function()? onCompleted;
  final void Function(double percentage)? onSlide;

  final Color thumbColor;

  const SlideToComplete({
    Key? key,
    required this.child,
    this.completionLabel = 'Slide to complete',
    this.width = 200,
    this.childWidth = 50,
    this.isComplete = false,
    this.enabled = true,
    this.onCompleted,
    this.onSlide,
    this.thumbColor = CupertinoColors.systemGrey,
  }) : super(key: key);

  @override
  SlideToCompleteState createState() => SlideToCompleteState();
}

class SlideToCompleteState extends State<SlideToComplete>
    with SingleTickerProviderStateMixin {
  final double radius = 10;

  int _duration = 0;
  double _offset = 0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      value: 0,
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SlideToComplete oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isComplete && !widget.isComplete) {
      setState(() {
        _duration = 250;
        _offset = 0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double offsetComplete = widget.width - widget.childWidth;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.isComplete) return;

        widget.onSlide
            ?.call(((_offset + widget.childWidth) / widget.width).clamp(0, 1));

        if (_offset + widget.childWidth >= widget.width) {
          setState(() {
            _duration = 0;
            _offset = widget.width - widget.childWidth;
          });
          widget.onCompleted?.call();
          return;
        }

        final newOffset = _offset + details.delta.dx;

        setState(() {
          _duration = 0;
          _offset = newOffset.clamp(0, widget.width);
        });
      },
      onHorizontalDragEnd: (details) {
        if (widget.isComplete) return;

        widget.onSlide?.call(0);

        setState(() {
          _duration = 250;
          _offset = 0;
        });
      },
      child: SizedBox(
        height: 50,
        width: widget.width,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              height: 50,
              decoration: BoxDecoration(
                color: ThemeColors.surfacePrimary.resolveFrom(context),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: widget.isComplete
                      ? ThemeColors.surfacePrimary.resolveFrom(context)
                      : ThemeColors.background.resolveFrom(context),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.enabled) const SizedBox(width: 30),
                  Text(
                    widget.completionLabel,
                    style: TextStyle(
                      color: ThemeColors.surfaceText.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                  if (widget.enabled) ...[
                    const SizedBox(width: 5),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Opacity(
                        opacity: _controller.view.value,
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: ThemeColors.surfaceText.resolveFrom(context),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Opacity(
                        opacity: _controller.view.value,
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: ThemeColors.surfaceText.resolveFrom(context),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Opacity(
                        opacity: _controller.view.value,
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: ThemeColors.surfaceText.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: _duration),
              curve: Curves.easeInOut,
              left: widget.isComplete ? offsetComplete : _offset,
              child: Container(
                width: widget.width,
                height: 50,
                decoration: BoxDecoration(
                  color: ThemeColors.surfaceSubtle.resolveFrom(context),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: _duration),
              curve: Curves.easeInOut,
              left: widget.isComplete ? offsetComplete : _offset,
              child: Container(
                height: 50,
                width: widget.childWidth,
                decoration: BoxDecoration(
                  color: widget.thumbColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
