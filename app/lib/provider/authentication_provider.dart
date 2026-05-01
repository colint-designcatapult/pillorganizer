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
    safePrint('🔐 Signing out...');
    
    // Do all async cleanup work FIRST
    try {
      await AmplifyService().signOut();
      safePrint('✓ Amplify signOut complete');
    } catch (e) {
      safePrint('⚠️ Amplify signOut error (expected): $e');
    }

    try {
      await credentialManager.cleanCredentials();
      safePrint('✓ Credentials cleaned up');
    } catch (e) {
      safePrint('⚠️ Credential cleanup error: $e');
    }

    // Update state if provider is still active
    try {
      state = null;
      safePrint('✓ Auth state cleared');
    } catch (e) {
      safePrint('ℹ️ Provider disposed (normal)');
    }
    
    // NOW that cleanup is complete, schedule navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToLoginViaGlobalKey();
    });
    
    safePrint('✓ Sign out complete, navigating to login');
  }
  
  static void _navigateToLoginViaGlobalKey() {
    final navState = navigatorKey.currentState;
    if (navState != null) {
      try {
        navState.pushNamedAndRemoveUntil('/', (route) => false);
        safePrint('✓ Navigated to login');
      } catch (e) {
        safePrint('✗ Navigation error: $e');
      }
    }
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
