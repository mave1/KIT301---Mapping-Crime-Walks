import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'crime_walk.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class FilteredList extends StatefulWidget
{
  const FilteredList({super.key});

  final EdgeInsets insets = const EdgeInsets.only(right: 12.0);

  @override
  _FilteredListState createState() => _FilteredListState();
}

class _FilteredListState extends State<FilteredList> with SingleTickerProviderStateMixin
{
  final startYearController = TextEditingController();
  final endYearController = TextEditingController();
  final crimeTypeKey = GlobalKey<_FilterableFlagState<CrimeType>>();
  final lengthKey = GlobalKey<_FilterableFlagState<Length>>();
  final locationKey = GlobalKey<_FilterableFlagState<Location>>();
  final difficultyKey = GlobalKey<_FilterableFlagState<Difficulty>>();
  final transportTypeKey = GlobalKey<_FilterableFlagState<TransportType>>();
  bool animateMenu = false;
  bool showMenu = false;
  late AnimationController animationController;

  @override
  void initState()
  {
    super.initState();

    startYearController.text = "0";
    endYearController.text = DateTime.timestamp().year.toString();

    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) setState(() { showMenu = false; });
    });
  }

  void animateMenuState()
  {
    setState(() {
      if (!showMenu) showMenu = true;

      animateMenu = !animateMenu;

      if (animateMenu) animationController.forward();
      else animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Consumer<CrimeWalkModel>(builder: createMenu);
  }

  // always visible? toggle actual menu when clicked. i.e. button + margin (8px?) + menu
  Widget createButton()
  {
    return Padding(
      padding: widget.insets,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(MediaQuery.of(context).size.width - 40 - widget.insets.right, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Search Walks"),
          onPressed: () => animateMenuState()
            // ANIMATE A NEW SCREEN INTO OPENING https://drive.google.com/file/d/1aLuebSfOxLSHfNO9XQEEtzAB-jmhArzx/view PAGE 5 (createMenu())
      ),
    );
  }

  Widget createMenu(BuildContext context, CrimeWalkModel model, _)
  {
    return Wrap(
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: animationController,
            curve: Curves.easeInOut,
          )),
          child: showMenu ?
          Column(
            children: [
              const Center(child: Text("Crime Walks Tasmania")), // TODO: translation string? https://pub.dev/packages/i18n_extension ?
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Padding(padding: EdgeInsets.only(right: 8), child: Text("Year Range:")),
                            SizedBox( // TODO: EXPANDED
                              width: 60,
                              child: TextField(
                                controller: startYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Start Year',
                                ),
                              ),
                            ),
                            SizedBox( // TODO: EXPANDED
                              width: 60,
                              child: TextField(
                                controller: endYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'End Year',
                                ),
                              ),
                            ),
                          ],
                        ),
                        FilterableFlag(key: crimeTypeKey, values: CrimeType.values),
                        FilterableFlag(key: lengthKey, values: Length.values),
                        FilterableFlag(key: locationKey, values: Location.values),
                        FilterableFlag(key: difficultyKey, values: Difficulty.values),
                        FilterableFlag(key: transportTypeKey, values: TransportType.values),
                        Row(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(right: 4),
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
                                          lengthKey.currentState!.state,
                                          locationKey.currentState!.state,
                                          difficultyKey.currentState!.state,
                                          transportTypeKey.currentState!.state),
                                      child: const Text("Search")
                                  )
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => model.resetFilter(),
                                      child: const Text("Clear")
                                  )
                              )
                            ]
                        ),
                      ]
                  ),
                  Expanded(child: Container(
                      height: MediaQuery.of(context).size.height / 2.5,
                      child: ListView.builder(itemBuilder: (context, index)
                      {
                        var walk = model.filteredWalks[index];

                        return ListTile(title: Text(walk.name), subtitle: Text(walk.description), leading: walk.transportType == TransportType.WALK ? const Icon(Icons.directions_walk) : const Icon(Icons.directions_car), onTap: () => print("TODO: open crime walk"));
                      },
                          itemCount: model.filteredWalks.length
                      )
                  ),
                  ),
                ],
              ),
            ],
          ) : const SizedBox(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: createButton()
          ),
        ),
      ]
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
    return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: Text("${fancyEnumName(state)}:")),
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
        )
    );
  }

  // Generated via copilot
  String fancyEnumName(T value)
  {
    return value.toString().split('.').first.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });
  }
}