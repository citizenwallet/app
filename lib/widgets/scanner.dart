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
  final bool confirm;

  const Scanner({
    Key? key,
    this.modalKey = 'scanner',
    this.confirm = false,
  }) : super(key: key);

  @override
  ScannerState createState() => ScannerState();
}

class ScannerState extends State<Scanner> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _animationController;
  late MobileScannerController _controller;

  double _opacity = 0;
  bool _complete = false;
  bool _hasTorch = false;
  bool _isTextEmpty = true;
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
      autoStart: true,
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
    await delay(const Duration(milliseconds: 250));

    _controller.torchState.addListener(() {
      setState(() {
        _torchState = _controller.torchState.value;
      });
    });

    await delay(const Duration(milliseconds: 250));

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

    if (widget.confirm) {
      _animationController.forward();

      await delay(const Duration(milliseconds: 1000));

      _animationController.animateBack(0);

      _textController.text = '${capture.barcodes[0].rawValue}';

      setState(() {
        _isTextEmpty = _textController.value.text.isEmpty;
        _complete = false;
      });

      return;
    }

    _animationController.forward();

    await delay(const Duration(milliseconds: 1000));

    _animationController.stop();

    navigator.pop('${capture.barcodes[0].rawValue}');
  }

  void handleChanged() {
    setState(() {
      _isTextEmpty = _textController.value.text.isEmpty;
    });
  }

  void handleSubmit(BuildContext context) async {
    final navigator = GoRouter.of(context);

    _animationController.forward();

    await delay(const Duration(milliseconds: 1000));

    _animationController.stop();

    if (_textController.value.text.isNotEmpty) {
      navigator.pop(_textController.value.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DismissibleModalPopup(
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
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                                      color: ThemeColors.subtle
                                          .resolveFrom(context),
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
                                margin:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                                    margin: const EdgeInsets.fromLTRB(
                                        20, 20, 20, 20),
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
                    if (widget.confirm)
                      Positioned(
                        bottom: bottomInset <= 120 ? 120 : bottomInset,
                        child: Container(
                          height: 50,
                          width: width - 40,
                          decoration: BoxDecoration(
                            color:
                                ThemeColors.uiBackground.resolveFrom(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Center(
                            child: CupertinoTextField(
                              controller: _textController,
                              placeholder: 'Manual Entry',
                              maxLines: 1,
                              autofocus: false,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              decoration: BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color: ThemeColors.transparent
                                      .resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                              onChanged: (_) {
                                handleChanged();
                              },
                              onSubmitted: (_) {
                                handleSubmit(context);
                              },
                              suffix: Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                  color: _isTextEmpty
                                      ? ThemeColors.subtle.resolveFrom(context)
                                      : ThemeColors.primary
                                          .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                // margin:
                                //     const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                child: Center(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.all(5),
                                    onPressed: _isTextEmpty
                                        ? null
                                        : () => handleSubmit(context),
                                    child: Icon(
                                      CupertinoIcons.arrow_right,
                                      color: _isTextEmpty
                                          ? ThemeColors.subtleText
                                              .resolveFrom(context)
                                          : ThemeColors.white
                                              .resolveFrom(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
      ),
    );
  }
}
