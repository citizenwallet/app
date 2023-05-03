import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<TransactionAuthor, List<String>> createKnownAuthorsMap() => {
      TransactionAuthor.bank: [
        dotenv.get('KNOWN_ADDRESS_BANK').toLowerCase(),
        dotenv.get('KNOWN_ADDRESS_BANK2').toLowerCase(),
      ],
      TransactionAuthor.bar: [
        dotenv.get('KNOWN_ADDRESS_BAR').toLowerCase(),
      ],
    };

TransactionAuthor getTransactionAuthor(String own, String from, String to) {
  final knownAuthors = createKnownAuthorsMap();

  // is it the bank?
  if (!knownAuthors[TransactionAuthor.bank]!.contains(own.toLowerCase()) &&
      (knownAuthors[TransactionAuthor.bank]!.contains(from) ||
          knownAuthors[TransactionAuthor.bank]!.contains(to))) {
    return TransactionAuthor.bank;
  }

  // is it the bar?
  if (!knownAuthors[TransactionAuthor.bar]!.contains(own.toLowerCase()) &&
      (knownAuthors[TransactionAuthor.bar]!.contains(from) ||
          knownAuthors[TransactionAuthor.bar]!.contains(to))) {
    return TransactionAuthor.bar;
  }

  return TransactionAuthor.unknown;
}

enum TransactionState {
  pending,
  success,
  failed,
}

enum TransactionAuthor {
  self('assets/icons/anonymous_user.svg', 'You'),
  unknown('assets/icons/anonymous_user.svg', 'Unknown'),
  known('assets/icons/anonymous_user.svg', 'Known'),
  bar('assets/icons/bar_icon.svg', 'Bar'),
  bank('assets/icons/citizenbank.svg', 'Bank');

  const TransactionAuthor(this.icon, this.name);

  final String icon;
  final String name;
}

class CWTransaction {
  final String id;
  final int chainId;
  final String from;
  final String to;
  final String title;
  final String _amount;
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

  String get amount => _amount;

  bool get isPending => state == TransactionState.pending;

  bool isIncoming(String to) => this.to == to;

  String formattedAmount(CWWallet wallet, {bool isIncoming = false}) =>
      formatCurrency(
        double.tryParse(amount) ?? 0.0,
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
