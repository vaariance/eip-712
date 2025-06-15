import 'dart:math';
import 'dart:typed_data';

import 'package:eip712/eip712.dart';
import 'package:web3dart/web3dart.dart';

final Map<String, dynamic> rawTypedDataJson = {
  "types": {
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"},
    ],
    "Person": [
      {"name": "name", "type": "string"},
      {"name": "wallets", "type": "address[]"},
    ],
    "Mail": [
      {"name": "from", "type": "Person"},
      {"name": "to", "type": "Person[]"},
      {"name": "contents", "type": "string"},
    ],
    "Group": [
      {"name": "name", "type": "string"},
      {"name": "members", "type": "Person[]"},
    ],
  },
  "domain": {
    "name": "Ether Mail",
    "version": "1",
    "chainId": 1,
    "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
  },
  "primaryType": "Mail",
  "message": {
    "from": {
      "name": "Cow",
      "wallets": [
        "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        "0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF",
      ],
    },
    "to": [
      {
        "name": "Bob",
        "wallets": [
          "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
          "0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57",
          "0xB0B0b0b0b0b0B000000000000000000000000000",
        ],
      },
    ],
    "contents": "Hello, Bob!",
  },
};

void main() {
  final Random random = Random.secure();
  final EthPrivateKey privateKey = EthPrivateKey.createRandom(random);

  final TypedMessage typedData = TypedMessage.fromJson(rawTypedDataJson);
  final Uint8List typedDataHash = hashTypedData(
    typedData: typedData,
    version: TypedDataVersion.v4,
  );

  final Uint8List signature = privateKey.signToUint8List(typedDataHash);
  print(bytesToHex(signature, include0x: true));
}
