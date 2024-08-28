import 'dart:math';

import 'package:latlong2/latlong.dart';

const String baseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking';
const String apiKey = '5b3ce3597851110001cf624869c9a86867464b2e89cd132a9bc84986';

getRouteUrl(String startPoint, String endPoint) {
  return Uri.parse('$baseUrl?api_key=$apiKey&start=$startPoint&end=$endPoint');
}

double geologicalDistance(LatLng loc1, LatLng loc2)
{
  // Radius of the Earth in meters
  double R = 6371.0 * 1000;

  // Convert latitude and longitude from degrees to radians

  double lat1 = degToRadian(loc1.latitude);
  double lon1 = degToRadian(loc1.longitude);
  double lat2 = degToRadian(loc2.latitude);
  double lon2 = degToRadian(loc2.longitude);

  // Differences between the coordinates
  double difLat = lat2 - lat1;
  double difLon = lon2 - lon1;

  // Haversine formula
  double a = (sin(difLat / 2) * sin(difLat / 2)) + cos(lat1) * cos(lat2) * (sin(difLon / 2) * sin(difLon / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in kilometers
  double distance = R * c;

  return distance;
}