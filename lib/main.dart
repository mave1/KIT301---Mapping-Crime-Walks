import 'dart:async';

import 'package:crimewalksapp/api.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  List listOfPoints = []; //List of points on the map to map out route
  List<LatLng> points = []; //List of points to create routes between listOfPoints
  late double currentLat = 0.0;
  late double currentLong = 0.0;
  Position? _position;

  //function to consume the openrouteservice API
  //TODO: have function take in data to then input into getRouteUrl
  getCoordinates() async {
    //temporary entry to test code
    var responce = await http.get(getRouteUrl("147.325439, -42.90395", "147.329874, -42.879601"));

    setState(() {
      if(responce.statusCode == 200){
        var data = jsonDecode(responce.body);
        listOfPoints = data['features'][0]['geometry']['coordinates'];
        points = listOfPoints.map((e) => LatLng(e[1].toDouble(), e[0].toDouble())).toList();
      }
    });
  }

  void _getCurrentLocation() async {
    Position position = await _determinePosition();

    setState(() {
      _position = position;

      currentLat = _position!.latitude;
      currentLong = _position!.longitude;
    });

  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

      Position current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return current;
  }

  void initLocation() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings).listen((Position? position) { 
        _getCurrentLocation();
      });
  }

  @override
  void initState() {
    _getCurrentLocation();
    initLocation();
    super.initState();
  }

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
            //TODO: input actual data into function
            getCoordinates();
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
      Marker (
        point: LatLng(currentLat, currentLong),
        child: const Icon(
          Icons.circle,
          size: 15,
          color: Colors.blue,
        )
      )
    ];

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
                          initialCenter: LatLng(-42.8794, 147.3294),
                          initialZoom: 11,
                        ),
                        children: [
                          openStreetMapTileLayer, //input map
                          MarkerLayer(
                            markers: markerLocations,
                          ),
                          if(points.isNotEmpty)  //checking to see if val points is not empty so errors aren't thrown
                            PolylineLayer(
                              polylineCulling: true,
                              polylines: [
                                Polyline(
                                    points: points,
                                    color: Colors.red,
                                    strokeWidth: 5
                                )
                              ],
                            ),
                          PopupMarkerLayer(
                              options: PopupMarkerLayerOptions(
                                  markers: [
                                    const Marker(
                                        point: LatLng(-40.87936, 147.32941),
                                        child: Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Colors.red,
                                        ))
                                  ],
                                  popupDisplayOptions: PopupDisplayOptions(
                                    builder: (BuildContext context, Marker marker) => Container(
                                      color: Colors.white,
                                      child: Text(informationPopup(marker)),
                                    ),
                                  ))
                          ),
                          copyrightNotice, // input copyright
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

informationPopup(Marker marker) {
  return 'popupB';
}