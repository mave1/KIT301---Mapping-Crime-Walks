import 'package:crimewalksapp/crime_walk.dart';

class UserSettings {
  CrimeWalk? currentWalk;

  double currentLat = 0.0;
  double currentLong = 0.0;

  // Walk stats for current walk
  int checkpointsHit = 0;
  double distanceWalked = 0.0;
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

  void finishWalk()
  {
    if (currentWalk != null)
    {
      currentWalk!.isCompleted = true;

      currentWalk = null;
      locationsReached.clear();

      checkpointsHit = 0;
      distanceWalked = 0.0;
    }
  }

}