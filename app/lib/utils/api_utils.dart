import 'package:app/exceptions/auth_connection.dart';
import 'package:app/exceptions/auth_generic_login.dart';
import 'package:app/exceptions/auth_generic.dart';
import 'package:app/exceptions/auth_register_email_existing.dart';

void registerError(dynamic error) {
  if (error.toString().contains("[connection error]")) {
    throw AuthConnectionException();
  }
  if (error.response?.data != null) {
    Map<String, dynamic> responseBody = error.response!.data;
    if (responseBody['title'] == "A user with that email already exists") {
      throw AuthRegistereEmailExistingException();
    }
  }
  throw AuthGenericException();
}

void loginError(dynamic error) {
  if (error.toString().contains("[connection error]")) {
    throw AuthConnectionException();
  }
  throw AuthGenericLoginException();
}
