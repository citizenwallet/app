import 'dart:io';

import 'package:citizenwallet/services/photos/file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class PhotosService {
  static final PhotosService _instance = PhotosService._internal();
  factory PhotosService() => _instance;
  PhotosService._internal();

  Future<(Uint8List, String)?> selectPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      if (result.files.single.bytes == null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        return (bytes, result.files.single.extension!);
      }

      return (result.files.single.bytes!, result.files.single.extension!);
    }

    return null;
  }

  Future<(List<int>, String)> photoToData(String path) async {
    final bytes = await pathToFile(path);
    return (bytes, path.split('.').last);
  }
}
