import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:emconnect/char.dart';
import 'package:emconnect/logs.dart' show Logs, addLog;
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/connected_device_interface/le_device_services.dart';
import 'package:emconnect/app_globals.dart';
import 'package:emconnect/write_dialog.dart';

//import 'package:emconnect/connected_device_interface/widgets/le_device_services.dart';

class ServicesListWidget extends StatefulWidget {
  final String deviceId;
  final List<BleService> discoveredServices;
  final bool scrollable;
  final Function(BleService service, BleCharacteristic characteristic)? onTap;

  const ServicesListWidget({
    super.key,
    required this.deviceId,
    required this.discoveredServices,
    this.onTap,
    this.scrollable = false,
  });

  @override
  State<ServicesListWidget> createState() => _ServicesListWidgetState();
}

class _ServicesListWidgetState extends State<ServicesListWidget> {
  late List<bool> _expandedStates;
  BeaconTunerService? beaconTunerService;

  @override
  void initState() {
    super.initState();
    _initializeExpandedStates();
  }

  void _initializeExpandedStates() {
    _expandedStates =
        List.generate(widget.discoveredServices.length, (index) => false);
  }

  @override
  void didUpdateWidget(ServicesListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discoveredServices.length !=
        widget.discoveredServices.length) {
      _initializeExpandedStates();
    }
  }

  final Map<String, bool> _characteristicSubscriptions = {};
  final Map<String, String> _characteristicValues = {};
  final Map<String, bool> _showValueForCharacteristic = {};

  final Map<String, IconData> propertyIcons = {
    'read': Icons.download,
    'write': Icons.upload,
  };

  Future<void> subscribeToCharacteristic() async {
    BleInputProperty bleInputProperty;
    List<CharacteristicProperty> properties =
        beaconTunerService!.beaconTunerChar.properties;

    if (properties.contains(CharacteristicProperty.notify)) {
      bleInputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      bleInputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      bleInputProperty,
    );
    setState(() {});
  }

  bool isSubscribed(String serviceUuid, String charUuid) {
    final key = _getCharacteristicKey(serviceUuid, charUuid);
    return _characteristicSubscriptions[key] ?? false;
  }

  void toggleSubscription(String serviceUuid, String charUuid) async {
    final key = _getCharacteristicKey(serviceUuid, charUuid);
    final isCurrentlySubscribed = _characteristicSubscriptions[key] ?? false;


    if (isCurrentlySubscribed) {
      await unsubscribeAssignedCharacteristic();
    } else {
      await subscribeToCharacteristic();
    }

    setState(() {
      _characteristicSubscriptions[key] = !isCurrentlySubscribed;
      debugPrint("new subsribition:${_characteristicSubscriptions[key]}");
    });
  }

  
  
  
  Future<void> _readValue(
    String deviceId,
  ) async {
    var services = await UniversalBle.discoverServices(widget.deviceId);

    for (var service in services) {
      debugPrint("service: $service");
      debugPrint("services12: $services");
      for (var characteristic in service.characteristics) {
        debugPrint("characteristic: $characteristic");
        debugPrint("characteristic.uuid: ${characteristic.uuid}");
        // debugPrint("characteristicUuid: $characteristicUuid");
        // if (characteristic.uuid != characteristicUuid) continue;
        beaconTunerService = BeaconTunerService();
        beaconTunerService!.service = service;
        beaconTunerService!.beaconTunerChar = characteristic;

        if (!characteristic.properties
            .map((e) => e.toString())
            .contains('read')) {
          debugPrint("Characteristic ${characteristic.uuid} is not readable.");
          continue;
        }

        try {
          Uint8List value = await UniversalBle.readValue(
            deviceId,
            beaconTunerService!.service.uuid,
            beaconTunerService!.beaconTunerChar.uuid,
          );
          debugPrint("values: $value");

          // Prepare hex
          String hexValue =
              value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          debugPrint("hexValue: $hexValue");

          // Check if it's all zero
          bool isZero = value.isNotEmpty && value.every((b) => b == 0);

          // Try decoding to string
          String decodedValue = '';
          bool isValidString = true;
          try {
            decodedValue = utf8.decode(value);
            debugPrint("decodedValue: $decodedValue");
            if (decodedValue.trim().isEmpty) isValidString = false;
          } catch (_) {
            isValidString = false;
          }

          final displayValue = isZero
              ? "0"
              : isValidString
                  ? decodedValue
                  : hexValue;

          debugPrint("displayValue: $displayValue");

          setState(() {
            _characteristicValues[characteristic.uuid] = displayValue;
          });
        } catch (e) {
          debugPrint('Error reading ${characteristic.uuid}: $e');
          setState(() {
            _characteristicValues[characteristic.uuid] = "0";
          });
        }
      }
    }
  }

  Future<void> assignServiceAndCharacteristic({
    required String targetServiceUuid,
    required String targetCharacteristicUuid,
  }) async {
    var services = await UniversalBle.discoverServices(widget.deviceId);
    debugPrint("Discovered services: $services");

    for (var service in services) {
      if (service.uuid.toLowerCase() != targetServiceUuid.toLowerCase()) {
        continue;
      }

      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toLowerCase() !=
            targetCharacteristicUuid.toLowerCase()) {
          continue;
        }

        // Found correct service & characteristic → assign to beaconTunerService
        beaconTunerService = BeaconTunerService();
        beaconTunerService!.service = service;
        beaconTunerService!.beaconTunerChar = characteristic;

        debugPrint("Assigned service: ${beaconTunerService!.service.uuid}");
        debugPrint(
            "Assigned characteristic: ${beaconTunerService!.beaconTunerChar.uuid}");
        return;
      }
    }

    debugPrint("Target service/characteristic not found!");
  }

  Future<void> unsubscribeAssignedCharacteristic() async {
    List<CharacteristicProperty> properties =
        beaconTunerService!.beaconTunerChar.properties;

    BleInputProperty bleInputProperty;
    if (properties.contains(CharacteristicProperty.notify)) {
      bleInputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      bleInputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property on characteristic';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      // Pass null or a way to disable notification, here false disables it
      BleInputProperty.disabled,
    );
    setState(() {});
  }

  
  
  
  Future<void> readAssignedCharacteristicValue() async {
    if (beaconTunerService == null) {
      debugPrint(
          "Error: beaconTunerService or characteristic is not assigned.");
      return;
    }

    try {
      Uint8List value = await UniversalBle.readValue(
        widget.deviceId,
        beaconTunerService!.service.uuid,
        beaconTunerService!.beaconTunerChar.uuid,
      );

      debugPrint("values: $value");

      String hexValue =
          value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      debugPrint("hexValue: $hexValue");

      bool isZero = value.isNotEmpty && value.every((b) => b == 0);

      String decodedValue = '';
      bool isValidString = true;
      try {
        decodedValue = utf8.decode(value);
        debugPrint("decodedValue: $decodedValue");
        if (decodedValue.trim().isEmpty) isValidString = false;
      } catch (_) {
        isValidString = false;
      }

      final displayValue = isZero
          ? "0"
          : isValidString
              ? decodedValue
              : hexValue;

      debugPrint("displayValue: $displayValue");

      setState(() {
        _characteristicValues[beaconTunerService!.beaconTunerChar.uuid] =
            displayValue;
      });
    } catch (e) {
      debugPrint(
          'Error reading ${beaconTunerService!.beaconTunerChar.uuid}: $e');
      setState(() {
        _characteristicValues[beaconTunerService!.beaconTunerChar.uuid] = "0";
      });
    }
  }

  
  
  
  
  Future<void> writeToAssignedCharacteristic(Uint8List value) async {
    if (beaconTunerService == null) {
      debugPrint(
          "Error: beaconTunerService or characteristic is not assigned.");
      return;
    }

    try {
      await UniversalBle.writeValue(
        widget.deviceId,
        beaconTunerService!.service.uuid,
        beaconTunerService!.beaconTunerChar.uuid,
        value,
        BleOutputProperty.withResponse,
      );

      debugPrint(
          'Write command sent successfully to ${beaconTunerService!.beaconTunerChar.uuid}');
    } catch (e) {
      debugPrint('Write Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Write failed: $e')),
      );
    }
  }

  
  Future<void>charactersticSubscribe() async {
    if (beaconTunerService == null) {
      debugPrint("BeaconTunerService is not initialized yet.");
      return;
    }

    final characteristic = beaconTunerService!.beaconTunerChar;

    if (!characteristic.properties.contains(CharacteristicProperty.notify) &&
        !characteristic.properties.contains(CharacteristicProperty.indicate)) {
      debugPrint(
          "Characteristic ${characteristic.uuid} does not support notifications or indications.");
      return;
    }

    await subscribeAssignedCharacteristic();
  }
  
  Future<void> subscribeAssignedCharacteristic() async {
    debugPrint(
        "Subscribing to Beacon Tuner Characteristic$beaconTunerService");
    debugPrint("sunscribe2${beaconTunerService!.beaconTunerChar}");
    BleInputProperty bleInputProperty;
    List<CharacteristicProperty> properties =
        beaconTunerService!.beaconTunerChar.properties;

    if (properties.contains(CharacteristicProperty.notify)) {
      bleInputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      bleInputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      bleInputProperty,
    );
    setState(() {});
  }

  
  
  
  
  // Future<void> _readvalue() async{
  //   try {
  //     Uint8List value = await UniversalBle.readValue(
  //       widget.deviceId,
  //       beaconTunerService.service.uuid,
  //       beaconTunerService.beaconTunerChar.uuid,
  //     );
  //     debugPrint("values: $value");

  //     // Prepare hex
  //     String hexValue =
  //         value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  //     debugPrint("hexValue: $hexValue");

  //     // Check if it's all zero
  //     bool isZero = value.isNotEmpty && value.every((b) => b == 0);

  //     // Try decoding to string
  //     String decodedValue = '';
  //     bool isValidString = true;
  //     try {
  //       decodedValue = utf8.decode(value);
  //       debugPrint("decodedValue: $decodedValue");
  //       if (decodedValue.trim().isEmpty) isValidString = false;
  //     } catch (_) {
  //       isValidString = false;
  //     }

  //     final displayValue = isZero
  //         ? "0"
  //         : isValidString
  //             ? decodedValue
  //             : hexValue;

  //     debugPrint("displayValue: $displayValue");

  //     setState(() {
  //       _characteristicValues[beaconTunerService.beaconTunerChar.uuid] =
  //           displayValue;
  //       _showValueForCharacteristic[beaconTunerService.beaconTunerChar.uuid] =
  //           true;
  //     });
  //   } catch (e) {
  //     debugPrint(
  //         'Error reading ${beaconTunerService.beaconTunerChar.uuid}: $e');
  //   }

  // }
  // Future<void> _readvalue() async {
  //     if (beaconTunerService == null) {
  //   debugPrint("BeaconTunerService is not initialized yet.");
  //   return;
  // }

  //   final characteristic = beaconTunerService!.beaconTunerChar;

  //   if (!characteristic.properties.contains(CharacteristicProperty.read)) {
  //     debugPrint("Characteristic ${characteristic.uuid} is not readable.");
  //     return;
  //   }

  //   try {
  //     Uint8List value = await UniversalBle.readValue(
  //       widget.deviceId,
  //       beaconTunerService!.service.uuid,
  //       characteristic.uuid,
  //     );
  //     debugPrint("values: $value");

  //     // Prepare hex
  //     String hexValue =
  //         value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  //     debugPrint("hexValue: $hexValue");

  //     // Check if it's all zero
  //     bool isZero = value.isNotEmpty && value.every((b) => b == 0);

  //     // Try decoding to string
  //     String decodedValue = '';
  //     bool isValidString = true;
  //     try {
  //       decodedValue = utf8.decode(value);
  //       debugPrint("decodedValue: $decodedValue");
  //       if (decodedValue.trim().isEmpty) isValidString = false;
  //     } catch (_) {
  //       isValidString = false;
  //     }

  //     final displayValue = isZero
  //         ? "0"
  //         : isValidString
  //             ? decodedValue
  //             : hexValue;

  //     debugPrint("displayValue: $displayValue");

  //     setState(() {
  //       _characteristicValues[characteristic.uuid] = displayValue;
  //       _showValueForCharacteristic[characteristic.uuid] = true;
  //     });
  //   } catch (e) {
  //     debugPrint('Error reading ${characteristic.uuid}: $e');
  //     setState(() {
  //       _characteristicValues[characteristic.uuid] = "0";
  //     });
  //   }
  // }

//   void discoverBeaconTunerService(List<BleService> services, String characteristicUuid) {
//   for (var service in services) {
//     for (var characteristic in service.characteristics) {
//       if (characteristic.uuid.toLowerCase() == characteristicUuid.toLowerCase()) {
//         if (!characteristic.properties
//             .map((e) => e.toString())
//             .contains('read')) {
//           debugPrint("Characteristic ${characteristic.uuid} is not readable.");
//           return;
//         }

//         setState(() {
//                   beaconTunerService = BeaconTunerService()
//           ..service = service
//           ..beaconTunerChar = characteristic;

//           // beaconTunerService = BeaconTunerService(

//           // );
//         });
//         debugPrint("Assigned beaconTunerService: service ${service.uuid}, characteristic ${characteristic.uuid}");
//         return;
//       }
//     }
//   }
//   debugPrint("BeaconTunerService not found.");
// }

// Your _readvalue method as you wrote it
// Future<void> _readvalue() async {
//   final targetUuid = beaconTunerService?.beaconTunerChar.uuid.toLowerCase();

//   if (targetUuid == null) {
//     debugPrint("BeaconTunerService is not initialized.");
//     return;
//   }

//   var services = await UniversalBle.discoverServices(widget.deviceId);
//   debugPrint("Discovered services: $services");

//   for (var service in services) {
//     for (var characteristic in service.characteristics) {
//       debugPrint("Checking characteristic: ${characteristic.uuid}");

//       if (characteristic.uuid.toLowerCase() != targetUuid) continue;

//       if (!characteristic.properties.contains(CharacteristicProperty.read)) {
//         debugPrint("Characteristic ${characteristic.uuid} is not readable.");
//         return;
//       }

//       beaconTunerService!.service = service;
//       beaconTunerService!.beaconTunerChar = characteristic;

//       try {
//         Uint8List value = await UniversalBle.readValue(
//           widget.deviceId,
//           service.uuid,
//           characteristic.uuid,
//         );

//         debugPrint("Raw Value: $value");

//         String hexValue =
//             value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
//         bool isZero = value.isNotEmpty && value.every((b) => b == 0);

//         String decodedValue = '';
//         bool isValidString = true;
//         try {
//           decodedValue = utf8.decode(value);
//           if (decodedValue.trim().isEmpty) isValidString = false;
//         } catch (_) {
//           isValidString = false;
//         }

//         final displayValue = isZero
//             ? "0"
//             : isValidString
//                 ? decodedValue
//                 : hexValue;

//         debugPrint("Final displayValue: $displayValue");

//         setState(() {
//           _characteristicValues[characteristic.uuid] = displayValue;
//           _showValueForCharacteristic[characteristic.uuid] = true;
//         });
//       } catch (e) {
//         debugPrint('Error reading ${characteristic.uuid}: $e');
//         setState(() {
//           _characteristicValues[characteristic.uuid] = "0";
//         });
//       }

//       return; // Stop after reading the correct one
//     }
//   }

//   debugPrint("No matching characteristic found for UUID: $targetUuid");
// }

//   Future<void> _readvalue() async {
//   final services = await UniversalBle.discoverServices(widget.deviceId);
//   debugPrint("Discovered services: $services");

//   for (var service in services) {
//     for (var characteristic in service.characteristics) {
//       final charUuid = characteristic.uuid.toLowerCase();

//       if (!characteristic.properties.contains(CharacteristicProperty.read)) {
//         debugPrint("Skipping non-readable characteristic: $charUuid");
//         continue;
//       }

//       debugPrint("Reading readable characteristic: $charUuid");

//       try {
//         Uint8List value = await UniversalBle.readValue(
//           widget.deviceId,
//           service.uuid,
//           characteristic.uuid,
//         );

//         debugPrint("Raw Value for $charUuid: $value");

//         String hexValue = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
//         bool isZero = value.isNotEmpty && value.every((b) => b == 0);

//         String decodedValue = '';
//         bool isValidString = true;
//         try {
//           decodedValue = utf8.decode(value);
//           if (decodedValue.trim().isEmpty) isValidString = false;
//         } catch (_) {
//           isValidString = false;
//         }

//         final displayValue = isZero
//             ? "0"
//             : isValidString
//                 ? decodedValue
//                 : hexValue;

//         debugPrint("Final displayValue for $charUuid: $displayValue");

//         setState(() {
//           _characteristicValues[characteristic.uuid] = displayValue;
//           _showValueForCharacteristic[characteristic.uuid] = true;
//         });
//       } catch (e) {
//         debugPrint('Error reading $charUuid: $e');
//         setState(() {
//           _characteristicValues[characteristic.uuid] = "0";
//         });
//       }
//     }
//   }
// }

  String _getCharacteristicKey(String serviceUuid, String charUuid) {
    return '$serviceUuid|$charUuid';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) async {
        // if (details.primaryVelocity != null && details.primaryVelocity! > 0) {

        //   // final dir = await getApplicationDocumentsDirectory();
        //   // final file = File('${dir.path}/logs.txt');
        //   // if (await file.exists()) {
        //   //   await file.writeAsString(''); // Clear the file content
        //   // }
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => Logs()),
        //   );
        // }
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            debugPrint("Left to right swipe detected");
            // Left to right swipe – go to Logs
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const Logs(),
                transitionsBuilder: (_, animation, __, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(-1.0, 0.0), // From left
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                      position: offsetAnimation, child: child);
                },
              ),
            );
          } else if (details.primaryVelocity! < 0) {
            debugPrint("Right to left swipe detected");
            // Right to left swipe – go back
            Navigator.pop(context);
          }
        }
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.discoveredServices.length,
              itemBuilder: (BuildContext context, int index) {
                final service = widget.discoveredServices[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceName(service.uuid),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Card(
                        color: Colors.white,
                        elevation: 4,
                        margin: const EdgeInsets.all(1),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                        child: ListTile(
                          title: Text(
                            'UUID: ${_formatUUID(service.uuid)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: const Text(
                            "PRIMARY SERVICE",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Icon(
                            _expandedStates[index]
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            setState(() {
                              _expandedStates[index] = !_expandedStates[index];
                            });
                          },
                        ),
                      ),
                      if (_expandedStates[index])
                        Column(
                          children: service.characteristics.map((e) {
                            final showValue =
                                _showValueForCharacteristic[e.uuid] ?? false;
                            return Card(
                              color: Colors.white,
                              elevation: 4,
                              margin: const EdgeInsets.all(0.5),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                BLECharacteristicHelper
                                                    .getCharacteristicName(
                                                        e.uuid.substring(0, 8)),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                softWrap: true,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'UUID: 0x${e.uuid.substring(0, 8).replaceFirst(RegExp(r'^0+'), '').toUpperCase()}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                                softWrap: true,
                                              ),
                                              Text(
                                                'Properties: ${e.properties.join(', ').toUpperCase()}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                                softWrap: true,
                                              ),
                                              if (e.properties.contains(
                                                  CharacteristicProperty
                                                      .indicate)) ...[
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'Descriptors:',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'Client Characteristic Configuration',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                              if (showValue)
                                                Text(
                                                  'value: ${_characteristicValues[e.uuid] ?? ""}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: null,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: e.properties.map((prop) {
                                            String type =
                                                prop.name.toLowerCase();

                                            if (type == 'read') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    //await _readvalue();
                                                    // await _readValue(
                                                    //   widget.deviceId,
                                                    //   // widget.discoveredServices,
                                                    //   // e.uuid,
                                                    // );
                                                    await assignServiceAndCharacteristic(
                                                      targetServiceUuid:
                                                          service.uuid,
                                                      targetCharacteristicUuid:
                                                          e.uuid,
                                                    );

                                                    await readAssignedCharacteristicValue();

                                                    if (mounted) {
                                                      setState(() {
                                                        _showValueForCharacteristic[
                                                            e.uuid] = true;
                                                      });
                                                    }
                                                  },
                                                  child: Icon(
                                                    propertyIcons[type]!,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            } 
                                            else if (type == 'write') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // showDialog(
                                                    //   context: context,
                                                    //   builder: (BuildContext
                                                    //       context) {
                                                    //     String inputValue = '';
                                                    //     String selectedFormat =
                                                    //         'Byte Array';
                                                    //     final formats = [
                                                    //       'Text (UTF-8)',
                                                    //       'Byte',
                                                    //       'Byte Array',
                                                    //       'UInt8',
                                                    //       'UInt16 (Little Endian)',
                                                    //       'UInt16 (Big Endian)',
                                                    //       'UInt32 (Little Endian)',
                                                    //       'UInt32 (Big Endian)',
                                                    //       'SInt8',
                                                    //       'SInt16 (Big Endian)',
                                                    //       'SInt32 (Little Endian)',
                                                    //       'SInt32 (Big Endian)',
                                                    //       'Float16 (IEEE-11073)',
                                                    //       'Float32 (IEEE-11073)',
                                                    //     ];

                                                    //     return StatefulBuilder(
                                                    //       builder: (context,
                                                    //           setState) {
                                                    //         return AlertDialog(
                                                    //           title: const Text(
                                                    //               'Write value'),
                                                    //           content: Column(
                                                    //             mainAxisSize:
                                                    //                 MainAxisSize
                                                    //                     .min,
                                                    //             children: [
                                                    //               Row(
                                                    //                 children: [
                                                    //                   Expanded(
                                                    //                     child:
                                                    //                         TextField(
                                                    //                       autofocus:
                                                    //                           true,
                                                    //                       keyboardType: selectedFormat == 'Text (UTF-8)'
                                                    //                           ? TextInputType.text
                                                    //                           : TextInputType.number,
                                                    //                       decoration:
                                                    //                           const InputDecoration(hintText: 'Enter value'),
                                                    //                       onChanged: (value) =>
                                                    //                           inputValue = value,
                                                    //                     ),
                                                    //                   ),
                                                    //                   const SizedBox(
                                                    //                       width:
                                                    //                           8),
                                                    //                   DropdownButton<
                                                    //                       String>(
                                                    //                     value:
                                                    //                         selectedFormat,
                                                    //                     isDense:
                                                    //                         true,
                                                    //                     style: const TextStyle(
                                                    //                         color:
                                                    //                             Colors.black,
                                                    //                         fontSize: 12),
                                                    //                     alignment:
                                                    //                         Alignment.centerRight,
                                                    //                     items: formats
                                                    //                         .map((format) {
                                                    //                       return DropdownMenuItem(
                                                    //                         value:
                                                    //                             format,
                                                    //                         child:
                                                    //                             Text(
                                                    //                           format,
                                                    //                           style: const TextStyle(fontSize: 12),
                                                    //                         ),
                                                    //                       );
                                                    //                     }).toList(),
                                                    //                     onChanged:
                                                    //                         (value) {
                                                    //                       if (value !=
                                                    //                           null) {
                                                    //                         setState(() =>
                                                    //                             selectedFormat = value);
                                                    //                       }
                                                    //                     },
                                                    //                   ),
                                                    //                 ],
                                                    //               ),
                                                    //             ],
                                                    //           ),
                                                    //           actions: [
                                                    //             TextButton(
                                                    //               onPressed: () =>
                                                    //                   Navigator.of(
                                                    //                           context)
                                                    //                       .pop(),
                                                    //               child: const Text(
                                                    //                   'CANCEL'),
                                                    //             ),
                                                    //             TextButton(
                                                    //               onPressed:
                                                    //                   () async {
                                                    //                 Navigator.of(
                                                    //                         context)
                                                    //                     .pop();
                                                    //                 List<int>
                                                    //                     bytes =
                                                    //                     [];

                                                    //                 try {
                                                    //                   debugPrint(
                                                    //                       "Input Value: $inputValue");
                                                    //                   switch (
                                                    //                       selectedFormat) {
                                                    //                     case 'Text (UTF-8)':
                                                    //                       bytes =
                                                    //                           inputValue.codeUnits;
                                                    //                       break;

                                                    //                     case 'Byte':
                                                    //                     case 'UInt8':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       if (val < 0 ||
                                                    //                           val > 255) {
                                                    //                         throw Exception("UInt8 out of range");
                                                    //                       }
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'Byte Array':
                                                    //                       bytes = inputValue
                                                    //                           .split(',')
                                                    //                           .map((s) => int.parse(s.trim()))
                                                    //                           .toList();
                                                    //                           debugPrint("Byte Array: $bytes");
                                                    //                       break;

                                                    //                     case 'UInt16 (Little Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'UInt16 (Big Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         val &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'UInt32 (Little Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         (val >> 16) &
                                                    //                             0xFF,
                                                    //                         (val >> 24) &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'UInt32 (Big Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         (val >> 24) &
                                                    //                             0xFF,
                                                    //                         (val >> 16) &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         val &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'SInt8':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       if (val < -128 ||
                                                    //                           val > 127) {
                                                    //                         throw Exception("SInt8 out of range");
                                                    //                       }
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'SInt16 (Big Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       if (val < -32768 ||
                                                    //                           val > 32767) {
                                                    //                         throw Exception("SInt16 out of range");
                                                    //                       }
                                                    //                       bytes =
                                                    //                           [
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         val &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'SInt32 (Little Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         (val >> 16) &
                                                    //                             0xFF,
                                                    //                         (val >> 24) &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'SInt32 (Big Endian)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue);
                                                    //                       bytes =
                                                    //                           [
                                                    //                         (val >> 24) &
                                                    //                             0xFF,
                                                    //                         (val >> 16) &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF,
                                                    //                         val &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'Float16 (IEEE-11073)':
                                                    //                       int val =
                                                    //                           int.parse(inputValue); // Simulated as 2-byte int
                                                    //                       bytes =
                                                    //                           [
                                                    //                         val &
                                                    //                             0xFF,
                                                    //                         (val >> 8) &
                                                    //                             0xFF
                                                    //                       ];
                                                    //                       break;

                                                    //                     case 'Float32 (IEEE-11073)':
                                                    //                       double
                                                    //                           floatVal =
                                                    //                           double.parse(inputValue);
                                                    //                       final byteData = ByteData(
                                                    //                           4)
                                                    //                         ..setFloat32(
                                                    //                             0,
                                                    //                             floatVal,
                                                    //                             Endian.little);
                                                    //                       bytes = byteData
                                                    //                           .buffer
                                                    //                           .asUint8List();
                                                    //                       break;

                                                    //                     default:
                                                    //                       bytes =
                                                    //                           inputValue.codeUnits;
                                                    //                   }
                                                    //                   addLog(
                                                    //                       "Sent",
                                                    //                       bytes);
                                                    //                   // .map((b) => b.toRadixString(16).padLeft(2, '0'))
                                                    //                   // .join('-'));

                                                    //                   await assignServiceAndCharacteristic(
                                                    //                     targetServiceUuid:
                                                    //                         service.uuid,
                                                    //                     targetCharacteristicUuid:
                                                    //                         e.uuid,
                                                    //                   );
                                                    //                   await writeToAssignedCharacteristic(
                                                    //                       Uint8List.fromList(
                                                    //                           bytes));

                                                    //                   debugPrint(
                                                    //                       'Write command sent successfully');
                                                    //                   await Future.delayed(const Duration(
                                                    //                       milliseconds:
                                                    //                           500));
                                                    //                 } catch (e) {
                                                    //                   debugPrint(
                                                    //                       'Write Error: $e');
                                                    //                   if (!mounted) {
                                                    //                     return;
                                                    //                   }
                                                    //                   ScaffoldMessenger.of(
                                                    //                           context)
                                                    //                       .showSnackBar(
                                                    //                     SnackBar(
                                                    //                         content:
                                                    //                             Text('Invalid input: $e')),
                                                    //                   );
                                                    //                 }
                                                    //               },
                                                    //               child:
                                                    //                   const Text(
                                                    //                       'SEND'),
                                                    //             ),
                                                    //           ],
                                                    //         );
                                                    //       },
                                                    //     );
                                                    //   },
                                                    // );



                                                      showWriteDialog(
    context,
    service.uuid,
    e.uuid,
    onWrite: (Uint8List value) async {
      await assignServiceAndCharacteristic(
        targetServiceUuid: service.uuid,
        targetCharacteristicUuid: e.uuid,
      );
      await writeToAssignedCharacteristic(value);
    },
    addLog: (type, bytes) {
      addLog(type, bytes);
    },
  );

                                                  },
                                                  child: Icon(
                                                    propertyIcons[type]!,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            } 
                                            else if (type == 'notify' ||
                                                type == 'notification') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    toggleSubscription(
                                                        service.uuid, e.uuid);

                                                    final subscribed =
                                                        isSubscribed(
                                                            service.uuid,
                                                            e.uuid);
                                                    final displayValue = subscribed
                                                        ? "Notifications are enabled"
                                                        : "Notifications are disabled";

                                                    setState(() {
                                                      _showValueForCharacteristic[
                                                          e.uuid] = true;
                                                      _characteristicValues[e
                                                          .uuid] = displayValue;
                                                    });

                                                    debugPrint(
                                                        "Status: $displayValue");
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: Colors.black,
                                                            width: 1.5),
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Icon(
                                                          isSubscribed(
                                                                  service.uuid,
                                                                  e.uuid)
                                                              ? Icons
                                                                  .notifications_on_outlined
                                                              : Icons
                                                                  .notifications_off_outlined,
                                                          size: 25,
                                                          color: Colors.grey,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else if (type == 'indicate') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    toggleSubscription(
                                                        service.uuid, e.uuid);

                                                    final subscribed =
                                                        isSubscribed(
                                                            service.uuid,
                                                            e.uuid);
                                                    final displayValue = subscribed
                                                        ? "Indications are enabled"
                                                        : "Indications are disabled";

                                                    setState(() {
                                                      _showValueForCharacteristic[
                                                          e.uuid] = true;
                                                      _characteristicValues[e
                                                          .uuid] = displayValue;
                                                    });

                                                    debugPrint(
                                                        "Status: $displayValue");
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: Colors.black,
                                                            width: 1.5),
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Icon(
                                                          isSubscribed(
                                                                  service.uuid,
                                                                  e.uuid)
                                                              ? Icons
                                                                  .notifications_on_outlined
                                                              : Icons
                                                                  .notifications_off_outlined,
                                                          size: 25,
                                                          color: Colors.grey,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Handle both notify and indicate or unknown type
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    toggleSubscription(
                                                        service.uuid, e.uuid);

                                                    final subscribed =
                                                        isSubscribed(
                                                            service.uuid,
                                                            e.uuid);
                                                    final displayValue = subscribed
                                                        ? "Notifications and indications are enabled"
                                                        : "Notifications and indications are disabled";

                                                    setState(() {
                                                      _showValueForCharacteristic[
                                                          e.uuid] = true;
                                                      _characteristicValues[e
                                                          .uuid] = displayValue;
                                                    });

                                                    debugPrint(
                                                        "Status: $displayValue");
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: Colors.black,
                                                            width: 1.5),
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .notifications_off,
                                                            size: 28,
                                                            color:
                                                                Colors.black),
                                                        if (isSubscribed(
                                                            service.uuid,
                                                            e.uuid))
                                                          const Icon(
                                                              Icons
                                                                  .notifications_active,
                                                              size: 28,
                                                              color:
                                                                  Colors.blue),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }).toList(),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatUUID(String uuid) {
    // Format the UUID based on its type
    if (uuid.toLowerCase() == "81cf7a98-454d-11e8-adc0-fa7ae01bd428") {
      // Beacon Tuning Service - Display full 128-bit UUID
      return uuid;
    } else if (uuid.toLowerCase().contains("00001800") ||
        uuid.toLowerCase().contains("00001801")) {
      // Generic Access and Generic Attribute - Display 16-bit UUID
      return '0x${uuid.substring(4, 8)}'; // Extract 16-bit portion and prefix with 0x
    } else if (uuid.length > 8) {
      // Default - Display first 32 bits with 0x prefix
      return '0x${uuid.substring(0, 8)}';
    } else {
      // Short UUIDs
      return '0x$uuid';
    }
  }

  String _getServiceName(String uuid) {
    if (uuid.length == 36 &&
        uuid.toLowerCase() == "81cf7a98-454d-11e8-adc0-fa7ae01bd428") {
      return 'BEACON TUNER';
    }

    String shortUuid = uuid.length > 8
        ? uuid.substring(4, 8).toLowerCase()
        : uuid.toLowerCase();

    switch (shortUuid) {
      case "1800":
        return 'GENERIC ACCESS';
      case "1801":
        return 'GENERIC ATTRIBUTE';
      default:
        return 'UNNAMED';
    }
  }

  String _getCharacteristicName(String uuid) {
    switch (uuid) {
      case "00002a00":
        return 'Device Name : ';
      case "00002b29":
        return 'Client Supported Feature : ';
      case "00002a01":
        return 'Appearance : ';
      case "00002a04":
        return 'Peripheral Preferred Connection  : ';
      case "00002b2a":
        return 'Database Hash : ';
      case "00002a05":
        return 'Service Changed : ';
      case "00002a19":
        return 'Battery Level : ';
      case "00002a29":
        return 'Manufacturer Name String : ';
      case "00002a24":
        return 'Model Number String : ';
      case "00002a37":
        return 'Heart Rate Measurement : ';
      case "00002a1c":
        return 'Temperature Measurement : ';
      case "00002aa6":
        return 'Central Address Resolution :';
      case "00002b3a":
        return 'Server Supported Feature :';
      default:
        return '$uuid : '; // Return UUID if not recognized
    }
  }
}
