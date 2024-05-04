import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
    ));
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{

// void _showWalkSummary(BuildContext context){
//   showModalBottomSheet(
//     context: context,
//     builder: (BuildContext context) {
//       return Container(
//         height: MediaQuery.of(context).size.height * 0.4,
//         child: Center(
//           child: Text('Walk Summary Content'),
//         )
//       );
//     }
//   );
// }

Widget _buildSummaryField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.0,
          ),
        ),
        Divider(), // Add a divider between fields
      ],
    );
  }

void _showWalkSummary(BuildContext context){
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walk Summary',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0,),
              _buildSummaryField('Crime Type', 'Murder'),
              _buildSummaryField('Length', '7kms'),
              _buildSummaryField('Difficulty', 'Hard'),
              _buildSummaryField('Physical Requirments', 'Walking'),
              _buildSummaryField('Transport Type', 'Public Transport'),
            ],
          ),
        ),
      );
    }
  );
}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CrimeWalkModel(),
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  Flexible(
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(-41.45451960, 145.97066470),
                        initialZoom: 7,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             const Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Expanded(child: FilteredList())
                ]
              ),
            ),
          ]
        ),
      ),
    );
  }
}