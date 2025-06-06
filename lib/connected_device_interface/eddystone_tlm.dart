import 'dart:io';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:path_provider/path_provider.dart';
import 'package:emconnect/data/uicolors.dart';

String Batteryvoltage = '';
String Temperature = '';
String PDUcounter = '';
String Time = '';
Uint8List? response;

class EddystoneTlm extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  final BeaconTunerService beaconTunerService;
  const EddystoneTlm(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.beaconTunerService});

  @override
  State<EddystoneTlm> createState() => _EddystoneTlm();
}

class _EddystoneTlm extends State<EddystoneTlm> {
  String formattedText = "";
  List<Map<String, dynamic>> rows = [];
  int getComplete = 0;
  bool isFetchComplete = false;
  @override
  void initState() {
    super.initState();

    UniversalBle.onValueChange = _handleValueChange;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      readBeacon();
    });
  }

  @override
  void dispose() {
    super.dispose();

    UniversalBle.onValueChange = null;
  }

  final List<String> _logs = [];
  void addLog(String type, dynamic data) async {
    // Get the current timestamp and manually format it as YYYY-MM-DD HH:mm:ss
    DateTime now = DateTime.now();
    String timestamp =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    // Log entry with just the formatted timestamp
    String logEntry = '[$timestamp]:$type: ${data.toString()}\n';

    _logs.add(logEntry);

    await _writeLogToFile(logEntry);
  }

  Future<void> _writeLogToFile(String logEntry) async {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/logs.txt');
    await logFile.writeAsString(logEntry, mode: FileMode.append);
  }

  //Method to read beacon values
  // Future readBeacon() async {
  //   Uint8List deviceInfoopcode = Uint8List.fromList([0x3A]);

  //   try {
  //     BleService selService = widget.beaconTunerService.service;
  //     BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

  //     debugPrint("into eddystone uuid get\n");

  //     await UniversalBle.writeValue(
  //       widget.deviceId,
  //       selService.uuid,
  //       selChar.uuid,
  //       deviceInfoopcode,
  //       BleOutputProperty.withResponse,
  //     );
  //     await Future.delayed(const Duration(milliseconds: 2000));
  //   } catch (e) {
  //     print("Error writing advertising settings: $e");
  //   }
  // }

  Future readBeacon() async {
  try {
    await EmBleOps.serialize(
      deviceId: widget.deviceId,
      service: widget.beaconTunerService.service,
      characteristic: widget.beaconTunerService.beaconTunerChar,
      opcodes: [0x3A],
    );
  } catch (e) {
    print("Error in readIBeaconConfig: $e");
  }
}

  
  
  bool check = false; // Flag to track dialog state

//Method to extract byte values for all beacon types from response
  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    String hexString =
        value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('-');

    String s = String.fromCharCodes(value);

    print('_handleValueChange $deviceId, $characteristicId, $s');
    print('Received hex data: $hexString');
    addLog("Received", hexString);

    if (value.length > 3) {
      if (value.length >= 15) {
        if (value[1] == 0x3A) {
          print("Entered Eddystone-TLM");

          // Decode Battery Voltage (2 bytes, UINT16, big endian)
          int batteryVoltage = (value[3] << 8) | value[4];

          // Decode Temperature (2 bytes, INT16, big endian, divided by 256)
          int tempRaw = (value[5] << 8) | value[6];
          double temperature;
          if (tempRaw == 0x8000) {
            temperature = double.nan; // Not supported
          } else {
            temperature = tempRaw / 256.0;
          }

          // Decode PDU Counter (4 bytes, UINT32, big endian)
          int pduCounter =
              (value[7] << 24) | (value[8] << 16) | (value[9] << 8) | value[10];

          // Decode Time (4 bytes, UINT32, big endian, 0.1s units)
          int timeSinceResetRaw = (value[11] << 24) |
              (value[12] << 16) |
              (value[13] << 8) |
              value[14];
          double timeSinceReset =
              timeSinceResetRaw / 10.0; // convert to seconds

          setState(() {
            Batteryvoltage = '$batteryVoltage mV';
            Temperature =
                temperature.isNaN ? 'Not supported' : '$temperature °C';
            PDUcounter = '$pduCounter';
            Time = '$timeSinceReset seconds';
            getComplete += 1;
            check = true;
          });
        }
      }

      setState(() async {});
    }
    isFetchComplete = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emGrey,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          "Eddystone-TLM Info",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: !check
          ? Center(
              child: CircularProgressIndicator(), // Show loader while loading
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // Card for Product ID
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: UIColors.emNotWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.emDarkGrey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Battery Voltage",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                        Spacer(),
                        Text(
                          "Batteryvoltage",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                      ],
                    ),
                  ),
                  // Card for Firmware Version Major
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: UIColors.emNotWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.emDarkGrey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Temperature",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                        Spacer(),
                        Text(
                          "Temperature",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                      ],
                    ),
                  ),
                  // Card for Firmware Version Minor
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: UIColors.emNotWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.emDarkGrey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "PDU Counter",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                        Spacer(),
                        Text(
                          "PDUcounter",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                      ],
                    ),
                  ),
                  // Card for Hardware Version
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: UIColors.emNotWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.emDarkGrey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Time",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                        Spacer(),
                        Text(
                          "Time",
                          style: TextStyle(
                              fontSize: 15, color: UIColors.emDarkGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

// Function to convert hex string to Uint8List
  Uint8List hexStringToBytes(String hex) {
    hex = hex.replaceAll(
        RegExp(r'[^0-9A-Fa-f]'), ''); // Remove non-hexadecimal characters
    if (hex.length % 2 != 0) {
      hex = "0$hex"; // Pad with a leading 0 if the length is odd
    }
    return Uint8List.fromList(List.generate(hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));
  }
}
