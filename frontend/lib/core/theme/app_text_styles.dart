import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';

class AppTypography {
  static const display = TextStyle(
    fontSize: 28,
    height: 1.20,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static const heading = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    height: 1.55,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const bodySecondary = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
}

class AppTextStyles {
  static const heading1 = AppTypography.display;
  static const heading2 = AppTypography.heading;
  static const title = AppTypography.title;
  static const body = AppTypography.body;
  static const bodySecondary = AppTypography.bodySecondary;
  static const caption = AppTypography.caption;

  static const pageTitle = heading1;
  static const sectionTitle = heading2;
  static const cardTitle = title;
  static const bodySmall = bodySecondary;
  static const button = AppTypography.button;
}
