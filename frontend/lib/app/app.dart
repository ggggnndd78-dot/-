import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/app_router.dart';
import 'package:ghiyarak/core/theme/app_theme.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';

class GhiyarakApp extends ConsumerWidget {
  const GhiyarakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr('app.name'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkPremium,
      routerConfig: router,
      builder: (context, child) {
        final direction = AppLocalizations.of(context).textDirection;
        return Directionality(
            textDirection: direction, child: child ?? const SizedBox.shrink());
      },
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
    );
  }
}
