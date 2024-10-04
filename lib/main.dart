import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crimewalksapp/api.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crimewalksapp/marker_generator.dart';
import 'package:crimewalksapp/user_settings.dart';
import 'package:crimewalksapp/walk_info.dart';
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

GlobalKey <MyAppState> appStateKey = GlobalKey<MyAppState>();
UserSettings userSettings = UserSettings();

Future<void> main() async {
  try {
    //WidgetsFlutterBinding and Firebase.initializeApp ensure app is connected to database
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e){
    debugPrint('Failed to initalizeApp');
  }

  runApp(MaterialApp(
    home: MyApp(key: appStateKey,),
    ));
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  List listOfPoints = []; //List of points on the map to map out route
  List<LatLng> points = []; //List of points to create routes between listOfPoints
  late MapController mapController; // Controller for map
  late double currentLat = 0.0; //User's current location - latitude
  late double currentLong = 0.0;  //User's current location - Longitude
  String currentLatString = ""; //User's current location in string form - latitude
  String currentLongString = ""; //User's current location in string form - Longitude
  Position? _position; //Position object to store user's current location

  //function to consume the openrouteservice API
  //TODO: have function take in data to then input into getRouteUrl
  getCoordinates(String lat, String long) async {
    String comma = ", ";
    String point1 = long + comma + lat;
    String point2 = "147.325439, -42.90395";

    if (lat == "-1" && long == "-1") {
      points = [];
    } else {
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

  //instantiate the user's location with high accuracy
  void initLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    //opens a stream to listen to changes in the user's current location
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings).listen((Position? position) {
        setState(() {
          var beforeUpdate = LatLng(currentLat, currentLong);

          _getCurrentLocation();

          if (userSettings.currentWalk != null && !userSettings.currentWalk!.isCompleted)
          {
            // checkpoint to reach
            CrimeWalkLocation toReach = userSettings.getNextLocation();

            double distTravelled = geologicalDistance(LatLng(currentLat, currentLong), LatLng(toReach.latitude, toReach.longitude));
            userSettings.distanceWalked += geologicalDistance(beforeUpdate, LatLng(currentLat, currentLong));

            // generate route from currentLocation to toReach.
            if (toReach.next != null && true) // replace true with atomic variable that determines if a route is being calculated async (i.e. hasn't returned yet).
            {
              // generate route to seamlessly transition from toReach -> toReach.next when reaching current checkpoint
            }

            if (distTravelled <= 5.0)
            {
              userSettings.checkpointReached();
            }

            // update route
          }
        });
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
                          MarkerGenerator(latitude: currentLat, longitude: currentLong), // all the markers and the current location marker
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
        floatingActionButton: Consumer<CrimeWalkModel>(
          builder: (context, model, _) {
            return userSettings.currentWalk != null ? FloatingActionButton(
              onPressed: () {
                showWalkSummary(context, model, userSettings.currentWalk!);
              },
              child: const Icon(Icons.directions_walk),
            ) : const SizedBox.shrink();
          },
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