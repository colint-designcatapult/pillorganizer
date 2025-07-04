class BaseUser {
  final int id;

  const BaseUser({
    required this.id,
  });
}

class User extends BaseUser {
  final String? email;

  User({required super.id, required this.email});
}
