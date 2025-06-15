part of 'typed_data.dart';

RegExp _hexadecimal = RegExp(r'^[0-9a-fA-F]+$');

/// Checks if a value is a valid hexadecimal string.
///
/// Parameters:
/// - [value]: The value to check.
/// - [bits]: Optional bit length to validate against. Defaults to -1 (no length check).
/// - [ignoreLength]: If true, ignores odd-length strings. Defaults to false.
///
/// Returns true if the value is a valid hexadecimal string, false otherwise.
///
/// Example:
/// ```dart
/// print(isHex('0x1234')); // Prints: true
/// print(isHex('0x123')); // Prints: false
/// print(isHex('0x123', ignoreLength: true)); // Prints: true
/// ```
bool isHex(dynamic value, {int bits = -1, bool ignoreLength = false}) {
  if (value is! String) {
    return false;
  }
  if (value == '0x') {
    // Adapt Ethereum special cases.
    return true;
  }
  if (value.startsWith('0x')) {
    value = value.substring(2);
  }
  if (_hexadecimal.hasMatch(value)) {
    if (bits != -1) {
      return value.length == (bits / 4).ceil();
    }
    return ignoreLength || value.length % 2 == 0;
  }
  return false;
}

/// Encodes a list of types and values into ABI-encoded data.
///
/// Parameters:
///   - `types`: A list of string types describing the ABI types.
///   - `values`: A list of dynamic values to be ABI-encoded.
///
/// Returns:
///   A [Uint8List] containing the ABI-encoded types and values.
///
/// Example:
/// ```dart
/// var encodedData = abi.encode(['uint256', 'string'], [BigInt.from(123), 'Hello']);
/// ```
Uint8List encode(List<String> types, List<dynamic> values) {
  List<AbiType> abiTypes = [];
  LengthTrackingByteSink result = LengthTrackingByteSink();
  for (String type in types) {
    var abiType = parseAbiType(type);
    abiTypes.add(abiType);
  }
  TupleType(abiTypes).encode(values, result);
  var resultBytes = result.asBytes();
  result.close();
  return resultBytes;
}

/// Decodes a list of ABI-encoded types and values.
///
/// Parameters:
///   - `types`: A list of string types describing the ABI types to decode.
///   - `value`: A [Uint8List] containing the ABI-encoded data to be decoded.
///
/// Returns:
///   A list of decoded values with the specified type.
///
/// Example:
/// ```dart
/// var decodedValues = abi.decode(['uint256', 'string'], encodedData);
/// ```
List decode(List<String> types, Uint8List value) {
  List<AbiType> abiTypes = [];
  for (String type in types) {
    var abiType = parseAbiType(type);
    abiTypes.add(abiType);
  }
  final parsedData = TupleType(abiTypes).decode(value.buffer, 0);
  return parsedData.data;
}
