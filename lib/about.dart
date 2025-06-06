import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, canLaunch, canLaunchUrl, launch, launchUrl;

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _About();
}

class _About extends State<About> {
  bool isScanning = false;

  Future<Map<String, String>> _getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version, // Get the version number
      'buildNumber': packageInfo.buildNumber, // Get the build number
    };
  }

  Future<void> _launchURL(Uri url) async {
    if (true) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emNotWhite,
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(
              color: UIColors.emNearBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: UIColors.emGrey,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('ABOUT THIS APP'),
                ],
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.zero,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8), // Adjust the radius as needed
                  ),
                  color: UIColors.emNotWhite,
                  margin: EdgeInsets.all(1),
                  child: SizedBox(
                    width: 500, // Set your desired width
                    height: 35, // Set your desired height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Row(
                                children: [
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Text('Application Version'),
                                    ),
                                  ),
                                  FutureBuilder<Map<String, String>>(
                                    future: _getAppInfo(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error');
                                      } else {
                                        final version =
                                            snapshot.data?['version'] ?? 'N/A';
                                        final buildNumber =
                                            snapshot.data?['buildNumber'] ??
                                                'N/A';
                                        // return Text('$version (Build: $buildNumber)');
                                        return Text('$version($buildNumber)');
                                      }
                                    },
                                  ),
                                  SizedBox(width: 20),
                                ],
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildCard1('Feedback & Report Issue', ''),
              _buildCard1('Acknowledgements', ''),
              _buildCard2(
                  'Privacy Policy', 'https://sclabsglobal.com/PrivacyPolicy'),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 10),
                  _buildHeading('WHO ARE WE'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard2('About Us', 'https://sclabsglobal.com/AboutUs'),
              _buildCard3('Services and Capabilities', ''),
              _buildCard3('Project Inquiry', ''),
              SizedBox(height: 10),
              Center(
                child: Text(
                  'Copyright © 2025 EM Microelectronic - Marin SA',
                  style: TextStyle(color: UIColors.emDarkGrey, fontSize: 12),
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  "em | connect",
                  style: TextStyle(
                      color: UIColors.emtitle,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 15, color: UIColors.emDarkGrey),
    );
  }

  Widget _buildCard1(String name, String link) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Adjust the radius as needed
        ),
        color: UIColors.emNotWhite,
        margin: EdgeInsets.all(1),
        child: SizedBox(
          width: 500, // Set desired width
          height: 35, // Set desired height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: UIColors.emDarkGrey, // Set text color to grey
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                color: UIColors.emDarkGrey,
                onPressed: () async {
                  final Uri url = Uri.parse(link);
                  _launchURL(url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard2(String name, String link) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Adjust the radius as needed
        ),
        color: UIColors.emNotWhite,
        margin: EdgeInsets.all(1),
        child: SizedBox(
          width: 500,
          height: 35,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    name,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () async {
                  final Uri url = Uri.parse(link);
                  _launchURL(url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard3(String name, String link) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Adjust the radius as needed
        ),
        color: UIColors.emNotWhite,
        margin: EdgeInsets.all(1),
        child: SizedBox(
          width: 500, // Set your desired width
          height: 35, // Set your desired height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: UIColors.emDarkGrey, // Set text color to grey
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                color: UIColors.emDarkGrey,
                onPressed: () async {
                  final Uri url = Uri.parse(link);
                  _launchURL(url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
