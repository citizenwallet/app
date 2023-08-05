import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/strings.dart';
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
  String balance;
  final DateTime createdAt;
  bool archived;

  Voucher({
    required this.address,
    required this.token,
    this.name = '',
    required this.balance,
    required this.createdAt,
    required this.archived,
  });

  String get formattedBalance => '${(double.tryParse(balance) ?? 0.0) / 1000}';
  String get formattedAddress => formatLongText(address);

  String getLink(String appLink, String symbol, String voucher) {
    final doubleAmount = balance.replaceAll(',', '.');
    final parsedAmount = double.parse(doubleAmount) / 1000;

    final encoded = compress(voucher);

    String params = 'token=$token&balance=$parsedAmount&symbol=$symbol';

    if (name.isNotEmpty) {
      params += '&name=$name';
    }

    final encodedParams = compress(params);

    String link = '$appLink/#/voucher/$encoded?params=$encodedParams';

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

  void updateVoucherBalance(String address, String balance) {
    final index = vouchers.indexWhere((v) => v.address == address);

    if (index > -1) {
      vouchers[index].balance = balance;
      notifyListeners();
    }
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

  // return
  bool returnLoading = false;
  bool returnError = false;

  void returnVoucherRequest() {
    returnLoading = true;
    returnError = false;
    notifyListeners();
  }

  void returnVoucherSuccess(String address) {
    final index = vouchers.indexWhere((v) => v.address == address);

    if (index > -1) {
      vouchers[index].archived = true;
    }

    returnLoading = false;
    returnError = false;
    notifyListeners();
  }

  void returnVoucherError() {
    returnLoading = false;
    returnError = true;
    notifyListeners();
  }

  // delete
  bool deleteLoading = false;
  bool deleteError = false;

  void deleteVoucherRequest() {
    deleteLoading = true;
    deleteError = false;
    notifyListeners();
  }

  void deleteVoucherSuccess(String address) {
    final index = vouchers.indexWhere((v) => v.address == address);

    if (index > -1) {
      vouchers[index].archived = true;
    }

    deleteLoading = false;
    deleteError = false;
    notifyListeners();
  }

  void deleteVoucherError() {
    deleteLoading = false;
    deleteError = true;
    notifyListeners();
  }
}
