import 'package:flutter/cupertino.dart';

class AndroidPinCodeState with ChangeNotifier {
  final TextEditingController pinCodeController = TextEditingController();
  final TextEditingController confirmPinCodeController =
      TextEditingController();

  String get pinCode => pinCodeController.text;
  String get confirmPinCode => confirmPinCodeController.text;

  bool get hasPinCode => pinCode.isNotEmpty;
  bool get hasConfirmPinCode => confirmPinCode.isNotEmpty;

  bool get isPinCodeValid => pinCode.length == 6;
  bool get isConfirmPinCodeValid => confirmPinCode.length == 6;

  bool get isPinCodeMatch => pinCode == confirmPinCode;

  bool obscureText = false;

  bool invalidRecoveryPin = false;

  void onPinCodeChanged() {
    invalidRecoveryPin = false;
    notifyListeners();
  }

  void onConfirmPinCodeChanged() {
    invalidRecoveryPin = false;
    notifyListeners();
  }

  void toggleObscureText() {
    obscureText = !obscureText;
    notifyListeners();
  }

  void setInvalidRecoveryPin(bool value) {
    invalidRecoveryPin = value;
    notifyListeners();
  }

  @override
  void dispose() {
    pinCodeController.dispose();
    confirmPinCodeController.dispose();
    super.dispose();
  }
}
