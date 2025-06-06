import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:emconnect/data/uicolors.dart';

final Map<String, Color> deviceColors = {};

Color getColorForDevice(String deviceId) {
  // Check if the device already has an assigned color
  if (deviceColors.containsKey(deviceId)) {
    return deviceColors[deviceId]!;
  }

  // If not, generate a new random color and store it
  final Random random = Random();
  Color newColor = Color.fromARGB(
    255, // Fully opaque
    random.nextInt(256), // Random red value
    random.nextInt(256), // Random green value
    random.nextInt(256), // Random blue value
  );

  deviceColors[deviceId] = newColor; // Store the color for future use
  return newColor;
}

class ScannedItemWidget extends StatelessWidget {
  final BleDevice bleDevice;
  final int advInterval;

  final VoidCallback? onTap;
  const ScannedItemWidget(
      {super.key,
      required this.bleDevice,
      required this.advInterval,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    String? deviceName = bleDevice.name;
    String? macID = bleDevice.deviceId;
    debugPrint(bleDevice.deviceId);

    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 0, end: 0, top: 0, bottom: 0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(10),
                    alignment: Alignment.center,
                    backgroundColor: UIColors.emGreen,
                    foregroundColor: UIColors.emNearBlack,
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    size: 30,
                  )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Align items in the row
                      children: [
                        Container(
                          constraints: BoxConstraints.tightFor(width: 150),
                          child: Text(
                            deviceName!,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: UIColors.emNotWhite,
                                backgroundColor: UIColors.emActionBlue,
                                elevation: 4.0,
                                shadowColor: UIColors.emNearBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Text('Connect'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (Platform.isAndroid)
                      Text(
                        'Mac Address: $macID',
                        style: TextStyle(fontSize: 12),
                      ),
                    buildSignalAndInterval(bleDevice.rssi, advInterval),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSignalAndInterval(int? rssi, int? advInterval) {
    return Row(
      children: [
        getSignalIcon(rssi),
        Text(
          ' $rssi',
          style: TextStyle(fontSize: 12),
        ),
        Padding(padding: EdgeInsets.fromLTRB(30, 0, 0, 0)),
        Transform.rotate(
          angle: 45 * 3.14 / 180,
          child: Icon(
            Icons.open_in_full,
            color: UIColors.emDarkGrey,
            size: 18,
          ),
        ),
        Text(
          ' $advInterval ms',
          style: TextStyle(fontSize: 12),
        )
      ],
    );
  }

  Icon getSignalIcon(int? rssi) {
    double towerSize = 15.0;
    if (rssi! >= -60) {
      return Icon(
        Icons.signal_cellular_4_bar,
        color: UIColors.rssigreen,
        size: towerSize,
      ); // Excellent
    } else if (rssi >= -90) {
      return Icon(
        Icons.network_cell,
        color: UIColors.emYellow,
        size: towerSize,
      ); // Good
    } else {
      return Icon(
        Icons.signal_cellular_null,
        color: UIColors.emRed,
        size: towerSize,
      ); // Poor
    }
  }
}
