const String baseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking';
const String apiKey = '5b3ce3597851110001cf624869c9a86867464b2e89cd132a9bc84986';

getRouteUrl(String startPoint, String endPoint) {
  return Uri.parse('$baseUrl?api_key=$apiKey&start=$startPoint&end=$endPoint');
}