// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ShareCode {
  int get deviceId => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ShareCodeCopyWith<ShareCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShareCodeCopyWith<$Res> {
  factory $ShareCodeCopyWith(ShareCode value, $Res Function(ShareCode) then) =
      _$ShareCodeCopyWithImpl<$Res, ShareCode>;
  @useResult
  $Res call({int deviceId, String code, DateTime expiresAt});
}

/// @nodoc
class _$ShareCodeCopyWithImpl<$Res, $Val extends ShareCode>
    implements $ShareCodeCopyWith<$Res> {
  _$ShareCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? code = null,
    Object? expiresAt = null,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as int,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ShareCodeCopyWith<$Res> implements $ShareCodeCopyWith<$Res> {
  factory _$$_ShareCodeCopyWith(
          _$_ShareCode value, $Res Function(_$_ShareCode) then) =
      __$$_ShareCodeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int deviceId, String code, DateTime expiresAt});
}

/// @nodoc
class __$$_ShareCodeCopyWithImpl<$Res>
    extends _$ShareCodeCopyWithImpl<$Res, _$_ShareCode>
    implements _$$_ShareCodeCopyWith<$Res> {
  __$$_ShareCodeCopyWithImpl(
      _$_ShareCode _value, $Res Function(_$_ShareCode) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? code = null,
    Object? expiresAt = null,
  }) {
    return _then(_$_ShareCode(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as int,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$_ShareCode extends _ShareCode {
  const _$_ShareCode(
      {required this.deviceId, required this.code, required this.expiresAt})
      : super._();

  @override
  final int deviceId;
  @override
  final String code;
  @override
  final DateTime expiresAt;

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ShareCodeCopyWith<_$_ShareCode> get copyWith =>
      __$$_ShareCodeCopyWithImpl<_$_ShareCode>(this, _$identity);
}

abstract class _ShareCode extends ShareCode {
  const factory _ShareCode(
      {required final int deviceId,
      required final String code,
      required final DateTime expiresAt}) = _$_ShareCode;
  const _ShareCode._() : super._();

  @override
  int get deviceId;
  @override
  String get code;
  @override
  DateTime get expiresAt;
  @override
  @JsonKey(ignore: true)
  _$$_ShareCodeCopyWith<_$_ShareCode> get copyWith =>
      throw _privateConstructorUsedError;
}
