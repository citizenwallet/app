class ExtendedAbiItem {
  final String name;
  final String type;
  final List<dynamic> inputs;
  final String id;
  final String signature;
  bool selected;

  ExtendedAbiItem({
    required this.name,
    required this.type,
    required this.inputs,
    required this.id,
    required this.signature,
    this.selected = false,
  });
}
