# EIP-712

[![Coverage Status](https://coveralls.io/repos/github/variance-labs/eip-712/badge.svg?branch=main)](https://coveralls.io/github/variance-labs/eip-712?branch=main)

A comprehensive Dart implementation of [EIP-712](https://eips.ethereum.org/EIPS/eip-712) (Ethereum Typed Structured Data Hashing and Signing) that provides secure and standardized message signing for Ethereum applications.

## Features

- **Complete EIP-712 Implementation**: Full support for typed structured data hashing according to the EIP-712 specification
- **Multi-Version Support**: Compatible with both EIP-712 v3 and v4 standards
- **Comprehensive Type Support**: Handles all Ethereum data types including:
  - `address` - Ethereum addresses with automatic hex validation
  - `bool` - Boolean values with flexible string parsing
  - `bytes` and `bytesN` - Dynamic and fixed-size byte arrays
  - `string` - UTF-8 encoded strings
  - `uint`/`int` - Signed and unsigned integers (8 to 256 bits) with range validation
  - Arrays - Support for dynamic and fixed-size arrays (v4 only)
  - Custom struct types with automatic dependency resolution
- **Type Safety**: Strict typing and Built-in range checking for integer types and comprehensive error handling
- **Domain Separation**: Proper EIP-712 domain hashing
- **Null Handling**: Smart null value processing for optional fields (v4)

## Getting Started

### Prerequisites

- Dart SDK 2.17.0 or higher
- Dependencies: `web3dart` and `wallet`

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  eip712: ^0.0.1
```

## Usage

### Basic Usage

```dart
import 'package:eip712/eip712.dart';

// Define your typed message structure
final typedMessage = TypedMessage(
  types: {
    'EIP712Domain': [
      MessageTypeProperty(name: 'name', type: 'string'),
      MessageTypeProperty(name: 'version', type: 'string'),
      MessageTypeProperty(name: 'chainId', type: 'uint256'),
      MessageTypeProperty(name: 'verifyingContract', type: 'address'),
    ],
    'Person': [
      MessageTypeProperty(name: 'name', type: 'string'),
      MessageTypeProperty(name: 'wallet', type: 'address'),
    ],
    'Mail': [
      MessageTypeProperty(name: 'from', type: 'Person'),
      MessageTypeProperty(name: 'to', type: 'Person'),
      MessageTypeProperty(name: 'contents', type: 'string'),
    ],
  },
  primaryType: 'Mail',
  domain: EIP712Domain(
    name: 'Ether Mail',
    version: '1',
    chainId: BigInt.from(1),
    verifyingContract: EthereumAddress.fromHex('0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC'),
    salt: null,
  ),
  message: {
    'from': {
      'name': 'Cow',
      'wallet': EthereumAddress.fromHex('0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826'),
    },
    'to': {
      'name': 'Bob',
      'wallet': EthereumAddress.fromHex('0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB'),
    },
    'contents': 'Hello, Bob!',
  },
);
```

Alternatively you can use the `TypedMessage.fromJson` method.

```dart
import 'package:eip712/eip712.dart';
final typedMessage = TypedMessage.fromJson(
 {
  "types": {
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"},
    ],
    "Person": [
      {"name": "name", "type": "string"},
      {"name": "wallets", "type": "address"},
    ],
    "Mail": [
      {"name": "from", "type": "Person"},
      {"name": "to", "type": "Person"},
      {"name": "contents", "type": "string"},
    ],
  },
  "primaryType": "Mail",
  "domain": {
    "name": "Ether Mail",
    "version": "1",
    "chainId": 1,
    "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
  },
  "message": {
    "from": {
      "name": "Cow",
      "wallet": 0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826,
    },
    "to": [
      {
        "name": "Bob",
        "wallet": 0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826,
      },
    ],
    "contents": "Hello, Bob!",
  },
 }
)
```

Generate the hash using EIP-712 v4/v3

```dart
final hash = hashTypedData(
  typedData: typedMessage,
  version: TypedDataVersion.v4,
);

print('EIP-712 Hash: ${bytesToHex(hash, include0x: true)}');
```

### Supported Data Types

Primitive Types

```dart
// Address type with automatic validation
final addressField = MessageTypeProperty(name: 'recipient', type: 'address');

// Boolean with flexible parsing
final boolField = MessageTypeProperty(name: 'approved', type: 'bool');

// Integer types with range validation
final uint256Field = MessageTypeProperty(name: 'amount', type: 'uint256');
final int128Field = MessageTypeProperty(name: 'balance', type: 'int128');

// String type (UTF-8 encoded and hashed)
final stringField = MessageTypeProperty(name: 'message', type: 'string');

// Bytes types (dynamic and fixed-size)
final bytesField = MessageTypeProperty(name: 'data', type: 'bytes');
final bytes32Field = MessageTypeProperty(name: 'hash', type: 'bytes32');
```

Array Types (EIP-712 v4 only)

```dart
// Dynamic arrays
final dynamicArray = MessageTypeProperty(name: 'items', type: 'string[]');

// Fixed-size arrays
final fixedArray = MessageTypeProperty(name: 'coordinates', type: 'uint256[2]');

// Arrays of custom types
final structArray = MessageTypeProperty(name: 'people', type: 'Person[]');
```

### Version Differences

EIP-712 v3:

- Basic type support without arrays
- Simpler encoding scheme

EIP-712 v4 (Recommended):

- Full array support (dynamic and fixed-size)
- Enhanced null value handling
- Improved type dependency resolution

```dart
// Use v3 for compatibility with older systems
final hashV3 = hashTypedData(
  typedData: typedMessage,
  version: TypedDataVersion.v3,
);

// Use v4 for full feature support (default)
final hashV4 = hashTypedData(
  typedData: typedMessage,
  version: TypedDataVersion.v4,
);
```

### Advanced Usage

Custom Struct Types

```dart
final customTypes = {
  'Asset': [
    MessageTypeProperty(name: 'token', type: 'address'),
    MessageTypeProperty(name: 'amount', type: 'uint256'),
  ],
  'Order': [
    MessageTypeProperty(name: 'maker', type: 'address'),
    MessageTypeProperty(name: 'taker', type: 'address'),
    MessageTypeProperty(name: 'assets', type: 'Asset[]'), // Array of custom type
    MessageTypeProperty(name: 'expiry', type: 'uint256'),
  ],
};
```

Domain Separation

```dart
// Each domain creates a unique signing context
final domain = EIP712Domain(
  name: 'MyDApp',
  version: '1.0',
  chainId: BigInt.from(1), // Ethereum mainnet
  verifyingContract: EthereumAddress.fromHex('0x1234...'), // Your contract address
  salt: intToBytes(2), // Optional additional entropy
);
```

### Error Handling

The package provides comprehensive error handling:

```dart
try {
  final hash = hashTypedData(
    typedData: typedMessage,
    version: TypedDataVersion.v4,
  );
} on ArgumentError catch (e) {
  // Handle missing values or invalid types
  print('Argument error: ${e.message}');
} on RangeError catch (e) {
  // Handle integer overflow/underflow
  print('Range error: ${e.message}');
} on StateError catch (e) {
  // Handle internal state errors
  print('State error: ${e.message}');
}
```

### Data Models

- `TypedMessage` - Complete typed data structure
- `TypedDataVersion` - Enum for v3/v4 versions
- `MessageTypeProperty` - Individual field definition
- `EIP712Domain` - Domain separator structure

### Additional Information

- Always validate contract addresses in the domain
- Use appropriate chain IDs for network identification
- Validate all input data before hashing

### Contributing

Contributions are welcome! Please ensure:

- All tests pass
- Code follows Dart style guidelines
- New features include comprehensive tests
- Documentation is updated for API changes

### Issues and Support

For bug reports and feature requests, please use the [GitHub issue tracker](https://github.com/vaariance/eip712/issues).
