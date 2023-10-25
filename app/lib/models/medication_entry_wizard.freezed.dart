// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_entry_wizard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$NewMedicationState {
  ScheduledMedication? get existing => throw _privateConstructorUsedError;
  int get deviceID => throw _privateConstructorUsedError;
  NewMedicationStage get stage => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  MedicationShape? get shape => throw _privateConstructorUsedError;
  Color? get color => throw _privateConstructorUsedError;
  Set<int>? get assignedDispenseTimes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NewMedicationStateCopyWith<NewMedicationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewMedicationStateCopyWith<$Res> {
  factory $NewMedicationStateCopyWith(
          NewMedicationState value, $Res Function(NewMedicationState) then) =
      _$NewMedicationStateCopyWithImpl<$Res, NewMedicationState>;
  @useResult
  $Res call(
      {ScheduledMedication? existing,
      int deviceID,
      NewMedicationStage stage,
      String? name,
      MedicationShape? shape,
      Color? color,
      Set<int>? assignedDispenseTimes});

  $ScheduledMedicationCopyWith<$Res>? get existing;
}

/// @nodoc
class _$NewMedicationStateCopyWithImpl<$Res, $Val extends NewMedicationState>
    implements $NewMedicationStateCopyWith<$Res> {
  _$NewMedicationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existing = freezed,
    Object? deviceID = null,
    Object? stage = null,
    Object? name = freezed,
    Object? shape = freezed,
    Object? color = freezed,
    Object? assignedDispenseTimes = freezed,
  }) {
    return _then(_value.copyWith(
      existing: freezed == existing
          ? _value.existing
          : existing // ignore: cast_nullable_to_non_nullable
              as ScheduledMedication?,
      deviceID: null == deviceID
          ? _value.deviceID
          : deviceID // ignore: cast_nullable_to_non_nullable
              as int,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as NewMedicationStage,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      shape: freezed == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as MedicationShape?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      assignedDispenseTimes: freezed == assignedDispenseTimes
          ? _value.assignedDispenseTimes
          : assignedDispenseTimes // ignore: cast_nullable_to_non_nullable
              as Set<int>?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ScheduledMedicationCopyWith<$Res>? get existing {
    if (_value.existing == null) {
      return null;
    }

    return $ScheduledMedicationCopyWith<$Res>(_value.existing!, (value) {
      return _then(_value.copyWith(existing: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_NewMedicationStateCopyWith<$Res>
    implements $NewMedicationStateCopyWith<$Res> {
  factory _$$_NewMedicationStateCopyWith(_$_NewMedicationState value,
          $Res Function(_$_NewMedicationState) then) =
      __$$_NewMedicationStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ScheduledMedication? existing,
      int deviceID,
      NewMedicationStage stage,
      String? name,
      MedicationShape? shape,
      Color? color,
      Set<int>? assignedDispenseTimes});

  @override
  $ScheduledMedicationCopyWith<$Res>? get existing;
}

/// @nodoc
class __$$_NewMedicationStateCopyWithImpl<$Res>
    extends _$NewMedicationStateCopyWithImpl<$Res, _$_NewMedicationState>
    implements _$$_NewMedicationStateCopyWith<$Res> {
  __$$_NewMedicationStateCopyWithImpl(
      _$_NewMedicationState _value, $Res Function(_$_NewMedicationState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existing = freezed,
    Object? deviceID = null,
    Object? stage = null,
    Object? name = freezed,
    Object? shape = freezed,
    Object? color = freezed,
    Object? assignedDispenseTimes = freezed,
  }) {
    return _then(_$_NewMedicationState(
      existing: freezed == existing
          ? _value.existing
          : existing // ignore: cast_nullable_to_non_nullable
              as ScheduledMedication?,
      deviceID: null == deviceID
          ? _value.deviceID
          : deviceID // ignore: cast_nullable_to_non_nullable
              as int,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as NewMedicationStage,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      shape: freezed == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as MedicationShape?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      assignedDispenseTimes: freezed == assignedDispenseTimes
          ? _value._assignedDispenseTimes
          : assignedDispenseTimes // ignore: cast_nullable_to_non_nullable
              as Set<int>?,
    ));
  }
}

/// @nodoc

class _$_NewMedicationState implements _NewMedicationState {
  const _$_NewMedicationState(
      {this.existing,
      required this.deviceID,
      this.stage = NewMedicationStage.name,
      this.name,
      this.shape,
      this.color,
      final Set<int>? assignedDispenseTimes})
      : _assignedDispenseTimes = assignedDispenseTimes;

  @override
  final ScheduledMedication? existing;
  @override
  final int deviceID;
  @override
  @JsonKey()
  final NewMedicationStage stage;
  @override
  final String? name;
  @override
  final MedicationShape? shape;
  @override
  final Color? color;
  final Set<int>? _assignedDispenseTimes;
  @override
  Set<int>? get assignedDispenseTimes {
    final value = _assignedDispenseTimes;
    if (value == null) return null;
    if (_assignedDispenseTimes is EqualUnmodifiableSetView)
      return _assignedDispenseTimes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(value);
  }

  @override
  String toString() {
    return 'NewMedicationState(existing: $existing, deviceID: $deviceID, stage: $stage, name: $name, shape: $shape, color: $color, assignedDispenseTimes: $assignedDispenseTimes)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_NewMedicationState &&
            (identical(other.existing, existing) ||
                other.existing == existing) &&
            (identical(other.deviceID, deviceID) ||
                other.deviceID == deviceID) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shape, shape) || other.shape == shape) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality()
                .equals(other._assignedDispenseTimes, _assignedDispenseTimes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      existing,
      deviceID,
      stage,
      name,
      shape,
      color,
      const DeepCollectionEquality().hash(_assignedDispenseTimes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_NewMedicationStateCopyWith<_$_NewMedicationState> get copyWith =>
      __$$_NewMedicationStateCopyWithImpl<_$_NewMedicationState>(
          this, _$identity);
}

abstract class _NewMedicationState implements NewMedicationState {
  const factory _NewMedicationState(
      {final ScheduledMedication? existing,
      required final int deviceID,
      final NewMedicationStage stage,
      final String? name,
      final MedicationShape? shape,
      final Color? color,
      final Set<int>? assignedDispenseTimes}) = _$_NewMedicationState;

  @override
  ScheduledMedication? get existing;
  @override
  int get deviceID;
  @override
  NewMedicationStage get stage;
  @override
  String? get name;
  @override
  MedicationShape? get shape;
  @override
  Color? get color;
  @override
  Set<int>? get assignedDispenseTimes;
  @override
  @JsonKey(ignore: true)
  _$$_NewMedicationStateCopyWith<_$_NewMedicationState> get copyWith =>
      throw _privateConstructorUsedError;
}
