import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../models/user.dart';
import '../service/credential_manager.dart';
import '../api/api.dart';

final CredentialManager credentialManager = CredentialManager();

enum AuthenticationState { unknown, unauthenticated, anonymous, authenticated }

class AuthenticationProvider with ChangeNotifier {
  BaseUser? get currentUser => _user;
  BaseUser? _user;

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    var creds =
        EmailPasswordCredentialsDTO(username: username, password: password);

    return client
        .login(creds)
        .then((value) => credentialManager.updateJWT(value))
        .then((v) =>
            credentialManager.updateCreds(creds.username!, creds.password!))
        .then((v) async {
      if (!await checkAuthStatus()) {
        throw 'Authentication failed';
      }
    }).catchError((error) {
      throw ('The email or password is incorrect');
    });
  }

  Future<void> createAnonymous() async {
    var reg = await client.registerAnonymous();
    await logInAnonymous(id: reg.id, secret: reg.secret);
  }

  Future<void> logInAnonymous({
    required int id,
    required String secret,
  }) async {
    var creds = AnonymousCredentialsDTO(id: id, secret: secret);

    return client
        .loginAnonymous(creds)
        .then((value) => credentialManager.updateJWT(value))
        .then((v) => credentialManager.updateAnonymousCreds(creds))
        .then((v) async {
      if (!await checkAuthStatus()) {
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
      _user = user.email != null
          ? User(id: user.id, email: user.email)
          : AnonymousUser(id: user.id);
      notifyListeners();
      return true;
    }).catchError((err) {
      if (err is DioError) {
        if (err.response != null) {
          if (err.response!.statusCode == 401 ||
              err.response!.statusCode == 403) {
            return false;
          }
        }
      }
      throw err;
    });
  }
}
