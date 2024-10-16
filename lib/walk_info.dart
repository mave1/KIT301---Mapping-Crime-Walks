import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/walk_widgets.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum TravelMode { WALK, CAR, CYCLE }
TravelMode selectedMode = TravelMode.WALK; // Default mode is walking
TransportType selectedModeRoute = TransportType.WALK;

class WalkInfo extends StatefulWidget
{
  const WalkInfo({super.key, required this.walk});

  final CrimeWalk walk;

  @override
  State<StatefulWidget> createState() => _WalkInfoState();
}

class _WalkInfoState extends State<WalkInfo>
{
  @override
  void initState()
  {
    super.initState();
    print("--------------------------------");
    print("Walk Info");
    print("--------------------------------");
  }

  Widget _buildSummaryField(String label, String value, bool shouldCapitalize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5.0),
        Text(
          shouldCapitalize ? value.capitalize() : value,
          style: const TextStyle(
            fontSize: 14.0,
          ),
        ),
        const Divider(), // Add a divider between fields
      ],
    );
  }

// The menu that appears after clicking on a specific menu item.
  void showWalkSummary(BuildContext context, CrimeWalkModel model, CrimeWalk walk) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tour Summary',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0,),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: StartWalkButton(model: model, callback: () {setState(() {

                          });}, walk: walk),
                        )
                      ]
                  ),
                  const Divider(), // Add a divider between fields
                  _buildSummaryField('Name', walk.name.toString(), false),
                  _buildSummaryField('Description', walk.description.toString(), false),
                  _buildSummaryField('Has Completed', walk.isCompleted.toString(), true),
                  _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Length', walk.length.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Location', walk.location.capitalizeAll(), false),
                  _buildSummaryField('Wheelchair Accessible', (walk.transportType == TransportType.CAR || walk.transportType == TransportType.WHEELCHAIR_ACCESS).toString(), true),
                  _buildSummaryField('Transport Type', walk.transportType.toString().split(".").sublist(1).join(" "), true),
                  if (walk.imageUrl != null)
                      walk.imageCache == null ? FutureBuilder<String>(
                        future: _getImageUrl(walk.imageUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            walk.imageCache = Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(snapshot.data!),
                            );

                            return walk.imageCache!;
                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else {
                            return const Text('Failed to load image');
                          }
                        },
                      ) : walk.imageCache!,
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (walk.isCompleted == true)
                          FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  walk.isCompleted = false;
                                });
                              },
                              child: const Text("Mark Walk as Incomplete")
                          ),
                        if (walk.isCompleted != true)
                          FilledButton(
                              onPressed: () {
                                setState(() {
                                  walk.isCompleted = true;
                                });
                              },
                              child: const Text("Mark Walk as Complete")
                          ),
                      ]
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrimeWalkModel>(
      builder: (context, model, _) {
        showWalkSummary(context, model, widget.walk);
        return const SizedBox.shrink();
      },
    );

  }
}

Widget _buildSummaryField(String label, String value, bool shouldCapitalize) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10.0),
      Text(
        label,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5.0),
      Text(
        shouldCapitalize ? value.capitalize() : value,
        style: const TextStyle(
          fontSize: 14.0,
        ),
      ),
      const Divider(), // Add a divider between fields
    ],
  );
}

// Method to show walk summary that is shown once a walk has been selected from the filtered list
// The menu that appears after clicking on a specific menu item.
void showWalkSummary(BuildContext context, CrimeWalkModel model, CrimeWalk walk) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tour Summary',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: userSettings.currentWalk != walk ? StartWalkButton(model: model, callback: () {setState(() {});}, walk: walk) : CancelWalkButton(model: model, callback: () {setState(() {});})
                          ),
                        ]
                    ),
                    const Divider(), // Add a divider between fields
                    _buildSummaryField('Name', walk.name.toString(), false),
                    _buildSummaryField('Description', walk.description.toString(), false),
                    _buildSummaryField('Tour Completed?', walk.isCompleted ? "Yes" : "No", true),
                    _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Length', walk.length.toStringAsFixed(1), true),
                    _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Location', walk.location.capitalizeAll(), false),
                    _buildSummaryField('Wheelchair Accessible', (walk.transportType == TransportType.CAR || walk.transportType == TransportType.WHEELCHAIR_ACCESS) ? "Yes" : "No", true),
                    _buildSummaryField('Transport Type', walk.transportType.toString().split('.').last.replaceAll(RegExp('_'), ' '), true),
                    if (walk.imageUrl != null)
                      walk.imageCache == null ? FutureBuilder<String>(
                        future: _getImageUrl(walk.imageUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            walk.imageCache = Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(snapshot.data!),
                            );

                            return walk.imageCache!;
                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else {
                            return const Text('Failed to load image');
                          }
                        },
                      ) : walk.imageCache!,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (walk.isCompleted == true)
                          FilledButton.tonal(
                            onPressed: () {
                            setState(() {
                              walk.isCompleted = false;
                            });
                          },
                          child: const Text("Mark Tour as Incomplete")
                          ),
                        if (walk.isCompleted != true)
                          FilledButton(
                            onPressed: () {
                            setState(() {
                              walk.isCompleted = true;
                            });
                          },
                          child: const Text("Mark Tour as Complete")
                          ),
                      ]
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
  );
}

Future<void> showTransportType(BuildContext context, CrimeWalk walk, CrimeWalkModel model) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => AlertDialog(
        title: const Text(
          'Select Travel Mode to the Start',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: DropdownButton<TravelMode>(
          value: selectedMode,
          onChanged: (TravelMode? newValue) {
            setState(() {
              selectedMode = newValue!;
            });
          },
          items: TravelMode.values.map((TravelMode mode) {
            return DropdownMenuItem<TravelMode>(
              value: mode,
              child: Text(modeToString(mode)),
            );
          }).toList(),
        ),
        actions: <Widget>[
          FilledButton(
              onPressed: () {
                switch (selectedMode) {
                  case TravelMode.WALK:
                    selectedModeRoute = TransportType.WALK;
                  case TravelMode.CYCLE:
                    selectedModeRoute = TransportType.CYCLE;
                  case TravelMode.CAR:
                    selectedModeRoute = TransportType.CAR;
                  default:
                    selectedModeRoute = TransportType.WALK;
                }

                userSettings.startWalk(walk, model, selectedModeRoute);
                appStateKey.currentState!.getCoordinates(walk.locations.first.latitude.toString(), walk.locations.first.longitude.toString(), false);
                Navigator.pop(context); // Close the popup after marking as completed

                appStateKey.currentState!.focusOnRoute([LatLng(appStateKey.currentState!.currentLat, appStateKey.currentState!.currentLong), LatLng(walk.locations.first.latitude, walk.locations.first.longitude)]);
              },
              child: const Text("Select")
          ),
        ],
      ),
    )
  );
}

// Helper function to convert mode enum to string
String modeToString(TravelMode mode) {
  switch (mode) {
    case TravelMode.WALK:
      return 'Walking';
    case TravelMode.CYCLE:
      return 'Cycling';
    case TravelMode.CAR:
      return 'Driving';
    default:
      return '';
    }
}

Future<String> _getImageUrl(String gsUrl) async {
  final ref = FirebaseStorage.instance.refFromURL(gsUrl);
  return await ref.getDownloadURL();
}