import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// All possible crime types and a default ALL value that is used for filtering
enum CrimeType { ALL, MURDER }
// All possible locations for a walk and a default ALL value that is used for filtering
enum Location { ALL, HOBART, LAUNCESTON }
// All possible difficulty levels for the walk and a default ALL value that is used for filtering
enum Difficulty { ALL, EASY, MEDIUM, HARD }
// All possible types of transport required for participating in the crime walk and a default ALL value that is used for filtering
enum TransportType { ALL, WALK, CAR }

class CrimeWalk
{
  CrimeWalk({
    required this.name,
    required this.description,
    required this.yearOccurred,
    required this.crimeType,
    required this.length,
    required this.location,
    required this.difficulty,
    required this.transportType,
  });

  String name;
  String description;
  int yearOccurred;
  CrimeType crimeType;
  double length;
  Location location;
  Difficulty difficulty;
  TransportType transportType;
  final locations = LinkedList<CrimeWalkLocation>();


  // Get snapshot of data from the firebase, put it in the data variable to be able to access

  factory CrimeWalk.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Gets each variable in the database and maps it to a CrimeWalk

    return CrimeWalk(
      name: data['Title'] ?? '',
      description: data['Description'] ?? '',
      yearOccurred: data['YearOccured'] ?? 0,

      //This maps the string variable found in the database to the enums we have set for each category
      //At the moment the string variable has to be exact and correct case to match properly
      // Keeping it like this ensures functionality with filtering

      crimeType: data['CrimeType'] != null
          ? CrimeType.values.firstWhere(
              (e) => e.toString().split('.').last == data['CrimeType'],
          orElse: () => CrimeType.ALL // Default value if no match is found
      )
          : CrimeType.ALL,

      length: 0.0,
      // length: data['Length'] != null
      //     ? Length.values.firstWhere(
      //         (e) => e.toString().split('.').last == data['Length'],
      //     orElse: () => Length.ALL // Default value if no match is found
      // )
      //     : Length.ALL,

      location: data['Location'] != null
          ? Location.values.firstWhere(
              (e) => e.toString().split('.').last == data['Location'],
          orElse: () => Location.ALL // Default value if no match is found
      )
          : Location.ALL,

      difficulty: data['Difficulty'] != null
          ? Difficulty.values.firstWhere(
              (e) => e.toString().split('.').last == data['Difficulty'],
          orElse: () => Difficulty.ALL // Default value if no match is found
      )
          : Difficulty.ALL,

      transportType: data['TransportType'] != null
          ? TransportType.values.firstWhere(
              (e) => e.toString().split('.').last == data['TransportType'],
          orElse: () => TransportType.ALL // Default value if no match is found
      )
          : TransportType.ALL,
    );
  }

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

  CrimeWalkModel() {
    fetchCrimeWalks();
  }

  Future<void> fetchCrimeWalks() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Walks').get();

    crimeWalks.clear();
    for (var doc in querySnapshot.docs) {
      crimeWalks.add(CrimeWalk.fromFirestore(doc));
    }
    
    crimeWalks[0].locations.add(CrimeWalkLocation(latitude: -42.886554838136846,
        longitude: 147.3198146282025,
        description: "100 Goulburn Street is where Evelyn Maughan, the 7 year old girl who was abducted and killed by Frederick Thompson in 1945, lived with her family. She was last seen alive on the 8th July 1945 heading to the nearby church. Initially her body was not found, but 3 months later her remains were found in the Queenborough Cemetery by a member of the public who was looking for his father's place of rest. He found a child's shoe and then the body and altered police immediately. Frederick Thompson was a convicted sex offender who was a wharf labourer by trade and the last person executed in Tasmania. Today at 100 Goulburn Street there is a small art installation in front of the Maughan home commemorating Evelyn.",
        color: Colors.deepPurple));
    crimeWalks[1].locations.add(CrimeWalkLocation(latitude: -42.881902259533184,
        longitude: 147.33569091753807,
        description: "Footsteps Sculpture. Four sculptures commemorating the convict women and children transported to VDL (Tasmania). This was the disembarkation point for all convicts entering Hobart. The sculpture simply titled \"Footsteps\" was created by Rowan Gillespie and unveiled on October 14 2017. In total 13,000 convict women were transported to VDL in the 50 years between 1803 and 1853, bringing with them 2,000 children.",
        color: Colors.green));
    crimeWalks[2].locations.add(CrimeWalkLocation(latitude: -42.84014,
        longitude: 147.34966,
        description: "Test POI 2",
        color: Colors.red));
    crimeWalks[3].locations.add(CrimeWalkLocation(latitude: -42.88268488248128,
        longitude: 147.32955278742915,
        description: "Formerly known as the Stage Door Cabaret. This was a popular location for young people to meet in the early 20th century for romance, song and dance. It was here inside that on the 27th August 1945 Mona Hazel Gladys Elliot and Harry Cleaver caught up and had a dance. Mona's sister was also present. Mona had a cut or bruise on her forehead but she said it was nothing and it isn't clear how she got that mark. Witnesses reported seeing her at Franklin Square before her arrival to the Stage Door Cabaret. Inside Cleaver's brother and a friend started a fight with three sailors. A police officer asked all of them to leave. The brawl continued on the street. ",
        color: Colors.orange));
    

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
    filterWalks(0, -1 >>> 1, CrimeType.ALL, 0.0, Location.ALL, Difficulty.ALL, TransportType.ALL);
  }

  void filterWalks(int minYear, int maxYear, CrimeType crimeType, double length,
      Location location, Difficulty difficulty, TransportType transportType) {
    filteredWalks.clear();

    for (var element in crimeWalks) {
      if (element.yearOccurred >= minYear &&
          element.yearOccurred <= maxYear &&
          (crimeType == CrimeType.ALL || element.crimeType == crimeType) &&
          (length == 0.0 || element.length == length) &&
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
