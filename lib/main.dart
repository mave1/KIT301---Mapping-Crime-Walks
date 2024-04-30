import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

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
  @override
  Widget build(BuildContext context) {
    var markerLocations = <Marker>[]; // marker list variable used to add markers onto map

    // list of locations within the app
    markerLocations = [
      Marker(
        point: const LatLng(-42.90395, 147.325439), 
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            // TODO: open walk information here
          },
          child: const Icon(
          Icons.location_pin,
          size: 40,
          color: Colors.red,
          ),
        ),
      ),
      Marker(
        point: const LatLng(-42.879601, 147.329874), 
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            // TODO: open walk information here
          },
          child: const Icon(
          Icons.location_pin,
          size: 40,
          color: Colors.red,
          ),
        ),
      ),
    ];

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(   
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-41.45451960, 145.97066470),
                  initialZoom: 7,
                ),
                children: [
                  openStreetMapTileLayer, //input map
                  copyrightNotice, // input copyright
                  MarkerLayer(markers: markerLocations), //input markers
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// retrieve openstreetmap map
TileLayer get openStreetMapTileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.app',
);

// retrieve copyright notice
RichAttributionWidget get copyrightNotice => RichAttributionWidget(
  attributions: [
    TextSourceAttribution(
      'OpenStreetMap contributors',
      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
    ),
  ],
);