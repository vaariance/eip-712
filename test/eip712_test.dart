import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:eip712/src/typed_data.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart'
    show
        EthPrivateKey,
        bytesToHex,
        hexToBytes,
        intToBytes,
        isValidSignature,
        keccak256;

import '../example/eip712_example.dart' show rawTypedDataJson;

void main() {
  final Random random = Random.secure();
  final EthPrivateKey privateKey = EthPrivateKey.createRandom(random);

  final TypedMessage typedMessage = TypedMessage.fromJson(rawTypedDataJson);
  final encoder = EIP712Encoder(types: typedMessage.types);
  final encoderV3 = EIP712Encoder(
    types: typedMessage.types,
    version: TypedDataVersion.v3,
  );

  group('EIP-712 Core Functions', () {
    group('hashTypedData', () {
      test('should hash typed data with v4 version', () {
        final digest = hashTypedData(
          typedData: typedMessage,
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
        final digest = hashTypedData(
          typedData: typedMessage,
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
      final fullDomainHash = eip712DomainHash(
        typedData: typedMessage,
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
            value: '0x1234q',
          ),
          throwsArgumentError,
        );
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

      test("should handle fixed bytes from hex string", () {
        final fixed = '0x12345678'; // 4 bytes
        final typeValuePair = encoder.encodeField(
          name: 'data',
          type: 'bytes4',
          value: fixed,
        );

        expect(typeValuePair.type, equals('bytes32'));
        expect(typeValuePair.value, equals(hexToBytes(fixed).padTo32Bytes()));

        final encoded = encode([typeValuePair.type], [typeValuePair.value]);
        final decoded = decode(['bytes32'], encoded);
        expect(decoded.first, equals(typeValuePair.value));
      });

      test("should handle fixed bytes from nummber", () {
        final fixed = BigInt.parse('0xff');
        final typeValuePair = encoder.encodeField(
          name: 'data',
          type: 'bytes4',
          value: fixed,
        );

        expect(typeValuePair.type, equals('bytes32'));
        expect(typeValuePair.value, equals(intToBytes(fixed).padTo32Bytes()));

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

      test('should handle unknown vlaue type for a fixed bytes', () {
        expect(
          () => encoder.encodeField(
            name: 'data',
            type: 'bytes4',
            value: BytesBuilder(),
          ),
          throwsArgumentError,
        );
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
    final String zeroHashHex = bytesToHex(Uint8List(32), include0x: true);
    test('should handle v3 encoding differences', () {
      final tvp3 = encoderV3.encodeField(
        name: 'person',
        type: 'Person',
        value: null,
      );
      expect(tvp3.type, equals('bytes32'));
      final String tvp3Hex = bytesToHex(
        tvp3.value.as<Uint8List>(),
        include0x: true,
      );
      expect(tvp3Hex, isNot(equals(zeroHashHex)));
      expect(
        () => encoderV3.encodeField(
          name: 'arr',
          type: 'uint256[]',
          value: [BigInt.one, BigInt.two],
        ),
        throwsArgumentError,
      );
    });

    test('should handle v4 encoding differences', () {
      final tvp4 = encoder.encodeField(
        name: 'person',
        type: 'Person',
        value: null,
      );
      expect(tvp4.type, equals('bytes32'));
      expect(tvp4.value, equals(zeroHashHex));
    });

    test('should handle version-specific null behavior', () {
      final domainOnlyJson = {
        'types': {'EIP712Domain': rawTypedDataJson['types']['EIP712Domain']},
        'primaryType': 'EIP712Domain',
        'domain': rawTypedDataJson['domain'],
        'message': <String, dynamic>{},
      };
      final domainMsg = TypedMessage.fromJson(domainOnlyJson);
      final domEnc3 = EIP712Encoder(
        types: domainMsg.types,
        version: TypedDataVersion.v3,
      );
      final domEnc4 = EIP712Encoder(
        types: domainMsg.types,
        version: TypedDataVersion.v4,
      );

      final tvp3Dom = domEnc3.encodeField(
        name: 'EIP712Domain',
        type: 'EIP712Domain',
        value: null,
      );
      final tvp4Dom = domEnc4.encodeField(
        name: 'EIP712Domain',
        type: 'EIP712Domain',
        value: null,
      );

      // v3 domain null → non-zero
      final String dom3Hex = bytesToHex(
        tvp3Dom.value as Uint8List,
        include0x: true,
      );
      expect(dom3Hex, isNot(equals(zeroHashHex)));

      // v4 domain null → zero
      expect(tvp4Dom.value, equals(zeroHashHex));
    });
  });

  group('Type Dependencies and Validation', () {
    test('should find all type dependencies', () {
      final deps = encoder.findTypeDependencies(primaryType: 'Mail');
      expect(
        deps.toSet(),
        equals({'Mail', 'Person'}),
        reason: 'Mail should depend on Person exactly once',
      );
    });

    test('should handle circular type dependencies', () {
      final circular = {
        'A': [MessageTypeProperty(name: 'b', type: 'B')],
        'B': [MessageTypeProperty(name: 'a', type: 'A')],
      };
      final subEnc = EIP712Encoder(types: circular);

      expect(
        () => subEnc.findTypeDependencies(primaryType: 'A'),
        throwsArgumentError,
        reason: 'Circular references should error out',
      );
    });

    test('should throw error for missing type definitions', () {
      final missing = {
        'A': [MessageTypeProperty(name: 'foo', type: 'Unknown')],
      };
      final subEnc = EIP712Encoder(types: missing);
      expect(
        () => subEnc.findTypeDependencies(primaryType: 'A'),
        throwsA(isA<AssertionError>()),
        reason: 'Referencing an undefined type must throw',
      );
    });

    test('should validate type names', () {
      const valid = ['Foo', 'Bar123', '_Baz'];
      for (final name in valid) {
        expect(
          () => encoder.validateTypeName(name),
          returnsNormally,
          reason: 'Type name `$name` should be accepted',
        );
      }
      const invalid = ['1Foo', 'Foo-bar', ''];
      for (final name in invalid) {
        expect(
          () => encoder.validateTypeName(name),
          throwsArgumentError,
          reason: 'Type name `$name` should be rejected',
        );
      }
    });

    test('should throw error when type is not matched', () {
      expect(
        () => encoder.findTypeDependencies(primaryType: ''),
        throwsArgumentError,
        reason: 'Referencing an empty type must throw',
      );
    });
  });

  group('Range Checking', () {
    test('should validate uint ranges correctly', () {
      // min: uint8: 0…255
      expect(
        () => encoder.encodeField(
          name: 'minU8',
          type: 'uint8',
          value: BigInt.zero,
        ),
        returnsNormally,
      );
      expect(
        () => encoder.encodeField(
          name: 'maxU8',
          type: 'uint8',
          value: BigInt.from(255),
        ),
        returnsNormally,
      );

      //max: uint256: 0…2^256-1
      final maxU256 = (BigInt.one << 256) - BigInt.one;
      expect(
        () => encoder.encodeField(
          name: 'maxU256',
          type: 'uint256',
          value: maxU256,
        ),
        returnsNormally,
      );
    });

    test('should validate int ranges correctly', () {
      //min: int8: -128…127
      expect(
        () => encoder.encodeField(
          name: 'minI8',
          type: 'int8',
          value: BigInt.from(-128),
        ),
        returnsNormally,
      );
      expect(
        () => encoder.encodeField(
          name: 'maxI8',
          type: 'int8',
          value: BigInt.from(127),
        ),
        returnsNormally,
      );

      //max: int256: -2^255…2^255-1
      expect(
        () => encoder.encodeField(
          name: 'minI256',
          type: 'int256',
          value: -(BigInt.one << 255),
        ),
        returnsNormally,
      );
      expect(
        () => encoder.encodeField(
          name: 'maxI256',
          type: 'int256',
          value: (BigInt.one << 255) - BigInt.one,
        ),
        returnsNormally,
      );
    });

    test('should handle edge cases for range limits', () {
      // overflow uint8
      expect(
        () => encoder.encodeField(
          name: 'overflowU8',
          type: 'uint8',
          value: BigInt.from(256),
        ),
        throwsRangeError,
      );
      // underflow int8
      expect(
        () => encoder.encodeField(
          name: 'underflowI8',
          type: 'int8',
          value: BigInt.from(-129),
        ),
        throwsRangeError,
      );
    });

    test('should parse bit sizes correctly', () {
      final (minU8, maxU8, parsedU8) = encoder.rangeCheck(
        type: 'uint8',
        value: '42',
      );
      expect(minU8, BigInt.zero);
      expect(maxU8, BigInt.from(255));
      expect(parsedU8, BigInt.from(42));

      final (minI16, maxI16, parsedI16) = encoder.rangeCheck(
        type: 'int16',
        value: '-12345',
      );
      expect(minI16, BigInt.from(-32768));
      expect(maxI16, BigInt.from(32767));
      expect(parsedI16, BigInt.from(-12345));
    });
  });

  group('Error Handling', () {
    test('should throw Error for invalid domian property access', () {
      expect(() => typedMessage.domain?['john'], throwsArgumentError);
    });
    test('should throw Error for unrecognized types', () {
      expect(
        () =>
            encoder.encodeField(name: 'foo', type: 'not_a_type', value: 'bar'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => encoder.encodeField(
          name: 'foo',
          type: 'not_a_type[]',
          value: ['bar'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw RangeError for out-of-range values', () {
      // uint8 only allows 0..255
      expect(
        () => encoder.encodeField(
          name: 'tooBig',
          type: 'uint8',
          value: BigInt.from(256),
        ),
        throwsRangeError,
      );
      // int16 allows -32768..32767
      expect(
        () => encoder.encodeField(
          name: 'tooSmall',
          type: 'int16',
          value: BigInt.from(-32769),
        ),
        throwsRangeError,
      );
    });

    test('should handle malformed type definitions gracefully', () {
      final badJson = {
        'types': {
          'EIP712Domain': rawTypedDataJson['types']['EIP712Domain'],
          'Foo': [
            {'name': 'bar', 'type': 'NonExistent'},
          ],
        },
        'primaryType': 'Foo',
        'domain': rawTypedDataJson['domain'],
        'message': {'bar': 123},
      };
      final badMsg = TypedMessage.fromJson(badJson);
      final badEncoder = EIP712Encoder(
        types: badMsg.types,
        version: TypedDataVersion.v4,
      );

      expect(
        () => badEncoder.encodeField(
          name: 'bar',
          type: 'Foo',
          value: {'bar': 123},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate required parameters', () {
      // encode() requires matching lengths
      expect(
        () => encode(['uint256', 'address'], [BigInt.one]),
        throwsA(isA<AssertionError>()),
      );
      // hashTypedData requires a valid domain
      final noDomainJson = {
        ...rawTypedDataJson,
        'domain': <String, dynamic>{}, // missing required domain fields
      };
      final noDomainMsg = TypedMessage.fromJson(noDomainJson);
      expect(
        () =>
            hashTypedData(typedData: noDomainMsg, version: TypedDataVersion.v4),
        throwsArgumentError,
      );
    });
  });

  group('Edge Cases', () {
    test('should handle extremely large integers', () {
      // max uint256
      final BigInt maxUint = (BigInt.one << 256) - BigInt.one;
      final tvpUint = encoder.encodeField(
        name: 'max',
        type: 'uint256',
        value: maxUint,
      );
      final encUint = encode([tvpUint.type], [tvpUint.value]);
      final decUint = decode(['uint256'], encUint);
      expect(decUint.first, equals(maxUint));

      // min int256
      final BigInt minInt = -(BigInt.one << 255);
      final tvpInt = encoder.encodeField(
        name: 'min',
        type: 'int256',
        value: minInt,
      );
      final encInt = encode([tvpInt.type], [tvpInt.value]);
      final decInt = decode(['int256'], encInt);
      expect(decInt.first, equals(minInt));
    });

    test('should handle very long strings', () {
      final String longStr = 'a' * 21000;
      final tvp = encoder.encodeField(
        name: 'long',
        type: 'string',
        value: longStr,
      );
      final Uint8List encoded = encode([tvp.type], [tvp.value]);
      final decoded = decode(['bytes32'], encoded);
      expect(decoded.first, equals(keccak256(utf8.encode(longStr))));
    });

    test('should handle deeply nested structures', () {
      // Build a deep nested struct: L1→L2→L3→value
      final nestedJson = {
        'types': {
          'EIP712Domain': rawTypedDataJson['types']['EIP712Domain'],
          'Level3': [
            {'name': 'value', 'type': 'uint256'},
          ],
          'Level2': [
            {'name': 'next', 'type': 'Level3'},
          ],
          'Level1': [
            {'name': 'next', 'type': 'Level2'},
          ],
        },
        'primaryType': 'Level1',
        'domain': rawTypedDataJson['domain'],
        'message': {
          'next': {
            'next': {'value': BigInt.from(123)},
          },
        },
      };
      final nestedMsg = TypedMessage.fromJson(nestedJson);
      final nestedEnc = EIP712Encoder(
        types: nestedMsg.types,
        version: TypedDataVersion.v4,
      );
      final tvp = nestedEnc.encodeField(
        name: 'lvl',
        type: 'Level1',
        value: nestedJson['message'],
      );
      // Should be a 32-byte hash and not the zero hash
      expect(tvp.value.length, equals(32));
      expect(
        bytesToHex(tvp.value.as<List<int>>(), include0x: true),
        isNot(equals(bytesToHex(Uint8List(32), include0x: true))),
      );
    });

    test('should handle special characters in strings', () {
      final String emoji = '🚀🔥 中文';
      final tvp = encoder.encodeField(
        name: 'text',
        type: 'string',
        value: emoji,
      );
      final encoded = encode([tvp.type], [tvp.value]);
      final decoded = decode(['bytes32'], encoded);
      expect(decoded.first, equals(keccak256(utf8.encode(emoji))));
    });

    test("should handle null value correctly", () {
      expect(
        () =>
            encoder.encodeField(name: 'nullValue', type: 'string', value: null),
        throwsArgumentError,
      );
    });

    test('should handle zero values correctly', () {
      // Zero uint256
      final tvpUint = encoder.encodeField(
        name: 'zeroUint',
        type: 'uint256',
        value: BigInt.zero,
      );
      final encUint = encode([tvpUint.type], [tvpUint.value]);
      // All bytes zero
      expect(encUint.every((b) => b == 0), isTrue);
      final decUint = decode(['uint256'], encUint);
      expect(decUint.first, equals(BigInt.zero));

      // Zero-length bytes (empty bytes array)
      final tvpBytes = encoder.encodeField(
        name: 'emptyBytes',
        type: 'bytes',
        value: <int>[],
      );
      final encBytes = encode([tvpBytes.type], [tvpBytes.value]);
      expect(encBytes.length, equals(32));
    });
  });

  group('Utility Functions', () {
    test('should validate hex strings correctly', () {
      expect(isHex('0xabcdef'), isTrue);
      expect(isHex('0XABCDEF'), isFalse, reason: 'invalid in ethereum context');
      expect(isHex('0x1234'), isTrue);
      expect(isHex('0x123', ignoreLength: true), isTrue);

      expect(isHex('abcdef'), isTrue, reason: 'true, valid hex');
      expect(isHex('abcdefq'), isFalse, reason: 'false, invalid hex');
      expect(isHex('0x12345g'), isFalse, reason: 'invalid hex character');
      expect(isHex('0x'), isTrue, reason: 'adapts to eth empty bytes');
      expect(isHex('0x1234 '), isFalse, reason: 'trailing space');
    });

    test('should handle type conversions', () {
      // 1) TypedMessage JSON ↔ model round-trip
      final Map<String, dynamic> msgJson = typedMessage.toJson();
      final TypedMessage msgRt = TypedMessage.fromJson(msgJson);
      expect(msgRt, equals(typedMessage));

      // 2) Domain field conversions
      expect(
        typedMessage.domain?.chainId,
        equals(BigInt.from(rawTypedDataJson['domain']['chainId'])),
      );
      expect(
        typedMessage.domain?.verifyingContract,
        equals(
          EthereumAddress.fromHex(
            rawTypedDataJson['domain']['verifyingContract'],
          ),
        ),
      );

      // 3) MessageTypes / Property conversions
      final personProps = typedMessage.types['Person']!;
      expect(personProps.map((p) => p.name), containsAll(['name', 'wallets']));
      expect(
        personProps.firstWhere((p) => p.name == 'wallets').type,
        equals('address[]'),
      );

      // 4) Raw message content intact
      expect(
        typedMessage.message['contents'],
        equals(rawTypedDataJson['message']['contents']),
      );

      // 5) U8AConverter sanity
      final U8AConverter u8aConv = U8AConverter();
      final Uint8List rawBytes = Uint8List.fromList([10, 20, 30]);
      final dynamic u8aJson = u8aConv.toJson(rawBytes);
      expect(u8aJson, equals(bytesToHex([10, 20, 30], include0x: true)));
      final Uint8List u8aRt = u8aConv.fromJson(u8aJson);
      expect(u8aRt, equals(rawBytes));

      // 6) EthereumAddressConverter sanity
      final EthereumAddress addr = EthereumAddress.fromHex(
        '0x000000000000000000000000000000000000dead',
      );
      final EthereumAddressConverter ethConv = EthereumAddressConverter();
      final dynamic ethJson = ethConv.toJson(addr);
      expect(ethJson, equals(addr.with0x));
      final EthereumAddress ethRt = ethConv.fromJson(ethJson);
      expect(ethRt, equals(addr));
    });
  });
}
