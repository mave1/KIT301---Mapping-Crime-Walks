import 'package:crimewalksapp/filtered_list.dart';
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

class _FilteredListState extends State<FilteredList>
{
  final GlobalKey<_FilterableFlagState<CrimeType>> crimeTypeKey = GlobalKey();
  final GlobalKey<_FilterableFlagState<Length>> lengthKey = GlobalKey();
  final GlobalKey<_FilterableFlagState<Location>> locationKey = GlobalKey();
  final GlobalKey<_FilterableFlagState<Difficulty>> difficultyKey = GlobalKey();
  final GlobalKey<_FilterableFlagState<TransportType>> transportTypeKey = GlobalKey();

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
          onPressed: () => print("Search Walks") // ANIMATE A NEW SCREEN INTO OPENING https://drive.google.com/file/d/1aLuebSfOxLSHfNO9XQEEtzAB-jmhArzx/view PAGE 5 (createMenu())
      ),
    );
  }

  Widget createMenu(BuildContext context, CrimeWalkModel model, _)
  {
    return Scaffold(
      body: Column(
        children: [
          const Center(child: Text("Crime Walks Tasmania")), // TODO: translation string? https://pub.dev/packages/i18n_extension ?
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  // Row( // TODO: year range
                  //   children: [
                  //     const Padding(padding: EdgeInsets.only(right: 8), child: Text("Year Range:")),
                  //     TextField(
                  //       decoration: const InputDecoration(
                  //         border: OutlineInputBorder(),
                  //         labelText: 'Start Year',
                  //       ),
                  //     ),
                  //     TextField(
                  //       decoration: const InputDecoration(
                  //         border: OutlineInputBorder(),
                  //         labelText: 'End Year',
                  //       ),
                  //     ),
                  //   ],
                  // ),
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
                              0,
                              -1 >>> 1,
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

                      return ListTile(title: Text(walk.name), leading: walk.transportType == TransportType.WALK ? const Icon(Icons.directions_walk) : const Icon(Icons.directions_car), onTap: () => print("TODO: open crime walk"));
                    },
                    itemCount: model.filteredWalks.length
                  )
                ),
              ),
            ],
          ),
        ]
      ),
      floatingActionButton: createButton(),
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