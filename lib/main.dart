import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

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
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey <MyAppState> appStateKey = GlobalKey<MyAppState>();
UserSettings userSettings = UserSettings();

Future<void> main() async {
  try {
    //WidgetsFlutterBinding and Firebase.initializeApp ensure app is connected to database
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Failed to initializeApp');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => CrimeWalkModel(),
      child: MaterialApp(
        home: MyApp(key: appStateKey),
      ),
    ),
  );
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
  late CrimeWalkModel model;
  final keyIsFirstLoaded = 'is_first_loaded';

  // Store when requests are made so old routes don't get used.
  HashMap<String, DateTime> requestSent = HashMap<String, DateTime>();
  DateTime pointsUpdated = DateTime.now();
  final LocationSettings locationSettings = const LocationSettings(
                          accuracy: LocationAccuracy.high,
                          distanceFilter: 5,);

  //function to consume the openrouteservice API
  // check is used if you want to make sure that the generated route still points to the correct checkpoint
  //TODO: have function take in data to then input into getRouteUrl
  Future<void> getCoordinates(String lat, String long, bool check) async {
    if (lat == "-1" && long == "-1") {
      setState(() {
        points = [];
        pointsUpdated = DateTime.now();
      });
    } else {
      CrimeWalkLocation? toReach = userSettings.getNextLocation();
      TransportType type = toReach == userSettings.currentWalk!.locations.first ? userSettings.startRouteType! : userSettings.currentWalk!.transportType;

      var url = getRouteUrl("$currentLongString, $currentLatString", "$long, $lat", type);
      requestSent[url.toString()] = DateTime.now();

      http.get(url).then((response) {
        setState(() {
          if(response.statusCode == 200) {
            var data = jsonDecode(response.body);
            listOfPoints = data['features'][0]['geometry']['coordinates'];

            if (!check || (toReach != null && toReach.latitude.toString() == lat && toReach.longitude.toString() == long))
            {
              String? responseUrl = response.request?.url.toString();

              if (requestSent[responseUrl]?.isAfter(pointsUpdated) == true)
              {
                points = listOfPoints.map((e) => LatLng(e[1].toDouble(), e[0].toDouble())).toList();
                pointsUpdated = requestSent[responseUrl]!;

                requestSent.remove(responseUrl);
              }
            }
          }
        });
      }).catchError((error) {});
    }
  }

  //function to retrieve the user's current location
  Future<void> _getCurrentLocation() async {
    _position = await _determinePosition(); //gather the user's current location

    //extract the logitude and latitude from the user's current position
    setState(() {
      currentLat = _position!.latitude; //user's current latitude
      currentLong = _position!.longitude; //user's current longitude
      currentLatString = currentLat.toString();
      currentLongString = currentLong.toString();
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
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: locationSettings.accuracy);
  }

  //instantiate the user's location with high accuracy
  void initLocation() {
    //opens a stream to listen to changes in the user's current location
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings).listen((Position? position) async {
        var beforeUpdate = LatLng(currentLat, currentLong);

        _getCurrentLocation().then((_) {
          setState(() {
            updateRoute(beforeUpdate);
          });
        });
      }
    );
  }

  void updateRoute(LatLng? beforeUpdate)
  {
    if (userSettings.currentWalk != null && !userSettings.isAtEndOfWalk())
    {
      // checkpoint to reach
      CrimeWalkLocation? toReach = userSettings.getNextLocation();

      double distToPoint = geologicalDistance(LatLng(currentLat, currentLong), LatLng(toReach!.latitude, toReach.longitude));
      if (beforeUpdate != null)
      {
        userSettings.distanceWalked += geologicalDistance(beforeUpdate, LatLng(currentLat, currentLong));
      }

      if (distToPoint <= (userSettings.currentWalk!.transportType == TransportType.CAR ? 100.0 : 30.0))
      {
        userSettings.checkpointReached(context, model);
      }

      // get this again in case the next checkpoint has been reached.
      toReach = userSettings.getNextLocation();
      if (toReach != null)
      {
        getCoordinates(toReach.latitude.toString(), toReach.longitude.toString(), true);
      }
    }
  }

  @override
  void initState() {
    _getCurrentLocation().then((_) => initLocation()); //collect the user's current location
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
      mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100.0)));
    }
  }


  contentWarning(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLoaded = prefs.getBool(keyIsFirstLoaded);
    if (isFirstLoaded == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: const Text("CONTENT WARNING", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
            content: const Text("The following tours include details about historical crimes. Although graphic details are not included some users may find the specifics about some cases challenging. If you have any concerns, please exit the application immediately.\n\nPlease respect that the cases presented involved real people. This app and the tours contained within should be used for informative and educative purposes.\n\nWhile these crimes are historical and occurred over 50 years ago, in some rural locations local communities are still very aware of the incidents. Please avoid harassing local residents about people involved in the following cases."),
            actions: <Widget>[
              FilledButton(
                child: const Text("I Disagree"),
                onPressed: ()=> exit(0),
              ),
              FilledButton(
                child: const Text("I Agree"),
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                  prefs.setBool(keyIsFirstLoaded, false);
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () => contentWarning(context));
    return ChangeNotifierProvider(
      create: (context) {
        model = CrimeWalkModel();
        return model;
      },
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
                          if(points.isNotEmpty && userSettings.currentWalk != null && !userSettings.isAtEndOfWalk())  //checking to see if val points is not empty so errors aren't thrown
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                    points: points,
                                    color: Colors.red,
                                    strokeWidth: 5
                                )
                              ],
                            ),
                          MarkerGenerator(latitude: currentLat, longitude: currentLong), // all the markers and the current location marker
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