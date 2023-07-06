///
//  Generated code. Do not modify.
//  source: pill.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class BinStatus extends $pb.ProtobufEnum {
  static const BinStatus DISABLED = BinStatus._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DISABLED');
  static const BinStatus TAKEN = BinStatus._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TAKEN');
  static const BinStatus MISSED = BinStatus._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MISSED');
  static const BinStatus PENDING = BinStatus._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PENDING');
  static const BinStatus TAKE_NOW = BinStatus._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TAKE_NOW');

  static const $core.List<BinStatus> values = <BinStatus> [
    DISABLED,
    TAKEN,
    MISSED,
    PENDING,
    TAKE_NOW,
  ];

  static final $core.Map<$core.int, BinStatus> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BinStatus? valueOf($core.int value) => _byValue[value];

  const BinStatus._($core.int v, $core.String n) : super(v, n);
}

class RecordedEvent_EventType extends $pb.ProtobufEnum {
  static const RecordedEvent_EventType OPENED = RecordedEvent_EventType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OPENED');
  static const RecordedEvent_EventType CLOSED = RecordedEvent_EventType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CLOSED');
  static const RecordedEvent_EventType MISSED = RecordedEvent_EventType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MISSED');

  static const $core.List<RecordedEvent_EventType> values = <RecordedEvent_EventType> [
    OPENED,
    CLOSED,
    MISSED,
  ];

  static final $core.Map<$core.int, RecordedEvent_EventType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RecordedEvent_EventType? valueOf($core.int value) => _byValue[value];

  const RecordedEvent_EventType._($core.int v, $core.String n) : super(v, n);
}

class BinSchedule_DayOfWeek extends $pb.ProtobufEnum {
  static const BinSchedule_DayOfWeek MONDAY = BinSchedule_DayOfWeek._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MONDAY');
  static const BinSchedule_DayOfWeek TUESDAY = BinSchedule_DayOfWeek._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TUESDAY');
  static const BinSchedule_DayOfWeek WEDNESDAY = BinSchedule_DayOfWeek._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WEDNESDAY');
  static const BinSchedule_DayOfWeek THURSDAY = BinSchedule_DayOfWeek._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'THURSDAY');
  static const BinSchedule_DayOfWeek FRIDAY = BinSchedule_DayOfWeek._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FRIDAY');
  static const BinSchedule_DayOfWeek SATURDAY = BinSchedule_DayOfWeek._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SATURDAY');
  static const BinSchedule_DayOfWeek SUNDAY = BinSchedule_DayOfWeek._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SUNDAY');
  static const BinSchedule_DayOfWeek DISABLED = BinSchedule_DayOfWeek._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DISABLED');

  static const $core.List<BinSchedule_DayOfWeek> values = <BinSchedule_DayOfWeek> [
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY,
    SUNDAY,
    DISABLED,
  ];

  static final $core.Map<$core.int, BinSchedule_DayOfWeek> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BinSchedule_DayOfWeek? valueOf($core.int value) => _byValue[value];

  const BinSchedule_DayOfWeek._($core.int v, $core.String n) : super(v, n);
}

