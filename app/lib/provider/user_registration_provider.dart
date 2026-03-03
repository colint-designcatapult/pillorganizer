import 'package:app/api/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_registration_provider.g.dart';

@riverpod
class UserRegistrationNotifier extends _$UserRegistrationNotifier {
  @override
  UserRegistration build() {
    return const UserRegistration(email: '', password: '');
  }

  void updateEmail(String? email) {
    state = state.copyWith(email: email ?? '');
  }

  void updatePassword(String? password) {
    state = state.copyWith(password: password ?? '');
  }

  Future<void> register() async {
    await userService.register(state);
  }
}
