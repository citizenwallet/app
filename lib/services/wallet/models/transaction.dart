import 'package:citizenwallet/services/wallet/models/message.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:web3dart/web3dart.dart';

enum TransactionDirection {
  incoming,
  outgoing,
}

class WalletTransaction {
  final String hash;
  final String nonce;
  final String blockHash;
  final BlockNum blockNumber;
  final BigInt transactionIndex;
  final EthereumAddress from;
  final EthereumAddress to;
  final EtherAmount value;
  final EtherAmount gasPrice;
  final EtherAmount gas;
  final Message? input;

  DateTime timestamp = DateTime.now();
  TransactionDirection direction;

  WalletTransaction({
    required this.hash,
    required this.nonce,
    required this.blockHash,
    required this.blockNumber,
    required this.transactionIndex,
    required this.from,
    required this.to,
    required this.value,
    required this.gasPrice,
    required this.gas,
    this.input,
    DateTime? timestamp,
    this.direction = TransactionDirection.outgoing,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final transaction = WalletTransaction(
      hash: '${json['hash']}',
      nonce: '${json['nonce']}',
      blockHash: '${json['blockHash']}',
      blockNumber: BlockNum.exact(parseIntFromHex(json['blockNumber']).toInt()),
      transactionIndex: parseIntFromHex(json['transactionIndex']),
      from: EthereumAddress.fromHex(json['from']),
      to: EthereumAddress.fromHex(json['to']),
      value:
          EtherAmount.fromBigInt(EtherUnit.wei, parseIntFromHex(json['value'])),
      gasPrice: EtherAmount.fromBigInt(
          EtherUnit.wei, parseIntFromHex(json['gasPrice'])),
      gas: EtherAmount.fromBigInt(EtherUnit.wei, parseIntFromHex(json['gas'])),
      input: json['input'] != null && !isZeroHexValue('${json['input']}')
          ? Message.fromHexString('${json['input']}')
          : null,
    );

    return transaction;
  }

  void setDirection(EthereumAddress address) {
    direction = from == address
        ? TransactionDirection.outgoing
        : TransactionDirection.incoming;
  }

  void setTimestamp(DateTime timestamp) {
    this.timestamp = timestamp;
  }
}
