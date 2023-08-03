import 'package:flutter/cupertino.dart';

enum VoucherCreationState {
  none(''),
  creating('Creating...'),
  funding('Funding...'),
  created('Created'),
  error('Error creating voucher');

  const VoucherCreationState(this.description);

  // description
  final String description;
}

class Voucher {
  final String address;
  final String name;
  final String balance;
  final DateTime createdAt;

  Voucher({
    required this.address,
    required this.name,
    required this.balance,
    required this.createdAt,
  });
}

class VoucherState with ChangeNotifier {
  Voucher? createdVoucher;
  VoucherCreationState creationState = VoucherCreationState.none;

  bool createLoading = false;
  bool createError = false;

  void createVoucherRequest() {
    creationState = VoucherCreationState.creating;

    createLoading = true;
    createError = false;
    notifyListeners();
  }

  void createVoucherFunding() {
    creationState = VoucherCreationState.funding;

    notifyListeners();
  }

  void createVoucherSuccess(Voucher voucher) {
    creationState = VoucherCreationState.created;

    createdVoucher = voucher;
    createLoading = false;
    createError = false;
    notifyListeners();
  }

  void createVoucherError() {
    creationState = VoucherCreationState.error;

    createLoading = false;
    createError = true;
    notifyListeners();
  }

  void resetCreate() {
    creationState = VoucherCreationState.none;

    createLoading = false;
    createError = false;
    notifyListeners();
  }
}
