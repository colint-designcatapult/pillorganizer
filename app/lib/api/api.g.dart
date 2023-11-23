// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemJsonViolation _$ProblemJsonViolationFromJson(
        Map<String, dynamic> json) =>
    ProblemJsonViolation(
      field: json['field'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ProblemJsonViolationToJson(
        ProblemJsonViolation instance) =>
    <String, dynamic>{
      'field': instance.field,
      'message': instance.message,
    };

ProblemJson _$ProblemJsonFromJson(Map<String, dynamic> json) => ProblemJson(
      type: json['type'] as String?,
      title: json['title'] as String?,
      detail: json['detail'] as String?,
      cause: json['cause'] == null
          ? null
          : ProblemJson.fromJson(json['cause'] as Map<String, dynamic>),
      violations: (json['violations'] as List<dynamic>?)
          ?.map((e) => ProblemJsonViolation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProblemJsonToJson(ProblemJson instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'detail': instance.detail,
      'cause': instance.cause,
      'violations': instance.violations,
    };

UserDTO _$UserDTOFromJson(Map<String, dynamic> json) => UserDTO(
      id: json['id'] as int,
      email: json['email'] as String,
    );

Map<String, dynamic> _$UserDTOToJson(UserDTO instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
    };

UserRegistrationDTO _$UserRegistrationDTOFromJson(Map<String, dynamic> json) =>
    UserRegistrationDTO(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$UserRegistrationDTOToJson(
        UserRegistrationDTO instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

Map<String, dynamic> _$UserChangePasswordDTOToJson(
        UserChangePasswordDTO instance) =>
    <String, dynamic>{
      'currentPassword': instance.currentPassword,
      'newPassword': instance.newPassword,
    };

ProvisionStart _$ProvisionStartFromJson(Map<String, dynamic> json) =>
    ProvisionStart(
      serialNo: json['serialNo'] as String,
      deviceClass: json['deviceClass'] as String,
    );

Map<String, dynamic> _$ProvisionStartToJson(ProvisionStart instance) =>
    <String, dynamic>{
      'serialNo': instance.serialNo,
      'deviceClass': instance.deviceClass,
    };

DeviceProvision _$DeviceProvisionFromJson(Map<String, dynamic> json) =>
    DeviceProvision(
      id: json['id'] as int,
      oobKey: json['oobKey'] as String,
    );

Map<String, dynamic> _$DeviceProvisionToJson(DeviceProvision instance) =>
    <String, dynamic>{
      'id': instance.id,
      'oobKey': instance.oobKey,
    };

VerifyProvision _$VerifyProvisionFromJson(Map<String, dynamic> json) =>
    VerifyProvision(
      serialNo: json['serialNo'] as String,
      ssid: json['ssid'] as String,
    );

Map<String, dynamic> _$VerifyProvisionToJson(VerifyProvision instance) =>
    <String, dynamic>{
      'serialNo': instance.serialNo,
      'ssid': instance.ssid,
    };

UserInfoDTO _$UserInfoDTOFromJson(Map<String, dynamic> json) => UserInfoDTO(
      id: json['id'] as int,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$UserInfoDTOToJson(UserInfoDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
    };

ProvisionStatus _$ProvisionStatusFromJson(Map<String, dynamic> json) =>
    ProvisionStatus(
      deviceID: json['deviceID'] as int,
      provisioned: json['provisioned'] as bool,
    );

Map<String, dynamic> _$ProvisionStatusToJson(ProvisionStatus instance) =>
    <String, dynamic>{
      'deviceID': instance.deviceID,
      'provisioned': instance.provisioned,
    };

DeviceBinID _$DeviceBinIDFromJson(Map<String, dynamic> json) => DeviceBinID(
      deviceID: json['deviceID'] as int,
      binID: json['binID'] as int,
    );

Map<String, dynamic> _$DeviceBinIDToJson(DeviceBinID instance) =>
    <String, dynamic>{
      'deviceID': instance.deviceID,
      'binID': instance.binID,
    };

BinEventDTO _$BinEventDTOFromJson(Map<String, dynamic> json) => BinEventDTO(
      id: json['id'] as int,
      ts: json['ts'] as int,
      eventType: json['eventType'] as String,
      bin: json['bin'] as int,
    );

Map<String, dynamic> _$BinEventDTOToJson(BinEventDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ts': instance.ts,
      'eventType': instance.eventType,
      'bin': instance.bin,
    };

BinStateDTO _$BinStateDTOFromJson(Map<String, dynamic> json) => BinStateDTO(
      id: DeviceBinID.fromJson(json['id'] as Map<String, dynamic>),
      binStatus: json['binStatus'] as String,
      scheduledTime: json['scheduledTime'] as int,
      event: json['event'] == null
          ? null
          : BinEventDTO.fromJson(json['event'] as Map<String, dynamic>),
      schedule: json['schedule'] == null
          ? null
          : ScheduleDTO.fromJson(json['schedule'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BinStateDTOToJson(BinStateDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'binStatus': instance.binStatus,
      'scheduledTime': instance.scheduledTime,
      'event': instance.event,
      'schedule': instance.schedule,
    };

DeviceUserDTO _$DeviceUserDTOFromJson(Map<String, dynamic> json) =>
    DeviceUserDTO(
      id: json['id'] as int,
      deviceID: json['deviceID'] as int,
      deviceClass: json['deviceClass'] as String,
      customName: json['customName'] as String?,
      serialNo: json['serialNo'] as int,
      lastSync: json['lastSync'] as int?,
      primaryUser: json['primaryUser'] as bool,
      owner: json['owner'] as bool,
      notifications: json['notifications'] as bool,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$DeviceUserDTOToJson(DeviceUserDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceID': instance.deviceID,
      'deviceClass': instance.deviceClass,
      'customName': instance.customName,
      'serialNo': instance.serialNo,
      'lastSync': instance.lastSync,
      'primaryUser': instance.primaryUser,
      'owner': instance.owner,
      'notifications': instance.notifications,
      'timezone': instance.timezone,
    };

DeviceDTO _$DeviceDTOFromJson(Map<String, dynamic> json) => DeviceDTO(
      id: json['id'] as int,
      deviceClass: json['deviceClass'] as String,
      serialNo: json['serialNo'] as String,
      customName: json['customName'] as String?,
      lastSync: json['lastSync'] as int?,
    );

Map<String, dynamic> _$DeviceDTOToJson(DeviceDTO instance) => <String, dynamic>{
      'id': instance.id,
      'deviceClass': instance.deviceClass,
      'serialNo': instance.serialNo,
      'customName': instance.customName,
      'lastSync': instance.lastSync,
    };

AnonymousCredentialsDTO _$AnonymousCredentialsDTOFromJson(
        Map<String, dynamic> json) =>
    AnonymousCredentialsDTO(
      id: json['id'] as int,
      secret: json['secret'] as String,
    );

Map<String, dynamic> _$AnonymousCredentialsDTOToJson(
        AnonymousCredentialsDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'secret': instance.secret,
    };

JwtCredentials _$JwtCredentialsFromJson(Map<String, dynamic> json) =>
    JwtCredentials(
      username: json['username'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
      access_token: json['access_token'] as String?,
      token_type: json['token_type'] as String?,
      expires_in: json['expires_in'] as int?,
    );

Map<String, dynamic> _$JwtCredentialsToJson(JwtCredentials instance) =>
    <String, dynamic>{
      'username': instance.username,
      'roles': instance.roles,
      'access_token': instance.access_token,
      'token_type': instance.token_type,
      'expires_in': instance.expires_in,
    };

ScheduleDTO _$ScheduleDTOFromJson(Map<String, dynamic> json) => ScheduleDTO(
      binID: json['binID'] as int,
      dayOfWeek: json['dayOfWeek'] as String,
      secondsFrom00: json['secondsFrom00'] as int,
    );

Map<String, dynamic> _$ScheduleDTOToJson(ScheduleDTO instance) =>
    <String, dynamic>{
      'binID': instance.binID,
      'dayOfWeek': instance.dayOfWeek,
      'secondsFrom00': instance.secondsFrom00,
    };

EngineeringDataDTO _$EngineeringDataDTOFromJson(Map<String, dynamic> json) =>
    EngineeringDataDTO(
      vbatMeas: (json['vbatMeas'] as num).toDouble(),
      vbatScaled: (json['vbatScaled'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      voltages:
          (json['voltages'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$EngineeringDataDTOToJson(EngineeringDataDTO instance) =>
    <String, dynamic>{
      'vbatMeas': instance.vbatMeas,
      'vbatScaled': instance.vbatScaled,
      'timestamp': instance.timestamp,
      'voltages': instance.voltages,
    };

EngineeringReqDTO _$EngineeringReqDTOFromJson(Map<String, dynamic> json) =>
    EngineeringReqDTO(
      holdMuxChannel: json['holdMuxChannel'] as int?,
    );

Map<String, dynamic> _$EngineeringReqDTOToJson(EngineeringReqDTO instance) =>
    <String, dynamic>{
      'holdMuxChannel': instance.holdMuxChannel,
    };

DeviceEngineeringData _$DeviceEngineeringDataFromJson(
        Map<String, dynamic> json) =>
    DeviceEngineeringData(
      engrMode: json['engrMode'] as bool,
      engrReq: json['engrReq'] as String?,
      engrData: json['engrData'] as String?,
    );

Map<String, dynamic> _$DeviceEngineeringDataToJson(
        DeviceEngineeringData instance) =>
    <String, dynamic>{
      'engrMode': instance.engrMode,
      'engrReq': instance.engrReq,
      'engrData': instance.engrData,
    };

EventDTO _$EventDTOFromJson(Map<String, dynamic> json) => EventDTO(
      id: json['id'] as int,
      ts: json['ts'] as int,
      eventType: json['eventType'] as String,
      bin: json['bin'] as int,
    );

Map<String, dynamic> _$EventDTOToJson(EventDTO instance) => <String, dynamic>{
      'id': instance.id,
      'ts': instance.ts,
      'eventType': instance.eventType,
      'bin': instance.bin,
    };

DeviceUserSettings _$DeviceUserSettingsFromJson(Map<String, dynamic> json) =>
    DeviceUserSettings(
      notifications: json['notifications'] as bool,
    );

Map<String, dynamic> _$DeviceUserSettingsToJson(DeviceUserSettings instance) =>
    <String, dynamic>{
      'notifications': instance.notifications,
    };

NotificationTokenDTO _$NotificationTokenDTOFromJson(
        Map<String, dynamic> json) =>
    NotificationTokenDTO(
      notificationToken: json['notificationToken'] as String?,
    );

Map<String, dynamic> _$NotificationTokenDTOToJson(
        NotificationTokenDTO instance) =>
    <String, dynamic>{
      'notificationToken': instance.notificationToken,
    };

MedicationDispenseTimeDTO _$MedicationDispenseTimeDTOFromJson(
        Map<String, dynamic> json) =>
    MedicationDispenseTimeDTO(
      id: json['id'] as int?,
      medicationID: json['medicationID'] as int?,
      dispenseID: json['dispenseID'] as int?,
      quantity: json['quantity'] as int?,
      dispense: json['dispense'] == null
          ? null
          : SimpleDispenseTimeDTO.fromJson(
              json['dispense'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MedicationDispenseTimeDTOToJson(
        MedicationDispenseTimeDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'medicationID': instance.medicationID,
      'dispenseID': instance.dispenseID,
      'quantity': instance.quantity,
      'dispense': instance.dispense,
    };

SimpleDispenseTimeDTO _$SimpleDispenseTimeDTOFromJson(
        Map<String, dynamic> json) =>
    SimpleDispenseTimeDTO(
      id: json['id'] as int?,
      period: json['period'] as String?,
      time: json['time'] as int?,
    );

Map<String, dynamic> _$SimpleDispenseTimeDTOToJson(
        SimpleDispenseTimeDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'period': instance.period,
      'time': instance.time,
    };

ScheduledMedicationDTO _$ScheduledMedicationDTOFromJson(
        Map<String, dynamic> json) =>
    ScheduledMedicationDTO(
      id: json['id'] as int?,
      med_name: json['med_name'] as String,
      shape: json['shape'] as String?,
      color: json['color'] as int?,
      dispenseTimes: (json['dispenseTimes'] as List<dynamic>?)
          ?.map((e) =>
              MedicationDispenseTimeDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScheduledMedicationDTOToJson(
        ScheduledMedicationDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'med_name': instance.med_name,
      'shape': instance.shape,
      'color': instance.color,
      'dispenseTimes': instance.dispenseTimes,
    };

UpdateDeviceUserSettings _$UpdateDeviceUserSettingsFromJson(
        Map<String, dynamic> json) =>
    UpdateDeviceUserSettings(
      deviceName: json['deviceName'] as String?,
      notificationToken: json['notificationToken'] as String?,
      notifications: json['notifications'] as bool?,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$UpdateDeviceUserSettingsToJson(
        UpdateDeviceUserSettings instance) =>
    <String, dynamic>{
      'deviceName': instance.deviceName,
      'notificationToken': instance.notificationToken,
      'notifications': instance.notifications,
      'timezone': instance.timezone,
    };

SimpleScheduleDTO _$SimpleScheduleDTOFromJson(Map<String, dynamic> json) =>
    SimpleScheduleDTO(
      amID: json['amID'] as int?,
      amSecondsFrom00: json['amSecondsFrom00'] as int?,
      pmID: json['pmID'] as int?,
      pmSecondsFrom00: json['pmSecondsFrom00'] as int?,
    );

Map<String, dynamic> _$SimpleScheduleDTOToJson(SimpleScheduleDTO instance) =>
    <String, dynamic>{
      'amID': instance.amID,
      'amSecondsFrom00': instance.amSecondsFrom00,
      'pmID': instance.pmID,
      'pmSecondsFrom00': instance.pmSecondsFrom00,
    };

SaveMedicationDTO _$SaveMedicationDTOFromJson(Map<String, dynamic> json) =>
    SaveMedicationDTO(
      id: json['id'] as int?,
      name: json['name'] as String?,
      shape: json['shape'] as String?,
      color: json['color'] as int?,
      dispenseTimes: (json['dispenseTimes'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toSet(),
    );

Map<String, dynamic> _$SaveMedicationDTOToJson(SaveMedicationDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'shape': instance.shape,
      'color': instance.color,
      'dispenseTimes': instance.dispenseTimes?.toList(),
    };

DosePeriodDTO _$DosePeriodDTOFromJson(Map<String, dynamic> json) =>
    DosePeriodDTO(
      binID: json['binID'] as int,
      timestamp: json['timestamp'] as int?,
      status: json['status'] as int,
      medications: (json['medications'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );

Map<String, dynamic> _$DosePeriodDTOToJson(DosePeriodDTO instance) =>
    <String, dynamic>{
      'binID': instance.binID,
      'timestamp': instance.timestamp,
      'status': instance.status,
      'medications': instance.medications,
    };

DeviceStateDTO _$DeviceStateDTOFromJson(Map<String, dynamic> json) =>
    DeviceStateDTO(
      id: json['id'] as int,
      lastSync: json['lastSync'] as int?,
      bins: json['bins'] as int?,
      dosePeriods: (json['dosePeriods'] as List<dynamic>?)
          ?.map((e) => DosePeriodDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      battery: json['battery'] as int?,
      charging: json['charging'] as bool?,
    );

Map<String, dynamic> _$DeviceStateDTOToJson(DeviceStateDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lastSync': instance.lastSync,
      'bins': instance.bins,
      'dosePeriods': instance.dosePeriods,
      'battery': instance.battery,
      'charging': instance.charging,
    };

_$_EmailPasswordCredentialsDTO _$$_EmailPasswordCredentialsDTOFromJson(
        Map<String, dynamic> json) =>
    _$_EmailPasswordCredentialsDTO(
      username: json['username'] as String?,
      password: json['password'] as String?,
    );

Map<String, dynamic> _$$_EmailPasswordCredentialsDTOToJson(
        _$_EmailPasswordCredentialsDTO instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _RestClient implements RestClient {
  _RestClient(
    this._dio, {
    this.baseUrl,
  });

  final Dio _dio;

  String? baseUrl;

  @override
  Future<DeviceProvision> provisionStart(ProvisionStart ps) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(ps.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<DeviceProvision>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/provision/start',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = DeviceProvision.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ProvisionStatus> provisionStatus(
    int id,
    VerifyProvision status,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(status.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ProvisionStatus>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/provision/${id}/verify',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = ProvisionStatus.fromJson(_result.data!);
    return value;
  }

  @override
  Future<void> reload(int id) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/device/${id}/reload',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
  }

  @override
  Future<AnonymousCredentialsDTO> registerAnonymous() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<AnonymousCredentialsDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/user/register_anonymous',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = AnonymousCredentialsDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<JwtCredentials> loginAnonymous(AnonymousCredentialsDTO creds) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(creds.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<JwtCredentials>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/auth/login_anonymous',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = JwtCredentials.fromJson(_result.data!);
    return value;
  }

  @override
  Future<JwtCredentials> login(EmailPasswordCredentialsDTO creds) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = creds;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<JwtCredentials>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/auth/login',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = JwtCredentials.fromJson(_result.data!);
    return value;
  }

  @override
  Future<UserInfoDTO> authStatus() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<UserInfoDTO>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/user/me',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = UserInfoDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<UserDTO> upgradeAnonymous(UserRegistrationDTO reg) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(reg.toJson());
    final _result =
        await _dio.fetch<Map<String, dynamic>>(_setStreamType<UserDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/user/anonymous_upgrade',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = UserDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<UserDTO> register(UserRegistrationDTO reg) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(reg.toJson());
    final _result =
        await _dio.fetch<Map<String, dynamic>>(_setStreamType<UserDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/user/register',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = UserDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<void> changePassword(UserChangePasswordDTO reg) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(reg.toJson());

    await _dio.fetch<Map<String, dynamic>>(_setStreamType<UserDTO>(Options(
      method: 'PUT',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/user/change_password',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
  }

  @override
  Future<DeviceUserSettings> userSettings(int deviceID) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<DeviceUserSettings>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/user_settings',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = DeviceUserSettings.fromJson(_result.data!);
    return value;
  }

  @override
  Future<void> notificationToken(
    int deviceID,
    NotificationTokenDTO dto,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(dto.toJson());
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'PUT',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/device/${deviceID}/notification_token',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
  }

  @override
  Future<List<DeviceUserDTO>> listMyDevices() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<List<dynamic>>(_setStreamType<List<DeviceUserDTO>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/list',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) => DeviceUserDTO.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<List<ScheduledMedicationDTO>> medications(int deviceID) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<ScheduledMedicationDTO>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/medication',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) =>
            ScheduledMedicationDTO.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  @override
  Future<ScheduledMedicationDTO> addMedication(
    int deviceID,
    ScheduledMedicationDTO dto,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(dto.toJson());
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ScheduledMedicationDTO>(Options(
      method: 'PUT',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/medication',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = ScheduledMedicationDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<ScheduledMedicationDTO> saveMedication(
    int deviceID,
    SaveMedicationDTO dto,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(dto.toJson());
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ScheduledMedicationDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/medication',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = ScheduledMedicationDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<void> deleteMedication(
    int deviceID,
    int medID,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'DELETE',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/device/${deviceID}/medication/${medID}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
  }

  @override
  Future<void> removeDevice(int deviceID) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'DELETE',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/device/${deviceID}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
  }

  @override
  Future<ScheduledMedicationDTO> medication(
    int deviceID,
    int medID,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<ScheduledMedicationDTO>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/medication/${medID}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = ScheduledMedicationDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<DeviceUserDTO> setDeviceSettings(
    int deviceID,
    UpdateDeviceUserSettings settings,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(settings.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<DeviceUserDTO>(Options(
      method: 'PUT',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = DeviceUserDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SimpleScheduleDTO> getDispenseTimes(int deviceID) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SimpleScheduleDTO>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/dispense_time',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = SimpleScheduleDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<SimpleScheduleDTO> updateDispenseTimes(
    int deviceID,
    SimpleScheduleDTO dto,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(dto.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<SimpleScheduleDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/dispense_time',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = SimpleScheduleDTO.fromJson(_result.data!);
    return value;
  }

  @override
  Future<String> deviceSync(
    int deviceID,
    String data,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = data;
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/device/${deviceID}/sync',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data!;
    return value;
  }

  @override
  Future<DeviceStateDTO> stateDate(
    int deviceID,
    String date,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {'date': date};
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<DeviceStateDTO>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
            .compose(
              _dio.options,
              '/device/${deviceID}/state',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = DeviceStateDTO.fromJson(_result.data!);
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
