import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/char.dart';
import 'package:emconnect/logs.dart' show Logs, addLog;
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
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
    // Start listening for characteristic value changes (notifications)
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
  Map<String, String> _notificationValues =
      {}; // key = characteristic UUID, value = hex string

  final Map<String, IconData> propertyIcons = {
    'read': Icons.download,
    'write': Icons.upload,
  };

  bool isSubscribed(String serviceUuid, String charUuid) {
    final key = _getCharacteristicKey(serviceUuid, charUuid);
    return _characteristicSubscriptions[key] ?? false;
  }

  // void toggleSubscription(String serviceUuid, String charUuid) async {
  //   final key = _getCharacteristicKey(serviceUuid, charUuid);
  //   final isCurrentlySubscribed = _characteristicSubscriptions[key] ?? false;

  //   debugPrint(
  //       "toggleSubscription: $key, currently subscribed: $isCurrentlySubscribed");

  //   if (isCurrentlySubscribed) {
  //   } else {}

  //   setState(() {
  //     _characteristicSubscriptions[key] = !isCurrentlySubscribed;
  //   });
  // }

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

        return;
      }
    }

    debugPrint("Target service/characteristic not found!");
  }

  Future<void> writeToAssignedCharacteristic(Uint8List value) async {
    if (beaconTunerService == null) {
      debugPrint(
          "Error: beaconTunerService or characteristic is not assigned.");
      return;
    }

    try {
      // await UniversalBle.writeValue(
      //   widget.deviceId,
      //   beaconTunerService!.service.uuid,
      //   beaconTunerService!.beaconTunerChar.uuid,
      //   value,
      //   BleOutputProperty.withResponse,
      // );

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

  Future<void> subscribeAssignedCharacteristic() async {
    if (beaconTunerService == null) {
      debugPrint(
          "Error: beaconTunerService or characteristic is not assigned.");
      return;
    }

    // Determine the correct BleInputProperty based on characteristic properties
    BleInputProperty inputProperty;
    List<CharacteristicProperty> properties =
        beaconTunerService!.beaconTunerChar.properties;

    if (properties.contains(CharacteristicProperty.notify)) {
      inputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      inputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      inputProperty,
    );
    addLog('BleInputProperty', inputProperty);

    setState(() {});
  }

  Future<void> unsubscribeAssignedCharacteristic() async {
    if (beaconTunerService == null) {
      debugPrint(
          "Error: beaconTunerService or characteristic is not assigned.");
      return;
    }

    // Determine the correct BleInputProperty based on characteristic properties
    BleInputProperty inputProperty;
    List<CharacteristicProperty> properties =
        beaconTunerService!.beaconTunerChar.properties;

    if (properties.contains(CharacteristicProperty.notify)) {
      inputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      inputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      BleInputProperty.disabled, // Disable notifications/indications
    );
    addLog('BleInputProperty', 'disabled');

    setState(() {});
  }

  String _getCharacteristicKey(String serviceUuid, String charUuid) {
    return '$serviceUuid|$charUuid';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) async {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
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
                                              FutureBuilder<String>(
                                                future: BLECharacteristicHelper
                                                    .getCharacteristicName(
                                                        e.uuid),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data ?? e.uuid,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    softWrap: true,
                                                  );
                                                },
                                              ),

                                              // Text(
                                              //   BLECharacteristicHelper
                                              //       .getCharacteristicName(
                                              //           e.uuid.substring(0, 8)),
                                              //   style: const TextStyle(
                                              //       fontSize: 12,
                                              //       fontWeight:
                                              //           FontWeight.w500),
                                              //   softWrap: true,
                                              // ),
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
                                              if (_notificationValues
                                                  .containsKey(e.uuid))
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(
                                                    'Notification value: ${_notificationValues[e.uuid]}',
                                                    style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 12),
                                                  ),
                                                ),

                                              if (e.properties.contains(
                                                      CharacteristicProperty
                                                          .indicate) ||
                                                  e.properties.contains(
                                                      CharacteristicProperty
                                                          .notify)) ...[
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
                                                    try {
                                                      Uint8List? value =
                                                          await EmBleOpcodes
                                                              .readvalue(
                                                        deviceId:
                                                            widget.deviceId,
                                                        service: service,
                                                        characteristic: e,
                                                      );

                                                      debugPrint(
                                                          "values: $value");

                                                      final hexValue = value !=
                                                              null
                                                          ? value
                                                              .map((b) => b
                                                                  .toRadixString(
                                                                      16)
                                                                  .padLeft(
                                                                      2, '0'))
                                                              .join(' ')
                                                          : '';

                                                      debugPrint(
                                                          "hexValue: $hexValue");

                                                      final isZero = value !=
                                                              null &&
                                                          value.isNotEmpty &&
                                                          value.every(
                                                              (b) => b == 0);

                                                      String decodedValue = '';
                                                      bool isPrintable = false;
                                                      bool isValidString =
                                                          false;
                                                      try {
                                                        decodedValue =
                                                            utf8.decode(
                                                                value ?? []);
            isPrintable = decodedValue.runes.every((r) => r >= 0x20 && r <= 0x7E);
                                                        // isValidString =
                                                        //     decodedValue
                                                        //         .trim()
                                                        //         .isNotEmpty;
                                                        debugPrint(
                                                            "decodedValue: $decodedValue");
                                                      } catch (_) {}

                                                      final displayValue =
                                                          isZero
                                                              ? "0"
                                                              : (isPrintable
                                                                  ? decodedValue
                                                                  : hexValue);

                                                      debugPrint(
                                                          "displayValue: $displayValue");

                                                      if (mounted) {
                                                        setState(() {
                                                          _characteristicValues[
                                                                  e.uuid] =
                                                              displayValue;
                                                          _showValueForCharacteristic[
                                                              e.uuid] = true;
                                                        });
                                                      }
                                                    } catch (err) {
                                                      debugPrint(
                                                          'Error reading ${e.uuid}: $err');
                                                      if (mounted) {
                                                        setState(() {
                                                          _characteristicValues[
                                                              e.uuid] = "0";
                                                          _showValueForCharacteristic[
                                                              e.uuid] = true;
                                                        });
                                                      }
                                                    }
                                                  },
                                                  child: Icon(
                                                    propertyIcons[type]!,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            } else if (type == 'write') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    showWriteDialog(
                                                      context,
                                                      service.uuid,
                                                      e.uuid,
                                                      onWrite: (Uint8List
                                                          value) async {
                                                        await EmBleOpcodes
                                                            .writeWithResponse(
                                                          deviceId:
                                                              widget.deviceId,
                                                          service: service,
                                                          characteristic: e,
                                                          payload: value,
                                                        );
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
//                                             else if (type == 'notify' ||
//                                                 type == 'notification') {
//                                               return Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 2.0),
//                                                 child: GestureDetector(
//                                                   onTap: () async {
//                                                      final key =
//                                                         _getCharacteristicKey(
//                                                             service.uuid,
//                                                             e.uuid);
//                                                     final isCurrentlySubscribed =
//                                                         _characteristicSubscriptions[
//                                                                 key] ??
//                                                             false;

//                                                     if (isCurrentlySubscribed) {
//                                                       await EmBleOpcodes
//                                                           .unsubscription(
//                                                         deviceId:
//                                                             widget.deviceId,
//                                                         service: service,
//                                                         characteristic: e,
//                                                       );
//                                                     } else {

//                                                       await EmBleOpcodes
//                                                           .subscription(
//                                                         deviceId:
//                                                             widget.deviceId,
//                                                         service: service,
//                                                         characteristic: e,
//                                                       );
//                                                       debugPrint("added subscription");
// UniversalBle.characteristicValueStream(widget.deviceId, e.uuid).listen((Uint8List value) {
//   final hexString = hex.encode(value);
//   debugPrint('📩 Notification from ${e.uuid}: $hexString');

//   setState(() {
//     _notificationValues[e.uuid] = hexString; // Store the received value
//     // _showValueForCharacteristic[e.uuid] = true;
//     // _characteristicValues[e.uuid] = hexString; // optional if already using
//   });
// });

//                                                     }

//                                                     setState(() {

//                                                       _characteristicSubscriptions[
//                                                               key] =
//                                                           !isCurrentlySubscribed;
//                                                     });

//                                                     final subscribed =
//                                                         isSubscribed(
//                                                             service.uuid,
//                                                             e.uuid);
//                                                     debugPrint(
//                                                         "notification: $subscribed");
//                                                     final displayValue = subscribed
//                                                         ? "Notifications are enabled"
//                                                         : "Notifications are disabled";

//                                                     setState(() {

//                                                       _showValueForCharacteristic[
//                                                           e.uuid] = true;
//                                                       _characteristicValues[e
//                                                           .uuid] = displayValue;
//                                                     });

//                                                     // toggleSubscription(
//                                                     //     service.uuid, e.uuid);

//                                                     // final subscribed =
//                                                     //     isSubscribed(
//                                                     //         service.uuid,
//                                                     //         e.uuid);
//                                                     // final displayValue = subscribed
//                                                     //     ? "Notifications are enabled"
//                                                     //     : "Notifications are disabled";

//                                                     // setState(() {
//                                                     //   _showValueForCharacteristic[
//                                                     //       e.uuid] = true;
//                                                     //   _characteristicValues[e
//                                                     //       .uuid] = displayValue;
//                                                     // });

//                                                     // debugPrint(
//                                                     //     "Status: $displayValue");
//                                                   },
//                                                   child: Container(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             4.0),
//                                                     decoration:
//                                                         const BoxDecoration(
//                                                       border: Border(
//                                                         bottom: BorderSide(
//                                                             color: Colors.black,
//                                                             width: 1.5),
//                                                       ),
//                                                     ),
//                                                     child: Stack(
//                                                       alignment:
//                                                           Alignment.center,
//                                                       children: [
//                                                         Icon(
//                                                           isSubscribed(
//                                                                   service.uuid,
//                                                                   e.uuid)
//                                                               ? Icons
//                                                                   .notifications_on_outlined
//                                                               : Icons
//                                                                   .notifications_off_outlined,
//                                                           size: 25,
//                                                           color: Colors.grey,
//                                                         )
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ),
//                                               );
//                                             }

                                            else if (type == 'notify' ||
                                                type == 'notification') {
                                              final isAutoSubscribed = service
                                                          .uuid
                                                          .toLowerCase() ==
                                                      '81cf7a98-454d-11e8-adc0-fa7ae01bd428' ||
                                                  service.uuid.toLowerCase() ==
                                                      '81cfa888-454d-11e8-adc0-fa7ae01bd428';
                                              final key = _getCharacteristicKey(
                                                  service.uuid, e.uuid);

                                              if (isAutoSubscribed &&
                                                  (_characteristicSubscriptions[
                                                              key] ??
                                                          false) ==
                                                      false) {
                                                EmBleOpcodes.subscription(
                                                  deviceId: widget.deviceId,
                                                  service: service,
                                                  characteristic: e,
                                                ).then((_) {
                                                  debugPrint(
                                                      "Auto-subscribe notify success for $key");
                                                  setState(() {
                                                    _characteristicSubscriptions[
                                                        key] = true;
                                                    _showValueForCharacteristic[
                                                        e.uuid] = true;
                                                    _characteristicValues[
                                                            e.uuid] =
                                                        "Notifications are enabled";
                                                  });

                                                  UniversalBle
                                                          .characteristicValueStream(
                                                              widget.deviceId,
                                                              e.uuid)
                                                      .listen(
                                                          (Uint8List value) {
                                                    final hexString =
                                                        hex.encode(value);
                                                    debugPrint(
                                                        '📩 Auto-Notification from ${e.uuid}: $hexString');

                                                    setState(() {
                                                      _notificationValues[
                                                          e.uuid] = hexString;
                                                    });
                                                  });
                                                });
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: isAutoSubscribed
                                                      ? null
                                                      : () async {
                                                          final isSubscribed =
                                                              _characteristicSubscriptions[
                                                                      key] ??
                                                                  false;

                                                          if (isSubscribed) {
                                                            await EmBleOpcodes
                                                                .unsubscription(
                                                              deviceId: widget
                                                                  .deviceId,
                                                              service: service,
                                                              characteristic: e,
                                                            );
                                                          } else {
                                                            await EmBleOpcodes
                                                                .subscription(
                                                              deviceId: widget
                                                                  .deviceId,
                                                              service: service,
                                                              characteristic: e,
                                                            );

                                                            UniversalBle.characteristicValueStream(
                                                                    widget
                                                                        .deviceId,
                                                                    e.uuid)
                                                                .listen(
                                                                    (Uint8List
                                                                        value) {
                                                              final hexString =
                                                                  hex.encode(
                                                                      value);
                                                              debugPrint(
                                                                  '📩 Notification from ${e.uuid}: $hexString');

                                                              setState(() {
                                                                _notificationValues[
                                                                        e.uuid] =
                                                                    hexString;
                                                              });
                                                            });
                                                          }

                                                          setState(() {
                                                            _characteristicSubscriptions[
                                                                    key] =
                                                                !isSubscribed;
                                                            _showValueForCharacteristic[
                                                                e.uuid] = true;
                                                            _characteristicValues[
                                                                    e.uuid] =
                                                                !isSubscribed
                                                                    ? "Notifications are enabled"
                                                                    : "Notifications are disabled";
                                                          });
                                                        },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                          bottom: BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1.5)),
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Icon(
                                                          (_characteristicSubscriptions[
                                                                      key] ??
                                                                  false)
                                                              ? Icons
                                                                  .notifications_on_outlined
                                                              : Icons
                                                                  .notifications_off_outlined,
                                                          size: 25,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            // else if (type == 'indicate') {
                                            //   return Padding(
                                            //     padding:
                                            //         const EdgeInsets.symmetric(
                                            //             horizontal: 2.0),
                                            //     child: GestureDetector(
                                            //       onTap: () async {
                                            //         final key =
                                            //             _getCharacteristicKey(
                                            //                 service.uuid,
                                            //                 e.uuid);
                                            //         final isCurrentlySubscribed =
                                            //             _characteristicSubscriptions[
                                            //                     key] ??
                                            //                 false;
                                            //         debugPrint(
                                            //             "toggleSubscription: $key, currently subscribed: $isCurrentlySubscribed");

                                            //         if (isCurrentlySubscribed) {
                                            //           await EmBleOpcodes
                                            //               .unsubscription(
                                            //             deviceId:
                                            //                 widget.deviceId,
                                            //             service: service,
                                            //             characteristic: e,
                                            //           );
                                            //         } else {
                                            //           await EmBleOpcodes
                                            //               .subscription(
                                            //             deviceId:
                                            //                 widget.deviceId,
                                            //             service: service,
                                            //             characteristic: e,
                                            //           );
                                            //         }

                                            //         setState(() {
                                            //           _characteristicSubscriptions[
                                            //                   key] =
                                            //               !isCurrentlySubscribed;
                                            //         });

                                            //         // toggleSubscription(
                                            //         //     service.uuid, e.uuid);

                                            //         final subscribed =
                                            //             isSubscribed(
                                            //                 service.uuid,
                                            //                 e.uuid);
                                            //         debugPrint(
                                            //             "indications: $subscribed");
                                            //         final displayValue = subscribed
                                            //             ? "Indications are enabled"
                                            //             : "Indications are disabled";

                                            //         setState(() {
                                            //           _showValueForCharacteristic[
                                            //               e.uuid] = true;
                                            //           _characteristicValues[e
                                            //               .uuid] = displayValue;
                                            //         });

                                            //         debugPrint(
                                            //             "Status: $displayValue");
                                            //       },
                                            //       child: Container(
                                            //         padding:
                                            //             const EdgeInsets.all(
                                            //                 4.0),
                                            //         decoration:
                                            //             const BoxDecoration(
                                            //           border: Border(
                                            //             bottom: BorderSide(
                                            //                 color: Colors.black,
                                            //                 width: 1.5),
                                            //           ),
                                            //         ),
                                            //         child: Stack(
                                            //           alignment:
                                            //               Alignment.center,
                                            //           children: [
                                            //             Icon(
                                            //               isSubscribed(
                                            //                       service.uuid,
                                            //                       e.uuid)
                                            //                   ? Icons
                                            //                       .notifications_on_outlined
                                            //                   : Icons
                                            //                       .notifications_off_outlined,
                                            //               size: 25,
                                            //               color: Colors.grey,
                                            //             )
                                            //           ],
                                            //         ),
                                            //       ),
                                            //     ),
                                            //   );
                                            // }

                                            else if (type == 'indicate') {
                                              final isAutoSubscribedService = service
                                                          .uuid
                                                          .toLowerCase() ==
                                                      '81cf7a98-454d-11e8-adc0-fa7ae01bd428' ||
                                                  service.uuid.toLowerCase() ==
                                                      '81cfa888-454d-11e8-adc0-fa7ae01bd428';
                                              final key = _getCharacteristicKey(
                                                  service.uuid, e.uuid);

                                              if (isAutoSubscribedService &&
                                                  (_characteristicSubscriptions[
                                                              key] ??
                                                          false) ==
                                                      false) {
                                                // Automatically subscribe once if not already subscribed
                                                EmBleOpcodes.subscription(
                                                  deviceId: widget.deviceId,
                                                  service: service,
                                                  characteristic: e,
                                                ).then((_) {
                                                  setState(() {
                                                    _characteristicSubscriptions[
                                                        key] = true;
                                                    _showValueForCharacteristic[
                                                        e.uuid] = true;
                                                    _characteristicValues[
                                                            e.uuid] =
                                                        "Indications are enabled";
                                                  });
                                                });
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                child: GestureDetector(
                                                  onTap: isAutoSubscribedService
                                                      ? null // Disable tapping for auto-subscribed services
                                                      : () async {
                                                          final isCurrentlySubscribed =
                                                              _characteristicSubscriptions[
                                                                      key] ??
                                                                  false;
                                                          debugPrint(
                                                              "toggleSubscription: $key, currently subscribed: $isCurrentlySubscribed");

                                                          if (isCurrentlySubscribed) {
                                                            await EmBleOpcodes
                                                                .unsubscription(
                                                              deviceId: widget
                                                                  .deviceId,
                                                              service: service,
                                                              characteristic: e,
                                                            );
                                                          } else {
                                                            await EmBleOpcodes
                                                                .subscription(
                                                              deviceId: widget
                                                                  .deviceId,
                                                              service: service,
                                                              characteristic: e,
                                                            );
                                                          }

                                                          setState(() {
                                                            _characteristicSubscriptions[
                                                                    key] =
                                                                !isCurrentlySubscribed;
                                                          });

                                                          final subscribed =
                                                              isSubscribed(
                                                                  service.uuid,
                                                                  e.uuid);
                                                          final displayValue =
                                                              subscribed
                                                                  ? "Indications are enabled"
                                                                  : "Indications are disabled";

                                                          setState(() {
                                                            _showValueForCharacteristic[
                                                                e.uuid] = true;
                                                            _characteristicValues[
                                                                    e.uuid] =
                                                                displayValue;
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
                                                          (_characteristicSubscriptions[
                                                                      key] ??
                                                                  false)
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
                                                    // toggleSubscription(
                                                    //     service.uuid, e.uuid);

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
