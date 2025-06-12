library;

import 'package:emconnect/connected_device_interface/alt_beacon.dart';
import 'package:emconnect/connected_device_interface/device_status.dart';
import 'package:emconnect/connected_device_interface/eddystone_tlm.dart';
import 'package:emconnect/connected_device_interface/eddystone_uid.dart';
import 'package:emconnect/connected_device_interface/eddystone_url.dart';
import 'package:emconnect/connected_device_interface/manufacturer_specific_data.dart';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/app_globals.dart';
import 'package:emconnect/connected_device_interface/ibeacon_config.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

bool isEddystoneTlmAvailable = false;
bool isEddystoneTlmSelected = false;
bool showCteCard = true;
String AoA_Enable = '';
String AoA_Interval = '';
String AoA_CTE_length = '';
String AoA_CTE_count = '';
int interval = 0;
int cteLength = 0;
int cteCount = 0;
int blockSize = 0;
bool isOn = true;
bool ibeacon = true;
String uuid = '';
int? majorId;
int? minorId;
String namespaceID = '';
String instanceID = '';
int? prefix;
String url = "";
String displayurl = "";
int? suffix;
int packetType = 0;
int? interval1;
int? txPowerLevel;
Uint8List? response;
String mfgID = '';
String beaconID = '';
String mfgData = '';
int? selectedRadioIndex;
String manufacturerId = "";
String userData = "";
String dynamicdata = "";
String _productId = "";
String _fwVersionMajor = "";
String _fwVersionMinor = "";
String _hwVersion = "";
String _batteryVoltage = "";
int? advPacketType;

class BeaconConfiguration extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final BeaconTunerService beaconTunerService;

  const BeaconConfiguration(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.beaconTunerService});

  @override
  State<StatefulWidget> createState() => _BeaconConfigurationState();
}

class _BeaconConfigurationState extends State<BeaconConfiguration> {
  final _formKey = GlobalKey<FormState>();
  bool cteEnabled = false;
  String? calculatedIntervalDisplay;

  final TextEditingController _CTEintervalController = TextEditingController();
  final TextEditingController _CTElengthController = TextEditingController();
  final TextEditingController _CTEcountController = TextEditingController();

  String? errortextInterval;
  String? errortextTxpower;
  bool isFetchComplete = false;

  @override
  void initState() {
    super.initState();

    UniversalBle.onValueChange = _handleValueChange;
    readBeacon();
  }

  @override
  void dispose() {
    super.dispose();

    UniversalBle.onValueChange = null;
  }

//Method to read beacon values
  Future readBeacon() async {
    Uint8List opcode = Uint8List.fromList([0x30]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      for (int i = 0; i < 9; i++) {
        isFetchComplete = false;
        if (i == 0) {
          debugPrint("into adv settings\n");
          opcode = Uint8List.fromList([0x21]);
        } else if (i == 1) {
          debugPrint("into ibeacon get\n");
          opcode = Uint8List.fromList([0x30]);
        } else if (i == 2) {
          debugPrint("into substitution get\n");
          opcode = Uint8List.fromList([0x60]);
        } else if (i == 3) {
          debugPrint("into eddystone-url get\n");
          opcode = Uint8List.fromList([0x34]);
        } else if (i == 4) {
          debugPrint("into altbeacon get\n");
          opcode = Uint8List.fromList([0x36]);
        } else if (i == 5) {
          debugPrint("into Manufacturer Specific Data\n");
          opcode = Uint8List.fromList([0x38]);
        } else if (i == 6) {
          debugPrint("into Device status\n");
          opcode = Uint8List.fromList([0x02]);
        } else if (i == 7) {
          debugPrint("into Eddystone TLM\n");
          opcode = Uint8List.fromList([0x3A]);
        } else if (i == 8) {
          debugPrint("into AoA \n");
          opcode = Uint8List.fromList([0x70]);
        }

        await UniversalBle.writeValue(
          widget.deviceId,
          selService.uuid,
          selChar.uuid,
          opcode,
          BleOutputProperty.withResponse,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
  }

  bool check = false; // Flag to track dialog state

//Method to extract byte values for all beacon types from response
  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    String hexString =
        value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('-');

    print('Received hex data: $hexString');
    addLog("Received", hexString);

    if (value.length > 3) {
      if (value[1] == 0x21) {
        setState(() {
          selectedRadioIndex = value[3];
          selectedRadioIndex = _mapAdvPacketTypeToRadioIndex(value[3]);
          interval1 = (value[5] << 8) | value[4];
          interval1 = (interval1! * 0.625).round();
          txPowerLevel = value[6] > 127 ? (value[6] - 256) : value[6];
        });
      }
      if (value[1] == 0x02) {
        _productId = value
            .sublist(3, 4) // Extract only the 3rd byte
            .map((byte) =>
                byte.toRadixString(16).padLeft(2, '0')) // Convert to hex
            .join(); // Join into a string

        _fwVersionMajor = value
            .sublist(4, 5)
            .map((byte) =>
                byte.toRadixString(16).padLeft(2, '0')) // Convert to hex
            .join();

        _fwVersionMinor = value
            .sublist(5, 6)
            .map((byte) =>
                byte.toRadixString(16).padLeft(2, '0')) // Convert to hex
            .join(); // Join into a string

        _hwVersion = value
            .sublist(6, 7)
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();

        String vBatString = value
            .sublist(7, 8)
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();

        // Convert the hex string to a numeric value and multiply by 0.1
        double batteryVoltageValue = int.parse(vBatString, radix: 16) * 0.1;
        _batteryVoltage = batteryVoltageValue.toStringAsFixed(1);
      }
      if (value[1] == 0x60) {
        print("entered into substituion layer");
        setState(() {
          sharedText = value
              .sublist(3)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
        });
      }

      if (value[1] == 0x32) {
        print("entered eddystone UID");
        setState(() {
          namespaceID = value
              .sublist(3, 13)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          instanceID = value
              .sublist(13, 19) // From 4th to 19th byte
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
        });
      }

      if (value[1] == 0x30) {
        print("ibeacon");

        setState(() {
          uuid = value
              .sublist(3, 19)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          uuid = '${uuid.substring(0, 8)}-'
              '${uuid.substring(8, 12)}-'
              '${uuid.substring(12, 16)}-'
              '${uuid.substring(16, 20)}-'
              '${uuid.substring(20)}';

          ByteData byteData = ByteData.sublistView(value);

          majorId = byteData.getUint16(19, Endian.big); // Bytes 19-20
          minorId = byteData.getUint16(21, Endian.big);
        });
      }
      if (value[1] == 0x34) {
        print("entered eddystone url");
        setState(() {
          prefix = value[3];
          print("prefix : $prefix");
          List<int> urlBytes = [];

          for (int i = 4; i < value.length; i++) {
            int byte = value[i];

            // Check for suffix termination condition
            if (byte >= 0x00 && byte < 0x0d) {
              suffix = byte;
              displayurl = String.fromCharCodes(urlBytes);
              // Store suffix
              break;
            }
            // Add byte to URL bytes list
            urlBytes.add(byte);
          }
        });
      }

      if (value[1] == 0x36) {
        print("entered altbeacon");
        setState(() {
          mfgID = value
              .sublist(3, 5)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          beaconID = value
              .sublist(5, 25)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();

          mfgData = value
              .sublist(25, 26)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
        });
        check = true;
      }

      if (value[1] == 0x38) {
        print("Entered Manufacturer Specific Data");
        setState(() {
          manufacturerId = value
              .sublist(3, 5)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          userData = value
              .sublist(5)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
        });
        print('user data: $userData');
        print('mfid: $manufacturerId');
        print('UserData: $userData');
        check = true;
      }
      if (value[1] == 0x70) {
        print("entered AoA");
        debugPrint("CTE opcode received");
        setState(() {
          showCteCard = value.length > 3 && value[3] == 0x01;
          showCteCard = true;

          ByteData aoaData = ByteData.sublistView(value);

          int enable = aoaData.getUint8(3); // Byte 3
          int interval = aoaData.getUint16(4, Endian.little); // Bytes 4-5
          int cteLength = aoaData.getUint8(6); // Byte 6
          int cteCount = aoaData.getUint8(7); // Byte 7

          // Apply default fallbacks for invalid values (0)
          interval =
              (interval < 6 || interval > 65535) ? 80 : interval; // 80 = 100ms
          // interval = (interval / 1.25).round();
          double intervalMs = (interval * 1.25);

          cteLength = (cteLength < 2 || cteLength > 20) ? 10 : cteLength;
          cteCount = (cteCount < 1 || cteCount > 16) ? 1 : cteCount;

          setState(() {
            AoA_Enable = enable.toString();
            AoA_Interval = interval.toString();
            AoA_CTE_length = cteLength.toString();
            AoA_CTE_count = cteCount.toString();

            cteEnabled = enable == 1;
          });

          print("Enable: $AoA_Enable");
          print("Interval: $AoA_Interval");
          print("CTE Length: $AoA_CTE_length");
          print("CTE Count: $AoA_CTE_count");

          _CTEintervalController.text = interval.toString();
          _CTElengthController.text = cteLength.toString();
          _CTEcountController.text = cteCount.toString();
          calculatedIntervalDisplay =
              'Equivalent Interval Time: ${intervalMs.toStringAsFixed(2)} ms';
        });
      } else {
        setState(() {
          showCteCard = false;
        });
      }

      if (value[1] == 0x3A) {
        print("Entered Eddystone-TLM");
        setState(() {
          isEddystoneTlmAvailable = true;
          isEddystoneTlmSelected =
              value[3] == 0x01; // Select only if value is 0x01
        });

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
        double timeSinceReset = timeSinceResetRaw / 10.0; // convert to seconds

        setState(() {
          Batteryvoltage = '$batteryVoltage mV';
          Temperature = temperature.isNaN ? 'Not supported' : '$temperature °C';
          PDUcounter = '$pduCounter';
          Time = '$timeSinceReset seconds';
          check = true;
        });
      }
      if (!value.contains(0x3A)) {
        setState(() {
          isEddystoneTlmAvailable = false;
          isEddystoneTlmSelected = false;
        });
      }

      setState(() async {});
    }
    isFetchComplete = true;
  }

  int _mapAdvPacketTypeToRadioIndex(int type) {
    switch (type) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 5:
        return 3; // Eddystone-TLM
      case 3:
        return 4; // AltBeacon
      case 4:
        return 5; // Manufacturer Specific Data
      default:
        return -1;
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: UIColors.emNotWhite,
          title: Text(title, style: TextStyle(color: UIColors.emNearBlack)),
          content: Text(message, style: TextStyle(color: UIColors.emNearBlack)),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(color: UIColors.emActionBlue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Uint8List createAdvertisingSettings(
      Uint8List opcode, int packetType, interval, int txPowerLevel) {
    if (interval < 20 || interval > 10240) {
      throw Exception(
          "Invalid advertising interval. Accepted values: 20 – 10240.");
    }
    interval = (interval * 1.6).round();
    debugPrint("@@txpowerLevel1: $txPowerLevel ");
    if (txPowerLevel < -60 || txPowerLevel > 10) {
      throw Exception(
          "Invalid Tx Power Level. Accepted values: -60 to 10 dBm.");
    }

    return Uint8List.fromList([
      opcode[0],
      packetType, // Advertising Packet Type
      interval & 0xFF, // Lower byte of interval
      (interval >> 8) & 0xFF, // Upper byte of interval
      txPowerLevel, // Tx Power Level
    ]);
  }

  void setAdvertisingSettings(
      int packetType, int interval, int txPowerLevel) async {
    Uint8List opcode = Uint8List.fromList([0x22]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;
      Uint8List advertisingSettings = createAdvertisingSettings(
          opcode, advPacketType!, interval, txPowerLevel);

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        advertisingSettings,
        BleOutputProperty.withResponse,
      );

      setState(() {
        response = advertisingSettings;
      });

      print(
          "Advertising Settings data written to device: $advertisingSettings");
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
  }

// // Radio button widget
  Widget _buildRadioRow(String option, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedRadioIndex = index;
          packetType = index;
          _handleRadioChange(index); // Open the respective page
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              option,
              style: TextStyle(
                color: UIColors.emNearBlack,
                fontWeight: (option == 'Eddystone-UID' ||
                        option == 'Eddystone-URL' ||
                        option == 'iBeacon' ||
                        option == 'AltBeacon' ||
                        option == 'Manufacturer Specific Data' ||
                        option == 'Eddystone-TLM')
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Radio<int>(
            value: index,
            groupValue: selectedRadioIndex,

            activeColor: UIColors.emActionBlue, // Set the active color to blue
            onChanged: (int? value) {
              setState(() {
                selectedRadioIndex = value!;
                packetType = value;
                _handleRadioChange(value);
              });
            },

            focusColor: UIColors.emActionBlue, // Add focus color
            hoverColor: UIColors.emActionBlue, // Add hover color
            visualDensity:
                VisualDensity(vertical: -3.0), // Adjust vertical spacing
          ),
        ],
      ),
    );
  }

//Configuration page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emGrey,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Row(
          mainAxisSize: MainAxisSize
              .min, // Ensure the Row doesn't take up all available space
          children: [
            Text(
              "EM Beacon Tuner Configuration",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                !check
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text("Fetching configuration from device..."),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            width: double
                                .infinity, // Set the desired width for the button
                            margin: const EdgeInsets.only(
                                top: 0.0, bottom: 8.0), // Add spacing
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                backgroundColor: UIColors.emNotWhite,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DeviceStatus(
                                          productId: _productId,
                                          fwVersionMajor: _fwVersionMajor,
                                          fwVersionMinor: _fwVersionMinor,
                                          hwVersion: _hwVersion,
                                          batteryVoltage: _batteryVoltage)),
                                );
                              },
                              child: Text(
                                'Read Device Status',
                                style: TextStyle(
                                    color: UIColors.emNearBlack, fontSize: 15),
                              ),
                            ),
                          ),
                          // Toggle Switch Inside White Textbox
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: UIColors.emNotWhite,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: UIColors.emGrey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Beaconing State',
                                  style: TextStyle(color: UIColors.emNearBlack),
                                ),
                                Spacer(),
                                Switch(
                                  value: isOn,
                                  activeColor: UIColors.emNotWhite,

                                  activeTrackColor: UIColors.emActionBlue,
                                  inactiveThumbColor: UIColors
                                      .emNotWhite, // Thumb color when OFF
                                  inactiveTrackColor: UIColors.emNotWhite,

                                  onChanged: (value) {
                                    setState(() {
                                      isOn = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              Text('Interval (20 to 10240 ms)',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: UIColors.emDarkGrey)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(10),
                            child: TextFormField(
                              style: TextStyle(fontSize: 15),
                              onTapOutside: (event) =>
                                  FocusManager.instance.primaryFocus?.unfocus,
                              inputFormatters: _interval,
                              initialValue: interval1!.toString(),
                              decoration: InputDecoration(
                                isDense: true,
                                errorText: errortextInterval,
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 5, 10, 5),
                                fillColor: UIColors.emNotWhite,
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                int? intervalValue = int.tryParse(value ?? '');
                                if (intervalValue == null ||
                                    intervalValue < 20 ||
                                    intervalValue > 10240) {
                                  return 'Enter a valid interval (20 to 10240 ms).';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                int? enteredValue = int.tryParse(value) ?? 20;
                                setState(() {
                                  if (enteredValue > 10240) {
                                    errortextInterval =
                                        'Enter a valid interval (20 to 10240 ms). ';
                                  } else if (enteredValue < 20) {
                                    errortextInterval =
                                        'Enter a valid interval (20 to 10240 ms). ';
                                  } else {
                                    errortextInterval = null;
                                    interval1 = enteredValue;
                                  }
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Text('TX Power Level (-60 to +10 dBm)',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: UIColors.emDarkGrey)),
                            ],
                          ),
                          SizedBox(height: 10),

                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(10),
                            child: TextFormField(
                              style: TextStyle(fontSize: 15),
                              onTapOutside: (event) =>
                                  FocusManager.instance.primaryFocus?.unfocus,
                              inputFormatters: _txpowerlevel,
                              initialValue: txPowerLevel.toString(),
                              decoration: InputDecoration(
                                isDense: true,
                                errorText: errortextTxpower,
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 5, 10, 5),
                                fillColor: UIColors.emNotWhite,
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                int? txPowerValue = int.tryParse(value ?? '');
                                if (txPowerValue == null ||
                                    txPowerValue < -60 ||
                                    txPowerValue > 10) {
                                  return 'Please enter a valid TX power level (-60 to 10 dBm).';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                int? txPowerValue = int.tryParse(value);
                                setState(() {
                                  if (txPowerValue! > 10) {
                                    errortextTxpower =
                                        'Enter a valid txpower (-60 to 10 dBm). ';
                                  } else if (txPowerValue < -60) {
                                    errortextTxpower =
                                        'Enter a valid txpower (-60 to 10 dBm). ';
                                  } else {
                                    errortextTxpower = null;
                                    txPowerLevel = txPowerValue;
                                  }
                                });
                                if (txPowerValue != null) {
                                  txPowerLevel = txPowerValue;
                                  debugPrint('txPowerlevel: $txPowerLevel');
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 10),

                          SizedBox(height: 20),
                          Card(
                            elevation: 2.0,
                            color: UIColors.emNotWhite,
                            margin: EdgeInsets.all(0),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Advertising Packet',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    height: 1.0,
                                    color: UIColors.emGrey.withOpacity(0.5),
                                  ),
                                  _buildRadioRow('iBeacon', 0),
                                  _buildRadioRow('Eddystone-UID', 1),
                                  _buildRadioRow('Eddystone-URL', 2),
                                  _buildRadioRow(
                                    'Eddystone-TLM',
                                    3,
                                  ),
                                  _buildRadioRow('AltBeacon', 4),
                                  _buildRadioRow(
                                      'Manufacturer Specific Data', 5),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          if (showCteCard)
                            SizedBox(
                              height: cteEnabled
                                  ? 350
                                  : 70, // Adjust collapsed height as needed
                              child: Card(
                                elevation: 2.0,
                                color: UIColors.emNotWhite,
                                margin: EdgeInsets.all(0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // Ensure alignment starts from left
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'CTE Enable', // Change text as needed
                                            style: TextStyle(
                                                color: UIColors.emNearBlack),
                                          ),
                                          Spacer(), // This creates the space between the text and the toggle
                                          Switch(
                                            value: cteEnabled,
                                            activeColor: UIColors.emNotWhite,
                                            activeTrackColor:
                                                Color.fromRGBO(45, 127, 224, 1),
                                            inactiveThumbColor:
                                                UIColors.emNotWhite,
                                            inactiveTrackColor: Color.fromARGB(
                                                247, 247, 244, 244),
                                            onChanged: (val) {
                                              setState(() {
                                                cteEnabled = val;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      if (cteEnabled)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Interval Units (6 to 65535)',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: UIColors.emDarkGrey,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Material(
                                              elevation: 2,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: TextFormField(
                                                controller:
                                                    _CTEintervalController,
                                                style: TextStyle(fontSize: 15),
                                                inputFormatters:
                                                    _intervalInputFormatters,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.fromLTRB(
                                                          10, 5, 10, 5),
                                                  fillColor:
                                                      UIColors.emNotWhite,
                                                  filled: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a value';
                                                  }
                                                  if (!RegExp(r'^\d+$')
                                                      .hasMatch(value)) {
                                                    return 'Only numbers are allowed';
                                                  }
                                                  final intValue =
                                                      int.tryParse(value);
                                                  if (intValue == null ||
                                                      intValue < 6 ||
                                                      intValue > 65535) {
                                                    return 'Interval must be between 6 and 65535';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  AoA_Interval = value;
                                                  _formKey.currentState
                                                      ?.validate();

                                                  final intValue =
                                                      int.tryParse(value);

                                                  if (intValue != null &&
                                                      intValue >= 6 &&
                                                      intValue <= 65535) {
                                                    final calculated =
                                                        (intValue * 1.25)
                                                            .toStringAsFixed(2);
                                                    setState(() {
                                                      calculatedIntervalDisplay =
                                                          'Equivalent Interval Time: $calculated ms ';
                                                    });
                                                  } else {
                                                    setState(() {
                                                      calculatedIntervalDisplay =
                                                          null;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            if (calculatedIntervalDisplay !=
                                                null)
                                              Text(
                                                calculatedIntervalDisplay!,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        UIColors.emActionBlue),
                                              ),

                                            SizedBox(height: 16),
                                            // CTE Length Field
                                            Row(
                                              children: [
                                                Text(
                                                  'CTE Length (2 to 20)',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    //color:UIColors.emNearBlack
                                                    color: UIColors.emDarkGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),

                                            Material(
                                              elevation: 2,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: TextFormField(
                                                controller:
                                                    _CTElengthController,
                                                style: TextStyle(fontSize: 15),
                                                inputFormatters:
                                                    _ctelengthInputFormatters,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.fromLTRB(
                                                          10, 5, 10, 5),
                                                  fillColor:
                                                      UIColors.emNotWhite,
                                                  filled: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a value';
                                                  }
                                                  if (!RegExp(r'^\d+$')
                                                      .hasMatch(value)) {
                                                    return 'Only numbers are allowed';
                                                  }
                                                  final intValue =
                                                      int.tryParse(value);
                                                  if (intValue == null ||
                                                      intValue < 2 ||
                                                      intValue > 20) {
                                                    return 'CTE Length must be between 2 and 20';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  AoA_CTE_length = value;
                                                  _formKey.currentState
                                                      ?.validate(); // Re-validate on every change
                                                },
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            // CTE Count Field
                                            Row(
                                              children: [
                                                Text(
                                                  'CTE Count (1 to 16)',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    //color: UIColors.emGrey,
                                                    color:UIColors.emDarkGrey
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),

                                            Material(
                                              elevation: 2,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: TextFormField(
                                                controller: _CTEcountController,
                                                style: TextStyle(fontSize: 15),
                                                inputFormatters:
                                                    _ctecountInputFormatters,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.fromLTRB(
                                                          10, 5, 10, 5),
                                                  fillColor:
                                                      UIColors.emNotWhite,
                                                  filled: true,
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a value';
                                                  }
                                                  if (!RegExp(r'^\d+$')
                                                      .hasMatch(value)) {
                                                    return 'Only numbers are allowed';
                                                  }
                                                  final intValue =
                                                      int.tryParse(value);
                                                  if (intValue == null ||
                                                      intValue < 1 ||
                                                      intValue > 16) {
                                                    return 'CTE Count must be between 1 and 16';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  AoA_CTE_count = value;
                                                  _formKey.currentState
                                                      ?.validate(); // Re-validate on every change
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
            16.0, 0, 16.0, 40), // Adjust bottom padding

        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: Color.fromRGBO(45, 127, 224, 1),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (txPowerLevel! > 6) {
                      _showHighRfOutputDialog();
                    } else {
                      _applySettings();
                      String enableHex = cteEnabled ? "01" : "00";

                      setCteEnable(enableHex, AoA_Interval, AoA_CTE_length,
                          AoA_CTE_count);
                    }
                  }
                },
                child: Text(
                  'Apply',
                  style: TextStyle(
                      color: Color.fromRGBO(250, 247, 243, 1), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void setCteEnable(
      String enableHex, // 1 byte
      String intervalHex, // 2 bytes
      String cteLengthHex, // 1 byte
      String cteCountHex // 1 byte
      ) async {
    Uint8List opcode = Uint8List.fromList([0x71]); // Example opcode for AOA

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      Uint8List aoaSettings = createCteSettings(
        opcode,
        enableHex,
        intervalHex,
        cteLengthHex,
        cteCountHex,
      );

      addLog(
        "Sent",
        aoaSettings.map((b) => b.toRadixString(16).padLeft(2, '0')).join('-'),
      );

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        aoaSettings,
        BleOutputProperty.withResponse,
      );

      setState(() {
        response = aoaSettings;
      });
    } catch (e) {
      print("Error writing AOA settings: $e");
    }
  }

  Uint8List createCteSettings(Uint8List opcode, String enableHex,
      String intervalHex, String cteLengthHex, String cteCountHex) {
    // Step 1: Convert hex string to decimal integers
    int enable = int.parse(enableHex); // 1 byte
    interval = int.parse(intervalHex); // 2 bytes
    int cteLength = int.parse(cteLengthHex); // 1 byte
    int cteCount = int.parse(cteCountHex); // 1 byte

    // Step 2: Split 2-byte interval into 2 bytes (Little Endian format)
    Uint8List intervalBytes = Uint8List(2);
    intervalBytes[0] = interval & 0xFF; // LSB
    intervalBytes[1] = (interval >> 8) & 0xFF; // MSB

    return Uint8List.fromList([
      opcode[0],
      enable,
      intervalBytes[0],
      intervalBytes[1],
      cteLength,
      cteCount
    ]);
  }

  // Success Dialog Method after applying configuration
  void _applySettings() {
    try {
      if (isOn) {
        // Enable advertising (Opcode: 0x20, Enable response: 20-01)
        _setAdvertisingState(true);
      } else {
        // Disable advertising (Opcode: 0x20, Disable response: 20-00)
        _setAdvertisingState(false);
      }

      setAdvertisingSettings(selectedRadioIndex!, interval1!, txPowerLevel!);
      _showDialog(
          context, "Success", "Changes have been applied successfully.");
    } catch (e) {
      _showDialog(
          context, "Error", "Changes could not be applied: ${e.toString()}");
    }
  }

  void _setAdvertisingState(bool enable) async {
    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      // Create advertising command
      Uint8List opcode = enable
          ? Uint8List.fromList([0x20, 0x01]) // Enable advertising
          : Uint8List.fromList([0x20, 0x00]); // Disable advertising

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        opcode,
        BleOutputProperty.withResponse,
      );

      print(
          "Advertising ${enable ? "enabled" : "disabled"} successfully: $opcode");
    } catch (e) {
      print("Error updating advertising state: $e");
    }
  }

  // Regular expression to validate Textbox ( hexadecimal characters)

  final List<TextInputFormatter> _intervalInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(5),
    _INTERVALTextFormatter(),
  ];
  final List<TextInputFormatter> _ctelengthInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(2),
    _CTELENGTHTextFormatter(),
  ];
  final List<TextInputFormatter> _ctecountInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(2),
    _CTECOUNTTextFormatter(),
  ];

  final List<TextInputFormatter> _interval = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
    LengthLimitingTextInputFormatter(5),
  ];

  final List<TextInputFormatter> _txpowerlevel = [
    FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]*')),
    LengthLimitingTextInputFormatter(3),
  ];

//Method to open respective page for each beacon type
  void _handleRadioChange(int value) {
    switch (value) {
      case 0:
        advPacketType = 0;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => IBeaconConfig(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );
        break;

      case 1:
        advPacketType = 1;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EddystoneUid(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );

        break;

      case 2:
        advPacketType = 2;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EddystoneUrl(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );

        break;

      case 3:
        advPacketType = 5;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EddystoneTlm(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );
        break;

      case 4:
        advPacketType = 3;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AltBeacon(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );

        break;

      case 5:
        advPacketType = 4;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ManufacturerSpecificData(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    beaconTunerService: widget.beaconTunerService,
                  )),
        );
    }
  }

// Helper function to check if a string is a valid hex string of a specific length
  bool isValidHex(String hex, int expectedLength) {
    if (hex.length != expectedLength) return false;
    final validHex = RegExp(r'^[0-9A-Fa-f]+$');
    return validHex.hasMatch(hex);
  }

  Uint8List createibeaconSettings(
      Uint8List opcode, String uuid, int majorId, int minorId) {
    // Remove hyphens from the UUID
    String cleanUuid = uuid.replaceAll('-', '');

    // Convert the clean UUID string to a Uint8List
    Uint8List uuidBytes = Uint8List.fromList(List.generate(16, (i) {
      return int.parse(cleanUuid.substring(i * 2, i * 2 + 2), radix: 16);
    }));

    return Uint8List.fromList([
      opcode[0],
      ...uuidBytes, // Spread the uuidBytes
      (majorId >> 8) & 0xFF, // Major ID high byte
      majorId & 0xFF, // Major ID low byte
      (minorId >> 8) & 0xFF, // Minor ID high byte
      minorId & 0xFF, // Minor ID low byte
    ]);
  }

  void setibeaconPacket(String uuid, int majorId, int minorId) async {
    Uint8List opcode = Uint8List.fromList([0x31]);
    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;
      Uint8List iBeaconSettings =
          createibeaconSettings(opcode, uuid, majorId, minorId);

      addLog(
          "Sent",
          iBeaconSettings
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('-'));
      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        iBeaconSettings,
        BleOutputProperty.withResponse,
      );

      setState(() {
        response = iBeaconSettings;
      });

      print("iBeacon data written to the device: $iBeaconSettings");
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
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

  Uint8List createEddystoneUrlPacket(
      Uint8List opcode, int prefix, String url, int? suffix) {
    // Convert the URL (hexadecimal string) to a byte array
    List<int> urlBytes = _hexStringToBytes(url);
    List<int> extraBytesArray = [];
    debugPrint("urlBytes:${urlBytes.length}");

    // If a suffix is provided (not null), append it to the URL bytes
    if (suffix != null) {
      urlBytes.add(suffix);
    }
    if (urlBytes.length < 17) {
      while (urlBytes.length < 17) {
        urlBytes.add(0x20);
      }
    }

    // Construct the Eddystone-URL packet
    return Uint8List.fromList([
      opcode[0],
      prefix,
      ...urlBytes,
      ...extraBytesArray,
    ]);
  }

// Method to convert a hex string to bytes
  List<int> _hexStringToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String byteString = hex.substring(i, i + 2);
      int byteValue = int.parse(byteString, radix: 16);
      bytes.add(byteValue);
    }
    return bytes;
  }

  void setEddystoneUrlPacket(
    int prefix,
    String encodedUrlHex,
    int? suffix,
  ) async {
    Uint8List opcode = Uint8List.fromList([0x35]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      // Create Eddystone URL Settings
      Uint8List eddyBeaconSettings =
          createEddystoneUrlPacket(opcode, prefix, encodedUrlHex, suffix);

      print("Characteristics UUID: ${selChar.uuid}");
      print("Device ID: ${widget.deviceId}");
      print("Advertising Settings: $eddyBeaconSettings");
      addLog(
          "Sent",
          eddyBeaconSettings
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('-'));
      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        eddyBeaconSettings,
        BleOutputProperty.withResponse,
      );

      setState(() {});

      print("Eddystone-URL data written to the device: $eddyBeaconSettings");
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
  }

  // High RF Output Power Dialog
  void _showHighRfOutputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
              'Warning!\nThe requested output power level is greater than 6 dbm and is subjected to device compliance.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applySettings(); // Apply settings after the dialog is closed
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
}

class _INTERVALTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Format the new text if needed
    String formattedText = newText;

    // Calculate the new cursor position based on the user's input
    int newOffset =
        newValue.selection.baseOffset + (formattedText.length - newText.length);

    // Ensure the new offset is within bounds
    newOffset = newOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class _CTELENGTHTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Format the new text if needed
    String formattedText = newText;

    // Calculate the new cursor position based on the user's input
    int newOffset =
        newValue.selection.baseOffset + (formattedText.length - newText.length);

    // Ensure the new offset is within bounds
    newOffset = newOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class _CTECOUNTTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Format the new text if needed
    String formattedText = newText;

    // Calculate the new cursor position based on the user's input
    int newOffset =
        newValue.selection.baseOffset + (formattedText.length - newText.length);

    // Ensure the new offset is within bounds
    newOffset = newOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
