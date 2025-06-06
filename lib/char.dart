// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:yaml/yaml.dart';

// class BLECharacteristicHelper {
//   static final Map<String, String> _uuidToNameMap = {};

//   /// Load and parse the YAML file
//   static Future<void> loadCharacteristicsFromYaml() async {
//     final yamlString = await rootBundle.loadString('assets/characteristic_uuids.yaml');
//     final yaml = loadYaml(yamlString);

//     if (yaml is YamlMap && yaml['uuids'] is YamlList) {
//       for (var item in yaml['uuids']) {
//         final uuid = item['uuid'].toString().toLowerCase().padLeft(8, '0'); // normalize to 8-digit hex
//         final name = item['name'].toString();
//         _uuidToNameMap[uuid] = name;
//       }
//     }
//   }

//   /// Get the characteristic name
//   static String getCharacteristicName(String uuid) {
//     final normalized = uuid.toLowerCase();
//     return _uuidToNameMap[normalized] ?? '$uuid :';
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class BLECharacteristicHelper {
  static final Map<String, String> _uuidToNameMap = {};

  /// Load and parse the YAML file
  static Future<void> loadCharacteristicsFromYaml() async {
    final yamlString = await rootBundle.loadString('assets/characteristic_uuids.yaml');
    final yaml = loadYaml(yamlString);

    if (yaml is YamlMap && yaml['uuids'] is YamlList) {
      for (var item in yaml['uuids']) {
  var rawUuid = item['uuid'];
  String uuid;

  if (rawUuid is int) {
    uuid = rawUuid.toRadixString(16);
  } else {
    uuid = rawUuid.toString().toLowerCase().replaceAll("0x", "");
  }

  uuid = uuid.padLeft(8, '0');
  final name = item['name'].toString();

  debugPrint('Loaded UUID: $uuid, Name: $name');
  _uuidToNameMap[uuid] = name;
}

      // for (var item in yaml['uuids']) {
      //   String uuid = item['uuid'].toString().toLowerCase().replaceAll("0x", "");
      //   uuid = uuid.padLeft(8, '0'); // Pad to 8 characters like 00002a00
      //   final name = item['name'].toString();
      //   debugPrint('Loaded UUID: $uuid, Name: $name');
      //   _uuidToNameMap[uuid] = name;
      // }
    }
  }

  /// Get the characteristic name from a 128-bit UUID or short form
  static String getCharacteristicName(String uuid) {
    final normalized = uuid.toLowerCase().substring(0, 8);
      final name = _uuidToNameMap[normalized];

  if (name == null) {
    debugPrint('[UUID NAME NOT FOUND] UUID: $uuid, Normalized: $normalized');
  } else {
    debugPrint('[UUID NAME FOUND] UUID: $uuid, Normalized: $normalized → Name: $name');
  }

  return name ?? '$uuid :';
 // Use first 8 digits
    //return _uuidToNameMap[normalized] ?? '$uuid :';
  }
}
