import 'package:app/service/authentication_service.dart';

class AuthConnectionException implements Exception {
  final String message;

  AuthConnectionException([this.message = AuthError.authConnectionError]);

  @override
  String toString() {
    return message;
  }
}
