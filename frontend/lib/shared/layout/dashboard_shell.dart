import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/platform/platform_layout.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';
import 'package:ghiyarak/shared/navigation/navigation_context.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';
import 'package:go_router/go_router.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.currentRoute,
    this.navigationArea,
    this.onRefresh,
    this.contentPadding,
    this.showSidebar = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final String? currentRoute;
  final AppNavigationArea? navigationArea;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? contentPadding;
  final bool showSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = currentRoute ?? currentLocationOf(context);
    final auth = ref.watch(authControllerProvider);
    final area =
        navigationArea ?? AppNavigationConfig.effectiveAreaForPath(path, auth);
    final effectiveRoute = currentRoute ?? path;
    final useDesktopShell = PlatformLayout.isDesktopShell(context);
    final locale = Localizations.localeOf(context);
    final resolvedDirection = resolveTextDirection(locale);
    final pagePadding = contentPadding ??
        EdgeInsets.all(useDesktopShell ? AppSpacing.xl : AppSpacing.lg);

    Widget content = Container(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardTopBar(
              title: title,
              subtitle: subtitle,
              actions: actions,
              area: area,
            ),
            Expanded(
              child: Padding(
                padding: pagePadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxContentWidth =
                        PlatformLayout.contentMaxWidth(context);
                    final effectiveWidth = maxContentWidth.isFinite
                        ? constraints.maxWidth
                            .clamp(0.0, maxContentWidth)
                            .toDouble()
                        : constraints.maxWidth;
                    return Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: effectiveWidth,
                          maxWidth: effectiveWidth,
                        ),
                        child: AppTileMaterial(child: child),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    if (useDesktopShell && showSidebar) {
      return Directionality(
        textDirection: resolvedDirection,
        child: UnifiedSidebarFrame(
          area: area,
          currentRoute: effectiveRoute,
          child: content,
        ),
      );
    }

    final isRtl = resolvedDirection == TextDirection.rtl;
    final showBack = _shouldShowBack(context, area);
    final drawerWidth = _mobileDrawerWidth(context);

    return Directionality(
      textDirection: resolvedDirection,
      child: Scaffold(
        drawer: showSidebar && !isRtl
            ? Drawer(
                width: drawerWidth,
                child: DashboardSidebar(
                  area: area,
                  currentRoute: effectiveRoute,
                  compact: true,
                ),
              )
            : null,
        endDrawer: showSidebar && isRtl
            ? Drawer(
                width: drawerWidth,
                child: DashboardSidebar(
                  area: area,
                  currentRoute: effectiveRoute,
                  compact: true,
                ),
              )
            : null,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          centerTitle: true,
          leading: showSidebar
              ? const _OpenDrawerButton()
              : (showBack ? _BackActionButton(area: area) : null),
          actions: [
            if (showSidebar && showBack) _BackActionButton(area: area),
            if (actions != null) ...actions!,
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
        ),
        bottomNavigationBar: DashboardBottomNavigation(
          area: area,
          currentRoute: effectiveRoute,
        ),
        body: content,
      ),
    );
  }
}

class UnifiedSidebarFrame extends StatefulWidget {
  const UnifiedSidebarFrame({
    super.key,
    required this.area,
    required this.currentRoute,
    required this.child,
  });

  final AppNavigationArea area;
  final String currentRoute;
  final Widget child;

  @override
  State<UnifiedSidebarFrame> createState() => _UnifiedSidebarFrameState();
}

class _UnifiedSidebarFrameState extends State<UnifiedSidebarFrame> {
  static final Map<AppNavigationArea, bool> _openStateByArea =
      <AppNavigationArea, bool>{};

  late bool _sidebarOpen;

  @override
  void initState() {
    super.initState();
    _sidebarOpen = _openStateByArea[widget.area] ?? true;
  }

  @override
  void didUpdateWidget(covariant UnifiedSidebarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) {
      _sidebarOpen = _openStateByArea[widget.area] ?? true;
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
      _openStateByArea[widget.area] = _sidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return Scaffold(
      body: Row(
        textDirection: direction,
        children: [
          if (_sidebarOpen)
            DashboardSidebar(
              area: widget.area,
              currentRoute: widget.currentRoute,
              onToggle: _toggleSidebar,
            )
          else
            _CollapsedSidebarRail(onOpen: _toggleSidebar),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _CollapsedSidebarRail extends StatelessWidget {
  const _CollapsedSidebarRail({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        border: BorderDirectional(
          end: BorderSide(color: AppColors.border.withValues(alpha: 0.60)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.34),
            blurRadius: 22,
            offset: Offset(
              Directionality.of(context) == TextDirection.rtl ? -8 : 8,
              0,
            ),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Material(
              color: AppColors.surfaceHigh.withValues(alpha: 0.72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).drawerLabel,
                icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
                onPressed: onOpen,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.headerFooterAccent,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _OpenDrawerButton extends StatelessWidget {
  const _OpenDrawerButton();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        tooltip: MaterialLocalizations.of(context).drawerLabel,
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _openDirectionalDrawer(context),
      ),
    );
  }
}

class _BackActionButton extends StatelessWidget {
  const _BackActionButton({required this.area});

  final AppNavigationArea area;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_forward_rounded
            : Icons.arrow_back_rounded,
      ),
      onPressed: () => _goBackOrHome(context, area),
    );
  }
}

void _openDirectionalDrawer(BuildContext context) {
  final scaffold = Scaffold.of(context);
  if (Directionality.of(context) == TextDirection.rtl) {
    scaffold.openEndDrawer();
  } else {
    scaffold.openDrawer();
  }
}

bool _shouldShowBack(BuildContext context, AppNavigationArea? area) {
  final path = currentLocationOf(context);
  final fallback =
      _fallbackRouteForArea(area ?? AppNavigationConfig.areaForPath(path));
  return Navigator.of(context).canPop() || path != fallback;
}

void _goBackOrHome(BuildContext context, AppNavigationArea? area) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  final path = currentLocationOf(context);
  final fallback =
      _fallbackRouteForArea(area ?? AppNavigationConfig.areaForPath(path));
  if (path != fallback) context.go(fallback);
}

String _fallbackRouteForArea(AppNavigationArea area) {
  return switch (area) {
    AppNavigationArea.admin => RouteNames.adminControlCenter,
    AppNavigationArea.merchant => RouteNames.merchantHub,
    AppNavigationArea.workshop => RouteNames.workshopOperationsHub,
    AppNavigationArea.customer => RouteNames.customerCenter,
    AppNavigationArea.finance => RouteNames.merchantFinanceOverview,
    AppNavigationArea.support => RouteNames.supportOperations,
    AppNavigationArea.warehouse => RouteNames.warehouseHub,
    AppNavigationArea.settings => RouteNames.settings,
    AppNavigationArea.public => RouteNames.marketplaceHome,
  };
}

double _mobileDrawerWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width < 420 ? width * 0.88 : width.clamp(0, 360).toDouble();
}

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({
    super.key,
    required this.area,
    required this.currentRoute,
    this.compact = false,
    this.onToggle,
  });

  final AppNavigationArea area;
  final String currentRoute;
  final bool compact;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final items = AppNavigationConfig.visibleItems(auth, area: area);
    final direction = Directionality.of(context);

    return Container(
      width: compact ? null : 292,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.surfaceAlt],
        ),
        border: BorderDirectional(
          end: BorderSide(color: AppColors.border.withValues(alpha: 0.80)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: Offset(direction == TextDirection.rtl ? -10 : 10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(area: area, onToggle: onToggle),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Column(
                      children: [
                        if (item.dividerBefore)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            child: Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.72),
                            ),
                          ),
                        DashboardSidebarTile(
                          item: item,
                          selected: AppNavigationConfig.isRouteSelected(
                            currentRoute,
                            item.route,
                          ),
                          closeDrawerOnNavigate: compact,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (!auth.isGuest && auth.isAuthenticated) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.tr('auth.logout')),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go(RouteNames.login);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends ConsumerWidget {
  const _SidebarHeader({required this.area, this.onToggle});

  final AppNavigationArea area;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final title = switch (area) {
      AppNavigationArea.admin => context.tr('admin.title'),
      AppNavigationArea.merchant => context.tr('merchant.dashboard'),
      AppNavigationArea.workshop => context.tr('workshop.dashboard'),
      AppNavigationArea.warehouse => context.tr('warehouse.dashboard'),
      AppNavigationArea.support => context.tr('support.title'),
      AppNavigationArea.customer => context.tr('customer.dashboard'),
      AppNavigationArea.public => context.tr('guest.dashboard'),
      _ => context.tr('app.name'),
    };
    final subtitle = auth.user?.displayName.isNotEmpty == true
        ? auth.user!.displayName
        : (auth.isGuest ? context.tr('auth.guest') : context.tr('app.name'));

    return AppCard(
      tone: AppCardTone.accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.primary.withValues(alpha: 0.26),
      child: Row(
        children: [
          const AppIconContainer(
            icon: Icons.directions_car_filled_rounded,
            color: AppColors.primary,
            size: 46,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).drawerLabel,
              icon: const Icon(Icons.menu_rounded),
              onPressed: onToggle,
            ),
        ],
      ),
    );
  }
}

class DashboardSidebarTile extends StatelessWidget {
  const DashboardSidebarTile({
    super.key,
    required this.item,
    required this.selected,
    this.closeDrawerOnNavigate = false,
  });

  final AppNavigationItem item;
  final bool selected;
  final bool closeDrawerOnNavigate;

  void _navigate(BuildContext context) {
    final router = GoRouter.of(context);
    final currentPath = currentLocationOf(context);
    final targetRoute = item.route;

    if (closeDrawerOnNavigate) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (currentPath != targetRoute) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go(targetRoute);
        });
      }
      return;
    }

    if (currentPath != targetRoute) {
      router.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = selected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceHigh.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.34)
                    : AppColors.border.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              children: [
                AppIconContainer(
                  icon: icon,
                  color: color,
                  size: 38,
                  iconSize: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr(item.labelKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.area,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final AppNavigationArea? area;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_shouldShowBack(context, area)) ...[
            Material(
              color: AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side:
                    BorderSide(color: AppColors.border.withValues(alpha: 0.65)),
              ),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                ),
                onPressed: () => _goBackOrHome(context, area),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle,
                ),
                if ((subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.md),
            Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: actions!),
          ],
        ],
      ),
    );
  }
}

class DashboardBottomNavigation extends ConsumerWidget {
  const DashboardBottomNavigation({
    super.key,
    required this.area,
    required this.currentRoute,
  });

  final AppNavigationArea area;
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final items = AppNavigationConfig.visibleItems(auth, area: area)
        .where((item) => !item.dividerBefore)
        .take(4)
        .toList(growable: false);

    if (items.isEmpty) return const SizedBox.shrink();

    var selectedIndex = items.indexWhere(
      (item) => AppNavigationConfig.isRouteSelected(currentRoute, item.route),
    );
    if (selectedIndex < 0) selectedIndex = 0;
    if (selectedIndex >= items.length) selectedIndex = items.length - 1;

    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon ?? item.icon),
            label: context.tr(item.labelKey),
          ),
      ],
      onDestinationSelected: (index) => context.go(items[index].route),
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.caption,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.cardTitle),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary),
                if ((caption ?? '').isNotEmpty)
                  Text(caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
            ],
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.bodySecondary),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                if ((subtitle ?? '').isNotEmpty)
                  Text(subtitle!, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconMuted),
        ],
      ),
    );
  }
}

class DashboardTableCard extends StatelessWidget {
  const DashboardTableCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: child,
      ),
    );
  }
}
