import 'dart:async';
import 'package:emconnect/connected_device_interface/fwu_firmware_info_page.dart';
import 'package:emconnect/app_globals.dart';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/connected_device_interface/beacon_configuration.dart';
import 'package:emconnect/connected_device_interface/widgets/services_list_widget.dart';
import 'package:emconnect/data/uicolors.dart';

class LeDeviceServices extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const LeDeviceServices(this.deviceId, this.deviceName, {super.key});
  @override
  State<LeDeviceServices> createState() => _LeDeviceServices();
}

class _LeDeviceServices extends State<LeDeviceServices> {
  bool isConnected = false;
  int getComplete = 0;
  bool isFetchComplete = false;
  GlobalKey<FormState> valueFormKey = GlobalKey<FormState>();
  List<BleService> discoveredServices = [];
  final binaryCode = TextEditingController();
  bool showButtons = false;
  bool isConnecting = false;
  bool connectionFailed = false;
  bool hasBeaconTunerService = false;
  bool hasFirmwareUpdateService = false;
  bool servicesDiscovered = false;
  //late BeaconTunerService beaconTunerService;
  BeaconTunerService? beaconTunerService;

  late FirmwareUpdateService firmwareUpdateService;

  Future<void> subscribeBeaconTunerChar() async {
    debugPrint("Subscribing to Beacon Tuner Characteristic$beaconTunerService");
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

  
  
  Future<void> subscribeFirmwareUpdateChar() async {
    BleInputProperty bleInputProperty;
    List<CharacteristicProperty> properties =
        firmwareUpdateService.controlPointChar.properties;

    if (properties.contains(CharacteristicProperty.notify)) {
      bleInputProperty = BleInputProperty.notification;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      bleInputProperty = BleInputProperty.indication;
    } else {
      throw 'No notify or indicate property';
    }

    await UniversalBle.setNotifiable(
      widget.deviceId,
      firmwareUpdateService.service.uuid,
      firmwareUpdateService.controlPointChar.uuid,
      bleInputProperty,
    );
    setState(() {});
  }

  Future<List<BleService>> _discoverServices() async {
    var services = await UniversalBle.discoverServices(widget.deviceId);
    if (services.isNotEmpty) {
      servicesDiscovered = true;
    }
    setState(() {
      discoveredServices = services;
    });

    for (var service in discoveredServices) {
      if (service.uuid.toLowerCase() ==
          '81cf7a98-454d-11e8-adc0-fa7ae01bd428') {
        hasBeaconTunerService = true;
        beaconTunerService = BeaconTunerService();
        debugPrint("Discovered Beacon Tuner Service: $beaconTunerService");
        beaconTunerService!.service = service;
        beaconTunerService!.beaconTunerChar = service.characteristics[0];
        await subscribeBeaconTunerChar();
      } else if (service.uuid.toLowerCase() ==
          '81cfa888-454d-11e8-adc0-fa7ae01bd428') {
        hasFirmwareUpdateService = true;
        firmwareUpdateService = FirmwareUpdateService();
        firmwareUpdateService.service = service;
        firmwareUpdateService.controlPointChar = service.characteristics[0];
        firmwareUpdateService.dataChar = service.characteristics[1];
        await subscribeFirmwareUpdateChar();
      }
    }
    return discoveredServices;
  }

  
  
  
  void _handleConnectionChange(
    String deviceId,
    bool isConnected,
    String? error,
  ) async {
    setState(() {
      this.isConnected = isConnected;
    });

    // Auto Discover Services
    if (this.isConnected) {
      setState(() {
        isConnecting = false;
        connectionFailed = false;
      });
      addLog("ConnState", "Connected to device");
      await Future.delayed(Duration(milliseconds: 500));
      _discoverServices();
    } else if (isConnecting) {
      addLog("ConnState", "Connection failed");
      setState(() {
        connectionFailed = true;
      });
      connect();
    }
  }

  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    addLog("Received",
        value.map((b) => b.toRadixString(16).padLeft(2, '0')).join('-'));
  }

  Future<void> connect() async {
    addLog("ConnState", "Connecting to device");
    await UniversalBle.connect(
      widget.deviceId,
    );
  }

  @override
  void initState() {
    super.initState();
    UniversalBle.onConnectionChange = _handleConnectionChange;
    UniversalBle.onValueChange = _handleValueChange;
    isConnecting = true;
    connect();
  }

  @override
  void dispose() {
    super.dispose();

    // Deregister the call back
    UniversalBle.onConnectionChange = null;
    if (isConnected) UniversalBle.disconnect(widget.deviceId);
  }

  Future<void> _showDialog(BuildContext context, String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(color: Color.fromRGBO(45, 127, 224, 1)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void resetInFwUpdaterMode() async {
    Uint8List opcode = Uint8List.fromList([0x01, 0x04]);
    addLog("Sent",
        opcode.map((b) => b.toRadixString(16).padLeft(2, '0')).join('-'));

    await UniversalBle.writeValue(
      widget.deviceId,
      beaconTunerService!.service.uuid,
      beaconTunerService!.beaconTunerChar.uuid,
      opcode,
      BleOutputProperty.withResponse,
    );
  }

//Connection page
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     resizeToAvoidBottomInset: false,
  //     backgroundColor: UIColors.emGrey,
  //     appBar: AppBar(
  //       scrolledUnderElevation: 0,
  //       backgroundColor: UIColors.emNotWhite,
  //       title: Text(
  //         "${widget.deviceName}\n${widget.deviceId}",
  //         textAlign: TextAlign.center,
  //         style: TextStyle(
  //           fontSize: UIFont.appBarFontSize,
  //           fontWeight: FontWeight.bold,
  //           color: UIColors.emNearBlack,
  //         ),
  //       ),
  //       centerTitle: true,
  //       leading: IconButton(
  //         icon: Icon(Icons.chevron_left, color: UIColors.emNearBlack),
  //         onPressed: () {
  //           // Dispose the activity
  //           Navigator.pop(context);
  //         },
  //       ),
  //       actions: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Icon(
  //             isConnected
  //                 ? Icons.bluetooth_connected
  //                 : Icons.bluetooth_disabled,
  //             color: isConnected ? UIColors.emGreen : UIColors.emRed,
  //             size: 20,
  //           ),
  //         ),
  //       ],
  //     ),
  //     body: Column(
  //       children: [
  //         Expanded(
  //           child: Padding(
  //             padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
  //             child: Column(
  //               children: [
  //                 (isConnecting && !connectionFailed)
  //                     ? const Center(
  //                         child: Column(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             SizedBox(
  //                               height: 10,
  //                             ),
  //                             CircularProgressIndicator(),
  //                             SizedBox(height: 20),
  //                             Text("Connecting to device..."),
  //                           ],
  //                         ),
  //                       )
  //                     : connectionFailed
  //                         ? const Center(
  //                             child: Column(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 SizedBox(
  //                                   height: 10,
  //                                 ),
  //                                 CircularProgressIndicator(),
  //                                 SizedBox(height: 20),
  //                                 Text(
  //                                     "Connection failed, retrying to connect..."),
  //                               ],
  //                             ),
  //                           )
  //                         : ServicesListWidget(
  //                           deviceId: widget.deviceId,
  //                             discoveredServices: discoveredServices,
  //                           ),
  //               ],
  //             ),
  //           ),
  //         ),

  //         //! @@ Button for configuration
  //         Padding(
  //           padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
  //           child: SizedBox(
  //             width: double.infinity, // Makes the button take the full width
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(5),
  //                 ),
  //                 backgroundColor: UIColors.emActionBlue,
  //               ),
  //               onPressed: hasBeaconTunerService
  //                   ? () {
  //                       Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                               builder: (context) => BeaconConfiguration(
  //                                   deviceId: widget.deviceId,
  //                                   deviceName: widget.deviceName,
  //                                   beaconTunerService: beaconTunerService)));
  //                     }
  //                   : null,
  //               child: Text(
  //                 'Configuration',
  //                 style: TextStyle(
  //                   color: UIColors.emNotWhite,
  //                   fontSize: UIFont.titleFontSize,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),

  //         //! @@ Button for reset in firmware updater mode
  //         Padding(
  //           padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
  //           child: SizedBox(
  //             width: double.infinity, // Makes the button take the full width
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(5),
  //                 ),
  //                 backgroundColor: UIColors.emActionBlue,
  //               ),
  //               onPressed: discoveredServices.isEmpty
  //                   ? null
  //                   : !hasFirmwareUpdateService
  //                       ? () {
  //                           resetInFwUpdaterMode();
  //                           _showDialog(context, "Info",
  //                                   "Rebooted to Firmware Update mode.\nPlease connect again to the device EMXX_FWU")
  //                               .then((_) {
  //                             Navigator.pop(context);
  //                           });
  //                         }
  //                       : null,
  //               child: Text(
  //                 'Reset in Firmware Updater Mode',
  //                 style: TextStyle(
  //                   color: UIColors.emNotWhite,
  //                   fontSize: UIFont.titleFontSize,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),

  //         //! @@ Button for firmware update
  //         Padding(
  //           padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
  //           child: SizedBox(
  //             width: double.infinity, // Makes the button take the full width
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(5),
  //                 ),
  //                 backgroundColor: UIColors.emActionBlue,
  //               ),
  //               onPressed: hasFirmwareUpdateService
  //                   ? () async {
  //                       Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                               builder: (context) => FwuFirmwareInfoPage(
  //                                   deviceId: widget.deviceId,
  //                                   deviceName: widget.deviceName,
  //                                   firmwareUpdateService:
  //                                       firmwareUpdateService)));
  //                     }
  //                   : null,
  //               child: Text(
  //                 'Firmware Update',
  //                 style: TextStyle(
  //                   color: UIColors.emNotWhite,
  //                   fontSize: UIFont.titleFontSize,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final availableHeight = screenHeight -
      kToolbarHeight - // AppBar height
      MediaQuery.of(context).padding.top - // Status bar
      180; // Estimated height of buttons and paddings

  return Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: UIColors.emGrey,
    appBar: AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: UIColors.emNotWhite,
      title: Text(
        "${widget.deviceName}\n${widget.deviceId}",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: UIFont.appBarFontSize,
          fontWeight: FontWeight.bold,
          color: UIColors.emNearBlack,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.chevron_left, color: UIColors.emNearBlack),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? UIColors.emGreen : UIColors.emRed,
            size: 20,
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: availableHeight,
              child: isConnecting && !connectionFailed
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 10),
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text("Connecting to device..."),
                        ],
                      ),
                    )
                  : connectionFailed
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text("Connection failed, retrying to connect..."),
                            ],
                          ),
                        )
                      : ServicesListWidget(
                          deviceId: widget.deviceId,
                          discoveredServices: discoveredServices,
                          scrollable: true,
                        ),
            ),

            const SizedBox(height: 10),

            _buildButton("Configuration", hasBeaconTunerService, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BeaconConfiguration(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: beaconTunerService!,
                  ),
                ),
              );
            }),

            _buildButton(
              "Reset in Firmware Updater Mode",
              discoveredServices.isNotEmpty && !hasFirmwareUpdateService,
              () {
                resetInFwUpdaterMode();
                _showDialog(context, "Info",
                    "Rebooted to Firmware Update mode.\nPlease connect again to the device EMXX_FWU")
                    .then((_) => Navigator.pop(context));
              },
            ),

            _buildButton("Firmware Update", hasFirmwareUpdateService, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FwuFirmwareInfoPage(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    firmwareUpdateService: firmwareUpdateService,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
Widget _buildButton(String label, bool enabled, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          backgroundColor: UIColors.emActionBlue,
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: TextStyle(
            color: UIColors.emNotWhite,
            fontSize: UIFont.titleFontSize,
          ),
        ),
      ),
    ),
  );
}



}
