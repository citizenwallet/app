import 'dart:convert';
import 'dart:typed_data';

import 'package:citizenwallet/state/connect/state.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:walletconnect_flutter_v2/apis/auth_api/models/auth_client_events.dart';
import 'package:walletconnect_flutter_v2/apis/auth_api/models/auth_client_models.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/json_rpc_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/proposal_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';
import 'package:walletconnect_flutter_v2/apis/utils/errors.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';
import 'package:logger/logger.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ConnectService {
  final String projectId;
  final String chainId;
  final String account;
  final String address;
  late Web3Wallet _client;

  ConnectService(
    this.projectId,
    this.chainId,
    this.account,
    this.address,
  );

  Future<void> init() async {
    print('chainId $chainId');
    _client = await Web3Wallet.createInstance(
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Citizen Wallet',
        description: 'A wallet for your community',
        url: 'https://citizenwallet.xyz',
        icons: ['https://app.citizenwallet.xyz/full_logo.png'],
      ),
      logLevel: Level.verbose,
    );
  }

  Future<void> connect(
    String uri, {
    Function(AuthMetadata)? onMetadata,
  }) async {
    print('registering... $uri');
    _client.onSessionProposal.subscribe((SessionProposalEvent? proposal) {
      print('!!!!!!!PROPOSAL!!!!!!!!');
      print('Proposal received: $proposal');
      if (onMetadata != null && proposal != null) {
        final metadata = proposal.params.proposer.metadata;
        onMetadata(AuthMetadata(
          id: proposal.id,
          name: metadata.name,
          description: metadata.description,
          url: metadata.url,
          icons: metadata.icons,
        ));
      }
      print('!!!!!!!PROPOSAL!!!!!!!!');
    });
    _client.onSessionProposalError.subscribe(sessionProposalErrorHandler);

    _client.onAuthRequest.subscribe((AuthRequest? args) async {
      print('!!!!!!!AUTH REQUEST!!!!!!!!');
      print(args);
      print('!!!!!!!AUTH REQUEST!!!!!!!!');
      // This is where you would
      // 1. Store the information to be signed
      // 2. Display to the user that an auth request has been received

      // You can create the message to be signed in this manner
      // String message = clientB.formatAuthMessage(
      //   iss: TEST_ISSUER_EIP191,
      //   cacaoPayload: CacaoRequestPayload.fromPayloadParams(
      //     args!.payloadParams,
      //   ),
      // );
    });

    Uri parsed = Uri.parse(uri);
    final PairingInfo pairing = await _client.authEngine.core.pairing.pair(
      uri: parsed,
      activatePairing: true,
    );
    print(pairing.topic);
    print(pairing.relay.data);
    print(pairing.relay.protocol);

    print('initing...');
    _client.init();
  }

  Future<void> approveSession(
      AuthMetadata metadata, EthPrivateKey credentials) async {
    print('approving session... address $address account $account');

    final walletNamespaces = {
      'eip155': Namespace(
        accounts: [
          // 'eip155:$chainId:$account',
          // 'eip155:137:$account',
          'eip155:$chainId:$address',
        ],
        methods: [
          'eth_sendTransaction',
          'personal_sign',
          'eth_sign',
          'eth_signTransaction',
          'eth_signTypedData',
          'eth_signTypedData_v4',
        ],
        events: ['chainChanged', 'accountsChanged'],
      ),
    };

    _client.registerRequestHandler(
      chainId: 'eip155:$chainId',
      method: 'eth_sendTransaction',
      handler: signRequestHandler,
    );

    _client.registerRequestHandler(
      chainId: 'eip155:$chainId',
      method: 'personal_sign',
      handler: (String topic, dynamic parameters) async {
        // https://github.com/WalletConnect/WalletConnectFlutterV2/blob/bdda5e9a8834dd11f535c06789c3f2b46d601e9b/example/wallet/lib/dependencies/chains/evm_service.dart#L143C10-L143C22
        print('!!!!!!!PERSONAL SIGN REQUEST!!!!!!!!');
        print('Sign request received: $topic, $parameters');
        return await sign(credentials, metadata, topic, parameters);

        print('!!!!!!!PERSONAL SIGN REQUEST!!!!!!!!');
      },
    );

    // _client.registerEventEmitter(
    //   chainId: 'eip155:$chainId',
    //   event: 'chainChanged',
    // );
    // _client.registerAccount(
    //   chainId: 'eip155:$chainId',
    //   accountAddress: account,
    // );

    _client.onSessionConnect.subscribe((SessionConnect? args) async {
      print('!!!!!!!CONNECT!!!!!!!!');
      print(args);
      if (args == null) {
        return;
      }

      // await _client.core.pairing.activate(topic: args.session.pairingTopic);

      // final params = AuthRequestParams(
      //   chainId: 'eip155:$chainId',
      //   aud: metadata.url,
      //   domain: metadata.url.replaceFirst('https://', ''),
      // );

      // final request = await _client.authEngine.requestAuth(
      //   params: params,
      //   pairingTopic: args.session.pairingTopic,
      // );

      // final response = await request.completer.future;
      // print(response);
      print('!!!!!!!CONNECT!!!!!!!!');
    });

    _client.onSessionRequest.subscribe((SessionRequestEvent? args) async {
      print('!!!!!!!REQUEST!!!!!!!!');
      print(args);
      if (args == null) {
        return;
      }

      // await sign(credentials, metadata, args.topic, args.params, args.id);

      // await _client.emitSessionEvent(topic: args.topic, chainId: 'eip155:$chainId', event: event)
      // await _client.approveSession(
      //   id: args.id,
      //   namespaces:
      //       walletNamespaces, // This will have the accounts requested in params
      // );

      // final params = AuthRequestParams(
      //   chainId: chainId,
      //   aud: metadata.url,
      //   domain: metadata.url.replaceFirst('https://', ''),
      // );

      // final request = await _client.authEngine.requestAuth(
      //   params: params,
      //   pairingTopic: args.session.pairingTopic,
      // );

      // final response = await request.completer.future;
      // print(response);
      print('!!!!!!!REQUEST!!!!!!!!');
    });

    await _client.approveSession(
      id: metadata.id,
      namespaces:
          walletNamespaces, // This will have the accounts requested in params
    );
  }

  Future<String> sign(
    EthPrivateKey cred,
    AuthMetadata metadata,
    String topic,
    dynamic params,
  ) async {
    print('signing...');
    // final issuer = 'did:pkh:eip155:$chainId:$account';

    // final packed = LengthTrackingByteSink();

    final rawValues = (params as List<dynamic>).map((e) => '$e').toList();

    // final List<AbiType> encoders = [
    //   parseAbiType('bytes'),
    //   parseAbiType('bytes'),
    //   parseAbiType('address'),
    //   parseAbiType('bytes'),
    // ];

    // final List<dynamic> values = [
    //   Uint8List.fromList('\u0019'.codeUnits),
    //   Uint8List.fromList('\u0000'.codeUnits),
    //   EthereumAddress.fromHex(account),
    //   utf8.encode(rawValues[0])
    // ];

    // for (var i = 0; i < encoders.length; i++) {
    //   encoders[i].encode(values[i], packed);
    // }

    // final rawValues = (params as List<dynamic>).map((e) => '$e').toList();

    // final payload = AuthPayloadParams.fromRequestParams(AuthRequestParams(
    //   chainId: 'eip155:$chainId',
    //   aud: metadata.url,
    //   domain: metadata.url.replaceFirst('https://', ''),
    //   // resources: (params as List<dynamic>).map((e) => '$e').toList(),
    // ));

    // final authMessage = _client.formatAuthMessage(
    //   iss: issuer,
    //   cacaoPayload: CacaoRequestPayload.fromPayloadParams(payload),
    // );
    print('to sign: ${rawValues[0]}');

    // final message = utf8.encode(rawValues[0]);

    // final prefix = '\u0019 \u0000 $address ${rawValues[0]}';

    // final payload = keccak256(packed.asBytes());

    // final prefix = '\u0019\u0000$address';
    // final prefixBytes = ascii.encode(prefix);

    // will be a Uint8List, see the documentation of Uint8List.+
    // final concat = Uint8List.fromList(prefixBytes + hexToBytes(rawValues[0]));

    // final hash = keccak256(concat);

    final signed =
        cred.signPersonalMessageToUint8List(hexToBytes(rawValues[0]));

    // final cacao = CacaoSignature(
    //   t: CacaoSignature.EIP191,
    //   s: bytesToHex(signed, include0x: true),
    // );

    // print(cacao.toJson());
    print('address ${cred.address.hexEip55}');

    // await _client.emitSessionEvent(
    //   topic: topic,
    //   chainId: 'eip155:$chainId',
    //   event: SessionEventParams(
    //     name: 'message',
    //     data: account,
    //     // data: signed,
    //   ),
    // );

    // return jsonEncode(cacao.toJson());

    final result = bytesToHex(signed, include0x: true);

    print('result: $result');

    return result;

    // await _client.respondSessionRequest(
    //   topic: topic,
    //   response: JsonRpcResponse(
    //     id: id,
    //     jsonrpc: '2.0',
    //     result: bytesToHex(signed, include0x: true),
    //     // result: signed,
    //   ),
    // );

    // final payload = AuthPayloadParams.fromRequestParams(AuthRequestParams(
    //   chainId: 'eip155:$chainId',
    //   aud: metadata.url,
    //   domain: metadata.url.replaceFirst('https://', ''),
    //   // resources: (params as List<dynamic>).map((e) => '$e').toList(),
    // ));

    // final authMessage = _client.formatAuthMessage(
    //   iss: issuer,
    //   cacaoPayload: CacaoRequestPayload.fromPayloadParams(payload),
    // );

    // final signed = cred
    //     .signPersonalMessageToUint8List(Uint8List.fromList(message.codeUnits));

    // await _client.respondAuthRequest(
    //   id: metadata.id,
    //   iss: issuer,
    // signature: CacaoSignature(
    //   t: CacaoSignature.EIP1271,
    //   s: bytesToHex(signed, include0x: true),
    // ),
    // );
  }

  void signRequestHandler(String topic, dynamic parameters) async {
    print('!!!!!!!SIGN REQUEST!!!!!!!!');
    print('Sign request received: $topic, $parameters');
    print('!!!!!!!SIGN REQUEST!!!!!!!!');
  }

  // void personalSignRequestHandler(String topic, dynamic parameters) async {
  //   print('!!!!!!!PERSONAL SIGN REQUEST!!!!!!!!');
  //   print('Sign request received: $topic, $parameters');
  //   // await sign();
  //   print('!!!!!!!PERSONAL SIGN REQUEST!!!!!!!!');
  // }

  void sessionProposalErrorHandler(SessionProposalErrorEvent? args) {
    // Handle the error
    print('!!!!!!!ERROR!!!!!!!!');
    print(args?.error);
  }

  // void onAuthRequest(AuthRequest? args) async {
  //   print('!!!!!!!AUTH REQUEST!!!!!!!!');
  //   // This is where you would
  //   // 1. Store the information to be signed
  //   // 2. Display to the user that an auth request has been received

  //   // You can create the message to be signed in this manner
  //   // String message = clientB.formatAuthMessage(
  //   //   iss: TEST_ISSUER_EIP191,
  //   //   cacaoPayload: CacaoRequestPayload.fromPayloadParams(
  //   //     args!.payloadParams,
  //   //   ),
  //   // );
  // }
}
