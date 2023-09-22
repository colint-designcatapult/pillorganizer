import 'package:app/api/user.dart';
import 'package:flutter/material.dart';

class UserRegistrationProvider with ChangeNotifier {
  UserRegistration _registration =
      const UserRegistration(email: '', password: '');
  UserRegistration get model => _registration;
  Future<void> _future = Future.value();
  Future<void> get future => _future;

  void updateEmail(String? email) {
    _registration = _registration.copyWith(email: email ?? '');
    notifyListeners();
  }

  void updatePassword(String? password) {
    _registration = _registration.copyWith(password: password ?? '');
    notifyListeners();
  }

  Future<void> register() {
    _future = userService.register(_registration);
    notifyListeners();
    return _future;
  }
}
