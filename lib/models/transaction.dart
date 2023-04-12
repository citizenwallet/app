import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final int chainId;
  final String from;
  final String to;
  final String title;
  final double _amount;
  final DateTime date;

  Transaction(
    this._amount, {
    required this.id,
    required this.chainId,
    required this.from,
    required this.to,
    required this.title,
    required this.date,
  });

  get amount => _amount / 100;

  String formattedAmount(Wallet wallet) =>
      formatCurrency(amount, wallet.symbol);

  // convert to Transaction object from JSON
  Transaction.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        from = json['from'],
        to = json['to'],
        title = json['title'],
        _amount = json['amount'],
        date = DateTime.parse(json['date']);

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'from': from,
        'to': to,
        'title': title,
        'amount': _amount,
        'date': date.toIso8601String(),
      };
}
