import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:crimewalksapp/main.dart';
import 'package:crimewalksapp/walk_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
                    'Walk Summary',
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
                          child: FilledButton(onPressed: userSettings.currentWalk != walk ? () => {
                            setState(() {
                              userSettings.startWalk(walk, model);
                            })
                          } : null, child: const Text('Start Walk')),
                        ),
                      ]
                  ),
                  const Divider(), // Add a divider between fields
                  _buildSummaryField('Name', walk.name.toString(), false),
                  _buildSummaryField('Description', walk.description.toString(), false),
                  _buildSummaryField('Has Completed', walk.isCompleted.toString(), true),
                  _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Length', walk.length.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Location', walk.location.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Wheelchair Accessible', (walk.transportType == TransportType.CAR || walk.transportType == TransportType.WHEELCHAIR_ACCESS).toString(), true),
                  _buildSummaryField('Transport Type', walk.transportType.toString().split(".").sublist(1).join(" "), true),
                  if (walk.imageUrl != null)
                      FutureBuilder<String>(
                        future: _getImageUrl(walk.imageUrl!),
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

        return SizedBox.shrink();
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
                      'Walk Summary',
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
                    _buildSummaryField('Walk Completed', walk.isCompleted ? "Yes" : "No", true),
                    _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Length', walk.length.toStringAsFixed(1), true),
                    _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Location', walk.location.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Wheelchair Accessible', (walk.transportType == TransportType.CAR || walk.transportType == TransportType.WHEELCHAIR_ACCESS) ? "Yes" : "No", true),
                    _buildSummaryField('Transport Type', walk.transportType.toString().split('.').last.replaceAll(RegExp('_'), ' '), true),
                    if (walk.imageUrl != null)
                      FutureBuilder<String>(
                        future: _getImageUrl(walk.imageUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(snapshot.data!),
                            );
                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else {
                            return const Text('Failed to load image');
                          }
                        },
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

Future<String> _getImageUrl(String gsUrl) async {
  final ref = FirebaseStorage.instance.refFromURL(gsUrl);
  return await ref.getDownloadURL();
}