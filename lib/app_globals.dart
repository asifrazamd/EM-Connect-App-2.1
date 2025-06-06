import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:universal_ble/universal_ble.dart';

String sharedText = "Initial Data";
final List<String> _logs = [];

Future<void> _writeLogToFile(String logEntry) async {
  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/logs.txt');
  await logFile.writeAsString(logEntry, mode: FileMode.append);
}

void addLog(String type, dynamic data) async {
  DateTime now = DateTime.now();
  String timestamp =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  String logEntry = '[$timestamp]:$type: ${data.toString()}\n';
  _logs.add(logEntry);
  await _writeLogToFile(logEntry);
}






class LeDeviceItem {
  late BleDevice bleDevice;
  int advInterval = 0;
  int timeStamp = 0;
}
