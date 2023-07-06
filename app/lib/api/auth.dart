import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';

enum CredentialType {
  USER,
  ANONYMOUS
}

class CredentialPair {
  final String id;
  final String secret;
  final CredentialType type;

  const CredentialPair({
    required this.id,
    required this.secret,
    required this.type
  });
}

class CredentialManager {
  final storage = const FlutterSecureStorage();

  final KEY_ANON_ID = 'anon_id';
  final KEY_ANON_SECRET = 'anon_secret';
  final KEY_USER_EMAIL = 'user_email';
  final KEY_USER_PASS = 'user_pass';
  final KEY_JWT = 'jwt';

  CredentialPair? credentialPair;
  JwtCredentials? jwt;

  Future<bool> hasAnonymousCreds() async {
    return await storage.read(key: KEY_ANON_ID) != null
        && await storage.read(key: KEY_ANON_SECRET) != null;
  }

  Future<bool> hasUserCreds() async {
    return await storage.read(key: KEY_USER_EMAIL) != null
        && await storage.read(key: KEY_USER_PASS) != null;
  }

  Future<CredentialPair?> getBestCredentials() async {
    if(credentialPair == null) {
      if(await hasUserCreds()) {
        credentialPair = CredentialPair(
          id: (await storage.read(key: KEY_USER_EMAIL))!,
          secret: (await storage.read(key: KEY_USER_PASS))!,
          type: CredentialType.USER
        );
      } else if(await hasAnonymousCreds()) {
        credentialPair = CredentialPair(
            id: (await storage.read(key: KEY_ANON_ID))!,
            secret: (await storage.read(key: KEY_ANON_SECRET))!,
            type: CredentialType.ANONYMOUS
        );
      }
    }
    return credentialPair;
  }

  Future<bool> hasJWT() {
    return storage.containsKey(key: KEY_JWT);
  }

  Future<JwtCredentials?> getJWT() async {
    String? str = await storage.read(key: KEY_JWT);
    if(str == null) {
      return null;
    }
    jwt ??= JwtCredentials.fromJson(jsonDecode(str));
    return jwt;
  }

  Future<void> updateJWT(JwtCredentials creds) async {
    assert(creds.access_token != null);
    jwt = creds;
    return storage.write(key: KEY_JWT, value: jsonEncode(creds.toJson()));
  }

  Future<void> updateCreds(String username, String password) async {
    credentialPair = CredentialPair(
        id: username,
        secret: password,
        type: CredentialType.USER
    );
    await storage.write(key: KEY_USER_EMAIL, value: username);
    await storage.write(key: KEY_USER_PASS, value: password);
  }

  Future<void> updateAnonymousCreds(AnonymousCredentialsDTO creds) async {
    String idStr = creds.id.toString();
    credentialPair = CredentialPair(
        id: idStr,
        secret: creds.secret,
        type: CredentialType.ANONYMOUS
    );
    await storage.write(key: KEY_ANON_ID, value: idStr);
    await storage.write(key: KEY_ANON_SECRET, value: creds.secret);
  }


  Future<bool> isAnonUser() async {
    return (await getJWT())?.roles?.contains("anon") ?? false;
  }

  Future<bool> isRealUser() async {
    return (await getJWT())?.roles?.contains("user") ?? false;
  }

  Future<bool> isLoggedIn() async {
    return (await getJWT()) != null;
  }

  Future<void> signOut() async {
    await storage.deleteAll();
    jwt = null;
    credentialPair = null;
  }

}

final CredentialManager credentialManager = CredentialManager();

class JwtAuthInterceptor extends Interceptor {

  final Dio dio;

  JwtAuthInterceptor({required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // If a JWT token exists, add it to the request headers
    String? jwt = (await credentialManager.getJWT())?.access_token;
    if(jwt != null) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }
    return handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if(err.response?.statusCode == 401) {
      // Check if we have stored credentials. Attempt to authenticate with them
      CredentialPair? bestCreds = await credentialManager.getBestCredentials();
      if(bestCreds != null) {
        String endpoint;
        dynamic data;
        if(bestCreds.type == CredentialType.ANONYMOUS) {
          endpoint = "${AppApi.base()}/auth/login_anonymous";
          data = {
            "id": bestCreds.id,
            "secret": bestCreds.secret
          };
        } else if(bestCreds.type == CredentialType.USER) {
          endpoint = "${AppApi.base()}/auth/login";
          data = {
            "username": bestCreds.id,
            "password": bestCreds.secret
          };
        } else {
          return handler.reject(err);
        }

        Response<dynamic> loginResp = await dio.post(
            endpoint,
            data: jsonEncode(data)
        );
        if(loginResp.statusCode == 200) {
          if(loginResp.data != null) {
            JwtCredentials creds = JwtCredentials.fromJson(loginResp.data!);
            await credentialManager.updateJWT(creds);

            final opts = Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers);
            final cloneReq = await dio.request(err.requestOptions.baseUrl + err.requestOptions.path,
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

Dio addAuthInterceptorsToDio(Dio dio) {
  return dio..interceptors.add(JwtAuthInterceptor(dio: dio));
}


enum AuthenticationState {
  unknown,
  unauthenticated,
  anonymous,
  authenticated
}

class BaseUser {
  final int id;

  const BaseUser({
    required this.id,
  });

}

class AnonymousUser extends BaseUser {
  AnonymousUser({required super.id});
}

class User extends BaseUser {
  final String? email;

  User({required super.id, required this.email});
}

class AuthenticationProvider with ChangeNotifier {

  BaseUser? get currentUser => _user;
  BaseUser? _user;

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    var creds = EmailPasswordCredentialsDTO(
        username: username,
        password: password
    );


    return client.login(creds)
        .then((value) => credentialManager.updateJWT(value))
        .then((v) => credentialManager.updateCreds(creds.username!, creds.password!))
        .then((v) async {
          if(!await checkAuthStatus()) {
            throw 'Authentication failed';
          }
        });
  }

  Future<void> createAnonymous() async  {
    var reg = await client.registerAnonymous();
    await logInAnonymous(id: reg.id, secret: reg.secret);
  }

  Future<void> logInAnonymous({
    required int id,
    required String secret,
  }) async {
    var creds = AnonymousCredentialsDTO(id: id, secret: secret);

    return client.loginAnonymous(creds)
        .then((value) => credentialManager.updateJWT(value))
        .then((v) => credentialManager.updateAnonymousCreds(creds))
        .then((v) async {
          if(!await checkAuthStatus()) {
            throw 'Authentication failed';
          }
        });
  }

  Future<void> signOut(BuildContext context) async {
    return credentialManager.signOut().then((value) {
      _user = null;
      notifyListeners();
      Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
    });
  }

  Future<bool> checkAuthStatus() {
    return client.authStatus().then((user) {
      _user = user.email != null ? User(id: user.id, email: user.email) : AnonymousUser(id: user.id);
      notifyListeners();
      return true;
    }).catchError((err) {
      if(err is DioError) {
        if(err.response != null) {
          if(err.response!.statusCode == 401 || err.response!.statusCode == 403) {
            return false;
          }
        }
      }
      throw err;
    });
  }

}