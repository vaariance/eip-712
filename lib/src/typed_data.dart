import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

part 'utils.dart';
part 'extensions.dart';
part 'models.dart';
part 'typed_data.freezed.dart';
part 'typed_data.g.dart';

/// Hashes typed data according to EIP-712 specification.
///
/// This function implements the core hashing algorithm defined in EIP-712 for
/// structured typed data. It combines the domain separator and message data
/// using the specified version of the EIP-712 standard.
///
/// [typedData] The typed message data containing domain and message information
/// [version] The version of EIP-712 standard to use (v3 or v4)
///
/// Returns a [Uint8List] containing the 32-byte keccak256 hash of the encoded data
Uint8List hashTypedData({
  required TypedMessage typedData,
  required TypedDataVersion version,
}) {
  final prefix = hexToBytes('1901');
  final domainHash = eip712DomainHash(typedData: typedData, version: version);
  final messageHash = getMessageHash(typedData: typedData, version: version);

  final builder = BytesBuilder();
  builder.add(prefix);
  builder.add(domainHash);
  if (messageHash != null) {
    builder.add(messageHash);
  }

  return keccak256(builder.toBytes());
}

/// Computes the hash of an EIP-712 domain separator.
///
/// The domain separator is a crucial component that helps prevent replay attacks
/// across different domains. It includes chain ID, verifying contract address,
/// and other domain-specific data.
///
/// [typedData] The typed message containing domain information
/// [version] The version of EIP-712 standard to use
///
/// Returns a [Uint8List] containing the 32-byte keccak256 hash of the domain
Uint8List eip712DomainHash({
  required TypedMessage typedData,
  required TypedDataVersion version,
}) {
  final MessageTypes domain = MessageTypes.eip712Domain(
    value: typedData.domain,
  );
  final domainTypes = {
    EIP712Domain.type: typedData.types[EIP712Domain.type] ?? [],
  };
  return hashStruct(
    primaryType: EIP712Domain.type,
    data: domain,
    types: domainTypes,
    version: version,
  );
}

/// Computes the hash of the message data portion of a typed data structure.
///
/// This function handles the message portion of the typed data, separate from
/// the domain separator. It returns null if the primary type is the domain type,
/// as per EIP-712 specification.
///
/// [typedData] The typed message containing the data to hash
/// [version] The version of EIP-712 standard to use
///
/// Returns a [Uint8List] containing the 32-byte keccak256 hash of the message,
/// or null if the primary type is the domain type
Uint8List? getMessageHash({
  required TypedMessage typedData,
  required TypedDataVersion version,
}) {
  final MessageTypes message = MessageTypes.additionalData(
    value: typedData.message,
  );
  final isPrimaryType = typedData.primaryType == EIP712Domain.type;
  if (!isPrimaryType) {
    return hashStruct(
      primaryType: typedData.primaryType,
      data: message,
      types: typedData.types,
      version: version,
    );
  }
  return null;
}

/// Computes the hash of a structured data type according to EIP-712 rules.
///
/// This function encodes and hashes a structured data type using the specified
/// encoder version. It handles both basic types and custom struct types defined
/// in the types parameter.
///
/// [primaryType] The primary type name of the struct to hash
/// [data] The data values for the struct
/// [types] A map of type definitions used in the struct
/// [version] The version of EIP-712 standard to use
///
/// Returns a [Uint8List] containing the 32-byte keccak256 hash of the encoded struct
Uint8List hashStruct({
  required String primaryType,
  required MessageTypes data,
  required Map<String, List<MessageTypeProperty>> types,
  required TypedDataVersion version,
}) {
  final encoder = EIP712Encoder(types: types, version: version);
  final encodedData = encoder.encodeData(primaryType, data);
  return keccak256(encodedData);
}

/// An encoder for EIP-712 typed data that implements the encoding rules specified in the standard.
///
/// This class handles the encoding of structured data according to EIP-712 specification,
/// supporting both v3 and v4 versions of the standard. It provides functionality to encode
/// various data types, hash types, and handle type dependencies.
///
/// The encoder supports the following data types:
/// - Basic types: address, bool, string, bytes
/// - Integer types: uint8-uint256, int8-int256
/// - Bytes types: bytes1-bytes32
/// - Arrays (only in v4)
/// - Custom struct types
///
/// Example usage:
/// ```dart
/// final encoder = EIP712Encoder(
///   types: {
///     'Person': [
///       MessageTypeProperty(name: 'name', type: 'string'),
///       MessageTypeProperty(name: 'age', type: 'uint8'),
///     ],
///   },
/// );
/// ```
class EIP712Encoder {
  /// A map of type names to their corresponding property definitions.
  final Map<String, List<MessageTypeProperty>> types;

  /// The version of the EIP-712 standard to use for encoding.
  final TypedDataVersion version;

  /// Creates a new [EIP712Encoder] instance.
  ///
  /// [types] is a map of type names to their corresponding property definitions.
  /// [version] specifies the EIP-712 version to use, defaulting to v4.
  EIP712Encoder({required this.types, this.version = TypedDataVersion.v4});

  /// Encodes structured data according to EIP-712 rules.
  ///
  /// [primaryType] is the name of the primary type to encode.
  /// [data] contains the actual values to encode.
  ///
  /// Returns a [Uint8List] containing the encoded data.
  Uint8List encodeData(String primaryType, MessageTypes data) {
    final List<String> encodedTypes = ['bytes32'];
    final List<Object> encodedValues = [hashType(primaryType: primaryType)];

    for (var field in types[primaryType] ?? <MessageTypeProperty>[]) {
      if (version == TypedDataVersion.v3) {
        continue;
      }
      final typeValuePair = encodeField(
        name: field.name,
        type: field.type,
        value: data[field.name],
      );
      encodedTypes.add(typeValuePair.type);
      encodedValues.add(typeValuePair.value);
    }

    return encode(encodedTypes, encodedValues);
  }

  /// Encodes a single field according to its type and value.
  ///
  /// [name] is the field name.
  /// [type] is the field type.
  /// [value] is the field value.
  ///
  /// Returns a [TypeValuePair] containing the encoded type and value.
  TypeValuePair encodeField({
    required String name,
    required String type,
    required dynamic value,
  }) {
    if (types[type] != null) {
      return (
        type: 'bytes32',
        value:
            version == TypedDataVersion.v4 && value == null
                ? bytesToHex(Uint8List(32), include0x: true)
                : keccak256(encodeData(type, MessageTypes.from(value))),
      );
    }

    if (value == null) {
      throw ArgumentError("missing value for field $name of type $type");
    }

    if (type == 'address') {
      if (value is String) {
        if (isHex(value)) {
          return (type: 'address', value: EthereumAddress.fromHex(value));
        } else {
          throw ArgumentError(
            "value for field $name of type $type is not a valid hexadecimal string",
          );
        }
      }
      return (type: 'address', value: value);
    }

    if (type == 'bool') {
      final boolVal =
          value is bool ? value : (value.toString().toLowerCase() == 'true');
      return (type: 'bool', value: boolVal);
    }

    if (type == 'bytes') {
      if (value is num) {
        value = intToBytes(BigInt.from(value));
      } else if (value is BigInt) {
        value = intToBytes(value);
      } else if (isHex(value)) {
        value = hexToBytes(value);
      } else if (value is List<int>) {
        value = Uint8List.fromList(value);
      }
      return (type: 'bytes32', value: keccak256(value));
    }

    if (type.startsWith('bytes') && type != 'bytes' && !type.contains('[')) {
      if (value is num) {
        if (value < 0) {
          return (type: 'bytes32', value: Uint8List(32));
        }
        return (
          type: 'bytes32',
          value: intToBytes(BigInt.from(value)).padTo32Bytes(),
        );
      } else if (value is BigInt) {
        value = intToBytes(value);
      } else if (isHex(value)) {
        return (type: 'bytes32', value: hexToBytes(value).padTo32Bytes());
      }
      if (value is! List<int> || value is! Uint8List) {
        throw ArgumentError('Invalid value for field $name of type $type');
      }
      return (type: 'bytes32', value: value.padTo32Bytes());
    }

    if ((type.startsWith('uint') || type.startsWith('int')) &&
        !type.contains('[')) {
      final (min, max, parsed) = rangeCheck(
        type: type,
        value: value.toString(),
      );

      if (parsed < min || parsed > max) {
        throw RangeError(
          'Integer value $parsed out of range for $type '
          '($min … $max)',
        );
      }

      return (type: type, value: parsed);
    }

    if (type == 'string') {
      if (value is num) {
        value = intToBytes(BigInt.from(value));
      } else if (value is BigInt) {
        value = intToBytes(value);
      } else if (value is List<int>) {
      } else {
        value = Uint8List.fromList(utf8.encode(value));
      }
      return (type: 'bytes32', value: keccak256(value));
    }

    if (type.endsWith(']')) {
      if (version == TypedDataVersion.v3) {
        throw ArgumentError(
          'Arrays are unimplemented in encodeData; use V4 extension',
        );
      }
      final parsedType = type.substring(0, type.lastIndexOf('['));
      final typeValuePairs = value.map(
        (item) => encodeField(name: name, type: parsedType, value: item),
      );

      final typesList =
          typeValuePairs.map((pair) => pair.type).cast<String>().toList();
      final valuesList =
          typeValuePairs.map((pair) => pair.value).cast<Object>().toList();

      return (type: 'bytes32', value: keccak256(encode(typesList, valuesList)));
    }

    recognizeType(name, type, types.keys.toSet());
    return (type: type, value: value);
  }

  /// Computes the hash of a type string.
  ///
  /// [primaryType] is the name of the type to hash.
  ///
  /// Returns a [Uint8List] containing the type hash.
  Uint8List hashType({required String primaryType}) {
    final encodedHashType = encodeType(primaryType: primaryType);
    return keccak256(Uint8List.fromList(utf8.encode(encodedHashType)));
  }

  /// Encodes a type string according to EIP-712 rules.
  ///
  /// [primaryType] is the name of the type to encode.
  ///
  /// Returns the encoded type string.
  String encodeType({required String primaryType}) {
    var result = '';
    final unsortedDeps = findTypeDependencies(primaryType: primaryType)
      ..removeWhere((element) => element == primaryType);
    final deps = [primaryType, ...List.of(unsortedDeps)..sort()];

    for (final type in deps) {
      result +=
          "$type(${types[type]?.map((tp) => '${tp.type} ${tp.name}').join(',')})";
    }

    return result;
  }

  /// Finds all type dependencies for a given type.
  ///
  /// [primaryType] is the type to find dependencies for.
  /// [results] is the set of already found dependencies.
  /// [stack] is used to detect circular dependencies.
  ///
  /// Returns a set of all dependent type names.
  Set<String> findTypeDependencies({
    required String primaryType,
    Set<String>? results,
    Set<String>? stack,
  }) {
    final RegExp typeRegex = RegExp(r"^\w*", unicode: true);
    final match = typeRegex.stringMatch(primaryType);

    if (match == null || match.isEmpty) {
      throw ArgumentError('Invalid type: $primaryType');
    }

    validateTypeName(match);

    results ??= <String>{};
    stack ??= <String>{};

    if (stack.contains(match)) {
      throw ArgumentError('Circular type dependency detected on `$match`');
    }
    if (results.contains(match) || !types.containsKey(match)) {
      recognizeType("any", match, types.keys.toSet());
      return results;
    }

    stack.add(match);
    results.add(match);

    for (final field in types[match]!) {
      findTypeDependencies(
        primaryType: field.type,
        results: results,
        stack: stack,
      );
    }

    stack.remove(match);
    return results;
  }

  /// Checks if a numeric value is within the valid range for its type.
  ///
  /// [type] is the numeric type (uint/int with bit size).
  /// [value] is the string representation of the number.
  ///
  /// Returns a tuple containing the minimum value, maximum value, and parsed value.
  (BigInt min, BigInt max, BigInt parsed) rangeCheck({
    required String type,
    required String value,
  }) {
    final isUnsigned = type.startsWith('uint');
    final bitSize =
        int.tryParse(type.replaceFirst(RegExp(r'^(?:u?int)'), '')) ?? 256;

    final parsed = BigInt.parse(value.toString());

    final min = isUnsigned ? BigInt.zero : -(BigInt.one << (bitSize - 1));
    final max =
        isUnsigned
            ? (BigInt.one << bitSize) - BigInt.one
            : (BigInt.one << (bitSize - 1)) - BigInt.one;

    return (min, max, parsed);
  }

  /// Validates that a type is recognized and properly formatted.
  ///
  /// [name] is the field name.
  /// [type] is the type to validate.
  /// [definedStructs] is the set of defined struct types.
  ///
  /// Throws an [AssertionError] if the type is not recognized.
  void recognizeType(String name, String type, Set<String> definedStructs) {
    bool isPrimitive(String t) {
      if (t == 'address' || t == 'bool' || t == 'string' || t == 'bytes') {
        return true;
      }
      if (RegExp(r'^uint(8|16|32|64|128|256)$').hasMatch(t)) {
        return true;
      }
      if (RegExp(r'^int(8|16|32|64|128|256)$').hasMatch(t)) {
        return true;
      }
      if (RegExp(r'^bytes([1-9]|1[12]|2[0-9]|3[0-2])$').hasMatch(t)) {
        return true;
      }
      return false;
    }

    if (isPrimitive(type)) return;

    if (definedStructs.contains(type)) return;

    if (type.endsWith(']')) {
      final base = type.substring(0, type.indexOf('['));
      return recognizeType(name, base, definedStructs);
    }

    throw AssertionError('Unrecognized type `$type` for field `$name`');
  }

  /// Validates that a type name follows the allowed format.
  ///
  /// [name] is the type name to validate.
  ///
  /// Throws an [ArgumentError] if the name is invalid.
  void validateTypeName(String name) {
    const pattern = r'^[A-Za-z_][A-Za-z0-9_]*$';
    if (!RegExp(pattern).hasMatch(name)) {
      throw ArgumentError('Invalid type name `$name`');
    }
  }
}
