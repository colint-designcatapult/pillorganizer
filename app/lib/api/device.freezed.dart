// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$BinEvent {
  int get id => throw _privateConstructorUsedError;
  int get bin => throw _privateConstructorUsedError;
  DateTime? get time => throw _privateConstructorUsedError;
  DateTime? get timeLocal => throw _privateConstructorUsedError;
  EventType? get eventType => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BinEventCopyWith<BinEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinEventCopyWith<$Res> {
  factory $BinEventCopyWith(BinEvent value, $Res Function(BinEvent) then) =
      _$BinEventCopyWithImpl<$Res, BinEvent>;
  @useResult
  $Res call(
      {int id,
      int bin,
      DateTime? time,
      DateTime? timeLocal,
      EventType? eventType});
}

/// @nodoc
class _$BinEventCopyWithImpl<$Res, $Val extends BinEvent>
    implements $BinEventCopyWith<$Res> {
  _$BinEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bin = null,
    Object? time = freezed,
    Object? timeLocal = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      bin: null == bin
          ? _value.bin
          : bin // ignore: cast_nullable_to_non_nullable
              as int,
      time: freezed == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeLocal: freezed == timeLocal
          ? _value.timeLocal
          : timeLocal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as EventType?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_BinEventCopyWith<$Res> implements $BinEventCopyWith<$Res> {
  factory _$$_BinEventCopyWith(
          _$_BinEvent value, $Res Function(_$_BinEvent) then) =
      __$$_BinEventCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int bin,
      DateTime? time,
      DateTime? timeLocal,
      EventType? eventType});
}

/// @nodoc
class __$$_BinEventCopyWithImpl<$Res>
    extends _$BinEventCopyWithImpl<$Res, _$_BinEvent>
    implements _$$_BinEventCopyWith<$Res> {
  __$$_BinEventCopyWithImpl(
      _$_BinEvent _value, $Res Function(_$_BinEvent) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bin = null,
    Object? time = freezed,
    Object? timeLocal = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_$_BinEvent(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      bin: null == bin
          ? _value.bin
          : bin // ignore: cast_nullable_to_non_nullable
              as int,
      time: freezed == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeLocal: freezed == timeLocal
          ? _value.timeLocal
          : timeLocal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as EventType?,
    ));
  }
}

/// @nodoc

class _$_BinEvent extends _BinEvent with DiagnosticableTreeMixin {
  const _$_BinEvent(
      {required this.id,
      required this.bin,
      this.time,
      this.timeLocal,
      this.eventType})
      : super._();

  @override
  final int id;
  @override
  final int bin;
  @override
  final DateTime? time;
  @override
  final DateTime? timeLocal;
  @override
  final EventType? eventType;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BinEvent(id: $id, bin: $bin, time: $time, timeLocal: $timeLocal, eventType: $eventType)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'BinEvent'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('bin', bin))
      ..add(DiagnosticsProperty('time', time))
      ..add(DiagnosticsProperty('timeLocal', timeLocal))
      ..add(DiagnosticsProperty('eventType', eventType));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BinEvent &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bin, bin) || other.bin == bin) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timeLocal, timeLocal) ||
                other.timeLocal == timeLocal) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bin, time, timeLocal, eventType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BinEventCopyWith<_$_BinEvent> get copyWith =>
      __$$_BinEventCopyWithImpl<_$_BinEvent>(this, _$identity);
}

abstract class _BinEvent extends BinEvent {
  const factory _BinEvent(
      {required final int id,
      required final int bin,
      final DateTime? time,
      final DateTime? timeLocal,
      final EventType? eventType}) = _$_BinEvent;
  const _BinEvent._() : super._();

  @override
  int get id;
  @override
  int get bin;
  @override
  DateTime? get time;
  @override
  DateTime? get timeLocal;
  @override
  EventType? get eventType;
  @override
  @JsonKey(ignore: true)
  _$$_BinEventCopyWith<_$_BinEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BinSchedule {
  int get id => throw _privateConstructorUsedError;
  TimeOfDayOfWeek? get tdow => throw _privateConstructorUsedError;
  TimeOfDayOfWeek? get tdowLocal => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BinScheduleCopyWith<BinSchedule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinScheduleCopyWith<$Res> {
  factory $BinScheduleCopyWith(
          BinSchedule value, $Res Function(BinSchedule) then) =
      _$BinScheduleCopyWithImpl<$Res, BinSchedule>;
  @useResult
  $Res call({int id, TimeOfDayOfWeek? tdow, TimeOfDayOfWeek? tdowLocal});
}

/// @nodoc
class _$BinScheduleCopyWithImpl<$Res, $Val extends BinSchedule>
    implements $BinScheduleCopyWith<$Res> {
  _$BinScheduleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tdow = freezed,
    Object? tdowLocal = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      tdow: freezed == tdow
          ? _value.tdow
          : tdow // ignore: cast_nullable_to_non_nullable
              as TimeOfDayOfWeek?,
      tdowLocal: freezed == tdowLocal
          ? _value.tdowLocal
          : tdowLocal // ignore: cast_nullable_to_non_nullable
              as TimeOfDayOfWeek?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_BinScheduleCopyWith<$Res>
    implements $BinScheduleCopyWith<$Res> {
  factory _$$_BinScheduleCopyWith(
          _$_BinSchedule value, $Res Function(_$_BinSchedule) then) =
      __$$_BinScheduleCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, TimeOfDayOfWeek? tdow, TimeOfDayOfWeek? tdowLocal});
}

/// @nodoc
class __$$_BinScheduleCopyWithImpl<$Res>
    extends _$BinScheduleCopyWithImpl<$Res, _$_BinSchedule>
    implements _$$_BinScheduleCopyWith<$Res> {
  __$$_BinScheduleCopyWithImpl(
      _$_BinSchedule _value, $Res Function(_$_BinSchedule) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tdow = freezed,
    Object? tdowLocal = freezed,
  }) {
    return _then(_$_BinSchedule(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      tdow: freezed == tdow
          ? _value.tdow
          : tdow // ignore: cast_nullable_to_non_nullable
              as TimeOfDayOfWeek?,
      tdowLocal: freezed == tdowLocal
          ? _value.tdowLocal
          : tdowLocal // ignore: cast_nullable_to_non_nullable
              as TimeOfDayOfWeek?,
    ));
  }
}

/// @nodoc

class _$_BinSchedule extends _BinSchedule with DiagnosticableTreeMixin {
  const _$_BinSchedule({required this.id, this.tdow, this.tdowLocal})
      : super._();

  @override
  final int id;
  @override
  final TimeOfDayOfWeek? tdow;
  @override
  final TimeOfDayOfWeek? tdowLocal;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BinSchedule(id: $id, tdow: $tdow, tdowLocal: $tdowLocal)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'BinSchedule'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('tdow', tdow))
      ..add(DiagnosticsProperty('tdowLocal', tdowLocal));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BinSchedule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tdow, tdow) || other.tdow == tdow) &&
            (identical(other.tdowLocal, tdowLocal) ||
                other.tdowLocal == tdowLocal));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, tdow, tdowLocal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BinScheduleCopyWith<_$_BinSchedule> get copyWith =>
      __$$_BinScheduleCopyWithImpl<_$_BinSchedule>(this, _$identity);
}

abstract class _BinSchedule extends BinSchedule {
  const factory _BinSchedule(
      {required final int id,
      final TimeOfDayOfWeek? tdow,
      final TimeOfDayOfWeek? tdowLocal}) = _$_BinSchedule;
  const _BinSchedule._() : super._();

  @override
  int get id;
  @override
  TimeOfDayOfWeek? get tdow;
  @override
  TimeOfDayOfWeek? get tdowLocal;
  @override
  @JsonKey(ignore: true)
  _$$_BinScheduleCopyWith<_$_BinSchedule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BinState {
  DeviceBinID get id => throw _privateConstructorUsedError;
  BinStatus? get binStatus => throw _privateConstructorUsedError;
  DateTime? get scheduledTime => throw _privateConstructorUsedError;
  DateTime? get scheduledTimeLocal => throw _privateConstructorUsedError;
  BinSchedule? get schedule => throw _privateConstructorUsedError;
  BinEvent? get event => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BinStateCopyWith<BinState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinStateCopyWith<$Res> {
  factory $BinStateCopyWith(BinState value, $Res Function(BinState) then) =
      _$BinStateCopyWithImpl<$Res, BinState>;
  @useResult
  $Res call(
      {DeviceBinID id,
      BinStatus? binStatus,
      DateTime? scheduledTime,
      DateTime? scheduledTimeLocal,
      BinSchedule? schedule,
      BinEvent? event});

  $BinScheduleCopyWith<$Res>? get schedule;
  $BinEventCopyWith<$Res>? get event;
}

/// @nodoc
class _$BinStateCopyWithImpl<$Res, $Val extends BinState>
    implements $BinStateCopyWith<$Res> {
  _$BinStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binStatus = freezed,
    Object? scheduledTime = freezed,
    Object? scheduledTimeLocal = freezed,
    Object? schedule = freezed,
    Object? event = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as DeviceBinID,
      binStatus: freezed == binStatus
          ? _value.binStatus
          : binStatus // ignore: cast_nullable_to_non_nullable
              as BinStatus?,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      scheduledTimeLocal: freezed == scheduledTimeLocal
          ? _value.scheduledTimeLocal
          : scheduledTimeLocal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schedule: freezed == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as BinSchedule?,
      event: freezed == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as BinEvent?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BinScheduleCopyWith<$Res>? get schedule {
    if (_value.schedule == null) {
      return null;
    }

    return $BinScheduleCopyWith<$Res>(_value.schedule!, (value) {
      return _then(_value.copyWith(schedule: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BinEventCopyWith<$Res>? get event {
    if (_value.event == null) {
      return null;
    }

    return $BinEventCopyWith<$Res>(_value.event!, (value) {
      return _then(_value.copyWith(event: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_BinStateCopyWith<$Res> implements $BinStateCopyWith<$Res> {
  factory _$$_BinStateCopyWith(
          _$_BinState value, $Res Function(_$_BinState) then) =
      __$$_BinStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DeviceBinID id,
      BinStatus? binStatus,
      DateTime? scheduledTime,
      DateTime? scheduledTimeLocal,
      BinSchedule? schedule,
      BinEvent? event});

  @override
  $BinScheduleCopyWith<$Res>? get schedule;
  @override
  $BinEventCopyWith<$Res>? get event;
}

/// @nodoc
class __$$_BinStateCopyWithImpl<$Res>
    extends _$BinStateCopyWithImpl<$Res, _$_BinState>
    implements _$$_BinStateCopyWith<$Res> {
  __$$_BinStateCopyWithImpl(
      _$_BinState _value, $Res Function(_$_BinState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binStatus = freezed,
    Object? scheduledTime = freezed,
    Object? scheduledTimeLocal = freezed,
    Object? schedule = freezed,
    Object? event = freezed,
  }) {
    return _then(_$_BinState(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as DeviceBinID,
      binStatus: freezed == binStatus
          ? _value.binStatus
          : binStatus // ignore: cast_nullable_to_non_nullable
              as BinStatus?,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      scheduledTimeLocal: freezed == scheduledTimeLocal
          ? _value.scheduledTimeLocal
          : scheduledTimeLocal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schedule: freezed == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as BinSchedule?,
      event: freezed == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as BinEvent?,
    ));
  }
}

/// @nodoc

class _$_BinState extends _BinState with DiagnosticableTreeMixin {
  const _$_BinState(
      {required this.id,
      this.binStatus,
      this.scheduledTime,
      this.scheduledTimeLocal,
      this.schedule,
      this.event})
      : super._();

  @override
  final DeviceBinID id;
  @override
  final BinStatus? binStatus;
  @override
  final DateTime? scheduledTime;
  @override
  final DateTime? scheduledTimeLocal;
  @override
  final BinSchedule? schedule;
  @override
  final BinEvent? event;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BinState(id: $id, binStatus: $binStatus, scheduledTime: $scheduledTime, scheduledTimeLocal: $scheduledTimeLocal, schedule: $schedule, event: $event)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'BinState'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('binStatus', binStatus))
      ..add(DiagnosticsProperty('scheduledTime', scheduledTime))
      ..add(DiagnosticsProperty('scheduledTimeLocal', scheduledTimeLocal))
      ..add(DiagnosticsProperty('schedule', schedule))
      ..add(DiagnosticsProperty('event', event));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BinState &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binStatus, binStatus) ||
                other.binStatus == binStatus) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.scheduledTimeLocal, scheduledTimeLocal) ||
                other.scheduledTimeLocal == scheduledTimeLocal) &&
            (identical(other.schedule, schedule) ||
                other.schedule == schedule) &&
            (identical(other.event, event) || other.event == event));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, binStatus, scheduledTime,
      scheduledTimeLocal, schedule, event);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BinStateCopyWith<_$_BinState> get copyWith =>
      __$$_BinStateCopyWithImpl<_$_BinState>(this, _$identity);
}

abstract class _BinState extends BinState {
  const factory _BinState(
      {required final DeviceBinID id,
      final BinStatus? binStatus,
      final DateTime? scheduledTime,
      final DateTime? scheduledTimeLocal,
      final BinSchedule? schedule,
      final BinEvent? event}) = _$_BinState;
  const _BinState._() : super._();

  @override
  DeviceBinID get id;
  @override
  BinStatus? get binStatus;
  @override
  DateTime? get scheduledTime;
  @override
  DateTime? get scheduledTimeLocal;
  @override
  BinSchedule? get schedule;
  @override
  BinEvent? get event;
  @override
  @JsonKey(ignore: true)
  _$$_BinStateCopyWith<_$_BinState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DosePeriod {
  int get binID => throw _privateConstructorUsedError;
  DateTime? get scheduledTime => throw _privateConstructorUsedError;
  BinStatus get status => throw _privateConstructorUsedError;
  List<int> get medicationIDs => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DosePeriodCopyWith<DosePeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DosePeriodCopyWith<$Res> {
  factory $DosePeriodCopyWith(
          DosePeriod value, $Res Function(DosePeriod) then) =
      _$DosePeriodCopyWithImpl<$Res, DosePeriod>;
  @useResult
  $Res call(
      {int binID,
      DateTime? scheduledTime,
      BinStatus status,
      List<int> medicationIDs});
}

/// @nodoc
class _$DosePeriodCopyWithImpl<$Res, $Val extends DosePeriod>
    implements $DosePeriodCopyWith<$Res> {
  _$DosePeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? binID = null,
    Object? scheduledTime = freezed,
    Object? status = null,
    Object? medicationIDs = null,
  }) {
    return _then(_value.copyWith(
      binID: null == binID
          ? _value.binID
          : binID // ignore: cast_nullable_to_non_nullable
              as int,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BinStatus,
      medicationIDs: null == medicationIDs
          ? _value.medicationIDs
          : medicationIDs // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_DosePeriodCopyWith<$Res>
    implements $DosePeriodCopyWith<$Res> {
  factory _$$_DosePeriodCopyWith(
          _$_DosePeriod value, $Res Function(_$_DosePeriod) then) =
      __$$_DosePeriodCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int binID,
      DateTime? scheduledTime,
      BinStatus status,
      List<int> medicationIDs});
}

/// @nodoc
class __$$_DosePeriodCopyWithImpl<$Res>
    extends _$DosePeriodCopyWithImpl<$Res, _$_DosePeriod>
    implements _$$_DosePeriodCopyWith<$Res> {
  __$$_DosePeriodCopyWithImpl(
      _$_DosePeriod _value, $Res Function(_$_DosePeriod) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? binID = null,
    Object? scheduledTime = freezed,
    Object? status = null,
    Object? medicationIDs = null,
  }) {
    return _then(_$_DosePeriod(
      binID: null == binID
          ? _value.binID
          : binID // ignore: cast_nullable_to_non_nullable
              as int,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BinStatus,
      medicationIDs: null == medicationIDs
          ? _value._medicationIDs
          : medicationIDs // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc

class _$_DosePeriod extends _DosePeriod with DiagnosticableTreeMixin {
  const _$_DosePeriod(
      {required this.binID,
      this.scheduledTime,
      required this.status,
      required final List<int> medicationIDs})
      : _medicationIDs = medicationIDs,
        super._();

  @override
  final int binID;
  @override
  final DateTime? scheduledTime;
  @override
  final BinStatus status;
  final List<int> _medicationIDs;
  @override
  List<int> get medicationIDs {
    if (_medicationIDs is EqualUnmodifiableListView) return _medicationIDs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_medicationIDs);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DosePeriod(binID: $binID, scheduledTime: $scheduledTime, status: $status, medicationIDs: $medicationIDs)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DosePeriod'))
      ..add(DiagnosticsProperty('binID', binID))
      ..add(DiagnosticsProperty('scheduledTime', scheduledTime))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('medicationIDs', medicationIDs));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DosePeriod &&
            (identical(other.binID, binID) || other.binID == binID) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._medicationIDs, _medicationIDs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, binID, scheduledTime, status,
      const DeepCollectionEquality().hash(_medicationIDs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DosePeriodCopyWith<_$_DosePeriod> get copyWith =>
      __$$_DosePeriodCopyWithImpl<_$_DosePeriod>(this, _$identity);
}

abstract class _DosePeriod extends DosePeriod {
  const factory _DosePeriod(
      {required final int binID,
      final DateTime? scheduledTime,
      required final BinStatus status,
      required final List<int> medicationIDs}) = _$_DosePeriod;
  const _DosePeriod._() : super._();

  @override
  int get binID;
  @override
  DateTime? get scheduledTime;
  @override
  BinStatus get status;
  @override
  List<int> get medicationIDs;
  @override
  @JsonKey(ignore: true)
  _$$_DosePeriodCopyWith<_$_DosePeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DeviceState {
  int get id => throw _privateConstructorUsedError;
  DateTime? get lastSync => throw _privateConstructorUsedError;
  List<BinStatus> get bins => throw _privateConstructorUsedError;
  List<DosePeriod> get dosePeriods => throw _privateConstructorUsedError;
  int? get battery => throw _privateConstructorUsedError;
  bool? get charging => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceStateCopyWith<DeviceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceStateCopyWith<$Res> {
  factory $DeviceStateCopyWith(
          DeviceState value, $Res Function(DeviceState) then) =
      _$DeviceStateCopyWithImpl<$Res, DeviceState>;
  @useResult
  $Res call(
      {int id,
      DateTime? lastSync,
      List<BinStatus> bins,
      List<DosePeriod> dosePeriods,
      int? battery,
      bool? charging});
}

/// @nodoc
class _$DeviceStateCopyWithImpl<$Res, $Val extends DeviceState>
    implements $DeviceStateCopyWith<$Res> {
  _$DeviceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lastSync = freezed,
    Object? bins = null,
    Object? dosePeriods = null,
    Object? battery = freezed,
    Object? charging = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      lastSync: freezed == lastSync
          ? _value.lastSync
          : lastSync // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bins: null == bins
          ? _value.bins
          : bins // ignore: cast_nullable_to_non_nullable
              as List<BinStatus>,
      dosePeriods: null == dosePeriods
          ? _value.dosePeriods
          : dosePeriods // ignore: cast_nullable_to_non_nullable
              as List<DosePeriod>,
      battery: freezed == battery
          ? _value.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as int?,
      charging: freezed == charging
          ? _value.charging
          : charging // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_DeviceStateCopyWith<$Res>
    implements $DeviceStateCopyWith<$Res> {
  factory _$$_DeviceStateCopyWith(
          _$_DeviceState value, $Res Function(_$_DeviceState) then) =
      __$$_DeviceStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      DateTime? lastSync,
      List<BinStatus> bins,
      List<DosePeriod> dosePeriods,
      int? battery,
      bool? charging});
}

/// @nodoc
class __$$_DeviceStateCopyWithImpl<$Res>
    extends _$DeviceStateCopyWithImpl<$Res, _$_DeviceState>
    implements _$$_DeviceStateCopyWith<$Res> {
  __$$_DeviceStateCopyWithImpl(
      _$_DeviceState _value, $Res Function(_$_DeviceState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call(
      {Object? id = null,
      Object? lastSync = freezed,
      Object? bins = null,
      Object? dosePeriods = null,
      Object? battery = freezed,
      Object? charging = freezed}) {
    return _then(_$_DeviceState(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      lastSync: freezed == lastSync
          ? _value.lastSync
          : lastSync // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bins: null == bins
          ? _value._bins
          : bins // ignore: cast_nullable_to_non_nullable
              as List<BinStatus>,
      dosePeriods: null == dosePeriods
          ? _value._dosePeriods
          : dosePeriods // ignore: cast_nullable_to_non_nullable
              as List<DosePeriod>,
      battery: freezed == battery
          ? _value.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as int?,
      charging: freezed == charging
          ? _value.charging
          : charging // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$_DeviceState extends _DeviceState {
  const _$_DeviceState(
      {required this.id,
      this.lastSync,
      required final List<BinStatus> bins,
      required final List<DosePeriod> dosePeriods,
      this.battery,
      this.charging})
      : _bins = bins,
        _dosePeriods = dosePeriods,
        super._();

  @override
  final int id;
  @override
  final DateTime? lastSync;
  final List<BinStatus> _bins;
  @override
  List<BinStatus> get bins {
    if (_bins is EqualUnmodifiableListView) return _bins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bins);
  }

  final List<DosePeriod> _dosePeriods;
  @override
  List<DosePeriod> get dosePeriods {
    if (_dosePeriods is EqualUnmodifiableListView) return _dosePeriods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dosePeriods);
  }

  @override
  final int? battery;
  @override
  final bool? charging;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DeviceStateCopyWith<_$_DeviceState> get copyWith =>
      __$$_DeviceStateCopyWithImpl<_$_DeviceState>(this, _$identity);
}

abstract class _DeviceState extends DeviceState {
  const factory _DeviceState(
      {required final int id,
      final DateTime? lastSync,
      required final List<BinStatus> bins,
      required final List<DosePeriod> dosePeriods,
      final int? battery,
      final bool? charging}) = _$_DeviceState;
  const _DeviceState._() : super._();

  @override
  int get id;
  @override
  DateTime? get lastSync;
  @override
  List<BinStatus> get bins;
  @override
  List<DosePeriod> get dosePeriods;
  @override
  int? get battery;
  @override
  bool? get charging;
  @override
  @JsonKey(ignore: true)
  _$$_DeviceStateCopyWith<_$_DeviceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DeviceUser {
  int get id => throw _privateConstructorUsedError;
  int get deviceID => throw _privateConstructorUsedError;
  String get deviceClass => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get serialNo => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastSeen => throw _privateConstructorUsedError;
  bool get primaryUser => throw _privateConstructorUsedError;
  bool get owner => throw _privateConstructorUsedError;
  bool get notifications => throw _privateConstructorUsedError;
  tz.Location? get timezone => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceUserCopyWith<DeviceUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceUserCopyWith<$Res> {
  factory $DeviceUserCopyWith(
          DeviceUser value, $Res Function(DeviceUser) then) =
      _$DeviceUserCopyWithImpl<$Res, DeviceUser>;
  @useResult
  $Res call(
      {int id,
      int deviceID,
      String deviceClass,
      String name,
      int serialNo,
      bool isOnline,
      DateTime? lastSeen,
      bool primaryUser,
      bool owner,
      bool notifications,
      tz.Location? timezone});
}

/// @nodoc
class _$DeviceUserCopyWithImpl<$Res, $Val extends DeviceUser>
    implements $DeviceUserCopyWith<$Res> {
  _$DeviceUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceID = null,
    Object? deviceClass = null,
    Object? name = null,
    Object? serialNo = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? primaryUser = null,
    Object? owner = null,
    Object? notifications = null,
    Object? timezone = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      deviceID: null == deviceID
          ? _value.deviceID
          : deviceID // ignore: cast_nullable_to_non_nullable
              as int,
      deviceClass: null == deviceClass
          ? _value.deviceClass
          : deviceClass // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      serialNo: null == serialNo
          ? _value.serialNo
          : serialNo // ignore: cast_nullable_to_non_nullable
              as int,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      primaryUser: null == primaryUser
          ? _value.primaryUser
          : primaryUser // ignore: cast_nullable_to_non_nullable
              as bool,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as bool,
      notifications: null == notifications
          ? _value.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as bool,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as tz.Location?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_DeviceUserCopyWith<$Res>
    implements $DeviceUserCopyWith<$Res> {
  factory _$$_DeviceUserCopyWith(
          _$_DeviceUser value, $Res Function(_$_DeviceUser) then) =
      __$$_DeviceUserCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int deviceID,
      String deviceClass,
      String name,
      int serialNo,
      bool isOnline,
      DateTime? lastSeen,
      bool primaryUser,
      bool owner,
      bool notifications,
      tz.Location? timezone});
}

/// @nodoc
class __$$_DeviceUserCopyWithImpl<$Res>
    extends _$DeviceUserCopyWithImpl<$Res, _$_DeviceUser>
    implements _$$_DeviceUserCopyWith<$Res> {
  __$$_DeviceUserCopyWithImpl(
      _$_DeviceUser _value, $Res Function(_$_DeviceUser) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceID = null,
    Object? deviceClass = null,
    Object? name = null,
    Object? serialNo = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? primaryUser = null,
    Object? owner = null,
    Object? notifications = null,
    Object? timezone = freezed,
  }) {
    return _then(_$_DeviceUser(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      deviceID: null == deviceID
          ? _value.deviceID
          : deviceID // ignore: cast_nullable_to_non_nullable
              as int,
      deviceClass: null == deviceClass
          ? _value.deviceClass
          : deviceClass // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      serialNo: null == serialNo
          ? _value.serialNo
          : serialNo // ignore: cast_nullable_to_non_nullable
              as int,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      primaryUser: null == primaryUser
          ? _value.primaryUser
          : primaryUser // ignore: cast_nullable_to_non_nullable
              as bool,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as bool,
      notifications: null == notifications
          ? _value.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as bool,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as tz.Location?,
    ));
  }
}

/// @nodoc

class _$_DeviceUser extends _DeviceUser {
  const _$_DeviceUser(
      {required this.id,
      required this.deviceID,
      required this.deviceClass,
      required this.name,
      required this.serialNo,
      required this.isOnline,
      this.lastSeen,
      required this.primaryUser,
      required this.owner,
      required this.notifications,
      this.timezone})
      : super._();

  @override
  final int id;
  @override
  final int deviceID;
  @override
  final String deviceClass;
  @override
  final String name;
  @override
  final int serialNo;
  @override
  final bool isOnline;
  @override
  final DateTime? lastSeen;
  @override
  final bool primaryUser;
  @override
  final bool owner;
  @override
  final bool notifications;
  @override
  final tz.Location? timezone;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DeviceUserCopyWith<_$_DeviceUser> get copyWith =>
      __$$_DeviceUserCopyWithImpl<_$_DeviceUser>(this, _$identity);
}

abstract class _DeviceUser extends DeviceUser {
  const factory _DeviceUser(
      {required final int id,
      required final int deviceID,
      required final String deviceClass,
      required final String name,
      required final int serialNo,
      required final bool isOnline,
      final DateTime? lastSeen,
      required final bool primaryUser,
      required final bool owner,
      required final bool notifications,
      final tz.Location? timezone}) = _$_DeviceUser;
  const _DeviceUser._() : super._();

  @override
  int get id;
  @override
  int get deviceID;
  @override
  String get deviceClass;
  @override
  String get name;
  @override
  int get serialNo;
  @override
  bool get isOnline;
  @override
  DateTime? get lastSeen;
  @override
  bool get primaryUser;
  @override
  bool get owner;
  @override
  bool get notifications;
  @override
  tz.Location? get timezone;
  @override
  @JsonKey(ignore: true)
  _$$_DeviceUserCopyWith<_$_DeviceUser> get copyWith =>
      throw _privateConstructorUsedError;
}
