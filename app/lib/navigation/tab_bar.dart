import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget> tabs;

  const CustomTabBar(
      {Key? key,
      required this.currentIndex,
      required this.onTabSelected,
      required this.tabs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFFBFD2DB), width: 4),
        color: Color(0xFF206B8B),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs,
        ),
      ),
    );
  }
}
