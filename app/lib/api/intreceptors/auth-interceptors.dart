import 'package:dio/dio.dart';

import '../../service/credential_manager.dart';

final CredentialManager credentialManager = CredentialManager();

Dio addAuthInterceptorsToDio(Dio dio) {
  return dio..interceptors.add(JwtAuthInterceptor(dio: dio));
}

class JwtAuthInterceptor extends Interceptor {
  final Dio dio;

  JwtAuthInterceptor({required this.dio});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // If a JWT token exists, add it to the request headers
    String? jwt = (await credentialManager.getJWT())?.access_token;
    if (jwt != null) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
