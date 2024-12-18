import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crimewalksapp/walk_info.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/walk_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// All possible crime types and a default ALL value that is used for filtering
enum CrimeType { ALL, MURDER, INFANTICIDE, GANGLAND, BUSHRANGING, POISONINGS }
// All possible locations for a walk and a default ALL value that is used for filtering
// enum Location { ALL, HOBART, LAUNCESTON }
// All possible difficulty levels for the walk and a default ALL value that is used for filtering
enum Difficulty { ALL, EASY, MEDIUM, HARD }
// All possible types of transport required for participating in the crime walk and a default ALL value that is used for filtering
enum TransportType { ALL, WALK, WHEELCHAIR_ACCESS, CAR, CYCLE }

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
  String location;
  Difficulty difficulty;
  TransportType transportType;
  LinkedList<CrimeWalkLocation> locations;
  bool isCompleted = false;
  bool isMarkerMenuOpen = false;
  String? imageUrl;
  Widget? imageCache;


  // Get snapshot of data from the firebase, put it in the data variable to be able to access

  factory CrimeWalk.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> data, LinkedList<CrimeWalkLocation> locations) {
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

      location: data['Location'],

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
  Widget? imageCache;

  Future createMenu(BuildContext context, CrimeWalkModel model, CrimeWalk walk, bool fromButton)
  {
    if (walk.isMarkerMenuOpen && !fromButton)
    {
      Navigator.pop(context);
    }

    walk.isMarkerMenuOpen = true;

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
                  imageCache == null ? FutureBuilder<String>(
                    future: _getImageUrl(imageUrl!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        imageCache = Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(snapshot.data!),
                        );

                        return imageCache!;
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else {
                        return const Text('Failed to load image');
                      }
                    },
                  ) : imageCache!,
                //end of images test
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton(onPressed: onPressed(context, model, walk, previous), child: const Icon(Icons.navigate_before)),
                        FilledButton.icon(onPressed: userSettings.currentWalk != null && userSettings.getNextLocation() != this ? () => setState(() => userSettings.setActiveCheckpoint(this)) : null, icon: const Icon(Icons.directions), label: const Text("Directions")),
                        FilledButton(onPressed: onPressed(context, model, walk, next), child: const Icon(Icons.navigate_next)),
                      ]
                  ),
                ),
                // Only show the start walk button if it is the start of the walk
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                            child: userSettings.currentWalk != walk ? StartWalkButton(model: model, callback: () {setState(() {});}, walk: walk) : CancelWalkButton(model: model, callback: () {setState(() {});})
                        )
                      ]
                  ),
                ),
              ],
            ),
          ),
        )
    ).whenComplete(() => walk.isMarkerMenuOpen = false );
  }

  // The menu that appears when you click on a marker.
  Future buildMenu(BuildContext context, CrimeWalkModel model, CrimeWalk walk, bool fromButton)
  {
    return createMenu(context, model, walk, fromButton);
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

      return element.buildMenu(context, model, walk, true);
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
          currentWalk != null ? buildMenu(context, model, walk, false) : showWalkSummary(context, model, walk);
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
  final Set<String> allLocations = { "ALL" };

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
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      data['Location'] = data['Location'].replaceAll(' ', '_').toUpperCase();
      allLocations.add(data['Location']);

      crimeWalks.add(CrimeWalk.fromFirestore(doc, data, locations));
    }

    resetFilter();
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
    filterWalks(0, -1 >>> 1, CrimeType.ALL, const RangeValues(0.0, 1000000.0), "ALL", Difficulty.ALL, TransportType.ALL, false);
  }

  void filterWalks(int minYear, int maxYear, CrimeType crimeType, RangeValues lengthRange,
      String location, Difficulty difficulty, TransportType transportType, bool ignoreCompleted) {
    filteredWalks.clear();

    for (var element in crimeWalks) {
      if (element.yearOccurred >= minYear &&
          element.yearOccurred <= maxYear &&
          (crimeType == CrimeType.ALL || element.crimeType == crimeType) &&
          (element.length >= lengthRange.start && element.length <= lengthRange.end) &&
          (location == "ALL" || element.location == location) &&
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
