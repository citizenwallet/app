import 'package:citizenwallet/utils/currency.dart';

class CWWallet {
  final String name;
  final String address;
  double _balance;
  final String symbol;
  final int decimalDigits;

  CWWallet(
    this._balance, {
    required this.name,
    required this.address,
    required this.symbol,
    this.decimalDigits = 2,
  });

  double get balance => _balance;

  get formattedBalance => formatCurrency(
        balance,
        symbol,
        decimalDigits: decimalDigits,
      );

  // convert to Wallet object from JSON
  CWWallet.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        address = json['address'],
        _balance = json['balance'],
        symbol = json['symbol'],
        decimalDigits = json['decimalDigits'];

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'balance': _balance,
        'symbol': symbol,
        'decimalDigits': decimalDigits,
      };

  void setBalance(double balance) {
    _balance = balance;
  }
}
