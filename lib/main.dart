import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';

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

  late double currentLat = 0.0;
  late double currentLong = 0.0;
  Position? _position;

  void _getCurrentLocation() async {
    Position position = await _determinePosition();

    _position = position;

    currentLat = _position!.latitude;
    currentLong = _position!.longitude;
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

      return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    _init();
    super.initState();
  }
  
  _init() {
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(   
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-42.8794, 147.3294),
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker (
                        point: LatLng(currentLat, currentLong),
                        child: Icon(
                          Icons.circle,
                          size: 30,
                          color: Colors.blue,
                        ))
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
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                  
                  //Positioned.fill(
                    //child: Align(
                      //alignment: Alignment.center,
                      //child: _getMarker())
                  //)
                ],
              ),
            ),
          ],
        )),
    );
  }
}


informationPopup(Marker marker) {
  return 'popupB';
}

