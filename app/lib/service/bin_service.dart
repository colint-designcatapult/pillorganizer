import 'package:flutter/material.dart';

class BinService {
  static DayPeriod binDayPeriod(int binID) {
    return binID % 2 == 1 ? DayPeriod.am : DayPeriod.pm;
  }
}
