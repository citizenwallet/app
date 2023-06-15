class Pagination {
  int offset;
  int limit;
  int total;

  Pagination({
    required this.offset,
    required this.limit,
    required this.total,
  });

  // instantiate empty
  Pagination.empty()
      : offset = 0,
        limit = 0,
        total = 0;

  // instantiate from json
  Pagination.fromJson(Map<String, dynamic> json)
      : offset = json['offset'],
        limit = json['limit'],
        total = json['total'];
}
