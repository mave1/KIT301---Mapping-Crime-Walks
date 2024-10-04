// import 'package:flutter/material.dart';

// enum CrimeType
// {
//   ALL
// }

// enum Length
// {
//   ALL
// }

// enum Location
// {
//   ALL,
//   HOBART,
//   LAUNCESTON
// }

// enum Difficulty
// {
//   ALL
// }

// enum TransportType
// {
//   ALL,
//   WALK,
//   CAR
// }

// class CrimeWalk
// {
//   CrimeWalk({required this.name, required this.description, required this.yearOccurred, required this.crimeType, required this.length, required this.location, required this.difficulty, required this.transportType});

//   String name;
//   String description;
//   int yearOccurred;
//   CrimeType crimeType;
//   Length length;
//   Location location;
//   Difficulty difficulty;
//   TransportType transportType;
// }

// class CrimeWalkModel extends ChangeNotifier
// {
//   final List<CrimeWalk> crimeWalks = [];
//   final List<CrimeWalk> filteredWalks = [];

//   CrimeWalkModel()
//   {
//     crimeWalks.add(CrimeWalk(name: "The Crime Walk", description: "A walk through the city of Hobart", yearOccurred: 2021, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
//     crimeWalks.add(CrimeWalk(name: "The Crime Drive", description: "A drive through the city of Launceston", yearOccurred: 2000, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
//     crimeWalks.add(CrimeWalk(name: "The Crime Walk 2", description: "A walk through the city of Hobart", yearOccurred: 1980, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
//     crimeWalks.add(CrimeWalk(name: "The Crime Drive 2", description: "A drive through the city of Launceston", yearOccurred: 1990, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
//     crimeWalks.add(CrimeWalk(name: "The Crime Drive 3", description: "A drive through the city of Hobart", yearOccurred: 1500, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
//     crimeWalks.add(CrimeWalk(name: "The Crime Drive 4", description: "A drive through the city of Launceston", yearOccurred: 1670, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
//     crimeWalks.add(CrimeWalk(name: "The Crime Walk 3", description: "A walk through the city of Hobart", yearOccurred: 1280, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
//     crimeWalks.add(CrimeWalk(name: "The Crime Walk 4", description: "A walk through the city of Launceston", yearOccurred: 1800, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.WALK));

//     resetFilter();
//   }

//   void resetFilter()
//   {
//     filterWalks(0, -1 >>> 1, CrimeType.ALL, Length.ALL, Location.ALL, Difficulty.ALL, TransportType.ALL);
//   }

//   void filterWalks(int minYear, int maxYear, CrimeType crimeType, Length length, Location location, Difficulty difficulty, TransportType transportType)
//   {
//     filteredWalks.clear();

//     for (var element in crimeWalks) {
//       if (element.yearOccurred >= minYear &&
//           element.yearOccurred <= maxYear &&
//           (crimeType == CrimeType.ALL || element.crimeType == crimeType) &&
//           (length == Length.ALL || element.length == length) &&
//           (location == Location.ALL || element.location == location) &&
//           (difficulty == Difficulty.ALL || element.difficulty == difficulty) &&
//           (transportType == TransportType.ALL || element.transportType == transportType))
//       {
//         filteredWalks.add(element);
//       }
//     }

//     update();
//   }

//   void addCrimeWalk(CrimeWalk crimeWalk)
//   {
//     crimeWalks.add(crimeWalk);
//   }

//   void update()
//   {
//     notifyListeners();
//   }
// }

import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimewalksapp/walk_info.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/user_settings.dart';
import 'package:crimewalksapp/walk_widgets.dart';
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
enum TransportType { ALL, WALK, WHEELCHAIR_ACCESS, CAR }

class CrimeWalk {
  CrimeWalk({
    required this.id,
    required this.name,
    required this.description,
    required this.yearOccurred,
    required this.crimeType,
    required this.length,
    required this.location,
    required this.difficulty,
    required this.transportType,
    required this.locations,
    this.imageUrl
  });

  String id;
  String name;
  String description;
  int yearOccurred;
  CrimeType crimeType;
  double length;
  Location location;
  Difficulty difficulty;
  TransportType transportType;
  LinkedList<CrimeWalkLocation> locations;
  bool isCompleted = false;
  String? imageUrl;


  // Get snapshot of data from the firebase, put it in the data variable to be able to access

  factory CrimeWalk.fromFirestore(DocumentSnapshot doc, LinkedList<CrimeWalkLocation> locations) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Gets each variable in the database and maps it to a CrimeWalk

    return CrimeWalk(
      id: doc.id,
      name: data['Title'] ?? '',
      description: data['Description'] ?? '',
      yearOccurred: data['YearOccurred'] ?? 0,

      //This maps the string variable found in the database to the enums we have set for each category
      //At the moment the string variable has to be exact and correct case to match properly
      // Keeping it like this ensures functionality with filtering

      crimeType: data['CrimeType'] != null
          ? CrimeType.values.firstWhere(
              (e) => e.toString().split('.').last == data['CrimeType'],
          orElse: () => CrimeType.ALL // Default value if no match is found
      )
          : CrimeType.ALL,

      length: data['Length'] != null ? data['Length'].toDouble() : 0.0,
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

      locations: locations,

      imageUrl: data['image'] as String?,
    );
  }

  // Build a journey from all the locations
  // TODO: build a path between each point
  List<Marker> buildJourney(BuildContext context, CrimeWalkModel model, bool filtered)
  {
    var markers = <Marker>[];

    for (var location in locations)
    {
      if (userSettings.currentWalk == null && location == locations.first)
      {
        markers.add(location.createPOI(context, model, this, filtered));
      }
      else if (userSettings.currentWalk == this)
      {
        markers.add(location.createPOI(context, model, this, filtered));
      }
    }

    return markers;
  }
}

final class CrimeWalkLocation extends LinkedListEntry<CrimeWalkLocation>
{
  CrimeWalkLocation({required this.latitude, required this.longitude, required this.description, required this.color, required this.index, this.imageUrl});

  double latitude;
  double longitude;
  Color color;
  int index;

  String description;

  //Optional for if an image exists or not
  String? imageUrl; 

  // The menu that appears when you click on a marker.
  Future buildMenu(BuildContext context, CrimeWalkModel model, CrimeWalk walk)
  {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${walk.name} #${index + 1}",
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(), // Add a divider between fields
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35
                    ),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // testing images
                  const Divider(), // Add a divider between fields
                  if (imageUrl != null)
                    FutureBuilder<String>(
                      future: _getImageUrl(imageUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(snapshot.data!),
                          );
                        } else if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else {
                          return Text('Failed to load image');
                        }
                      },
                    ),
                  //end of images test
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(onPressed: onPressed(context, model, walk, previous), child: const Text('Previous')),
                          FilledButton(onPressed: onPressed(context, model, walk, walk.locations.first), child: const Text("First Marker")),
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
                            child: userSettings.currentWalk != walk ? StartWalkButton(model: model, callback: () {setState(() {});}, walk: walk) : CancelWalkButton(model: model, callback: () {setState(() {});})
                          )
                        ]
                    ),
                  ) : const SizedBox(),
                ],
              ),
            ),
        )
    );
  }

  Future<String> _getImageUrl(String gsUrl) async {
    final ref = FirebaseStorage.instance.refFromURL(gsUrl);
    return await ref.getDownloadURL();
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

  Marker createPOI(BuildContext context, CrimeWalkModel model, CrimeWalk walk, bool filtered)
  {
    CrimeWalk? currentWalk = userSettings.currentWalk;
    return Marker(
      point: LatLng(latitude, longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          if (currentWalk != null) {
            currentWalk != null ? buildMenu(context, model, walk) : showWalkSummary(context, model, walk);

            appStateKey.currentState!.getCoordinates(latitude.toString(), longitude.toString());
          }
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
  final List<Color> possibleColors = [Colors.red, Colors.orange, Colors.green, Colors.deepPurple, Colors.blue, Colors.pinkAccent, Colors.yellow];
  int colorIndex = 0;

  CrimeWalkModel() {
    fetchCrimeWalks();
  }

  // Function Currently loops through walks, retrieves Points of Interest, then for each POI in a walk debugPrints to test that output is correct.
  // Called at the start of build() to test.
  Future<LinkedList<CrimeWalkLocation>> fetchPointsOfInterestFromWalk(var walkDoc) async {
    var locations = LinkedList<CrimeWalkLocation>();
    String walkDocumentId = walkDoc.id; // Get the auto-generated document ID

    // Reference to the "Points of Interest" sub-collection for this walk document
    CollectionReference pointsOfInterestRef = FirebaseFirestore.instance
        .collection('Walks')
        .doc(walkDocumentId)
        .collection('Points of Interest');

    // Get all documents from the "Points of Interest" sub-collection
    QuerySnapshot pointsSnapshot = await pointsOfInterestRef.get();

    // Print data for each point of interest
    for (var pointDoc in pointsSnapshot.docs) {
      Map<String, dynamic> data = pointDoc.data() as Map<String, dynamic>;
      String poiId = pointDoc.id;

      // Check if the location field is present and is a GeoPoint
      if (data['Location'] != null && data['Location'] is GeoPoint) {
        // Splitting GeoPoint into two variables for lat & long
        GeoPoint location = data['Location'];
        double latitude = location.latitude;
        double longitude = location.longitude;

        // fetch image url if it exists
        String? imageUrl = data['image'] as String?;

        locations.add(CrimeWalkLocation(latitude: latitude, longitude: longitude, description: data['Information'], color: possibleColors[colorIndex % possibleColors.length], imageUrl: imageUrl, index: locations.length));
      } else {
        debugPrint('Location data is missing or invalid for POI ID: $poiId');
      }
    }

    colorIndex += 1;
    return locations;
  }

  Future<void> fetchCrimeWalks() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Walks').get();

    crimeWalks.clear();
    for (var doc in querySnapshot.docs) {
      final locations = await fetchPointsOfInterestFromWalk(doc);
      crimeWalks.add(CrimeWalk.fromFirestore(doc, locations));
    }

    // TODO: REMOVE
    crimeWalks.last.isCompleted = true;

    resetFilter();
  }

  void cancelWalk()
  {
    userSettings.currentWalk = null;
    userSettings.locationsReached.clear();

    update();

    appStateKey.currentState!.getCoordinates("-1", "-1");
  }

  void startWalk(CrimeWalk walk)
  {
    userSettings.currentWalk = walk;
    userSettings.walkStarted = DateTime.now();
    userSettings.distanceWalked = 0;
    userSettings.checkpointsHit = 0;

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
    filterWalks(0, -1 >>> 1, CrimeType.ALL, const RangeValues(0.0, 1000000.0), Location.ALL, Difficulty.ALL, TransportType.ALL, false);
  }

  void filterWalks(int minYear, int maxYear, CrimeType crimeType, RangeValues lengthRange,
      Location location, Difficulty difficulty, TransportType transportType, bool ignoreCompleted) {
    filteredWalks.clear();

    for (var element in crimeWalks) {
      if (element.yearOccurred >= minYear &&
          element.yearOccurred <= maxYear &&
          (crimeType == CrimeType.ALL || element.crimeType == crimeType) &&
          (element.length >= lengthRange.start && element.length <= lengthRange.end) &&
          (location == Location.ALL || element.location == location) &&
          (difficulty == Difficulty.ALL || element.difficulty == difficulty) &&
          (transportType == TransportType.ALL || element.transportType == transportType) &&
          (!ignoreCompleted || (ignoreCompleted && !element.isCompleted)))
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
