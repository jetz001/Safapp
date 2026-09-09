import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/crane_inspection_model.dart';
import '../../data/models/boiler_inspection_model.dart';
import '../../data/models/machinery_asset_model.dart';
import '../../data/repositories/machinery_repository.dart';

final machineryRepositoryProvider = Provider<MachineryRepository>((ref) {
  return MachineryRepository();
});

// ================= CRANES =================
class CraneListNotifier extends AsyncNotifier<List<CraneInspectionModel>> {
  @override
  Future<List<CraneInspectionModel>> build() async {
    final repo = ref.read(machineryRepositoryProvider);
    return await repo.getCraneInspections();
  }

  Future<void> saveCrane(CraneInspectionModel item) async {
    final repo = ref.read(machineryRepositoryProvider);
    if (item.id == null) {
      await repo.insertCraneInspection(item);
    } else {
      await repo.updateCraneInspection(item);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteCrane(int id) async {
    final repo = ref.read(machineryRepositoryProvider);
    await repo.deleteCraneInspection(id);
    ref.invalidateSelf();
  }
}

final craneInspectionListProvider =
    AsyncNotifierProvider<CraneListNotifier, List<CraneInspectionModel>>(
  CraneListNotifier.new,
);

// ================= BOILERS =================
class BoilerListNotifier extends AsyncNotifier<List<BoilerInspectionModel>> {
  @override
  Future<List<BoilerInspectionModel>> build() async {
    final repo = ref.read(machineryRepositoryProvider);
    return await repo.getBoilerInspections();
  }

  Future<void> saveBoiler(BoilerInspectionModel item) async {
    final repo = ref.read(machineryRepositoryProvider);
    if (item.id == null) {
      await repo.insertBoilerInspection(item);
    } else {
      await repo.updateBoilerInspection(item);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteBoiler(int id) async {
    final repo = ref.read(machineryRepositoryProvider);
    await repo.deleteBoilerInspection(id);
    ref.invalidateSelf();
  }
}

final boilerInspectionListProvider =
    AsyncNotifierProvider<BoilerListNotifier, List<BoilerInspectionModel>>(
  BoilerListNotifier.new,
);

// ================= MACHINERY ASSETS =================
class MachineryAssetListNotifier extends AsyncNotifier<List<MachineryAssetModel>> {
  @override
  Future<List<MachineryAssetModel>> build() async {
    final repo = ref.read(machineryRepositoryProvider);
    return await repo.getMachineryAssets();
  }

  Future<void> saveAsset(MachineryAssetModel item) async {
    final repo = ref.read(machineryRepositoryProvider);
    if (item.id == null) {
      await repo.insertMachineryAsset(item);
    } else {
      await repo.updateMachineryAsset(item);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(int id) async {
    final repo = ref.read(machineryRepositoryProvider);
    await repo.deleteMachineryAsset(id);
    ref.invalidateSelf();
  }

  Future<void> setStatus(int id, String status) async {
    final repo = ref.read(machineryRepositoryProvider);
    await repo.updateAssetStatus(id, status);
    ref.invalidateSelf();
  }
}

final machineryAssetListProvider =
    AsyncNotifierProvider<MachineryAssetListNotifier, List<MachineryAssetModel>>(
  MachineryAssetListNotifier.new,
);

// ================= KPI SUMMARY =================
class MachineryKpiSummary {
  final int totalCranes;
  final int craneOverdue;
  final int craneWarning;
  final int totalBoilers;
  final int boilerOverdue;
  final int totalAssets;
  final int defectiveAssets;

  const MachineryKpiSummary({
    required this.totalCranes,
    required this.craneOverdue,
    required this.craneWarning,
    required this.totalBoilers,
    required this.boilerOverdue,
    required this.totalAssets,
    required this.defectiveAssets,
  });
}

final machineryKpiSummaryProvider = Provider<MachineryKpiSummary>((ref) {
  final cranes = ref.watch(craneInspectionListProvider).value ?? [];
  final boilers = ref.watch(boilerInspectionListProvider).value ?? [];
  final assets = ref.watch(machineryAssetListProvider).value ?? [];

  final craneOverdue = cranes.where((c) => c.slaStatus == 'OVERDUE').length;
  final craneWarning = cranes.where((c) => c.slaStatus == 'WARNING').length;
  final boilerOverdue = boilers.where((b) => b.slaStatus == 'OVERDUE').length;
  final defectiveAssets = assets.where((a) => a.status == 'DEFECTIVE').length;

  return MachineryKpiSummary(
    totalCranes: cranes.length,
    craneOverdue: craneOverdue,
    craneWarning: craneWarning,
    totalBoilers: boilers.length,
    boilerOverdue: boilerOverdue,
    totalAssets: assets.length,
    defectiveAssets: defectiveAssets,
  );
});
