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
}
