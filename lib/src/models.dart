part of 'typed_data.dart';

typedef TypeValuePair = ({String type, Object value});

@JsonEnum(valueField: 'version')
enum TypedDataVersion {
  v3(version: 'V3'),
  v4(version: 'V4');

  final String version;

  const TypedDataVersion({required this.version});
}

class EthereumAddressConverter extends JsonConverter<EthereumAddress, Object> {
  const EthereumAddressConverter();

  @override
  fromJson(address) {
    if (address is EthereumAddress) {
      return address;
    }
    return EthereumAddress.fromHex(address.toString());
  }

  @override
  toJson(address) {
    return address.with0x;
  }
}

class U8AConverter extends JsonConverter<Uint8List, Object> {
  const U8AConverter();

  @override
  fromJson(bytes) {
    if (bytes is Uint8List) {
      return bytes;
    } else if (bytes is List<int>) {
      return Uint8List.fromList(bytes);
    }
    return hexToBytes(bytes.toString());
  }

  @override
  toJson(bytes) {
    return bytesToHex(bytes, include0x: true);
  }
}

class BigintConverter extends JsonConverter<BigInt, Object> {
  const BigintConverter();

  @override
  fromJson(value) {
    return BigInt.parse(value.toString());
  }

  @override
  toJson(value) {
    return value.toInt();
  }
}

@freezed
abstract class MessageTypeProperty with _$MessageTypeProperty {
  const factory MessageTypeProperty({
    required String name,
    required String type,
  }) = _MessageTypeProperty;

  factory MessageTypeProperty.fromJson(Map<String, String> json) =>
      _$MessageTypePropertyFromJson(json);
}

@freezed
abstract class TypedMessage with _$TypedMessage {
  const factory TypedMessage({
    required Map<String, List<MessageTypeProperty>> types,
    required String primaryType,
    required EIP712Domain? domain,
    required Map<String, dynamic> message,
  }) = _TypedMessage;

  factory TypedMessage.fromJson(Map<String, Object?> json) =>
      _$TypedMessageFromJson(json);
}

@freezed
abstract class EIP712Domain with _$EIP712Domain {
  const EIP712Domain._();

  const factory EIP712Domain({
    required String? name,
    required String? version,
    @BigintConverter() required BigInt? chainId,
    @EthereumAddressConverter() required EthereumAddress? verifyingContract,
    @U8AConverter() required Uint8List? salt,
  }) = _EIP712Domain;

  factory EIP712Domain.fromJson(Map<String, Object?> json) =>
      _$EIP712DomainFromJson(json);

  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'version':
        return version;
      case 'chainId':
        return chainId;
      case 'verifyingContract':
        return verifyingContract;
      case 'salt':
        return salt;
      default:
        throw ArgumentError("Var $key is not declared in EIP712Domain");
    }
  }
}

@freezed
sealed class MessageTypes with _$MessageTypes {
  const factory MessageTypes.eip712Domain({required EIP712Domain? value}) =
      Eip712Domain;

  const factory MessageTypes.additionalData({
    required Map<String, dynamic>? value,
  }) = AdditionalData;

  factory MessageTypes.from(dynamic raw) =>
      MessageTypes.additionalData(value: raw as Map<String, dynamic>);
}
