import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crimewalksapp/api.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _position; // 用户当前位置
  double currentLat = 0.0; // 当前纬度
  double currentLong = 0.0; // 当前经度
  String currentLatString = ""; // 当前纬度的字符串表示
  String currentLongString = ""; // 当前经度的字符串表示
  final String directionsApiKey = 'AIzaSyB-lR8q6a-AorSxQFuzCLYSTQk-bL0G3hw';  // Directions API 密钥
  List<ll.LatLng> points = []; // 用于绘制路径的地理坐标点列表
  late MapController mapController; // 地图控制器

  // 从 API 获取路径坐标并解码
  Future<void> _getCoordinates(String lat1, String long1, String lat2, String long2) async {
    String comma = ", ";
    String point1 = long1 + comma + lat1;
    String point2 = long2 + comma + lat2;

    // 发起请求并解析响应
    final response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$point1&destination=$point2&key=$directionsApiKey'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      // 提取并解码多段线字符串
      String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
      
      setState(() {
        points = _decodePolyline(encodedPolyline); // 解码后的多段线点
        focusOnRoute(points); // 自动聚焦到加载后的路线
      });
    } else {
      print('Failed to load directions');
    }
  }

  // 解码多段线字符串为 LatLng 列表
  List<ll.LatLng> _decodePolyline(String encoded) {
    List<ll.LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(ll.LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  // 获取用户当前位置的函数
  void _getCurrentLocation() async {
    Position position = await _determinePosition(); // 获取用户当前位置

    // 更新 _position 和其他变量，并刷新 UI
    setState(() {
      _position = position;

      currentLat = _position!.latitude;
      currentLong = _position!.longitude;
      currentLatString = currentLat.toString();
      currentLongString = currentLong.toString();
    });
  }

  // 请求位置权限并获取当前位置
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查是否启用了位置服务
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 请求位置权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 初始化位置监听
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
    _getCurrentLocation(); // 获取用户当前位置信息
    initLocation(); // 初始化位置服务
    mapController = MapController();
    super.initState();
  }

  void focusOnRoute(List<ll.LatLng> routePoints) {
    if (routePoints.isNotEmpty) {
      double minLat = routePoints.map((p) => p.latitude).reduce(min);
      double maxLat = routePoints.map((p) => p.latitude).reduce(max);
      double minLon = routePoints.map((p) => p.longitude).reduce(min);
      double maxLon = routePoints.map((p) => p.longitude).reduce(max);
      LatLngBounds bounds = LatLngBounds(ll.LatLng(minLat, minLon), ll.LatLng(maxLat, maxLon));
      mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50.0)));
    }
  }

  @override
  Widget build(BuildContext context) {
    var markerLocations = <Marker>[]; // Marker list variable used to add markers onto map

    // List of locations within the app
    markerLocations = [
      Marker(
        point: const ll.LatLng(-42.90395, 147.325439),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            _getCoordinates("-42.90395", "147.325439", "-42.879601", "147.329874");
          },
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
      Marker(
        point: const ll.LatLng(-42.879601, 147.329874),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            // TODO: open walk information here
            _getCoordinates("-42.90395", "147.325439", "-42.879601", "147.329874");
          },
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
      // Marker for the user's current location
      Marker(
        point: ll.LatLng(currentLat, currentLong),
        child: GestureDetector(
          onTap: () {
            _getCoordinates(currentLatString, currentLongString, "-42.879601", "147.329874");
          },
          child: const Icon(
            Icons.circle,
            size: 15,
            color: Colors.blue,
          ),
        ),
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
                        initialCenter: ll.LatLng(-42.8794, 147.3294),
                        initialZoom: 11,
                      ),
                      children: [
                        openStreetMapTileLayer, // Input map
                        MarkerLayer(
                          markers: markerLocations,
                        ),
                        if (points.isNotEmpty) // Checking to see if val points is not empty so errors aren't thrown
                          PolylineLayer(
                            polylineCulling: true,
                            polylines: [
                              Polyline(
                                points: points,
                                color: Colors.red,
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        PopupMarkerLayer(
                          options: PopupMarkerLayerOptions(
                            popupController: PopupController(),
                            markers: [
                              const Marker(
                                point: ll.LatLng(-40.87936, 147.32941),
                                child: Icon(
                                  Icons.location_pin,
                                  size: 40,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                            // Popup test marker
                            popupDisplayOptions: PopupDisplayOptions(
                              snap: PopupSnap.markerTop,
                              builder: (BuildContext context, Marker marker) => Container(
                                color: Colors.white,
                                child: Text(informationPopup(marker)),
                              ),
                            ),
                          ),
                        ),
                        copyrightNotice, // Input copyright
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Retrieve OpenStreetMap tile layer
TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.app',
);

// Retrieve copyright notice
RichAttributionWidget get copyrightNotice => RichAttributionWidget(
  attributions: [
    TextSourceAttribution(
      'OpenStreetMap contributors',
      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
    ),
  ],
);

// Placeholder for the marker's popup information
informationPopup(Marker marker) {
  return 'popupB';
}