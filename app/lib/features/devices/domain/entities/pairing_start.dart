/// The result of initiating pairing: a short code to share plus its expiry.
class PairingStart {
  const PairingStart({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}
