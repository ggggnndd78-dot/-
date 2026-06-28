import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepository(ref.watch(apiClientProvider));
});

class TranslationRepository {
  TranslationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, String>> fetchCatalog(String locale) async {
    final response = await _apiClient.get(
      ApiEndpoints.translationCatalog,
      queryParameters: <String, dynamic>{
        'locale': locale,
        'platform': 'FLUTTER',
      },
    );
    final rawData = response.data is Map ? response.data['data'] : null;
    final translations = rawData is Map ? rawData['translations'] : null;
    if (translations is! Map) return const <String, String>{};
    return translations
        .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
  }
}
