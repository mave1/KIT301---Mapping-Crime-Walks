import 'dart:js';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    ));
}

class MyApp extends StatefulWidget{
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(   
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-42.87936, 147.32941),
                  initialZoom: 7,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions( 
                      markers: [
                        const Marker(
                          point: LatLng(-40.87936, 147.32941), 
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Colors.pink,
                          ))
                      ],
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) => Container(
                          color: Colors.white,
                          child: Text(informationPopup(marker)),
                        ),
                    ))
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
    );
  }
}

informationPopup(Marker marker) {
  return 'popupB';
}


