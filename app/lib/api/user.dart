import 'package:app/exceptions/auth_already_registered.dart';
import 'package:app/utils/api_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'api.dart';
import '../provider/authentication_provider.dart';

part 'user.freezed.dart';

class UserService {
  Future<void> createAnonymousUser() async {
    AnonymousCredentialsDTO creds = await client.registerAnonymous();
    return credentialManager.updateAnonymousCreds(creds);
  }

  Future<void> register(UserRegistration registration) async {
    try {
      if (await credentialManager.isAnonUser()) {
        await client.upgradeAnonymous(registration.toDTO());
      } else if (await credentialManager.isRealUser()) {
        throw AuthAlreadyRegisteredException();
      } else {
        await client.register(registration.toDTO());
      }
    } catch (error) {
      if (error is AuthAlreadyRegisteredException) {
        throw AuthAlreadyRegisteredException;
      } else {
        registerError(error);
      }
    }
  }

  Future<void> changePassword(UserChangePasswordDTO creds) async {
    if (await credentialManager.isAnonUser() == false) {
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
