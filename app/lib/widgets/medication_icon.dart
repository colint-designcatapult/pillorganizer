import 'package:app/api/medication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MedicationIcon extends StatelessWidget {
  const MedicationIcon(
      {super.key,
      required this.size,
      required this.shape,
      required this.color});

  factory MedicationIcon.fromMed(ScheduledMedication med, double size) {
    return MedicationIcon(size: size, shape: med.shape, color: med.color);
  }

  final double size;
  final MedicationShape? shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Stack(children: [
          Center(
              child: SvgPicture.asset(_iconAssets(),
                  colorFilter: ColorFilter.mode(
                      color ?? Theme.of(context).iconTheme.color!,
                      BlendMode.modulate))),
        ]),
      ),
    );
  }

//Will need more icons and to have every MedicationShape icons
  String _iconAssets() {
    switch (shape) {
      case MedicationShape.hexagon:
        return "lib/assets/SVG/pills/hexagon.svg";
      case MedicationShape.round:
        return 'lib/assets/SVG/pills/round.svg';
      case MedicationShape.triangle:
        return "lib/assets/SVG/pills/triangle.svg";
      case MedicationShape.doubleCircle:
        return "lib/assets/SVG/pills/doubleCircle.svg";
      case MedicationShape.tear:
        return "lib/assets/SVG/pills/tear.svg";
      case MedicationShape.square:
        return "lib/assets/SVG/pills/square.svg";
      case MedicationShape.pentagon:
        return "lib/assets/SVG/pills/pentagon.svg";
      case MedicationShape.capsule:
        return 'lib/assets/SVG/pills/capsule.svg';
      default:
        return "lib/assets/SVG/pills/capsule.svg";
    }
  }
}

class HorizontalPillShapeSelectorOption extends StatelessWidget {
  const HorizontalPillShapeSelectorOption(
      {super.key,
      required this.shape,
      required this.color,
      required this.selected,
      required this.onTap});

  final MedicationShape shape;
  final Color color;
  final bool selected;
  final Function(MedicationShape) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(shape),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: const Color.fromARGB(16, 0, 0, 0),
            border: selected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2.0)
                : const Border()),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MedicationIcon(size: 40, shape: shape, color: color),
          ],
        ),
      ),
    );
  }
}

class PillShapeSelector extends StatefulWidget {
  const PillShapeSelector(
      {super.key, this.color = Colors.white, this.selected, this.onChange});

  final Color? color;
  final MedicationShape? selected;
  final Function(MedicationShape?)? onChange;

  @override
  State<StatefulWidget> createState() => _PillShapeSelectorState();
}

class _PillShapeSelectorState extends State<PillShapeSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Shape',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 28)),
        const SizedBox(height: 12),
        GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 28,
            mainAxisSpacing: 28,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...MedicationShape.values
                  .map((e) => HorizontalPillShapeSelectorOption(
                        shape: e,
                        color: widget.color ?? Colors.white,
                        selected: widget.selected == e,
                        onTap: (val) => widget.onChange != null
                            ? widget.onChange!(val)
                            : {},
                      ))
            ])
      ],
    );
  }
}

class MedicationColorSelectorColor extends StatelessWidget {
  final Color color;
  final bool selected;
  final Icon? icon;
  final Function(Color?) onTap;

  const MedicationColorSelectorColor(
      {super.key,
      required this.color,
      this.selected = false,
      this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: color,
          border: selected
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 4,
                )
              : icon != null
                  ? Border.all(
                      color: Theme.of(context).secondaryHeaderColor,
                      width: 2,
                    )
                  : null,
        ),
        child: icon,
      ),
    );
  }
}

class MedicationColorSelector extends StatelessWidget {
  const MedicationColorSelector({super.key, this.selected, this.onChange});

  final List<Color> commonColors = const [
    Color.fromARGB(255, 232, 232, 232),
    Color.fromARGB(255, 149, 173, 195),
    Color.fromARGB(255, 234, 178, 161),
    Color.fromARGB(255, 201, 175, 173),
    Color.fromARGB(255, 204, 175, 105),
    Color.fromARGB(255, 229, 165, 174),
    Color.fromARGB(255, 227, 232, 149)
  ];

  final Color? selected;
  final Function(Color?)? onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Color',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 28)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 28,
          mainAxisSpacing: 28,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...commonColors
                .map((e) => MedicationColorSelectorColor(
                      color: e,
                      selected: e == selected,
                      onTap: (color) => onChange!(color),
                    ))
                .toList(growable: false),
            MedicationColorSelectorColor(
              color: Colors.white30,
              icon: const Icon(Icons.colorize),
              onTap: (color) => onChange!(color),
            )
          ],
        )
      ],
    );
  }
}
