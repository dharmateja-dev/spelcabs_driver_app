import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TextFieldThem {
  const TextFieldThem({Key? key});

  /// Builds a validated text field with error state support.
  /// When [errorText] is not null, the field shows a red border and
  /// displays the error message below the field.
  ///
  /// This is the preferred method for fields that require on-submit validation.
  static Widget buildValidatedTextField(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    String? errorText,
    TextInputType keyBoardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enable = true,
    int maxLine = 1,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixIcon,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool hasError = errorText != null && errorText.isNotEmpty;

    // Determine border color based on error state
    final normalBorderColor = themeChange.getThem()
        ? AppColors.darkTextFieldBorder
        : AppColors.textFieldBorder;
    const errorBorderColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          enabled: enable,
          keyboardType: keyBoardType,
          textCapitalization: textCapitalization,
          maxLines: maxLine,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            contentPadding: EdgeInsets.only(
              left: prefixIcon != null ? 0 : 10,
              right: 10,
              top: maxLine == 1 ? 12 : 10,
              bottom: maxLine == 1 ? 12 : 10,
            ),
            prefixIcon: prefixIcon,
            disabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: themeChange.getThem() ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        // Inline error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a validated text field specifically for phone numbers with country code picker.
  /// When [errorText] is not null, the field shows a red border and
  /// displays the error message below the field.
  static Widget buildValidatedPhoneField(
    BuildContext context, {
    required TextEditingController controller,
    required Widget countryCodePicker,
    String? errorText,
    String hintText = "Phone number",
    bool enable = true,
    int? maxLength,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool hasError = errorText != null && errorText.isNotEmpty;

    // Determine border color based on error state
    final normalBorderColor = themeChange.getThem()
        ? AppColors.darkTextFieldBorder
        : AppColors.textFieldBorder;
    const errorBorderColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          enabled: enable,
          keyboardType: const TextInputType.numberWithOptions(
              signed: false, decimal: false),
          maxLength: maxLength,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: GoogleFonts.poppins(
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: countryCodePicker,
            counterText: '', // Hide the character counter
            disabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : normalBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: themeChange.getThem() ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        // Inline error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  static buildTextFiled(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    TextInputType keyBoardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enable = true,
    int maxLine = 1,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return TextFormField(
        controller: controller,
        textAlign: TextAlign.start,
        enabled: enable,
        keyboardType: keyBoardType,
        textCapitalization: textCapitalization,
        maxLines: maxLine,
        style: GoogleFonts.poppins(
            color: themeChange.getThem() ? Colors.white : Colors.black),
        decoration: InputDecoration(
            filled: true,
            fillColor: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            contentPadding: EdgeInsets.only(
                left: 10, right: 10, top: maxLine == 1 ? 0 : 10),
            disabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            hintText: hintText));
  }

  static buildTextFiledWithPrefixIcon(BuildContext context,
      {required String hintText,
      required TextEditingController controller,
      required Widget prefix,
      TextInputType keyBoardType = TextInputType.text,
      bool enable = true,
      ValueChanged<String>? onChanged}) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return TextFormField(
        controller: controller,
        textAlign: TextAlign.start,
        enabled: enable,
        keyboardType: keyBoardType,
        style: GoogleFonts.poppins(
            color: themeChange.getThem() ? Colors.white : Colors.black),
        onChanged: onChanged,
        decoration: InputDecoration(
            prefix: prefix,
            filled: true,
            fillColor: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            disabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            hintText: hintText));
  }

  static buildTextFiledWithSuffixIcon(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    required Widget suffixIcon,
    TextInputType keyBoardType = TextInputType.text,
    bool enable = true,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return TextFormField(
        controller: controller,
        textAlign: TextAlign.start,
        enabled: enable,
        keyboardType: keyBoardType,
        style: GoogleFonts.poppins(
            color: themeChange.getThem() ? Colors.white : Colors.black),
        decoration: InputDecoration(
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            disabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1),
            ),
            hintText: hintText));
  }
}
