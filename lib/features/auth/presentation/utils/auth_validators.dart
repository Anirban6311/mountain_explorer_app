class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  static String? validateEmail(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your email.';
    if (!_emailRegex.hasMatch(value)) return 'Please enter a valid email.';
    return null;
  }

  static String? validatePassword(String? raw) {
    final value = raw ?? '';
    if (value.isEmpty) return 'Please enter your password.';
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Password must include a letter and a number.';
    }
    return null;
  }

  static String? validateDisplayName(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your name.';
    if (value.length > 40) return 'Name must be 40 characters or fewer.';
    return null;
  }
}
