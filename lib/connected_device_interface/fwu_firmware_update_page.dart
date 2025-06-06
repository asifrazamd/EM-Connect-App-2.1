import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:emconnect/connected_device_interface/device_service_globals.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/protos/generated/firmware_package.pb.dart';
import 'package:path_provider/path_provider.dart';

bool hasErrorOccurred = false;
bool _shouldReboot = false;
int blockSize = 0;
Uint8List? response;
int totalFwCount = 0;
int currentFwCount = 0;
bool _isUpdatingFirmware = false;

class FwuFirmwareUpdatePage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final FirmwareUpdateService firmwareUpdateService;

  const FwuFirmwareUpdatePage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.firmwareUpdateService,
  });

  @override
  State<StatefulWidget> createState() {
    return _FwuFirmwareUpdatePageState();
  }
}

class _FwuFirmwareUpdatePageState extends State<FwuFirmwareUpdatePage> {
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    UniversalBle.onConnectionChange = _handleConnectionChange;
    UniversalBle.onValueChange = _handleValueChange;
  }

  @override
  void dispose() {
    super.dispose();
    UniversalBle.onValueChange = null;
    if (isConnected) UniversalBle.disconnect(widget.deviceId);
  }

  void _handleConnectionChange(
    String deviceId,
    bool isConnected,
    String? error,
  ) {
    debugPrint(
      '_handleConnectionChange $deviceId, $isConnected ${error != null ? 'Error: $error' : ''}',
    );

    setState(() {
      if (deviceId == widget.deviceId) {
        this.isConnected = isConnected;
      }
    });

    addLog('Connection', isConnected ? "Connected" : "Disconnected");

    // Auto Discover Services
    if (this.isConnected) {
      // _discoverServices(isFirmwareUpdate: false);
    }
  }

  Uint8List convertToLittleEndian(Uint8List bigEndianData) {
    Uint8List littleEndianData = Uint8List(bigEndianData.length);
    for (int i = 0; i < bigEndianData.length; i += 2) {
      if (i + 1 < bigEndianData.length) {
        littleEndianData[i] = bigEndianData[i + 1];
        littleEndianData[i + 1] = bigEndianData[i];
      }
    }
    return littleEndianData;
  }

  bool check = false; // Flag to track dialog state
  ValueNotifier<int?> errorCodeNotifier = ValueNotifier(null);

  //Method to extract byte values for all beacon types from response
  void _handleValueChange(
    String deviceId,
    String characteristicId,
    Uint8List value,
  ) {
    // If error encountered in the last BLE operation
    if (hasErrorOccurred) return;

    String responseString =
        value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('-');

    debugPrint('Received hex data: $responseString');
    addLog("Received", responseString);

    Uint8List tempval = convertToLittleEndian(value);
    if (tempval[0] == 0x00 && tempval[1] == 0x10) {
      blockSize = tempval[2] << 8 | tempval[3];
    }

    if (value[1] != 0x00) {
      hasErrorOccurred = true;
      _showDialog(
        context,
        "Error!",
        "Firmware Updated Failed.\nResponse is $responseString\n\n${errorCodes(value[1].toRadixString(16).toUpperCase().padLeft(2, '0'))}",
      );

      return;
    }
  }

  String errorCodes(String errorType) {
    switch (errorType) {
      case '02':
        return "An unknown opcode has been received.";
      case '03':
        return "One or more command parameters contain invalid values.";
      case '04':
        return "Not enough memory or buffer size too short to store data.";
      case '05':
        return "The signature check of a firmware image failed.";
      case '06':
        return "RFU";
      case '07':
        return "RFU";
      case '08':
        return "The FW update state machine has entered into an invalid state.";
      case '09':
        return "RFU";
      case "0A":
        return "The requested operation has failed.";
      case "0B":
        return "An error occurred but the root cause is not identified.";
      case "0C":
        return "The provided public key for verifying the FW image signature is invalid.";
      case "0D":
        return "Use of the SHA256 crypto engine failed.";
      case "0E":
        return "Use of the AES crypto engine failed.";
      default:
        return "Unknown";
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
                hasErrorOccurred = false;
              },
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

  ValueNotifier<String> logNotifier = ValueNotifier<String>("");
  ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);

  Future<void> _pickFirmwareFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'bin', 'hex', 'pack'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      _showFileTypeSelectionDialog(file);
    } else {
      addLog('FirmwareUpdate', 'No file selected.');
    }
  }

  void _showFileTypeSelectionDialog(PlatformFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: UIColors.emNotWhite,
          title: Text('File Selected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Selected file: ${file.name}'),
              SizedBox(
                height: 10,
              ), // Add some space between the text and the button
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _startFirmwareUpdate(file, 'packfile');
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 500));
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: UIColors.emActionBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  ValueNotifier<FirmwareDetails?> firmwareDetailsNotifier =
      ValueNotifier<FirmwareDetails?>(null);

  Future _processFirmwareUpdate(
    List<int> fileData,
    String fileType,
    List<int> firmwareData,
    List<int> signatureX,
    List<int> signatureY,
    List<int> digest,
  ) async {
    debugPrint(
      "Processing firmware update for $fileType with file data of size ${fileData.length} bytes.",
    );

    await Future.delayed(const Duration(milliseconds: 200));

    // Parse the binary data into Protobuf message
    try {
      var myFWPackage = FW_Package.fromBuffer(fileData);

      debugPrint("Firmware Package count: ${myFWPackage.fwCount}}\n");
      debugPrint(
        "Firmware Package generation for  ${myFWPackage.targetInfo.productId}(EM  ${myFWPackage.targetInfo.siliconInfo.siliconType}-D${myFWPackage.targetInfo.siliconInfo.siliconRev}\n",
      );

      totalFwCount = myFWPackage.fwElements.length;
      currentFwCount = 0;
      // for (var firmwareElement in myFWPackage.fwElements) {
      // NOTE: This code can expose more details from pack file
      // if needed, these lines can be uncommented and variables
      // can be used to get the corresponding info.
      // var sigx = (firmwareElement.fwSignature.x);
      // var sigy = (firmwareElement.fwSignature.y);
      // var digest = (firmwareElement.digest);
      // var name = firmwareElement.fwHdr.sectionCode;
      // var fwsignature = FW_Signature.fromBuffer(fileData);

      // Append firmware details to logNotifier
      logNotifier.value += "\n=== Firmware Details ===\n";
      logNotifier.value += "Firmware Count: ${myFWPackage.fwCount}\n";
      logNotifier.value += "Product ID: ${myFWPackage.targetInfo.productId}\n";
      logNotifier.value +=
          "Silicon Type: ${myFWPackage.targetInfo.siliconInfo.siliconType}\n";
      logNotifier.value +=
          "Silicon Rev: ${myFWPackage.targetInfo.siliconInfo.siliconRev}\n";

      ValueNotifier<String> tempLogs = ValueNotifier<String>("");
      tempLogs.value = logNotifier.value;

      // Iterate through the firmwares present in the pack file
      for (var firmwareElement in myFWPackage.fwElements) {
        ++currentFwCount;
        progressNotifier.value = 0;
        logNotifier.value = tempLogs.value;
        logNotifier.value +=
            "Section Code: ${firmwareElement.fwHdr.sectionCode}\n";
        logNotifier.value +=
            "FW Start Address: ${firmwareElement.fwHdr.fwStartAddr}\n";
        logNotifier.value += "FW Size: ${firmwareElement.fwHdr.fwSize} bytes\n";
        logNotifier.value += "FW CRC: ${firmwareElement.fwHdr.fwCrc}\n";
        logNotifier.value += "FW Version: ${firmwareElement.fwHdr.fwVer}\n";
        logNotifier.value += "Header Length: ${firmwareElement.fwHdr.hdrLen}\n";
        logNotifier.value += "Header CRC: ${firmwareElement.fwHdr.hdrCrc}\n";
        logNotifier.value += "Emcore CRC: ${firmwareElement.fwHdr.emcoreCrc}\n";
        logNotifier.value += "========================\n";

        // Process encType
        var encryptionType = [
          firmwareElement.encType.value,
        ]; // Extract integer value from enum

        // Validate and process cryptoInitData
        var cryptoData = Uint8List.fromList(
          firmwareElement.cryptoInitData,
        ); // Convert to Uint8List

        getAreaCount();
        await Future.delayed(const Duration(milliseconds: 500));

        getFirmwareInfo();
        await Future.delayed(const Duration(milliseconds: 500));

        fwuCryptoEngineInit(encryptionType, cryptoData);
        logNotifier.value += "Initializing crypto engine...\n";
        await Future.delayed(const Duration(milliseconds: 500));

        // Upload signature material
        uploadSignatureMaterial(
          firmwareElement.fwSignature.x,
          firmwareElement.fwSignature.y,
          firmwareElement.digest,
        );
        logNotifier.value += "Uploading signature material...\n";

        await Future.delayed(const Duration(milliseconds: 500));

        await sendFirmwareUploadInit(firmwareElement.fwHdrRaw);
        logNotifier.value += "Sending firmware upload initialization...\n";

        await Future.delayed(const Duration(milliseconds: 500));
        int showPrct = 1;
        int i;
        for (i = 0; i < firmwareElement.fwHdr.fwSize; i += blockSize) {
          if (hasErrorOccurred) {
            debugPrint("Error detected. Stopping firmware transfer loop.");
            logNotifier.value +=
                "\nError occurred. Firmware transfer aborted.\n";
            return;
          }
          int prct = ((i / firmwareElement.fwHdr.fwSize) * 100).toInt();

          if (prct >= showPrct) {
            debugPrint('percentage: $prct');
            progressNotifier.value = prct; // Update UI

            showPrct = prct + 13;
          }

          bool status = await writeFirmwareData(
            firmwareElement.fwCodeRaw.sublist(
              i,
              min(i + blockSize, firmwareElement.fwCodeRaw.length),
            ),
            200,
          );
          await Future.delayed(const Duration(milliseconds: 100));

          status = await storeFirmwareBlock();
          if (!status) {
            logNotifier.value +=
                "\nError occurred. Firmware transfer aborted.\n";
            debugPrint("Error storing firmware block");
            return;
          }

          await Future.delayed(const Duration(milliseconds: 150));
        }

        validateFirmware();
        logNotifier.value += "Validating firmware...\n";
        await Future.delayed(const Duration(milliseconds: 200));

        progressNotifier.value = 100; // Mark as complete
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_shouldReboot) {
        if (progressNotifier.value == 100) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
        rebootToApplication();
      }
    } catch (e) {
      debugPrint("Error parsing firmware package: $e");
    }
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: UIColors.emNotWhite,
          title: Text(title, style: TextStyle(color: UIColors.emNearBlack)),
          content: Text(message, style: TextStyle(color: UIColors.emNearBlack)),
          actions: [
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(color: UIColors.emActionBlue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  ValueNotifier<bool> showUploadProgress = ValueNotifier<bool>(false);

  void _startFirmwareUpdate(PlatformFile file, String fileType) {
    showUploadProgress.value = true;
    List<int> firmwareData = [];
    List<int> signatureX = [];
    List<int> signatureY = [];
    List<int> digest = [];

    if (file.path != null) {
      File selectedFile = File(file.path!);
      selectedFile.readAsBytes().then((fileData) {
        // Proceed with firmware update using fileData
        _processFirmwareUpdate(
          fileData,
          fileType,
          firmwareData,
          signatureX,
          signatureY,
          digest,
        );
      });
    }
  }

  void getAreaCount() async {
    Uint8List opcode = Uint8List.fromList([0x02]);

    debugPrint("DeviceID: ${widget.deviceId}");

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;
      debugPrint("DeviceID: ${widget.deviceId}");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        opcode,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = opcode;
      });

      debugPrint("Data written to the device: $opcode");
    } catch (e) {
      debugPrint("Get Area Count Failed: $e");
    }
  }

  void getFirmwareInfo() async {
    Uint8List opcode = Uint8List.fromList([0x03, 0x00]);

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        opcode,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = opcode;
      });

      debugPrint("Data written to the device: $opcode");
      debugPrint("Firmware update Information received successfully");
    } catch (e) {
      debugPrint("Get Firmwareupdate Failed: $e");
    }
  }

  Uint8List createCryptoEngineInitPacket(
    dynamic encryptionType,
    dynamic initializationData,
  ) {
    // Convert initializationData to Uint8List if it's a List<int>
    if (initializationData is List<int>) {
      initializationData = Uint8List.fromList(initializationData);
    }

    // Validate initializationData length
    if (initializationData != null &&
        initializationData.isNotEmpty &&
        initializationData.length != 16) {
      throw Exception(
        "The size of the initialization data (0x${initializationData.length.toRadixString(16)}) is not 16",
      );
    }

    // Construct the BLE command packet
    return Uint8List.fromList([
      0x30,

      ...encryptionType, // Encryption type bytes
      if (initializationData != null)
        ...initializationData, // Initialization data bytes
    ]);
  }

  Future<void> fwuCryptoEngineInit(
    dynamic encryptionType,
    dynamic initializationData,
  ) async {
    // Handle `encryptionType` as either `int` or `List<int>`
    if (encryptionType is int) {
      encryptionType = [encryptionType]; // Convert single int to a List<int>
    } else if (encryptionType is List<int>) {
      // No action needed
    } else {
      throw Exception(
        "Unsupported encryptionType format. Expected int or List<int>.",
      );
    }

    // Convert initializationData to Uint8List if it's a List<int>
    if (initializationData is List<int>) {
      initializationData = Uint8List.fromList(initializationData);
    }

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;

      Uint8List cryptoEnginePacket = createCryptoEngineInitPacket(
        encryptionType,
        initializationData,
      );

      debugPrint("Characteristic UUID: ${selChar.uuid}");
      debugPrint("Device ID: ${widget.deviceId}");
      debugPrint("Crypto Engine Init Packet: $cryptoEnginePacket");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        cryptoEnginePacket,
        BleOutputProperty.withResponse,
      );

      setState(() {
        response = cryptoEnginePacket;
      });

      debugPrint(
        "Crypto engine initialized successfully with response: $cryptoEnginePacket",
      );
    } catch (e) {
      debugPrint("Error initializing crypto engine: $e");
    }
  }

  void uploadSignatureMaterial(
    List<int> sigx,
    List<int> sigy,
    List<int> digest,
  ) async {
    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;

      // Convert List<int> to Uint8List
      Uint8List sigxBytes = Uint8List.fromList(sigx);
      Uint8List sigyBytes = Uint8List.fromList(sigy);
      Uint8List digestBytes = Uint8List.fromList(digest);

      // Combine all the data into a single Uint8List
      Uint8List signaturePacket = Uint8List.fromList([
        0x31,
        ...sigxBytes,
        ...sigyBytes,
        ...digestBytes,
      ]);

      debugPrint("characteristics: ${selChar.uuid}");
      debugPrint("DeviceID: ${widget.deviceId}");

      // Write to BLE characteristic
      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        signaturePacket,
        BleOutputProperty.withResponse,
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            "BLE write operation timed out after 15 seconds.",
          );
        },
      );

      setState(() {
        response = signaturePacket;
      });

      debugPrint("Signature material uploaded successfully:$signaturePacket");
    } catch (e) {
      debugPrint("Error uploading signature material: $e");
    }
  }

  Uint8List prepareFirmwareHeader(dynamic header) {
    // Convert hex string to bytes
    if (header is String) {
      header = header.replaceAll("0x", "");
      return Uint8List.fromList(
        List.generate(header.length ~/ 2, (i) {
          return int.parse(header.substring(i * 2, i * 2 + 2), radix: 16);
        }),
      );
    }
    // If already Uint8List, return it
    if (header is Uint8List) {
      return header;
    }
    throw ArgumentError("Invalid header type. Must be String or Uint8List.");
  }

  Map<String, String> decodeFwHeader(Uint8List header) {
    return {"header_crc_ctrl": "OK"}; // Simulating a valid CRC response
  }

  Future<int> sendFirmwareUploadInit(dynamic header) async {
    // response.where((byte) => ![70, 72, 68, 82].contains(byte)).toList();
    Uint8List preparedHeader = prepareFirmwareHeader(header);

    // Ensure header is exactly 0x28 (40 bytes)
    if (preparedHeader.length != 0x28) {
      debugPrint("Error: Header size (${preparedHeader.length}) is incorrect.");
      return preparedHeader.length;
    }

    // Perform CRC check
    String crcCheck = decodeFwHeader(preparedHeader)["header_crc_ctrl"] ?? "";
    if (!crcCheck.startsWith("OK")) {
      debugPrint("CRC Error: $crcCheck");
      return preparedHeader.length;
    }

    Uint8List firmwareInitPacket = Uint8List.fromList([
      0x10,
      ...preparedHeader,
    ]);

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        firmwareInitPacket,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = firmwareInitPacket;
      });
      debugPrint('Response from sendFirmwareUploadInit: $response');

      debugPrint("Header length: ${preparedHeader.length}");
      debugPrint("Firmware upload initialization:$firmwareInitPacket");

      return preparedHeader.length;
    } catch (e) {
      debugPrint("Error writing firmware upload init packet: $e");
      return preparedHeader.length;
    }
  }

  Future<bool> writeFirmwareData(List<int> block, int chunkSize) async {
    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.dataChar;

      int blocks = (block.length / chunkSize).ceil();

      for (int i = 0; i < blocks; i++) {
        Uint8List d = Uint8List.fromList(
          block.sublist(
            i * chunkSize,
            min(i * chunkSize + chunkSize, block.length),
          ),
        );
        Uint8List newList = Uint8List.fromList([...d]);

        await UniversalBle.writeValue(
          widget.deviceId,
          selService.uuid,
          selChar.uuid,
          newList,
          BleOutputProperty.withoutResponse,
        );

        await Future.delayed(Duration(milliseconds: 120));
      }

      return true;
    } catch (e) {
      debugPrint("Error writing firmware data block: $e");
      return false;
    }
  }

  Future<bool> storeFirmwareBlock() async {
    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;

      Uint8List firmwareBlockCommand = Uint8List.fromList([0x20]);

      debugPrint("Characteristics: ${selChar.uuid}");
      debugPrint("DeviceID: ${widget.deviceId}");
      debugPrint("Sending Firmware Block Store Command");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        firmwareBlockCommand,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = firmwareBlockCommand;
      });

      debugPrint("Firmware block stored successfully");
      return true;
    } catch (e) {
      debugPrint("Error storing firmware block: $e");
      return false;
    }
  }

  void validateFirmware() async {
    Uint8List opcode = Uint8List.fromList([0x21]);

    debugPrint("DeviceID: ${widget.deviceId}");

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;
      debugPrint("DeviceID: ${widget.deviceId}");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        opcode,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = opcode;
      });

      debugPrint("Received response from the device: $opcode");
    } catch (e) {
      debugPrint("Crypto Initialization Failed: $e");
    }
  }

  void rebootToApplication() async {
    Uint8List opcode = Uint8List.fromList([0x04, 0x02]);

    debugPrint("DeviceID: ${widget.deviceId}");

    try {
      BleService selService = widget.firmwareUpdateService.service;
      BleCharacteristic selChar = widget.firmwareUpdateService.controlPointChar;
      debugPrint("DeviceID: ${widget.deviceId}");

      await UniversalBle.writeValue(
        widget.deviceId,
        selService.uuid,
        selChar.uuid,
        opcode,
        BleOutputProperty.withResponse,
      );
      setState(() {
        response = opcode;
      });

      debugPrint("Data written to the device: $opcode");
    } catch (e) {
      debugPrint("Crypto Initialization Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emNotWhite,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          "Firmware Updater",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: Offset(-15, 0),
                    child: Checkbox(
                      value: _shouldReboot,
                      onChanged: _isUpdatingFirmware
                          ? null
                          : (bool? value) {
                              setState(() {
                                _shouldReboot = value ?? true;
                              });
                            },
                      side: BorderSide(color: UIColors.emRed, width: 2),
                      fillColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return UIColors.emActionBlue;
                        }
                        return UIColors.emGrey;
                      }),
                      checkColor: UIColors.emNotWhite,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(-15, 0),
                    child: Text(
                      'Reboot to Application Mode after update',
                      style:
                          TextStyle(fontSize: 14, color: UIColors.emNearBlack),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _isUpdatingFirmware ? null : _pickFirmwareFile,
                child: Opacity(
                  opacity: _isUpdatingFirmware ? 0.5 : 1.0,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UIColors.emNotWhite,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.emNearBlack,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 24,
                          color: UIColors.emActionBlue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Select File",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              ValueListenableBuilder<String>(
                valueListenable: logNotifier,
                builder: (context, log, child) {
                  return Text(log, style: TextStyle(fontSize: 14));
                },
              ),

              // Show Progress Only When Confirm is Clicked
              ValueListenableBuilder<bool>(
                valueListenable: showUploadProgress,
                builder: (context, show, child) {
                  return show
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              "Uploading Firmware:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            ValueListenableBuilder<int>(
                              valueListenable: progressNotifier,
                              builder: (context, progress, child) {
                                if ((progress > 0 && progress < 100) ||
                                    !showUploadProgress.value) {
                                  _isUpdatingFirmware = true;
                                }
                                if (progress == 100 || hasErrorOccurred) {
                                  Future.microtask(
                                    () => setState(() {
                                      _isUpdatingFirmware = false;
                                    }),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasErrorOccurred
                                          ? "Firmware Update Failed ❌"
                                          : (progress == 100
                                              ? "Firmware update done ✅"
                                              : "Flashing firmware $currentFwCount of $totalFwCount\n$progress% completed"),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: hasErrorOccurred
                                            ? UIColors.emRed
                                            : UIColors.emActionBlue,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress / 100,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        UIColors.emActionBlue,
                                      ),
                                      backgroundColor: UIColors.emNotWhite,
                                    ),
                                    (progress == 100 &&
                                            currentFwCount == totalFwCount)
                                        ? Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              top: 8.0,
                                              bottom: 0,
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      const Size(200, 40),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  backgroundColor:
                                                      UIColors.emActionBlue),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'Done',
                                                style: TextStyle(
                                                  color: UIColors.emNotWhite,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SizedBox.shrink(),
                                  ],
                                );
                              },
                            ),
                          ],
                        )
                      : SizedBox(); // Hide progress bar initially
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ValueNotifier<FirmwareDetails?> firmwareDetailsNotifier =
    ValueNotifier<FirmwareDetails?>(null);

class FirmwareDetails {
  String productId;
  int siliconType;
  int siliconRev;
  int firmwareVer;
  int fwStartAddr;
  int fwSize;
  int fwCrc;
  int hdrLen;
  int hdrCrc;
  int emcoreCrc;
  int firmwarecount;

  FirmwareDetails({
    required this.productId,
    required this.siliconType,
    required this.siliconRev,
    required this.firmwareVer,
    required this.fwStartAddr,
    required this.fwSize,
    required this.fwCrc,
    required this.hdrLen,
    required this.hdrCrc,
    required this.emcoreCrc,
    required this.firmwarecount,
  });
}
