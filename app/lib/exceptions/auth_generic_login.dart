import 'package:app/service/authentication_service.dart';

class AuthGenericLoginException implements Exception {
  final String message;

  AuthGenericLoginException([this.message = AuthError.authGenericLoginError]);

  @override
  String toString() {
    return message;
  }
}
