class Contact {
  final int id;
  final String name;
  final String avatar;

  Contact({
    required this.id,
    required this.name,
    required this.avatar,
  });

  // convert to Contact object from JSON
  Contact.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        avatar = json['avatar'];

  // Convert a Conversation object into a Map object.
  // The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
      };
}
