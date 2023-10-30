import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ButtonIconText extends StatelessWidget {
  final String text;
  final IconData iconData;
  final VoidCallback onPressed;
  const ButtonIconText(
      {super.key,
      required this.text,
      required this.iconData,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Color textColor = text == AppLocalizations.of(context)!.delete
        ? const Color(0XFFA11106)
        : const Color(0XFF03012C);
    Color underlineColor = text == AppLocalizations.of(context)!.delete
        ? const Color(0XFFA11106)
        : const Color(0XFF03012C);

    TextStyle? textStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          decoration: TextDecoration.combine([
            TextDecoration.underline,
          ]),
          decorationColor: underlineColor,
          color: textColor,
        );
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(iconData, color: textColor),
          const SizedBox(width: 1.0),
          Text(
            text,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
