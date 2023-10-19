import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:simple_animations/simple_animations.dart';

class CoinSpinner extends StatefulWidget {
  final double size;
  final String logo;
  final bool spin;
  final double? value;

  const CoinSpinner({
    super.key,
    this.size = 40,
    required this.logo,
    this.spin = false,
    this.value,
  });

  @override
  State<CoinSpinner> createState() => _CoinSpinnerState();
}

class _CoinSpinnerState extends State<CoinSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  void onLoad() {
    if (widget.spin) {
      spin();
    }
  }

  @override
  void didUpdateWidget(CoinSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spin != oldWidget.spin) {
      if (widget.spin) {
        spin();
      } else {
        stop();
      }
    }
  }

  @override
  void dispose() {
    stop();
    _controller.dispose();
    super.dispose();
  }

  void spin() async {
    if (_controller.isAnimating) {
      _controller.stop();
    }

    _controller.loop();
  }

  void stop() {
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.animateTo(
        _controller.value > 0.5 ? 1 : 0,
        // 0,
        duration: const Duration(milliseconds: 150),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()
                    ..setEntry(1, 2, 0.15)
                    ..rotateY(
                      math.pi *
                          2 *
                          (widget.spin
                              ? _controller.value
                              : widget.value ?? _controller.value),
                    ),
                  child: CoinLogo(
                    size: widget.size,
                    logo: widget.logo,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
