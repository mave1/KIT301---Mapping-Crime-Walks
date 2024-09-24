import 'package:crimewalksapp/crime_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class MarkerGenerator extends StatefulWidget
{
  const MarkerGenerator({super.key, required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  State<StatefulWidget> createState() => _MarkerGeneratorState();
}

class _MarkerGeneratorState extends State<MarkerGenerator>
{
  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    return Consumer<CrimeWalkModel>(builder: createMenu);
  }

  // Generate all the markers including the current location marker
  List<Marker> grabMarkers(CrimeWalkModel model)
  {
    var markerLocations = <Marker>[]; // marker list variable used to add markers onto map

    // Only grab the markers that are used based on current filtering rules.
    model.generateMarkers(context);

    markerLocations.addAll(model.markers);

    // Add the marker that identifies the current user location last so it is rendered on top of the other markers.
    markerLocations.add(Marker (
        point: LatLng(widget.latitude, widget.longitude),
        child: const Icon(
          Icons.circle,
          size: 20,
          color: Colors.blue
        )
      )
    );

    return markerLocations;
  }

  Widget createMenu(BuildContext context, CrimeWalkModel model, _)
  {
    // Return a layer with all the markers placed on the map.
    return MarkerLayer(markers: grabMarkers(model));
  }
}