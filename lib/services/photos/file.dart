import 'package:universal_io/io.dart';

Future<List<int>> pathToFile(String path) async {
  final file = File(path);

  final bytes = await file.readAsBytes();

  return bytes.toList();
}
