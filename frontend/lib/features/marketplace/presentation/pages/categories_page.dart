import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/account_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/providers/marketplace_home_providers.dart';
import 'package:ghiyarak/features/marketplace/presentation/widgets/marketplace_image.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';
import 'package:go_router/go_router.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedGroup = 'الكل';
  String? _expandedParentId;
  bool _onlyAvailable = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(marketplaceCategoriesProvider);
    final vehicleAsync = ref.watch(selectedMarketplaceVehicleProvider);
    final locationAsync = ref.watch(selectedMarketplaceLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketplaceCategoriesProvider);
              await ref.read(marketplaceCategoriesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _CategoriesHeader(
                          vehicle: vehicleAsync.valueOrNull,
                          location: locationAsync.valueOrNull,
                          onChangeVehicle: () =>
                              context.go(RouteNames.vehicles),
                          onSearch: () =>
                              context.go(RouteNames.marketplaceSearch),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SearchBox(
                          controller: _searchController,
                          onlyAvailable: _onlyAvailable,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          onToggleAvailable: (value) =>
                              setState(() => _onlyAvailable = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        categoriesAsync.when(
                          data: (categories) {
                            final groups = _groups(categories);
                            final visible = _filterCategories(categories);
                            final featured = _featuredCategories(categories);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ResultHeader(
                                  totalCount: categories.length,
                                  visibleCount: visible.length,
                                  hasQuery: _query.isNotEmpty,
                                  availableOnly: _onlyAvailable,
                                  totalListings: _sumListings(categories),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _GroupChips(
                                  groups: groups,
                                  selectedGroup: _selectedGroup,
                                  onChanged: (value) =>
                                      setState(() => _selectedGroup = value),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (featured.isNotEmpty &&
                                    _query.isEmpty &&
                                    _selectedGroup == 'الكل') ...[
                                  _SectionTitle(
                                    title: 'الأكثر استخدامًا',
                                    subtitle:
                                        'تصنيفات عليها عروض متوفرة وتفيدك في البحث السريع',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _FeaturedStrip(categories: featured),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                if (categories.isEmpty)
                                  const _StatePanel(
                                    icon: Icons.category_outlined,
                                    title: 'لا توجد تصنيفات حاليًا',
                                    message:
                                        'عند إضافة التصنيفات من لوحة الإدارة ستظهر هنا مع عدد المنتجات والعروض.',
                                  )
                                else if (visible.isEmpty)
                                  _StatePanel(
                                    icon: Icons.search_off,
                                    title: 'لا توجد نتائج مطابقة',
                                    message:
                                        'لم نجد تصنيفًا يطابق البحث أو الفلاتر الحالية. جرّب كلمة أخرى أو ألغِ فلتر المتاح فقط.',
                                  )
                                else
                                  _CategoriesList(
                                    categories: visible,
                                    expandedParentId: _expandedParentId,
                                    onToggleExpanded: (id) => setState(() {
                                      _expandedParentId =
                                          _expandedParentId == id ? null : id;
                                    }),
                                  ),
                              ],
                            );
                          },
                          loading: () => const _LoadingCategoriesList(),
                          error: (error, _) => _ErrorPanel(
                            message: error.toString(),
                            onRetry: () =>
                                ref.invalidate(marketplaceCategoriesProvider),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _CategoriesBottomNav(),
    );
  }

  List<String> _groups(List<CatalogCategory> categories) {
    final values = categories
        .map((e) => e.group.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['الكل', 'المتاح', ...values];
  }

  List<CatalogCategory> _filterCategories(List<CatalogCategory> categories) {
    final query = _query.toLowerCase();
    return categories.where((category) {
      final matchesQuery = query.isEmpty ||
          category.name.toLowerCase().contains(query) ||
          (category.nameEn ?? '').toLowerCase().contains(query) ||
          category.slug.toLowerCase().contains(query) ||
          category.children.any((child) =>
              child.name.toLowerCase().contains(query) ||
              (child.nameEn ?? '').toLowerCase().contains(query) ||
              child.slug.toLowerCase().contains(query));
      final matchesGroup = _selectedGroup == 'الكل' ||
          (_selectedGroup == 'المتاح'
              ? category.totalChildrenListings > 0
              : category.group == _selectedGroup);
      final matchesAvailability =
          !_onlyAvailable || category.totalChildrenListings > 0;
      return matchesQuery && matchesGroup && matchesAvailability;
    }).toList();
  }

  List<CatalogCategory> _featuredCategories(List<CatalogCategory> categories) {
    final items = [...categories]..sort(
        (a, b) => b.totalChildrenListings.compareTo(a.totalChildrenListings));
    return items
        .where((item) => item.totalChildrenListings > 0)
        .take(8)
        .toList();
  }

  int _sumListings(List<CatalogCategory> categories) =>
      categories.fold<int>(0, (sum, item) => sum + item.totalChildrenListings);
}

class _CategoriesHeader extends StatelessWidget {
  final Map<String, dynamic>? vehicle;
  final Map<String, String>? location;
  final VoidCallback onChangeVehicle;
  final VoidCallback onSearch;

  const _CategoriesHeader({
    required this.vehicle,
    required this.location,
    required this.onChangeVehicle,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = vehicle == null
        ? 'اختر سيارتك لفلترة أدق'
        : [
            vehicle!['makeName'] ?? vehicle!['make'],
            vehicle!['modelName'] ?? vehicle!['model'],
            vehicle!['yearValue'] ?? vehicle!['year']
          ]
            .where((item) => item != null && item.toString().isNotEmpty)
            .join(' ');
    final locationLabel = [location?['city'], location?['district']]
        .where((item) => item != null && item.isNotEmpty)
        .join(' - ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'رجوع',
              ),
              const Spacer(),
              Image.asset(
                AppConfig.logoAsset,
                height: 42,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car_filled,
                    color: Colors.white,
                    size: 34),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('تصنيفات قطع السيارات',
              style:
                  AppTextStyles.heading1.copyWith(color: AppColors.textOnDark)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تصفح القطع حسب أنظمة السيارة، ثم افتح نتائج البحث مباشرة مع الفلاتر المناسبة لسيارتك وموقعك.',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textOnDark.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ContextPill(
                  icon: Icons.directions_car,
                  label: vehicleLabel,
                  onTap: onChangeVehicle),
              _ContextPill(
                  icon: Icons.location_on_outlined,
                  label: locationLabel.isEmpty
                      ? 'الموقع غير محدد'
                      : locationLabel),
              _ContextPill(
                  icon: Icons.search, label: 'بحث مباشر', onTap: onSearch),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ContextPill({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggleAvailable;
  final bool onlyAvailable;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onlyAvailable,
    required this.onToggleAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 7))
        ],
      ),
      child: AppTileMaterial(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? const Icon(Icons.tune, color: AppColors.iconAccent)
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'مسح البحث',
                      ),
                labelText: 'ابحث عن تصنيف أو نظام في السيارة',
                hintText: 'مثال: فرامل، كهرباء، فلاتر، زيوت',
              ),
            ),
            SwitchListTile.adaptive(
              value: onlyAvailable,
              onChanged: onToggleAvailable,
              dense: true,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.iconAccent),
              title: const Text('إظهار التصنيفات التي لديها عروض متاحة فقط'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final int totalCount;
  final int visibleCount;
  final bool hasQuery;
  final bool availableOnly;
  final int totalListings;

  const _ResultHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.hasQuery,
    required this.availableOnly,
    required this.totalListings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
              hasQuery || availableOnly
                  ? '$visibleCount نتيجة'
                  : '$totalCount تصنيف',
              style: AppTextStyles.heading2),
        ),
        _MetricChip(
            label: '$totalListings عرض', icon: Icons.local_offer_outlined),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetricChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GroupChips extends StatelessWidget {
  final List<String> groups;
  final String selectedGroup;
  final ValueChanged<String> onChanged;

  const _GroupChips(
      {required this.groups,
      required this.selectedGroup,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = groups.contains(selectedGroup)
        ? selectedGroup
        : (groups.isNotEmpty ? groups.first : 'الكل');
    return DropdownButtonFormField<String>(
      initialValue: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'تصفية التصنيفات',
        prefixIcon: Icon(Icons.filter_list_rounded),
      ),
      items: groups
          .map((group) => DropdownMenuItem<String>(
                value: group,
                child: Row(
                  children: [
                    Icon(_groupIcon(group), size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(group, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  final List<CatalogCategory> categories;

  const _FeaturedStrip({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () => _openCategory(context, category),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _CategoryIconBox(category: category, size: 58),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('${category.totalChildrenListings} عرض',
                            style: AppTextStyles.bodySecondary
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final List<CatalogCategory> categories;
  final String? expandedParentId;
  final ValueChanged<String> onToggleExpanded;

  const _CategoriesList({
    required this.categories,
    required this.expandedParentId,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (wide) {
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: categories.map((category) {
              return SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _CategoryCard(
                  category: category,
                  expanded: expandedParentId == category.id,
                  onToggleExpanded: () => onToggleExpanded(category.id),
                ),
              );
            }).toList(),
          );
        }
        return Column(
          children: categories
              .map((category) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _CategoryCard(
                      category: category,
                      expanded: expandedParentId == category.id,
                      onToggleExpanded: () => onToggleExpanded(category.id),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CatalogCategory category;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _CategoryCard(
      {required this.category,
      required this.expanded,
      required this.onToggleExpanded});

  @override
  Widget build(BuildContext context) {
    final children = category.children;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: category.hasActiveListings
                ? AppColors.accent.withValues(alpha: 0.28)
                : AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 7))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _openCategory(context, category),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _CategoryIconBox(category: category, size: 68),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(category.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.title)),
                            if (category.hasCompatibleListings)
                              const Icon(Icons.verified_outlined,
                                  color: AppColors.success, size: 20),
                          ],
                        ),
                        if ((category.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(category.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySecondary
                                  .copyWith(fontSize: 12)),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _SmallInfo(
                                label: '${category.totalChildrenListings} عرض'),
                            _SmallInfo(label: '${category.productCount} منتج'),
                            if (category.deliveryCount > 0)
                              _SmallInfo(
                                  label: 'توصيل ${category.deliveryCount}'),
                            if (category.workshopCount > 0)
                              _SmallInfo(
                                  label: 'ورش ${category.workshopCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    children: [
                      Icon(Icons.arrow_forward_ios,
                          color: AppColors.iconAccent, size: 17),
                      if (children.isNotEmpty)
                        IconButton(
                          onPressed: onToggleExpanded,
                          icon: Icon(
                              expanded ? Icons.expand_less : Icons.expand_more),
                          tooltip: expanded ? 'إخفاء الفرعية' : 'عرض الفرعية',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (children.isNotEmpty && expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _ChildrenWrap(children: children),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildrenWrap extends StatelessWidget {
  final List<CatalogCategory> children;

  const _ChildrenWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children.map((child) {
        return InkWell(
          onTap: () => _openCategory(context, child),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_categoryIcon(child),
                    size: 16, color: AppColors.iconAccent),
                const SizedBox(width: 6),
                Text(child.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Text('${child.listingCount}',
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;

  const _SmallInfo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _CategoryIconBox extends StatelessWidget {
  final CatalogCategory category;
  final double size;

  const _CategoryIconBox({required this.category, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: MarketplaceImage(
          imageUrl: category.imageUrl,
          icon: _categoryIcon(category),
          iconSize: size * 0.48),
    );
  }
}

class _LoadingCategoriesList extends StatelessWidget {
  const _LoadingCategoriesList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Container(
          height: 122,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 14, width: 160, color: AppColors.surfaceAlt),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                        height: 10,
                        width: double.infinity,
                        color: AppColors.surfaceAlt),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                        height: 10, width: 120, color: AppColors.surfaceAlt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatePanel(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.iconAccent, size: 46),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25))),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.error, size: 46),
          const SizedBox(height: AppSpacing.md),
          const Text('تعذر تحميل التصنيفات', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

class _CategoriesBottomNav extends StatelessWidget {
  const _CategoriesBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, -8))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_outlined,
                label: 'الرئيسية',
                onTap: () => context.go(RouteNames.marketplaceHome)),
            _NavItem(
                icon: Icons.category,
                label: 'الأصناف',
                active: true,
                onTap: () {}),
            _NavItem(
                icon: Icons.shopping_cart_outlined,
                label: 'السلة',
                onTap: () => context.go(RouteNames.cart)),
            _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'طلباتي',
                onTap: () => context.go(RouteNames.myOrders)),
            _NavItem(
              icon: Icons.person_outline,
              label: 'حسابي',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AccountPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.secondary : Colors.white.withValues(alpha: 0.76);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

void _openCategory(BuildContext context, CatalogCategory category) {
  final params = <String, String>{
    'categoryId': category.id,
    'categoryName': category.name,
  };
  final query = params.entries
      .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
      .join('&');
  context.pushPath('${RouteNames.marketplaceSearch}?$query');
}

IconData _groupIcon(String group) {
  if (group == 'الكل') return Icons.apps;
  if (group == 'المتاح') return Icons.inventory_2_outlined;
  if (group.contains('محرك')) return Icons.settings;
  if (group.contains('فرامل')) return Icons.album_outlined;
  if (group.contains('كهرب')) return Icons.electric_bolt_outlined;
  if (group.contains('هيكل')) return Icons.car_repair;
  if (group.contains('زيوت')) return Icons.opacity;
  if (group.contains('إطارات') || group.contains('اطارات')) {
    return Icons.circle_outlined;
  }
  return Icons.category_outlined;
}

IconData _categoryIcon(CatalogCategory category) {
  final text =
      '${category.name} ${category.slug} ${category.group}'.toLowerCase();
  if (text.contains('فرامل') || text.contains('brake')) {
    return Icons.album_outlined;
  }
  if (text.contains('بطار') ||
      text.contains('كهرب') ||
      text.contains('electric')) {
    return Icons.electric_bolt_outlined;
  }
  if (text.contains('محرك') || text.contains('engine')) return Icons.settings;
  if (text.contains('فلتر') || text.contains('filter')) {
    return Icons.filter_alt_outlined;
  }
  if (text.contains('زيت') || text.contains('oil')) return Icons.opacity;
  if (text.contains('إطار') || text.contains('اطار') || text.contains('tire')) {
    return Icons.circle_outlined;
  }
  if (text.contains('هيكل') || text.contains('body')) return Icons.car_repair;
  if (text.contains('تبريد') || text.contains('cool')) return Icons.ac_unit;
  if (text.contains('تعليق') || text.contains('suspension')) {
    return Icons.settings_input_component;
  }
  return Icons.category_outlined;
}
