// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

EmailPasswordCredentialsDTO _$EmailPasswordCredentialsDTOFromJson(
    Map<String, dynamic> json) {
  return _EmailPasswordCredentialsDTO.fromJson(json);
}

/// @nodoc
mixin _$EmailPasswordCredentialsDTO {
  String? get username => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EmailPasswordCredentialsDTOCopyWith<EmailPasswordCredentialsDTO>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmailPasswordCredentialsDTOCopyWith<$Res> {
  factory $EmailPasswordCredentialsDTOCopyWith(
          EmailPasswordCredentialsDTO value,
          $Res Function(EmailPasswordCredentialsDTO) then) =
      _$EmailPasswordCredentialsDTOCopyWithImpl<$Res,
          EmailPasswordCredentialsDTO>;
  @useResult
  $Res call({String? username, String? password});
}

/// @nodoc
class _$EmailPasswordCredentialsDTOCopyWithImpl<$Res,
        $Val extends EmailPasswordCredentialsDTO>
    implements $EmailPasswordCredentialsDTOCopyWith<$Res> {
  _$EmailPasswordCredentialsDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? password = freezed,
  }) {
    return _then(_value.copyWith(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_EmailPasswordCredentialsDTOCopyWith<$Res>
    implements $EmailPasswordCredentialsDTOCopyWith<$Res> {
  factory _$$_EmailPasswordCredentialsDTOCopyWith(
          _$_EmailPasswordCredentialsDTO value,
          $Res Function(_$_EmailPasswordCredentialsDTO) then) =
      __$$_EmailPasswordCredentialsDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? username, String? password});
}

/// @nodoc
class __$$_EmailPasswordCredentialsDTOCopyWithImpl<$Res>
    extends _$EmailPasswordCredentialsDTOCopyWithImpl<$Res,
        _$_EmailPasswordCredentialsDTO>
    implements _$$_EmailPasswordCredentialsDTOCopyWith<$Res> {
  __$$_EmailPasswordCredentialsDTOCopyWithImpl(
      _$_EmailPasswordCredentialsDTO _value,
      $Res Function(_$_EmailPasswordCredentialsDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? password = freezed,
  }) {
    return _then(_$_EmailPasswordCredentialsDTO(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_EmailPasswordCredentialsDTO implements _EmailPasswordCredentialsDTO {
  const _$_EmailPasswordCredentialsDTO(
      {required this.username, required this.password});

  factory _$_EmailPasswordCredentialsDTO.fromJson(Map<String, dynamic> json) =>
      _$$_EmailPasswordCredentialsDTOFromJson(json);

  @override
  final String? username;
  @override
  final String? password;

  @override
  String toString() {
    return 'EmailPasswordCredentialsDTO(username: $username, password: $password)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_EmailPasswordCredentialsDTO &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, username, password);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_EmailPasswordCredentialsDTOCopyWith<_$_EmailPasswordCredentialsDTO>
      get copyWith => __$$_EmailPasswordCredentialsDTOCopyWithImpl<
          _$_EmailPasswordCredentialsDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_EmailPasswordCredentialsDTOToJson(
      this,
    );
  }
}

abstract class _EmailPasswordCredentialsDTO
    implements EmailPasswordCredentialsDTO {
  const factory _EmailPasswordCredentialsDTO(
      {required final String? username,
      required final String? password}) = _$_EmailPasswordCredentialsDTO;

  factory _EmailPasswordCredentialsDTO.fromJson(Map<String, dynamic> json) =
      _$_EmailPasswordCredentialsDTO.fromJson;

  @override
  String? get username;
  @override
  String? get password;
  @override
  @JsonKey(ignore: true)
  _$$_EmailPasswordCredentialsDTOCopyWith<_$_EmailPasswordCredentialsDTO>
      get copyWith => throw _privateConstructorUsedError;
}
