import 'package:citizenwallet/services/photos/file.dart';
import 'package:file_picker/file_picker.dart';

class PhotosService {
  static final PhotosService _instance = PhotosService._internal();
  factory PhotosService() => _instance;
  PhotosService._internal();

  Future<String?> selectPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      return result.files.single.path;
    }

    return null;
  }

  Future<(List<int>, String)> photoToData(String path) async {
    final bytes = await pathToFile(path);
    return (bytes, path.split('.').last);
  }
}
