

import 'package:flutter/material.dart';
import 'package:timezone/standalone.dart' as tz;

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}


extension DayOfWeekExtension on DayOfWeek {
  String get internalName {
    switch (this) {
      case DayOfWeek.monday:
        return 'MONDAY';
      case DayOfWeek.tuesday:
        return 'TUESDAY';
      case DayOfWeek.wednesday:
        return 'WEDNESDAY';
      case DayOfWeek.thursday:
        return 'THURSDAY';
      case DayOfWeek.friday:
        return 'FRIDAY';
      case DayOfWeek.saturday:
        return 'SATURDAY';
      case DayOfWeek.sunday:
        return 'SUNDAY';
    }
  }

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get deviceLetter {
    switch (this) {
      case DayOfWeek.monday:
        return 'M';
      case DayOfWeek.tuesday:
        return 'T';
      case DayOfWeek.wednesday:
        return 'W';
      case DayOfWeek.thursday:
        return 'T';
      case DayOfWeek.friday:
        return 'F';
      case DayOfWeek.saturday:
        return 'S';
      case DayOfWeek.sunday:
        return 'S';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  static DayOfWeek byInternalName(String name) {
    switch(name) {
      case 'MONDAY':
        return DayOfWeek.monday;
      case 'TUESDAY':
        return DayOfWeek.tuesday;
      case 'WEDNESDAY':
        return DayOfWeek.wednesday;
      case 'THURSDAY':
        return DayOfWeek.thursday;
      case 'FRIDAY':
        return DayOfWeek.friday;
      case 'SATURDAY':
        return DayOfWeek.saturday;
      case 'SUNDAY':
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.sunday;
    }
  }
}

class TimeService {
  static const List<String> DAYS_OF_WEEK = <String>['MONDAY', 'TUESDAY',
    'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  DateTime now = DateTime.now();

  DateTime serverTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
  }

  DateTime timeToLocal(DateTime serverTime) {
    return serverTime
        //.add(now.timeZoneOffset)
        .toLocal();
  }

  DateTime serverTimeToLocal(int timestamp) {
    return timeToLocal(serverTime(timestamp));
  }

  int parseDayOfWeek(String dow) {
    return DAYS_OF_WEEK.indexOf(dow);
  }

  String dayOfWeekToString(int dow) {
    return DAYS_OF_WEEK[dow];
  }


}

TimeOfDay timeOfDayFromSecondsFrom00(int secondsFrom00, {bool isUTC = true}) {
  DateTime dt;
  if(isUTC) {
    dt = DateTime.utc(0, 1, 1, 0, 0, secondsFrom00).toLocal();
  } else {
    dt = DateTime(0, 1, 1, 0, 0, secondsFrom00);
  }
  var tod = TimeOfDay.fromDateTime(dt);
  return tod;
}

extension TimeOfDayExtension on TimeOfDay {
  int toSecondsFrom00() {
    return (hour * 3600) + (minute * 60);
  }
}

class TimeOfDayOfWeek {
  late int dayOfWeek;
  late int offsetFrom00;
  final bool isUTC;
  late Duration duration;

  TimeOfDayOfWeek({
    required this.dayOfWeek,
    required this.offsetFrom00,
    required this.isUTC
  }) {
    duration = Duration(seconds: offsetFrom00);
  }

  TimeOfDayOfWeek.fromString({
    required String dowString,
    required this.offsetFrom00,
    required this.isUTC
  }) {
    duration = Duration(seconds: offsetFrom00);
    dayOfWeek = TimeService().parseDayOfWeek(dowString);
  }

  TimeOfDayOfWeek.fromTimeOfDay({
    required this.dayOfWeek,
    required TimeOfDay tod,
    required this.isUTC
  }) {
    offsetFrom00 = (tod.hour * 3600) + (tod.minute * 60);
    duration = Duration(seconds: offsetFrom00);
  }


  TimeOfDayOfWeek adjust(bool positive, bool isUTC) {

    int tzOffset = DateTime.now().timeZoneOffset.inSeconds;
    var dur = Duration(seconds: positive ? offsetFrom00 + tzOffset
                                         : offsetFrom00 - tzOffset);

    var epoch = DateTime.fromMillisecondsSinceEpoch(1, isUtc: true);
    var relativeToEpoch = epoch.add(dur);

    int deltaDays = relativeToEpoch.weekday - epoch.weekday;

    return TimeOfDayOfWeek(
        dayOfWeek: (dayOfWeek + deltaDays) % 7,
        offsetFrom00: (relativeToEpoch.hour * 3600) + (relativeToEpoch.minute * 60) + relativeToEpoch.second,
        isUTC: isUTC
    );
  }

  TimeOfDayOfWeek toLocal() {
    if(!isUTC) {
      return this;
    }
    return adjust(true, false);
  }

  TimeOfDayOfWeek toUTC() {
    if(isUTC) {
      return this;
    }
    return adjust(false, true);
  }

  String dayOfWeekString() {
    return TimeService().dayOfWeekToString(dayOfWeek);
  }

  TimeOfDay toTimeOfDay() {
    List<String> parts = duration.toString().split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class FilterableTimeZoneProvider extends ChangeNotifier {
  Map<String, tz.Location>? get zones => _zones;
  Map<String, tz.Location>? _zones;
  String? _filter;
  String? get filterBy => _filter;
  List<tz.Location> _filteredZones = List.empty(growable: false);
  List<tz.Location> get filteredZones => _filteredZones;

  FilterableTimeZoneProvider() {
    _zones = tz.timeZoneDatabase.locations
        .map((key, value) {
          String index = value.name.replaceAll("/", " ")
              .replaceAll("_", " ");
          index += " ${value.currentTimeZone.abbreviation}";
          return MapEntry(
              index.toLowerCase(),
              value
          );
        });
  }

  Future<List<tz.Location>> filter(String? filterBy) {
    String? fb = filterBy?.toLowerCase().replaceAll(RegExp("[^a-z0-9]"), "");
    _filter = filterBy;
    if (filterBy == null || filterBy!.isEmpty) {
      _filteredZones = List.empty(growable: false);
      notifyListeners();
      return Future.value(_filteredZones);
    } else {
      _filteredZones = _zones?.entries
          .where((element) => element.key.contains(fb!))
          .map((e) => e.value)
          .toList(growable: false) ?? List.empty(growable: false);
      notifyListeners();
      return Future.value(
          _filteredZones
      );
    }
  }

}

typedef TimeZone = tz.TimeZone;
typedef TimeZoneLocation = tz.Location;

TimeZone? lookupTimeZone(String? tzString) {
  if(tzString == null) {
    return null;
  }
  return tz.timeZoneDatabase.locations[tzString]?.currentTimeZone;
}

TimeZoneLocation? lookupTimeZoneLocation(String? tzString) {
  if(tzString == null) {
    return null;
  }
  return tz.timeZoneDatabase.locations[tzString];
}