import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/health_repository.dart';
import '../../domain/models/health_models.dart';

final healthRepoProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

// --------------------------------------------------------------------------
// 1. Employee Health Records Notifier
// --------------------------------------------------------------------------
class HealthRecordsNotifier extends AsyncNotifier<List<EmployeeHealthRecord>> {
  @override
  Future<List<EmployeeHealthRecord>> build() async {
    final repo = ref.watch(healthRepoProvider);
    return await repo.getAllHealthRecords();
  }

  Future<int> saveRecord(EmployeeHealthRecord record, {String? newPdfPath}) async {
    final repo = ref.read(healthRepoProvider);
    final id = await repo.saveHealthRecord(record, newPdfPath: newPdfPath);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteRecord(int id) async {
    final repo = ref.read(healthRepoProvider);
    await repo.deleteHealthRecord(id);
    ref.invalidateSelf();
    ref.invalidate(medicalFollowupsProvider);
  }
}

final healthRecordsProvider =
    AsyncNotifierProvider<HealthRecordsNotifier, List<EmployeeHealthRecord>>(HealthRecordsNotifier.new);

// --------------------------------------------------------------------------
// 2. Company Bulk Reports Notifier (เล่มรวม รพ.)
// --------------------------------------------------------------------------
class CompanyBulkReportsNotifier extends AsyncNotifier<List<CompanyHealthBulkReport>> {
  @override
  Future<List<CompanyHealthBulkReport>> build() async {
    final repo = ref.watch(healthRepoProvider);
    return await repo.getAllBulkReports();
  }

  Future<int> saveBulkReport(CompanyHealthBulkReport report, {String? newPdfPath}) async {
    final repo = ref.read(healthRepoProvider);
    final id = await repo.saveBulkReport(report, newPdfPath: newPdfPath);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteBulkReport(int id) async {
    final repo = ref.read(healthRepoProvider);
    await repo.deleteBulkReport(id);
    ref.invalidateSelf();
  }
}

final companyBulkReportsProvider =
    AsyncNotifierProvider<CompanyBulkReportsNotifier, List<CompanyHealthBulkReport>>(CompanyBulkReportsNotifier.new);

// --------------------------------------------------------------------------
// 3. Medical Surveillance Follow-ups Notifier
// --------------------------------------------------------------------------
class MedicalFollowupsNotifier extends AsyncNotifier<List<MedicalSurveillanceFollowup>> {
  @override
  Future<List<MedicalSurveillanceFollowup>> build() async {
    final repo = ref.watch(healthRepoProvider);
    return await repo.getAllFollowups();
  }

  Future<int> saveFollowup(MedicalSurveillanceFollowup followup) async {
    final repo = ref.read(healthRepoProvider);
    final id = await repo.saveFollowup(followup);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteFollowup(int id) async {
    final repo = ref.read(healthRepoProvider);
    await repo.deleteFollowup(id);
    ref.invalidateSelf();
  }
}

final medicalFollowupsProvider =
    AsyncNotifierProvider<MedicalFollowupsNotifier, List<MedicalSurveillanceFollowup>>(MedicalFollowupsNotifier.new);
