class Transaction {
  final String id;
  final int chainId;
  final String from;
  final String to;
  final String title;
  final double amount;
  final DateTime date;

  Transaction({
    required this.id,
    required this.chainId,
    required this.from,
    required this.to,
    required this.title,
    required this.amount,
    required this.date,
  });

  // convert to Transaction object from JSON
  Transaction.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        from = json['from'],
        to = json['to'],
        title = json['title'],
        amount = json['amount'],
        date = DateTime.parse(json['date']);

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'from': from,
        'to': to,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
      };
}
