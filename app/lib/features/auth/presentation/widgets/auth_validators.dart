/// Pure, reusable client-side form validators. Mirror (a subset of) the
/// backend rules to give instant feedback; the server remains authoritative.
abstract final class AuthValidators {
  const AuthValidators._();

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Must contain a letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Must contain a number';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Password is required' : null;
}
