import 'dart:async';
import 'dart:convert';

import 'package:app/api/intreceptors/auth-interceptors.dart';
import 'package:app/service/time_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'api.freezed.dart';
part 'api.g.dart';

class AppApi {
  static String base() {
    return dotenv.env['API_URL'] ?? 'https://jctbackend.herokuapp.com/api/v1';
  }

  static String deviceClass() {
    return "v1_7x2";
  }

  static Future<int?> deviceID() async {
    return (await SharedPreferences.getInstance()).getInt("device_id");
  }

  static Future<String?> deviceSerial() async {
    return (await SharedPreferences.getInstance()).getString("device_sn");
  }
}

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST("/device/provision/start")
  Future<DeviceProvision> provisionStart(@Body() ProvisionStart ps);

  @POST("/device/provision/{id}/verify")
  Future<ProvisionStatus> provisionStatus(
      @Path("id") int id, @Body() VerifyProvision status);

  @POST("/device/{id}/reload")
  Future<void> reload(@Path("id") int id);

  @POST("/user/register_anonymous")
  Future<AnonymousCredentialsDTO> registerAnonymous();

  @POST("/auth/login_anonymous")
  Future<JwtCredentials> loginAnonymous(@Body() AnonymousCredentialsDTO creds);

  @POST("/auth/login")
  Future<JwtCredentials> login(@Body() EmailPasswordCredentialsDTO creds);

  @GET("/user/me")
  Future<UserInfoDTO> authStatus();

  @POST("/user/anonymous_upgrade")
  Future<UserDTO> upgradeAnonymous(@Body() UserRegistrationDTO reg);

  @POST("/user/register")
  Future<UserDTO> register(@Body() UserRegistrationDTO reg);

  @PUT("user/change_password")
  Future<void> changePassword(@Body() UserChangePasswordDTO reg);

  @GET("/device/list")
  Future<List<DeviceUserDTO>> listMyDevices();

  @GET("/device/{id}/medication")
  Future<List<ScheduledMedicationDTO>> medications(@Path("id") int deviceID);

  @PUT("/device/{id}/medication")
  Future<ScheduledMedicationDTO> addMedication(
      @Path("id") int deviceID, @Body() ScheduledMedicationDTO dto);

  @POST("/device/{id}/medication")
  Future<ScheduledMedicationDTO> saveMedication(
      @Path("id") int deviceID, @Body() SaveMedicationDTO dto);

  @DELETE("/device/{id}/medication/{med_id}")
  Future<void> deleteMedication(
      @Path("id") int deviceID, @Path("med_id") int medID);

  @DELETE("/device/{id}")
  Future<void> removeDevice(@Path("id") int deviceID);

  @GET("/device/{id}/medication/{med_id}")
  Future<ScheduledMedicationDTO> medication(
      @Path("id") int deviceID, @Path("med_id") int medID);

  @PUT("/device/{id}")
  Future<DeviceUserDTO> setDeviceSettings(
      @Path("id") int deviceID, @Body() UpdateDeviceUserSettings settings);

  @GET("/device/{id}/dispense_time")
  Future<SimpleScheduleDTO> getDispenseTimes(@Path("id") int deviceID);

  @POST("/device/{id}/dispense_time")
  Future<SimpleScheduleDTO> updateDispenseTimes(
      @Path("id") int deviceID, @Body() SimpleScheduleDTO dto);

  @POST("/device/{id}/sync")
  Future<String> deviceSync(@Path("id") int deviceID, @Body() String data);

  @POST("/device/{id}/state")
  @FormUrlEncoded()
  Future<DeviceStateDTO> stateDate(
      @Path("id") int deviceID, @Field() String date);
}

@JsonSerializable()
class ProblemJsonViolation {
  final String? field;
  final String? message;

  ProblemJsonViolation({this.field, this.message});
  factory ProblemJsonViolation.fromJson(Map<String, dynamic> json) =>
      _$ProblemJsonViolationFromJson(json);

  @override
  String toString() {
    var split = field?.split(".");
    String? last = split?.last;
    return '$last $message';
  }
}

@JsonSerializable()
class ProblemJson {
  final String? type;
  final String? title;
  final String? detail;
  final ProblemJson? cause;
  final List<ProblemJsonViolation>? violations;

  ProblemJson(
      {this.type, this.title, this.detail, this.cause, this.violations});
  factory ProblemJson.fromJson(Map<String, dynamic> json) =>
      _$ProblemJsonFromJson(json);

  @override
  String toString() {
    if (violations != null && violations!.isNotEmpty) {
      var str = violations!.map((e) => '  \u2022 $e\n').join();
      return 'Please correct the following errors:\n$str';
    } else {
      return title ?? (detail ?? 'Unspecified error');
    }
  }
}

class ProblemJsonException extends DioError {
  ProblemJsonException({required super.requestOptions, required this.problem});

  final ProblemJson problem;
}

class ProblemJsonInterceptor extends Interceptor {
  DioError? tryHandleResponse(Response response) {
    if (response.headers['content-type']?.first == 'application/problem+json') {
      final problem = ProblemJson.fromJson(json.decode(response.data));
      return ProblemJsonException(
          requestOptions: response.requestOptions, problem: problem);
    } else {
      return null;
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (tryHandleResponse(response) == null) {
      super.onResponse(response, handler);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    FlutterTimezone.getLocalTimezone().then((value) {
      options.headers["X-Local-TZ"] = value;
      handler.next(options);
    });
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioErrorType.connectionTimeout:
      case DioErrorType.receiveTimeout:
      case DioErrorType.sendTimeout:
        throw TimeoutException(err.message);
      default:
        super.onError(err, handler);
    }
  }
}

Dio addProblemJsonInterceptorToDio(Dio dio) {
  return dio..interceptors.add(ProblemJsonInterceptor());
}

final client = RestClient(
    addProblemJsonInterceptorToDio(addAuthInterceptorsToDio(Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        contentType: 'application/json')))),
    baseUrl: AppApi.base());

@JsonSerializable()
class UserDTO {
  final int id;
  final String email;

  UserDTO({required this.id, required this.email});
  factory UserDTO.fromJson(Map<String, dynamic> json) =>
      _$UserDTOFromJson(json);
}

@JsonSerializable()
class UserRegistrationDTO {
  final String email;
  final String password;

  UserRegistrationDTO({required this.email, required this.password});
  Map<String, dynamic> toJson() => _$UserRegistrationDTOToJson(this);
}

@JsonSerializable()
class UserChangePasswordDTO {
  final String currentPassword;
  final String newPassword;

  UserChangePasswordDTO(
      {required this.currentPassword, required this.newPassword});
  Map<String, dynamic> toJson() => _$UserChangePasswordDTOToJson(this);
}

@JsonSerializable()
class ProvisionStart {
  final String serialNo;
  final String deviceClass;

  ProvisionStart({required this.serialNo, required this.deviceClass});
  Map<String, dynamic> toJson() => _$ProvisionStartToJson(this);
}

@JsonSerializable()
class DeviceProvision {
  final int id;
  final String oobKey;

  DeviceProvision({required this.id, required this.oobKey});
  factory DeviceProvision.fromJson(Map<String, dynamic> json) =>
      _$DeviceProvisionFromJson(json);
}

@JsonSerializable()
class VerifyProvision {
  final String serialNo;
  final String ssid;

  VerifyProvision({required this.serialNo, required this.ssid});
  Map<String, dynamic> toJson() => _$VerifyProvisionToJson(this);
}

@JsonSerializable()
class UserInfoDTO {
  final int id;
  final String? email;

  UserInfoDTO({required this.id, this.email});
  factory UserInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDTOFromJson(json);
}

@JsonSerializable()
class ProvisionStatus {
  final int deviceID;
  final bool provisioned;

  ProvisionStatus({required this.deviceID, required this.provisioned});
  factory ProvisionStatus.fromJson(Map<String, dynamic> json) =>
      _$ProvisionStatusFromJson(json);
}

@JsonSerializable()
class DeviceBinID {
  final int deviceID;
  final int binID;

  DeviceBinID({required this.deviceID, required this.binID});
  factory DeviceBinID.fromJson(Map<String, dynamic> json) =>
      _$DeviceBinIDFromJson(json);
}

@JsonSerializable()
class BinEventDTO {
  final int id;
  final int ts;
  final String eventType;
  final int bin;

  BinEventDTO(
      {required this.id,
      required this.ts,
      required this.eventType,
      required this.bin});
  factory BinEventDTO.fromJson(Map<String, dynamic> json) =>
      _$BinEventDTOFromJson(json);
}

@JsonSerializable()
class BinStateDTO {
  final DeviceBinID id;
  final String binStatus;
  final int scheduledTime;
  final BinEventDTO? event;
  final ScheduleDTO? schedule;

  BinStateDTO(
      {required this.id,
      required this.binStatus,
      required this.scheduledTime,
      this.event,
      this.schedule});
  factory BinStateDTO.fromJson(Map<String, dynamic> json) =>
      _$BinStateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$BinStateDTOToJson(this);
}

@JsonSerializable()
class DeviceUserDTO {
  final int id;
  final int deviceID;
  final String deviceClass;
  final String? customName;
  final int serialNo;
  final int? lastSync;
  final bool primaryUser;
  final bool owner;
  final bool notifications;
  final String? timezone;

  DeviceUserDTO(
      {required this.id,
      required this.deviceID,
      required this.deviceClass,
      this.customName,
      required this.serialNo,
      this.lastSync,
      required this.primaryUser,
      required this.owner,
      required this.notifications,
      this.timezone});
  factory DeviceUserDTO.fromJson(Map<String, dynamic> json) =>
      _$DeviceUserDTOFromJson(json);
}

@JsonSerializable()
class DeviceDTO {
  final int id;
  final String deviceClass;
  final String serialNo;
  final String? customName;
  final int? lastSync;

  DeviceDTO(
      {required this.id,
      required this.deviceClass,
      required this.serialNo,
      this.customName,
      this.lastSync});
  factory DeviceDTO.fromJson(Map<String, dynamic> json) =>
      _$DeviceDTOFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceDTOToJson(this);

  String bestHumanNane() {
    if (customName != null) {
      return customName!;
    } else {
      return "Device #${id}";
    }
  }
}

@JsonSerializable()
class AnonymousCredentialsDTO {
  final int id;
  final String secret;

  AnonymousCredentialsDTO({required this.id, required this.secret});
  factory AnonymousCredentialsDTO.fromJson(Map<String, dynamic> json) =>
      _$AnonymousCredentialsDTOFromJson(json);
  Map<String, dynamic> toJson() => _$AnonymousCredentialsDTOToJson(this);
}

@freezed
class EmailPasswordCredentialsDTO with _$EmailPasswordCredentialsDTO {
  const factory EmailPasswordCredentialsDTO(
      {required String? username,
      required String? password}) = _EmailPasswordCredentialsDTO;

  factory EmailPasswordCredentialsDTO.fromJson(Map<String, dynamic> json) =>
      _$EmailPasswordCredentialsDTOFromJson(json);
}

@JsonSerializable()
class JwtCredentials {
  final String? username;
  final List<String>? roles;
  final String? access_token;
  final String? token_type;
  final int? expires_in;

  JwtCredentials(
      {this.username,
      this.roles,
      this.access_token,
      this.token_type,
      this.expires_in});
  factory JwtCredentials.fromJson(Map<String, dynamic> json) =>
      _$JwtCredentialsFromJson(json);
  Map<String, dynamic> toJson() => _$JwtCredentialsToJson(this);
}

@JsonSerializable()
class ScheduleDTO {
  final int binID;
  late String dayOfWeek;
  late int secondsFrom00;

  ScheduleDTO.fromTimeOfDayOfWeek(
      {required this.binID, required TimeOfDayOfWeek tdow}) {
    dayOfWeek = tdow.dayOfWeekString();
    secondsFrom00 = tdow.offsetFrom00;
  }

  TimeOfDayOfWeek toTimeOfDayOfWeek() {
    return TimeOfDayOfWeek.fromString(
        dowString: dayOfWeek, offsetFrom00: secondsFrom00, isUTC: true);
  }

  ScheduleDTOAndTimeOfDayOfWeek toLocalCombined() {
    return ScheduleDTOAndTimeOfDayOfWeek(
        dto: this, tdow: toTimeOfDayOfWeek().toLocal());
  }

  ScheduleDTO(
      {required this.binID,
      required this.dayOfWeek,
      required this.secondsFrom00});
  factory ScheduleDTO.fromJson(Map<String, dynamic> json) =>
      _$ScheduleDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleDTOToJson(this);
}

class ScheduleDTOAndTimeOfDayOfWeek {
  final ScheduleDTO dto;
  final TimeOfDayOfWeek tdow;

  ScheduleDTOAndTimeOfDayOfWeek({required this.dto, required this.tdow});
}

@JsonSerializable()
class EngineeringDataDTO {
  final double vbatMeas;
  final double vbatScaled;
  final String timestamp;
  final List<int> voltages;

  EngineeringDataDTO(
      {required this.vbatMeas,
      required this.vbatScaled,
      required this.timestamp,
      required this.voltages});
  factory EngineeringDataDTO.fromJson(Map<String, dynamic> json) =>
      _$EngineeringDataDTOFromJson(json);
}

@JsonSerializable()
class EngineeringReqDTO {
  final int? holdMuxChannel;

  EngineeringReqDTO({this.holdMuxChannel});
  factory EngineeringReqDTO.fromJson(Map<String, dynamic> json) =>
      _$EngineeringReqDTOFromJson(json);
  Map<String, dynamic> toJson() => _$EngineeringReqDTOToJson(this);
}

@JsonSerializable()
class DeviceEngineeringData {
  final bool engrMode;
  final String? engrReq;
  final String? engrData;

  DeviceEngineeringData({required this.engrMode, this.engrReq, this.engrData});
  factory DeviceEngineeringData.fromJson(Map<String, dynamic> json) =>
      _$DeviceEngineeringDataFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceEngineeringDataToJson(this);
}

@JsonSerializable()
class EventDTO {
  final int id;
  final int ts;
  final String eventType;
  final int bin;

  EventDTO(
      {required this.id,
      required this.ts,
      required this.eventType,
      required this.bin});
  factory EventDTO.fromJson(Map<String, dynamic> json) =>
      _$EventDTOFromJson(json);
}

@JsonSerializable()
class DeviceUserSettings {
  final bool notifications;

  DeviceUserSettings({required this.notifications});
  factory DeviceUserSettings.fromJson(Map<String, dynamic> json) =>
      _$DeviceUserSettingsFromJson(json);
}

@JsonSerializable()
class NotificationTokenDTO {
  final String? notificationToken;

  NotificationTokenDTO({this.notificationToken});
  factory NotificationTokenDTO.fromJson(Map<String, dynamic> json) =>
      _$NotificationTokenDTOFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationTokenDTOToJson(this);
}

@JsonSerializable()
class MedicationDispenseTimeDTO {
  final int? id;
  final int? medicationID;
  final int? dispenseID;
  final int? quantity;
  final SimpleDispenseTimeDTO? dispense;

  MedicationDispenseTimeDTO(
      {this.id,
      this.medicationID,
      this.dispenseID,
      this.quantity,
      this.dispense});

  factory MedicationDispenseTimeDTO.fromJson(Map<String, dynamic> json) =>
      _$MedicationDispenseTimeDTOFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationDispenseTimeDTOToJson(this);
}

@JsonSerializable()
class SimpleDispenseTimeDTO {
  final int? id;
  final String? period;
  final int? time;

  SimpleDispenseTimeDTO({this.id, this.period, this.time});

  factory SimpleDispenseTimeDTO.fromJson(Map<String, dynamic> json) =>
      _$SimpleDispenseTimeDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SimpleDispenseTimeDTOToJson(this);
}

@JsonSerializable()
class ScheduledMedicationDTO {
  final int? id;
  final String med_name;
  final String? shape;
  final int? color;
  final List<MedicationDispenseTimeDTO>? dispenseTimes;

  ScheduledMedicationDTO(
      {this.id,
      required this.med_name,
      this.shape,
      this.color,
      this.dispenseTimes});
  factory ScheduledMedicationDTO.fromJson(Map<String, dynamic> json) =>
      _$ScheduledMedicationDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduledMedicationDTOToJson(this);
}

@JsonSerializable()
class UpdateDeviceUserSettings {
  final String? deviceName;
  final String? notificationToken;
  final bool? notifications;
  final String? timezone;

  UpdateDeviceUserSettings(
      {required this.deviceName,
      required this.notificationToken,
      required this.notifications,
      required this.timezone});
  factory UpdateDeviceUserSettings.fromJson(Map<String, dynamic> json) =>
      _$UpdateDeviceUserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateDeviceUserSettingsToJson(this);
}

@JsonSerializable()
class SimpleScheduleDTO {
  final int? amID;
  final int? amSecondsFrom00;
  final int? pmID;
  final int? pmSecondsFrom00;

  SimpleScheduleDTO(
      {this.amID, this.amSecondsFrom00, this.pmID, this.pmSecondsFrom00});
  factory SimpleScheduleDTO.fromJson(Map<String, dynamic> json) =>
      _$SimpleScheduleDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SimpleScheduleDTOToJson(this);
}

@JsonSerializable()
class SaveMedicationDTO {
  final int? id;
  final String? name;
  final String? shape;
  final int? color;
  final Set<int>? dispenseTimes;

  SaveMedicationDTO(
      {this.id, this.name, this.shape, this.color, this.dispenseTimes});
  factory SaveMedicationDTO.fromJson(Map<String, dynamic> json) =>
      _$SaveMedicationDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SaveMedicationDTOToJson(this);
}

@JsonSerializable()
class DosePeriodDTO {
  final int binID;
  final int? timestamp;
  final int status;
  final List<int>? medications;
  final String? takenAtTime;
  DosePeriodDTO(
      {required this.binID,
      this.timestamp,
      required this.status,
      this.medications,
      this.takenAtTime});
  factory DosePeriodDTO.fromJson(Map<String, dynamic> json) =>
      _$DosePeriodDTOFromJson(json);
}

@JsonSerializable()
class DeviceStateDTO {
  final int id;
  final int? lastSync;
  final int? bins;
  final List<DosePeriodDTO>? dosePeriods;
  final int? battery;
  final bool? charging;
  DeviceStateDTO(
      {required this.id,
      this.lastSync,
      this.bins,
      this.dosePeriods,
      this.battery,
      this.charging});
  factory DeviceStateDTO.fromJson(Map<String, dynamic> json) =>
      _$DeviceStateDTOFromJson(json);
}

class LoadingValueNotifier<T> extends ValueNotifier<T?> {
  bool _loading = false;
  LoadingValueNotifier(super.value) : _loading = value == null;

  bool get loading => _loading;
  set loading(bool newValue) {
    if (_loading == newValue) {
      return;
    }
    _loading = newValue;
    notifyListeners();
  }

  Future<T> fromFuture(Future<T> future) {
    loading = true;
    future.then((value) {
      this.value = value;
      loading = false;
    });
    return future;
  }
}

abstract mixin class Refreshable {
  void refresh();
}

class RefreshableValueNotifier<T> extends LoadingValueNotifier<T>
    with Refreshable {
  Future<T> Function() loadFunction;
  RefreshableValueNotifier(super.value, this.loadFunction);

  @override
  void refresh() {
    fromFuture(loadFunction());
  }
}

class AutoRefresh extends StatefulWidget {
  const AutoRefresh(
      {super.key,
      required this.refreshable,
      required this.child,
      this.refreshInterval = const Duration(seconds: 10)});

  final Refreshable refreshable;
  final Widget child;
  final Duration refreshInterval;

  @override
  State<StatefulWidget> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> {
  late Timer _timer;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.refreshInterval, (timer) {
      widget.refreshable.refresh();
    });
  }
}
