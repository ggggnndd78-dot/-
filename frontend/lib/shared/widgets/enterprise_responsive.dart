import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';

class EnterpriseBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class EnterpriseResponsiveGrid extends StatelessWidget {
  const EnterpriseResponsiveGrid(
      {super.key, required this.children, this.minTileWidth = 220});
  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = (width / minTileWidth).floor().clamp(1, 5);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: width < EnterpriseBreakpoints.mobile ? 1.55 : 1.75,
        ),
        itemBuilder: (context, index) => children[index],
      );
    });
  }
}

class EnterpriseInfoCard extends StatelessWidget {
  const EnterpriseInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            if (icon != null) Icon(icon, size: 26),
            if (icon != null) const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800))),
          ]),
          if (value != null)
            Text(value!,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
          if (subtitle != null)
            Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: content,
            ),
    );
  }
}
