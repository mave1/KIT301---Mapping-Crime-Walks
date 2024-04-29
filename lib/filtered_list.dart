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
  CrimeType crimeType = CrimeType.ALL;
  Length length = Length.ALL;
  Location location = Location.ALL;
  Difficulty difficulty = Difficulty.ALL;
  TransportType transportType = TransportType.ALL;


  @override
  Widget build(BuildContext context)
  {
    return Consumer<CrimeWalkModel>(builder: createMenu);
  }

  // always visible? toggle actual menu when clicked. i.e. button + margin (4px?) + menu
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
          onPressed: () => print("Search Walks") // ANIMATE A NEW SCREEN INTO OPENING https://drive.google.com/file/d/1aLuebSfOxLSHfNO9XQEEtzAB-jmhArzx/view PAGE 5
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
                  const FilterableFlag(values: CrimeType.values),
                  const FilterableFlag(values: Length.values),
                  const FilterableFlag(values: Location.values),
                  const FilterableFlag(values: Difficulty.values),
                  const FilterableFlag(values: TransportType.values),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => model.filterWalks(0, -1 >>> 1, crimeType, length, location, difficulty, transportType),
                        child: Text("Search")),
                      ElevatedButton(
                        onPressed: () => model.resetFilter(),
                        child: Text("Clear"))
                    ]
                  ),
                ]
              ),
              Expanded(child: Container(
                  height: MediaQuery.of(context).size.height / 2.5,
                  child: ListView.builder(itemBuilder: (context, index)
                    {
                      var walk = model.crimeWalks[index];

                      return ListTile(title: Text(walk.name), leading: walk.transportType == TransportType.WALK ? const Icon(Icons.directions_walk) : const Icon(Icons.directions_car), onTap: () => print("TODO: open crime walk"));
                    },
                    itemCount: model.crimeWalks.length
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
  State<StatefulWidget> createState() => _FilterableFlagState();
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

  // Generated via copilot
  String fancyEnumName(T value)
  {
    return value.toString().split('.').first.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });
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
}