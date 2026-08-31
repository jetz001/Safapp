import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/legal_register_repository.dart';
import '../../domain/models/legal_master_item_model.dart';
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../../domain/models/legal_capa_model.dart';
import '../../domain/models/legal_compliance_stats_model.dart';

/// Provider for the LegalRegisterRepository singleton instance.
final legalRepoProvider = Provider<LegalRegisterRepository>((ref) {
  return LegalRegisterRepository();
});

// ----------------------------------------------------------------------------
// 1. UI & Filter State Notifiers (Riverpod 3 NotifierProvider)
// ----------------------------------------------------------------------------

/// Search query string filter for legal assessments
class LegalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}
final legalSearchQueryProvider =
    NotifierProvider<LegalSearchQueryNotifier, String>(LegalSearchQueryNotifier.new);

/// Law category filter ('ALL' or category code e.g. 'OSH_ACT', 'CHEMICAL_SAFETY')
class LegalCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}
final legalCategoryFilterProvider =
    NotifierProvider<LegalCategoryFilterNotifier, String>(LegalCategoryFilterNotifier.new);

/// Compliance status filter ('ALL', 'COMPLIANT', 'NON_COMPLIANT', 'IN_PROGRESS', 'NOT_APPLICABLE')
class LegalStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}
final legalStatusFilterProvider =
    NotifierProvider<LegalStatusFilterNotifier, String>(LegalStatusFilterNotifier.new);

/// Active main navigation tab (0: Register/Assessments, 1: Gazette Catalog, 2: CAPA Plan)
class LegalSelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  @override
  set state(int val) => super.state = val;
}
final legalSelectedTabProvider =
    NotifierProvider<LegalSelectedTabNotifier, int>(LegalSelectedTabNotifier.new);

/// Master catalog search query
class LegalMasterSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}
final legalMasterSearchQueryProvider =
    NotifierProvider<LegalMasterSearchQueryNotifier, String>(LegalMasterSearchQueryNotifier.new);

/// CAPA Action Plan search query
class LegalCapaSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}
final legalCapaSearchQueryProvider =
    NotifierProvider<LegalCapaSearchQueryNotifier, String>(LegalCapaSearchQueryNotifier.new);

/// CAPA status filter ('ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE')
class LegalCapaStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}
final legalCapaStatusFilterProvider =
    NotifierProvider<LegalCapaStatusFilterNotifier, String>(LegalCapaStatusFilterNotifier.new);

// ----------------------------------------------------------------------------
// 2. Compliance Assessments Notifier & Provider (Tab 1)
// ----------------------------------------------------------------------------

class LegalAssessmentListNotifier
    extends AsyncNotifier<List<LegalComplianceAssessmentModel>> {
  @override
  Future<List<LegalComplianceAssessmentModel>> build() async {
    final repo = ref.watch(legalRepoProvider);
    final query = ref.watch(legalSearchQueryProvider);
    final category = ref.watch(legalCategoryFilterProvider);
    final status = ref.watch(legalStatusFilterProvider);

    return await repo.getAllAssessments(
      query: query,
      category: category,
      status: status,
    );
  }

  /// Save or update an assessment with optional evidence files
  Future<int> saveAssessment(
    LegalComplianceAssessmentModel item, {
    List<String>? newEvidencePaths,
  }) async {
    final repo = ref.read(legalRepoProvider);
    final id = await repo.saveAssessment(
      item,
      newEvidencePaths: newEvidencePaths,
    );
    ref.invalidateSelf();
    ref.invalidate(legalComplianceKpiProvider);
    return id;
  }

  /// Delete an assessment by ID
  Future<int> deleteAssessment(int id) async {
    final repo = ref.read(legalRepoProvider);
    final count = await repo.deleteAssessment(id);
    ref.invalidateSelf();
    ref.invalidate(legalComplianceKpiProvider);
    ref.invalidate(legalCapaListProvider);
    return count;
  }

  /// Reset all assessments to master catalog defaults
  Future<void> resetDefaultAssessments() async {
    final repo = ref.read(legalRepoProvider);
    await repo.resetDefaultAssessments();
    ref.invalidateSelf();
    ref.invalidate(legalComplianceKpiProvider);
  }
}

final legalAssessmentListProvider = AsyncNotifierProvider<
    LegalAssessmentListNotifier, List<LegalComplianceAssessmentModel>>(
  LegalAssessmentListNotifier.new,
);

final legalAssessmentDetailProvider =
    FutureProvider.family<LegalComplianceAssessmentModel?, int>((ref, id) async {
  final repo = ref.watch(legalRepoProvider);
  return await repo.getAssessmentById(id);
});

// ----------------------------------------------------------------------------
// 3. Master Legal Catalog Notifier & Provider (Tab 2)
// ----------------------------------------------------------------------------

class LegalMasterListNotifier extends AsyncNotifier<List<LegalMasterItemModel>> {
  @override
  Future<List<LegalMasterItemModel>> build() async {
    final repo = ref.watch(legalRepoProvider);
    final keyword = ref.watch(legalMasterSearchQueryProvider);
    final category = ref.watch(legalCategoryFilterProvider);

    return await repo.getAllMasterItems(
      keyword: keyword,
      category: category,
    );
  }
}

final legalMasterListProvider =
    AsyncNotifierProvider<LegalMasterListNotifier, List<LegalMasterItemModel>>(
  LegalMasterListNotifier.new,
);

final legalMasterItemDetailProvider =
    FutureProvider.family<LegalMasterItemModel?, String>((ref, itemId) async {
  final repo = ref.watch(legalRepoProvider);
  return await repo.getMasterItemById(itemId);
});

// ----------------------------------------------------------------------------
// 4. CAPA Action Plans Notifier & Provider (Tab 3)
// ----------------------------------------------------------------------------

class LegalCapaListNotifier extends AsyncNotifier<List<LegalCapaModel>> {
  @override
  Future<List<LegalCapaModel>> build() async {
    final repo = ref.watch(legalRepoProvider);
    final query = ref.watch(legalCapaSearchQueryProvider);
    final status = ref.watch(legalCapaStatusFilterProvider);

    return await repo.getAllCapa(
      query: query,
      status: status,
    );
  }

  /// Save or update a CAPA action plan
  Future<int> saveCapa(
    LegalCapaModel item, {
    String? newEvidencePath,
  }) async {
    final repo = ref.read(legalRepoProvider);
    final id = await repo.saveCapa(
      item,
      newEvidencePath: newEvidencePath,
    );
    ref.invalidateSelf();
    ref.invalidate(legalAssessmentListProvider);
    ref.invalidate(legalComplianceKpiProvider);
    return id;
  }

  /// Delete a CAPA action plan by ID
  Future<int> deleteCapa(int id) async {
    final repo = ref.read(legalRepoProvider);
    final count = await repo.deleteCapa(id);
    ref.invalidateSelf();
    ref.invalidate(legalComplianceKpiProvider);
    return count;
  }

  /// Mark a CAPA as COMPLETED
  Future<int> closeCapa(int id, {String? completedDate, String? notes}) async {
    final repo = ref.read(legalRepoProvider);
    final res = await repo.closeCapa(id, completedDate: completedDate, notes: notes);
    ref.invalidateSelf();
    ref.invalidate(legalAssessmentListProvider);
    ref.invalidate(legalComplianceKpiProvider);
    return res;
  }
}

final legalCapaListProvider =
    AsyncNotifierProvider<LegalCapaListNotifier, List<LegalCapaModel>>(
  LegalCapaListNotifier.new,
);

final legalCapaDetailProvider =
    FutureProvider.family<LegalCapaModel?, int>((ref, id) async {
  final repo = ref.watch(legalRepoProvider);
  return await repo.getCapaById(id);
});

// ----------------------------------------------------------------------------
// 5. Compliance KPI Statistics Providers
// ----------------------------------------------------------------------------

final legalComplianceKpiProvider =
    FutureProvider<LegalComplianceStatsModel>((ref) async {
  final repo = ref.watch(legalRepoProvider);
  return await repo.calculateStats();
});

/// Alias provider for legal statistics
final legalStatsProvider = legalComplianceKpiProvider;
