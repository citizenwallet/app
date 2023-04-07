class Wallet {
  final int id;
  final int chainId;
  final String name;
  final String address;
  final int balance;
  final String symbol;

  Wallet({
    required this.id,
    required this.chainId,
    required this.name,
    required this.address,
    required this.balance,
    required this.symbol,
  });

  // convert to Wallet object from JSON
  Wallet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        name = json['name'],
        address = json['address'],
        balance = json['balance'],
        symbol = json['symbol'];

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'name': name,
        'address': address,
        'balance': balance,
        'symbol': symbol,
      };
}
