import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/api/intreceptors/auth-interceptors.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'control_plane.g.dart';

final controlPlaneDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://control-plane.app.healthesolutions.ca/',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(JwtAuthInterceptor(dio: dio));

  return dio;
});

@RestApi()
abstract class ControlPlaneApiClient {
  factory ControlPlaneApiClient(Dio dio) = _ControlPlaneApiClient;

  //@GET("/user/devices")
  //Future<Person> get();
}