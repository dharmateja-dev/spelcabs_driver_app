/// Utility class for validating form fields.
/// This provides centralized validation logic for email and phone numbers
/// with consistent error messages across the app.
class ValidationUtils {
  /// Email validation regex pattern
  /// Matches standard email format: local@domain.tld
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Phone number validation: must contain only digits
  static final RegExp _phoneDigitsOnlyRegex = RegExp(r'^[0-9]+$');

  /// Validates an email address.
  /// Returns null if valid, or an error message if invalid.
  ///
  /// Validation rules:
  /// - Must not be empty
  /// - Must contain '@' and a valid domain with TLD
  ///
  /// Example valid emails: test@example.com, user.name@domain.co.in
  /// Example invalid emails: test, test@, test@.com, @example.com
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedEmail = email.trim();

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a phone number.
  /// Returns null if valid, or an error message if invalid.
  ///
  /// Validation rules:
  /// - Must not be empty
  /// - Must contain only digits (0-9)
  /// - Must be exactly 10 digits
  ///
  /// Note: The country code is handled separately by the CountryCodePicker widget.
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmedPhone = phone.trim();

    // Check if phone number contains only digits
    if (!_phoneDigitsOnlyRegex.hasMatch(trimmedPhone)) {
      return 'Phone number must contain only digits';
    }

    // Check if phone number is exactly 10 digits
    if (trimmedPhone.length != 10) {
      return 'Please enter a valid 10-digit number';
    }

    return null;
  }

  /// Validates a phone number with flexible length (for login scenarios).
  /// Returns null if valid, or an error message if invalid.
  ///
  /// Validation rules:
  /// - Must not be empty
  /// - Must contain only digits (0-9)
  /// - Must be between 6-15 digits
  static String? validatePhoneFlexible(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmedPhone = phone.trim();

    // Check if phone number contains only digits
    if (!_phoneDigitsOnlyRegex.hasMatch(trimmedPhone)) {
      return 'Phone number must contain only digits';
    }

    // Check minimum length
    if (trimmedPhone.length < 6) {
      return 'Phone number must be at least 6 digits';
    }

    // Check maximum length
    if (trimmedPhone.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }

    return null;
  }

  /// Validates a vehicle number (India format).
  /// Returns null if valid, or an error message if invalid.
  ///
  /// Validation Rules:
  /// 1. Mandatory - must not be empty
  /// 2. Format - valid Indian vehicle number format (8-10 chars)
  /// 3. Character restrictions - no special characters or emojis
  /// 4. Case handling - accepts lowercase, auto-converts to uppercase
  /// 5. Whitespace validation - no leading/trailing/multiple spaces
  ///
  /// Accepted patterns (ignoring case):
  /// - KA01AB1234
  /// - DL5CAF5030
  static String? validateVehicleNumber(String? number) {
    // 1. Mandatory validation - must not be empty
    if (number == null || number.isEmpty) {
      return 'Please enter vehicle number';
    }

    // 6. Whitespace validation - check for only spaces
    if (number.trim().isEmpty) {
      return 'Invalid vehicle number format';
    }

    // 6. Check for multiple consecutive spaces
    if (RegExp(r'\s{2,}').hasMatch(number)) {
      return 'Invalid vehicle number format';
    }

    // 6. Check for leading or trailing spaces
    if (number != number.trim()) {
      return 'Invalid vehicle number format';
    }

    // Remove spaces and hyphens for format validation (allowed separators)
    final cleanNumber = number.replaceAll(RegExp(r'[\s-]'), '');

    // 3. Character restrictions - check for special characters and emojis
    // Only allow letters and numbers after removing allowed separators
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanNumber)) {
      return 'Vehicle number should contain only letters and numbers';
    }

    // 2. Format validation - length check
    if (cleanNumber.length < 8) {
      return 'Enter a valid vehicle number';
    }

    if (cleanNumber.length > 10) {
      return 'Enter a valid vehicle number';
    }

    // Convert to uppercase for pattern matching (4. Case handling)
    final upperNumber = cleanNumber.toUpperCase();

    // Extract first 2 characters as state code
    final String stateCode = upperNumber.substring(0, 2);

    // List of valid Indian State/UT codes
    const Set<String> validStateCodes = {
      'AN',
      'AP',
      'AR',
      'AS',
      'BR',
      'CG',
      'CH',
      'DD',
      'DL',
      'DN',
      'GA',
      'GJ',
      'HR',
      'HP',
      'JH',
      'JK',
      'KA',
      'KL',
      'LA',
      'LD',
      'MH',
      'ML',
      'MN',
      'MP',
      'MZ',
      'NL',
      'OD',
      'OR',
      'PB',
      'PY',
      'RJ',
      'SK',
      'TN',
      'TR',
      'TS',
      'TG',
      'UK',
      'UA',
      'UP',
      'WB'
    };

    if (!validStateCodes.contains(stateCode)) {
      return 'Enter a valid vehicle number';
    }

    // Regex for valid Indian vehicle number pattern:
    // ^[A-Z]{2} : Starts with 2 letters (State code)
    // [0-9]{1,2} : 1 or 2 digits (District code)
    // [A-Z]{0,3} : 0 to 3 letters (Series - optional)
    // [0-9]{4}$ : Ends with 4 digits (Unique number)
    final RegExp standardRegex =
        RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$');

    if (!standardRegex.hasMatch(upperNumber)) {
      return 'Enter a valid vehicle number';
    }

    return null;
  }

  /// Normalizes a vehicle number to uppercase format for storage.
  /// Removes spaces and hyphens, converts to uppercase.
  /// Use this before saving to database or comparing.
  static String normalizeVehicleNumber(String number) {
    return number.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  }
}
