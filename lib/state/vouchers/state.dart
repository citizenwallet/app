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
  final String alias;
  final String name;
  String balance;
  final String creator;
  final DateTime createdAt;
  bool archived;

  Voucher({
    required this.address,
    required this.alias,
    this.name = '',
    required this.balance,
    required this.creator,
    required this.createdAt,
    required this.archived,
  });

  String get formattedBalance =>
      (double.tryParse(balance) ?? 0.0).toStringAsFixed(2);
  String get formattedAddress => formatLongText(address);

  String getLink(String appLink, String symbol, String voucher) {
    final encoded = compress(voucher);

    String params = 'alias=$alias&creator=$creator';

    if (name.isNotEmpty) {
      params += '&name=$name';
    }

    final encodedParams = compress(params);

    String link =
        '$appLink/#/?voucher=$encoded&params=$encodedParams&alias=$alias';

    return link;
  }

  String get id => '$address-$balance';

  // address + balance is used to determine if a voucher is the same
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Voucher &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          balance == other.balance;

  // hashcode is used to determine if a voucher is the same
  @override
  int get hashCode => address.hashCode ^ balance.hashCode;
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
    this.vouchers = [...vouchers];
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

    final index = vouchers.indexWhere((v) => v.address == voucher.address);
    if (index < 0) {
      vouchers.insert(0, voucher);
    } else {
      vouchers[index] = voucher;
    }

    createdVoucher = voucher;
    shareLink = link;
    createLoading = false;
    createError = false;
    notifyListeners();
  }

  void createVoucherMultiSuccess(List<Voucher> vouchers) {
    creationState = VoucherCreationState.created;

    for (final voucher in vouchers) {
      final index =
          this.vouchers.indexWhere((v) => v.address == voucher.address);
      if (index < 0) {
        this.vouchers.add(voucher);
      } else {
        this.vouchers[index] = voucher;
      }
    }

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

  // reading

  Voucher? readVoucher;

  bool readLoading = false;
  bool readError = false;

  void readVoucherRequest() {
    readLoading = true;
    readError = false;
    notifyListeners();
  }

  void readVoucherSuccess(Voucher voucher) {
    readVoucher = voucher;

    final index = vouchers.indexWhere((v) => v.address == voucher.address);
    if (index < 0) {
      vouchers.add(voucher);
    } else {
      vouchers[index] = voucher;
    }

    readLoading = false;
    readError = false;
    notifyListeners();
  }

  void readVoucherError() {
    readLoading = false;
    readError = true;
    notifyListeners();
  }

  // viewing

  Voucher? viewingVoucher;
  String? viewingVoucherLink;

  bool viewLoading = false;
  bool viewError = false;

  void openVoucherRequest() {
    viewLoading = true;
    viewError = false;
    notifyListeners();
  }

  void openVoucherSuccess(Voucher voucher, String link) {
    viewingVoucher = voucher;
    viewingVoucherLink = link;

    viewLoading = false;
    viewError = false;
    notifyListeners();
  }

  void openVoucherError() {
    viewLoading = false;
    viewError = true;
    notifyListeners();
  }

  void openVoucherClear({notify = true}) {
    viewingVoucher = null;
    viewingVoucherLink = null;

    viewLoading = false;
    viewError = false;
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
