import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class SlideToComplete extends StatefulWidget {
  final Widget child;
  final String completionLabel;
  final double width;
  final double childWidth;
  final bool isComplete;
  final void Function()? onCompleted;

  final Color thumbColor;

  const SlideToComplete({
    Key? key,
    required this.child,
    this.completionLabel = 'Slide to complete',
    this.width = 200,
    this.childWidth = 50,
    this.isComplete = false,
    this.onCompleted,
    this.thumbColor = CupertinoColors.systemGrey,
  }) : super(key: key);

  @override
  SlideToCompleteState createState() => SlideToCompleteState();
}

class SlideToCompleteState extends State<SlideToComplete> {
  int _duration = 0;
  double _offset = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.isComplete) return;

        if (_offset + widget.childWidth >= widget.width) {
          setState(() {
            _duration = 0;
            _offset = widget.width - widget.childWidth;
          });
          widget.onCompleted?.call();
          return;
        }

        setState(() {
          _duration = 0;
          _offset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (widget.isComplete) return;
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
                  color: ThemeColors.primary.resolveFrom(context),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: widget.isComplete
                        ? ThemeColors.primary.resolveFrom(context)
                        : ThemeColors.background.resolveFrom(context),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.completionLabel,
                    style: TextStyle(
                      color: ThemeColors.text.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                )),
            AnimatedPositioned(
              duration: Duration(milliseconds: _duration),
              curve: Curves.easeInOut,
              left: _offset,
              child: Container(
                width: widget.width,
                height: 50,
                decoration: BoxDecoration(
                  color: ThemeColors.surfaceSubtle.resolveFrom(context),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: _duration),
              curve: Curves.easeInOut,
              left: _offset,
              child: Container(
                height: 50,
                width: widget.childWidth,
                decoration: BoxDecoration(
                  color: widget.thumbColor,
                  borderRadius: BorderRadius.circular(5),
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
