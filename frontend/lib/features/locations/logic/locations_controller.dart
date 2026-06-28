import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/shared/models/location_item.dart';

class LocationsState {
  final bool loading;
  final List<LocationItem> cities;
  final List<LocationItem> districts;
  final String? error;

  const LocationsState({
    this.loading = false,
    this.cities = const [],
    this.districts = const [],
    this.error,
  });

  LocationsState copyWith({
    bool? loading,
    List<LocationItem>? cities,
    List<LocationItem>? districts,
    String? error,
  }) {
    return LocationsState(
      loading: loading ?? this.loading,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      error: error,
    );
  }
}

final locationsControllerProvider =
    StateNotifierProvider<LocationsController, LocationsState>((ref) {
  final repository = ref.watch(locationsRepositoryProvider);
  return LocationsController(repository)..loadCities();
});

class LocationsController extends StateNotifier<LocationsState> {
  final LocationsRepository _repository;

  LocationsController(this._repository) : super(const LocationsState());

  Future<void> loadCities() async {
    try {
      state = state.copyWith(loading: true, error: null);
      final cities = await _repository.fetchCities();
      state = state.copyWith(loading: false, cities: cities);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadDistricts(int cityId) async {
    try {
      state = state.copyWith(
        loading: true,
        error: null,
        districts: const [],
      );
      final districts = await _repository.fetchDistricts(cityId);
      state = state.copyWith(loading: false, districts: districts);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
