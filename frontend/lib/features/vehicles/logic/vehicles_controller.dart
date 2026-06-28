import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/vehicles/data/models/vehicle_model.dart';
import 'package:ghiyarak/features/vehicles/data/vehicles_repository.dart';

final vehiclesControllerProvider =
    StateNotifierProvider<VehiclesController, AsyncValue<List<VehicleModel>>>(
  (ref) {
    final repository = ref.watch(vehiclesRepositoryProvider);
    return VehiclesController(repository)..loadVehicles();
  },
);

class VehiclesController extends StateNotifier<AsyncValue<List<VehicleModel>>> {
  VehiclesController(this._repository) : super(const AsyncValue.loading());

  final VehiclesRepository _repository;

  Future<void> loadVehicles() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getVehicles();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setDefault(String id) async {
    await _repository.setDefault(id);
    await loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await _repository.deleteVehicle(id);
    await loadVehicles();
  }
}
