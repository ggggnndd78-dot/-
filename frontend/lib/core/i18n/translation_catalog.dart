class TranslationCatalog {
  TranslationCatalog._();

  static final Map<String, Map<String, String>> _catalogs = {
    'ar': <String, String>{},
    'en': <String, String>{},
  };

  static void merge(String locale, Map<String, String> values) {
    final lang = locale.toLowerCase().startsWith('en') ? 'en' : 'ar';
    _catalogs.putIfAbsent(lang, () => <String, String>{}).addAll(values);
  }

  static String? value(String locale, String key) {
    final lang = locale.toLowerCase().startsWith('en') ? 'en' : 'ar';
    return _catalogs[lang]?[key];
  }

  static Map<String, String> values(String locale) {
    final lang = locale.toLowerCase().startsWith('en') ? 'en' : 'ar';
    return Map.unmodifiable(_catalogs[lang] ?? const <String, String>{});
  }
}
