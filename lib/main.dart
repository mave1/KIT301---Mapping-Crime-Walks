import 'dart:async';
import 'dart:math';

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
  late MapController mapController; // Controller for map
  late double currentLat = 0.0; //User's current location - latitude
  late double currentLong = 0.0;  //User's current location - Longitude
  Position? _position; //Position object to store user's current location

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
        focusOnRoute(points); // Auto-focus on the route after data is loaded
      }
    });
  }

  //function to retrieve the user's current location
  void _getCurrentLocation() async {
    Position position = await _determinePosition(); //gather the user's current location

    //extract the logitude and latitude from the user's current position
    setState(() {
      _position = position;

      currentLat = _position!.latitude; //user's current latitude
      currentLong = _position!.longitude; //user's current longitude
    });

  }

  //a function to ask location services permissions and await the user's current location
  Future<Position> _determinePosition() async {
    bool serviceEnabled; //if the location services are enabled
    LocationPermission permission; //user's permission given to location services

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    //if permissions are denied, do not collect the user's current location thi time but still ask next time the app loads.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied'); //return error message
      }
    }

    // Permissions are denied forever, handle appropriately - never ask for permission again.
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.'); //return error message
    }

      //store and return the user's current location if the proper permissions are given
      Position current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return current;
  }

  //instatciate the user's location with high accuracy 
  void initLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    //opens a stream to listen to changes in the user's current location
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings).listen((Position? position) { 
        _getCurrentLocation();
      });
  }

  @override
  void initState() {
    _getCurrentLocation(); //collect the user's current location
    initLocation(); 
    mapController = MapController();
    super.initState();
  }

  void focusOnRoute(List<LatLng> routePoints) {
    if (routePoints.isNotEmpty) {
      double minLat = routePoints.map((p) => p.latitude).reduce(min);
      double maxLat = routePoints.map((p) => p.latitude).reduce(max);
      double minLon = routePoints.map((p) => p.longitude).reduce(min);
      double maxLon = routePoints.map((p) => p.longitude).reduce(max);
      LatLngBounds bounds = LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
      mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50.0)));
    }
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
      //Marker for the user's current location
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
                        mapController: mapController,
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
                                  popupController: PopupController(),
                                  markers: [
                                    const Marker(
                                        point: LatLng(-40.87936, 147.32941),
                                        child: Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Colors.red,
                                        ))
                                  ],
                                  //popup test marker
                                  popupDisplayOptions: PopupDisplayOptions(
                                    snap: PopupSnap.markerTop,
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

//placeholder for the marker's popup information
informationPopup(Marker marker) {
  return 'popupB';
}