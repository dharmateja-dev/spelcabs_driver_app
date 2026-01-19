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
  /// Accepted patterns (ignoring case and separators):
  /// - KA01AB1234
  /// - KA-01-AB-1234
  /// - DL1C1234
  ///
  /// Rules:
  /// - Must start with 2 letters (State code)
  /// - Followed by 1-2 digits (District code)
  /// - Followed by 0-3 letters (Series - optional)
  /// - Ends with 4 digits (Unique number)
  static String? validateVehicleNumber(String? number) {
    if (number == null || number.trim().isEmpty) {
      return 'Vehicle number is required';
    }

    // Remove spaces and hyphens for validation
    final cleanNumber =
        number.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    if (cleanNumber.length < 2) {
      return 'Please enter a valid vehicle number (e.g. KA01AB1234)';
    }

    // Extract first 2 characters as state code
    final String stateCode = cleanNumber.substring(0, 2);

    // List of valid Indian State/UT codes
    // Note: 'TS' and 'TG' are both used for Telangana in different contexts/times, including both for robustness.
    // 'OR' was old Odisha code, 'OD' is new. Included 'OR' for older vehicles.
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
      return 'Invalid state code. Please enter a valid Indian vehicle number.';
    }

    // Regex explanation:
    // ^[A-Z]{2} : Starts with 2 letters (State)
    // [0-9]{1,2} : 1 or 2 digits (District)
    // [A-Z]{0,3} : 0 to 3 letters (Series)
    // [0-9]{4}$ : Ends with 4 digits (Number)
    final RegExp standardRegex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]*[0-9]{4}$');

    if (!standardRegex.hasMatch(cleanNumber)) {
      return 'Please enter a valid vehicle number (e.g. KA01AB1234)';
    }

    return null;
  }
}
