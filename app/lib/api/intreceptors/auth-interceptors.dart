import 'dart:convert';

import 'package:dio/dio.dart';

import '../../service/credential_manager.dart';
import '../api.dart';

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Check if we have stored credentials. Attempt to authenticate with them
      CredentialPair? bestCreds = await credentialManager.getBestCredentials();
      if (bestCreds != null) {
        String endpoint;
        dynamic data;
        if (bestCreds.type == CredentialType.ANONYMOUS) {
          endpoint = "${AppApi.base()}/auth/login_anonymous";
          data = {"id": bestCreds.id, "secret": bestCreds.secret};
        } else if (bestCreds.type == CredentialType.USER) {
          endpoint = "${AppApi.base()}/auth/login";
          data = {"username": bestCreds.id, "password": bestCreds.secret};
        } else {
          return handler.reject(err);
        }

        Response<dynamic> loginResp =
            await dio.post(endpoint, data: jsonEncode(data));
        if (loginResp.statusCode == 200) {
          if (loginResp.data != null) {
            JwtCredentials creds = JwtCredentials.fromJson(loginResp.data!);
            await credentialManager.updateJWT(creds);

            final opts = Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers);
            final cloneReq = await dio.request(
                err.requestOptions.baseUrl + err.requestOptions.path,
                options: opts,
                data: err.requestOptions.data,
                queryParameters: err.requestOptions.queryParameters);

            return handler.resolve(cloneReq);
          }
        }
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
