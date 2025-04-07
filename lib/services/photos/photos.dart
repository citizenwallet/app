import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:citizenwallet/services/photos/file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class PhotosService {
  static final PhotosService _instance = PhotosService._internal();
  factory PhotosService() => _instance;
  PhotosService._internal();

  Future<Uint8List?> _resize(Uint8List bytes) async {
    final cmd = Command()
      ..decodeImage(bytes)
      ..bakeOrientation()
      ..copyResize(
        width: 512,
        interpolation: Interpolation.linear,
      )
      ..encodeJpg();

    await cmd.executeThread();

    final imgbytes = await cmd.getBytesThread();
    if (imgbytes == null) {
      return null;
    }

    return Uint8List.fromList(imgbytes);
  }

  Future<(Uint8List, String)?> selectPhoto() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null && result.files.isNotEmpty) {
      if (result.files.single.bytes == null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();

        final resized = await _resize(bytes);
        if (resized == null) {
          return null;
        }

        return (resized, 'jpg');
      }

      final resized = await _resize(result.files.single.bytes!);
      if (resized == null) {
        return null;
      }

      return (resized, 'jpg');
    }

    return null;
  }

  Future<(List<int>, String)> photoToData(String path) async {
    final bytes = await pathToFile(path);
    return (bytes, path.split('.').last);
  }

  Future<Uint8List> photoFromBundle(String path) async {
    final data = await rootBundle.load(path);

    final buffer = data.buffer;

    return buffer.asUint8List();
  }
}
