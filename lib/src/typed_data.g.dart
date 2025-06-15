// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typed_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageTypeProperty _$MessageTypePropertyFromJson(Map<String, dynamic> json) =>
    _MessageTypeProperty(
      name: json['name'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$MessageTypePropertyToJson(
  _MessageTypeProperty instance,
) => <String, dynamic>{'name': instance.name, 'type': instance.type};

_TypedMessage _$TypedMessageFromJson(Map<String, dynamic> json) =>
    _TypedMessage(
      types: (json['types'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map(
                (e) => MessageTypeProperty.fromJson(
                  Map<String, String>.from(e as Map),
                ),
              )
              .toList(),
        ),
      ),
      primaryType: json['primaryType'] as String,
      domain:
          json['domain'] == null
              ? null
              : EIP712Domain.fromJson(json['domain'] as Map<String, dynamic>),
      message: json['message'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$TypedMessageToJson(_TypedMessage instance) =>
    <String, dynamic>{
      'types': instance.types.map(
        (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
      ),
      'primaryType': instance.primaryType,
      'domain': instance.domain?.toJson(),
      'message': instance.message,
    };

_EIP712Domain _$EIP712DomainFromJson(Map<String, dynamic> json) =>
    _EIP712Domain(
      name: json['name'] as String?,
      version: json['version'] as String?,
      chainId: _$JsonConverterFromJson<Object, BigInt>(
        json['chainId'],
        const BigintConverter().fromJson,
      ),
      verifyingContract: _$JsonConverterFromJson<Object, EthereumAddress>(
        json['verifyingContract'],
        const EthereumAddressConverter().fromJson,
      ),
      salt: _$JsonConverterFromJson<Object, Uint8List>(
        json['salt'],
        const U8AConverter().fromJson,
      ),
    );

Map<String, dynamic> _$EIP712DomainToJson(_EIP712Domain instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'chainId': _$JsonConverterToJson<Object, BigInt>(
        instance.chainId,
        const BigintConverter().toJson,
      ),
      'verifyingContract': _$JsonConverterToJson<Object, EthereumAddress>(
        instance.verifyingContract,
        const EthereumAddressConverter().toJson,
      ),
      'salt': _$JsonConverterToJson<Object, Uint8List>(
        instance.salt,
        const U8AConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
