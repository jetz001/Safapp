import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_superapp/features/electrical/data/models/electrical_inspection_model.dart';
import 'package:safety_superapp/features/electrical/data/repositories/electrical_repository.dart';

final electricalRepositoryProvider = Provider<ElectricalRepository>((ref) {
  return ElectricalRepository();
});

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
