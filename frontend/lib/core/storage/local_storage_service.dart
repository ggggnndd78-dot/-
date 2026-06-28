import 'dart:convert' as dart_convert;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  static const _guestModeKey = 'guest_mode';
  static const _guestTokenKey = 'guest_token';
  static const _guestSessionIdKey = 'guest_session_id';
  static const _profileNameKey = 'profile_name';
  static const _selectedCityKey = 'selected_city';
  static const _selectedDistrictKey = 'selected_district';
  static const _setupCompleteKey = 'setup_complete';
  static const _localeCodeKey = 'locale_code';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> setGuestMode(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_guestModeKey, value);
  }

  Future<bool> isGuestMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> setGuestToken(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_guestTokenKey, value);
  }

  Future<String> getGuestToken() async {
    final prefs = await _prefs;
    return prefs.getString(_guestTokenKey) ?? '';
  }

  Future<void> setGuestSessionId(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_guestSessionIdKey, value);
  }

  Future<String> getGuestSessionId() async {
    final prefs = await _prefs;
    return prefs.getString(_guestSessionIdKey) ?? '';
  }

  Future<void> clearGuestSession() async {
    final prefs = await _prefs;
    await prefs.remove(_guestModeKey);
    await prefs.remove(_guestTokenKey);
    await prefs.remove(_guestSessionIdKey);
  }

  Future<void> setProfileName(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_profileNameKey, value);
  }

  Future<String> getProfileName() async {
    final prefs = await _prefs;
    return prefs.getString(_profileNameKey) ?? '';
  }

  Future<void> setSelectedCity(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_selectedCityKey, value);
  }

  Future<String> getSelectedCity() async {
    final prefs = await _prefs;
    return prefs.getString(_selectedCityKey) ?? '';
  }

  Future<void> setSelectedDistrict(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_selectedDistrictKey, value);
  }

  Future<String> getSelectedDistrict() async {
    final prefs = await _prefs;
    return prefs.getString(_selectedDistrictKey) ?? '';
  }

  Future<void> setProviderOrganizationType(String value) async {
    final prefs = await _prefs;
    await prefs.setString('provider_onboarding_org_type', value);
  }

  Future<String> getProviderOrganizationType() async {
    final prefs = await _prefs;
    return prefs.getString('provider_onboarding_org_type') ?? '';
  }

  Future<void> setProviderOrganizationId(String value) async {
    final prefs = await _prefs;
    await prefs.setString('provider_onboarding_org_id', value);
  }

  Future<String> getProviderOrganizationId() async {
    final prefs = await _prefs;
    return prefs.getString('provider_onboarding_org_id') ?? '';
  }

  Future<void> setLocaleCode(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_localeCodeKey, value);
  }

  Future<String> getLocaleCode() async {
    final prefs = await _prefs;
    return prefs.getString(_localeCodeKey) ?? '';
  }

  Future<void> setSetupComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_setupCompleteKey, value);
  }

  Future<bool> isSetupComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  Future<List<Map<String, dynamic>>> getFavoriteListings() async {
    final prefs = await _prefs;
    final raw = prefs.getString('favorite_listings');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = raw.startsWith('[') ? raw : '[]';
      final list = (dart_convert.jsonDecode(decoded) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isFavoriteListing(String listingId) async {
    final items = await getFavoriteListings();
    return items.any((item) => item['id']?.toString() == listingId);
  }

  Future<void> toggleFavoriteListing(Map<String, dynamic> listing) async {
    final id = listing['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final prefs = await _prefs;
    final items = await getFavoriteListings();
    final existing = items.indexWhere((item) => item['id']?.toString() == id);
    if (existing >= 0) {
      items.removeAt(existing);
    } else {
      items.add(listing);
    }
    await prefs.setString(
      'favorite_listings',
      dart_convert.jsonEncode(items),
    );
  }

  Future<Map<String, dynamic>?> getSelectedVehicle() async {
    final prefs = await _prefs;
    final raw = prefs.getString('selected_vehicle');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = dart_convert.jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelectedVehicle(Map<String, dynamic>? vehicle) async {
    final prefs = await _prefs;
    if (vehicle == null) {
      await prefs.remove('selected_vehicle');
    } else {
      await prefs.setString(
        'selected_vehicle',
        dart_convert.jsonEncode(vehicle),
      );
    }
  }

  Future<void> clearSessionData() async {
    final prefs = await _prefs;
    await prefs.remove(_guestModeKey);
    await prefs.remove(_guestTokenKey);
    await prefs.remove(_guestSessionIdKey);
    await prefs.remove(_profileNameKey);
    await prefs.remove(_selectedCityKey);
    await prefs.remove(_selectedDistrictKey);
    await prefs.remove(_setupCompleteKey);
    // Locale is intentionally preserved across logout/session clearing.
    await prefs.remove('customer_vehicles');
    await prefs.remove('selected_vehicle');
    await prefs.remove('favorite_listings');
    await prefs.remove('provider_onboarding_org_type');
    await prefs.remove('provider_onboarding_org_id');
  }
}
