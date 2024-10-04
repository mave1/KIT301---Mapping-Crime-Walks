import 'package:crimewalksapp/crime_walk.dart';

class UserSettings {
  CrimeWalk? currentWalk;

  double currentLat = 0.0;
  double currentLong = 0.0;

  // Walk stats for current walk
  int checkpointsHit = 0; // TODO:
  double distanceWalked = 0.0; // TODO:
  var walkStarted = DateTime.now();

  String getTimeElapsed()
  {
    // var split = timeElapsed.toString().split(RegExp(':'));
    var diff = DateTime.now().difference(walkStarted);
    var split = diff.toString().split(RegExp(':'));

    return '${split[0]}:${split[1]}';
  }

  // These are the locations for the current walk
  List<CrimeWalkLocation> locationsReached = [];

  List<CrimeWalk> bookmarkedWalks = [];

  CrimeWalkLocation getNextLocation()
  {
    return locationsReached.firstWhere((location) => !currentWalk!.locations.contains(location));
  }

  void checkpointReached()
  {
    locationsReached.add(getNextLocation());
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

    model?.update();
  }

  void startWalk(CrimeWalk walk, CrimeWalkModel? model)
  {
    currentWalk = walk;
    walkStarted = DateTime.now();
    distanceWalked = 0;
    checkpointsHit = 0;

    // TODO: GENERATE AUTO UPDATING PATH FROM CURRENT LOCATION TO FIRST LOCATION - HOW?
    // TODO: MAYBE LET OTHER POINT AS START?

    // ONCE REACHES POINT DISPLAY CHECKPOINT INFO AND GENERATE UPDATING ROUTE FROM CURRENT LOCATION TO NEXT POINT
    // REPEAT UNTIL DONE

    // ONCE DONE SHOW DIFFERENT SCREEN?

    // userSettings.finishWalk();

    model?.update();
  }

  void _finishWalk()
  {
    if (currentWalk != null)
    {
      currentWalk!.isCompleted = true;

      // Let user see these stats.
      // currentWalk = null;
      // locationsReached.clear();
      //
      // checkpointsHit = 0;
      // distanceWalked = 0.0;
    }
  }
}