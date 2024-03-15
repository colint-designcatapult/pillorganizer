import 'package:app/service/authentication_service.dart';

class AuthAlreadyRegisteredException implements Exception {
  final String message;

  AuthAlreadyRegisteredException(
      [this.message = AuthError.authAlreadyRegistered]);

  @override
  String toString() {
    return message;
  }
}
