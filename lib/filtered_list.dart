import 'dart:collection';

import 'package:crimewalksapp/walk_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timer_builder/timer_builder.dart';
import 'crime_walk.dart';

extension StringExtension on String? {
  String capitalize() {
    if (this == null || this!.isEmpty) {
      return "";
    }
    return "${this![0].toUpperCase()}${this!.substring(1).toLowerCase()}";
  }
}

// The menu that appears when you click the bottom Search Walks button.
class FilteredList extends StatefulWidget
{
  const FilteredList({super.key});

  @override
  _FilteredListState createState() => _FilteredListState();
}

class _FilteredListState extends State<FilteredList> with SingleTickerProviderStateMixin
{
  final startYearController = TextEditingController();
  final endYearController = TextEditingController();
  final crimeTypeKey = GlobalKey<_FilterableFlagState<CrimeType>>();
  // final lengthKey = GlobalKey<double>(); // TODO: Fix
  final locationKey = GlobalKey<_FilterableFlagState<Location>>();
  final difficultyKey = GlobalKey<_FilterableFlagState<Difficulty>>();
  final transportTypeKey = GlobalKey<_FilterableFlagState<TransportType>>();
  bool ignoreCompletedWalks = false;
  bool animateMenu = false;
  bool showMenu = false;
  bool onWalk = false; // Add the onWalk variable
  late AnimationController animationController;
  RangeValues? lengthRange;
  Map<TransportType, IconData> walkIcons = {TransportType.WALK: Icons.directions_walk, TransportType.WHEELCHAIR_ACCESS: Icons.wheelchair_pickup, TransportType.CAR: Icons.directions_car};


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

  // Method to show statistics from current walk the user is on, button is only shown if user is currently on a walk
  void _showWalkStats(BuildContext context, CrimeWalkModel model) {
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
                    'Statistics of Current Walk',
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
                          child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  onWalk = false; // Update the onWalk variable
                                });
                                print("Walk ended");
                                model.cancelWalk();

                                Navigator.pop(context);
                              },
                              child: const Text('End Walk')
                          ),
                        ),
                      ]
                  ),
                  const Divider(), // Add a divi
                  TimerBuilder.periodic(const Duration(seconds: 5),
                      builder: (BuildContext context) {
                        return Column(
                          children: [
                            _buildSummaryField('Distance Walked', '${model.userSettings.distanceWalked.toStringAsFixed(0)}m', false),
                            _buildSummaryField('Checkpoints Hit', model.userSettings.checkpointsHit.toString(), false),
                            _buildSummaryField('Time Elapsed', '${model.userSettings.getTimeElapsed()}h', true)
                          ],
                        );
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
  void initState()
  {
    super.initState();

    startYearController.text = "0";
    endYearController.text = DateTime.timestamp().year.toString();

    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) setState(() {
        showMenu = false;
      });
    });
  }

  void animateMenuState()
  {
    setState(() {
      if (!showMenu) showMenu = true;

      animateMenu = !animateMenu;

      if (animateMenu) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Consumer<CrimeWalkModel>(builder: createMenu);
  }

  // The button at the bottom of the screen that shows the walks when clicked.
  Widget createButton()
  {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Search Walks"),
          onPressed: () => animateMenuState()
      ),
    );
  }

  void filterWalks(CrimeWalkModel model)
  {
    model.filterWalks(int.parse(startYearController.value.text),
        int.parse(endYearController.value.text),
        crimeTypeKey.currentState!.state,
        lengthRange!,
        locationKey.currentState!.state,
        difficultyKey.currentState!.state,
        transportTypeKey.currentState!.state,
        ignoreCompletedWalks);
  }

  // The menu that appears when you click on the Search Walks/createButton button.
  Widget createMenu(BuildContext context, CrimeWalkModel model, _)
  {
    // print(model.crimeWalks.reduce((a,b) => a.length < b.length ? a : b).length);
    // print(model.crimeWalks.reduce((a,b) => a.length > b.length ? a : b).length);
    if (model.crimeWalks.isNotEmpty)
    {
      lengthRange ??= RangeValues(model.crimeWalks.reduce((a,b) => a.length < b.length ? a : b).length, model.crimeWalks.reduce((a,b) => a.length > b.length ? a : b).length);
    }

    return Stack(
        children: [
          IntrinsicHeight(
            child: Column(
              children: [
                // The filtering menu.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  // Controls the animation transition.
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 2),
                      end: const Offset(0, 0),
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeInOut,
                    )),
                    child: showMenu ?
                    Material(
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: Column(
                        children: [
                          // Title
                          Row(
                            children: [
                              Expanded(child:
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text("Crime Walks Tasmania",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.close),
                                        ),
                                        onTap: () {
                                          animateMenuState();
                                        },
                                      )
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          // Filtering options
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // All filtering options
                                      Column(
                                        children: [
                                          FilterableFlag(key: crimeTypeKey, values: CrimeType.values, model: model),
                                          Wrap(
                                            children: [
                                              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Walk Length:")),
                                              RangeSlider(
                                                  min: model.crimeWalks.isNotEmpty ? model.crimeWalks.reduce((a,b) => a.length < b.length ? a : b).length : 0.0,
                                                  max: model.crimeWalks.isNotEmpty ? model.crimeWalks.reduce((a,b) => a.length > b.length ? a : b).length : 1.0,
                                                  values: lengthRange == null ? const RangeValues(0.0, 1.0) : lengthRange!,
                                                  labels: RangeLabels(lengthRange?.start.toStringAsFixed(1) ?? "0.0", lengthRange?.end.toStringAsFixed(1) ?? "1.0"),
                                                  divisions: ((model.crimeWalks.isNotEmpty ? model.crimeWalks.reduce((a,b) => a.length > b.length ? a : b).length : 1.0) * 10 - (model.crimeWalks.isNotEmpty ? model.crimeWalks.reduce((a,b) => a.length < b.length ? a : b).length : 0.0) * 10).toInt(),
                                                  onChanged: (range) {
                                                    setState(() {
                                                      lengthRange = range;
                                                    });

                                                    filterWalks(model);
                                                  }
                                              ),
                                            ],
                                          ),
                                          FilterableFlag(key: locationKey, values: Location.values, model: model),
                                          FilterableFlag(key: difficultyKey, values: Difficulty.values, model: model),
                                          FilterableFlag(key: transportTypeKey, values: TransportType.values, model: model),
                                          Wrap(children: [
                                            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Ignore Completed Walk:")),
                                            Checkbox(value: ignoreCompletedWalks, onChanged: (bool? value) {
                                              setState(() {
                                                ignoreCompletedWalks = value!;
                                              });

                                              filterWalks(model);
                                            })],
                                          ),
                                        ],
                                      ),
                                      // Apply filter and clear filtering buttons.
                                      Flexible(
                                        fit: FlexFit.loose, // Allow the child to take up less space
                                        child: Container(), // You can place an empty container or any widget here
                                      ),
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8, right: 4, bottom: 8),
                                                child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () => model.filterWalks(
                                                        int.parse(startYearController.value.text),
                                                        int.parse(endYearController.value.text),
                                                        crimeTypeKey.currentState!.state,
                                                        lengthRange!,
                                                        locationKey.currentState!.state,
                                                        difficultyKey.currentState!.state,
                                                        transportTypeKey.currentState!.state,
                                                        ignoreCompletedWalks),
                                                    child: const FittedBox(child: Text("Search")),
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 4, right: 8, bottom: 8),
                                                child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () => model.resetFilter(),
                                                    child: const FittedBox(child: Text("Clear")),
                                                ),
                                              ),
                                            ),
                                          ]
                                      ),
                                    ]
                                ),
                              ),
                              // Currently filtered walks.
                              Expanded(
                                child: SizedBox(
                                  // This is just supposed to be a decently sized box to show the filtered walks. Might need tuning.
                                  height: MediaQuery.of(context).size.height / 2.5,
                                  child: Scrollbar(
                                    child: ListView.separated(
                                      separatorBuilder: (context, index) {
                                        return const Divider();
                                      },
                                      itemBuilder: (context, index)
                                      {
                                        var walk = model.filteredWalks[index];

                                        return ListTile(
                                          title: Text(walk.name),
                                          subtitle: Text(walk.description),
                                          leading: Icon(walkIcons[walk.transportType]),
                                          titleAlignment: ListTileTitleAlignment.top,
                                          onTap: () => {
                                            showWalkSummary(context, model, walk)
                                          },
                                        );
                                      },
                                      itemCount: model.filteredWalks.length
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ) : const SizedBox(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    createButton()
                  ],
                ),
              ],
            ),
        ),
        if (model.userSettings.currentWalk != null) // Conditionally render the "walk stats" button
          Positioned(
            bottom: 8,
            left: 10,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                _showWalkStats(context, model);
              },
              child: const Text('Walk Stats'),
            ),
          ),
      ],
    );
  }
}

class FilterableFlag<T extends Enum> extends StatefulWidget
{
  const FilterableFlag({super.key, required this.values, required this.model});

  final List<T> values;
  final CrimeWalkModel model;

  @override
  State<StatefulWidget> createState() => _FilterableFlagState<T>();
}

class _FilterableFlagState<T extends Enum> extends State<FilterableFlag<T>>
{
  late T state;
  late List<T> enumValues;

  @override
  void initState()
  {
    super.initState();
    state = widget.values.first;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("${fancyEnumName(state)}:")),
        // Creates a dropdown menu of all the enum values but capitialised. Removes the enum prefix.
        DropdownButton(
          value: state,
          items: widget.values.map((T value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value.toString().split('.').last.replaceAll(RegExp('_'), ' ').capitalize()),
            );
          }).toList(),
          onChanged: (T? value) {
            setState(() {
              state = value!;
            });
          },
        ),
      ],
    );
  }

  String fancyEnumName(T value) {
    return value.toString().split('.').first.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });
  }
}