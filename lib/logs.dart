import 'dart:io';
import 'dart:async';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _Logs();
}

class _Logs extends State<Logs> with WidgetsBindingObserver {
  bool isScanning = false;
  List<String> logs = [];

  Future<void> _deleteLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/logs.txt');
    if (await logFile.exists()) {
      await logFile.delete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _deleteLogFile(); // Delete the log file when the app is paused or detached
    }
  }

  // Clear the logs in the UI and the log file
  Future<void> _clearLogs() async {
    setState(() {
      logs.clear(); // Clear the logs in the UI
    });

    // Also delete the log file
    _deleteLogFile();
  }

  Future<List<String>> _readLogs() async {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/logs.txt');

    if (await logFile.exists()) {
      String contents = await logFile.readAsString();
      List<String> connections = contents.split('--Connection Start--');
      if (connections.isNotEmpty) {
        return connections.last
            .split('\n')
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Future<void> _loadLogs() async {
    List<String> temp = await _readLogs();

    setState(() {
      logs = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLogs();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emGrey,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text("Logs",
            style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
        backgroundColor: UIColors.emGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              _clearLogs(); // Trigger the clear functionality
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              logs[index],
              style: TextStyle(
                fontSize: 13.0, // Set the font size here
                color: UIColors.emNearBlack, // Optional: Adjust the color
              ),
            ),
          );
        },
      ),
    );
  }
}
