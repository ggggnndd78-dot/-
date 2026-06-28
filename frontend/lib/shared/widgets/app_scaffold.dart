import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/platform/platform_layout.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/layout/dashboard_shell.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';
import 'package:ghiyarak/shared/navigation/navigation_context.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget child;
  final bool showAppBar;
  final bool showBottomNav;
  final AppNavigationArea? navigationArea;
  final List<Widget>? actions;
  final String? currentLocation;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.navigationArea,
    this.actions,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = currentLocation ?? currentLocationOf(context);
    final auth = ref.watch(authControllerProvider);
    final area =
        navigationArea ?? AppNavigationConfig.effectiveAreaForPath(path, auth);
    final useDesktopShell = PlatformLayout.isDesktopShell(context);
    final locale = Localizations.localeOf(context);
    final resolvedDirection = resolveTextDirection(locale);

    if (!showAppBar) {
      return Directionality(
        textDirection: resolvedDirection,
        child: Scaffold(body: _PageBody(padded: true, child: child)),
      );
    }

    final content = Container(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (useDesktopShell)
              DashboardTopBar(
                title: title,
                actions: actions,
                area: area,
              ),
            Expanded(child: _PageBody(padded: true, child: child)),
          ],
        ),
      ),
    );

    if (useDesktopShell) {
      return Directionality(
        textDirection: resolvedDirection,
        child: _DesktopSideNavigation(
          area: area,
          currentRoute: path,
          child: content,
        ),
      );
    }

    final showMobileBack = _shouldShowMobileBack(context, area);
    final isRtl = resolvedDirection == TextDirection.rtl;
    final drawerWidth = _mobileDrawerWidth(context);

    return Directionality(
      textDirection: resolvedDirection,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          centerTitle: true,
          leading: _MobileMenuButton(area: area),
          actions: [
            if (showMobileBack) _MobileBackButton(area: area),
            if (actions != null) ...actions!,
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.lg),
            ),
          ),
        ),
        drawer: isRtl
            ? null
            : Drawer(
                width: drawerWidth,
                child: DashboardSidebar(
                  area: area,
                  currentRoute: path,
                  compact: true,
                ),
              ),
        endDrawer: isRtl
            ? Drawer(
                width: drawerWidth,
                child: DashboardSidebar(
                  area: area,
                  currentRoute: path,
                  compact: true,
                ),
              )
            : null,
        bottomNavigationBar: showBottomNav
            ? DashboardBottomNavigation(
                area: auth.isGuest ? AppNavigationArea.public : area,
                currentRoute: path,
              )
            : null,
        body: _PageBody(padded: true, child: child),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.child, required this.padded});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: SafeArea(
        child: Padding(
          padding: padded
              ? EdgeInsets.all(
                  PlatformLayout.isDesktopShell(context)
                      ? AppSpacing.xl
                      : AppSpacing.md,
                )
              : EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = PlatformLayout.contentMaxWidth(context);
              final effectiveWidth = maxContentWidth.isFinite
                  ? constraints.maxWidth.clamp(0.0, maxContentWidth).toDouble()
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
    );
  }
}

class _DesktopSideNavigation extends StatelessWidget {
  const _DesktopSideNavigation({
    required this.area,
    required this.currentRoute,
    required this.child,
  });

  final AppNavigationArea area;
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UnifiedSidebarFrame(
      area: area,
      currentRoute: currentRoute,
      child: child,
    );
  }
}

class _MobileMenuButton extends StatelessWidget {
  const _MobileMenuButton({required this.area});

  final AppNavigationArea area;

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

class _MobileBackButton extends StatelessWidget {
  const _MobileBackButton({required this.area});

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
      onPressed: () => _goMobileBackOrHome(context, area),
    );
  }
}

bool _shouldShowMobileBack(BuildContext context, AppNavigationArea area) {
  final path = currentLocationOf(context);
  final fallback = _mobileFallbackRouteForArea(area);
  return Navigator.of(context).canPop() || path != fallback;
}

void _openDirectionalDrawer(BuildContext context) {
  final scaffold = Scaffold.of(context);
  if (Directionality.of(context) == TextDirection.rtl) {
    scaffold.openEndDrawer();
  } else {
    scaffold.openDrawer();
  }
}

void _goMobileBackOrHome(BuildContext context, AppNavigationArea area) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).maybePop();
    return;
  }
  final fallback = _mobileFallbackRouteForArea(area);
  if (currentLocationOf(context) != fallback) context.go(fallback);
}

String _mobileFallbackRouteForArea(AppNavigationArea area) {
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
