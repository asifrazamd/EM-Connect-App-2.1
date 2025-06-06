import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

class BeaconTunerService {
  late BleService service;
  late BleCharacteristic beaconTunerChar;
}

class FirmwareUpdateService {
  late BleService service;
  late BleCharacteristic controlPointChar;
  late BleCharacteristic dataChar;
}

class EmBleOps {
  EmBleOps._();

  /// Generic BLE write function.
  /// Accepts single or multiple opcodes or full payloads.
  /// Example usages:
  /// - serialize(opcodes: [0x30])
  /// - serialize(payloads: [Uint8List.fromList([0x04, 0x01])])
  // static Future<void> serialize({
  //   required String deviceId,
  //   required BleService service,
  //   required BleCharacteristic characteristic,
  //   List<int>? opcodes,
  //   List<Uint8List>? payloads,
  //   Duration delayBetweenOps = const Duration(milliseconds: 2000),
  // }) async {
  //   try {
  //     // If opcodes provided, convert each to Uint8List and add to payloads
  //     List<Uint8List> finalPayloads = [];

  //     if (opcodes != null) {
  //       for (int opcode in opcodes) {
  //         finalPayloads.add(Uint8List.fromList([opcode]));
  //       }
  //     }

  //     if (payloads != null) {
  //       finalPayloads.addAll(payloads);
  //     }

  //     for (Uint8List payload in finalPayloads) {
  //       print('Writing payload: $payload');

  //       await UniversalBle.writeValue(
  //         deviceId,
  //         service.uuid,
  //         characteristic.uuid,
  //         payload,
  //         BleOutputProperty.withResponse,
  //       );

  //       await Future.delayed(delayBetweenOps);
  //     }
  //   } catch (e) {
  //     print("Error writing BLE operation: $e");
  //   }
  // }


  // Generic BLE write function to send single or multiple opcodes or payloads sequentially
  static Future<void> serialize({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
    List<int>? opcodes,
    List<Uint8List>? payloads,
    Duration delayBetweenOps = const Duration(milliseconds: 500),
  }) async {
    if ((opcodes == null && payloads == null) ||
        (opcodes != null && payloads != null)) {
      throw ArgumentError(
          'Exactly one of opcodes or payloads must be provided.');
    }

    // Prepare list of Uint8List payloads to send
    final List<Uint8List> commands = [];

    if (opcodes != null) {
      for (final opcode in opcodes) {
        commands.add(Uint8List.fromList([opcode]));
      }
    } else if (payloads != null) {
      commands.addAll(payloads);
    }

    for (final payload in commands) {
      try {
        print('Writing payload: $payload');
        await UniversalBle.writeValue(
          deviceId,
          service.uuid,
          characteristic.uuid,
          payload,
          BleOutputProperty.withResponse,
        );
        await Future.delayed(delayBetweenOps);
      } catch (e) {
        print('Error writing BLE payload $payload: $e');
      }
    }
  }

  
  // Utility to build a substitution settings payload (opcode + hex data)
  static Uint8List buildSubstitutionSettings(int advOpcode, String hex) {
    List<int> byteList = [];
    for (int i = 0; i < hex.length; i += 2) {
      byteList.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    print('Substitution bytes: $byteList');
    return Uint8List.fromList([advOpcode, ...byteList]);
  }
}

