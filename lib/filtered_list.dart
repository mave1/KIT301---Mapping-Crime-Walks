import 'package:crimewalksapp/walk_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool animateMenu = false;
  bool showMenu = false;
  bool onWalk = false; // Add the onWalk variable
  late AnimationController animationController;

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
  void _showWalkStats(BuildContext context, CrimeWalk walk) {
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
                              },
                              child: const Text('End Walk')
                          ),
                        ),
                      ]
                  ),
                  const Divider(), // Add a divider between fields
                  _buildSummaryField('Distance Walked', '1360m', false),
                  _buildSummaryField('Checkpoints Hit', '4', false),
                  _buildSummaryField('Time Elapsed', '5:03', true),
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

  // The menu that appears when you click on the Search Walks/createButton button.
  Widget createMenu(BuildContext context, CrimeWalkModel model, _)
  {
    return Stack(
        children: [
          IntrinsicHeight(
            child: Column(
              children: [
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.white, // The colour of the menu
                      ),
                      child: Column(
                        children: [
                          // Title
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Center(child: Text("Crime Walks Tasmania")),
                          ),
                          // Filtering options
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FilterableFlag(key: crimeTypeKey, values: CrimeType.values),
                                    // FilterableFlag(key: lengthKey, values: Length.values), // TODO: FIX UP WITH DOUBLE SLIDER
                                    FilterableFlag(key: locationKey, values: Location.values),
                                    FilterableFlag(key: difficultyKey, values: Difficulty.values),
                                    FilterableFlag(key: transportTypeKey, values: TransportType.values),
                                    // Apply filter and clear filtering buttons.
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                                      0.0,
                                                      // lengthKey.currentState!.state, //TODO:
                                                      locationKey.currentState!.state,
                                                      difficultyKey.currentState!.state,
                                                      transportTypeKey.currentState!.state),
                                                  child: const Text("Search")
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () => model.resetFilter(),
                                                  child: const Text("Clear")
                                              ),
                                            ),
                                          )
                                        ]
                                    ),
                                  ]
                              ),
                              // Currently filtered walks.
                              Expanded(child: SizedBox(
                                  // This is just supposed to be a decently sized box to show the filtered walks. Might need tuning.
                                  height: MediaQuery.of(context).size.height / 2.5,
                                  child: ListView.builder(itemBuilder: (context, index)
                                  {
                                    var walk = model.filteredWalks[index];

                                    return ListTile(
                                      title: Text(walk.name),
                                      subtitle: Text(walk.description),
                                      leading: walk.transportType == TransportType.WALK ? const Icon(Icons.directions_walk) : const Icon(Icons.directions_car),
                                      onTap: () => {
                                        showWalkSummary(context, model, walk)
                                      },
                                    );
                                  },
                                      itemCount: model.filteredWalks.length
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
            bottom: 10,
            left: 10,
            child: ElevatedButton(
              onPressed: () {
                var walk = model.filteredWalks[1];
                _showWalkStats(context, walk);
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
  const FilterableFlag({super.key, required this.values});

  final List<T> values;

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
    return Row(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("${fancyEnumName(state)}:")),
        // Creates a dropdown menu of all the enum values but capitialised. Removes the enum prefix.
        DropdownButton(
          value: state,
          items: widget.values.map((T value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value.toString().split('.').last.capitalize()),
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
