import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/wallet/models/json_rpc.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EIP1559GasPrice {
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;

  EIP1559GasPrice({
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
  });
}

class EIP1559GasPriceEstimator {
  late APIService _rpc;
  late Web3Client _client;
  late int _gasExtraPercentage;

  EIP1559GasPriceEstimator(
    APIService rpc,
    Web3Client client, {
    int gasExtraPercentage = 13,
  }) {
    _rpc = rpc;
    _client = client;
    _gasExtraPercentage = gasExtraPercentage;
  }

  /// makes a jsonrpc request from this wallet
  Future<JSONRPCResponse> _requestRPC(JSONRPCRequest body) async {
    final rawRespoonse = await _rpc.post(
      body: body,
    );

    final response = JSONRPCResponse.fromJson(rawRespoonse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  Future<EIP1559GasPrice?> get estimate async {
    try {
      final block = await _client.getBlockInformation();
      final response = await _requestRPC(
        JSONRPCRequest(
          method: 'eth_maxPriorityFeePerGas',
          params: [],
        ),
      );

      final tip = hexToInt(response.result);

      final BigInt buffer =
          BigInt.from((tip / BigInt.from(100)) * _gasExtraPercentage);

      final maxPriorityFeePerGas = tip + buffer;

      return EIP1559GasPrice(
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        maxFeePerGas: block.baseFeePerGas != null
            ? (block.baseFeePerGas!.getValueInUnitBI(EtherUnit.wei) *
                    BigInt.from(2)) +
                maxPriorityFeePerGas
            : maxPriorityFeePerGas,
      );
    } catch (e) {
      //
    }

    return null;
  }
}
