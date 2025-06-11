import 'dart:async';
import 'package:emconnect/char.dart';
import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:emconnect/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
      //await BLECharacteristicHelper.loadCharacteristicsFromYaml(); // Load once


  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.light(),
      themeMode: ThemeMode.system,
      home: const SplashScreenPage(),
    ),
  );
}

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    Timer(
        Duration(seconds: 1),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Dashboard())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emNotWhite,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "em | connect",
                style: TextStyle(
                  color: UIColors.emtitle,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Image.asset(
                  'assets/splash.png',
                  width: 220,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
