import 'dart:collection';

import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/user_settings.dart';
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
  List<Marker> buildJourney(BuildContext context, CrimeWalkModel model, bool filtered)
  {
    var markers = <Marker>[];

    for (var location in locations)
    {
      var marker = location.createPOI(context, model, this, filtered);

      if (marker != null) markers.add(marker);
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
  Future buildMenu(BuildContext context, CrimeWalkModel model, CrimeWalk walk)
  {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => SingleChildScrollView(
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
                          FilledButton(onPressed: onPressed(context, model, walk, previous), child: const Text('Previous')),
                          FilledButton(onPressed: onPressed(context, model, walk, next), child: const Text('Next')),
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
                            child: FilledButton(onPressed: model.userSettings.currentWalk != walk ? () {
                              setState(() {
                                model.startWalk(walk);
                              });
                            }  : () {
                              setState(() {
                                model.cancelWalk();
                              });
                            }, child: model.userSettings.currentWalk != walk ? const Text('Start Walk') : const Text('Cancel Walk')),
                          ),
                        ]
                    ),
                  ) : const SizedBox(),
                ],
              ),
            ),
          ),
        )
    );
  }

  Future? Function()? onPressed(BuildContext context, CrimeWalkModel model, CrimeWalk walk, CrimeWalkLocation? element)
  {
    // Only make the button pressable if the element exists.
    return element != null ? () {
      // Close the previous menu so they don't build up.
      Navigator.pop(context);

      return element.buildMenu(context, model, walk);
    } : null;
  }

  Marker? createPOI(BuildContext context, CrimeWalkModel model, CrimeWalk walk, bool filtered)
  {
    CrimeWalk? currentWalk = model.userSettings.currentWalk;

    return currentWalk == null || currentWalk == walk ? Marker(
      point: LatLng(latitude, longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          buildMenu(context, model, walk);
        },
        child: Icon(
          Icons.location_pin,
          size: 40,
          color: filtered ? Colors.grey : color,
        ),
      ),
    ) : null;
  }
}

class CrimeWalkModel extends ChangeNotifier
{
  final List<CrimeWalk> crimeWalks = [];
  final List<CrimeWalk> filteredWalks = [];
  final List<Marker> markers = [];

  UserSettings userSettings = UserSettings();

  CrimeWalkModel()
  {
    crimeWalks.add(CrimeWalk(name: "The Crime Walk", description: "A walk through the city of Hobart", yearOccurred: 2021, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.last.locations.addAll([CrimeWalkLocation(latitude: -42.879601, longitude: 147.329874, description: "First", color: Colors.red), CrimeWalkLocation(latitude: -42.90395, longitude: 147.325439, description: "Second", color: Colors.red), CrimeWalkLocation(latitude: -42.93, longitude: 147.327, description: "Third", color: Colors.red)]);
    crimeWalks.add(CrimeWalk(name: "The Crime Drive", description: "A drive through the city of Launceston", yearOccurred: 2000, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.last.locations.addAll([CrimeWalkLocation(latitude: -42.889601, longitude: 147.339874, description: "First", color: Colors.lightBlue), CrimeWalkLocation(latitude: -42.91395, longitude: 147.335439, description: "Second", color: Colors.lightBlue), CrimeWalkLocation(latitude: -42.94, longitude: 147.337, description: "Third", color: Colors.lightBlue)]);
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 2", description: "A walk through the city of Hobart", yearOccurred: 1980, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.last.locations.addAll([CrimeWalkLocation(latitude: -42.869601, longitude: 147.319874, description: "First", color: Colors.green), CrimeWalkLocation(latitude: -42.89395, longitude: 147.315439, description: "Second", color: Colors.green), CrimeWalkLocation(latitude: -42.92, longitude: 147.317, description: "Third", color: Colors.green)]);
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 2", description: "A drive through the city of Launceston", yearOccurred: 1990, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 3", description: "A drive through the city of Hobart", yearOccurred: 1500, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 4", description: "A drive through the city of Launceston", yearOccurred: 1670, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 3", description: "A walk through the city of Hobart", yearOccurred: 1280, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 4", description: "A walk through the city of Launceston", yearOccurred: 1800, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.WALK));

    resetFilter();
  }

  void cancelWalk()
  {
    userSettings.currentWalk = null;
    userSettings.locationsReached.clear();

    update();
  }

  void startWalk(CrimeWalk walk)
  {
    userSettings.currentWalk = walk;

    // TODO: GENERATE AUTO UPDATING PATH FROM CURRENT LOCATION TO FIRST LOCATION - HOW?
    // TODO: MAYBE LET OTHER POINT AS START?

    // ONCE REACHES POINT DISPLAY CHECKPOINT INFO AND GENERATE UPDATING ROUTE FROM CURRENT LOCATION TO NEXT POINT
    // REPEAT UNTIL DONE

    // ONCE DONE SHOW DIFFERENT SCREEN?

    // userSettings.finishWalk();

    update();
  }

  void generateMarkers(BuildContext context)
  {
    markers.clear();

    for (var element in crimeWalks)
    {
      markers.addAll(element.buildJourney(context, this, !filteredWalks.contains(element)));
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