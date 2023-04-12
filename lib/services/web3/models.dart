import 'package:web3dart/web3dart.dart';

const zeroHexValue = '0x0';

int parseIntFromHex(String hex) {
  return int.parse(hex);
}

class Web3Transaction {
  final String hash;
  final String nonce;
  final String blockHash;
  final BlockNum blockNumber;
  final int transactionIndex;
  final EthereumAddress from;
  final EthereumAddress to;
  final EtherAmount value;
  final EtherAmount gasPrice;
  final EtherAmount gas;

  Web3Transaction({
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
  });

  factory Web3Transaction.fromJson(Map<String, dynamic> json) {
    return Web3Transaction(
      hash: '${json['hash']}',
      nonce: '${json['nonce']}',
      blockHash: '${json['blockHash']}',
      blockNumber: BlockNum.exact(parseIntFromHex(json['blockNumber'])),
      transactionIndex: parseIntFromHex(json['transactionIndex']),
      from: EthereumAddress.fromHex(json['from']),
      to: EthereumAddress.fromHex(json['to']),
      value: EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['value'])),
      gasPrice:
          EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['gasPrice'])),
      gas: EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['gas'])),
    );
  }
}

class Web3Block {
  final int number;
  final String hash;
  final String parentHash;
  final String miner;
  final int difficulty;
  final int totalDifficulty;
  final String extraData;
  final int size;
  final EtherAmount gasLimit;
  final EtherAmount gasUsed;
  final DateTime timestamp;
  final List<Web3Transaction> transactions;

  Web3Block({
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

  factory Web3Block.fromJson(Map<String, dynamic> json) {
    print('gasLimit');
    // print(parseIntFromHex(json['size']));
    print(EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['gasLimit']))
        .getValueInUnit(EtherUnit.wei));
    return Web3Block(
      number: parseIntFromHex(json['number']),
      hash: '${json['hash']}',
      parentHash: '${json['parentHash']}',
      miner: '${json['miner']}',
      difficulty: parseIntFromHex(json['difficulty']),
      totalDifficulty: parseIntFromHex(json['totalDifficulty']),
      extraData: '${json['extraData']}',
      size: parseIntFromHex(json['size']),
      gasLimit:
          EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['gasLimit'])),
      gasUsed:
          EtherAmount.fromInt(EtherUnit.wei, parseIntFromHex(json['gasUsed'])),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        parseIntFromHex(json['timestamp']) * 1000,
        isUtc: true,
      ),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((i) => Web3Transaction.fromJson(i))
              .toList()
          : [],
    );
  }
}
