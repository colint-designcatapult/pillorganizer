import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api.dart';

enum CredentialType { USER, ANONYMOUS }

class CredentialPair {
  final String id;
  final String secret;
  final CredentialType type;

  const CredentialPair(
      {required this.id, required this.secret, required this.type});
}

class CredentialManager {
  static final CredentialManager _instance = CredentialManager._internal();
  factory CredentialManager() => _instance;

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  CredentialManager._internal();

  final KEY_ANON_ID = 'anon_id';
  final KEY_ANON_SECRET = 'anon_secret';
  final KEY_USER_EMAIL = 'user_email';
  final KEY_USER_PASS = 'user_pass';
  final KEY_JWT = 'jwt';
  final KEY_HAS_ACCOUNT = 'has_account';

  CredentialPair? credentialPair;
  JwtCredentials? jwt;

  Future<bool> hasAnonymousCreds() async {
    return await storage.read(key: KEY_ANON_ID) != null &&
        await storage.read(key: KEY_ANON_SECRET) != null;
  }

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
            secret: (await storage.read(key: KEY_USER_PASS))!,
            type: CredentialType.USER);
      } else if (await hasAnonymousCreds()) {
        credentialPair = CredentialPair(
            id: (await storage.read(key: KEY_ANON_ID))!,
            secret: (await storage.read(key: KEY_ANON_SECRET))!,
            type: CredentialType.ANONYMOUS);
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
    credentialPair = CredentialPair(
        id: username, secret: password, type: CredentialType.USER);
    await storage.write(key: KEY_USER_EMAIL, value: username);
    await storage.write(key: KEY_USER_PASS, value: password);
  }

  Future<void> updatePasswordCreds(String password) async {
    String? userEmail = await storage.read(key: KEY_USER_EMAIL);

    credentialPair = CredentialPair(
        id: userEmail!, secret: password, type: CredentialType.USER);
    await storage.write(key: KEY_USER_PASS, value: password);
  }

  Future<void> updateAnonymousCreds(AnonymousCredentialsDTO creds) async {
    String idStr = creds.id.toString();
    credentialPair = CredentialPair(
        id: idStr, secret: creds.secret, type: CredentialType.ANONYMOUS);
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
    storage.write(key: KEY_HAS_ACCOUNT, value: "true");
    jwt = null;
    credentialPair = null;
  }
}
