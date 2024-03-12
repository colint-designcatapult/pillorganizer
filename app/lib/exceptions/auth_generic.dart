import 'package:app/service/authentication_service.dart';

class AuthGenericException implements Exception {
  final String message;

  AuthGenericException([this.message = AuthError.authGenericError]);

  @override
  String toString() {
    return message;
  }
}
