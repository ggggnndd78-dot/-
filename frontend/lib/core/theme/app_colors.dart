import 'package:flutter/material.dart';

/// Central Ghiyarak design palette.
///
/// The colors are intentionally close to the two reference apps the user
/// provided: deep professional navy backgrounds, teal/blue interactive accents,
/// subtle borders, and readable light text. Keep using these constants instead
/// of hardcoded colors so all roles and dashboards stay visually unified.
class AppColors {
  // Brand palette inspired by modern Saudi hackathon / Tuwaiq-style products:
  // deep navy foundation, vibrant teal actions, and warm gold highlights.
  static const primary = Color(0xFF1ED8B5);
  static const primaryDark = Color(0xFF041019);
  static const primaryDeep = Color(0xFF0C8D78);
  static const headerFooter = Color(0xFF041019);
  static const headerFooterEnd = Color(0xFF10233A);
  static const headerFooterAccent = Color(0xFF1ED8B5);
  static const secondary = Color(0xFFD7B76D);
  static const accent = Color(0xFF27C6D9);
  static const accentSoft = Color(0x1F1ED8B5);
  static const gold = secondary;

  // Backgrounds & surfaces
  static const backgroundBeige = Color(0xFF06111B);
  static const backgroundBlue = Color(0xFF091522);
  static const background = Color(0xFF06111B);
  static const surface = Color(0xFF0F1B2D);
  static const surfaceAlt = Color(0xFF0B1626);
  static const surfaceTint = Color(0xFF17283D);
  static const surfaceHigh = Color(0xFF182B42);
  static const surfaceHigher = Color(0xFF20324A);
  static const surfaceVariant = surfaceTint;

  // Text & misc
  static const textPrimary = Color(0xFFF6F9FF);
  static const textSecondary = Color(0xFFA3B1C8);
  static const textMuted = Color(0xFF71839F);
  static const textOnDark = Color(0xFFF6F9FF);

  // Icons
  static const iconAccent = Color(0xFF38E1C4);
  static const iconMuted = Color(0xFF71839F);
  static const border = Color(0xFF2A425F);
  static const borderSoft = Color(0xFF34506F);
  static const shadow = Color(0xCC020A13);

  // Status
  static const success = Color(0xFF2ED6A1);
  static const safe = success;
  static const error = Color(0xFFFF6B81);
  static const danger = error;
  static const warning = Color(0xFFFFC857);
  static const info = Color(0xFF6CB8FF);

  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF041019),
      Color(0xFF071626),
      Color(0xFF10233A),
      Color(0xFF0C8D78),
    ],
    stops: [0, 0.42, 0.78, 1],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF091522),
      Color(0xFF06111B),
      Color(0xFF041019),
    ],
    stops: [0, 0.48, 1],
  );
}
