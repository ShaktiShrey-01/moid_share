import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypted chunk = nonce ‖ ciphertext ‖ MAC, all as raw bytes.
class SealedChunk {
  const SealedChunk(this.bytes);
  final Uint8List bytes;
}

/// Per-transfer symmetric encryption for file bytes.
///
/// Each transfer uses a fresh 256-bit AES-GCM key (authenticated encryption:
/// confidentiality + integrity). The key is generated on the sender and shared
/// with the receiver out-of-band over the *signed* signaling channel — never
/// derived from anything guessable and never sent with the ciphertext.
///
/// The interface is deliberately transport-agnostic so the same manager can
/// seal bytes for a LAN socket, a relay, or a future WebRTC data channel.
abstract interface class EncryptionManager {
  /// Generates a fresh random key for one transfer, returned as raw bytes to
  /// hand to the peer over signaling.
  Future<Uint8List> generateKey();

  /// Seals one [chunk] under [keyBytes] with a unique nonce.
  Future<SealedChunk> seal(Uint8List keyBytes, List<int> chunk);

  /// Opens a previously [seal]ed chunk. Throws if authentication fails
  /// (tampered/corrupt data).
  Future<Uint8List> open(Uint8List keyBytes, SealedChunk chunk);
}

/// AES-GCM implementation backed by the `cryptography` package (pure Dart, so
/// it works identically on Android and — later — macOS).
class AesGcmEncryptionManager implements EncryptionManager {
  AesGcmEncryptionManager([AesGcm? algorithm])
      : _algo = algorithm ?? AesGcm.with256bits();

  final AesGcm _algo;
  static const int _nonceLength = 12; // 96-bit GCM nonce.
  static const int _macLength = 16; // 128-bit GCM tag.

  @override
  Future<Uint8List> generateKey() async {
    final key = await _algo.newSecretKey();
    return Uint8List.fromList(await key.extractBytes());
  }

  @override
  Future<SealedChunk> seal(Uint8List keyBytes, List<int> chunk) async {
    final secretBox = await _algo.encrypt(
      chunk,
      secretKey: SecretKey(keyBytes),
    );
    // Concatenate nonce ‖ ciphertext ‖ mac for a single self-describing blob.
    final out = Uint8List(
      secretBox.nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    var offset = 0;
    out.setAll(offset, secretBox.nonce);
    offset += secretBox.nonce.length;
    out.setAll(offset, secretBox.cipherText);
    offset += secretBox.cipherText.length;
    out.setAll(offset, secretBox.mac.bytes);
    return SealedChunk(out);
  }

  @override
  Future<Uint8List> open(Uint8List keyBytes, SealedChunk chunk) async {
    final bytes = chunk.bytes;
    if (bytes.length < _nonceLength + _macLength) {
      throw const FormatException('Sealed chunk is too short to be valid');
    }
    final nonce = bytes.sublist(0, _nonceLength);
    final mac = bytes.sublist(bytes.length - _macLength);
    final cipherText = bytes.sublist(_nonceLength, bytes.length - _macLength);

    final clear = await _algo.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(keyBytes),
    );
    return Uint8List.fromList(clear);
  }
}
