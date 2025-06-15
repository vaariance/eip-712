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

class EIP712Encoder {
  final Map<String, List<MessageTypeProperty>> types;
  final TypedDataVersion version;

  EIP712Encoder({required this.types, this.version = TypedDataVersion.v4});

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
        return (type: 'bytes32', value: intToBytes(BigInt.from(value)));
      } else if (isHex(value)) {
        return (type: 'bytes32', value: hexToBytes(value));
      }
      return (type: 'bytes32', value: value);
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

  Uint8List hashType({required String primaryType}) {
    final encodedHashType = encodeType(primaryType: primaryType);
    return keccak256(Uint8List.fromList(utf8.encode(encodedHashType)));
  }

  String encodeType({required String primaryType}) {
    var result = '';
    final unsortedDeps = findTypeDependencies(primaryType: primaryType)
      ..removeWhere((element) => element == primaryType);
    final deps = [primaryType, ...List.of(unsortedDeps)..sort()];

    for (final type in deps) {
      final children = types[type];
      if (children == null) {
        throw ArgumentError('No type definition for: \$type');
      }

      result +=
          "$type(${types[type]!.map((tp) => '${tp.type} ${tp.name}').join(',')})";
    }

    return result;
  }

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

  (BigInt min, BigInt max, BigInt parsed) rangeCheck({
    required String type,
    required String value,
  }) {
    final isUnsigned = type.startsWith('uint');
    final bitSize =
        int.tryParse(type.replaceFirst(RegExp(r'^(?:u?int)'), '')) ?? 256;

    final parsed = BigInt.parse(value.toString());

    // Signed range:  –2^(N–1) … 2^(N–1)–1
    // Unsigned range: 0 … 2^N–1
    final min = isUnsigned ? BigInt.zero : -(BigInt.one << (bitSize - 1));
    final max =
        isUnsigned
            ? (BigInt.one << bitSize) - BigInt.one
            : (BigInt.one << (bitSize - 1)) - BigInt.one;

    return (min, max, parsed);
  }

  void recognizeType(String name, String type, Set<String> definedStructs) {
    bool isPrimitive(String t) {
      if (t == 'address' || t == 'bool' || t == 'string' || t == 'bytes') {
        return true;
      }
      // uint8, uint16, …, uint256
      if (RegExp(r'^uint(8|16|32|64|128|256)$').hasMatch(t)) {
        return true;
      }
      // int8, int16, …, int256
      if (RegExp(r'^int(8|16|32|64|128|256)$').hasMatch(t)) {
        return true;
      }
      // bytes1…bytes32
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

  void validateTypeName(String name) {
    const pattern = r'^[A-Za-z_][A-Za-z0-9_]*$';
    if (!RegExp(pattern).hasMatch(name)) {
      throw ArgumentError('Invalid type name `$name`');
    }
  }
}
