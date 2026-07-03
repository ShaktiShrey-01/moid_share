import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/features/transfer/data/managers/encryption_manager.dart';

void main() {
  final manager = AesGcmEncryptionManager();

  test('generates a 256-bit (32-byte) key', () async {
    final key = await manager.generateKey();
    expect(key.length, 32);
  });

  test('seal then open round-trips the original bytes', () async {
    final key = await manager.generateKey();
    final plain = Uint8List.fromList(List.generate(1000, (i) => i % 256));

    final sealed = await manager.seal(key, plain);
    final opened = await manager.open(key, sealed);

    expect(opened, equals(plain));
    // Ciphertext must not equal plaintext, and carries nonce + MAC overhead.
    expect(sealed.bytes, isNot(equals(plain)));
    expect(sealed.bytes.length, greaterThan(plain.length));
  });

  test('two seals of the same data differ (unique nonce)', () async {
    final key = await manager.generateKey();
    final plain = Uint8List.fromList([1, 2, 3, 4, 5]);

    final a = await manager.seal(key, plain);
    final b = await manager.seal(key, plain);

    expect(a.bytes, isNot(equals(b.bytes)));
  });

  test('opening with the wrong key fails authentication', () async {
    final key = await manager.generateKey();
    final other = await manager.generateKey();
    final sealed = await manager.seal(key, Uint8List.fromList([9, 9, 9]));

    expect(() => manager.open(other, sealed), throwsA(isA<Object>()));
  });

  test('tampered ciphertext is rejected', () async {
    final key = await manager.generateKey();
    final sealed = await manager.seal(key, Uint8List.fromList([1, 2, 3, 4]));
    sealed.bytes[sealed.bytes.length - 1] ^= 0xFF; // flip a MAC byte

    expect(() => manager.open(key, sealed), throwsA(isA<Object>()));
  });
}
