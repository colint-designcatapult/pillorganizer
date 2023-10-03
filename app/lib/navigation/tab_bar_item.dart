import 'package:flutter/material.dart';

class CustomTabBarItem extends StatelessWidget {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomTabBarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 8.0),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 300), // Choose your duration
              child: isSelected
                  ? KeyedSubtree(
                      key: const ValueKey<int>(1), // Unique key for filled icon
                      child: selectedIcon,
                    )
                  : KeyedSubtree(
                      key:
                          const ValueKey<int>(0), // Unique key for outline icon
                      child: icon,
                    ),
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Opacity(
                opacity: isSelected ? 1 : 0,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14)),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isSelected
                          ? Container(
                              key: const ValueKey<int>(2),
                              width: 54.0,
                              height: 4.0,
                              color: const Color(0xFFBFD2DB),
                            )
                          : Container(
                              key: const ValueKey<int>(3),
                              width: 54.0,
                              height: 4.0,
                              color: Colors.transparent,
                            ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
