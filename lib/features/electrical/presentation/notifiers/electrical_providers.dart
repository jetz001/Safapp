import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_superapp/features/electrical/data/models/electrical_inspection_model.dart';
import 'package:safety_superapp/features/electrical/data/models/circuit_breaker_model.dart';
import 'package:safety_superapp/features/electrical/data/repositories/electrical_repository.dart';

final electricalRepositoryProvider = Provider<ElectricalRepository>((ref) {
  return ElectricalRepository();
});

// ==========================================================
// 1. Annual Inspection Providers
// ==========================================================

class ElectricalInspectionListNotifier extends AsyncNotifier<List<ElectricalInspectionModel>> {
  @override
  Future<List<ElectricalInspectionModel>> build() async {
    final repo = ref.read(electricalRepositoryProvider);
    return await repo.getElectricalInspections();
  }

  Future<int> saveInspection(ElectricalInspectionModel record) async {
    final repo = ref.read(electricalRepositoryProvider);
    int id;
    if (record.id == null) {
      id = await repo.insertElectricalInspection(record);
    } else {
      await repo.updateElectricalInspection(record);
      id = record.id!;
    }
    ref.invalidateSelf();
    return id;
  }

  Future<int> deleteInspection(int id) async {
    final repo = ref.read(electricalRepositoryProvider);
    final count = await repo.deleteElectricalInspection(id);
    ref.invalidateSelf();
    return count;
  }
}

final electricalInspectionListProvider = AsyncNotifierProvider<ElectricalInspectionListNotifier, List<ElectricalInspectionModel>>(
  ElectricalInspectionListNotifier.new,
);

final latestElectricalInspectionProvider = Provider<ElectricalInspectionModel?>((ref) {
  final inspectionsAsync = ref.watch(electricalInspectionListProvider);
  final inspections = inspectionsAsync.value ?? [];
  return inspections.isNotEmpty ? inspections.first : null;
});

// ==========================================================
// 2. Circuit Breakers & LOTO Providers
// ==========================================================

class CircuitBreakerListNotifier extends AsyncNotifier<List<CircuitBreakerModel>> {
  @override
  Future<List<CircuitBreakerModel>> build() async {
    final repo = ref.read(electricalRepositoryProvider);
    return await repo.getCircuitBreakers();
  }

  Future<int> saveBreaker(CircuitBreakerModel breaker) async {
    final repo = ref.read(electricalRepositoryProvider);
    int id;
    if (breaker.id == null) {
      id = await repo.insertCircuitBreaker(breaker);
    } else {
      await repo.updateCircuitBreaker(breaker);
      id = breaker.id!;
    }
    ref.invalidateSelf();
    return id;
  }

  Future<int> deleteBreaker(int id) async {
    final repo = ref.read(electricalRepositoryProvider);
    final count = await repo.deleteCircuitBreaker(id);
    ref.invalidateSelf();
    return count;
  }

  Future<void> toggleLock({
    required int id,
    required bool isLocked,
    String? lockoutTagNo,
    String? lockedBy,
    bool? zeroEnergyVerified,
  }) async {
    final repo = ref.read(electricalRepositoryProvider);
    await repo.toggleBreakerLock(
      id: id,
      isLocked: isLocked,
      lockoutTagNo: lockoutTagNo,
      lockedBy: lockedBy,
      zeroEnergyVerified: zeroEnergyVerified,
    );
    ref.invalidateSelf();
  }
}

final circuitBreakerListProvider = AsyncNotifierProvider<CircuitBreakerListNotifier, List<CircuitBreakerModel>>(
  CircuitBreakerListNotifier.new,
);

final lockedBreakersCountProvider = Provider<int>((ref) {
  final listAsync = ref.watch(circuitBreakerListProvider);
  final list = listAsync.value ?? [];
  return list.where((b) => b.isLocked).length;
});
