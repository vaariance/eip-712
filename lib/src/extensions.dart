part of 'typed_data.dart';

/// Extension on [MessageTypes] that provides indexing functionality
/// for accessing values in EIP712 message types.
extension MessageTypesIndexing on MessageTypes {
  /// Provides index operator access to fields in the message type.
  ///
  /// For [Eip712Domain], returns the value associated with [key] from the domain,
  /// throwing an [ArgumentError] if the value is null.
  ///
  /// For [AdditionalData], returns the value associated with [key] from the data map,
  /// throwing an [ArgumentError] if the key is not found.
  ///
  /// Parameters:
  ///   - key: The field name to access
  ///
  /// Returns:
  ///   The value associated with the key
  ///
  /// Throws:
  ///   - [ArgumentError] if the key is not found or if the value is null
  Object operator [](String key) => when(
    eip712Domain: (domain) {
      return domain[key] ??
          (throw ArgumentError(
            'Failed to get value for field `$key`: value was null',
          ));
    },
    additionalData: (dataMap) {
      if (!dataMap.containsKey(key)) {
        throw ArgumentError(
          'Failed to get value for field `$key`: key not found',
        );
      }
      return dataMap[key]!;
    },
  );

  /// Pattern matches on the [MessageTypes] variant and executes the corresponding callback.
  ///
  /// Parameters:
  ///   - eip712Domain: Callback function for handling [Eip712Domain] variant
  ///   - additionalData: Callback function for handling [AdditionalData] variant
  ///
  /// Returns:
  ///   The result of the executed callback function
  T when<T>({
    required T Function(EIP712Domain domain) eip712Domain,
    required T Function(Map<String, dynamic> dataMap) additionalData,
  }) {
    return switch (this) {
      Eip712Domain() => eip712Domain(value as EIP712Domain),
      AdditionalData() => additionalData(value as Map<String, dynamic>),
    };
  }
}

extension ObjectExtension on Object {
  /// Casts this object to the specified type [T]
  ///
  /// Returns:
  ///   The object cast to type [T]
  T as<T>() => this as T;

  /// Gets the length of this object if it supports the length property
  ///
  /// Returns:
  ///   The length of the object
  int get length => as<dynamic>().length;
}
