class SendTransaction {
  String? _to;
  String? _amount;
  String? _description;
  String? _tipTo;
  String? _tipAmount;
  String? _tipDescription;

  SendTransaction({
    String? to,
    String? amount,
    String? description,
    String? tipTo,
    String? tipAmount,
    String? tipDescription,
  })  : _to = to,
        _amount = amount,
        _description = description,
        _tipTo = tipTo,
        _tipAmount = tipAmount,
        _tipDescription = tipDescription;

  String? get to => _to;
  set to(String? value) => _to = value;

  String? get amount => _amount;
  set amount(String? value) => _amount = value;

  String? get description => _description;
  set description(String? value) => _description = value;

  String? get tipTo => _tipTo;
  set tipTo(String? value) => _tipTo = value;

  String? get tipAmount => _tipAmount;
  set tipAmount(String? value) => _tipAmount = value;

  String? get tipDescription => _tipDescription;
  set tipDescription(String? value) => _tipDescription = value;
}
