import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/standalone.dart' as tz;

part 'filterable_timezone_provider.g.dart';

@riverpod
class FilterableTimeZone extends _$FilterableTimeZone {
  Map<String, tz.Location> _zones = {};

  @override
  List<tz.Location> build() {
    _zones = tz.timeZoneDatabase.locations.map((key, value) {
      String index = value.name.replaceAll("/", " ").replaceAll("_", " ");
      index += " ${value.currentTimeZone.abbreviation}";
      return MapEntry(index.toLowerCase(), value);
    });
    return [];
  }

  void filter(String? filterBy) {
    if (filterBy == null || filterBy.isEmpty) {
      state = [];
    } else {
      final fb = filterBy.toLowerCase().replaceAll(RegExp("[^a-z0-9]"), "");
      state = _zones.entries
          .where((element) => element.key.contains(fb))
          .map((e) => e.value)
          .toList(growable: false);
    }
  }
}
