class PushUpdateRequest {
  final String token;
  final String account;

  PushUpdateRequest(
    this.token,
    this.account,
  );

  Map<String, dynamic> toJson() => {
        'token': token,
        'account': account,
      };
}
