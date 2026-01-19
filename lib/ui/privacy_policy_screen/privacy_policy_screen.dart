import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DriverPrivacyPolicyScreen extends StatelessWidget {
  const DriverPrivacyPolicyScreen({Key? key}) : super(key: key);

  // ===== STYLES =====

  Text _h1(BuildContext context, String text, bool isDark) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black,
        ),
      );

  Text _h2(BuildContext context, String text, bool isDark) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      );

  Widget _p(BuildContext context, String text, bool isDark) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );

  Widget _bullets(BuildContext context, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "•  ",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Expanded(child: _p(context, e, isDark)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ===== BUILD =====

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _h1(context, 'Spelcabs Driver Privacy Policy', isDark),
            const SizedBox(height: 8),
            _p(context, 'Effective Date: March 25, 2025', isDark),
            _p(context, 'Last Updated: April 5, 2025', isDark),
            const SizedBox(height: 16),
            _p(
              context,
              'This Privacy Policy explains how Spelcabs Services LLC ("we", "our", or "us") collects, uses, and protects the personal and non-personal data of drivers ("you" or "your") who use the Spelcabs Driver App.',
              isDark,
            ),
            const SizedBox(height: 24),
            _h2(context, '1) Information We Collect', isDark),
            const SizedBox(height: 8),
            _h2(context, 'a) Account Information', isDark),
            _bullets(
                context,
                [
                  'Name, mobile number, email address, driver’s license details, vehicle details, and profile photo.'
                ],
                isDark),
            const SizedBox(height: 8),
            _h2(context, 'b) Location Information', isDark),
            _bullets(
                context,
                [
                  'We collect your real-time location when you are online.',
                  'Tracking occurs when you log in, accept a trip, and complete it.',
                  'Foreground location permissions are used for ETA, fare, and safety.',
                ],
                isDark),
            const SizedBox(height: 24),
            _h2(context, '2) How We Use Your Information', isDark),
            _bullets(
                context,
                [
                  'Provide and manage services: enable bookings, calculate fares, and display trip history.',
                  'Ensure safety and integrity: verify driver identity, prevent fraud, and monitor trips for compliance.',
                  'Communicate with you: send notifications about trips, payments, or policy updates.',
                  'Comply with laws: fulfill legal obligations and regulatory requirements.'
                ],
                isDark),
            const SizedBox(height: 24),
            _h2(context, '3) Sharing Your Information', isDark),
            _p(
                context,
                'We do not sell driver data. We share information only when necessary:',
                isDark),
            _bullets(
                context,
                [
                  'With passengers: your name, profile photo, vehicle details, and real-time location during an active trip.',
                  'With service providers: background-check services, payment processors, and technical support.',
                  'With legal authorities: when required by law or to address safety or security issues.'
                ],
                isDark),
            const SizedBox(height: 24),
            _h2(context, '4) Data Security', isDark),
            _p(
                context,
                'We implement administrative, technical, and physical safeguards—including encryption and access controls—to protect your data against unauthorized access, disclosure, alteration, or misuse.',
                isDark),
            const SizedBox(height: 24),
            _h2(context, '5) Your Choices and Rights', isDark),
            _bullets(
                context,
                [
                  'Update your account details in the Driver App settings.',
                  'Request account deletion by contacting Spelcabs Support at info@spelcabs.com.',
                  'Note: Some data may be retained as required by law or for legitimate business needs (e.g., fraud prevention, tax and regulatory compliance).'
                ],
                isDark),
            const SizedBox(height: 24),
            _h2(context, '6) Changes to This Privacy Policy', isDark),
            _p(
                context,
                'We may update this policy periodically. We will post the updated version in the app and revise the "Last Updated" date above.',
                isDark),
            const SizedBox(height: 24),
            _h2(context, '7) Contact Us', isDark),
            _p(context, 'Spelcabs Services LLC', isDark),
            _p(context, '5900 Balcones Drive, Suite 100', isDark),
            _p(context, 'Austin, TX 78731', isDark),
            _p(context, 'Email: info@spelcabs.com', isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
