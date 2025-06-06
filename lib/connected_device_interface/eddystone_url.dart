import 'dart:convert';
import 'dart:io';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:path_provider/path_provider.dart';

int? prefix;
String url = "";
String displayurl = "";
int? suffix;
Uint8List? response;

class EddystoneUrl extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  final BeaconTunerService beaconTunerService;
  const EddystoneUrl(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.beaconTunerService});

  @override
  State<EddystoneUrl> createState() => _EddystoneUrl();
}

class _EddystoneUrl extends State<EddystoneUrl> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? errorMessage;
  int getComplete = 0;
  bool isFetchComplete = false;

  @override
  void initState() {
    super.initState();

    UniversalBle.onValueChange = _handleValueChange;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      readEddystoneURLBeacon();
    });
  }

  @override
  void dispose() {
    super.dispose();

    UniversalBle.onValueChange = null;
  }

  //Method to extract byte values for all beacon types from response
  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    String hexString =
        value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('-');

    String s = String.fromCharCodes(value);

    print('_handleValueChange $deviceId, $characteristicId, $s');
    print('Received hex data: $hexString');
    addLog("Received", hexString);
    if (value[0] == 0x80) {
      if (value[2] > 0x01) {
        _showDialog(
            context, "Error", "Parameters are Invalid\nLog: $hexString");
      }
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
            url = displayurl;
            // Store suffix
            break;
          }
          // Add byte to URL bytes list
          urlBytes.add(byte);
        }
        print('displayurl : $displayurl');
        print(' suffix : $suffix');
        getComplete += 1;
      });
    }
    isFetchComplete = true;
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
  Future readEddystoneURLBeacon() async {
    Uint8List deviceInfoopcode = Uint8List.fromList([0x34]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      debugPrint("into eddystone url get\n");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        deviceInfoopcode,
        BleOutputProperty.withResponse,
      );
      await Future.delayed(const Duration(milliseconds: 2000));
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
  }

  
  
  
  
  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
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

  final List<TextInputFormatter> _urlInputFormatters = [
    LengthLimitingTextInputFormatter(16),
    _URLTextFormatter(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 247, 244, 244),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          "Eddystone-URL",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),

                      // URL Scheme Prefix Input
                      Row(
                        children: [
                          Text(' Encoding',
                              style: TextStyle(
                                  fontSize: 15, color: UIColors.emDarkGrey)),
                        ],
                      ),
                      DropdownButtonFormField<int>(
                        value: prefix,
                        items: [
                          DropdownMenuItem(
                              value: 0, child: Text("http://www.")),
                          DropdownMenuItem(
                              value: 1, child: Text("https://www.")),
                          DropdownMenuItem(value: 2, child: Text("http://")),
                          DropdownMenuItem(value: 3, child: Text("https://")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            prefix = value;
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Row(
                        children: [
                          Text(' URL (max 16 char)',
                              style: TextStyle(
                                  fontSize: 15, color: UIColors.emDarkGrey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _urlInputFormatters,
                          initialValue: displayurl,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            fillColor: UIColors.emNotWhite,
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'URL cannot be empty.';
                            }

                            final regex = RegExp(r'^[a-zA-Z0-9/_]+$');
                            if (!regex.hasMatch(value)) {
                              return 'URL should contain only letters, numbers, slashes (/), and underscores (_).';
                            }

                            final encodedUrl = utf8.encode(value);
                            if (encodedUrl.isEmpty ||
                                encodedUrl.length > 16) {
                              return 'URL length should be between 1 to 16 values.';
                            }

                            return null;
                          },
                          onChanged: (value) {
                            if (_formKey.currentState?.validate() == true) {
                              displayurl = value;
                              url = utf8
                                  .encode(value)
                                  .map((byte) =>
                                      byte.toRadixString(16).padLeft(2, '0'))
                                  .join();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Suffix Input
                      Row(
                        children: [
                          Text(' Suffix',
                              style: TextStyle(
                                  fontSize: 15, color: UIColors.emDarkGrey)),
                        ],
                      ),
                      DropdownButtonFormField<int?>(
                        value: suffix,
                        items: [
                          DropdownMenuItem(value: 0x00, child: Text(".com/")),
                          DropdownMenuItem(value: 0x01, child: Text(".org/")),
                          DropdownMenuItem(value: 0x02, child: Text(".edu/")),
                          DropdownMenuItem(value: 0x03, child: Text(".net/")),
                          DropdownMenuItem(value: 0x04, child: Text(".info/")),
                          DropdownMenuItem(value: 0x05, child: Text(".biz/")),
                          DropdownMenuItem(value: 0x06, child: Text(".gov/")),
                          DropdownMenuItem(value: 0x07, child: Text(".com")),
                          DropdownMenuItem(value: 0x08, child: Text(".org")),
                          DropdownMenuItem(value: 0x09, child: Text(".edu")),
                          DropdownMenuItem(value: 0x0a, child: Text(".net")),
                          DropdownMenuItem(value: 0x0b, child: Text(".info")),
                          DropdownMenuItem(value: 0x0c, child: Text(".biz")),
                          DropdownMenuItem(value: 0x0d, child: Text(".gov")),
                        ],
                        onChanged: (value) {
                          suffix = value;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Apply Button at the bottom
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16.0, bottom: 32.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: UIColors.emActionBlue,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Process the validated input
                    setEddystoneURLPacket(prefix!, url, suffix);
                    Navigator.pop(
                        context); // Navigate only if validation is successful
                  } else {
                    // Optionally show a message or handle invalid input cases
                    print('Validation failed. Please correct the inputs.');
                  }
                },
                child: const Text(
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

  void setEddystoneURLPacket(
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
}

class _URLTextFormatter extends TextInputFormatter {
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
