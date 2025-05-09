class SendDestination {
  final String to;
  final String? amount;
  final String? description;

  const SendDestination({
    required this.to,
    this.amount,
    this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SendDestination &&
        other.to == to &&
        other.amount == amount &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(to, amount, description);
}
