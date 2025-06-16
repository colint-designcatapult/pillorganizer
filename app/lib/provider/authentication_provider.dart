import 'dart:async';

import 'package:app/api/user.dart';
import 'package:app/exceptions/auth_failed.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/utils/api_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../models/user.dart';
import '../service/credential_manager.dart';

final CredentialManager credentialManager = CredentialManager();

enum AuthenticationState { unknown, unauthenticated, anonymous, authenticated }

class AuthenticationProvider with ChangeNotifier {
  BaseUser? get currentUser => _user;
  BaseUser? _user;

  Future<void> _future = Future.value();

  Future<void> get future => _future;

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
        throw AuthFailedException();
      }
    }).catchError((error) {
      loginError(error);
    });
  }

  Future<void> sendRecoveryCode(String email) async {
    var dto = UserSendRecoveryCodeDTO(sendTo: email);
    await client.sendRecoveryCode(dto);
  }

  Future<bool> validateRecoveryCode(int code, String email) async {
    var dto = UserValidateRecoveryCodeDTO(recoveryCode: code, email: email);
    return await client.validateRecoveryCode(dto);
  }

  Future<void> newPassword({
    required String email,
    required String newPassword,
    required int recoveryCode,
  }) async {
    var creds = UserNewPasswordDTO(
        email: email, newPassword: newPassword, recoveryCode: recoveryCode);

    _future = userService.newPassword(creds);
    return _future;
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
        throw AuthFailedException();
      }
    });
  }

  Future<void> signOut(BuildContext context) async {
    return credentialManager.signOut().then((value) {
      _user = null;
      notifyListeners();
      Provider.of<DeviceBluetoothProvider>(context, listen: false).suppress();
      Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    var creds = UserChangePasswordDTO(
        currentPassword: currentPassword, newPassword: newPassword);

    _future = userService.changePassword(creds);
    return _future;
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
