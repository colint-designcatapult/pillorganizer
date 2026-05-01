import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app/api/user.dart';
import 'package:app/exceptions/auth_failed.dart';
import 'package:app/main.dart';
import 'package:app/service/amplify_service.dart';
import 'package:app/utils/api_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api.dart';
import '../models/user.dart';
import '../service/credential_manager.dart';

part 'authentication_provider.g.dart';

final CredentialManager credentialManager = CredentialManager();

@riverpod
class Authentication extends _$Authentication {
  @override
  User? build() {
    return null;
  }

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

    await userService.newPassword(creds);
  }

  Future<void> signOut() async {
    try {
      await AmplifyService().signOut();
    } catch (e) {
      safePrint('Error calling Amplify signOut: $e');
    }

    try {
      await credentialManager.cleanCredentials();
    } catch (e) {
      safePrint('Error cleaning credentials: $e');
    }

    // Clear the local authentication state
    state = null;

    // Use the global navigator key to navigate — this bypasses any stale
    // dialog/context issues and works regardless of where signOut is called from.
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    var creds = UserChangePasswordDTO(
        currentPassword: currentPassword, newPassword: newPassword);

    await userService.changePassword(creds);
  }

  Future<void> changeEmail({
    required String currentEmail,
    required String newEmail,
  }) async {
    var creds =
        UserChangeEmailDTO(currentEmail: currentEmail, newEmail: newEmail);

    await userService.changeEmail(creds);
  }

  Future<bool> checkAuthStatus() async {
    final amplifyService = AmplifyService();
    final idToken = await amplifyService.getIdToken();

    if (idToken != null) {
      await credentialManager.updateJWT(JwtCredentials(access_token: idToken));
    }

    try {
      final user = await client.authStatus();
      state = User(
          id: user.id,
          email: user.email,
          isLinkedToTakecare: user.isLinkedToTakecare);
      return true;
    } catch (err) {
      if (err is DioException) {
        if (err.response != null) {
          if (err.response!.statusCode == 401 ||
              err.response!.statusCode == 403) {
            return false;
          }
        }
      }
      rethrow;
    }
  }
}
