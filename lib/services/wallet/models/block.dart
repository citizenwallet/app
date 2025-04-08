import 'package:citizenwallet/services/wallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:web3dart/web3dart.dart';

const firstBlockNumber = 0;

class WalletBlock {
  final BigInt number;
  final String hash;
  final String parentHash;
  final String miner;
  final BigInt difficulty;
  final BigInt totalDifficulty;
  final String extraData;
  final BigInt size;
  final EtherAmount gasLimit;
  final EtherAmount gasUsed;
  final DateTime timestamp;
  final List<WalletTransaction> transactions;

  WalletBlock({
    required this.number,
    required this.hash,
    required this.parentHash,
    required this.miner,
    required this.difficulty,
    required this.totalDifficulty,
    required this.extraData,
    required this.size,
    required this.gasLimit,
    required this.gasUsed,
    required this.timestamp,
    required this.transactions,
  });

  factory WalletBlock.fromJson(Map<String, dynamic> json) {
    return WalletBlock(
      number: parseIntFromHex(json['number']),
      hash: '${json['hash']}',
      parentHash: '${json['parentHash']}',
      miner: '${json['miner']}',
      difficulty: parseIntFromHex(json['difficulty']),
      totalDifficulty: parseIntFromHex(json['totalDifficulty']),
      extraData: '${json['extraData']}',
      size: parseIntFromHex(json['size']),
      gasLimit: EtherAmount.fromBigInt(
          EtherUnit.wei, parseIntFromHex(json['gasLimit'])),
      gasUsed: EtherAmount.fromBigInt(
          EtherUnit.wei, parseIntFromHex(json['gasUsed'])),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        parseIntFromHex(json['timestamp']).toInt() * 1000,
        isUtc: true,
      ),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((i) => WalletTransaction.fromJson(i))
              .toList()
          : [],
    );
  }
}
