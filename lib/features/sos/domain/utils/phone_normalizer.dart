/// Pure functions for normalizing user-entered phone numbers into a stable
/// shape suitable for SMS deep-links and Firestore storage.
///
/// Iter 4 deliberately avoids country-code inference and full E.164
/// validation — the rule is "8–15 digits, optionally with a leading +".
class PhoneNormalizer {
  const PhoneNormalizer._();

  static const int _minDigits = 8;
  static const int _maxDigits = 15;

  /// Returns a normalized phone string (digits only, optionally
  /// preserving the leading `+`) when [input] satisfies the digit-count
  /// rule; otherwise returns null.
  static String? normalize(String input) {
    final hasLeadingPlus = input.trimLeft().startsWith('+');
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _minDigits || digits.length > _maxDigits) {
      return null;
    }
    return hasLeadingPlus ? '+$digits' : digits;
  }

  /// Convenience predicate over [normalize].
  static bool isValid(String input) => normalize(input) != null;
}
