
import 'package:app/api/medication.dart';
import 'package:flutter/material.dart';

class MedicationIcon extends StatelessWidget {
  const MedicationIcon({super.key, required this.size, required this.shape, required this.color});

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
        child: Stack(
            children: [
              Center(
                child: Image.asset(_assetColor(),
                    width: size * _sizeModifier(),
                    color: color ?? Theme.of(context).iconTheme.color),
              ),
              Center(
                  child: Image.asset(_assetFG(), width: size * _sizeModifier())
              ),
            ]
        ),
      ),
    );
  }

  String _assetFG() {
    switch(shape) {
      case MedicationShape.capsule:
        return "lib/assets/meds/CAPSULE_FG.png";
      case MedicationShape.diamond:
        return "lib/assets/meds/DIAMOND_FG.png";
      case MedicationShape.oval:
        return "lib/assets/meds/OVAL_FG.png";
      case MedicationShape.rectangle:
        return "lib/assets/meds/RECTANGLE_FG.png";
      case MedicationShape.round:
        return "lib/assets/meds/ROUND_FG.png";
      case MedicationShape.square:
        return "lib/assets/meds/SQUARE_FG.png";
      default:
        return "lib/assets/meds/UNK_FG.png";
    }
  }

  String _assetColor() {
    switch(shape) {
      case MedicationShape.capsule:
        return "lib/assets/meds/CAPSULE_COLOR.png";
      case MedicationShape.diamond:
        return "lib/assets/meds/DIAMOND_COLOR.png";
      case MedicationShape.oval:
        return "lib/assets/meds/OVAL_COLOR.png";
      case MedicationShape.rectangle:
        return "lib/assets/meds/RECTANGLE_COLOR.png";
      case MedicationShape.round:
        return "lib/assets/meds/ROUND_COLOR.png";
      case MedicationShape.square:
        return "lib/assets/meds/SQUARE_COLOR.png";
      default:
        return "lib/assets/meds/UNK_COLOR.png";
    }
  }

  double _sizeModifier() {
    switch(shape) {
      case MedicationShape.square: return 0.75;
      case MedicationShape.round: return 0.75;
      default: return 1;
    }
  }

}

class HorizontalPillShapeSelectorOption extends StatelessWidget {
  const HorizontalPillShapeSelectorOption({super.key,
    required this.shape, required this.color, required this.selected,
    required this.onTap });

  final MedicationShape shape;
  final Color color;
  final bool selected;
  final Function(MedicationShape) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => onTap(shape),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color.fromARGB(16, 0, 0, 0),
            border: selected ? Border.all(
              color: Theme.of(context).hintColor,
              width: 2.0
            ) : const Border()
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MedicationIcon(size: 64, shape: shape, color: color),
              Text(
                  '${shape.displayName}',
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }

}

class PillShapeSelector extends StatefulWidget {
  const PillShapeSelector({super.key, this.color = Colors.white, this.selected, this.onChange});

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
        Text('Choose a Shape', style: Theme.of(context).textTheme.titleSmall),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...MedicationShape.values.map((e) =>
                HorizontalPillShapeSelectorOption(
                  shape: e,
                  color: widget.color ?? Colors.white,
                  selected: widget.selected == e,
                  onTap: (val) => widget.onChange != null ? widget.onChange!(val) : {},
                ))
          ]
        )
      ],
    );
  }

}

class MedicationColorSelectorColor extends StatelessWidget {

  final Color color;
  final bool selected;
  final Icon? icon;
  final Function(Color?) onTap;

  const MedicationColorSelectorColor({
    super.key,
    required this.color,
    this.selected = false,
    this.icon,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => onTap(color),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(64)),
            color: color,
            border: Border.all(
              color: selected ? Theme.of(context).hintColor : Theme.of(context).shadowColor,
              width: 2
            ),
            boxShadow: [BoxShadow(
                offset: Offset.fromDirection(1),
                blurRadius: 1,
                color: Colors.black.withAlpha(100),
                spreadRadius: 1
            )]
          ),
          child: icon,
        ),
      ),
    );
  }

}


class MedicationColorSelector extends StatelessWidget {
  const MedicationColorSelector({
    super.key,
    this.selected,
    this.onChange
  });

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
        Text('Choose a Color', style: Theme.of(context).textTheme.titleSmall),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...commonColors.map((e) => MedicationColorSelectorColor(
              color: e,
              selected: e == selected,
              onTap: (color) => onChange!(color),
            ))
                .toList(growable: false),
            MedicationColorSelectorColor(
              color: Colors.white30,
              icon: Icon(Icons.colorize),
              onTap: (color) => onChange!(color),
            )
          ],
        )
      ],
    );
  }

}