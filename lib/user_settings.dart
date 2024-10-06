import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/main.dart';
import 'package:flutter/cupertino.dart';

class UserSettings {
  CrimeWalk? currentWalk;

  double currentLat = 0.0;
  double currentLong = 0.0;

  // Walk stats for current walk
  int checkpointsHit = 0; // TODO:
  double distanceWalked = 0.0; // TODO:
  var walkStarted = DateTime.now();
  DateTime? walkEnded;

  String getTimeElapsed()
  {
    // var split = timeElapsed.toString().split(RegExp(':'));
    var diff = (walkEnded ?? DateTime.now()).difference(walkStarted);
    var split = diff.toString().split(RegExp(':'));

    return '${split[0]}:${split[1]}';
  }

  // These are the locations for the current walk
  List<CrimeWalkLocation> locationsReached = [];

  List<CrimeWalk> bookmarkedWalks = [];

  CrimeWalkLocation? getNextLocation()
  {
    return currentWalk!.locations.length != locationsReached.length ? currentWalk!.locations.firstWhere((location) => !locationsReached.contains(location)) : null;
  }

  bool isAtEndOfWalk()
  {
    return currentWalk!.locations.length == locationsReached.length;
  }

  void setActiveCheckpoint(CrimeWalkLocation location) {
    if (currentWalk != null && !currentWalk!.isCompleted)
    {
      locationsReached = [];

      CrimeWalkLocation? previous = location.previous;

      while (previous != null)
      {
        locationsReached.add(previous);
        previous = previous.previous;
      }
    }
  }

  void checkpointReached(BuildContext context, CrimeWalkModel model)
  {
    var nextLocation = getNextLocation();

    nextLocation!.createMenu(context, model, currentWalk!, false);

    locationsReached.add(nextLocation);
    checkpointsHit += 1;

    if (locationsReached.last.next == null)
    {
      _finishWalk();
    }
  }

  void cancelWalk(CrimeWalkModel? model)
  {
    currentWalk = null;
    locationsReached.clear();

    // TODO: ask maeve
    // _finishWalk();
    model?.update();

    appStateKey.currentState!.getCoordinates("-1", "-1", TransportType.ALL, false);
  }

  void startWalk(CrimeWalk walk, CrimeWalkModel? model)
  {
    currentWalk = walk;
    walkStarted = DateTime.now();
    locationsReached = [];
    walkEnded = null;
    distanceWalked = 0;
    checkpointsHit = 0;

    appStateKey.currentState!.updateRoute(null);

    model?.update();
  }

  void _finishWalk()
  {
    if (currentWalk != null)
    {
      currentWalk!.isCompleted = true;
      walkEnded = DateTime.now();

      appStateKey.currentState!.getCoordinates("-1", "-1", TransportType.ALL, false);
      // Let user see these stats.
      // currentWalk = null;
      // locationsReached.clear();
      //
      // checkpointsHit = 0;
      // distanceWalked = 0.0;
    }
  }
}