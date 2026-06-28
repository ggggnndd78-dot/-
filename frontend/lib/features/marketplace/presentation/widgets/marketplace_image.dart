import 'package:flutter/material.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';

class MarketplaceImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final IconData icon;
  final double iconSize;

  const MarketplaceImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.icon = Icons.inventory_2_outlined,
    this.iconSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final url = _usableUrl(imageUrl);

    if (url == null) {
      return _MarketplaceImagePlaceholder(icon: icon, iconSize: iconSize);
    }

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _MarketplaceImagePlaceholder(
          icon: icon,
          iconSize: iconSize,
          isLoading: true,
        );
      },
      errorBuilder: (_, __, ___) =>
          _MarketplaceImagePlaceholder(icon: icon, iconSize: iconSize),
    );
  }

  static String? _usableUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    if (trimmed.startsWith('/uploads/')) {
      final base = Uri.tryParse(AppConfig.baseUrl);
      if (base == null || !base.hasScheme || base.host.isEmpty) return null;
      return '${base.origin}$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    if (host.endsWith('.test') || host == 'localhost') return null;

    return trimmed;
  }
}

class _MarketplaceImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool isLoading;

  const _MarketplaceImagePlaceholder({
    required this.icon,
    required this.iconSize,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.surface,
            AppColors.surfaceAlt,
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Container(
                width: iconSize + 22,
                height: iconSize + 22,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: iconSize,
                ),
              ),
      ),
    );
  }
}
