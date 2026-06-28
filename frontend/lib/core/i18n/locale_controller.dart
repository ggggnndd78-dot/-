import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/i18n/translation_catalog.dart';
import 'package:ghiyarak/core/i18n/translation_repository.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(
    ref.watch(localStorageServiceProvider),
    ref.watch(translationRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._storage, this._translations, this._apiClient)
      : super(AppConfig.locale) {
    _load();
  }

  final LocalStorageService _storage;
  final TranslationRepository _translations;
  final ApiClient _apiClient;

  Future<void> _load() async {
    final saved = await _storage.getLocaleCode();
    final next = saved == 'en' ? const Locale('en') : const Locale('ar');
    await _apply(next, syncUserProfile: false);
  }

  Future<void> setLocale(Locale locale) async {
    final next =
        locale.languageCode == 'en' ? const Locale('en') : const Locale('ar');
    await _apply(next, syncUserProfile: true);
  }

  Future<void> refreshCatalog() async {
    await _loadRemoteCatalog(state.languageCode);
    state = Locale(state.languageCode);
  }

  Future<void> toggle() async {
    await setLocale(
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }

  Future<void> _apply(Locale next, {required bool syncUserProfile}) async {
    await _storage.setLocaleCode(next.languageCode);
    await _loadRemoteCatalog(next.languageCode);
    state = next;
    if (syncUserProfile) {
      try {
        await _apiClient.patch(
          ApiEndpoints.meLocale,
          data: <String, dynamic>{'locale': next.languageCode},
        );
      } catch (_) {}
    }
  }

  Future<void> _loadRemoteCatalog(String locale) async {
    try {
      final values = await _translations.fetchCatalog(locale);
      TranslationCatalog.merge(locale, values);
    } catch (_) {
      // The embedded catalog remains active when the API is unavailable.
    }
  }
}
