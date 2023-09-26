import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'api.dart';
import '../provider/auth.dart';

part 'user.freezed.dart';

class UserService {
  Future<void> createAnonymousUser() async {
    AnonymousCredentialsDTO creds = await client.registerAnonymous();
    return credentialManager.updateAnonymousCreds(creds);
  }

  Future<void> register(UserRegistration registration) async {
    if (await credentialManager.isAnonUser()) {
      await client.upgradeAnonymous(registration.toDTO());
    } else if (await credentialManager.isRealUser()) {
      throw 'Already a full user';
    } else {
      await client.register(registration.toDTO());
    }
  }
}

final UserService userService = UserService();

@freezed
class UserRegistration extends Equatable with _$UserRegistration {
  const UserRegistration._();
  const factory UserRegistration(
      {required String email, required String password}) = _UserRegistration;

  factory UserRegistration.fromDTO(UserRegistrationDTO dto) {
    return UserRegistration(email: dto.email, password: dto.password);
  }

  UserRegistrationDTO toDTO() {
    return UserRegistrationDTO(email: email, password: password);
  }

  @override
  List<Object?> get props => [email, password];
}

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
