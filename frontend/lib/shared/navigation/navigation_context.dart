import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

TextDirection resolveTextDirection(Locale locale) {
  return locale.languageCode.toLowerCase().startsWith('ar')
      ? TextDirection.rtl
      : TextDirection.ltr;
}

bool isRtlLocale(Locale locale) =>
    resolveTextDirection(locale) == TextDirection.rtl;

String currentLocationOf(BuildContext context, {String fallback = '/'}) {
  final router = GoRouter.maybeOf(context);
  final routerPath = router?.routeInformationProvider.value.uri.path;
  if (routerPath != null && routerPath.isNotEmpty) return routerPath;

  final modalName = ModalRoute.of(context)?.settings.name;
  if (modalName != null && modalName.isNotEmpty) {
    final modalPath = Uri.tryParse(modalName)?.path;
    if (modalPath != null && modalPath.isNotEmpty) return modalPath;
  }

  final basePath = Uri.base.path;
  if (basePath.isNotEmpty) return basePath;
  return fallback;
}

Map<String, String> currentQueryParametersOf(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    return router.routeInformationProvider.value.uri.queryParameters;
  }

  final modalName = ModalRoute.of(context)?.settings.name;
  if (modalName == null || modalName.isEmpty) {
    return const <String, String>{};
  }

  return Uri.tryParse(modalName)?.queryParameters ?? const <String, String>{};
}
