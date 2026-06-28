import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';

enum AppCardTone { standard, elevated, accent }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.tone = AppCardTone.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final AppCardTone tone;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = backgroundColor ?? _backgroundForTone(tone);
    final effectiveBorder =
        borderColor ?? AppColors.border.withValues(alpha: 0.72);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(color: effectiveBorder),
    );

    final cardChild = Padding(padding: padding, child: child);

    final content = Material(
      color: effectiveBackground,
      shadowColor: AppColors.shadow.withValues(alpha: 0.24),
      elevation: tone == AppCardTone.elevated ? 10 : 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? cardChild
          : InkWell(
              onTap: onTap,
              child: cardChild,
            ),
    );

    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
  }

  static Color _backgroundForTone(AppCardTone tone) {
    return switch (tone) {
      AppCardTone.standard => AppColors.surface.withValues(alpha: 0.96),
      AppCardTone.elevated => AppColors.surfaceHigh.withValues(alpha: 0.96),
      AppCardTone.accent => AppColors.surfaceAlt.withValues(alpha: 0.98),
    };
  }
}

class AppIconContainer extends StatelessWidget {
  const AppIconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
