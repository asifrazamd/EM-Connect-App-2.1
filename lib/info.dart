import 'package:emconnect/data/uicolors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, canLaunch, canLaunchUrl, launch, launchUrl;

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _Info();
}

class _Info extends State<Info> {
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.emGrey,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Info',
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing Beacon tab content
              _buildSmallHeading('Beacon Details'),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('DOCUMENT'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard3('Factsheet (coming soon)', ''),
              _buildCard3('Datasheet (coming soon)', ''),
              _buildCard3('Flyer (coming soon)', ''),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('VIDEO'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard3('Starter Kit Presentation (coming soon)', ''),
              _buildCard3('Starter Kit Tutorial (coming soon)', ''),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.language_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('RESOURCE'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard('em Beacons', 'https://sclabsglobal.com/EmBeacons'),
              _buildCard('em Developer Forum',
                  'https://sclabsglobal.com/EmBeaconDeveloperForum'),

              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('PURCHASE'),
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
                  color: UIColors.emActionBlue,
                  margin: EdgeInsets.all(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8), // Add padding for inner content
                    constraints: BoxConstraints(
                      minHeight: 35, // Minimum height to maintain layout
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              'Order em Beacons (coming soon)',
                              style: TextStyle(
                                overflow: TextOverflow
                                    .ellipsis, // Handle long text gracefully
                                color: UIColors.emGrey,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: UIColors.emDarkGrey,
                          ),
                          onPressed: () async {
                            final Uri url = Uri.parse('');
                            _launchURL(url);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              _buildSmallHeading('em | bleu Details'),

              // Em|bleu tab content
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('DOCUMENT (em | bleu)'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard(
                  'Factsheet', 'https://sclabsglobal.com/EmBleuFactsheet'),
              _buildCard3('Datasheet',
                  'https://www.emmicroelectronic.com/sites/default/files/products/datasheets/9305-DS%201.pdf'),
              _buildCard3('Flyer (coming soon)', ''),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('VIDEO (em | bleu)'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard3('Starter Kit Presentation (coming soon)', ''),
              _buildCard3('Starter Kit Tutorial (coming soon)', ''),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.language_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('RESOURCE (em | bleu)'),
                ],
              ),
              SizedBox(height: 10),
              _buildCard('em | bleu website',
                  'https://sclabsglobal.com/EmBleuWebsite'),
              _buildCard('em Developer Forum',
                  'https://sclabsglobal.com/EmBleuDeveloperForum'),
              SizedBox(height: 40),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: UIColors.emDarkGrey,
                  ),
                  SizedBox(width: 10),
                  _buildHeading('PURCHASE (em | bleu)'),
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
                  color: UIColors.emActionBlue,
                  margin: EdgeInsets.all(1),
                  child: SizedBox(
                    width: 500, // Set your desired width
                    height: 40, // Set your desired height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              'Order em | bleu',
                              style: TextStyle(
                                color: UIColors
                                    .emNotWhite, // Change this to your desired color
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: UIColors.emNotWhite,
                          ),
                          onPressed: () async {
                            final Uri url = Uri.parse(
                                'https://sclabsglobal.com/OrderEmBleu');
                            _launchURL(url);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 8), // Add padding for inner content
        constraints: BoxConstraints(
          minHeight: 35, // Minimum height to maintain layout
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                softWrap: true,
                overflow: TextOverflow.ellipsis, // Handle long text gracefully
                style: TextStyle(
                  color: UIColors.emDarkGrey, // Set text color to grey
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

Widget _buildSmallHeading(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: UIColors.emNearBlack,
        ),
      ),
      SizedBox(height: 4), // Small spacing between text and underline
    ],
  );
}

Widget _buildHeading(String title) {
  return Text(
    title,
    style: TextStyle(fontSize: 15, color: UIColors.emDarkGrey),
  );
}

Widget _buildCard(String name, String link) {
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
                  child: InkWell(
                    child: Text(name),
                  )),
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

Future<void> _launchURL(Uri url) async {
  if (true) {
    await launchUrl(url);
  }
}
