import 'package:intl/intl.dart';

class Wallet {
  final int id;
  final int chainId;
  final String name;
  final String address;
  final int _balance;
  final String symbol;

  Wallet(
    this._balance, {
    required this.id,
    required this.chainId,
    required this.name,
    required this.address,
    required this.symbol,
  });

  get balance => _balance / 100;

  get formattedBalance =>
      NumberFormat.currency(name: name, symbol: symbol, decimalDigits: 2)
          .format(balance);

  // convert to Wallet object from JSON
  Wallet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        name = json['name'],
        address = json['address'],
        _balance = json['balance'],
        symbol = json['symbol'];

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'name': name,
        'address': address,
        'balance': _balance,
        'symbol': symbol,
      };
}
