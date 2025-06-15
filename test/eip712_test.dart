import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:eip712/src/typed_data.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart'
    show EthPrivateKey, bytesToHex, intToBytes, isValidSignature, keccak256;

import '../example/eip712_example.dart' show rawTypedDataJson;

void main() {
  final Random random = Random.secure();
  final EthPrivateKey privateKey = EthPrivateKey.createRandom(random);

  group('EIP-712 Core Functions', () {
    group('hashTypedData', () {
      test('should hash typed data with v4 version', () {
        final typedData = TypedMessage.fromJson(rawTypedDataJson);

        final digest = hashTypedData(
          typedData: typedData,
          version: TypedDataVersion.v4,
        );

        final signature = privateKey.signToEcSignature(digest);
        final isValid = isValidSignature(
          keccak256(digest),
          signature,
          privateKey.encodedPublicKey,
        );

        expect(isValid, equals(true));
      });

      test('should hash typed data with v3 version', () {
        final typedData = TypedMessage.fromJson(rawTypedDataJson);

        final digest = hashTypedData(
          typedData: typedData,
          version: TypedDataVersion.v3,
        );

        final signature = privateKey.signToEcSignature(digest);
        final isValid = isValidSignature(
          keccak256(digest),
          signature,
          privateKey.encodedPublicKey,
        );

        expect(isValid, equals(true));
      });

      test('should handle domain-only typed data', () {
        final domainOnlyJson = {
          'types': {'EIP712Domain': rawTypedDataJson['types']['EIP712Domain']},
          'primaryType': 'EIP712Domain',
          'domain': rawTypedDataJson['domain'],
          'message': <String, dynamic>{},
        };

        final typedData = TypedMessage.fromJson(domainOnlyJson);

        final digest = hashTypedData(
          typedData: typedData,
          version: TypedDataVersion.v4,
        );

        final signature = privateKey.signToEcSignature(digest);
        final isValid = isValidSignature(
          keccak256(digest),
          signature,
          privateKey.encodedPublicKey,
        );

        expect(isValid, equals(true));
      });

      test('should throw error for invalid typed data', () {
        final invalidJson = Map<String, dynamic>.from(rawTypedDataJson);
        invalidJson['domain'] = {
          'name': rawTypedDataJson['domain']['name'],
          'version': rawTypedDataJson['domain']['version'],
        };

        // mising chainId and verifyingContract and salt
        final typedData = TypedMessage.fromJson(invalidJson);

        expect(
          () =>
              hashTypedData(typedData: typedData, version: TypedDataVersion.v4),
          throwsArgumentError,
        );
      });
    });

    group('eip712DomainHash', () {
      final fullTypedData = TypedMessage.fromJson(rawTypedDataJson);

      final fullDomainHash = eip712DomainHash(
        typedData: fullTypedData,
        version: TypedDataVersion.v4,
      );

      test('should generate correct domain hash', () {
        final hex = bytesToHex(fullDomainHash, include0x: true);
        expect(
          hex,
          equals(
            '0xf2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f',
          ),
        );
      });

      test('should handle minimal domain fields', () {
        final minimalJson = {
          'types': {
            'EIP712Domain':
                rawTypedDataJson['types']['EIP712Domain']
                    .where((f) => f['name'] == 'name' || f['name'] == 'version')
                    .toList(),
          },
          'primaryType': 'EIP712Domain',
          'domain': {
            'name': rawTypedDataJson['domain']['name'],
            'version': rawTypedDataJson['domain']['version'],
          },
          'message': <String, dynamic>{},
        };
        final minimalTypedData = TypedMessage.fromJson(minimalJson);
        final minimalHash = eip712DomainHash(
          typedData: minimalTypedData,
          version: TypedDataVersion.v4,
        );

        expect(minimalHash.length, equals(32));
        expect(minimalHash, isNot(fullDomainHash));
      });

      test('should handle all domain fields', () {
        final allFieldsJson = {
          'types': {
            'EIP712Domain': [
              ...rawTypedDataJson['types']['EIP712Domain'],
              {'name': 'salt', 'type': 'bytes32'},
            ],
          },
          'primaryType': 'EIP712Domain',
          'domain':
              {
                ...rawTypedDataJson['domain'],
                'salt':
                    '0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd',
              }.cast<String, dynamic>(),
          'message': <String, dynamic>{},
        };
        final allFieldsTypedData = TypedMessage.fromJson(allFieldsJson);
        final allFieldsHash = eip712DomainHash(
          typedData: allFieldsTypedData,
          version: TypedDataVersion.v4,
        );

        expect(allFieldsHash.length, equals(32));
        expect(allFieldsHash, isNot(fullDomainHash));
      });
    });

    group('getMessageHash', () {
      final TypedMessage typedMessage = TypedMessage.fromJson(rawTypedDataJson);

      test('should return message hash for non-domain primary type', () {
        final hash = getMessageHash(
          typedData: typedMessage,
          version: TypedDataVersion.v4,
        );
        expect(
          hash,
          isNotNull,
          reason: 'Non-domain types must produce a 32-byte hash',
        );
        final String hex = bytesToHex(hash!, include0x: true);
        expect(
          hex,
          equals(
            '0xeb4221181ff3f1a83ea7313993ca9218496e424604ba9492bb4052c03d5c3df8',
          ),
        );
      });

      test('should return null for EIP712Domain primary type', () {
        final domainOnlyJson = {
          'types': {'EIP712Domain': rawTypedDataJson['types']['EIP712Domain']},
          'primaryType': 'EIP712Domain',
          'domain': rawTypedDataJson['domain'],
          'message': <String, dynamic>{},
        };
        final TypedMessage domainOnly = TypedMessage.fromJson(domainOnlyJson);

        final hash = getMessageHash(
          typedData: domainOnly,
          version: TypedDataVersion.v4,
        );
        expect(hash, isNull, reason: 'Domain-only messages should return null');
      });

      test('should handle complex nested structures', () {
        final nestedJson = {
          'types': {
            'EIP712Domain': rawTypedDataJson['types']['EIP712Domain'],
            'Inner': [
              {'name': 'value', 'type': 'uint256'},
            ],
            'Outer': [
              {'name': 'inner', 'type': 'Inner'},
            ],
          },
          'primaryType': 'Outer',
          'domain': rawTypedDataJson['domain'],
          'message': {
            'inner': {'value': 42},
          },
        };
        final TypedMessage nested = TypedMessage.fromJson(nestedJson);

        final hash = getMessageHash(
          typedData: nested,
          version: TypedDataVersion.v4,
        );
        expect(hash, isNotNull);
        expect(
          hash!.length,
          equals(32),
          reason: 'Nested struct hash must be 32 bytes',
        );
      });
    });
  });

  group('Data Type Encoding', () {
    final TypedMessage typedMessage = TypedMessage.fromJson(rawTypedDataJson);
    final encoder = EIP712Encoder(types: typedMessage.types);
    final encoderV3 = EIP712Encoder(
      types: typedMessage.types,
      version: TypedDataVersion.v3,
    );
    group('Address Type', () {
      test('should encode valid ethereum address', () {
        final address = EthereumAddress.fromHex(
          '0x001d3f1ef827552ae1114027bd3ecf1f086ba0f9',
        );

        // this is neccessary to sanitize value
        final typeValuePair = encoder.encodeField(
          name: 'recipient',
          type: 'address',
          value: address,
        );

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        expect(encoded.length, equals(32));
        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x000000000000000000000000001d3f1ef827552ae1114027bd3ecf1f086ba0f9',
          ),
        );

        final decoded = decode(['address'], encoded);
        expect(decoded.first, equals(address));
      });

      test('should encode hex string address', () {
        const String hexAddr = '0x000000000000000000000000000000000000dEaD';

        // this is neccessary to sanitize value
        final typeValuePair = encoder.encodeField(
          name: 'sender',
          type: 'address',
          value: hexAddr,
        );

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);
        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x000000000000000000000000000000000000000000000000000000000000dead',
          ),
        );

        final decoded = decode(['address'], encoded);
        expect(
          (decoded.first as EthereumAddress).with0x.toLowerCase(),
          equals(hexAddr.toLowerCase()),
        );
      });

      test('should throw error for invalid address', () {
        expect(
          () => encoder.encodeField(
            name: 'user',
            type: 'address',
            value: '0x1234',
          ),
          throwsArgumentError,
        );
      });
    });

    group('Boolean Type', () {
      test('should encode true boolean', () {
        final typeValuePair = encoder.encodeField(
          name: 'flag',
          type: 'bool',
          value: true,
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        // 32-byte word, last byte == 1
        expect(encoded.length, equals(32));
        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x0000000000000000000000000000000000000000000000000000000000000001',
          ),
        );

        final decoded = decode(['bool'], encoded);
        expect(decoded.first, isTrue);
      });

      test('should encode false boolean', () {
        final typeValuePair = encoder.encodeField(
          name: 'flag',
          type: 'bool',
          value: false,
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        // 32-byte word, all zeroes
        expect(encoded.length, equals(32));
        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );

        final decoded = decode(['bool'], encoded);
        expect(decoded.first, isFalse);
      });

      test('should encode string "true" as boolean', () {
        final typeValuePair = encoder.encodeField(
          name: 'flag',
          type: 'bool',
          value: 'true',
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x0000000000000000000000000000000000000000000000000000000000000001',
          ),
        );

        final decoded = decode(['bool'], encoded);
        expect(decoded.first, isTrue);
      });

      test('should encode string "false" as boolean', () {
        final typeValuePair = encoder.encodeField(
          name: 'flag',
          type: 'bool',
          value: 'false',
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        expect(
          bytesToHex(encoded, include0x: true),
          equals(
            '0x0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );

        final decoded = decode(['bool'], encoded);
        expect(decoded.first, isFalse);
      });
    });

    group('Bytes Type', () {
      test('should encode bytes from number', () {
        final typeValuePair = encoder.encodeField(
          name: 'data',
          type: 'bytes',
          value: 0x123456,
        );
        expect(typeValuePair.type, equals('bytes32'));
        expect(
          typeValuePair.value,
          equals(keccak256(Uint8List.fromList([0x12, 0x34, 0x56]))),
        );

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);
        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(typeValuePair.value));
      });

      test('should encode bytes from hex string', () {
        const hex = '0xdeadbeef';
        final typeValuePair = encoder.encodeField(
          name: 'data',
          type: 'bytes',
          value: hex,
        );
        expect(typeValuePair.type, equals('bytes32'));
        expect(
          typeValuePair.value,
          equals(keccak256(Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]))),
        );

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);
        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(typeValuePair.value));
      });

      test('should handle negative numbers for fixed bytes', () {
        final typeValuePair = encoder.encodeField(
          name: 'data',
          type: 'bytes4',
          value: -1,
        );
        expect(typeValuePair.type, equals('bytes32'));
        expect(typeValuePair.value, equals(Uint8List(32)));

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);
        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(typeValuePair.value));
      });
    });

    group('Integer Types', () {
      test('should encode uint256 within range', () {
        final BigInt value = BigInt.parse('123456789012345678901234567890');
        final typeValuePair = encoder.encodeField(
          name: 'amount',
          type: 'uint256',
          value: value,
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        expect(encoded.length, equals(32));

        final decoded = decode(['uint256'], encoded);
        expect(decoded.first, equals(value));
      });

      test('should encode int256 within range', () {
        final BigInt value = BigInt.from(-42);
        final typeValuePair = encoder.encodeField(
          name: 'balance',
          type: 'int256',
          value: value,
        );
        final encoded = encode([typeValuePair.type], [typeValuePair.value]);

        expect(encoded.length, equals(32));

        final decoded = decode(['int256'], encoded);
        expect(decoded.first, equals(value));
      });

      test('should throw error for uint out of range', () {
        final BigInt tooBig = BigInt.one << 256;
        expect(
          () => encoder.encodeField(
            name: 'overflow',
            type: 'uint256',
            value: tooBig,
          ),
          throwsRangeError,
        );
      });

      test('should throw error for int out of range', () {
        final BigInt tooBigSigned = BigInt.one << 255;
        expect(
          () => encoder.encodeField(
            name: 'overflow',
            type: 'int256',
            value: tooBigSigned,
          ),
          throwsArgumentError,
        );

        // also below -2^255
        final BigInt tooSmallSigned = -(BigInt.one << 255) - BigInt.one;
        expect(
          () => encoder.encodeField(
            name: 'underflow',
            type: 'int256',
            value: tooSmallSigned,
          ),
          throwsArgumentError,
        );
      });

      test('should encode smaller integer types (uint8, int32, etc.)', () {
        final cases = {
          'uint8': BigInt.from(255),
          'uint16': BigInt.from(65535),
          'uint32': BigInt.parse('4294967295'),
          'int8': BigInt.from(-128),
          'int16': BigInt.from(-32768),
          'int32': BigInt.from(-2147483648),
        };

        cases.forEach((type, val) {
          final tvp = encoder.encodeField(name: type, type: type, value: val);
          final encoded = encode([tvp.type], [tvp.value]);
          expect(encoded.length, equals(32), reason: '32 bytes for $type');

          final decoded = decode([type], encoded);
          expect(decoded.first, equals(val), reason: 'Round-trip $type');
        });
      });
    });

    group('String Type', () {
      test('should encode regular string', () {
        final String value = 'Hello, World!';
        final typeValuePair = encoder.encodeField(
          name: 'message',
          type: 'string',
          value: value,
        );
        expect(typeValuePair.type, equals('bytes32'));

        final Uint8List encoded = encode(
          [typeValuePair.type],
          [typeValuePair.value],
        );

        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(keccak256(utf8.encode(value))));
      });

      test('should encode empty string', () {
        final String value = '';
        final typeValuePair = encoder.encodeField(
          name: 'empty',
          type: 'string',
          value: value,
        );

        final Uint8List encoded = encode(
          [typeValuePair.type],
          [typeValuePair.value],
        );

        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(keccak256(utf8.encode(value))));
      });

      test('should encode unicode string', () {
        final String value =
            '你好'; // UTF-8 is 6 bytes, padded to 32 → same as above
        final typeValuePair = encoder.encodeField(
          name: 'greeting',
          type: 'string',
          value: value,
        );

        final Uint8List encoded = encode(
          [typeValuePair.type],
          [typeValuePair.value],
        );

        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(keccak256(utf8.encode(value))));
      });

      test('should encode number as string', () {
        final int raw = 12345;
        final Uint8List value = intToBytes(BigInt.from(raw));
        final typeValuePair = encoder.encodeField(
          name: 'numeric',
          type: 'string',
          value: raw,
        );

        expect(typeValuePair.value, equals(keccak256(value)));

        final Uint8List encoded = encode(
          [typeValuePair.type],
          [typeValuePair.value],
        );

        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(keccak256(value)));
      });
    });

    group('Array Types', () {
      test('should encode array of addresses in v4', () {
        final List<EthereumAddress> addrs = [
          EthereumAddress.fromHex('0x001d3f1ef827552ae1114027bd3ecf1f086ba0f9'),
          EthereumAddress.fromHex('0x000000000000000000000000000000000000dead'),
        ];

        final tvp = encoder.encodeField(
          name: 'recipients',
          type: 'address[]',
          value: addrs,
        );
        expect(tvp.type, equals('bytes32'));

        final innerHash = keccak256(encode(['address', 'address'], addrs));
        expect(tvp.value, equals(innerHash));

        final Uint8List encoded = encode([tvp.type], [tvp.value]);
        expect(encoded, equals(innerHash));
      });

      test('should encode array of strings in v4', () {
        final List<String> msgs = ['foo', 'barbaz'];

        final tvp = encoder.encodeField(
          name: 'notes',
          type: 'string[]',
          value: msgs,
        );
        expect(tvp.type, equals('bytes32'));

        final h1 = keccak256(Uint8List.fromList(utf8.encode('foo')));
        final h2 = keccak256(Uint8List.fromList(utf8.encode('barbaz')));

        final innerHash = keccak256(encode(['bytes32', 'bytes32'], [h1, h2]));
        expect(tvp.value, equals(innerHash));
      });

      test('should encode array of custom structs in v4', () {
        final persons = [
          {
            'name': 'Alice',
            'wallets': ['0x001d3f1ef827552ae1114027bd3ecf1f086ba0f9'],
          },
          {
            'name': 'Bob',
            'wallets': ['0x000000000000000000000000000000000000dead'],
          },
        ];

        final tvp = encoder.encodeField(
          name: 'people',
          type: 'Person[]',
          value: persons,
        );
        expect(tvp.type, equals('bytes32'));

        final p1Hash = keccak256(
          encoder.encodeData('Person', MessageTypes.from(persons[0])),
        );
        final p2Hash = keccak256(
          encoder.encodeData('Person', MessageTypes.from(persons[1])),
        );

        final innerHash = keccak256(
          encode(['bytes32', 'bytes32'], [p1Hash, p2Hash]),
        );
        expect(tvp.value, equals(innerHash));
      });

      test('should throw error for arrays in v3', () {
        expect(
          () => encoderV3.encodeField(
            name: 'oops',
            type: 'address[]',
            value: <EthereumAddress>[],
          ),
          throwsArgumentError,
        );
      });

      test('should encode nested arrays', () {
        final nested = [
          [BigInt.one, BigInt.from(2)],
          [BigInt.from(3)],
        ];

        final tvp = encoder.encodeField(
          name: 'matrix',
          type: 'uint256[][]',
          value: nested,
        );
        expect(tvp.type, equals('bytes32'));

        final hA = keccak256(
          encode(['uint256', 'uint256'], [BigInt.one, BigInt.from(2)]),
        );
        final hB = keccak256(encode(['uint256'], [BigInt.from(3)]));

        final outerHash = keccak256(encode(['bytes32', 'bytes32'], [hA, hB]));
        expect(tvp.value, equals(outerHash));
      });

      test('should handle empty arrays', () {
        final tvp = encoder.encodeField(
          name: 'emptyList',
          type: 'uint256[]',
          value: <BigInt>[],
        );
        expect(tvp.type, equals('bytes32'));

        final emptyInner = keccak256(Uint8List(0));
        expect(tvp.value, equals(emptyInner));
      });
    });

    group('Custom Struct Types', () {
      test('should encode simple custom struct', () {
        final Map<String, dynamic> person = {
          'name': 'Alice',
          'wallets': ['0x001d3f1ef827552ae1114027bd3ecf1f086ba0f9'],
        };

        final tvp = encoder.encodeField(
          name: 'person',
          type: 'Person',
          value: person,
        );

        expect(tvp.type, equals('bytes32'));

        final Uint8List expectedHash = keccak256(
          encoder.encodeData('Person', MessageTypes.from(person)),
        );
        expect(tvp.value, equals(expectedHash));
      });

      test('should encode nested custom structs', () {
        final Map<String, dynamic> mail =
            rawTypedDataJson['message'] as Map<String, dynamic>;

        final tvp = encoder.encodeField(
          name: 'mail',
          type: 'Mail',
          value: mail,
        );

        expect(tvp.type, equals('bytes32'));

        final Uint8List expectedHash = keccak256(
          encoder.encodeData('Mail', MessageTypes.from(mail)),
        );
        expect(tvp.value, equals(expectedHash));
      });

      test('should handle null values in v4', () {
        final tvp = encoder.encodeField(
          name: 'person',
          type: 'Person',
          value: null,
        );

        expect(tvp.type, equals('bytes32'));
        expect(tvp.value, equals(bytesToHex(Uint8List(32), include0x: true)));
      });

      test('should throw error for missing required fields', () {
        final Map<String, dynamic> badPerson = {
          'name': 'Alice',
          // no 'wallet'
        };

        expect(
          () => encoder.encodeField(
            name: 'person',
            type: 'Person',
            value: badPerson,
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('Version Compatibility', () {
    test('should handle v3 encoding differences', () {
      // TODO: Implement v3 specific test
    });

    test('should handle v4 encoding differences', () {
      // TODO: Implement v4 specific test
    });

    test('should handle version-specific array behavior', () {
      // TODO: Implement version array behavior test
    });

    test('should handle version-specific null behavior', () {
      // TODO: Implement version null behavior test
    });
  });

  group('Type Dependencies and Validation', () {
    test('should find all type dependencies', () {
      // TODO: Implement type dependency test
    });

    test('should handle circular type dependencies', () {
      // TODO: Implement circular dependency test
    });

    test('should throw error for missing type definitions', () {
      // TODO: Implement missing type error test
    });

    test('should validate type names', () {
      // TODO: Implement type name validation test
    });
  });

  group('Range Checking', () {
    test('should validate uint ranges correctly', () {
      // TODO: Implement uint range validation test
    });

    test('should validate int ranges correctly', () {
      // TODO: Implement int range validation test
    });

    test('should handle edge cases for range limits', () {
      // TODO: Implement range edge case test
    });

    test('should parse bit sizes correctly', () {
      // TODO: Implement bit size parsing test
    });
  });

  group('Error Handling', () {
    test('should throw ArgumentError for invalid types', () {
      // TODO: Implement invalid type error test
    });

    test('should throw RangeError for out-of-range values', () {
      // TODO: Implement range error test
    });

    test('should handle malformed type definitions gracefully', () {
      // TODO: Implement malformed type test
    });

    test('should validate required parameters', () {
      // TODO: Implement required parameter test
    });
  });

  group('Edge Cases', () {
    test('should handle extremely large integers', () {
      // TODO: Implement large integer test
    });

    test('should handle very long strings', () {
      // TODO: Implement long string test
    });

    test('should handle deeply nested structures', () {
      // TODO: Implement deep nesting test
    });

    test('should handle special characters in strings', () {
      // TODO: Implement special character test
    });

    test('should handle zero values correctly', () {
      // TODO: Implement zero value test
    });
  });

  group('Utility Functions', () {
    test('should validate hex strings correctly', () {
      // TODO: Implement hex validation test
    });

    test('should handle type conversions', () {
      // TODO: Implement type conversion test
    });
  });
}
