/**import 'package:crimewalksapp/api.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


class MarkerLocations {
  //var mkrLoc = <Marker>[]; // marker list variable used to add markers onto map

  // list of locations within the app
  var mkrLoc = [
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
    /**Marker (
      point: LatLng(currentLat, currentLong),
      child: const Icon(
        Icons.circle,
        size: 15,
        color: Colors.blue,
      )
    )**/
  ];
}**/