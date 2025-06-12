
import 'package:convert/convert.dart';
import 'package:emconnect/app_globals.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

class EmBleOps {
  EmBleOps._();

  // static Future<List<Uint8List>> seralize({
  //   List<int>? opcodes,
  //   List<Uint8List>? payloads,
  // }) async {
  //   if ((opcodes == null && payloads == null) ||
  //       (opcodes != null && payloads != null)) {
  //     throw ArgumentError(
  //         'Exactly one of opcodes or payloads must be provided.');
  //   }

  //   // Prepare list of Uint8List payloads to send
  //   final List<Uint8List> commands = [];

  //   if (opcodes != null) {
  //     for (final opcode in opcodes) {
  //       commands.add(Uint8List.fromList([opcode]));
  //     }
  //   } else if (payloads != null) {
  //     commands.addAll(payloads);
  //   }

  //   return commands;
  // }

    static Uint8List seralize(List<dynamic> params) {
    return Uint8List.fromList([
      ...params,
    ]);
  }

  
  
  
  static Future<void> writeWithResponse({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
    required Uint8List payload,
  }) async {
    try {
      await UniversalBle.writeValue(
        deviceId,
        service.uuid,
        characteristic.uuid,
        payload,
        BleOutputProperty.withResponse,
      );
      debugPrint("Write with response successful.");
    } catch (e) {
      debugPrint("Error writing value with response: $e");
    }
  }

  static Future<Uint8List?> readvalue({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
  }) async {
    try {
      final value = await UniversalBle.readValue(
        deviceId,
        service.uuid,
        characteristic.uuid,
      );
      debugPrint("Read value successful: $value");
      return value;
    } catch (e) {
      debugPrint("Error reading value: $e");
      return null;
    }
  }

  static Future<void> writeWithoutResponse({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
    required Uint8List payload,
  }) async {
    try {
      await UniversalBle.writeValue(
        deviceId,
        service.uuid,
        characteristic.uuid,
        payload,
        BleOutputProperty.withoutResponse,
      );
      debugPrint("Write without response successful.");
    } catch (e) {
      debugPrint("Error writing value without response: $e");
    }
  }

  /// Notification or Indication subscription
  static Future<void> subscription({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
  }) async {
    try {
      BleInputProperty inputProperty;
      List<CharacteristicProperty> properties = characteristic.properties;

      if (properties.contains(CharacteristicProperty.notify)) {
        inputProperty = BleInputProperty.notification;
      } else if (properties.contains(CharacteristicProperty.indicate)) {
        inputProperty = BleInputProperty.indication;
      } else {
        throw 'Characteristic does not support notify or indicate.';
      }

      await UniversalBle.setNotifiable(
        deviceId,
        service.uuid,
        characteristic.uuid,
        inputProperty,
      );
      addLog("subscribed", inputProperty);

      debugPrint(
          "Subscription set successfully with BleInputProperty: $inputProperty");
            // Then listen for data changes

    } catch (e) {
      debugPrint("Error setting subscription: $e");
    }
  }

  
  
  /// Notification or Indication unsubscribe 
  static Future<void> unsubscription({
    required String deviceId,
    required BleService service,
    required BleCharacteristic characteristic,
  }) async {
    try {
      await UniversalBle.setNotifiable(
        deviceId,
        service.uuid,
        characteristic.uuid,
        BleInputProperty.disabled,
      );
      addLog(
          "unsubscribed", BleInputProperty.disabled); // Log the unsubscription

      debugPrint("Subscription cleared successfully (BleInputProperty.none)");
    } catch (e) {
      debugPrint("Error clearing subscription: $e");
    }
  }


}
