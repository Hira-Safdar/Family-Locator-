class PasswordValidator {
  const PasswordValidator._();

  static String? validate(String password) {
    if (password.length < 12) return 'Password must be at least 12 characters';
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[@#\$&]'));
    if (!hasUpper || !hasDigit || !hasSpecial) {
      return 'Use a capital letter, a number and a special symbol (@#\$&)';
    }
    return null;
  }
}
