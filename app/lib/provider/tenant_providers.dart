import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/api/intreceptors/auth-interceptors.dart';

part 'tenant_providers.g.dart';

@riverpod
class ActiveTenantBaseUrl extends _$ActiveTenantBaseUrl {
  @override
  String? build() {
    return null;
  }

  void setUrl(String url) {
    state = url;
  }
}

@riverpod
Dio tenantDio(Ref ref) {
  final baseUrl = ref.watch(activeTenantBaseUrlProvider);
  
  if (baseUrl == null) {
    throw Exception('Tenant Base URL not set. Cannot create Tenant API Client without a base URL.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(JwtAuthInterceptor(dio: dio));

  return dio;
}

@riverpod
TenantApiClient tenantClient(Ref ref) {
  final dio = ref.watch(tenantDioProvider);
  return TenantApiClient(dio);
}

@riverpod
TenantApiClient? activeTenantClient(Ref ref) {
  final DeviceMetadata? device = ref.watch(activeDeviceProvider);
  if (device == null) return null;

  final dio = Dio(BaseOptions(
    baseUrl: device.apiBase,
    connectTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(JwtAuthInterceptor(dio: dio));
  return TenantApiClient(dio);
}
