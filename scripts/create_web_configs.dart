// main.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:citizenwallet/services/config/config.dart';

const String communityConfigListFileName = 'communities';
const String communityDebugFileName = 'debug';
const int version = 3;

void main(List<String> arguments) async {
  print('\nCreating web configs...\n');

  final configs = await getConfigs();

  // Check if the directory exists and create it if it doesn't
  final directory = Directory('./temp/web_configs');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  } else {
    // Clear all files in the directory
    directory.listSync().forEach((fileSystemEntity) {
      if (fileSystemEntity is File) {
        fileSystemEntity.deleteSync();
      }
    });
  }

  int created = 0;
  for (final config in configs) {
    if (config.community.hidden) {
      continue;
    }

    // Convert the config object to a JSON string
    final jsonString = jsonEncode(config);

    // Write the JSON string to a file
    final file = File('./temp/web_configs/${config.community.alias}.json');
    await file.writeAsString(jsonString);

    print('✅ created config for ${config.community.alias}...');

    created++;
  }

  print('\n$created configs created!\n');
}

Future<List<Config>> getConfigs() async {
  final localConfigs = jsonDecode(
      File('assets/config/v$version/$communityConfigListFileName.json')
          .readAsStringSync());

  final configs =
      (localConfigs as List).map((e) => Config.fromJson(e)).toList();

  return configs;
}
