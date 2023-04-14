class Explorer {
  final String name;
  final String url;
  final String standard;

  Explorer({
    required this.name,
    required this.url,
    required this.standard,
  });

  factory Explorer.fromJson(Map<String, dynamic> json) {
    return Explorer(
      name: json['name'],
      url: json['url'],
      standard: json['standard'],
    );
  }
}

class NativeCurrency {
  final String name;
  final String symbol;
  final int decimals;

  NativeCurrency({
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  factory NativeCurrency.fromJson(Map<String, dynamic> json) {
    return NativeCurrency(
      name: json['name'],
      symbol: json['symbol'],
      decimals: json['decimals'],
    );
  }
}

class Chain {
  final String name;
  final String chain;
  final List<String> rpc;
  final List<String> faucets;
  final NativeCurrency nativeCurrency;
  final String infoURL;
  final String shortName;
  final int chainId;
  final int networkId;
  final List<Explorer>? explorers;

  Chain({
    required this.name,
    required this.chain,
    required this.rpc,
    required this.faucets,
    required this.nativeCurrency,
    required this.infoURL,
    required this.shortName,
    required this.chainId,
    required this.networkId,
    required this.explorers,
  });

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      name: json['name'],
      chain: json['chain'],
      rpc: List<String>.from(json['rpc']),
      faucets: List<String>.from(json['faucets']),
      nativeCurrency: NativeCurrency.fromJson(json['nativeCurrency']),
      infoURL: json['infoURL'],
      shortName: json['shortName'],
      chainId: json['chainId'],
      networkId: json['networkId'],
      explorers: json['explorers'] != null
          ? List<Explorer>.from(
              json['explorers'].map((x) => Explorer.fromJson(x)),
            )
          : null,
    );
  }

  @override
  // to string
  String toString() {
    return 'Chain: $name, $chain, $rpc, $faucets, ${nativeCurrency.name}, ${nativeCurrency.symbol}, $infoURL, $shortName, $chainId, $networkId, $explorers';
  }
}
