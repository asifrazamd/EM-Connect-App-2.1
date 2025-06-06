import 'dart:io';
import 'dart:typed_data';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:path_provider/path_provider.dart';

// bool IBeaconConfig = true;
String uuid = '';
int? majorId;
int? minorId;
Uint8List? response;

class IBeaconConfig extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  final BeaconTunerService beaconTunerService;
  const IBeaconConfig(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.beaconTunerService});

  @override
  State<IBeaconConfig> createState() => _IBeaconConfig();
}

class _IBeaconConfig extends State<IBeaconConfig> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int getComplete = 0;
  bool isFetchComplete = false;
  String? errortext1;

  @override
  void initState() {
    super.initState();

    UniversalBle.onValueChange = _handleValueChange;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      readIBeaconConfig();
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

    addLog("Received", hexString);
    if (value[0] == 0x80) {
      if (value[2] > 0x01) {
        _showDialog(
            context, "Error", "Parameters are Invalid\nLog: $hexString");
      }
    }

    if (value[1] == 0x30) {
      print("IBeaconConfig");

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
  Future readIBeaconConfig() async {
    Uint8List deviceInfoopcode = Uint8List.fromList([0x30]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      debugPrint("into IBeaconConfig get\n");

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

  final _uuidRegex = RegExp(r'^[0-9a-fA-F]{32}$');
  final List<TextInputFormatter> _uuidInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(32),
    _UUIDTextFormatter(),
  ];
  final List<TextInputFormatter> _majoridInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(5),
    _MAJORIDTextFormatter(),
  ];

  final List<TextInputFormatter> _minoridInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(5),
    _MINORIDTextFormatter(),
  ];
  Uint8List createIBeaconConfigSettings(
      Uint8List Advopcode, String uuid, int majorId, int minorId) {
    // Remove hyphens from the UUID
    String cleanUuid = uuid.replaceAll('-', '');

    // Convert the clean UUID string to a Uint8List
    Uint8List uuidBytes = Uint8List.fromList(List.generate(16, (i) {
      return int.parse(cleanUuid.substring(i * 2, i * 2 + 2), radix: 16);
    }));

    return Uint8List.fromList([
      Advopcode[0],
      ...uuidBytes, // Spread the uuidBytes
      (majorId >> 8) & 0xFF, // Major ID high byte
      majorId & 0xFF, // Major ID low byte
      (minorId >> 8) & 0xFF, // Minor ID high byte
      minorId & 0xFF, // Minor ID low byte
    ]);
  }

  void setIBeaconConfigPacket(String uuid, int majorId, int minorId) async {
    Uint8List Advopcode = Uint8List.fromList([0x31]);
    // Uint8List? response;
    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;
      Uint8List IBeaconConfigSettings =
          createIBeaconConfigSettings(Advopcode, uuid, majorId, minorId);

      print("characteristics: ${selChar.uuid}");
      print("DeviceID: ${widget.deviceId}");
      print("Advertising Settings: $createIBeaconConfigSettings");
      addLog(
          "Sent",
          IBeaconConfigSettings.map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('-'));
      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        IBeaconConfigSettings,
        BleOutputProperty.withResponse,
      );

      setState(() {
        response = IBeaconConfigSettings;
      });

      print(
          "IBeaconConfig data written to the device: $IBeaconConfigSettings");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 247, 244, 244),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          "iBeacon",
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
                      // UUID TextBox
                      Row(
                        children: [
                          Text(' Proximity UUID (16 Bytes)',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _uuidInputFormatters,
                          initialValue: uuid,
                          decoration: InputDecoration(
                            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: false,
                            contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            fillColor: UIColors.emNotWhite,
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'UUID cannot be empty.';
                            } else if (!_uuidRegex
                                .hasMatch(value.replaceAll('-', ''))) {
                              return 'Invalid UUID format. It should be 32 hex characters.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              uuid = value.replaceAll('-', '');
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      // Major ID TextBox
                      Row(
                        children: [
                          Text(' Major ID (0 to 65535)',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _majoridInputFormatters,
                          initialValue: majorId.toString(),
                          decoration: InputDecoration(
                            errorText: errortext1,
                            isDense: true,
                            contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            fillColor: UIColors.emNotWhite,
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            int? majorIdValue = int.tryParse(value ?? '');
                            if (majorIdValue == null ||
                                majorIdValue < 0 ||
                                majorIdValue > 65535) {
                              return 'Please enter a valid Major ID (0 - 65535).';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            majorId = int.tryParse(value) ?? 1;
                            setState(() {
                              if (majorId! > 65535) {
                                errortext1 =
                                    'Please enter a valid Minor ID (0 - 65535).';
                              } else {
                                errortext1 = null;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      // Minor ID TextBox
                      Row(
                        children: [
                          Text(' Minor ID (0 to 65535)',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _minoridInputFormatters,
                          initialValue: minorId.toString(),
                          decoration: InputDecoration(
                            isDense: true,
                            errorText: errortext1,
                            contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            fillColor: UIColors.emNotWhite,
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            int? minorIdValue = int.tryParse(value ?? '');
                            if (minorIdValue == null ||
                                minorIdValue < 0 ||
                                minorIdValue > 65535) {
                              return 'Please enter a valid Minor ID (0 - 65535).';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            minorId = int.tryParse(value);
                            setState(() {
                              if (minorId! > 65535) {
                                errortext1 =
                                    'Please enter a valid Minor ID (0 - 65535).';
                              } else {
                                errortext1 = null;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            // Button at the bottom
            Container(
              width: double.infinity, // Ensures the button spans the full width

              margin: const EdgeInsets.only(
                  top: 16.0,
                  bottom: 32.0), // Adds spacing without shrinking the button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    backgroundColor: UIColors.emActionBlue),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setIBeaconConfigPacket(uuid, majorId!, minorId!);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Apply',
                    style: TextStyle(
                        color: Color.fromRGBO(250, 247, 243, 1), fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UUIDTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove existing dashes from the new text
    String rawText = newValue.text.replaceAll('-', '');
    String formattedText = '';
    int rawCursorPosition = newValue.selection.baseOffset;

    // Build the formatted string by inserting dashes at appropriate positions
    for (int i = 0; i < rawText.length; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        formattedText += '-';
      }
      formattedText += rawText[i];
    }

    // Calculate the new cursor position
    int cursorPosition = rawCursorPosition;
    int dashCountBeforeCursor = 0;

    // Count dashes that would be added before the raw cursor position
    for (int i = 0; i < cursorPosition; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        dashCountBeforeCursor++;
      }
    }

    cursorPosition += dashCountBeforeCursor;

    // Ensure the cursor doesn't exceed the formatted text length
    cursorPosition = cursorPosition.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class _MAJORIDTextFormatter extends TextInputFormatter {
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

class _MINORIDTextFormatter extends TextInputFormatter {
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
