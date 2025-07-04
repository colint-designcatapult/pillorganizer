import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api.dart';

class CredentialPair {
  final String id;
  final String secret;

  const CredentialPair({required this.id, required this.secret});
}

class CredentialManager {
  static final CredentialManager _instance = CredentialManager._internal();

  factory CredentialManager() => _instance;

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  CredentialManager._internal();

  final KEY_USER_EMAIL = 'user_email';
  final KEY_USER_PASS = 'user_pass';
  final KEY_JWT = 'jwt';
  final KEY_HAS_ACCOUNT = 'has_account';

  CredentialPair? credentialPair;
  JwtCredentials? jwt;

  Future<bool> hasUserCreds() async {
    return await storage.read(key: KEY_USER_EMAIL) != null &&
        await storage.read(key: KEY_USER_PASS) != null;
  }

  Future<bool> hasAccount() async {
    return await storage.read(key: KEY_HAS_ACCOUNT) != null;
  }

  Future<CredentialPair?> getBestCredentials() async {
    if (credentialPair == null) {
      if (await hasUserCreds()) {
        credentialPair = CredentialPair(
            id: (await storage.read(key: KEY_USER_EMAIL))!,
            secret: (await storage.read(key: KEY_USER_PASS))!);
      }
    }
    return credentialPair;
  }

  Future<bool> hasJWT() {
    return storage.containsKey(key: KEY_JWT);
  }

  Future<JwtCredentials?> getJWT() async {
    String? str = await storage.read(key: KEY_JWT);
    if (str == null) {
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
    credentialPair = CredentialPair(id: username, secret: password);
    await storage.write(key: KEY_USER_EMAIL, value: username);
    await storage.write(key: KEY_USER_PASS, value: password);
  }

  Future<void> updatePasswordCreds(String password) async {
    String? userEmail = await storage.read(key: KEY_USER_EMAIL);

    credentialPair = CredentialPair(id: userEmail!, secret: password);
    await storage.write(key: KEY_USER_PASS, value: password);
  }

  Future<bool> isRealUser() async {
    return (await getJWT())?.roles?.contains("user") ?? false;
  }

  Future<void> signOut() async {
    await storage.deleteAll();
    storage.write(key: KEY_HAS_ACCOUNT, value: "true");
    jwt = null;
    credentialPair = null;
  }

  Future<void> cleanCredentials() async {
    await signOut();
    storage.write(key: KEY_HAS_ACCOUNT, value: null);
  }
}
