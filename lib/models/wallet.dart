import 'package:citizenwallet/utils/currency.dart';

class CWWallet {
  final String name;
  final String address;
  final String account;
  String _balance;
  final String currencyName;
  final String symbol;
  final int decimalDigits;
  final bool locked;

  CWWallet(
    this._balance, {
    required this.name,
    required this.address,
    required this.account,
    required this.currencyName,
    required this.symbol,
    this.decimalDigits = 2,
    this.locked = true,
  });

  String get balance => _balance;
  double get doubleBalance => double.tryParse(_balance) ?? 0.0;

  String get formattedBalance => formatAmount(
        double.tryParse(_balance) ?? 0.0,
        decimalDigits: decimalDigits,
      );

  // convert to Wallet object from JSON
  CWWallet.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        address = json['address'],
        account = json['account'],
        _balance = json['balance'],
        currencyName = json['currencyName'],
        symbol = json['symbol'],
        decimalDigits = json['decimalDigits'],
        locked = json['locked'];

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'account': account,
        'balance': _balance,
        'currencyName': currencyName,
        'symbol': symbol,
        'decimalDigits': decimalDigits,
        'locked': locked,
      };

  void setBalance(String balance) {
    _balance = balance;
  }
}
