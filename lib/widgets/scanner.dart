import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scanner extends StatefulWidget {
  final String modalKey;

  const Scanner({
    Key? key,
    this.modalKey = 'scanner',
  }) : super(key: key);

  @override
  ScannerState createState() => ScannerState();
}

class ScannerState extends State<Scanner> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late MobileScannerController _controller;

  double _opacity = 0;
  bool _complete = false;
  bool _hasTorch = false;
  TorchState _torchState = TorchState.off;

  @override
  void initState() {
    _complete = false;
    _hasTorch = false;
    _torchState = TorchState.off;

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
      formats: <BarcodeFormat>[BarcodeFormat.qrCode],
    );

    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 125));

    await _controller.start();

    _controller.torchState.addListener(() {
      setState(() {
        _torchState = _controller.torchState.value;
      });
    });

    await delay(const Duration(milliseconds: 125));

    setState(() {
      _opacity = 1;
      _hasTorch = _controller.hasTorch;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    _complete = true;
    GoRouter.of(context).pop();
  }

  void handleToggleTorch() {
    if (_complete) return;
    _controller.toggleTorch();
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

    final navigator = GoRouter.of(context);

    _animationController.forward();

    await delay(const Duration(milliseconds: 1000));

    navigator.pop('${capture.barcodes[0].rawValue}');

    _animationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return DismissibleModalPopup(
      modalKey: widget.modalKey,
      maxHeight: height,
      paddingSides: 0,
      paddingTopBottom: 0,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      onDismissed: (_) => handleDismiss(context),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
        resizeToAvoidBottomInset: false,
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      height: height,
                      width: width,
                      decoration: BoxDecoration(
                        color: ThemeColors.uiBackground.resolveFrom(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _opacity,
                          duration: const Duration(milliseconds: 1000),
                          child: MobileScanner(
                            controller: _controller,
                            onDetect: handleDetection,
                            fit: BoxFit.cover,
                            placeholderBuilder: (p0, p1) {
                              return Container(
                                height: height,
                                width: width,
                                decoration: BoxDecoration(
                                  color: ThemeColors.uiBackground
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: ThemeColors.uiBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                              child: Center(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.all(5),
                                  onPressed: () => handleDismiss(context),
                                  child: Icon(
                                    CupertinoIcons.xmark,
                                    color: ThemeColors.touchable
                                        .resolveFrom(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                    color: ThemeColors.uiBackground
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  margin:
                                      const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                  child: Center(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.all(5),
                                      onPressed: handleToggleTorch,
                                      child: Icon(
                                        _torchState == TorchState.off
                                            ? CupertinoIcons.lightbulb
                                            : CupertinoIcons.lightbulb_fill,
                                        color: ThemeColors.touchable
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
                        color: ThemeColors.uiBackground.resolveFrom(context),
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
            ),
          ],
        ),
      ),
    );
  }
}
