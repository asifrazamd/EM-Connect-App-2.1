import 'dart:typed_data';
import 'package:flutter/material.dart';

int parseInput(String input) {
  if (input.startsWith("0x") || input.startsWith("0X")) {
    return int.parse(input.substring(2), radix: 16);
  } else {
    return int.parse(input);
  }
}

bool isHexInputFormat(String format) {
  return format == 'Byte Array' || format.contains('UInt') || format.contains('SInt');
}

Future<void> showWriteDialog(
  BuildContext context,
  String serviceUuid,
  String charUuid, {
  required Future<void> Function(Uint8List value) onWrite,
  required void Function(String type, List<int> bytes) addLog,
}) async {
  String inputValue = '';
  String selectedFormat = 'Byte Array';
  final formats = [
    'Text (UTF-8)',
    'Byte',
    'Byte Array',
    'UInt8',
    'UInt16 (Little Endian)',
    'UInt16 (Big Endian)',
    'UInt32 (Little Endian)',
    'UInt32 (Big Endian)',
    'SInt8',
    'SInt16 (Big Endian)',
    'SInt32 (Little Endian)',
    'SInt32 (Big Endian)',
    'Float16 (IEEE-11073)',
    'Float32 (IEEE-11073)',
  ];

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Write value'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isHexInputFormat(selectedFormat))
                      const Text(
                        '0x ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        keyboardType: selectedFormat == 'Text (UTF-8)'
                            ? TextInputType.text
                            : TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Enter value',
                        ),
                        onChanged: (value) => inputValue = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedFormat,
                      isDense: true,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      alignment: Alignment.centerRight,
                      items: formats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(
                            format,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedFormat = value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  List<int> bytes = [];

                  try {
                    debugPrint("Input Value: $inputValue");

                    switch (selectedFormat) {
                      case 'Text (UTF-8)':
                        bytes = inputValue.codeUnits;
                        break;

                      case 'Byte':
                      case 'UInt8': {
                        int val = parseInput(inputValue);
                        if (val < 0 || val > 255) {
                          throw Exception("UInt8 out of range");
                        }
                        bytes = [val];
                        break;
                      }

                      case 'Byte Array': {
                        String cleaned = inputValue.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
                        if (cleaned.length % 2 != 0) {
                          throw Exception("Hex string length must be even");
                        }
                        bytes = [];
                        for (int i = 0; i < cleaned.length; i += 2) {
                          String byteStr = cleaned.substring(i, i + 2);
                          int byteVal = int.parse(byteStr, radix: 16);
                          bytes.add(byteVal);
                        }
                        debugPrint("Byte Array parsed as HEX: $bytes");
                        break;
                      }

                      case 'UInt16 (Little Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [val & 0xFF, (val >> 8) & 0xFF];
                        break;
                      }

                      case 'UInt16 (Big Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [(val >> 8) & 0xFF, val & 0xFF];
                        break;
                      }

                      case 'UInt32 (Little Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [
                          val & 0xFF,
                          (val >> 8) & 0xFF,
                          (val >> 16) & 0xFF,
                          (val >> 24) & 0xFF
                        ];
                        break;
                      }

                      case 'UInt32 (Big Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [
                          (val >> 24) & 0xFF,
                          (val >> 16) & 0xFF,
                          (val >> 8) & 0xFF,
                          val & 0xFF
                        ];
                        break;
                      }

                      case 'SInt8': {
                        int val = parseInput(inputValue);
                        if (val < -128 || val > 127) {
                          throw Exception("SInt8 out of range");
                        }
                        bytes = [val & 0xFF];
                        break;
                      }

                      case 'SInt16 (Big Endian)': {
                        int val = parseInput(inputValue);
                        if (val < -32768 || val > 32767) {
                          throw Exception("SInt16 out of range");
                        }
                        bytes = [(val >> 8) & 0xFF, val & 0xFF];
                        break;
                      }

                      case 'SInt32 (Little Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [
                          val & 0xFF,
                          (val >> 8) & 0xFF,
                          (val >> 16) & 0xFF,
                          (val >> 24) & 0xFF
                        ];
                        break;
                      }

                      case 'SInt32 (Big Endian)': {
                        int val = parseInput(inputValue);
                        bytes = [
                          (val >> 24) & 0xFF,
                          (val >> 16) & 0xFF,
                          (val >> 8) & 0xFF,
                          val & 0xFF
                        ];
                        break;
                      }

                      case 'Float16 (IEEE-11073)': {
                        int val = parseInput(inputValue); // Simulated as 2-byte int
                        bytes = [val & 0xFF, (val >> 8) & 0xFF];
                        break;
                      }

                      case 'Float32 (IEEE-11073)': {
                        double floatVal = double.parse(inputValue);
                        final byteData = ByteData(4)
                          ..setFloat32(0, floatVal, Endian.little);
                        bytes = byteData.buffer.asUint8List();
                        break;
                      }

                      default:
                        bytes = inputValue.codeUnits;
                    }

                    addLog("Sent", bytes);

                    await onWrite(Uint8List.fromList(bytes));

                    debugPrint('Write command sent successfully');
                    await Future.delayed(const Duration(milliseconds: 500));
                  } catch (e) {
                    debugPrint('Write Error: $e');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid input: $e')),
                    );
                  }
                },
                child: const Text('SEND'),
              ),
            ],
          );
        },
      );
    },
  );
}
