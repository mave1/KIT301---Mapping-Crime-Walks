import 'dart:async';
import 'dart:math';

import 'package:crimewalksapp/api.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:crimewalksapp/marker_generator.dart';
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

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  List listOfPoints = []; //List of points on the map to map out route
  List<LatLng> points = []; //List of points to create routes between listOfPoints
  late MapController mapController; // Controller for map
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
        focusOnRoute(points); // Auto-focus on the route after data is loaded
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
    const LocationSettings locationSettings = LocationSettings(
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
                          // MarkerLayer(
                          //   markers: markerLocations,
                          // ),
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
                                    Marker(
                                        point: const LatLng(-40.87936, 147.32941),
                                        child: GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return IntrinsicHeight(
                                                  child: Column(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                                                        child:
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8.0),
                                                              color: Colors.white,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Text("Walk to view a crime."),
                                                                SizedBox(
                                                                  height: 200,
                                                                  child: Text("This is a description for the walk.")
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(left: 8, right: 4, bottom: 8),
                                                                      child: ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(10),
                                                                          ),
                                                                        ),
                                                                        onPressed: () => {},
                                                                        child: const Text("End Walk")
                                                                      )
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        Padding(
                                                                          padding: const EdgeInsets.only(left: 8, right: 4, bottom: 8),
                                                                          child: ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                            ),
                                                                            onPressed: () => {},
                                                                            child: const Text("Previous")
                                                                          )
                                                                        ),
                                                                        Padding(
                                                                            padding: const EdgeInsets.only(left: 4, bottom: 8, right: 8),
                                                                            child: ElevatedButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(10),
                                                                                ),
                                                                              ),
                                                                              onPressed: () => {},
                                                                              child: const Text("Next")
                                                                            )
                                                                        )
                                                                      ]
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ),
                                                    ]
                                                  )
                                                );
                                            });
                                          },
                                          child: const Icon(
                                            Icons.location_pin,
                                            size: 40,
                                            color: Colors.red,
                                          ),
                                        )
                                    )
                                  ],
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

informationPopup(Marker marker) {
  return 'popupB';
}