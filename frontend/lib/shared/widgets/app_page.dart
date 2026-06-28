import 'package:flutter/material.dart';
import 'package:ghiyarak/core/platform/platform_layout.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: PlatformLayout.contentMaxWidth(context)),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.pagePadding),
          child: child,
        ),
      ),
    );
  }
}
