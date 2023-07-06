// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ScheduledMedication {
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MedicationShape? get shape => throw _privateConstructorUsedError;
  Color? get color => throw _privateConstructorUsedError;
  List<MedicationDispenseTime> get dispenseTimes =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScheduledMedicationCopyWith<ScheduledMedication> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduledMedicationCopyWith<$Res> {
  factory $ScheduledMedicationCopyWith(
          ScheduledMedication value, $Res Function(ScheduledMedication) then) =
      _$ScheduledMedicationCopyWithImpl<$Res, ScheduledMedication>;
  @useResult
  $Res call(
      {int? id,
      String name,
      MedicationShape? shape,
      Color? color,
      List<MedicationDispenseTime> dispenseTimes});
}

/// @nodoc
class _$ScheduledMedicationCopyWithImpl<$Res, $Val extends ScheduledMedication>
    implements $ScheduledMedicationCopyWith<$Res> {
  _$ScheduledMedicationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? shape = freezed,
    Object? color = freezed,
    Object? dispenseTimes = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shape: freezed == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as MedicationShape?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      dispenseTimes: null == dispenseTimes
          ? _value.dispenseTimes
          : dispenseTimes // ignore: cast_nullable_to_non_nullable
              as List<MedicationDispenseTime>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ScheduledMedicationCopyWith<$Res>
    implements $ScheduledMedicationCopyWith<$Res> {
  factory _$$_ScheduledMedicationCopyWith(_$_ScheduledMedication value,
          $Res Function(_$_ScheduledMedication) then) =
      __$$_ScheduledMedicationCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String name,
      MedicationShape? shape,
      Color? color,
      List<MedicationDispenseTime> dispenseTimes});
}

/// @nodoc
class __$$_ScheduledMedicationCopyWithImpl<$Res>
    extends _$ScheduledMedicationCopyWithImpl<$Res, _$_ScheduledMedication>
    implements _$$_ScheduledMedicationCopyWith<$Res> {
  __$$_ScheduledMedicationCopyWithImpl(_$_ScheduledMedication _value,
      $Res Function(_$_ScheduledMedication) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? shape = freezed,
    Object? color = freezed,
    Object? dispenseTimes = null,
  }) {
    return _then(_$_ScheduledMedication(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shape: freezed == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as MedicationShape?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      dispenseTimes: null == dispenseTimes
          ? _value._dispenseTimes
          : dispenseTimes // ignore: cast_nullable_to_non_nullable
              as List<MedicationDispenseTime>,
    ));
  }
}

/// @nodoc

class _$_ScheduledMedication extends _ScheduledMedication {
  const _$_ScheduledMedication(
      {this.id,
      required this.name,
      this.shape,
      this.color,
      required final List<MedicationDispenseTime> dispenseTimes})
      : _dispenseTimes = dispenseTimes,
        super._();

  @override
  final int? id;
  @override
  final String name;
  @override
  final MedicationShape? shape;
  @override
  final Color? color;
  final List<MedicationDispenseTime> _dispenseTimes;
  @override
  List<MedicationDispenseTime> get dispenseTimes {
    if (_dispenseTimes is EqualUnmodifiableListView) return _dispenseTimes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dispenseTimes);
  }

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ScheduledMedicationCopyWith<_$_ScheduledMedication> get copyWith =>
      __$$_ScheduledMedicationCopyWithImpl<_$_ScheduledMedication>(
          this, _$identity);
}

abstract class _ScheduledMedication extends ScheduledMedication {
  const factory _ScheduledMedication(
          {final int? id,
          required final String name,
          final MedicationShape? shape,
          final Color? color,
          required final List<MedicationDispenseTime> dispenseTimes}) =
      _$_ScheduledMedication;
  const _ScheduledMedication._() : super._();

  @override
  int? get id;
  @override
  String get name;
  @override
  MedicationShape? get shape;
  @override
  Color? get color;
  @override
  List<MedicationDispenseTime> get dispenseTimes;
  @override
  @JsonKey(ignore: true)
  _$$_ScheduledMedicationCopyWith<_$_ScheduledMedication> get copyWith =>
      throw _privateConstructorUsedError;
}
