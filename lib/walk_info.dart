import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/filtered_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


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
                          child: FilledButton(onPressed: model.userSettings.currentWalk != walk ? () => {
                            setState(() {
                              model.startWalk(walk);
                            })
                          } : null, child: const Text('Start Walk')),
                        ),
                      ]
                  ),
                  const Divider(), // Add a divider between fields
                  _buildSummaryField('Name', walk.name.toString(), false),
                  _buildSummaryField('Description', walk.description.toString(), false),
                  _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Length', walk.length.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Location', walk.location.toString().split(".").sublist(1).join(" "), true),
                  _buildSummaryField('Physical Requirements', 'TODO', true),
                  _buildSummaryField('Transport Type', walk.transportType.toString().split(".").sublist(1).join(" "), true),
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

        return model.userSettings.currentWalk != null ? FloatingActionButton(
          onPressed: () {
            showWalkSummary(context, model, model.userSettings.currentWalk!);
          },
          child: const Icon(Icons.directions_walk),
        ) : const SizedBox.shrink();
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
                            child: FilledButton(onPressed: model.userSettings.currentWalk != walk ? () => {
                                  setState(() {
                                    model.startWalk(walk);
                                  })
                                } : () {
                              setState(() {
                                model.cancelWalk();
                              });
                            },
                                child: model.userSettings.currentWalk != walk ? const Text('Start Walk') : const Text('Cancel Walk')),
                          ),
                        ]
                    ),
                    const Divider(), // Add a divider between fields
                    _buildSummaryField('Name', walk.name.toString(), false),
                    _buildSummaryField('Description', walk.description.toString(), false),
                    _buildSummaryField('Crime Type', walk.crimeType.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Length', walk.length.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Difficulty', walk.difficulty.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Location', walk.location.toString().split(".").sublist(1).join(" "), true),
                    _buildSummaryField('Physical Requirements', 'TODO', true),
                    _buildSummaryField('Transport Type', walk.transportType.toString().split(".").sublist(1).join(" "), true),
                  ],
                ),
              ),
            );
          },
        );
      }
  );
}