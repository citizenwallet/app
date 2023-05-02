import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/utils/currency.dart';

enum TransactionState {
  pending,
  success,
  failed,
}

class CWTransaction {
  final String id;
  final int chainId;
  final String from;
  final String to;
  final String title;
  final double _amount;
  final DateTime date;
  final int blockNumber;

  TransactionState state = TransactionState.success;

  CWTransaction(
    this._amount, {
    required this.id,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.title,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.success,
  });
  CWTransaction.pending(
    this._amount, {
    required this.id,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.title,
    required this.date,
    this.blockNumber = 0,
    this.state = TransactionState.pending,
  });

  double get amount => _amount;

  bool get isPending => state == TransactionState.pending;

  bool isIncoming(String to) => this.to == to;

  String formattedAmount(CWWallet wallet, {bool isIncoming = false}) =>
      formatCurrency(
        amount,
        wallet.symbol,
        decimalDigits: wallet.decimalDigits,
        isIncoming: isIncoming,
      );

  // convert to Transaction object from JSON
  CWTransaction.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        from = json['from'],
        to = json['to'],
        title = json['title'],
        _amount = json['amount'],
        date = DateTime.parse(json['date']),
        blockNumber = json['blockNumber'],
        state = json['state'] ?? TransactionState.success;

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'from': from,
        'to': to,
        'title': title,
        'amount': _amount,
        'blockNumber': blockNumber,
        'date': date.toIso8601String(),
      };

  void pending() {
    state = TransactionState.pending;
  }

  void success() {
    state = TransactionState.success;
  }
}
