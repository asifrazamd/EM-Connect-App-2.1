import 'dart:io';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:collection/collection.dart';
import 'package:emconnect/app_globals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:emconnect/connected_device_interface/em_ble_ops.dart';

Uint8List? response;
String manufacturerId = "";
String userData = "";
bool isEnabled = false;

class ManufacturerSpecificData extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  final BeaconTunerService beaconTunerService;
  const ManufacturerSpecificData({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.beaconTunerService,
  });

  @override
  State<ManufacturerSpecificData> createState() => _ManufacturerSpecificData();
}

class _ManufacturerSpecificData extends State<ManufacturerSpecificData> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController indexController = TextEditingController();

  int getComplete = 0;
  bool isFetchComplete = false;
  bool isLoading = true;
  bool check = false;

// Variables to store selected values
  String selectedFormat = "";
  String formattedText = "";
  Set<int> selectedIndexes = {};
  Set<int> updateIndexes = {};
  final Map<String, String> dataTypeToFormat = {
    "76": "U8",
    "56": "U16",
    "57": "U16",
    "63": "U8",
    "43": "U16",
    "44": "U16",
    "45": "U32",
    "46": "U32",
    "78": "S8",
    "58": "S16",
    "79": "S8",
    "59": "S16",
    "7A": "S8",
    "5A": "S16",
    "7a": "S8",
    "5a": "S16",
    "74": "S8",
    "54": "S16",
    "55": "S16",
    "52": "U32",
    "53": "U32",
  };

  // To get the blocksize according to U8,U16,U32
  int getBlockSize(String? format) {
    if (format == null) return 1;
    if (format.contains("U8") || format.contains("S8")) return 1;
    if (format.contains("U16") || format.contains("S16")) return 2;
    if (format.contains("U32")) return 4;
    return 0;
  }

  List<String> originalData = List.generate(24, (index) => "00");
  List<String> textFieldData = List.generate(24, (index) => "00");
  List<Map<String, dynamic>> rows = [];

  List<TextEditingController> textControllers = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    UniversalBle.onValueChange = _handleValueChange;
    readBeacon();
    addgetrow(sharedText);
  }

  @override
  void dispose() {
    super.dispose();

    UniversalBle.onValueChange = null;
  }

  //Method to read beacon values
  Future readBeacon() async {
    Uint8List deviceInfoopcode = Uint8List.fromList([0x30]);

    try {
      BleService selService = widget.beaconTunerService.service;
      BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

      for (int i = 0; i < 1; i++) {
        isFetchComplete = false;

        if (i == 0) {
          debugPrint("into Manufacturer specific data get\n");
          deviceInfoopcode = Uint8List.fromList([0x38]);
        }

        await UniversalBle.writeValue(
          widget.deviceId,
          selService.uuid,
          selChar.uuid,
          deviceInfoopcode,
          BleOutputProperty.withResponse,
        );
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    } catch (e) {
      print("Error writing advertising settings: $e");
    }
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

    if (value.length > 3) {
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

          getComplete += 1;
        });
        print('user data: $userData');
        print('mfid: $manufacturerId');
        print('UserData: $userData');
        check = true;
      }

      Future.delayed(Duration(seconds: 2));
      setState(() {
        isLoading = false; // Set loading to false after reading
      });

      Future.delayed(Duration(seconds: 2)); // Simulating delay
      setState(() {
        isLoading = false; // Set loading to false after reading
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

// To get the  substitution layer generated data
  void addgetrow(String hexString) {
    setState(() {
      if (hexString.length != 48) {
        print("Error: The hex string must be exactly 48 characters long.");
        return;
      }

      for (int i = 0; i < 24; i++) {
        String byte = hexString.substring(i * 2, (i * 2) + 2).toUpperCase();
        textFieldData[i] =
            byte; // Extract 2 hex characters (1 byte) // Extract 2 characters (1 byte)

        if (byte.compareTo("00") != 0) {
          rows.add({
            'selectedDataType': byte,
            'selectedFormat': dataTypeToFormat[byte],
            'selectedIndex': i,
            'isLastRow': false,
            'isDisabled': true, // Initialize as false
          });

          for (int j = i; j < i + getBlockSize(dataTypeToFormat[byte]); j++) {
            selectedIndexes.add(j);
            updateIndexes.add(j);
          }
          rows.last['isDisabled'] = true;
        }
      }
      formattedText = textFieldData.join();

      rows.add({
        'selectedDataType': null,
        'selectedFormat': null,
        'selectedIndex': null,
        'isLastRow': true,
        'isDisabled': false, // Initialize as false
      });
    });
  }

  // Mapping Data Types to Formats
// To update the UI selected by user
  void updateTextField(bool data) {
    List<String> tempData = List.generate(24, (index) => "00");
    int index;
    String dataType;
    String? format;
    for (var row in rows) {
      if (row['selectedIndex'] == null ||
          row['selectedDataType'] == null ||
          row['selectedFormat'] == null) {
        continue;
      }

      index = row['selectedIndex'];
      dataType = row['selectedDataType'];
      format = row['selectedFormat'];
      int zeroCount = (row['selectedFormat'] == "U8" ||
              row['selectedFormat'] == "S8")
          ? 2
          : (row['selectedFormat'] == "U16" || row['selectedFormat'] == "S16")
              ? 4
              : 8;
      if (index + (zeroCount ~/ 2) <= 24) {
        tempData[index] = dataType;
        for (int i = 1; i < (zeroCount ~/ 2); i++) {
          if (index + i < 24) tempData[index + i] = "00";
        }
      }

      if (data) {
        row['isDisabled'] = true;
      }
    }

    setState(() {
      textFieldData = tempData;
      sharedText = textFieldData.join();

      formattedText = textFieldData.join("").replaceAll(" ", "");
      int blockSize = getBlockSize(format);
      if (blockSize > 0) {
        for (int i = 0; i < selectedIndexes.length; i++) {
          updateIndexes.add(selectedIndexes.elementAt(i));
        }
      }
    });
    print('formatted data $formattedText');
  }

//To add new Rows
  void addRow() {
    setState(() {
      if (rows.isNotEmpty) {
        var lastRow = rows.last;
        if (lastRow['selectedDataType'] == null ||
            lastRow['selectedIndex'] == null) {
          errorMessage =
              "Please enter both Data Type and Index before adding a new row.";

          return;
        }

        if ((lastRow['selectedFormat'] == "U16" ||
                lastRow['selectedFormat'] == "S16") &&
            lastRow['selectedIndex'] > 22) {
          updateIndexes.remove(lastRow['selectedIndex']);
          selectedIndexes.remove(lastRow['selectedIndex']);
          lastRow['selectedFormat'] = null;
          lastRow['selectedDataType'] = null;
          lastRow['selectedIndex'] = null;
          errorMessage =
              "It is not possible to add this data type in this index.";
          return;
        }

        if ((lastRow['selectedFormat'] == "U32" ||
                lastRow['selectedFormat'] == "S32") &&
            lastRow['selectedIndex'] > 20) {
          errorMessage =
              "It is not possible to add this data type in this index.";
          return;
        }
        int lastIndex = lastRow['selectedIndex'] ?? -1;
        if (updateIndexes.contains(lastIndex + 1) &&
            !(lastRow['selectedFormat'] == "S8" ||
                lastRow['selectedFormat'] == "U8")) {
          updateIndexes.remove(lastIndex);
          selectedIndexes.remove(lastIndex);
          lastRow['selectedFormat'] = null;
          lastRow['selectedDataType'] = null;
          lastRow['selectedIndex'] = null;

          errorMessage = "Cannot add a row at this index with this data type";
          return;
        }

        rows.last['isLastRow'] = false;
      }

      rows.add({
        'selectedDataType': null,
        'selectedFormat': null,
        'selectedIndex': null,
        'isLastRow': true,
        'isDisabled': false, // Initialize as false
      });

      errorMessage = null;
      updateTextField(true);
    });
  }

  void deleteRow(int index) {
    setState(() {
      // Free the indices occupied by the row being deleted
      if (rows[index]['selectedIndex'] != null) {
        int prevIndex = rows[index]['selectedIndex'];
        String? prevFormat = rows[index]['selectedFormat'];
        int prevBlockSize = getBlockSize(prevFormat);

        for (int i = prevIndex; i < prevIndex + prevBlockSize; i++) {
          updateIndexes.remove(i);
          selectedIndexes.remove(i);
        }
      }

      // Remove the row
      //rows[index]['isDisabled'] = false;
      rows.removeAt(index);

      // Adjusting indices
      if (rows.isNotEmpty) rows.last['isLastRow'] = true;

      updateTextField(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int columnsPerRow = (screenWidth ~/ 30)
        .clamp(6, 12); // Adjust columns based on screen width
    int totalRows = (24 / columnsPerRow).ceil();
    return Scaffold(
      backgroundColor: UIColors.emGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          "Manufacturer Specific Data",
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize:
                        MainAxisSize.min, // Allow column to shrink/grow
                    children: [
                      // Manufacturer ID Input
                      Row(
                        children: [
                          Text(' Manufacturer ID (2 Bytes)',
                              style: TextStyle(
                                  fontSize: 15, color: UIColors.emDarkGrey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _manufacturerid2InputFormatters,
                          initialValue: manufacturerId,
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
                              return 'Manufacturer ID cannot be empty';
                            }
                            final hexRegex = RegExp(r'^[0-9A-Fa-f]{4}$');
                            if (!hexRegex.hasMatch(value)) {
                              return 'Manufacturer ID should be a valid 4-character hexadecimal.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            manufacturerId = value;
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // User Data Input
                      Row(
                        children: [
                          Text('Data (1 to 24 Bytes)',
                              style: TextStyle(
                                  fontSize: 15, color: UIColors.emDarkGrey)),
                        ],
                      ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          style: TextStyle(fontSize: 15),
                          inputFormatters: _dataInputFormatters,
                          initialValue: userData,
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
                              return 'Data cannot be empty';
                            }
                            if (value.length < 2 || value.length > 48) {
                              return 'Enter valid 2-48 hex characters.';
                            }
                            final hexRegex = RegExp(r'^[0-9A-Fa-f]+$');
                            if (!hexRegex.hasMatch(value)) {
                              return 'Enter valid hexadecimal characters (0-9, A-F).';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            userData = value;
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Manufacturer Data field
                      Row(
                        children: [
                          Transform.translate(
                            offset: Offset(-15, 0),
                            child: Checkbox(
                              value: isEnabled,
                              onChanged: (bool? value) {
                                setState(() {
                                  isEnabled = value ?? true;
                                });
                              },
                              side: BorderSide(
                                color: UIColors.emRed,
                                width: 2,
                              ),
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return UIColors.emActionBlue;
                                  }
                                  return UIColors.emDarkGrey;
                                },
                              ),
                              checkColor: UIColors.emNotWhite,
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(-15, 0),
                            child: Text(
                              'Enable Manufacturer Specific Substitution',
                              style: TextStyle(
                                  fontSize: 14, color: UIColors.emNearBlack),
                            ),
                          ),
                        ],
                      ),
                      if (isEnabled)
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Substitution Layer Generated (24 Bytes)',
                                style: TextStyle(
                                    fontSize: 15, color: UIColors.emDarkGrey),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Table with automatic wrapping
                                  Column(
                                    children:
                                        List.generate(totalRows, (rowIndex) {
                                      int startIndex = rowIndex * columnsPerRow;
                                      int endIndex =
                                          (startIndex + columnsPerRow)
                                              .clamp(0, 24);

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 5.0),
                                        child: Table(
                                          border: TableBorder.all(
                                              color: UIColors.emDarkGrey,
                                              width: 1),
                                          columnWidths: {
                                            for (int i = 0;
                                                i < columnsPerRow;
                                                i++)
                                              i: FlexColumnWidth()
                                          },
                                          children: [
                                            // Byte Indices Row
                                            TableRow(
                                              children: List.generate(
                                                endIndex - startIndex,
                                                (index) {
                                                  int currentIndex =
                                                      startIndex + index;
                                                  return Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Text(
                                                      currentIndex.toString(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color:
                                                            UIColors.emDarkGrey,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // Byte Values Row
                                            TableRow(
                                              children: List.generate(
                                                  endIndex - startIndex,
                                                  (index) {
                                                int currentIndex =
                                                    startIndex + index;
                                                return Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Text(
                                                      textFieldData[
                                                          startIndex + index],
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color: updateIndexes.contains(
                                                                  currentIndex)
                                                              ? UIColors
                                                                  .emActionBlue
                                                              : UIColors.emGrey,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ));
                                              }),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),

                                  SizedBox(height: 20),

                                  // Dynamically Generated Rows
                                  Column(
                                      children:
                                          List.generate(rows.length, (index) {
                                    return buildRow(index);
                                  })),
                                ],
                              ),
                            ]),

                      SizedBox(height: 20),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                                color: UIColors.emRed,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                      // Apply Button Positioned Dynamically
                      SizedBox(
                        width: double.infinity,
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
                              setState(() {
                                if (isEnabled) {
                                  if (textFieldData.equals(originalData)) {
                                    errorMessage =
                                        "Please validate your entry with + action.";
                                  } else {
                                    SetManufacturerSpecificData(
                                        manufacturerId, userData);
                                    setSubstitutionPacket(formattedText);
                                    Navigator.pop(context);
                                  }
                                } else {
                                  SetManufacturerSpecificData(
                                      manufacturerId, userData);
                                  Navigator.pop(context);
                                }
                              });
                            }
                          },
                          child: Text(
                            'Apply',
                            style:
                                TextStyle(color: UIColors.emGrey, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Card(
              margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
              elevation: 1,
              color: UIColors.emNotWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              child: Container(
                height: 30, // Ensure all cards have the same height
                padding: EdgeInsets.fromLTRB(4, 0, 1, 0),
                alignment: Alignment.center,
                child: DropdownButtonFormField<String>(
                  dropdownColor: UIColors.emNotWhite,
                  value: rows[index]['selectedDataType'],
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(fontSize: 10),
                    labelText: rows[index]['selectedDataType'] == null
                        ? "Data Type"
                        : null,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  ),
                  items: [
                    {"label": "Battery voltage 100 (mV) (U8)", "value": "76"},
                    {"label": "Battery voltage (mV) (U16) (LE)", "value": "56"},
                    {"label": "Battery voltage (mV) (U16) (BE)", "value": "57"},
                    {"label": "8-bit counter (U8)", "value": "63"},
                    {"label": "16-bit counter (U16) (LE)", "value": "43"},
                    {"label": "16-bit counter (U16) (BE)", "value": "44"},
                    {"label": "32-bit counter (U32) (LE)", "value": "45"},
                    {"label": "32-bit counter (U32) (BE)", "value": "46"},
                    {"label": "Accel X axis(1/32g) (S8)", "value": "78"},
                    {
                      "label": "Accel X axis(1/2048g) (S16) (LE)",
                      "value": "58"
                    },
                    {"label": "Accel Y axis(1/32g) (S8)", "value": "79"},
                    {
                      "label": "Accel Y axis(1/2048g) (S16) (LE)",
                      "value": "59"
                    },
                    {"label": "Accel Z axis(1/32g) (S8)", "value": "7A"},
                    {
                      "label": "Accel Z axis(1/2048g) (S16) (LE)",
                      "value": "5A"
                    },
                    {"label": "Temperature(°C) (S8)", "value": "74"},
                    {"label": "Temperature(0.01°C) (S16) (LE)", "value": "54"},
                    {"label": "Temperature(1/256°C) S16 BE", "value": "55"},
                    {"label": "Time(seconds) U32 LE", "value": "52"},
                    {"label": "Time(0.1 s) U32 BE", "value": "53"},
                  ]
                      .map((item) => DropdownMenuItem(
                            value: item["value"],
                            child: Text(item["label"]!,
                                style: TextStyle(fontSize: 10)),
                          ))
                      .toList(),
                  menuMaxHeight: 250,
                  onChanged: (rows[index]['isDisabled'] ?? false)
                      ? null
                      : (value) {
                          setState(() {
                            rows[index]['selectedDataType'] = value;
                            rows[index]['selectedFormat'] =
                                dataTypeToFormat[value] ?? "Unknown";
                          });
                        },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Card(
              margin: EdgeInsets.all(0),
              color: UIColors.emNotWhite,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              child: Container(
                height: 30, // Keep height consistent
                padding: EdgeInsets.all(0),
                alignment: Alignment.center,
                child: DropdownButtonFormField<int>(
                  value: rows[index]['selectedIndex'],
                  dropdownColor: UIColors.emNotWhite,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(fontSize: 10),
                    labelText:
                        rows[index]['selectedIndex'] == null ? "Index" : null,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(4, 0, 0, 0),
                  ),
                  items: List.generate(24, (i) => i)
                      .where((i) =>
                          !selectedIndexes.contains(i) ||
                          i == rows[index]['selectedIndex'])
                      .map((i) => DropdownMenuItem<int>(
                            value: i,
                            child: Text("$i", style: TextStyle(fontSize: 10)),
                          ))
                      .toList(),
                  onChanged: (rows[index]['isDisabled'] ?? false)
                      ? null
                      : (value) {
                          setState(() {
                            if (rows[index]['selectedIndex'] != null) {
                              int prevIndex = rows[index]['selectedIndex'];
                              String? prevFormat =
                                  rows[index]['selectedFormat'];
                              int prevBlockSize = getBlockSize(prevFormat);
                              for (int i = prevIndex;
                                  i < prevIndex + prevBlockSize;
                                  i++) {
                                selectedIndexes.remove(i);
                              }
                            }

                            rows[index]['selectedIndex'] = value;
                            String? format = rows[index]['selectedFormat'];
                            int blockSize = getBlockSize(format);
                            for (int i = value!; i < value + blockSize; i++) {
                              selectedIndexes.add(i);
                            }
                          });
                        },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              padding: EdgeInsets.fromLTRB(2, 0, 2, 0),
              icon: Icon(
                rows[index]['isLastRow']
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: rows[index]['isLastRow']
                    ? UIColors.emGreen
                    : UIColors.emRed,
                size: 21,
              ),
              onPressed: () {
                if (rows[index]['isLastRow']) {
                  addRow();
                } else {
                  deleteRow(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Uint8List createSubstitutionSettings(Uint8List Advopcode, String hex) {
  //   List<int> byteList = [];

  //   for (int i = 0; i < hex.length; i += 2) {
  //     byteList.add(int.parse(hex.substring(i, i + 2), radix: 16));
  //   }
  //   print(byteList);
  //   return Uint8List.fromList([
  //     Advopcode[0],
  //     ...byteList,
  //   ]);
  // }

  // void setSubstitutionPacket(String hexString) async {
  //   Uint8List Advopcode = Uint8List.fromList([0x61]);

  //   try {
  //     BleService selService = widget.beaconTunerService.service;
  //     BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

  //     Uint8List SubstituitionSettings =
  //         createSubstitutionSettings(Advopcode, hexString);
  //                                                                                   await EmBleOpcodes
  //                                                           .writeWithResponse(
  //                                                         deviceId:
  //                                                             widget.deviceId,
  //                                                         service: selService,
  //                                                         characteristic: selChar,
  //                                                         payload: SubstituitionSettings,
  //                                                       );


  //     // await UniversalBle.writeValue(
  //     //   widget.deviceId,
  //     //   selService.uuid,
  //     //   selChar.uuid,
  //     //   SubstituitionSettings,
  //     //   BleOutputProperty.withResponse,
  //     // );

  //     print("Substitution packet sent: $SubstituitionSettings");
  //   } catch (e) {
  //     print("Error writing substitution settings: $e");
  //   }
  // }

  
  
  
  
  
  
  
  // Uint8List createManufacturerSpecificDataPacket(
  //     Uint8List Advopcode, String manufacturerIdHex, String userDataHex) {
  //   // Convert hex string to byte array
  //   Uint8List manufacturerIdBytes = hexStringToBytes(manufacturerIdHex);
  //   Uint8List userDataBytes = hexStringToBytes(userDataHex);

  //   // Ensure the Manufacturer ID is exactly 2 bytes
  //   if (manufacturerIdBytes.length != 2) {
  //     throw Exception(
  //         "Manufacturer ID must be exactly 2 bytes (4 hex characters).");
  //   }

  //   // Ensure the User Data is between 1 and 24 bytes
  //   if (userDataBytes.isEmpty || userDataBytes.length > 24) {
  //     throw Exception("User Data must be 1-24 bytes (2-48 hex characters).");
  //   }

  //   return Uint8List.fromList([
  //     Advopcode[0],
  //     ...manufacturerIdBytes,
  //     ...userDataBytes,
  //   ]);
  // }

  // void SetManufacturerSpecificData(
  //     String manufacturerId, String userData) async {
  //   Uint8List Advopcode = Uint8List.fromList([0x39]);

  //   try {
  //     BleService selService = widget.beaconTunerService.service;
  //     BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;
  //     Uint8List mfgDataPacket = createManufacturerSpecificDataPacket(
  //         Advopcode, manufacturerId, userData);

  //     print("characteristics: ${selChar.uuid}");
  //     print("DeviceID: ${widget.deviceId}");
  //     print("Manufacturer Specific Data Packet: $mfgDataPacket");
  //     addLog(
  //         "Sent",
  //         mfgDataPacket
  //             .map((b) => b.toRadixString(16).padLeft(2, '0'))
  //             .join('-'));

  //     // await UniversalBle.writeValue(
  //     //   widget.deviceId,
  //     //   selService.uuid,
  //     //   selChar.uuid,
  //     //   mfgDataPacket,
  //     //   BleOutputProperty.withResponse,
  //     // );

  //     await EmBleOps.writeWithResponse(
  //       deviceId: widget.deviceId,
  //       service: selService,
  //       characteristic: selChar,
  //       payload: mfgDataPacket,
  //     );

  //     setState(() {
  //       response = mfgDataPacket;
  //     });

  //     print("Successfully written Manufacturer Specific Data Packet.");
  //   } catch (e) {
  //     print("Error writing Manufacturer Specific Data Packet: $e");
  //   }
  // }

  
  
  void setSubstitutionPacket(String hexString) async {
  Uint8List Advopcode = Uint8List.fromList([0x61]);

  try {
    BleService selService = widget.beaconTunerService.service;
    BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

    // Convert hex string to byte list
    List<int> byteList = [];
    for (int i = 0; i < hexString.length; i += 2) {
      byteList.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }

    // Serialize packet using opcode and byte data
    Uint8List substitutionSettings = EmBleOps.seralize([
      Advopcode[0],
      ...byteList,
    ]);

    await EmBleOpcodes.writeWithResponse(
      deviceId: widget.deviceId,
      service: selService,
      characteristic: selChar,
      payload: substitutionSettings,
    );

    print("Substitution packet sent: $substitutionSettings");
  } catch (e) {
    print("Error writing substitution settings: $e");
  }
}

  
  
  
  
  
  
  
  
  
  void SetManufacturerSpecificData(String manufacturerId, String userData) async {
  Uint8List Advopcode = Uint8List.fromList([0x39]);

  try {
    BleService selService = widget.beaconTunerService.service;
    BleCharacteristic selChar = widget.beaconTunerService.beaconTunerChar;

    // Convert hex strings to byte arrays
    Uint8List manufacturerIdBytes = hexStringToBytes(manufacturerId);
    Uint8List userDataBytes = hexStringToBytes(userData);

    // Validation
    if (manufacturerIdBytes.length != 2) {
      throw Exception("Manufacturer ID must be exactly 2 bytes (4 hex characters).");
    }

    if (userDataBytes.isEmpty || userDataBytes.length > 24) {
      throw Exception("User Data must be between 1 and 24 bytes (2-48 hex characters).");
    }

    // Combine into packet
    Uint8List mfgDataPacket = EmBleOps.seralize([
      Advopcode[0],
      ...manufacturerIdBytes,
      ...userDataBytes,
    ]);

    print("Characteristics UUID: ${selChar.uuid}");
    print("Device ID: ${widget.deviceId}");
    print("Manufacturer Specific Data Packet: $mfgDataPacket");

    addLog(
      "Sent",
      mfgDataPacket.map((b) => b.toRadixString(16).padLeft(2, '0')).join('-'),
    );

    await EmBleOps.writeWithResponse(
      deviceId: widget.deviceId,
      service: selService,
      characteristic: selChar,
      payload: mfgDataPacket,
    );

    setState(() {
      response = mfgDataPacket;
    });

    print("Successfully written Manufacturer Specific Data Packet.");
  } catch (e) {
    print("Error writing Manufacturer Specific Data Packet: $e");
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

  final List<TextInputFormatter> _manufacturerid2InputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(4),
    _MANUFACTURERID2TextFormatter(),
  ];

  final List<TextInputFormatter> _dataInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
    LengthLimitingTextInputFormatter(48),
    _DATATextFormatter(),
  ];
}

class _MANUFACTURERID2TextFormatter extends TextInputFormatter {
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

class _DATATextFormatter extends TextInputFormatter {
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
