import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/risk_assessment_repository.dart';
import '../../data/repositories/contractor_jsa_repository.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/contractor_jsa_models.dart';

final riskAssessmentRepoProvider = Provider<RiskAssessmentRepository>((ref) {
  return RiskAssessmentRepository();
});

final contractorJsaRepoProvider = Provider<ContractorJsaRepository>((ref) {
  return ContractorJsaRepository();
});

// ----------------------------------------------------
// Contractor JSA Documents Provider (AsyncNotifier)
// ----------------------------------------------------
class ContractorJsaNotifier extends AsyncNotifier<List<ContractorJsaDocument>> {
  @override
  Future<List<ContractorJsaDocument>> build() async {
    final repo = ref.watch(contractorJsaRepoProvider);
    return await repo.getAllDocuments();
  }

  Future<int> saveDocument(ContractorJsaDocument doc, {List<String>? newFilesToPersist}) async {
    final repo = ref.read(contractorJsaRepoProvider);
    List<String> finalFilePaths = doc.filePaths;

    if (newFilesToPersist != null && newFilesToPersist.isNotEmpty) {
      final persisted = await repo.persistPickedFiles(newFilesToPersist);
      finalFilePaths = [...finalFilePaths, ...persisted];
    }

    final toSave = doc.copyWith(filePaths: finalFilePaths);
    final id = await repo.saveDocument(toSave);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteDocument(int id) async {
    final repo = ref.read(contractorJsaRepoProvider);
    await repo.deleteDocument(id);
    ref.invalidateSelf();
  }
}

final contractorJsaProvider =
    AsyncNotifierProvider<ContractorJsaNotifier, List<ContractorJsaDocument>>(ContractorJsaNotifier.new);

// ----------------------------------------------------
// Company Profile Provider (AsyncNotifier)
// ----------------------------------------------------
class CompanyProfileNotifier extends AsyncNotifier<CompanyProfile?> {
  @override
  Future<CompanyProfile?> build() async {
    final repo = ref.watch(riskAssessmentRepoProvider);
    return await repo.getCompanyProfile();
  }

  Future<void> saveProfile(CompanyProfile profile) async {
    final repo = ref.read(riskAssessmentRepoProvider);
    await repo.saveCompanyProfile(profile);
    ref.invalidateSelf();
  }
}

final companyProfileNotifierProvider =
    AsyncNotifierProvider<CompanyProfileNotifier, CompanyProfile?>(CompanyProfileNotifier.new);

// ----------------------------------------------------
// Sessions List Provider (AsyncNotifier)
// ----------------------------------------------------
class RiskSessionsNotifier extends AsyncNotifier<List<RiskAssessmentSession>> {
  @override
  Future<List<RiskAssessmentSession>> build() async {
    final repo = ref.watch(riskAssessmentRepoProvider);
    return await repo.getAllSessions();
  }

  Future<int> saveSession(RiskAssessmentSession session) async {
    final repo = ref.read(riskAssessmentRepoProvider);
    final id = await repo.saveSession(session);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteSession(int id) async {
    final repo = ref.read(riskAssessmentRepoProvider);
    await repo.deleteSession(id);
    ref.invalidateSelf();
  }
}

final riskSessionsProvider =
    AsyncNotifierProvider<RiskSessionsNotifier, List<RiskAssessmentSession>>(RiskSessionsNotifier.new);

// ----------------------------------------------------
// Single Session Report Rows Provider (Family)
// ----------------------------------------------------
final sessionReportRowsProvider =
    FutureProvider.family<List<PorReportRowData>, int>((ref, sessionId) async {
  final repo = ref.watch(riskAssessmentRepoProvider);
  return await repo.getPorReportRows(sessionId);
});

final sessionDetailProvider =
    FutureProvider.family<RiskAssessmentSession?, int>((ref, sessionId) async {
  final repo = ref.watch(riskAssessmentRepoProvider);
  return await repo.getSessionById(sessionId);
});
