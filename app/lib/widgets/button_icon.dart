import 'package:flutter/material.dart';

class ButtonIcon extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDisabled;

  const ButtonIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 72,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          primary: isDisabled ? Colors.grey : Colors.white,
          onPrimary: const Color(0xFF5796A9),
          side: BorderSide(
            color: isDisabled ? Colors.grey[700]! : const Color(0xFF5796A9),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
