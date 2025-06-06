import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emconnect/data/scan_filter_model.dart';
import 'package:emconnect/data/uicolors.dart';

class ScanFilterWidget extends StatefulWidget {
  final String mac;
  final double rssi;
  const ScanFilterWidget(this.mac, this.rssi, {super.key});

  @override
  State<ScanFilterWidget> createState() => _ScanFilterWidgetState();
}

class _ScanFilterWidgetState extends State<ScanFilterWidget> {
  double rssiValue = 100;
  TextEditingController macFilterController = TextEditingController();
  TextEditingController namePrefixController = TextEditingController();
  TextEditingController macPrefixController = TextEditingController();
  TextEditingController manufacturerDataController = TextEditingController();

  @override
  void initState() {
    super.initState();

    rssiValue = 0 - widget.rssi;
    macFilterController.text = widget.mac;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context)
          .viewInsets
          .copyWith(left: 20, right: 20, top: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Platform.isAndroid)
            Row(
              children: [
                Icon(Icons.key, size: 14),
                Text(' MAC ADDRESS',
                    style:
                        TextStyle(fontSize: 15, color: UIColors.emNearBlack)),
              ],
            ),
          SizedBox(
            height: 10,
          ),
          if (Platform.isAndroid)
            Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: 40,
                    child:
                        // Consumer<BleScanState>(
                        //   builder: (context, scanState, child) {
                        //     // Dynamically update the controller text to reflect state changes
                        //     macFilterController.text = scanState.macFilter;

                        //     return
                        TextFormField(
                      controller: macFilterController,
                      decoration: InputDecoration(
                        hintText: 'Enter Mac Address',
                        contentPadding: EdgeInsets.all(10),
                        hintStyle: TextStyle(color: UIColors.emDarkGrey),
                        enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: UIColors.emDarkGrey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: UIColors.emDarkGrey),
                        ),
                        fillColor: UIColors.emNotWhite,
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    //   },
//),
                  ),
                ),
              ],
            ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Icon(
                Icons.network_cell,
                size: 14,
              ),
              Text(
                ' RSSI',
                style: TextStyle(fontSize: 14, color: UIColors.emNearBlack),
              ),
            ],
          ),
          Slider(
            activeColor: UIColors.emActionBlue,
            value: rssiValue,
            min: 40,
            max: 100,
            divisions: 60,
            label: (-rssiValue).toString(),
            onChanged: (double value) {
              setState(() {
                rssiValue = value;
              });
            },
          ),
          Text('-${rssiValue.round()} dBm', style: TextStyle(fontSize: 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 120,
                child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        rssiValue = 100;
                        macFilterController.text = "";
                        // Update the state in BleScanState to reset the mac filter
                        // context.read<BleScanState>().updateFilters(
                        //       "", // Reset MAC filter to empty
                        //       context.read<BleScanState>().nameFilter,
                        //       context.read<BleScanState>().rssiFilter,
                        //     );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: UIColors.emNearBlack,
                      backgroundColor: UIColors.emGrey,
                      elevation: 4.0,
                      shadowColor: UIColors.emNearBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: Text('Reset')),
              ),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(
                            context,
                            ScanFilterModel(macFilterController.text.toString(),
                                -rssiValue.toInt()));
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: UIColors.emNotWhite,
                      backgroundColor: UIColors.emActionBlue,
                      elevation: 4.0,
                      shadowColor: UIColors.emNearBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: Text('Apply')),
              ),
            ],
          ),
          SizedBox(height: 10)
        ],
      ),
    );
  }
}
