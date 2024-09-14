import 'package:crimewalksapp/crime_walk.dart';

class UserSettings {
  CrimeWalk? currentWalk;

  double currentLat = 0.0;
  double currentLong = 0.0;

  // These are the locations for the current walk
  List<CrimeWalkLocation> locationsReached = [];

  List<CrimeWalk> completedWalks = [];
  List<CrimeWalk> bookmarkedWalks = [];

  void finishWalk()
  {
    if (currentWalk != null)
    {
      completedWalks.add(currentWalk!);

      currentWalk = null;
      locationsReached.clear();
    }
  }

}