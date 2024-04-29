import 'package:crimewalksapp/crime_walk.dart';
import 'package:flutter/material.dart';

enum CrimeType
{
  ALL
}

enum Length
{
  ALL
}

enum Location
{
  ALL,
  HOBART,
  LAUNCESTON
}

enum Difficulty
{
  ALL
}

enum TransportType
{
  ALL,
  WALK,
  CAR
}

class CrimeWalk
{
  CrimeWalk({required this.name, required this.description, required this.yearOccurred, required this.crimeType, required this.length, required this.location, required this.difficulty, required this.transportType});

  String name;
  String description;
  int yearOccurred;
  CrimeType crimeType;
  Length length;
  Location location;
  Difficulty difficulty;
  TransportType transportType;
}

class CrimeWalkModel extends ChangeNotifier
{
  final List<CrimeWalk> crimeWalks = [];
  final List<CrimeWalk> filteredWalks = [];

  CrimeWalkModel()
  {
    crimeWalks.add(CrimeWalk(name: "The Crime Walk", description: "A walk through the city of Hobart", yearOccurred: 2021, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive", description: "A drive through the city of Launceston", yearOccurred: 2000, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 2", description: "A walk through the city of Launceston", yearOccurred: 1980, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 2", description: "A drive through the city of Hobart", yearOccurred: 1990, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 3", description: "A drive through the city of Launceston", yearOccurred: 1500, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Drive 4", description: "A drive through the city of Launceston", yearOccurred: 1670, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.CAR));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 3", description: "A walk through the city of Hobart", yearOccurred: 1280, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.HOBART, difficulty: Difficulty.ALL, transportType: TransportType.WALK));
    crimeWalks.add(CrimeWalk(name: "The Crime Walk 4", description: "A walk through the city of Hobart", yearOccurred: 1800, crimeType: CrimeType.ALL, length: Length.ALL, location: Location.LAUNCESTON, difficulty: Difficulty.ALL, transportType: TransportType.WALK));

    resetFilter();
  }

  void resetFilter()
  {
    filterWalks(0, -1 >>> 1, CrimeType.ALL, Length.ALL, Location.ALL, Difficulty.ALL, TransportType.ALL);
  }

  void filterWalks(int minYear, int maxYear, CrimeType crimeType, Length length, Location location, Difficulty difficulty, TransportType transportType)
  {
    filteredWalks.clear();

    for (var element in crimeWalks) {
      if (element.yearOccurred >= minYear && element.yearOccurred <= maxYear && (crimeType == CrimeType.ALL || element.crimeType == crimeType) && (length == Length.ALL || element.length == length) && (location == Location.ALL || element.location == location) && (difficulty == Difficulty.ALL || element.difficulty == difficulty) && (transportType == TransportType.ALL || element.transportType == transportType)) filteredWalks.add(element);
    }

    update();
  }

  void addCrimeWalk(CrimeWalk crimeWalk)
  {
    crimeWalks.add(crimeWalk);
  }

  void update()
  {
    notifyListeners();
  }
}