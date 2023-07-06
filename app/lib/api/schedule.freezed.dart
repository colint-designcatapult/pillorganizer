// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$MedicationDispenseTime {
  int get dispenseTimeID => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  DayPeriod get period => throw _privateConstructorUsedError;
  TimeOfDay get timeOfDay => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MedicationDispenseTimeCopyWith<MedicationDispenseTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicationDispenseTimeCopyWith<$Res> {
  factory $MedicationDispenseTimeCopyWith(MedicationDispenseTime value,
          $Res Function(MedicationDispenseTime) then) =
      _$MedicationDispenseTimeCopyWithImpl<$Res, MedicationDispenseTime>;
  @useResult
  $Res call(
      {int dispenseTimeID,
      int quantity,
      DayPeriod period,
      TimeOfDay timeOfDay});
}

/// @nodoc
class _$MedicationDispenseTimeCopyWithImpl<$Res,
        $Val extends MedicationDispenseTime>
    implements $MedicationDispenseTimeCopyWith<$Res> {
  _$MedicationDispenseTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dispenseTimeID = null,
    Object? quantity = null,
    Object? period = null,
    Object? timeOfDay = null,
  }) {
    return _then(_value.copyWith(
      dispenseTimeID: null == dispenseTimeID
          ? _value.dispenseTimeID
          : dispenseTimeID // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as DayPeriod,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as TimeOfDay,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_MedicationDispenseTimeCopyWith<$Res>
    implements $MedicationDispenseTimeCopyWith<$Res> {
  factory _$$_MedicationDispenseTimeCopyWith(_$_MedicationDispenseTime value,
          $Res Function(_$_MedicationDispenseTime) then) =
      __$$_MedicationDispenseTimeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dispenseTimeID,
      int quantity,
      DayPeriod period,
      TimeOfDay timeOfDay});
}

/// @nodoc
class __$$_MedicationDispenseTimeCopyWithImpl<$Res>
    extends _$MedicationDispenseTimeCopyWithImpl<$Res,
        _$_MedicationDispenseTime>
    implements _$$_MedicationDispenseTimeCopyWith<$Res> {
  __$$_MedicationDispenseTimeCopyWithImpl(_$_MedicationDispenseTime _value,
      $Res Function(_$_MedicationDispenseTime) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dispenseTimeID = null,
    Object? quantity = null,
    Object? period = null,
    Object? timeOfDay = null,
  }) {
    return _then(_$_MedicationDispenseTime(
      dispenseTimeID: null == dispenseTimeID
          ? _value.dispenseTimeID
          : dispenseTimeID // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as DayPeriod,
      timeOfDay: null == timeOfDay
          ? _value.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as TimeOfDay,
    ));
  }
}

/// @nodoc

class _$_MedicationDispenseTime extends _MedicationDispenseTime {
  const _$_MedicationDispenseTime(
      {required this.dispenseTimeID,
      required this.quantity,
      required this.period,
      required this.timeOfDay})
      : super._();

  @override
  final int dispenseTimeID;
  @override
  final int quantity;
  @override
  final DayPeriod period;
  @override
  final TimeOfDay timeOfDay;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_MedicationDispenseTimeCopyWith<_$_MedicationDispenseTime> get copyWith =>
      __$$_MedicationDispenseTimeCopyWithImpl<_$_MedicationDispenseTime>(
          this, _$identity);
}

abstract class _MedicationDispenseTime extends MedicationDispenseTime {
  const factory _MedicationDispenseTime(
      {required final int dispenseTimeID,
      required final int quantity,
      required final DayPeriod period,
      required final TimeOfDay timeOfDay}) = _$_MedicationDispenseTime;
  const _MedicationDispenseTime._() : super._();

  @override
  int get dispenseTimeID;
  @override
  int get quantity;
  @override
  DayPeriod get period;
  @override
  TimeOfDay get timeOfDay;
  @override
  @JsonKey(ignore: true)
  _$$_MedicationDispenseTimeCopyWith<_$_MedicationDispenseTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DispenseTime {
  int? get id => throw _privateConstructorUsedError;
  TimeOfDay get time => throw _privateConstructorUsedError;
  DayPeriod get period => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DispenseTimeCopyWith<DispenseTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DispenseTimeCopyWith<$Res> {
  factory $DispenseTimeCopyWith(
          DispenseTime value, $Res Function(DispenseTime) then) =
      _$DispenseTimeCopyWithImpl<$Res, DispenseTime>;
  @useResult
  $Res call({int? id, TimeOfDay time, DayPeriod period});
}

/// @nodoc
class _$DispenseTimeCopyWithImpl<$Res, $Val extends DispenseTime>
    implements $DispenseTimeCopyWith<$Res> {
  _$DispenseTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? time = null,
    Object? period = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as TimeOfDay,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as DayPeriod,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_DispenseTimeCopyWith<$Res>
    implements $DispenseTimeCopyWith<$Res> {
  factory _$$_DispenseTimeCopyWith(
          _$_DispenseTime value, $Res Function(_$_DispenseTime) then) =
      __$$_DispenseTimeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? id, TimeOfDay time, DayPeriod period});
}

/// @nodoc
class __$$_DispenseTimeCopyWithImpl<$Res>
    extends _$DispenseTimeCopyWithImpl<$Res, _$_DispenseTime>
    implements _$$_DispenseTimeCopyWith<$Res> {
  __$$_DispenseTimeCopyWithImpl(
      _$_DispenseTime _value, $Res Function(_$_DispenseTime) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? time = null,
    Object? period = null,
  }) {
    return _then(_$_DispenseTime(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as TimeOfDay,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as DayPeriod,
    ));
  }
}

/// @nodoc

class _$_DispenseTime extends _DispenseTime {
  const _$_DispenseTime({this.id, required this.time, required this.period})
      : super._();

  @override
  final int? id;
  @override
  final TimeOfDay time;
  @override
  final DayPeriod period;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DispenseTimeCopyWith<_$_DispenseTime> get copyWith =>
      __$$_DispenseTimeCopyWithImpl<_$_DispenseTime>(this, _$identity);
}

abstract class _DispenseTime extends DispenseTime {
  const factory _DispenseTime(
      {final int? id,
      required final TimeOfDay time,
      required final DayPeriod period}) = _$_DispenseTime;
  const _DispenseTime._() : super._();

  @override
  int? get id;
  @override
  TimeOfDay get time;
  @override
  DayPeriod get period;
  @override
  @JsonKey(ignore: true)
  _$$_DispenseTimeCopyWith<_$_DispenseTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SimpleSchedule {
  DispenseTime? get am => throw _privateConstructorUsedError;
  DispenseTime? get pm => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SimpleScheduleCopyWith<SimpleSchedule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimpleScheduleCopyWith<$Res> {
  factory $SimpleScheduleCopyWith(
          SimpleSchedule value, $Res Function(SimpleSchedule) then) =
      _$SimpleScheduleCopyWithImpl<$Res, SimpleSchedule>;
  @useResult
  $Res call({DispenseTime? am, DispenseTime? pm});

  $DispenseTimeCopyWith<$Res>? get am;
  $DispenseTimeCopyWith<$Res>? get pm;
}

/// @nodoc
class _$SimpleScheduleCopyWithImpl<$Res, $Val extends SimpleSchedule>
    implements $SimpleScheduleCopyWith<$Res> {
  _$SimpleScheduleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? am = freezed,
    Object? pm = freezed,
  }) {
    return _then(_value.copyWith(
      am: freezed == am
          ? _value.am
          : am // ignore: cast_nullable_to_non_nullable
              as DispenseTime?,
      pm: freezed == pm
          ? _value.pm
          : pm // ignore: cast_nullable_to_non_nullable
              as DispenseTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DispenseTimeCopyWith<$Res>? get am {
    if (_value.am == null) {
      return null;
    }

    return $DispenseTimeCopyWith<$Res>(_value.am!, (value) {
      return _then(_value.copyWith(am: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $DispenseTimeCopyWith<$Res>? get pm {
    if (_value.pm == null) {
      return null;
    }

    return $DispenseTimeCopyWith<$Res>(_value.pm!, (value) {
      return _then(_value.copyWith(pm: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_SimpleScheduleCopyWith<$Res>
    implements $SimpleScheduleCopyWith<$Res> {
  factory _$$_SimpleScheduleCopyWith(
          _$_SimpleSchedule value, $Res Function(_$_SimpleSchedule) then) =
      __$$_SimpleScheduleCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DispenseTime? am, DispenseTime? pm});

  @override
  $DispenseTimeCopyWith<$Res>? get am;
  @override
  $DispenseTimeCopyWith<$Res>? get pm;
}

/// @nodoc
class __$$_SimpleScheduleCopyWithImpl<$Res>
    extends _$SimpleScheduleCopyWithImpl<$Res, _$_SimpleSchedule>
    implements _$$_SimpleScheduleCopyWith<$Res> {
  __$$_SimpleScheduleCopyWithImpl(
      _$_SimpleSchedule _value, $Res Function(_$_SimpleSchedule) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? am = freezed,
    Object? pm = freezed,
  }) {
    return _then(_$_SimpleSchedule(
      am: freezed == am
          ? _value.am
          : am // ignore: cast_nullable_to_non_nullable
              as DispenseTime?,
      pm: freezed == pm
          ? _value.pm
          : pm // ignore: cast_nullable_to_non_nullable
              as DispenseTime?,
    ));
  }
}

/// @nodoc

class _$_SimpleSchedule extends _SimpleSchedule {
  const _$_SimpleSchedule({this.am, this.pm}) : super._();

  @override
  final DispenseTime? am;
  @override
  final DispenseTime? pm;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SimpleScheduleCopyWith<_$_SimpleSchedule> get copyWith =>
      __$$_SimpleScheduleCopyWithImpl<_$_SimpleSchedule>(this, _$identity);
}

abstract class _SimpleSchedule extends SimpleSchedule {
  const factory _SimpleSchedule(
      {final DispenseTime? am, final DispenseTime? pm}) = _$_SimpleSchedule;
  const _SimpleSchedule._() : super._();

  @override
  DispenseTime? get am;
  @override
  DispenseTime? get pm;
  @override
  @JsonKey(ignore: true)
  _$$_SimpleScheduleCopyWith<_$_SimpleSchedule> get copyWith =>
      throw _privateConstructorUsedError;
}
