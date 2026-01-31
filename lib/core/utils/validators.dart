/// Utility class for input validation
class Validators {
  Validators._();

  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Phone number validation regex (Indian format)
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Password validation regex (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
  );

  /// URL validation regex
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// PAN card validation regex
  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  /// GSTIN validation regex
  static final RegExp _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  /// Pincode validation regex (Indian)
  static final RegExp _pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate phone number (Indian format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final phoneNumber = cleaned.length > 10 && cleaned.startsWith('91')
        ? cleaned.substring(2)
        : cleaned;
    if (!_phoneRegex.hasMatch(phoneNumber)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    if (!_urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate PAN card
  static String? validatePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN is required';
    }
    if (!_panRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN number';
    }
    return null;
  }

  /// Validate GSTIN
  static String? validateGstin(String? value) {
    if (value == null || value.isEmpty) {
      return 'GSTIN is required';
    }
    if (!_gstinRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid GSTIN';
    }
    return null;
  }

  /// Validate Indian pincode
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    if (!_pincodeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  /// Validate numeric value
  static String? validateNumeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(
    String? value, {
    String fieldName = 'Field',
  }) {
    final numericError = validateNumeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validate name (only letters and spaces)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  /// Check if value is valid email
  static bool isValidEmail(String? value) =>
      value != null && _emailRegex.hasMatch(value);

  /// Check if value is valid phone
  static bool isValidPhone(String? value) {
    if (value == null) return false;
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final phoneNumber = cleaned.length > 10 && cleaned.startsWith('91')
        ? cleaned.substring(2)
        : cleaned;
    return _phoneRegex.hasMatch(phoneNumber);
  }

  /// Check if value is valid URL
  static bool isValidUrl(String? value) =>
      value != null && _urlRegex.hasMatch(value);
}
