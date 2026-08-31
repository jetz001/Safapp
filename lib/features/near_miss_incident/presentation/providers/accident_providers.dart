import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/accident_repository.dart';
import '../../domain/models/accident_models.dart';

final accidentRepoProvider = Provider<AccidentRepository>((ref) {
  return AccidentRepository();
});

// --------------------------------------------------------------------------
// 1. Accident Investigations Notifier
// --------------------------------------------------------------------------
class AccidentInvestigationsNotifier extends AsyncNotifier<List<AccidentInvestigation>> {
  @override
  Future<List<AccidentInvestigation>> build() async {
    final repo = ref.watch(accidentRepoProvider);
    return await repo.getAllInvestigations();
  }

  Future<int> saveInvestigation(AccidentInvestigation investigation, {List<String>? newPhotos}) async {
    final repo = ref.read(accidentRepoProvider);
    final id = await repo.saveInvestigation(investigation, newPhotos: newPhotos);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteInvestigation(int id) async {
    final repo = ref.read(accidentRepoProvider);
    await repo.deleteInvestigation(id);
    ref.invalidateSelf();
    ref.invalidate(accidentCapaProvider);
  }
}

final accidentInvestigationsProvider =
    AsyncNotifierProvider<AccidentInvestigationsNotifier, List<AccidentInvestigation>>(AccidentInvestigationsNotifier.new);

// --------------------------------------------------------------------------
// 2. CAPA Actions Notifier
// --------------------------------------------------------------------------
class AccidentCapaNotifier extends AsyncNotifier<List<AccidentCapaAction>> {
  @override
  Future<List<AccidentCapaAction>> build() async {
    final repo = ref.watch(accidentRepoProvider);
    return await repo.getAllActions();
  }

  Future<int> saveAction(AccidentCapaAction action, {String? newEvidencePhoto}) async {
    final repo = ref.read(accidentRepoProvider);
    final id = await repo.saveAction(action, newEvidencePhoto: newEvidencePhoto);
    ref.invalidateSelf();
    ref.invalidate(accidentInvestigationsProvider);
    return id;
  }

  Future<void> deleteAction(int id) async {
    final repo = ref.read(accidentRepoProvider);
    await repo.deleteAction(id);
    ref.invalidateSelf();
    ref.invalidate(accidentInvestigationsProvider);
  }
}

final accidentCapaProvider =
    AsyncNotifierProvider<AccidentCapaNotifier, List<AccidentCapaAction>>(AccidentCapaNotifier.new);
