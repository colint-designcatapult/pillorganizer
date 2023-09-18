///
//  Generated code. Do not modify.
//  source: pill.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'pill.pbenum.dart';

export 'pill.pbenum.dart';

class BinState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'BinState',
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'scheduledTime')
    ..e<BinStatus>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'status',
        $pb.PbFieldType.OE,
        defaultOrMaker: BinStatus.DISABLED,
        valueOf: BinStatus.valueOf,
        enumValues: BinStatus.values)
    ..hasRequiredFields = false;

  BinState._() : super();
  factory BinState({
    $fixnum.Int64? scheduledTime,
    BinStatus? status,
  }) {
    final _result = create();
    if (scheduledTime != null) {
      _result.scheduledTime = scheduledTime;
    }
    if (status != null) {
      _result.status = status;
    }
    return _result;
  }
  factory BinState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BinState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BinState clone() => BinState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BinState copyWith(void Function(BinState) updates) =>
      super.copyWith((message) => updates(message as BinState))
          as BinState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BinState create() => BinState._();
  BinState createEmptyInstance() => create();
  static $pb.PbList<BinState> createRepeated() => $pb.PbList<BinState>();
  @$core.pragma('dart2js:noInline')
  static BinState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BinState>(create);
  static BinState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get scheduledTime => $_getI64(0);
  @$pb.TagNumber(1)
  set scheduledTime($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasScheduledTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearScheduledTime() => clearField(1);

  @$pb.TagNumber(2)
  BinStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(BinStatus v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);
}

class AllBinsState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AllBinsState',
      createEmptyInstance: create)
    ..pc<BinState>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bins',
        $pb.PbFieldType.PM,
        subBuilder: BinState.create)
    ..hasRequiredFields = false;

  AllBinsState._() : super();
  factory AllBinsState({
    $core.Iterable<BinState>? bins,
  }) {
    final _result = create();
    if (bins != null) {
      _result.bins.addAll(bins);
    }
    return _result;
  }
  factory AllBinsState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AllBinsState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AllBinsState clone() => AllBinsState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AllBinsState copyWith(void Function(AllBinsState) updates) =>
      super.copyWith((message) => updates(message as AllBinsState))
          as AllBinsState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AllBinsState create() => AllBinsState._();
  AllBinsState createEmptyInstance() => create();
  static $pb.PbList<AllBinsState> createRepeated() =>
      $pb.PbList<AllBinsState>();
  @$core.pragma('dart2js:noInline')
  static AllBinsState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AllBinsState>(create);
  static AllBinsState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BinState> get bins => $_getList(0);
}

class RecordedEvent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RecordedEvent',
      createEmptyInstance: create)
    ..e<RecordedEvent_EventType>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: RecordedEvent_EventType.OPENED,
        valueOf: RecordedEvent_EventType.valueOf,
        enumValues: RecordedEvent_EventType.values)
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'timestamp')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bin',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  RecordedEvent._() : super();
  factory RecordedEvent({
    RecordedEvent_EventType? type,
    $fixnum.Int64? timestamp,
    $core.int? bin,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (bin != null) {
      _result.bin = bin;
    }
    return _result;
  }
  factory RecordedEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RecordedEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RecordedEvent clone() => RecordedEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RecordedEvent copyWith(void Function(RecordedEvent) updates) =>
      super.copyWith((message) => updates(message as RecordedEvent))
          as RecordedEvent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordedEvent create() => RecordedEvent._();
  RecordedEvent createEmptyInstance() => create();
  static $pb.PbList<RecordedEvent> createRepeated() =>
      $pb.PbList<RecordedEvent>();
  @$core.pragma('dart2js:noInline')
  static RecordedEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecordedEvent>(create);
  static RecordedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  RecordedEvent_EventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(RecordedEvent_EventType v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get bin => $_getIZ(2);
  @$pb.TagNumber(3)
  set bin($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBin() => $_has(2);
  @$pb.TagNumber(3)
  void clearBin() => clearField(3);
}

class SubmitEventRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubmitEventRequest',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deviceId',
        $pb.PbFieldType.OY)
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stateHash')
    ..aOM<RecordedEvent>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'event',
        subBuilder: RecordedEvent.create)
    ..hasRequiredFields = false;

  SubmitEventRequest._() : super();
  factory SubmitEventRequest({
    $core.List<$core.int>? deviceId,
    $fixnum.Int64? stateHash,
    RecordedEvent? event,
  }) {
    final _result = create();
    if (deviceId != null) {
      _result.deviceId = deviceId;
    }
    if (stateHash != null) {
      _result.stateHash = stateHash;
    }
    if (event != null) {
      _result.event = event;
    }
    return _result;
  }
  factory SubmitEventRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubmitEventRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubmitEventRequest clone() => SubmitEventRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubmitEventRequest copyWith(void Function(SubmitEventRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitEventRequest))
          as SubmitEventRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubmitEventRequest create() => SubmitEventRequest._();
  SubmitEventRequest createEmptyInstance() => create();
  static $pb.PbList<SubmitEventRequest> createRepeated() =>
      $pb.PbList<SubmitEventRequest>();
  @$core.pragma('dart2js:noInline')
  static SubmitEventRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitEventRequest>(create);
  static SubmitEventRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get stateHash => $_getI64(1);
  @$pb.TagNumber(2)
  set stateHash($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStateHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearStateHash() => clearField(2);

  @$pb.TagNumber(3)
  RecordedEvent get event => $_getN(2);
  @$pb.TagNumber(3)
  set event(RecordedEvent v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEvent() => $_has(2);
  @$pb.TagNumber(3)
  void clearEvent() => clearField(3);
  @$pb.TagNumber(3)
  RecordedEvent ensureEvent() => $_ensure(2);
}

class SubmitEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubmitEventsRequest',
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stateHash')
    ..pc<RecordedEvent>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'event',
        $pb.PbFieldType.PM,
        subBuilder: RecordedEvent.create)
    ..hasRequiredFields = false;

  SubmitEventsRequest._() : super();
  factory SubmitEventsRequest({
    $fixnum.Int64? stateHash,
    $core.Iterable<RecordedEvent>? event,
  }) {
    final _result = create();
    if (stateHash != null) {
      _result.stateHash = stateHash;
    }
    if (event != null) {
      _result.event.addAll(event);
    }
    return _result;
  }
  factory SubmitEventsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubmitEventsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubmitEventsRequest clone() => SubmitEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubmitEventsRequest copyWith(void Function(SubmitEventsRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitEventsRequest))
          as SubmitEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubmitEventsRequest create() => SubmitEventsRequest._();
  SubmitEventsRequest createEmptyInstance() => create();
  static $pb.PbList<SubmitEventsRequest> createRepeated() =>
      $pb.PbList<SubmitEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static SubmitEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitEventsRequest>(create);
  static SubmitEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get stateHash => $_getI64(0);
  @$pb.TagNumber(1)
  set stateHash($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStateHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearStateHash() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<RecordedEvent> get event => $_getList(1);
}

class SubmitEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubmitEventsResponse',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'result',
        $pb.PbFieldType.O3)
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stateHash')
    ..hasRequiredFields = false;

  SubmitEventsResponse._() : super();
  factory SubmitEventsResponse({
    $core.int? result,
    $fixnum.Int64? stateHash,
  }) {
    final _result = create();
    if (result != null) {
      _result.result = result;
    }
    if (stateHash != null) {
      _result.stateHash = stateHash;
    }
    return _result;
  }
  factory SubmitEventsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubmitEventsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubmitEventsResponse clone() =>
      SubmitEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubmitEventsResponse copyWith(void Function(SubmitEventsResponse) updates) =>
      super.copyWith((message) => updates(message as SubmitEventsResponse))
          as SubmitEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubmitEventsResponse create() => SubmitEventsResponse._();
  SubmitEventsResponse createEmptyInstance() => create();
  static $pb.PbList<SubmitEventsResponse> createRepeated() =>
      $pb.PbList<SubmitEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static SubmitEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitEventsResponse>(create);
  static SubmitEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get result => $_getIZ(0);
  @$pb.TagNumber(1)
  set result($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get stateHash => $_getI64(1);
  @$pb.TagNumber(2)
  set stateHash($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStateHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearStateHash() => clearField(2);
}

class BinSchedule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'BinSchedule',
      createEmptyInstance: create)
    ..e<BinSchedule_DayOfWeek>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dayOfWeek',
        $pb.PbFieldType.OE,
        defaultOrMaker: BinSchedule_DayOfWeek.MONDAY,
        valueOf: BinSchedule_DayOfWeek.valueOf,
        enumValues: BinSchedule_DayOfWeek.values)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'secondsFrom00',
        $pb.PbFieldType.OU3,
        protoName: 'seconds_from_00')
    ..hasRequiredFields = false;

  BinSchedule._() : super();
  factory BinSchedule({
    BinSchedule_DayOfWeek? dayOfWeek,
    $core.int? secondsFrom00,
  }) {
    final _result = create();
    if (dayOfWeek != null) {
      _result.dayOfWeek = dayOfWeek;
    }
    if (secondsFrom00 != null) {
      _result.secondsFrom00 = secondsFrom00;
    }
    return _result;
  }
  factory BinSchedule.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BinSchedule.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BinSchedule clone() => BinSchedule()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BinSchedule copyWith(void Function(BinSchedule) updates) =>
      super.copyWith((message) => updates(message as BinSchedule))
          as BinSchedule; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BinSchedule create() => BinSchedule._();
  BinSchedule createEmptyInstance() => create();
  static $pb.PbList<BinSchedule> createRepeated() => $pb.PbList<BinSchedule>();
  @$core.pragma('dart2js:noInline')
  static BinSchedule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BinSchedule>(create);
  static BinSchedule? _defaultInstance;

  @$pb.TagNumber(1)
  BinSchedule_DayOfWeek get dayOfWeek => $_getN(0);
  @$pb.TagNumber(1)
  set dayOfWeek(BinSchedule_DayOfWeek v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDayOfWeek() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayOfWeek() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get secondsFrom00 => $_getIZ(1);
  @$pb.TagNumber(2)
  set secondsFrom00($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSecondsFrom00() => $_has(1);
  @$pb.TagNumber(2)
  void clearSecondsFrom00() => clearField(2);
}

class ScheduleResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ScheduleResponse',
      createEmptyInstance: create)
    ..pc<BinSchedule>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'schedule',
        $pb.PbFieldType.PM,
        subBuilder: BinSchedule.create)
    ..hasRequiredFields = false;

  ScheduleResponse._() : super();
  factory ScheduleResponse({
    $core.Iterable<BinSchedule>? schedule,
  }) {
    final _result = create();
    if (schedule != null) {
      _result.schedule.addAll(schedule);
    }
    return _result;
  }
  factory ScheduleResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleResponse clone() => ScheduleResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleResponse copyWith(void Function(ScheduleResponse) updates) =>
      super.copyWith((message) => updates(message as ScheduleResponse))
          as ScheduleResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ScheduleResponse create() => ScheduleResponse._();
  ScheduleResponse createEmptyInstance() => create();
  static $pb.PbList<ScheduleResponse> createRepeated() =>
      $pb.PbList<ScheduleResponse>();
  @$core.pragma('dart2js:noInline')
  static ScheduleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScheduleResponse>(create);
  static ScheduleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BinSchedule> get schedule => $_getList(0);
}

class ProvisionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ProvisionRequest',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deviceId',
        $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bssid',
        $pb.PbFieldType.OY)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ssid')
    ..hasRequiredFields = false;

  ProvisionRequest._() : super();
  factory ProvisionRequest({
    $core.List<$core.int>? deviceId,
    $core.List<$core.int>? bssid,
    $core.String? ssid,
  }) {
    final _result = create();
    if (deviceId != null) {
      _result.deviceId = deviceId;
    }
    if (bssid != null) {
      _result.bssid = bssid;
    }
    if (ssid != null) {
      _result.ssid = ssid;
    }
    return _result;
  }
  factory ProvisionRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ProvisionRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ProvisionRequest clone() => ProvisionRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ProvisionRequest copyWith(void Function(ProvisionRequest) updates) =>
      super.copyWith((message) => updates(message as ProvisionRequest))
          as ProvisionRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ProvisionRequest create() => ProvisionRequest._();
  ProvisionRequest createEmptyInstance() => create();
  static $pb.PbList<ProvisionRequest> createRepeated() =>
      $pb.PbList<ProvisionRequest>();
  @$core.pragma('dart2js:noInline')
  static ProvisionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProvisionRequest>(create);
  static ProvisionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deviceId => $_getN(0);
  @$pb.TagNumber(1)
  set deviceId($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get bssid => $_getN(1);
  @$pb.TagNumber(2)
  set bssid($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBssid() => $_has(1);
  @$pb.TagNumber(2)
  void clearBssid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ssid => $_getSZ(2);
  @$pb.TagNumber(3)
  set ssid($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSsid() => $_has(2);
  @$pb.TagNumber(3)
  void clearSsid() => clearField(3);
}

class EngineeringData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EngineeringData',
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'timestamp')
    ..p<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'voltages',
        $pb.PbFieldType.K3)
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'vbatScaled',
        $pb.PbFieldType.OF)
    ..a<$core.double>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'vbatMeas',
        $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  EngineeringData._() : super();
  factory EngineeringData({
    $fixnum.Int64? timestamp,
    $core.Iterable<$core.int>? voltages,
    $core.double? vbatScaled,
    $core.double? vbatMeas,
  }) {
    final _result = create();
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (voltages != null) {
      _result.voltages.addAll(voltages);
    }
    if (vbatScaled != null) {
      _result.vbatScaled = vbatScaled;
    }
    if (vbatMeas != null) {
      _result.vbatMeas = vbatMeas;
    }
    return _result;
  }
  factory EngineeringData.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EngineeringData.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EngineeringData clone() => EngineeringData()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EngineeringData copyWith(void Function(EngineeringData) updates) =>
      super.copyWith((message) => updates(message as EngineeringData))
          as EngineeringData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EngineeringData create() => EngineeringData._();
  EngineeringData createEmptyInstance() => create();
  static $pb.PbList<EngineeringData> createRepeated() =>
      $pb.PbList<EngineeringData>();
  @$core.pragma('dart2js:noInline')
  static EngineeringData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineeringData>(create);
  static EngineeringData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get voltages => $_getList(1);

  @$pb.TagNumber(3)
  $core.double get vbatScaled => $_getN(2);
  @$pb.TagNumber(3)
  set vbatScaled($core.double v) {
    $_setFloat(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVbatScaled() => $_has(2);
  @$pb.TagNumber(3)
  void clearVbatScaled() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get vbatMeas => $_getN(3);
  @$pb.TagNumber(4)
  set vbatMeas($core.double v) {
    $_setFloat(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasVbatMeas() => $_has(3);
  @$pb.TagNumber(4)
  void clearVbatMeas() => clearField(4);
}

class EngineeringRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EngineeringRequest',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'holdMuxChannel',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  EngineeringRequest._() : super();
  factory EngineeringRequest({
    $core.int? holdMuxChannel,
  }) {
    final _result = create();
    if (holdMuxChannel != null) {
      _result.holdMuxChannel = holdMuxChannel;
    }
    return _result;
  }
  factory EngineeringRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EngineeringRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EngineeringRequest clone() => EngineeringRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EngineeringRequest copyWith(void Function(EngineeringRequest) updates) =>
      super.copyWith((message) => updates(message as EngineeringRequest))
          as EngineeringRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EngineeringRequest create() => EngineeringRequest._();
  EngineeringRequest createEmptyInstance() => create();
  static $pb.PbList<EngineeringRequest> createRepeated() =>
      $pb.PbList<EngineeringRequest>();
  @$core.pragma('dart2js:noInline')
  static EngineeringRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineeringRequest>(create);
  static EngineeringRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get holdMuxChannel => $_getIZ(0);
  @$pb.TagNumber(1)
  set holdMuxChannel($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHoldMuxChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearHoldMuxChannel() => clearField(1);
}

class SyncRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SyncRequest',
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stateHash')
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'eventCtr')
    ..pc<RecordedEvent>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'events',
        $pb.PbFieldType.PM,
        subBuilder: RecordedEvent.create)
    ..aOM<AllBinsState>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'binState',
        subBuilder: AllBinsState.create)
    ..aOM<EngineeringData>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'engrData',
        subBuilder: EngineeringData.create)
    ..a<$core.int>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ipv4',
        $pb.PbFieldType.OF3)
    ..a<$core.List<$core.int>>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ipv6',
        $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  SyncRequest._() : super();
  factory SyncRequest({
    $fixnum.Int64? stateHash,
    $fixnum.Int64? eventCtr,
    $core.Iterable<RecordedEvent>? events,
    AllBinsState? binState,
    EngineeringData? engrData,
    $core.int? ipv4,
    $core.List<$core.int>? ipv6,
  }) {
    final _result = create();
    if (stateHash != null) {
      _result.stateHash = stateHash;
    }
    if (eventCtr != null) {
      _result.eventCtr = eventCtr;
    }
    if (events != null) {
      _result.events.addAll(events);
    }
    if (binState != null) {
      _result.binState = binState;
    }
    if (engrData != null) {
      _result.engrData = engrData;
    }
    if (ipv4 != null) {
      _result.ipv4 = ipv4;
    }
    if (ipv6 != null) {
      _result.ipv6 = ipv6;
    }
    return _result;
  }
  factory SyncRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SyncRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SyncRequest clone() => SyncRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SyncRequest copyWith(void Function(SyncRequest) updates) =>
      super.copyWith((message) => updates(message as SyncRequest))
          as SyncRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SyncRequest create() => SyncRequest._();
  SyncRequest createEmptyInstance() => create();
  static $pb.PbList<SyncRequest> createRepeated() => $pb.PbList<SyncRequest>();
  @$core.pragma('dart2js:noInline')
  static SyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncRequest>(create);
  static SyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get stateHash => $_getI64(0);
  @$pb.TagNumber(1)
  set stateHash($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStateHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearStateHash() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get eventCtr => $_getI64(1);
  @$pb.TagNumber(2)
  set eventCtr($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEventCtr() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventCtr() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<RecordedEvent> get events => $_getList(2);

  @$pb.TagNumber(4)
  AllBinsState get binState => $_getN(3);
  @$pb.TagNumber(4)
  set binState(AllBinsState v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasBinState() => $_has(3);
  @$pb.TagNumber(4)
  void clearBinState() => clearField(4);
  @$pb.TagNumber(4)
  AllBinsState ensureBinState() => $_ensure(3);

  @$pb.TagNumber(5)
  EngineeringData get engrData => $_getN(4);
  @$pb.TagNumber(5)
  set engrData(EngineeringData v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEngrData() => $_has(4);
  @$pb.TagNumber(5)
  void clearEngrData() => clearField(5);
  @$pb.TagNumber(5)
  EngineeringData ensureEngrData() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.int get ipv4 => $_getIZ(5);
  @$pb.TagNumber(6)
  set ipv4($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasIpv4() => $_has(5);
  @$pb.TagNumber(6)
  void clearIpv4() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get ipv6 => $_getN(6);
  @$pb.TagNumber(7)
  set ipv6($core.List<$core.int> v) {
    $_setBytes(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasIpv6() => $_has(6);
  @$pb.TagNumber(7)
  void clearIpv6() => clearField(7);
}

class SyncResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SyncResponse',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'persistedEvents',
        $pb.PbFieldType.O3)
    ..aOM<AllBinsState>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'binState',
        subBuilder: AllBinsState.create)
    ..pc<BinSchedule>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'schedule',
        $pb.PbFieldType.PM,
        subBuilder: BinSchedule.create)
    ..aOB(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'engrMode')
    ..aOM<EngineeringRequest>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'engrReq',
        subBuilder: EngineeringRequest.create)
    ..a<$core.int>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'latestFirmware',
        $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  SyncResponse._() : super();
  factory SyncResponse({
    $core.int? persistedEvents,
    AllBinsState? binState,
    $core.Iterable<BinSchedule>? schedule,
    $core.bool? engrMode,
    EngineeringRequest? engrReq,
    $core.int? latestFirmware,
  }) {
    final _result = create();
    if (persistedEvents != null) {
      _result.persistedEvents = persistedEvents;
    }
    if (binState != null) {
      _result.binState = binState;
    }
    if (schedule != null) {
      _result.schedule.addAll(schedule);
    }
    if (engrMode != null) {
      _result.engrMode = engrMode;
    }
    if (engrReq != null) {
      _result.engrReq = engrReq;
    }
    if (latestFirmware != null) {
      _result.latestFirmware = latestFirmware;
    }
    return _result;
  }
  factory SyncResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SyncResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SyncResponse clone() => SyncResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SyncResponse copyWith(void Function(SyncResponse) updates) =>
      super.copyWith((message) => updates(message as SyncResponse))
          as SyncResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SyncResponse create() => SyncResponse._();
  SyncResponse createEmptyInstance() => create();
  static $pb.PbList<SyncResponse> createRepeated() =>
      $pb.PbList<SyncResponse>();
  @$core.pragma('dart2js:noInline')
  static SyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncResponse>(create);
  static SyncResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get persistedEvents => $_getIZ(0);
  @$pb.TagNumber(1)
  set persistedEvents($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPersistedEvents() => $_has(0);
  @$pb.TagNumber(1)
  void clearPersistedEvents() => clearField(1);

  @$pb.TagNumber(2)
  AllBinsState get binState => $_getN(1);
  @$pb.TagNumber(2)
  set binState(AllBinsState v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBinState() => $_has(1);
  @$pb.TagNumber(2)
  void clearBinState() => clearField(2);
  @$pb.TagNumber(2)
  AllBinsState ensureBinState() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<BinSchedule> get schedule => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get engrMode => $_getBF(3);
  @$pb.TagNumber(4)
  set engrMode($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEngrMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearEngrMode() => clearField(4);

  @$pb.TagNumber(6)
  EngineeringRequest get engrReq => $_getN(4);
  @$pb.TagNumber(6)
  set engrReq(EngineeringRequest v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasEngrReq() => $_has(4);
  @$pb.TagNumber(6)
  void clearEngrReq() => clearField(6);
  @$pb.TagNumber(6)
  EngineeringRequest ensureEngrReq() => $_ensure(4);

  @$pb.TagNumber(7)
  $core.int get latestFirmware => $_getIZ(5);
  @$pb.TagNumber(7)
  set latestFirmware($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasLatestFirmware() => $_has(5);
  @$pb.TagNumber(7)
  void clearLatestFirmware() => clearField(7);
}

class AuthorizeRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AuthorizeRequest',
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serialNo')
    ..a<$core.List<$core.int>>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'oobKey',
        $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  AuthorizeRequest._() : super();
  factory AuthorizeRequest({
    $fixnum.Int64? serialNo,
    $core.List<$core.int>? oobKey,
  }) {
    final _result = create();
    if (serialNo != null) {
      _result.serialNo = serialNo;
    }
    if (oobKey != null) {
      _result.oobKey = oobKey;
    }
    return _result;
  }
  factory AuthorizeRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AuthorizeRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AuthorizeRequest clone() => AuthorizeRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AuthorizeRequest copyWith(void Function(AuthorizeRequest) updates) =>
      super.copyWith((message) => updates(message as AuthorizeRequest))
          as AuthorizeRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AuthorizeRequest create() => AuthorizeRequest._();
  AuthorizeRequest createEmptyInstance() => create();
  static $pb.PbList<AuthorizeRequest> createRepeated() =>
      $pb.PbList<AuthorizeRequest>();
  @$core.pragma('dart2js:noInline')
  static AuthorizeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthorizeRequest>(create);
  static AuthorizeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serialNo => $_getI64(0);
  @$pb.TagNumber(1)
  set serialNo($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSerialNo() => $_has(0);
  @$pb.TagNumber(1)
  void clearSerialNo() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get oobKey => $_getN(1);
  @$pb.TagNumber(2)
  set oobKey($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOobKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearOobKey() => clearField(2);
}

class AuthorizeResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AuthorizeResponse',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'accessToken')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'refreshToken')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'tokenType')
    ..aInt64(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expiresIn')
    ..hasRequiredFields = false;

  AuthorizeResponse._() : super();
  factory AuthorizeResponse({
    $core.String? accessToken,
    $core.String? refreshToken,
    $core.String? tokenType,
    $fixnum.Int64? expiresIn,
  }) {
    final _result = create();
    if (accessToken != null) {
      _result.accessToken = accessToken;
    }
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (tokenType != null) {
      _result.tokenType = tokenType;
    }
    if (expiresIn != null) {
      _result.expiresIn = expiresIn;
    }
    return _result;
  }
  factory AuthorizeResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AuthorizeResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AuthorizeResponse clone() => AuthorizeResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AuthorizeResponse copyWith(void Function(AuthorizeResponse) updates) =>
      super.copyWith((message) => updates(message as AuthorizeResponse))
          as AuthorizeResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AuthorizeResponse create() => AuthorizeResponse._();
  AuthorizeResponse createEmptyInstance() => create();
  static $pb.PbList<AuthorizeResponse> createRepeated() =>
      $pb.PbList<AuthorizeResponse>();
  @$core.pragma('dart2js:noInline')
  static AuthorizeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthorizeResponse>(create);
  static AuthorizeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accessToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set accessToken($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAccessToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccessToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get refreshToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set refreshToken($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRefreshToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearRefreshToken() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get tokenType => $_getSZ(2);
  @$pb.TagNumber(3)
  set tokenType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTokenType() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokenType() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expiresIn => $_getI64(3);
  @$pb.TagNumber(4)
  set expiresIn($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasExpiresIn() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresIn() => clearField(4);
}

class DeviceProvisionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DeviceProvisionRequest',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bssid',
        $pb.PbFieldType.OY)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ssid')
    ..hasRequiredFields = false;

  DeviceProvisionRequest._() : super();
  factory DeviceProvisionRequest({
    $core.List<$core.int>? bssid,
    $core.String? ssid,
  }) {
    final _result = create();
    if (bssid != null) {
      _result.bssid = bssid;
    }
    if (ssid != null) {
      _result.ssid = ssid;
    }
    return _result;
  }
  factory DeviceProvisionRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DeviceProvisionRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DeviceProvisionRequest clone() =>
      DeviceProvisionRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DeviceProvisionRequest copyWith(
          void Function(DeviceProvisionRequest) updates) =>
      super.copyWith((message) => updates(message as DeviceProvisionRequest))
          as DeviceProvisionRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeviceProvisionRequest create() => DeviceProvisionRequest._();
  DeviceProvisionRequest createEmptyInstance() => create();
  static $pb.PbList<DeviceProvisionRequest> createRepeated() =>
      $pb.PbList<DeviceProvisionRequest>();
  @$core.pragma('dart2js:noInline')
  static DeviceProvisionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceProvisionRequest>(create);
  static DeviceProvisionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get bssid => $_getN(0);
  @$pb.TagNumber(1)
  set bssid($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBssid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBssid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get ssid => $_getSZ(1);
  @$pb.TagNumber(2)
  set ssid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSsid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSsid() => clearField(2);
}

class EngineeringBinState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EngineeringBinState',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'voltage',
        $pb.PbFieldType.O3)
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'open')
    ..e<BinStatus>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'status',
        $pb.PbFieldType.OE,
        defaultOrMaker: BinStatus.DISABLED,
        valueOf: BinStatus.valueOf,
        enumValues: BinStatus.values)
    ..aInt64(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'scheduledTime')
    ..hasRequiredFields = false;

  EngineeringBinState._() : super();
  factory EngineeringBinState({
    $core.int? voltage,
    $core.bool? open,
    BinStatus? status,
    $fixnum.Int64? scheduledTime,
  }) {
    final _result = create();
    if (voltage != null) {
      _result.voltage = voltage;
    }
    if (open != null) {
      _result.open = open;
    }
    if (status != null) {
      _result.status = status;
    }
    if (scheduledTime != null) {
      _result.scheduledTime = scheduledTime;
    }
    return _result;
  }
  factory EngineeringBinState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EngineeringBinState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EngineeringBinState clone() => EngineeringBinState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EngineeringBinState copyWith(void Function(EngineeringBinState) updates) =>
      super.copyWith((message) => updates(message as EngineeringBinState))
          as EngineeringBinState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EngineeringBinState create() => EngineeringBinState._();
  EngineeringBinState createEmptyInstance() => create();
  static $pb.PbList<EngineeringBinState> createRepeated() =>
      $pb.PbList<EngineeringBinState>();
  @$core.pragma('dart2js:noInline')
  static EngineeringBinState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineeringBinState>(create);
  static EngineeringBinState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get voltage => $_getIZ(0);
  @$pb.TagNumber(1)
  set voltage($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasVoltage() => $_has(0);
  @$pb.TagNumber(1)
  void clearVoltage() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get open => $_getBF(1);
  @$pb.TagNumber(2)
  set open($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOpen() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpen() => clearField(2);

  @$pb.TagNumber(3)
  BinStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(BinStatus v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get scheduledTime => $_getI64(3);
  @$pb.TagNumber(4)
  set scheduledTime($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasScheduledTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearScheduledTime() => clearField(4);
}

class EngineeringAllBins extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EngineeringAllBins',
      createEmptyInstance: create)
    ..pc<EngineeringBinState>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bins',
        $pb.PbFieldType.PM,
        subBuilder: EngineeringBinState.create)
    ..hasRequiredFields = false;

  EngineeringAllBins._() : super();
  factory EngineeringAllBins({
    $core.Iterable<EngineeringBinState>? bins,
  }) {
    final _result = create();
    if (bins != null) {
      _result.bins.addAll(bins);
    }
    return _result;
  }
  factory EngineeringAllBins.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EngineeringAllBins.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EngineeringAllBins clone() => EngineeringAllBins()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EngineeringAllBins copyWith(void Function(EngineeringAllBins) updates) =>
      super.copyWith((message) => updates(message as EngineeringAllBins))
          as EngineeringAllBins; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EngineeringAllBins create() => EngineeringAllBins._();
  EngineeringAllBins createEmptyInstance() => create();
  static $pb.PbList<EngineeringAllBins> createRepeated() =>
      $pb.PbList<EngineeringAllBins>();
  @$core.pragma('dart2js:noInline')
  static EngineeringAllBins getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineeringAllBins>(create);
  static EngineeringAllBins? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<EngineeringBinState> get bins => $_getList(0);
}
