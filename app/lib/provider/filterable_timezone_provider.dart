import 'package:flutter/material.dart';
import 'package:timezone/standalone.dart' as tz;

class FilterableTimeZoneProvider extends ChangeNotifier {
  Map<String, tz.Location>? get zones => _zones;
  Map<String, tz.Location>? _zones;
  String? _filter;
  String? get filterBy => _filter;
  List<tz.Location> _filteredZones = List.empty(growable: false);
  List<tz.Location> get filteredZones => _filteredZones;

  FilterableTimeZoneProvider() {
    _zones = tz.timeZoneDatabase.locations.map((key, value) {
      String index = value.name.replaceAll("/", " ").replaceAll("_", " ");
      index += " ${value.currentTimeZone.abbreviation}";
      return MapEntry(index.toLowerCase(), value);
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
              .toList(growable: false) ??
          List.empty(growable: false);
      notifyListeners();
      return Future.value(_filteredZones);
    }
  }
}
