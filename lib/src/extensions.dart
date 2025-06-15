part of 'typed_data.dart';

extension MessageTypesIndexing on MessageTypes {
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

  T when<T>({
    required T Function(EIP712Domain domain) eip712Domain,
    required T Function(Map<String, dynamic> dataMap) additionalData,
  }) {
    if (this is Eip712Domain) {
      return eip712Domain(value as EIP712Domain);
    }
    if (this is AdditionalData) {
      return additionalData(value as Map<String, dynamic>);
    }
    throw StateError('Unhandled Union case: $this');
  }
}
