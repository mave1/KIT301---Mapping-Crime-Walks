import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimewalksapp/api.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // for formatting the date

Future<void> main() async {
  try {
    //WidgetsFlutterBinding and Firebase.initializeApp ensure app is connected to database
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e){
    debugPrint('Failed to initalizeApp');
  }

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
  String currentLatString = ""; //User's current location in string form - latitude
  String currentLongString = ""; //User's current location in string form - Longitude
  Position? _position; //Position object to store user's current location

  // Retrieves the instance of the database into a variable, allowing further manipulation
  final db = FirebaseFirestore.instance;

  // Function that retrieves data from the database, puts it into a lits and then returns it
  Future<List<Map<String, dynamic>>> fetchWalks() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db.collection("Walks").get();

      List<Map<String, dynamic>> walks = [];

      for (var docSnapshot in querySnapshot.docs) {
        walks.add(docSnapshot.data());  // Collect each document's data into the list
      }

      debugPrint("Successfully fetched ${walks.length} walks.");
      return walks;
    } catch (e) {
      debugPrint("Error fetching walks: $e");
      return []; // Return an empty list on error
    }
  }
  
  //function to consume the openrouteservice API
  //TODO: have function take in data to then input into getRouteUrl
  getCoordinates(String lat1, String long1, String lat2, String long2) async {
    String comma = ", ";
    String point1 = long1 + comma + lat1;
    String point2 = long2 + comma + lat2;

    var response = await http.get(getRouteUrl(point1, point2));

    setState(() {
      if(response.statusCode == 200){
        var data = jsonDecode(response.body);
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
      currentLatString = currentLat.toString();
      currentLongString = currentLong.toString();
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
      //mapController.fitCamera(CameraFit.bounds(bounds: bounds), padding: EdgeInsets.all(50.0));
      mapController.fitCamera(CameraFit.bounds(bounds: bounds)); 
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
            getCoordinates("-42.90395", "147.325439", "-42.91", "147.32");
          },
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
      //Extra sub markers until actual child markers are added
      Marker(
        point: const LatLng(-42.91, 147.32),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            //TODO: input actual data into function
            //getCoordinates();
          },
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
      Marker(
        point: const LatLng(-42.92, 147.31),
        width: 40,
        height: 40,
        child: GestureDetector(
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
            getCoordinates("-42.90395", "147.325439", "-42.879601", "147.329874");
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
        child: GestureDetector( 
          onTap: () {
          getCoordinates(currentLatString, currentLongString, "-42.879601", "147.329874");
          },
          child: const Icon(
            Icons.circle,
            size: 15,
            color: Colors.blue,
        )
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