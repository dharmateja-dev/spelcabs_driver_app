import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AccountDeletionPolicyScreen extends StatelessWidget {
  const AccountDeletionPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACCOUNT DELETION',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We understand that circumstances change, and you may wish to delete your Spelcabs account. Below are the methods available to you:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              themeChange,
              icon: Icons.phone_android,
              iconColor: Colors.blue,
              title: 'Option 1: Delete Your Account via the Spelcabs App',
              steps: [
                'Open the Spelcabs app on your device.',
                'Navigate to Account Settings.',
                'Select Delete Account.',
                'Confirm your decision by entering your account password or verifying via OTP.',
              ],
              note:
                  'This action is permanent and cannot be undone. All your personal data, including booking history and preferences, will be permanently deleted.',
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              themeChange,
              icon: Icons.email,
              iconColor: Colors.orange,
              title: 'Option 2: Request Account Deletion via Email',
              subtitle: 'If you prefer to delete your account through email:',
              steps: [
                'Compose an email from your registered email address to info@nextspelcabs.com.',
                'Use the subject line: Account Deletion Request.',
                'In the body of the email, include a clear statement requesting the deletion of your account. For example: "I would like to delete my Spelcabs account associated with this email address."',
              ],
              note:
                  'Our support team will process your request and confirm the deletion of your account. Please allow up to 24 hours for this process.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.withOpacity(0.15)
                    : Colors.red[50], // Darker background for dark mode
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? Colors.red.withOpacity(0.5)
                        : Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDark ? Colors.red[300] : Colors.red[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Warning',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.red[200] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Account deletion is permanent and irreversible. All your data will be lost forever.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark ? Colors.red[100] : Colors.red[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    DarkThemeProvider themeChange, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required List<String> steps,
    required String note,
  }) {
    final isDark = themeChange.getThem();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkContainerBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkContainerBorder : Colors.grey[300]!),
        boxShadow: [
          if (!isDark) // Use shadow only in light mode mostly, or subtle in dark
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.amber[50], // Dark mode amber
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark
                      ? Colors.amber.withOpacity(0.5)
                      : Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.amber[400] : Colors.amber[900],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.amber[200] : Colors.amber[900],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
