import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';

/// Visual tokens shared by merchant management pages.
///
/// These deliberately contain no navigation or business behavior.
abstract final class MerchantThemeTokens {
  static const pageBackground = Color(0xFFF5F7FA);
  static const panelBackground = Colors.white;
  static const panelBorder = Color(0xFFE2E8F0);
  static const fieldBackground = Color(0xFFF8FAFC);
  static const heading = Color(0xFF082B51);
  static const body = Color(0xFF687686);

  static const panelRadius = AppRadius.card;
  static const controlRadius = AppRadius.md;
  static const controlHeight = 52.0;

  static const panelShadow = [
    BoxShadow(
      color: Color(0x0D082B51),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primaryDeep,
      surface: panelBackground,
      onSurface: heading,
      outline: panelBorder,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: panelBorder),
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: pageBackground,
      cardTheme: CardThemeData(
        color: panelBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          side: const BorderSide(color: panelBorder),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: fieldBackground,
        labelStyle: const TextStyle(
          color: body,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(color: body),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide:
              const BorderSide(color: AppColors.primaryDeep, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(controlHeight),
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(controlHeight),
          foregroundColor: heading,
          backgroundColor: panelBackground,
          side: const BorderSide(color: panelBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
