import 'dart:io';

import 'package:emconnect/app_globals.dart';
import 'package:emconnect/data/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/data/scan_filter_model.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:emconnect/connected_device_interface/le_device_services.dart';
import 'package:emconnect/scanner_page_widgets/scanned_item_widget.dart';
import 'package:emconnect/scanner_page_widgets/scan_filter_widget.dart';

bool btEnabled = false;
bool permissionsGranted = false;
String scannedMacAddress = "";

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _Scanner();
}

class _Scanner extends State<Scanner> {
  final _scannedLeDevices = <LeDeviceItem>[];
  bool _isScanning = false;

  TextEditingController namePrefixController = TextEditingController();
  TextEditingController macPrefixController = TextEditingController();
  TextEditingController manufacturerDataController = TextEditingController();
  int rssiValue = -100;
  String macFilter = "";

  AvailabilityState? bleAvailabilityState;
  ScanFilter? scanFilter;

  @override
  void initState() {
    super.initState();

    UniversalBle.onAvailabilityChange = (state) {
      setState(() {
        bleAvailabilityState = state;
      });
    };

    UniversalBle.onScanResult = (result) async {
      String deviceId = result.deviceId;
      // Get the current time
      DateTime now = DateTime.now();
      int index =
          _scannedLeDevices.indexWhere((e) => e.bleDevice.deviceId == deviceId);
      if (index == -1) {
        LeDeviceItem leDeviceItem = LeDeviceItem();
        leDeviceItem.bleDevice = result;
        if (result.name == null) {
          leDeviceItem.bleDevice.name = "N/A";
        }
        leDeviceItem.timeStamp = now.millisecondsSinceEpoch;
        _scannedLeDevices.add(leDeviceItem);
      } else {
        if (result.name != null) {
          _scannedLeDevices[index].bleDevice.name = result.name;
        }
        _scannedLeDevices[index].bleDevice.rssi = result.rssi;
        _scannedLeDevices[index].advInterval =
            now.millisecondsSinceEpoch - _scannedLeDevices[index].timeStamp;
        _scannedLeDevices[index].timeStamp = now.millisecondsSinceEpoch;
      }
      setState(() {});
    };
  }

  @override
  void dispose() async {
    super.dispose();
    await stopLeScan();
  }

  void showMacRssiFilterDialog() async {
    ScanFilterModel? model = await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: UIColors.emGrey,
          alignment: Alignment(0, -0.55),
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: Container(
            height: 250,
            width: 500,
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScanFilterWidget(
                    macPrefixController.text,
                    rssiValue.toDouble(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (model != null) {
      setState(() {
        macFilter = model.macAddr;
        rssiValue = model.rssiVal;
      });
    }
  }

  void showEnableBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enable Bluetooth"),
        content: Text(
            "Bluetooth is disabled. Please enable it in the Settings app."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Ok"),
          ),
        ],
      ),
    );
  }

  void processScannedQRCode(String qrCode) async {
    if (qrCode.isNotEmpty) {
      if (qrCode != "-1") {
        try {
          int snToInt = int.parse(qrCode);
          String hexValue = snToInt.toRadixString(16).toUpperCase();

          if (hexValue.length % 2 != 0) {
            hexValue = "0$hexValue";
          }

          List<String> bytePairs = [];
          for (int i = 0; i < hexValue.length; i += 2) {
            bytePairs.add(hexValue.substring(i, i + 2));
          }
          String fullMac = bytePairs.reversed.join(":");

          List<String> macParts = fullMac.split(":");
          String deviceName =
              "EM-${macParts.sublist(macParts.length - 3).join("")}";

          setState(() {
            scannedMacAddress = deviceName;
            namePrefixController.text = deviceName; // Update the search box
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Device Name: $scannedMacAddress")),
          );

          startLeScan();
        } catch (e) {
          debugPrint(" Error processing QR code: $e");
        }
      }
    }
  }

  Future startLeScan() async {
    if (Platform.isAndroid) {
      permissionsGranted = await PermissionHandler.arePermissionsGranted();
      btEnabled = await UniversalBle.enableBluetooth();
    }
    if (!_isScanning && permissionsGranted && btEnabled) {
      _isScanning = true;
      UniversalBle.startScan();
      setState(() {
        _scannedLeDevices.clear();
      });
    }
  }

  Future stopLeScan() async {
    if (_isScanning) {
      _isScanning = false;
      await UniversalBle.stopScan();
      setState(() {});
    }
  }

  Future scanQrCode() async {
    //! NOTE: Use this code only for Android
    //! comment for iOS build
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: MobileScanner(
            fit: BoxFit.cover, // Ensures the camera fills the entire dialog
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.displayValue != null) {
                processScannedQRCode(barcodes.first.displayValue!);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );

    //! NOTE: Use this code only for iOS, comment for Android
    // String qrCode = await FlutterBarcodeScanner.scanBarcode(
    //   "#ff6666", // Scanner overlay color
    //   "Cancel", // Cancel button text
    //   true, // Show flash icon
    //   ScanMode.QR, // Scan mode
    // );
    // if (qrCode != "-1") {
    //   processScannedQRCode(context, qrCode);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final nameQuery = namePrefixController.text.toLowerCase();
    final rssiThreshold = rssiValue;

    final filteredDevices = _scannedLeDevices.where((leDeviceItem) {
      if (nameQuery.isNotEmpty && macFilter.isNotEmpty) {
        return (leDeviceItem.bleDevice.name!
                .toLowerCase()
                .contains(nameQuery) &&
            leDeviceItem.bleDevice.deviceId
                .toString()
                .toLowerCase()
                .contains(macFilter.toLowerCase()) &&
            leDeviceItem.bleDevice.rssi! >= rssiThreshold);
      } else if (nameQuery.isEmpty && macFilter.isNotEmpty) {
        return (leDeviceItem.bleDevice.deviceId
                .toString()
                .toLowerCase()
                .contains(macFilter.toLowerCase()) &&
            leDeviceItem.bleDevice.rssi! >= rssiThreshold);
      } else if ((nameQuery.isNotEmpty && macFilter.isEmpty)) {
        return (leDeviceItem.bleDevice.name!
                .toLowerCase()
                .contains(nameQuery) &&
            leDeviceItem.bleDevice.rssi! >= rssiThreshold);
      } else {
        return (leDeviceItem.bleDevice.rssi! >= rssiThreshold);
      }
    }).toList();

    return Scaffold(
      backgroundColor: UIColors.emNotWhite,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UIColors.emNotWhite,
        title: Text(
          'Scan',
          style: TextStyle(
            color: UIColors.emNearBlack,
            fontSize: UIFont.appBarFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        /* Title bar buttons */
        actions: [
          //! @@ Action button filter
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: UIColors.emNearBlack,
            ),
            onPressed: showMacRssiFilterDialog,
          ),

          //! @@ Action button QR code scanner
          if (filteredDevices.isNotEmpty)
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: Colors.black),
              onPressed: scanQrCode,
            ),

          //! @@ Action button start / stop BLE scan
          IconButton(
              icon: Icon(
                _isScanning ? Icons.stop : Icons.play_arrow,
                color: UIColors.emNearBlack,
              ),
              onPressed: () async {
                if (_isScanning) {
                  await stopLeScan();
                } else {
                  await startLeScan();
                }
              } //_isScanning ? stopLeScan : startLeScan,
              ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: namePrefixController,
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: const Icon(Icons.search),
                  enabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: UIColors.emDarkGrey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: UIColors.emDarkGrey),
                  ),
                  fillColor: UIColors.emGrey,
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() {}); // Update the UI on text change
                },
              ),
            ),
          ),
          (_isScanning && filteredDevices.isEmpty)
              ? CircularProgressIndicator()
              : Expanded(
                  child: filteredDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Scan EM Beacon QR Code',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                  padding: EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue, // Background color
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: scanQrCode,
                                  )),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredDevices.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final leDeviceItem = filteredDevices[index];
                            return ScannedItemWidget(
                              bleDevice: leDeviceItem.bleDevice,
                              advInterval: leDeviceItem.advInterval,
                              onTap: () {
                                stopLeScan();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LeDeviceServices(
                                        leDeviceItem.bleDevice.deviceId,
                                        leDeviceItem.bleDevice.name!),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
