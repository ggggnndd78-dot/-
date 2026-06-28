import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final localeController = ref.read(localeControllerProvider.notifier);
    return AppScaffold(
      title: context.tr('settings.title'),
      child: ListView(
        children: [
          SectionTitle(
            title: context.tr('settings.language'),
            subtitle: context.tr('settings.language_changed'),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('settings.language'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(locale.languageCode == 'ar'
                      ? context.tr('settings.arabic')
                      : context.tr('settings.english')),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: 160,
                        child: AppButton(
                          text: context.tr('settings.arabic'),
                          isOutlined: locale.languageCode != 'ar',
                          onPressed: () =>
                              localeController.setLocale(const Locale('ar')),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: AppButton(
                          text: context.tr('settings.english'),
                          isOutlined: locale.languageCode != 'en',
                          onPressed: () =>
                              localeController.setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final content = [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.translate),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('admin.i18n_catalog'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(context.tr('common.success')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: compact ? double.infinity : 180,
                      child: AppButton(
                        text: context.tr('common.retry'),
                        onPressed: () => localeController.refreshCatalog(),
                      ),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content[0],
                        const SizedBox(height: AppSpacing.md),
                        content[1]
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: content[0]),
                      const SizedBox(width: AppSpacing.md),
                      content[1],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
