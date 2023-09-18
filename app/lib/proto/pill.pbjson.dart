///
import 'dart:convert' as $convert;
//  Generated code. Do not modify.
//  source: pill.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use binStatusDescriptor instead')
const BinStatus$json = const {
  '1': 'BinStatus',
  '2': const [
    const {'1': 'DISABLED', '2': 0},
    const {'1': 'TAKEN', '2': 1},
    const {'1': 'MISSED', '2': 2},
    const {'1': 'PENDING', '2': 3},
    const {'1': 'TAKE_NOW', '2': 4},
  ],
};

/// Descriptor for `BinStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List binStatusDescriptor = $convert.base64Decode(
    'CglCaW5TdGF0dXMSDAoIRElTQUJMRUQQABIJCgVUQUtFThABEgoKBk1JU1NFRBACEgsKB1BFTkRJTkcQAxIMCghUQUtFX05PVxAE');
@$core.Deprecated('Use binStateDescriptor instead')
const BinState$json = const {
  '1': 'BinState',
  '2': const [
    const {
      '1': 'scheduled_time',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'scheduledTime'
    },
    const {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.BinStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `BinState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List binStateDescriptor = $convert.base64Decode(
    'CghCaW5TdGF0ZRIlCg5zY2hlZHVsZWRfdGltZRgBIAEoA1INc2NoZWR1bGVkVGltZRIiCgZzdGF0dXMYAiABKA4yCi5CaW5TdGF0dXNSBnN0YXR1cw==');
@$core.Deprecated('Use allBinsStateDescriptor instead')
const AllBinsState$json = const {
  '1': 'AllBinsState',
  '2': const [
    const {
      '1': 'bins',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.BinState',
      '8': const {},
      '10': 'bins'
    },
  ],
};

/// Descriptor for `AllBinsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allBinsStateDescriptor = $convert.base64Decode(
    'CgxBbGxCaW5zU3RhdGUSKQoEYmlucxgBIAMoCzIJLkJpblN0YXRlQgqSPwIQDpI/AngBUgRiaW5z');
@$core.Deprecated('Use recordedEventDescriptor instead')
const RecordedEvent$json = const {
  '1': 'RecordedEvent',
  '2': const [
    const {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.RecordedEvent.EventType',
      '10': 'type'
    },
    const {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    const {'1': 'bin', '3': 3, '4': 1, '5': 5, '9': 0, '10': 'bin', '17': true},
  ],
  '4': const [RecordedEvent_EventType$json],
  '8': const [
    const {'1': '_bin'},
  ],
};

@$core.Deprecated('Use recordedEventDescriptor instead')
const RecordedEvent_EventType$json = const {
  '1': 'EventType',
  '2': const [
    const {'1': 'OPENED', '2': 0},
    const {'1': 'CLOSED', '2': 1},
    const {'1': 'MISSED', '2': 2},
  ],
};

/// Descriptor for `RecordedEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordedEventDescriptor = $convert.base64Decode(
    'Cg1SZWNvcmRlZEV2ZW50EiwKBHR5cGUYASABKA4yGC5SZWNvcmRlZEV2ZW50LkV2ZW50VHlwZVIEdHlwZRIcCgl0aW1lc3RhbXAYAiABKANSCXRpbWVzdGFtcBIVCgNiaW4YAyABKAVIAFIDYmluiAEBIi8KCUV2ZW50VHlwZRIKCgZPUEVORUQQABIKCgZDTE9TRUQQARIKCgZNSVNTRUQQAkIGCgRfYmlu');
@$core.Deprecated('Use submitEventRequestDescriptor instead')
const SubmitEventRequest$json = const {
  '1': 'SubmitEventRequest',
  '2': const [
    const {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
    const {'1': 'state_hash', '3': 2, '4': 1, '5': 3, '10': 'stateHash'},
    const {
      '1': 'event',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.RecordedEvent',
      '10': 'event'
    },
  ],
};

/// Descriptor for `SubmitEventRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitEventRequestDescriptor = $convert.base64Decode(
    'ChJTdWJtaXRFdmVudFJlcXVlc3QSGwoJZGV2aWNlX2lkGAEgASgMUghkZXZpY2VJZBIdCgpzdGF0ZV9oYXNoGAIgASgDUglzdGF0ZUhhc2gSJAoFZXZlbnQYAyABKAsyDi5SZWNvcmRlZEV2ZW50UgVldmVudA==');
@$core.Deprecated('Use submitEventsRequestDescriptor instead')
const SubmitEventsRequest$json = const {
  '1': 'SubmitEventsRequest',
  '2': const [
    const {'1': 'state_hash', '3': 1, '4': 1, '5': 3, '10': 'stateHash'},
    const {
      '1': 'event',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.RecordedEvent',
      '8': const {},
      '10': 'event'
    },
  ],
};

/// Descriptor for `SubmitEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitEventsRequestDescriptor = $convert.base64Decode(
    'ChNTdWJtaXRFdmVudHNSZXF1ZXN0Eh0KCnN0YXRlX2hhc2gYASABKANSCXN0YXRlSGFzaBIrCgVldmVudBgCIAMoCzIOLlJlY29yZGVkRXZlbnRCBZI/AhAbUgVldmVudA==');
@$core.Deprecated('Use submitEventsResponseDescriptor instead')
const SubmitEventsResponse$json = const {
  '1': 'SubmitEventsResponse',
  '2': const [
    const {'1': 'result', '3': 1, '4': 1, '5': 5, '10': 'result'},
    const {'1': 'state_hash', '3': 2, '4': 1, '5': 3, '10': 'stateHash'},
  ],
};

/// Descriptor for `SubmitEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitEventsResponseDescriptor = $convert.base64Decode(
    'ChRTdWJtaXRFdmVudHNSZXNwb25zZRIWCgZyZXN1bHQYASABKAVSBnJlc3VsdBIdCgpzdGF0ZV9oYXNoGAIgASgDUglzdGF0ZUhhc2g=');
@$core.Deprecated('Use binScheduleDescriptor instead')
const BinSchedule$json = const {
  '1': 'BinSchedule',
  '2': const [
    const {
      '1': 'day_of_week',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.BinSchedule.DayOfWeek',
      '10': 'dayOfWeek'
    },
    const {
      '1': 'seconds_from_00',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'secondsFrom00'
    },
  ],
  '4': const [BinSchedule_DayOfWeek$json],
};

@$core.Deprecated('Use binScheduleDescriptor instead')
const BinSchedule_DayOfWeek$json = const {
  '1': 'DayOfWeek',
  '2': const [
    const {'1': 'MONDAY', '2': 0},
    const {'1': 'TUESDAY', '2': 1},
    const {'1': 'WEDNESDAY', '2': 2},
    const {'1': 'THURSDAY', '2': 3},
    const {'1': 'FRIDAY', '2': 4},
    const {'1': 'SATURDAY', '2': 5},
    const {'1': 'SUNDAY', '2': 6},
    const {'1': 'DISABLED', '2': 1000},
  ],
};

/// Descriptor for `BinSchedule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List binScheduleDescriptor = $convert.base64Decode(
    'CgtCaW5TY2hlZHVsZRI2CgtkYXlfb2Zfd2VlaxgBIAEoDjIWLkJpblNjaGVkdWxlLkRheU9mV2Vla1IJZGF5T2ZXZWVrEiYKD3NlY29uZHNfZnJvbV8wMBgCIAEoDVINc2Vjb25kc0Zyb20wMCJ2CglEYXlPZldlZWsSCgoGTU9OREFZEAASCwoHVFVFU0RBWRABEg0KCVdFRE5FU0RBWRACEgwKCFRIVVJTREFZEAMSCgoGRlJJREFZEAQSDAoIU0FUVVJEQVkQBRIKCgZTVU5EQVkQBhINCghESVNBQkxFRBDoBw==');
@$core.Deprecated('Use scheduleResponseDescriptor instead')
const ScheduleResponse$json = const {
  '1': 'ScheduleResponse',
  '2': const [
    const {
      '1': 'schedule',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.BinSchedule',
      '8': const {},
      '10': 'schedule'
    },
  ],
};

/// Descriptor for `ScheduleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scheduleResponseDescriptor = $convert.base64Decode(
    'ChBTY2hlZHVsZVJlc3BvbnNlEjQKCHNjaGVkdWxlGAEgAygLMgwuQmluU2NoZWR1bGVCCpI/AhAOkj8CeAFSCHNjaGVkdWxl');
@$core.Deprecated('Use provisionRequestDescriptor instead')
const ProvisionRequest$json = const {
  '1': 'ProvisionRequest',
  '2': const [
    const {'1': 'device_id', '3': 1, '4': 1, '5': 12, '10': 'deviceId'},
    const {'1': 'bssid', '3': 2, '4': 1, '5': 12, '10': 'bssid'},
    const {'1': 'ssid', '3': 3, '4': 1, '5': 9, '10': 'ssid'},
  ],
};

/// Descriptor for `ProvisionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List provisionRequestDescriptor = $convert.base64Decode(
    'ChBQcm92aXNpb25SZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoDFIIZGV2aWNlSWQSFAoFYnNzaWQYAiABKAxSBWJzc2lkEhIKBHNzaWQYAyABKAlSBHNzaWQ=');
@$core.Deprecated('Use engineeringDataDescriptor instead')
const EngineeringData$json = const {
  '1': 'EngineeringData',
  '2': const [
    const {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    const {
      '1': 'voltages',
      '3': 2,
      '4': 3,
      '5': 5,
      '8': const {},
      '10': 'voltages'
    },
    const {
      '1': 'vbat_scaled',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'vbatScaled',
      '17': true
    },
    const {
      '1': 'vbat_meas',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 1,
      '10': 'vbatMeas',
      '17': true
    },
  ],
  '8': const [
    const {'1': '_vbat_scaled'},
    const {'1': '_vbat_meas'},
  ],
};

/// Descriptor for `EngineeringData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineeringDataDescriptor = $convert.base64Decode(
    'Cg9FbmdpbmVlcmluZ0RhdGESHAoJdGltZXN0YW1wGAEgASgDUgl0aW1lc3RhbXASJgoIdm9sdGFnZXMYAiADKAVCCpI/AhAQkj8CeAFSCHZvbHRhZ2VzEiQKC3ZiYXRfc2NhbGVkGAMgASgCSABSCnZiYXRTY2FsZWSIAQESIAoJdmJhdF9tZWFzGAQgASgCSAFSCHZiYXRNZWFziAEBQg4KDF92YmF0X3NjYWxlZEIMCgpfdmJhdF9tZWFz');
@$core.Deprecated('Use engineeringRequestDescriptor instead')
const EngineeringRequest$json = const {
  '1': 'EngineeringRequest',
  '2': const [
    const {
      '1': 'hold_mux_channel',
      '3': 1,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'holdMuxChannel',
      '17': true
    },
  ],
  '8': const [
    const {'1': '_hold_mux_channel'},
  ],
};

/// Descriptor for `EngineeringRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineeringRequestDescriptor = $convert.base64Decode(
    'ChJFbmdpbmVlcmluZ1JlcXVlc3QSLQoQaG9sZF9tdXhfY2hhbm5lbBgBIAEoBUgAUg5ob2xkTXV4Q2hhbm5lbIgBAUITChFfaG9sZF9tdXhfY2hhbm5lbA==');
@$core.Deprecated('Use syncRequestDescriptor instead')
const SyncRequest$json = const {
  '1': 'SyncRequest',
  '2': const [
    const {'1': 'state_hash', '3': 1, '4': 1, '5': 3, '10': 'stateHash'},
    const {'1': 'event_ctr', '3': 2, '4': 1, '5': 3, '10': 'eventCtr'},
    const {
      '1': 'events',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.RecordedEvent',
      '10': 'events'
    },
    const {
      '1': 'bin_state',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.AllBinsState',
      '8': const {},
      '9': 0,
      '10': 'binState',
      '17': true
    },
    const {
      '1': 'engr_data',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.EngineeringData',
      '9': 1,
      '10': 'engrData',
      '17': true
    },
    const {
      '1': 'ipv4',
      '3': 6,
      '4': 1,
      '5': 7,
      '9': 2,
      '10': 'ipv4',
      '17': true
    },
    const {
      '1': 'ipv6',
      '3': 7,
      '4': 1,
      '5': 12,
      '8': const {},
      '9': 3,
      '10': 'ipv6',
      '17': true
    },
  ],
  '8': const [
    const {'1': '_bin_state'},
    const {'1': '_engr_data'},
    const {'1': '_ipv4'},
    const {'1': '_ipv6'},
  ],
};

/// Descriptor for `SyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncRequestDescriptor = $convert.base64Decode(
    'CgtTeW5jUmVxdWVzdBIdCgpzdGF0ZV9oYXNoGAEgASgDUglzdGF0ZUhhc2gSGwoJZXZlbnRfY3RyGAIgASgDUghldmVudEN0chImCgZldmVudHMYAyADKAsyDi5SZWNvcmRlZEV2ZW50UgZldmVudHMSNgoJYmluX3N0YXRlGAQgASgLMg0uQWxsQmluc1N0YXRlQgWSPwIQHEgAUghiaW5TdGF0ZYgBARIyCgllbmdyX2RhdGEYBSABKAsyEC5FbmdpbmVlcmluZ0RhdGFIAVIIZW5nckRhdGGIAQESFwoEaXB2NBgGIAEoB0gCUgRpcHY0iAEBEiMKBGlwdjYYByABKAxCCpI/AggQkj8CeAFIA1IEaXB2NogBAUIMCgpfYmluX3N0YXRlQgwKCl9lbmdyX2RhdGFCBwoFX2lwdjRCBwoFX2lwdjY=');
@$core.Deprecated('Use syncResponseDescriptor instead')
const SyncResponse$json = const {
  '1': 'SyncResponse',
  '2': const [
    const {
      '1': 'persisted_events',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'persistedEvents'
    },
    const {
      '1': 'bin_state',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.AllBinsState',
      '9': 0,
      '10': 'binState',
      '17': true
    },
    const {
      '1': 'schedule',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.BinSchedule',
      '8': const {},
      '10': 'schedule'
    },
    const {'1': 'engr_mode', '3': 4, '4': 1, '5': 8, '10': 'engrMode'},
    const {
      '1': 'engr_req',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EngineeringRequest',
      '9': 1,
      '10': 'engrReq',
      '17': true
    },
    const {
      '1': 'latest_firmware',
      '3': 7,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'latestFirmware',
      '17': true
    },
  ],
  '8': const [
    const {'1': '_bin_state'},
    const {'1': '_engr_req'},
    const {'1': '_latest_firmware'},
  ],
};

/// Descriptor for `SyncResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncResponseDescriptor = $convert.base64Decode(
    'CgxTeW5jUmVzcG9uc2USKQoQcGVyc2lzdGVkX2V2ZW50cxgBIAEoBVIPcGVyc2lzdGVkRXZlbnRzEi8KCWJpbl9zdGF0ZRgCIAEoCzINLkFsbEJpbnNTdGF0ZUgAUghiaW5TdGF0ZYgBARI0CghzY2hlZHVsZRgDIAMoCzIMLkJpblNjaGVkdWxlQgqSPwIQDpI/AngBUghzY2hlZHVsZRIbCgllbmdyX21vZGUYBCABKAhSCGVuZ3JNb2RlEjMKCGVuZ3JfcmVxGAYgASgLMhMuRW5naW5lZXJpbmdSZXF1ZXN0SAFSB2VuZ3JSZXGIAQESLAoPbGF0ZXN0X2Zpcm13YXJlGAcgASgFSAJSDmxhdGVzdEZpcm13YXJliAEBQgwKCl9iaW5fc3RhdGVCCwoJX2VuZ3JfcmVxQhIKEF9sYXRlc3RfZmlybXdhcmU=');
@$core.Deprecated('Use authorizeRequestDescriptor instead')
const AuthorizeRequest$json = const {
  '1': 'AuthorizeRequest',
  '2': const [
    const {'1': 'serial_no', '3': 1, '4': 1, '5': 3, '10': 'serialNo'},
    const {'1': 'oob_key', '3': 2, '4': 1, '5': 12, '10': 'oobKey'},
  ],
};

/// Descriptor for `AuthorizeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorizeRequestDescriptor = $convert.base64Decode(
    'ChBBdXRob3JpemVSZXF1ZXN0EhsKCXNlcmlhbF9ubxgBIAEoA1IIc2VyaWFsTm8SFwoHb29iX2tleRgCIAEoDFIGb29iS2V5');
@$core.Deprecated('Use authorizeResponseDescriptor instead')
const AuthorizeResponse$json = const {
  '1': 'AuthorizeResponse',
  '2': const [
    const {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
    const {'1': 'refresh_token', '3': 2, '4': 1, '5': 9, '10': 'refreshToken'},
    const {'1': 'token_type', '3': 3, '4': 1, '5': 9, '10': 'tokenType'},
    const {'1': 'expires_in', '3': 4, '4': 1, '5': 3, '10': 'expiresIn'},
  ],
};

/// Descriptor for `AuthorizeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorizeResponseDescriptor = $convert.base64Decode(
    'ChFBdXRob3JpemVSZXNwb25zZRIhCgxhY2Nlc3NfdG9rZW4YASABKAlSC2FjY2Vzc1Rva2VuEiMKDXJlZnJlc2hfdG9rZW4YAiABKAlSDHJlZnJlc2hUb2tlbhIdCgp0b2tlbl90eXBlGAMgASgJUgl0b2tlblR5cGUSHQoKZXhwaXJlc19pbhgEIAEoA1IJZXhwaXJlc0lu');
@$core.Deprecated('Use deviceProvisionRequestDescriptor instead')
const DeviceProvisionRequest$json = const {
  '1': 'DeviceProvisionRequest',
  '2': const [
    const {'1': 'bssid', '3': 1, '4': 1, '5': 12, '10': 'bssid'},
    const {'1': 'ssid', '3': 2, '4': 1, '5': 9, '10': 'ssid'},
  ],
};

/// Descriptor for `DeviceProvisionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceProvisionRequestDescriptor =
    $convert.base64Decode(
        'ChZEZXZpY2VQcm92aXNpb25SZXF1ZXN0EhQKBWJzc2lkGAEgASgMUgVic3NpZBISCgRzc2lkGAIgASgJUgRzc2lk');
@$core.Deprecated('Use engineeringBinStateDescriptor instead')
const EngineeringBinState$json = const {
  '1': 'EngineeringBinState',
  '2': const [
    const {'1': 'voltage', '3': 1, '4': 1, '5': 5, '10': 'voltage'},
    const {'1': 'open', '3': 2, '4': 1, '5': 8, '10': 'open'},
    const {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.BinStatus',
      '10': 'status'
    },
    const {
      '1': 'scheduled_time',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'scheduledTime'
    },
  ],
};

/// Descriptor for `EngineeringBinState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineeringBinStateDescriptor = $convert.base64Decode(
    'ChNFbmdpbmVlcmluZ0JpblN0YXRlEhgKB3ZvbHRhZ2UYASABKAVSB3ZvbHRhZ2USEgoEb3BlbhgCIAEoCFIEb3BlbhIiCgZzdGF0dXMYAyABKA4yCi5CaW5TdGF0dXNSBnN0YXR1cxIlCg5zY2hlZHVsZWRfdGltZRgEIAEoA1INc2NoZWR1bGVkVGltZQ==');
@$core.Deprecated('Use engineeringAllBinsDescriptor instead')
const EngineeringAllBins$json = const {
  '1': 'EngineeringAllBins',
  '2': const [
    const {
      '1': 'bins',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.EngineeringBinState',
      '8': const {},
      '10': 'bins'
    },
  ],
};

/// Descriptor for `EngineeringAllBins`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineeringAllBinsDescriptor = $convert.base64Decode(
    'ChJFbmdpbmVlcmluZ0FsbEJpbnMSNAoEYmlucxgBIAMoCzIULkVuZ2luZWVyaW5nQmluU3RhdGVCCpI/AhAOkj8CeAFSBGJpbnM=');
