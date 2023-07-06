
import 'package:flutter/material.dart';

class BinService {
  static const List<String> binIDNames = [
    "Mon PM", "Mon AM",
    "Tue PM", "Tue AM",
    "Wed PM", "Wed AM",
    "Thu PM", "Thu AM",
    "Fri PM", "Fri AM",
    "Sat PM", "Sat AM",
    "Sun PM", "Sun AM"
  ];
  static const List<String> binIDLabels = [
    "M", "M", "T", "T", "W", "W", "T", "T", "F", "F", "S", "S", "S", "S"
  ];

  static String binName(int binID) {
    return binIDNames[binID];
  }
  static String binLabel(int binID) {
    return binIDLabels[binID];
  }
  static DayPeriod binDayPeriod(int binID) {
    return binID % 2 == 1 ? DayPeriod.am : DayPeriod.pm;
  }
}