import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/contractor_repository.dart';
import '../../domain/models/contractor_models.dart';

final contractorRepoProvider = Provider<ContractorRepository>((ref) {
  return ContractorRepository();
});

// --------------------------------------------------------------------------
// 1. Companies Notifier
// --------------------------------------------------------------------------
class ContractorCompaniesNotifier extends AsyncNotifier<List<ContractorCompany>> {
  @override
  Future<List<ContractorCompany>> build() async {
    final repo = ref.watch(contractorRepoProvider);
    return await repo.getAllContractors();
  }

  Future<int> saveCompany(ContractorCompany company) async {
    final repo = ref.read(contractorRepoProvider);
    final id = await repo.saveContractor(company);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteCompany(int id) async {
    final repo = ref.read(contractorRepoProvider);
    await repo.deleteContractor(id);
    ref.invalidateSelf();
  }
}

final contractorCompaniesProvider =
    AsyncNotifierProvider<ContractorCompaniesNotifier, List<ContractorCompany>>(ContractorCompaniesNotifier.new);

// --------------------------------------------------------------------------
// 2. Workers Notifier
// --------------------------------------------------------------------------
class ContractorWorkersNotifier extends AsyncNotifier<List<ContractorWorker>> {
  @override
  Future<List<ContractorWorker>> build() async {
    final repo = ref.watch(contractorRepoProvider);
    return await repo.getAllWorkers();
  }

  Future<int> saveWorker(ContractorWorker worker, {String? newPhotoPath, String? newCertPath}) async {
    final repo = ref.read(contractorRepoProvider);
    String? finalPhoto = worker.photoPath;
    String? finalCert = worker.certFilePath;

    if (newPhotoPath != null) {
      finalPhoto = await repo.persistFile(newPhotoPath, prefix: 'worker_photo');
    }
    if (newCertPath != null) {
      finalCert = await repo.persistFile(newCertPath, prefix: 'worker_cert');
    }

    final toSave = worker.copyWith(photoPath: finalPhoto, certFilePath: finalCert);
    final id = await repo.saveWorker(toSave);
    ref.invalidateSelf();
    // Also refresh company worker count
    ref.invalidate(contractorCompaniesProvider);
    return id;
  }

  Future<void> deleteWorker(int id) async {
    final repo = ref.read(contractorRepoProvider);
    await repo.deleteWorker(id);
    ref.invalidateSelf();
    ref.invalidate(contractorCompaniesProvider);
  }
}

final contractorWorkersProvider =
    AsyncNotifierProvider<ContractorWorkersNotifier, List<ContractorWorker>>(ContractorWorkersNotifier.new);

// --------------------------------------------------------------------------
// 3. Violations Notifier
// --------------------------------------------------------------------------
class ContractorViolationsNotifier extends AsyncNotifier<List<ContractorViolation>> {
  @override
  Future<List<ContractorViolation>> build() async {
    final repo = ref.watch(contractorRepoProvider);
    return await repo.getAllViolations();
  }

  Future<int> saveViolation(ContractorViolation violation, {List<String>? newPhotoPaths}) async {
    final repo = ref.read(contractorRepoProvider);
    List<String> finalPhotos = violation.photoPaths;

    if (newPhotoPaths != null && newPhotoPaths.isNotEmpty) {
      for (final p in newPhotoPaths) {
        final saved = await repo.persistFile(p, prefix: 'violation_evidence');
        if (saved != null) finalPhotos.add(saved);
      }
    }

    final id = await repo.saveViolation(violation);
    ref.invalidateSelf();
    ref.invalidate(contractorCompaniesProvider);
    return id;
  }

  Future<void> deleteViolation(int id) async {
    final repo = ref.read(contractorRepoProvider);
    await repo.deleteViolation(id);
    ref.invalidateSelf();
    ref.invalidate(contractorCompaniesProvider);
  }
}

final contractorViolationsProvider =
    AsyncNotifierProvider<ContractorViolationsNotifier, List<ContractorViolation>>(ContractorViolationsNotifier.new);
