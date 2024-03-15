import 'package:app/service/authentication_service.dart';

class AuthFailedException implements Exception {
  final String message;

  AuthFailedException([this.message = AuthError.authFailedError]);

  @override
  String toString() {
    return message;
  }
}
