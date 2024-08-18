import 'dart:collection';

import 'package:crimewalksapp/crime_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// All possible crime types and a default ALL value that is used for filtering
enum CrimeType
{
  ALL
}

// TODO: All possible lengths and a default ALL value that is used for filtering
enum Length
{
  ALL
}

// All possible locations for a walk and a default ALL value that is used for filtering
enum Location
{
  ALL,
  HOBART,
  LAUNCESTON
}

// All possible difficulty levels for the walk and a default ALL value that is used for filtering
enum Difficulty
{
  ALL
}

// All possible types of transport required for participating in the crime walk and a default ALL value that is used for filtering
enum TransportType
{
  ALL,
  WALK,
  CAR
}

class CrimeWalk
{
  CrimeWalk({required this.name, required this.description, required this.yearOccurred, required this.crimeType, required this.length, required this.location, required this.difficulty, required this.transportType});

  String name;
  String description;
  int yearOccurred;
  CrimeType crimeType;
  Length length;
  Location location;
  Difficulty difficulty;
  TransportType transportType;
  final locations = LinkedList<CrimeWalkLocation>();

  // Build a journey from all the locations
  // TODO: build a path between each point
  List<Marker> buildJourney(BuildContext context, bool filtered)
  {
    var markers = <Marker>[];

    for (var location in locations)
    {
      markers.add(location.createPOI(context, filtered));
    }

    return markers;
  }
}

final class CrimeWalkLocation extends LinkedListEntry<CrimeWalkLocation>
{
  CrimeWalkLocation({required this.latitude, required this.longitude, required this.description, required this.color});

  double latitude;
  double longitude;
  Color color;

  String description;

  // The menu that appears when you click on a marker.
  Future buildMenu(BuildContext context)
  {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Walk Summary',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(), // Add a divider between fields
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
                const Divider(), // Add a divider between fields
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton(onPressed: onPressed(context, previous), child: const Text('Previous')),
                        FilledButton(onPressed: onPressed(context, next), child: const Text('Next')),
                      ]
                  ),
                ),
                // Only show the start walk button if it is the start of the walk
                previous == null ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FilledButton(onPressed: () => print("Walk started"), child: const Text('Start Walk')),
                        ),
                      ]
                  ),
                ) : const SizedBox(),
              ],
            ),
          ),
        )
    );
  }

  Future? Function()? onPressed(BuildContext context, CrimeWalkLocation? element)
  {
    // Only make the button pressable if the element exists.
    return element != null ? () {
      // Close the previous menu so they don't build up.
      Navigator.pop(context);

      return element.buildMenu(context);
    } : null;
  }

  Marker createPOI(BuildContext context, bool filtered)
  {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          buildMenu(context);
        },
        child: Icon(
          Icons.location_pin,
          size: 40,
          color: filtered ? Colors.grey : color,
        ),
      ),
    );
  }
}

class CrimeWalkModel extends ChangeNotifier
{
  final List<CrimeWalk> crimeWalks = [];
  final List<CrimeWalk> filteredWalks = [];
  final List<Marker> markers = [];

  CrimeWalkModel()
  {
    crimeWalks.add(CrimeWalk(name: "The Crime Walk", description: "A walk through the city of Hobart", yearOccurred: 2021, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.last.locations.addAll([CrimeWalkLocation(latitude: -42.879601, longitude: 147.329874, description: "First", color: Colors.red), CrimeWalkLocation(latitude: -42.90395, longitude: 147.325439, description: "Second", color: Colors.red), CrimeWalkLocation(latitude: -42.93, longitude: 147.327, description: "Third", color: Colors.red)]);
    crimeWalks.add(CrimeWalk(name: "The Crime Drive", description: "A drive through the city of Launceston", yearOccurred: 2000, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 2", description: "A walk through the city of Hobart", yearOccurred: 1980, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 2", description: "A drive through the city of Launceston", yearOccurred: 1990, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 3", description: "A drive through the city of Hobart", yearOccurred: 1500, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 4", description: "A drive through the city of Launceston", yearOccurred: 1670, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 3", description: "A walk through the city of Hobart", yearOccurred: 1280, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 4", description: "A walk through the city of Launceston", yearOccurred: 1800, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.WALK));

    resetFilter();
  }

  void generateMarkers(BuildContext context)
  {
    markers.clear();

    for (var element in crimeWalks)
    {
      markers.addAll(element.buildJourney(context, !filteredWalks.contains(element)));
    }
  }

  void resetFilter()
  {
    filterWalks(0, -1 >>> 1, CrimeType.ALL, Length.ALL, Location.ALL, Difficulty.ALL, TransportType.ALL);
  }

  void filterWalks(int minYear, int maxYear, CrimeType crimeType, Length length, Location location, Difficulty difficulty, TransportType transportType)
  {
    filteredWalks.clear();

    for (var element in crimeWalks) {
      if (element.yearOccurred >= minYear &&
          element.yearOccurred <= maxYear &&
          (crimeType == CrimeType.ALL || element.crimeType == crimeType) &&
          (length == Length.ALL || element.length == length) &&
          (location == Location.ALL || element.location == location) &&
          (difficulty == Difficulty.ALL || element.difficulty == difficulty) &&
          (transportType == TransportType.ALL || element.transportType == transportType))
      {
        filteredWalks.add(element);
      }
    }

    update();
  }

  void update()
  {
    // Notify anything that is listening that they need to rebuild.
    notifyListeners();
  }
}