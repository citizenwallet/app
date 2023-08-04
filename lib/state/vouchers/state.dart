import 'dart:convert';

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
  final String token;
  final String name;
  final String balance;
  final DateTime createdAt;

  Voucher({
    required this.address,
    required this.token,
    this.name = '',
    required this.balance,
    required this.createdAt,
  });

  String getLink(String appLink, String symbol, String voucher) {
    final doubleAmount = balance.replaceAll(',', '.');
    final parsedAmount = double.parse(doubleAmount) / 1000;

    final encoded = base64.encode(utf8.encode(voucher));

    String link =
        '$appLink/#/voucher/$encoded?token=$token&balance=$parsedAmount&symbol=$symbol';

    if (name.isNotEmpty) {
      link += '&name=$name';
    }

    return link;
  }
}

class VoucherState with ChangeNotifier {
  // general
  List<Voucher> vouchers = [];

  bool loading = false;
  bool error = false;

  void vouchersRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void vouchersSuccess(List<Voucher> vouchers) {
    this.vouchers = vouchers;
    loading = false;
    error = false;
    notifyListeners();
  }

  void vouchersError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  // creation
  Voucher? createdVoucher;
  VoucherCreationState creationState = VoucherCreationState.none;

  bool createLoading = false;
  bool createError = false;

  String shareLink = '';
  bool shareReady = false;

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

  void createVoucherSuccess(Voucher voucher, String link) {
    creationState = VoucherCreationState.created;

    createdVoucher = voucher;
    shareLink = link;
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

  void setShareReady() {
    shareReady = true;
    notifyListeners();
  }

  void resetCreate({notify = true}) {
    creationState = VoucherCreationState.none;
    createdVoucher = null;

    createLoading = false;
    createError = false;

    shareLink = '';
    shareReady = false;
    if (notify) notifyListeners();
  }
}
