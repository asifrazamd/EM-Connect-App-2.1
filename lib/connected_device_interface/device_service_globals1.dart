// import 'dart:io';

// import 'package:emconnect/connected_device_interface/beacon_configuration.dart' as service;
// import 'package:flutter/foundation.dart';
// import 'package:universal_ble/universal_ble.dart';
// import 'package:path_provider/path_provider.dart';

// class BeaconTunerService {
//   late BleService service;
//   late BleCharacteristic beaconTunerChar;
// }

// class FirmwareUpdateService {
//   late BleService service;
//   late BleCharacteristic controlPointChar;
//   late BleCharacteristic dataChar;
// }

// final List<String> _logs = [];
// void addLog(String type, dynamic data) async {
//   // Get the current timestamp and manually format it as YYYY-MM-DD HH:mm:ss
//   DateTime now = DateTime.now();
//   String timestamp =
//       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//   // Log entry with just the formatted timestamp
//   String logEntry = '[$timestamp]:$type: ${data.toString()}\n';

//   _logs.add(logEntry);

//   await _writeLogToFile(logEntry);
// }

// Future<void> _writeLogToFile(String logEntry) async {
//   final directory = await getApplicationDocumentsDirectory();
//   final logFile = File('${directory.path}/logs.txt');
//   await logFile.writeAsString(logEntry, mode: FileMode.append);
// }

// class EmBleOpcodes {
//   EmBleOpcodes._();
//     static BeaconTunerService? beaconTunerService;


//   static Future<List<Uint8List>> seralize({
//     List<int>? opcodes,
//     List<Uint8List>? payloads,
//   }) async {
//     if ((opcodes == null && payloads == null) ||
//         (opcodes != null && payloads != null)) {
//       throw ArgumentError(
//           'Exactly one of opcodes or payloads must be provided.');
//     }

//     // Prepare list of Uint8List payloads to send
//     final List<Uint8List> commands = [];

//     if (opcodes != null) {
//       for (final opcode in opcodes) {
//         commands.add(Uint8List.fromList([opcode]));
//       }
//     } else if (payloads != null) {
//       commands.addAll(payloads);
//     }

//     return commands;
//   }

  
  
  
  
  
  
//   // Write with response
  
  
  
  
//   static Future<void> writeValueWithResponse({
//     required String deviceId,
//     required BeaconTunerService beaconTunerService,
//     required Uint8List payload,
//   }) async {
//     try {
//       await UniversalBle.writeValue(
//         deviceId,
//         beaconTunerService.service.uuid,
//         beaconTunerService.beaconTunerChar.uuid,
//         payload,
//         BleOutputProperty.withResponse,
//       );
//       debugPrint("Write with response successful.");
//     } catch (e) {
//       debugPrint("Error writing value with response: $e");
//     }
//   }

  
  
  
  
//   // Write without response
//   static Future<void> writeValueWithoutResponse({
//     required String deviceId,
//     required BeaconTunerService beaconTunerService,
//     required Uint8List payload,
//   }) async {
//     try {
//       await UniversalBle.writeValue(
//         deviceId,
//         beaconTunerService.service.uuid,
//         beaconTunerService.beaconTunerChar.uuid,
//         payload,
//         BleOutputProperty.withoutResponse,
//       );
//       debugPrint("Write without response successful.");
//     } catch (e) {
//       debugPrint("Error writing value without response: $e");
//     }
//   }

//   // Read value from specified service and characteristic
//   static Future<Uint8List?> readValue({
//     required String deviceId,
//     //required BeaconTunerService beaconTunerService,

//     // required BleService service,
//     // required BleCharacteristic characteristic,
//   }) async {
//     try {
//       final value = await UniversalBle.readValue(
//         deviceId,
//         beaconTunerService.service.uuid,
//         beaconTunerService.beaconTunerChar.uuid,

//         // service.uuid,
//         // characteristic.uuid,
//       );
//       debugPrint("Read value successful: $value");
//       return value; // Uint8List? or null if failed
//     } catch (e) {
//       debugPrint("Error reading value: $e");
//       return null;
//     }
//   }


//   // Subscribe to notifications/indications on beaconTunerChar
//   //  Future<void> subscribeToChar({
//   //   required String deviceId,
//   //   required BleInputProperty bleInputProperty,
//   //   //required BleService? service,
//   //   //  widget.selectedCharacteristic!.characteristic1.properties;
//   //   //List<CharacteristicProperty>? properties= service,

//   //   required BeaconTunerService beaconTunerService,
//   //   required void Function() setState,
//   // }) async {
//   //                                                       await assignServiceAndCharacteristic(
//   //                                                     targetServiceUuid:
//   //                                                         beaconTunerService
//   //                                                             .service.uuid,
//   //                                                             targetCharacteristicUuid:
//   //                                                           beaconTunerService
//   //                                                               .beaconTunerChar.uuid,
                                                          
//   //     widget: beaconTunerService,
//   //                                                   );

//   //   // BleInputProperty bleInputProperty;
//   //   List<CharacteristicProperty> properties =
//   //       beaconTunerService.beaconTunerChar.properties;

//   //   if (properties.contains(CharacteristicProperty.notify)) {
//   //     bleInputProperty = BleInputProperty.notification;
//   //   } else if (properties.contains(CharacteristicProperty.indicate)) {
//   //     bleInputProperty = BleInputProperty.indication;
//   //   } else {
//   //     throw 'No notify or indicate property';
//   //   }

//   //   await UniversalBle.setNotifiable(
//   //     deviceId,
//   //     beaconTunerService.service.uuid,
//   //     beaconTunerService.beaconTunerChar.uuid,
//   //     bleInputProperty,
//   //   );
//   //   addLog("subscribe", bleInputProperty.toString());
//   //   debugPrint(
//   //       "Subscribed to characteristic: ${beaconTunerService.beaconTunerChar.uuid}");
//   //   if (setState != null) setState();
//   // }

//   // static Future<void> unsubscribeToChar({
//   //   required String deviceId,
//   //   required BeaconTunerService beaconTunerService,
//   //   void Function()? setState,
//   // }) async {
//   //   BleInputProperty bleInputProperty;
//   //   List<CharacteristicProperty> properties =
//   //       beaconTunerService.beaconTunerChar.properties;

//   //   if (properties.contains(CharacteristicProperty.notify)) {
//   //     bleInputProperty = BleInputProperty.notification;
//   //   } else if (properties.contains(CharacteristicProperty.indicate)) {
//   //     bleInputProperty = BleInputProperty.indication;
//   //   } else {
//   //     throw 'No notify or indicate property';
//   //   }

//   //   await UniversalBle.setNotifiable(
//   //     deviceId,
//   //     beaconTunerService.service.uuid,
//   //     beaconTunerService.beaconTunerChar.uuid,
//   //     BleInputProperty.disabled,
//   //   );
//   //   //setState();
//   // }


//   Future<void> subscribeToChar(dynamic widget) async {
//     if (beaconTunerService == null) {
//       debugPrint(
//           "Error: beaconTunerService or characteristic is not assigned.");
//       return;
//     }

//     // Determine the correct BleInputProperty based on characteristic properties
//     BleInputProperty inputProperty;
//     List<CharacteristicProperty> properties =
//         beaconTunerService!.beaconTunerChar.properties;

//     if (properties.contains(CharacteristicProperty.notify)) {
//       inputProperty = BleInputProperty.notification;
//     } else if (properties.contains(CharacteristicProperty.indicate)) {
//       inputProperty = BleInputProperty.indication;
//     } else {
//       throw 'No notify or indicate property';
//     }

//     await UniversalBle.setNotifiable(
//       widget.deviceId,
//       beaconTunerService!.service.uuid,
//       beaconTunerService!.beaconTunerChar.uuid,
//       inputProperty,
//     );
//     addLog('BleInputProperty', inputProperty);

//     //setState(() {});
//   }

  
//     Future<void> unsubscribeAssignedCharacteristic(dynamic widget) async {
//     if (beaconTunerService == null) {
//       debugPrint(
//           "Error: beaconTunerService or characteristic is not assigned.");
//       return;
//     }

//     // Determine the correct BleInputProperty based on characteristic properties
//     BleInputProperty inputProperty;
//     List<CharacteristicProperty> properties =
//         beaconTunerService!.beaconTunerChar.properties;

//     if (properties.contains(CharacteristicProperty.notify)) {
//       inputProperty = BleInputProperty.notification;
//     } else if (properties.contains(CharacteristicProperty.indicate)) {
//       inputProperty = BleInputProperty.indication;
//     } else {
//       throw 'No notify or indicate property';
//     }

//     await UniversalBle.setNotifiable(
//       widget.deviceId,
//       beaconTunerService!.service.uuid,
//       beaconTunerService!.beaconTunerChar.uuid,
//       BleInputProperty.disabled, // Disable notifications/indications
//     );
//     addLog('BleInputProperty', 'disabled');

//     //setState(() {});
//   }

  
//   static Future<void> subscribeAssignedCharacteristic(String deviceId) async {
//     if (beaconTunerService == null) {
//       debugPrint(
//           "Error: beaconTunerService or characteristic is not assigned.");
//       return;
//     }

//     // Determine the correct BleInputProperty based on characteristic properties
//     BleInputProperty inputProperty;
//     List<CharacteristicProperty> properties =
//         beaconTunerService!.beaconTunerChar.properties;

//     if (properties.contains(CharacteristicProperty.notify)) {
//       inputProperty = BleInputProperty.notification;
//     } else if (properties.contains(CharacteristicProperty.indicate)) {
//       inputProperty = BleInputProperty.indication;
//     } else {
//       throw 'No notify or indicate property';
//     }

//     await UniversalBle.setNotifiable(
//       deviceId,
//       beaconTunerService!.service.uuid,
//       beaconTunerService!.beaconTunerChar.uuid,
//       inputProperty,
//     );
//     addLog('BleInputProperty', inputProperty);

//     // setState(() {}); // Remove or handle setState as needed
//   }

//   static Future<void> assignServiceAndCharacteristic({
//       required String deviceId,
//     required String targetServiceUuid,
//     required String targetCharacteristicUuid,
//   }) async {
//     var services = await UniversalBle.discoverServices(deviceId);
//     debugPrint("Discovered services: $services");

//     for (var service in services) {
//       if (service.uuid.toLowerCase() != targetServiceUuid.toLowerCase()) {
//         continue;
//       }

//       for (var characteristic in service.characteristics) {
//         if (characteristic.uuid.toLowerCase() !=
//             targetCharacteristicUuid.toLowerCase()) {
//           continue;
//         }

//         // Found correct service & characteristic → assign to beaconTunerService
//         beaconTunerService = BeaconTunerService();
//         beaconTunerService!.service = service;
//         beaconTunerService!.beaconTunerChar = characteristic;

//         return;
//       }
//     }

//     debugPrint("Target service/characteristic not found!");
//   }

  


// }
