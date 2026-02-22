import 'package:driver/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      primarySwatch: Colors.red,
      useMaterial3: false,
      colorScheme: ColorScheme(
          brightness: isDarkTheme ? Brightness.dark : Brightness.light,
          primary: isDarkTheme ? AppColors.darkModePrimary : AppColors.primary,
          onPrimary: Colors.white,
          secondary:
              isDarkTheme ? AppColors.darkBackground : AppColors.background,
          onSecondary: isDarkTheme ? Colors.white : Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface:
              isDarkTheme ? AppColors.darkBackground : AppColors.background,
          onSurface: isDarkTheme ? Colors.white : Colors.black),
      primaryColor: isDarkTheme ? AppColors.primary : AppColors.darkModePrimary,
      hintColor: isDarkTheme ? Colors.white38 : Colors.black38,
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: isDarkTheme ? Colors.white : Colors.black),
        ),
      ),
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      buttonTheme: ButtonThemeData(
        textTheme:
            ButtonTextTheme.primary, //  <-- dark text for light background
        colorScheme: Theme.of(context).colorScheme.copyWith(
            primary:
                isDarkTheme ? AppColors.darkModePrimary : AppColors.primary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDarkTheme ? Colors.white : Colors.black,
        selectionColor: isDarkTheme
            ? const Color(0xFF194751).withValues(alpha: 0.5)
            : const Color(0xFF194751).withValues(alpha: 0.3),
        selectionHandleColor: isDarkTheme ? Colors.white : Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDarkTheme ? AppColors.darkContainerBackground : AppColors.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        actionTextColor: isDarkTheme ? AppColors.ratingColour : Colors.white70,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDarkTheme
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        textStyle: TextStyle(
          color: isDarkTheme ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkTheme ? Colors.white : AppColors.primary,
        ),
      ),
      appBarTheme: AppBarTheme(
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle:
              GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
    );
  }
}
