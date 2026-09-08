import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/ptw_kpi_summary_model.dart';
import '../../data/repositories/ptw_repository.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/ptw_status.dart';
import '../../domain/services/ptw_workflow_engine.dart';
import 'ptw_filter_notifier.dart';

/// Provider for PTW SQLite Repository
final ptwRepositoryProvider = Provider<PtwRepository>((ref) {
  return PtwRepository();
});

/// Riverpod 3 AsyncNotifier managing the Master PTW Permit List
class PtwListNotifier extends AsyncNotifier<List<PtwModel>> {
  @override
  Future<List<PtwModel>> build() async {
    final repo = ref.watch(ptwRepositoryProvider);
    final filter = ref.watch(ptwFilterProvider);

    return await repo.getAllPermits(
      searchQuery: filter.searchQuery,
      riskTypeFilter: filter.riskType,
      statusFilter: filter.status,
      departmentFilter: filter.department,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  }

  /// Create a new permit and persist in SQLite
  Future<PtwModel> createPermit(PtwModel permit) async {
    final repo = ref.read(ptwRepositoryProvider);
    final saved = await repo.savePermit(permit);
    ref.invalidateSelf();
    ref.invalidate(ptwKpiProvider);
    return saved;
  }

  /// Update an existing permit
  Future<PtwModel> updatePermit(PtwModel permit) async {
    final repo = ref.read(ptwRepositoryProvider);
    final saved = await repo.savePermit(permit);
    ref.invalidateSelf();
    ref.invalidate(ptwKpiProvider);
    return saved;
  }

  /// Delete a permit by its PTW number
  Future<int> deletePermit(String ptwNumber) async {
    final repo = ref.read(ptwRepositoryProvider);
    final count = await repo.deletePermit(ptwNumber);
    ref.invalidateSelf();
    ref.invalidate(ptwKpiProvider);
    return count;
  }

  /// Guarded Status Transition with State Machine Validation & Audit Log Recording
  Future<WorkflowTransitionResult> transitionStatus(
    String ptwNumber,
    PtwStatus targetStatus, {
    String? comments,
    String? approverName,
    String? approverRole,
    String? signaturePath,
    Uint8List? signatureBytes,
    String? rejectionReason,
  }) async {
    final repo = ref.read(ptwRepositoryProvider);
    final currentPermit = await repo.getPermitByNumber(ptwNumber);

    if (currentPermit == null) {
      return WorkflowTransitionResult.denied(
        fromStatus: PtwStatus.draft,
        toStatus: targetStatus,
        errors: ['ไม่พบใบอนุญาตหมายเลข $ptwNumber ในระบบ'],
      );
    }

    // Validate using PtwWorkflowEngine
    final validationResult = PtwWorkflowEngine.validateTransition(
      currentPermit: currentPermit,
      targetStatus: targetStatus,
      rejectionReason: rejectionReason ?? comments,
      signatoryName: approverName,
      signatureBytes: signatureBytes,
      signaturePath: signaturePath,
    );

    if (!validationResult.isAllowed) {
      return validationResult;
    }

    // Apply Transition & Save Permit
    final updatedPermit = PtwWorkflowEngine.applyTransition(
      currentPermit,
      targetStatus,
      signatoryName: approverName,
      signatoryRole: approverRole,
      signaturePath: signaturePath,
      comments: comments ?? rejectionReason,
    );

    await repo.savePermit(updatedPermit);
    ref.invalidateSelf();
    ref.invalidate(ptwKpiProvider);

    return validationResult;
  }

  /// Force refresh permit list
  void refresh() {
    ref.invalidateSelf();
    ref.invalidate(ptwKpiProvider);
  }
}

/// Riverpod Provider for Master PTW List
final ptwListProvider = AsyncNotifierProvider<PtwListNotifier, List<PtwModel>>(
  PtwListNotifier.new,
);

/// Riverpod Provider for PTW Dashboard KPI Analytics Summary
final ptwKpiProvider = FutureProvider<PtwKpiSummaryModel>((ref) async {
  final repo = ref.watch(ptwRepositoryProvider);
  // Recompute whenever the list state changes
  ref.watch(ptwListProvider);
  return await repo.getKpiSummary();
});

/// Riverpod Provider for distinct applicant departments in the system
final ptwDepartmentsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(ptwRepositoryProvider);
  final permits = await repo.getAllPermits();
  final depts = permits
      .map((p) => p.applicantDepartment.trim())
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList();
  depts.sort();
  return ['ALL', ...depts];
});
