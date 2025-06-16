// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typed_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageTypeProperty {

/// The name of the property
 String get name;/// The type of the property
 String get type;
/// Create a copy of MessageTypeProperty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageTypePropertyCopyWith<MessageTypeProperty> get copyWith => _$MessageTypePropertyCopyWithImpl<MessageTypeProperty>(this as MessageTypeProperty, _$identity);

  /// Serializes this MessageTypeProperty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageTypeProperty&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type);

@override
String toString() {
  return 'MessageTypeProperty(name: $name, type: $type)';
}


}

/// @nodoc
abstract mixin class $MessageTypePropertyCopyWith<$Res>  {
  factory $MessageTypePropertyCopyWith(MessageTypeProperty value, $Res Function(MessageTypeProperty) _then) = _$MessageTypePropertyCopyWithImpl;
@useResult
$Res call({
 String name, String type
});




}
/// @nodoc
class _$MessageTypePropertyCopyWithImpl<$Res>
    implements $MessageTypePropertyCopyWith<$Res> {
  _$MessageTypePropertyCopyWithImpl(this._self, this._then);

  final MessageTypeProperty _self;
  final $Res Function(MessageTypeProperty) _then;

/// Create a copy of MessageTypeProperty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _MessageTypeProperty implements MessageTypeProperty {
  const _MessageTypeProperty({required this.name, required this.type});
  factory _MessageTypeProperty.fromJson(Map<String, dynamic> json) => _$MessageTypePropertyFromJson(json);

/// The name of the property
@override final  String name;
/// The type of the property
@override final  String type;

/// Create a copy of MessageTypeProperty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageTypePropertyCopyWith<_MessageTypeProperty> get copyWith => __$MessageTypePropertyCopyWithImpl<_MessageTypeProperty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageTypePropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageTypeProperty&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type);

@override
String toString() {
  return 'MessageTypeProperty(name: $name, type: $type)';
}


}

/// @nodoc
abstract mixin class _$MessageTypePropertyCopyWith<$Res> implements $MessageTypePropertyCopyWith<$Res> {
  factory _$MessageTypePropertyCopyWith(_MessageTypeProperty value, $Res Function(_MessageTypeProperty) _then) = __$MessageTypePropertyCopyWithImpl;
@override @useResult
$Res call({
 String name, String type
});




}
/// @nodoc
class __$MessageTypePropertyCopyWithImpl<$Res>
    implements _$MessageTypePropertyCopyWith<$Res> {
  __$MessageTypePropertyCopyWithImpl(this._self, this._then);

  final _MessageTypeProperty _self;
  final $Res Function(_MessageTypeProperty) _then;

/// Create a copy of MessageTypeProperty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,}) {
  return _then(_MessageTypeProperty(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TypedMessage {

 Map<String, List<MessageTypeProperty>> get types; String get primaryType; EIP712Domain? get domain; Map<String, dynamic> get message;
/// Create a copy of TypedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypedMessageCopyWith<TypedMessage> get copyWith => _$TypedMessageCopyWithImpl<TypedMessage>(this as TypedMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedMessage&&const DeepCollectionEquality().equals(other.types, types)&&(identical(other.primaryType, primaryType) || other.primaryType == primaryType)&&(identical(other.domain, domain) || other.domain == domain)&&const DeepCollectionEquality().equals(other.message, message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(types),primaryType,domain,const DeepCollectionEquality().hash(message));

@override
String toString() {
  return 'TypedMessage(types: $types, primaryType: $primaryType, domain: $domain, message: $message)';
}


}

/// @nodoc
abstract mixin class $TypedMessageCopyWith<$Res>  {
  factory $TypedMessageCopyWith(TypedMessage value, $Res Function(TypedMessage) _then) = _$TypedMessageCopyWithImpl;
@useResult
$Res call({
 Map<String, List<MessageTypeProperty>> types, String primaryType, EIP712Domain? domain, Map<String, dynamic> message
});




}
/// @nodoc
class _$TypedMessageCopyWithImpl<$Res>
    implements $TypedMessageCopyWith<$Res> {
  _$TypedMessageCopyWithImpl(this._self, this._then);

  final TypedMessage _self;
  final $Res Function(TypedMessage) _then;

/// Create a copy of TypedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? types = null,Object? primaryType = null,Object? domain = freezed,Object? message = null,}) {
  return _then(TypedMessage(
types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as Map<String, List<MessageTypeProperty>>,primaryType: null == primaryType ? _self.primaryType : primaryType // ignore: cast_nullable_to_non_nullable
as String,domain: freezed == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as EIP712Domain?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}



/// @nodoc
mixin _$EIP712Domain {

/// The name of the signing domain
 String? get name;/// The version of the signing domain
 String? get version;/// The chain ID of the network
@BigintConverter() BigInt? get chainId;/// The verifying contract address
@EthereumAddressConverter() EthereumAddress? get verifyingContract;/// An optional salt value
@U8AConverter() Uint8List? get salt;
/// Create a copy of EIP712Domain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EIP712DomainCopyWith<EIP712Domain> get copyWith => _$EIP712DomainCopyWithImpl<EIP712Domain>(this as EIP712Domain, _$identity);

  /// Serializes this EIP712Domain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EIP712Domain&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.chainId, chainId) || other.chainId == chainId)&&(identical(other.verifyingContract, verifyingContract) || other.verifyingContract == verifyingContract)&&const DeepCollectionEquality().equals(other.salt, salt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,version,chainId,verifyingContract,const DeepCollectionEquality().hash(salt));

@override
String toString() {
  return 'EIP712Domain(name: $name, version: $version, chainId: $chainId, verifyingContract: $verifyingContract, salt: $salt)';
}


}

/// @nodoc
abstract mixin class $EIP712DomainCopyWith<$Res>  {
  factory $EIP712DomainCopyWith(EIP712Domain value, $Res Function(EIP712Domain) _then) = _$EIP712DomainCopyWithImpl;
@useResult
$Res call({
 String? name, String? version,@BigintConverter() BigInt? chainId,@EthereumAddressConverter() EthereumAddress? verifyingContract,@U8AConverter() Uint8List? salt
});




}
/// @nodoc
class _$EIP712DomainCopyWithImpl<$Res>
    implements $EIP712DomainCopyWith<$Res> {
  _$EIP712DomainCopyWithImpl(this._self, this._then);

  final EIP712Domain _self;
  final $Res Function(EIP712Domain) _then;

/// Create a copy of EIP712Domain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? version = freezed,Object? chainId = freezed,Object? verifyingContract = freezed,Object? salt = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,chainId: freezed == chainId ? _self.chainId : chainId // ignore: cast_nullable_to_non_nullable
as BigInt?,verifyingContract: freezed == verifyingContract ? _self.verifyingContract : verifyingContract // ignore: cast_nullable_to_non_nullable
as EthereumAddress?,salt: freezed == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EIP712Domain extends EIP712Domain {
  const _EIP712Domain({required this.name, required this.version, @BigintConverter() required this.chainId, @EthereumAddressConverter() required this.verifyingContract, @U8AConverter() required this.salt}): super._();
  factory _EIP712Domain.fromJson(Map<String, dynamic> json) => _$EIP712DomainFromJson(json);

/// The name of the signing domain
@override final  String? name;
/// The version of the signing domain
@override final  String? version;
/// The chain ID of the network
@override@BigintConverter() final  BigInt? chainId;
/// The verifying contract address
@override@EthereumAddressConverter() final  EthereumAddress? verifyingContract;
/// An optional salt value
@override@U8AConverter() final  Uint8List? salt;

/// Create a copy of EIP712Domain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EIP712DomainCopyWith<_EIP712Domain> get copyWith => __$EIP712DomainCopyWithImpl<_EIP712Domain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EIP712DomainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EIP712Domain&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.chainId, chainId) || other.chainId == chainId)&&(identical(other.verifyingContract, verifyingContract) || other.verifyingContract == verifyingContract)&&const DeepCollectionEquality().equals(other.salt, salt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,version,chainId,verifyingContract,const DeepCollectionEquality().hash(salt));

@override
String toString() {
  return 'EIP712Domain(name: $name, version: $version, chainId: $chainId, verifyingContract: $verifyingContract, salt: $salt)';
}


}

/// @nodoc
abstract mixin class _$EIP712DomainCopyWith<$Res> implements $EIP712DomainCopyWith<$Res> {
  factory _$EIP712DomainCopyWith(_EIP712Domain value, $Res Function(_EIP712Domain) _then) = __$EIP712DomainCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? version,@BigintConverter() BigInt? chainId,@EthereumAddressConverter() EthereumAddress? verifyingContract,@U8AConverter() Uint8List? salt
});




}
/// @nodoc
class __$EIP712DomainCopyWithImpl<$Res>
    implements _$EIP712DomainCopyWith<$Res> {
  __$EIP712DomainCopyWithImpl(this._self, this._then);

  final _EIP712Domain _self;
  final $Res Function(_EIP712Domain) _then;

/// Create a copy of EIP712Domain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? version = freezed,Object? chainId = freezed,Object? verifyingContract = freezed,Object? salt = freezed,}) {
  return _then(_EIP712Domain(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,chainId: freezed == chainId ? _self.chainId : chainId // ignore: cast_nullable_to_non_nullable
as BigInt?,verifyingContract: freezed == verifyingContract ? _self.verifyingContract : verifyingContract // ignore: cast_nullable_to_non_nullable
as EthereumAddress?,salt: freezed == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

/// @nodoc
mixin _$MessageTypes {

 Object? get value;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageTypes&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'MessageTypes(value: $value)';
}


}

/// @nodoc
class $MessageTypesCopyWith<$Res>  {
$MessageTypesCopyWith(MessageTypes _, $Res Function(MessageTypes) __);
}


/// @nodoc


class Eip712Domain implements MessageTypes {
  const Eip712Domain({required this.value});
  

@override final  EIP712Domain? value;

/// Create a copy of MessageTypes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Eip712DomainCopyWith<Eip712Domain> get copyWith => _$Eip712DomainCopyWithImpl<Eip712Domain>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Eip712Domain&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'MessageTypes.eip712Domain(value: $value)';
}


}

/// @nodoc
abstract mixin class $Eip712DomainCopyWith<$Res> implements $MessageTypesCopyWith<$Res> {
  factory $Eip712DomainCopyWith(Eip712Domain value, $Res Function(Eip712Domain) _then) = _$Eip712DomainCopyWithImpl;
@useResult
$Res call({
 EIP712Domain? value
});


$EIP712DomainCopyWith<$Res>? get value;

}
/// @nodoc
class _$Eip712DomainCopyWithImpl<$Res>
    implements $Eip712DomainCopyWith<$Res> {
  _$Eip712DomainCopyWithImpl(this._self, this._then);

  final Eip712Domain _self;
  final $Res Function(Eip712Domain) _then;

/// Create a copy of MessageTypes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(Eip712Domain(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as EIP712Domain?,
  ));
}

/// Create a copy of MessageTypes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EIP712DomainCopyWith<$Res>? get value {
    if (_self.value == null) {
    return null;
  }

  return $EIP712DomainCopyWith<$Res>(_self.value!, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class AdditionalData implements MessageTypes {
  const AdditionalData({required final  Map<String, dynamic>? value}): _value = value;
  

 final  Map<String, dynamic>? _value;
@override Map<String, dynamic>? get value {
  final value = _value;
  if (value == null) return null;
  if (_value is EqualUnmodifiableMapView) return _value;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of MessageTypes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdditionalDataCopyWith<AdditionalData> get copyWith => _$AdditionalDataCopyWithImpl<AdditionalData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdditionalData&&const DeepCollectionEquality().equals(other._value, _value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_value));

@override
String toString() {
  return 'MessageTypes.additionalData(value: $value)';
}


}

/// @nodoc
abstract mixin class $AdditionalDataCopyWith<$Res> implements $MessageTypesCopyWith<$Res> {
  factory $AdditionalDataCopyWith(AdditionalData value, $Res Function(AdditionalData) _then) = _$AdditionalDataCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic>? value
});




}
/// @nodoc
class _$AdditionalDataCopyWithImpl<$Res>
    implements $AdditionalDataCopyWith<$Res> {
  _$AdditionalDataCopyWithImpl(this._self, this._then);

  final AdditionalData _self;
  final $Res Function(AdditionalData) _then;

/// Create a copy of MessageTypes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(AdditionalData(
value: freezed == value ? _self._value : value // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
