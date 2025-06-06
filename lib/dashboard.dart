
import 'package:emconnect/about.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:emconnect/info.dart';
import 'package:emconnect/logs.dart';
import 'package:emconnect/scanner.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _Dashboard();
}

class _Dashboard extends State<Dashboard> {
  int _selectedIndex = 0; // To track the selected index tab
  final List<Widget> _widgetOptions = <Widget>[
    Scanner(),
    Info(),
    Logs(),
    About(),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],

      /* Bottom Navigation Bar */
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: UIColors.emGrey,

        /* Bottom Navigation Bar Items */
        items: [
          //! @@ Navigation Item Scan
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.sensors), Text('Scan')],
            ),
            label: '',
          ),

          //! @@ Navigation Item Info
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.info_outline), Text('Info')],
            ),
            label: '',
          ),

          //! @@ Navigation Item Log
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.list), Text('Log')],
            ),
            label: '',
          ),

          //! @@ Navigation Item About
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.settings_outlined), Text('About')],
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: UIColors.emActionBlue,
        unselectedItemColor: UIColors.emNearBlack,
        onTap: _onItemTapped,
      ),
    );
  }
}
