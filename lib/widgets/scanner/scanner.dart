import 'dart:async';

import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/borders/border_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scanner extends StatefulWidget {
  final double height;
  final double width;
  final void Function(String value) onScan;

  const Scanner({
    super.key,
    this.height = 200,
    this.width = 200,
    required this.onScan,
  });

  @override
  ScannerState createState() => ScannerState();
}

class ScannerState extends State<Scanner>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _animationController;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    // autoStart: false,
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  double _opacity = 0;
  bool _complete = false;
  bool _hasTorch = false;
  TorchState _torchState = TorchState.off;

  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    _complete = false;
    _hasTorch = false;
    _torchState = TorchState.off;

    _controller.stop();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    super.initState();

    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = _controller.barcodes.listen(handleDetection);

        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 500));

    _controller.barcodes.listen(handleDetection);

    unawaited(_controller.start());

    await delay(const Duration(milliseconds: 125));

    setState(() {
      _opacity = 1;
      _hasTorch = _controller.torchEnabled;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;

    super.dispose();

    _controller.dispose();
  }

  void handleToggleTorch() {
    if (_complete) return;
    _controller.toggleTorch();

    setState(() {
      _torchState = _controller.torchEnabled ? TorchState.on : TorchState.off;
    });
  }

  void handleDetection(BarcodeCapture capture) async {
    if (_complete) return;

    if (capture.barcodes.isEmpty) {
      return;
    }

    HapticFeedback.heavyImpact();

    setState(() {
      _complete = true;
    });

    _animationController.forward();

    await delay(const Duration(milliseconds: 250));

    _animationController.stop();

    widget.onScan('${capture.barcodes[0].rawValue}');
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final width = widget.width;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colors.uiBackground.resolveFrom(context),
        border: Border.all(
          width: 0,
          color: Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              height: height,
              width: width,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 500),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: MobileScanner(
                      controller: _controller,
                      // startDelay: kIsWeb ? true : false,
                      fit: BoxFit.cover,
                      placeholderBuilder: (context) {
                        return SizedBox(
                          height: height,
                          width: width,
                        );
                      },
                      //     decoration: BoxDecoration(
                      //       color: Theme.of(context)
                      //           .colors
                      //           .transparent
                      //           .resolveFrom(context),
                      //       border: Border.all(
                      //         width: 3,
                      //         color: Theme.of(context).colors.white,
                      //         strokeAlign: BorderSide.strokeAlignInside,
                      //       ),
                      //       borderRadius: BorderRadius.circular(20),
                      //     ),
                      //     child: Center(
                      //       child: CupertinoActivityIndicator(
                      //         color: Theme.of(context)
                      //             .colors
                      //             .subtle
                      //             .resolveFrom(context),
                      //       ),
                      //     ),
                      //   );
                      // },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: Theme.of(context).colors.transparent.resolveFrom(context),
              border: Border.all(
                width: 2,
                color: Theme.of(context).colors.white,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Container(
              margin: const EdgeInsets.all(20),
              child: CustomPaint(
                foregroundPainter: BorderPainter(
                  color: Theme.of(context).colors.danger.resolveFrom(context),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_hasTorch)
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colors
                                .uiBackground
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Center(
                            child: CupertinoButton(
                              padding: const EdgeInsets.all(5),
                              onPressed: handleToggleTorch,
                              child: Icon(
                                _torchState == TorchState.off
                                    ? CupertinoIcons.lightbulb
                                    : CupertinoIcons.lightbulb_fill,
                                color: Theme.of(context)
                                    .colors
                                    .touchable
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
          if (_complete)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colors.uiBackground.darkColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(20),
              child: Lottie.asset(
                'assets/lottie/qr_scan_success.json',
                height: 200,
                width: 200,
                controller: _animationController,
              ),
            ),
        ],
      ),
    );
  }
}
