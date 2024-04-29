import 'package:flutter/material.dart';
import 'crime_walk.dart';

class FilteredList extends StatefulWidget {
  const FilteredList({super.key});

  final EdgeInsets insets = const EdgeInsets.only(right: 12.0);

  @override
  _FilteredListState createState() => _FilteredListState();
}

class _FilteredListState extends State<FilteredList>{
  final List<CrimeWalk> filteredList = [];

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => print("Search Walks")),
    );
  }
}