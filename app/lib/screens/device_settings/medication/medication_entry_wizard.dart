import 'package:app/api/medication.dart';
import 'package:app/api/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../../../api/api.dart';
import '../../../widgets/device_icon.dart';
import '../../../widgets/medication_icon.dart';

part 'medication_entry_wizard.freezed.dart';

enum NewMedicationStage {
  name,
  appearance,
  schedule
}

@freezed
class NewMedicationState with _$NewMedicationState {
  const factory NewMedicationState({
    ScheduledMedication? existing,
    required int deviceID,
    @Default(NewMedicationStage.name) NewMedicationStage stage,
    String? name,
    MedicationShape? shape,
    Color? color,
    Set<int>? assignedDispenseTimes
  }) = _NewMedicationState;
}

class NewMedicationProvider with ChangeNotifier {
  late NewMedicationState _state;
  NewMedicationState get state => _state;

  NewMedicationProvider(int deviceID) {
    _state = NewMedicationState(deviceID: deviceID);
  }

  NewMedicationProvider.fromExisting(int deviceID, ScheduledMedication med) {
    _state = NewMedicationState(
      existing: med,
      deviceID: deviceID,
      name: med.name,
      shape: med.shape,
      color: med.color,
      assignedDispenseTimes: med.dispenseTimes.map((e) => e.dispenseTimeID).toSet()
    );
  }

  void update(NewMedicationState newState) {
    _state = newState;
    notifyListeners();
  }

  void updateName(String? newName) {
    _state = state.copyWith(name: newName);
    notifyListeners();
  }

  void updateColor(Color? newColor) {
    _state = state.copyWith(color: newColor);
    notifyListeners();
  }

  void updateShape(MedicationShape? newShape) {
    _state = state.copyWith(shape: newShape);
    notifyListeners();
  }

  void nextStage() {
    _state = state.copyWith(stage: NewMedicationStage.values[state.stage.index + 1]);
    notifyListeners();
  }

  void previousStage() {
    _state = state.copyWith(stage: NewMedicationStage.values[state.stage.index - 1]);
    notifyListeners();
  }

  void complete(context) {
    client.saveMedication(_state.deviceID, SaveMedicationDTO(
      id: _state.existing?.id,
      name: _state.name,
      shape: _state.shape?.internalName,
      color: _state.color?.value,
      dispenseTimes: _state.assignedDispenseTimes
    )).then((value) {
      if(context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void toggleDispenseTime(int dispenseID) {
    Set<int> newSet = {...?state.assignedDispenseTimes};
    if(newSet.contains(dispenseID)) {
      newSet.remove(dispenseID);
    } else {
      newSet.add(dispenseID);
    }
    _state = state.copyWith(assignedDispenseTimes: newSet);
    notifyListeners();
  }



  final Key nameKey = UniqueKey();
  final Key appearanceKey = UniqueKey();
  final Key scheduleKey = UniqueKey();

  Widget buildWidgetForState() {
    if(state.name == null || state.stage == NewMedicationStage.name) {
      return NewMedicationWizardNameStage(key: nameKey);
    } else if(state.shape == null || state.color == null || state.stage == NewMedicationStage.appearance) {
      return NewMedicationWizardAppearanceStage(key: appearanceKey);
    } else if(state.stage == NewMedicationStage.schedule || (state.assignedDispenseTimes?.isEmpty ?? true)) {
      return NewMedicationWizardScheduleStage(key: scheduleKey);
    } else {
      return Text('over');
    }
  }
}

class NewMedicationWizardStage extends StatefulWidget {
  const NewMedicationWizardStage({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.onContinue
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onContinue;

  @override
  State<StatefulWidget> createState() =>
      _NewMedicationWizardStageState();
}

class _NewMedicationWizardStageState extends State<NewMedicationWizardStage> {

  final _formKey = GlobalKey<FormState>();

  Widget _buildBottomButtons(context) {
    final prov = Provider.of<NewMedicationProvider>(context, listen: false);
    final stage = prov.state.stage;
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if(stage != NewMedicationStage.name) ...[
            PlatformTextButton(
              child: const Text('Back'),
              onPressed: () {
                prov.previousStage();
              },
            ),
            const SizedBox(width: 30),
          ],
          Expanded(
            child: PlatformElevatedButton(
              onPressed: widget.onContinue != null ? () {
                if(_formKey.currentState!.validate()) {
                  _formKey.currentState?.save();
                  widget.onContinue!();
                }
              } : null,
              child: const Text('Continue'),
            ),
          )
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Icon(
                          widget.icon,
                          color: Theme.of(context).colorScheme.primary
                      )
                  ),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                      child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center
                      )
                  )
                ],
              ),
              Expanded(
                child: widget.child,
              ),
              _buildBottomButtons(context)
            ],
          ),
        ),
      ),
    );
  }

}

class NewMedicationWizardNameStage extends StatelessWidget {
  const NewMedicationWizardNameStage({super.key});

  @override
  Widget build(BuildContext context) {
    return NewMedicationWizardStage(
      icon: Icons.featured_play_list,
      title: 'What is the name of this medication?',
      onContinue: () => _continue(context),
      child: Column(
        children: [
          PlatformTextFormField(
            autofocus: true,
            initialValue: Provider.of<NewMedicationProvider>(context).state.name,
            validator: Validatorless.multiple([
              Validatorless.required("Name is required"),
              Validatorless.between(1, 32, "Name can't be more than 32 characters")
            ]),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (val) {
              _save(context, val);
              _continue(context);
            },
            onSaved: (val) {
              _save(context, val);
            },
          ),
          SizedBox(height: 20),
          Text(
            'Ex: Aspirin, Vitamin D',
            style: TextStyle(color: Colors.grey[500])
          )
        ],
      ),
    );
  }

  void _save(context, val) {
    Provider.of<NewMedicationProvider>(context, listen: false)
        .updateName(val);
  }

  void _continue(context) {
    Provider.of<NewMedicationProvider>(context, listen: false)
        .nextStage();
  }

}

class NewMedicationWizardScheduleStage extends StatelessWidget {
  const NewMedicationWizardScheduleStage({super.key});
  
  Widget _buildTitle(context, DispenseTime time) {
    return Text(
        '${time.time.format(context)}',
        style: TextStyle(fontWeight: FontWeight.bold)
    );
  }
  
  Widget _buildIcon(context, DispenseTime time, bool checked) {
    if(!checked) {
      return DevicePeriodIcon(
        period: time.period,
        width: 32,
      );
    } else {
      return RawMaterialButton(
        onPressed: () {},
        elevation: 2.0,
        fillColor: Colors.white,
        child: Text('1 x'),
        padding: EdgeInsets.all(10.0),
        shape: CircleBorder(),
      );
    }
  }

  Widget _buildDose(context, DispenseTime time, Set<int>? checked) {
    return InputChip(
      labelPadding: const EdgeInsets.all(16),
      label: _buildTitle(context, time),
      selected: checked?.contains(time.id) ?? false,
      onPressed: () {
        Provider.of<NewMedicationProvider>(context, listen: false)
          .toggleDispenseTime(time.id!);
      },
      /*onDeleted: () {
        Provider.of<NewMedicationProvider>(context, listen: false)
            .toggleDispenseTime(time.id!);
      },*/
      //deleteIcon: _buildIcon(context, time, checked?.contains(time.id) ?? false),
    );
  }

  List<Widget> _buildForSchedule(context, SimpleSchedule sched,
      Set<int>? checked) {
    return [
      if(sched.am != null) _buildDose(context, sched.am!, checked),
      if(sched.pm != null) _buildDose(context, sched.pm!, checked),
      if(sched.am == null && sched.pm == null) Text('Please set medication times in device settings')
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NewMedicationProvider>(context);

    return NewMedicationWizardStage(
      icon: Icons.schedule,
      title: 'When do you take ${prov.state.name}?',
      onContinue: prov.state.assignedDispenseTimes?.isNotEmpty ?? false
        ? () {
          prov.complete(context);
        }
        : null,
      child: Provider(
        create: (BuildContext context) {
          return ScheduleProvider(
            deviceID: prov.state.deviceID
          );
        },
        child: FutureBuilder<SimpleSchedule?>(
          future: Provider.of<ScheduleProvider>(context).future,
          builder: (context, snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                if(!snapshot.hasData)... [
                  const CircularProgressIndicator()
                ] else... [
                  ..._buildForSchedule(context, snapshot.requireData!,
                      prov.state.assignedDispenseTimes)
                ]
              ],
            );
          }
        ),
      ),
    );
  }
}

class NewMedicationWizardAppearanceStage extends StatelessWidget {
  const NewMedicationWizardAppearanceStage({super.key});

  VoidCallback? _onContinue(context) {
    final prov = Provider.of<NewMedicationProvider>(context, listen: false);
    if(prov.state.shape != null && prov.state.color != null) {
      return () => prov.nextStage();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return NewMedicationWizardStage(
      icon: Icons.medication,
      title: 'What does ${Provider.of<NewMedicationProvider>(context).state.name} look like?',
      onContinue: _onContinue(context),
      child: ListView(
        children: [
          MedicationColorSelector(
            selected: Provider.of<NewMedicationProvider>(context).state.color,
            onChange: (color) {
              Provider.of<NewMedicationProvider>(context, listen: false)
                  .updateColor(color);
            }
          ),
          PillShapeSelector(
            color: Provider.of<NewMedicationProvider>(context).state.color,
            selected: Provider.of<NewMedicationProvider>(context).state.shape,
            onChange: (shape) {
              Provider.of<NewMedicationProvider>(context, listen: false)
                  .updateShape(shape);
            },
          )
        ],
      ),
    );
  }

}


class NewMedicationWizardPage extends StatelessWidget {
  const NewMedicationWizardPage({super.key, required this.deviceID});

  static Route<NewMedicationWizardPage> route(context, deviceID) =>
      platformPageRoute(context: context, builder:
          (_) => NewMedicationWizardPage(deviceID: deviceID));

  final int deviceID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text('New Medication'),
      ),
      body: ChangeNotifierProvider<NewMedicationProvider>(
        create: (context) => NewMedicationProvider(deviceID),
        builder: (context, _) =>
            AnimatedSwitcher(
              switchInCurve: Curves.easeOut,
              reverseDuration: const Duration(seconds: 0),
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                final tween = Tween(begin: begin, end: end);
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: curve,
                );

                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              },
              child: Provider.of<NewMedicationProvider>(context)
                  .buildWidgetForState(),
            ),
      )
    );
  }

}

class EditMedicationWizardPage extends StatelessWidget {
  const EditMedicationWizardPage({super.key, required this.existing, required this.deviceID});

  static Route<EditMedicationWizardPage> route(context, existing, deviceID) =>
      platformPageRoute(context: context, builder:
          (_) => EditMedicationWizardPage(existing: existing, deviceID: deviceID));

  final ScheduledMedication existing;
  final int deviceID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: new Text('${existing.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                client.deleteMedication(deviceID, existing.id!)
                  .then((_) {
                    if(context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
              }
            )
          ],
        ),
        body: ChangeNotifierProvider<NewMedicationProvider>(
          create: (context) => NewMedicationProvider.fromExisting(deviceID, existing),
          builder: (context, _) =>
              AnimatedSwitcher(
                switchInCurve: Curves.easeOut,
                reverseDuration: const Duration(seconds: 0),
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  return SlideTransition(
                    position: Tween(begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
                        .animate(anim),
                    child: child,
                  );
                },
                child: Provider.of<NewMedicationProvider>(context)
                    .buildWidgetForState(),
              ),
        )
    );
  }

}