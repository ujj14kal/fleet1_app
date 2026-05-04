import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.5,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, height: 1.4,
    letterSpacing: 0.5, 
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, height: 1.4,
  );

  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white, height: 1.2,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white, height: 1.2,
  );

  static TextStyle get navLabel => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w600, height: 1.2,
  );

  static TextStyle get shipmentId => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryAmber,
    letterSpacing: 0.5,
  );

  static TextStyle get statValue => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1,
  );

  static TextStyle get sectionHeader => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted,
    letterSpacing: 0.8, 
  );
}
