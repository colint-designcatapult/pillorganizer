import 'package:app/exceptions/auth_already_registered.dart';
import 'package:app/utils/api_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../provider/authentication_provider.dart';
import 'api.dart';

part 'user.freezed.dart';

class UserService {
  Future<void> register(UserRegistration registration) async {
    try {
      await client.register(registration.toDTO());
    } catch (error) {
      if (error is AuthAlreadyRegisteredException) {
        throw AuthAlreadyRegisteredException;
      } else {
        registerError(error);
      }
    }
  }

  Future<void> changeEmail(UserChangeEmailDTO creds) async {
    if (await credentialManager.isRealUser()) {
      await client.changeEmail(creds).catchError((error) {
        throw ('The email does not match');
      });
    }
  }

  Future<void> changePassword(UserChangePasswordDTO creds) async {
    if (await credentialManager.isRealUser()) {
      await client.changePassword(creds).catchError((error) {
        throw ('The password does not match');
      });
    }
  }

  Future<void> newPassword(UserNewPasswordDTO creds) async {
    await client.newPassword(creds).catchError((error) {
      throw ('Error');
    });
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
