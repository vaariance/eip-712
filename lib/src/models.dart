part of 'typed_data.dart';

/// Represents a pair of type and value used in EIP-712 typed data
typedef TypeValuePair = ({String type, Object value});

/// Specifies the version of EIP-712 typed data
@JsonEnum(valueField: 'version')
enum TypedDataVersion {
  /// Version 3 of the EIP-712 specification
  v3(version: 'V3'),

  /// Version 4 of the EIP-712 specification
  v4(version: 'V4');

  final String version;

  const TypedDataVersion({required this.version});
}

/// Converts between EthereumAddress and JSON representation
class EthereumAddressConverter extends JsonConverter<EthereumAddress, Object> {
  const EthereumAddressConverter();

  /// Converts a JSON value to an EthereumAddress
  @override
  fromJson(address) {
    if (address is EthereumAddress) {
      return address;
    }
    return EthereumAddress.fromHex(address.toString());
  }

  /// Converts an EthereumAddress to its JSON representation
  @override
  toJson(address) {
    return address.with0x;
  }
}

/// Converts between Uint8List and JSON representation
class U8AConverter extends JsonConverter<Uint8List, Object> {
  const U8AConverter();

  /// Converts a JSON value to a Uint8List
  @override
  fromJson(bytes) {
    if (bytes is Uint8List) {
      return bytes;
    } else if (bytes is List<int>) {
      return Uint8List.fromList(bytes);
    }
    return hexToBytes(bytes.toString());
  }

  /// Converts a Uint8List to its JSON representation
  @override
  toJson(bytes) {
    return bytesToHex(bytes, include0x: true);
  }
}

/// Converts between BigInt and JSON representation
class BigintConverter extends JsonConverter<BigInt, Object> {
  const BigintConverter();

  /// Converts a JSON value to a BigInt
  @override
  fromJson(value) {
    return BigInt.parse(value.toString());
  }

  /// Converts a BigInt to its JSON representation
  @override
  toJson(value) {
    return value.toInt();
  }
}

/// Represents a property in an EIP-712 message type
@freezed
abstract class MessageTypeProperty with _$MessageTypeProperty {
  const factory MessageTypeProperty({
    /// The name of the property
    required String name,

    /// The type of the property
    required String type,
  }) = _MessageTypeProperty;

  factory MessageTypeProperty.fromJson(Map<String, String> json) =>
      _$MessageTypePropertyFromJson(json);
}

/// Represents a complete EIP-712 typed message
@freezed
abstract class TypedMessage with _$TypedMessage {
  @JsonSerializable(explicitToJson: true)
  const factory TypedMessage({
    /// The type definitions for the message
    required Map<String, List<MessageTypeProperty>> types,

    /// The primary type being signed
    required String primaryType,

    /// The domain separator data
    required EIP712Domain? domain,

    /// The message data
    required Map<String, dynamic> message,
  }) = _TypedMessage;

  factory TypedMessage.fromJson(Map<String, Object?> json) =>
      _$TypedMessageFromJson(json);
}

/// Represents the domain separator for EIP-712 typed data
@freezed
abstract class EIP712Domain with _$EIP712Domain {
  const EIP712Domain._();

  const factory EIP712Domain({
    /// The name of the signing domain
    required String? name,

    /// The version of the signing domain
    required String? version,

    /// The chain ID of the network
    @BigintConverter() required BigInt? chainId,

    /// The verifying contract address
    @EthereumAddressConverter() required EthereumAddress? verifyingContract,

    /// An optional salt value
    @U8AConverter() required Uint8List? salt,
  }) = _EIP712Domain;

  /// The type string for the domain separator
  static String get type => 'EIP712Domain';

  factory EIP712Domain.fromJson(Map<String, Object?> json) =>
      _$EIP712DomainFromJson(json);

  /// Creates an empty EIP712Domain with all fields set to null
  factory EIP712Domain.empty() => const EIP712Domain(
    name: null,
    version: null,
    chainId: null,
    verifyingContract: null,
    salt: null,
  );

  /// Provides array access to domain properties
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

/// Represents different types of messages in EIP-712
@freezed
sealed class MessageTypes with _$MessageTypes {
  /// Creates a domain separator message type
  const factory MessageTypes.eip712Domain({required EIP712Domain? value}) =
      Eip712Domain;

  /// Creates an additional data message type
  const factory MessageTypes.additionalData({
    required Map<String, dynamic>? value,
  }) = AdditionalData;

  /// Creates a MessageTypes instance from raw data
  factory MessageTypes.from(dynamic raw) =>
      MessageTypes.additionalData(value: raw as Map<String, dynamic>?);
}
