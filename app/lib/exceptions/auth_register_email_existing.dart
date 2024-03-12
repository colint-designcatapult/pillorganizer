import 'package:app/service/authentication_service.dart';

class AuthRegistereEmailExistingException implements Exception {
  final String message;

  AuthRegistereEmailExistingException(
      [this.message = AuthError.authRegisterEmailExistingError]);

  @override
  String toString() {
    return message;
  }
}
