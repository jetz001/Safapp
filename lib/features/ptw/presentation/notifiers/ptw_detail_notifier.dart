import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/gas_test_log_model.dart';
import '../../data/models/confined_role_model.dart';
import '../../data/models/fire_watch_model.dart';
import '../../data/models/loto_isolation_model.dart';
import '../../data/models/ptw_checklist_model.dart';
import '../../domain/enums/ptw_status.dart';
import '../../domain/services/ptw_workflow_engine.dart';
import 'ptw_list_notifier.dart';

/// Riverpod AsyncNotifier managing state for a single PTW Permit Detail View
class PtwDetailNotifier extends AsyncNotifier<PtwModel?> {
  final String ptwNumber;
  PtwDetailNotifier(this.ptwNumber);

  @override
  Future<PtwModel?> build() async {
    final repo = ref.watch(ptwRepositoryProvider);
    return await repo.getPermitByNumber(ptwNumber);
  }

  /// Save or update master permit details
  Future<PtwModel> savePermit(PtwModel permit) async {
    final repo = ref.read(ptwRepositoryProvider);
    final updated = await repo.savePermit(permit);
    state = AsyncData(updated);
    ref.invalidate(ptwListProvider);
    ref.invalidate(ptwKpiProvider);
    return updated;
  }

  /// Add a Gas Test Log entry to this permit
  Future<GasTestLogModel> addGasTestLog(GasTestLogModel log) async {
    final repo = ref.read(ptwRepositoryProvider);
    final savedLog = await repo.addGasTestLog(ptwNumber, log);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
    ref.invalidate(ptwKpiProvider);
    return savedLog;
  }

  /// Save or replace Confined Space 4 statutory roles
  Future<void> saveConfinedRoles(List<ConfinedRoleModel> roles) async {
    final repo = ref.read(ptwRepositoryProvider);
    await repo.saveConfinedRoles(ptwNumber, roles);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
  }

  /// Save or update Fire Watch monitoring log
  Future<void> saveFireWatch(FireWatchModel fireWatch) async {
    final repo = ref.read(ptwRepositoryProvider);
    await repo.saveFireWatch(ptwNumber, fireWatch);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
  }

  /// Save or replace LOTO energy isolation points
  Future<void> saveLotoIsolations(List<LotoIsolationModel> isolations) async {
    final repo = ref.read(ptwRepositoryProvider);
    await repo.saveLotoIsolations(ptwNumber, isolations);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
    ref.invalidate(ptwKpiProvider);
  }

  /// Toggle Zero-Energy Verification on a LOTO isolation point
  Future<void> toggleLotoZeroEnergy(String isolationId, bool isVerified, String verifiedBy) async {
    final repo = ref.read(ptwRepositoryProvider);
    await repo.toggleLotoZeroEnergy(isolationId, isVerified, verifiedBy);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
    ref.invalidate(ptwKpiProvider);
  }

  /// Toggle De-isolation on a LOTO point during closure
  Future<void> toggleLotoDeIsolation(String isolationId, bool isDeIsolated, String deIsolatedBy) async {
    final repo = ref.read(ptwRepositoryProvider);
    await repo.toggleLotoDeIsolation(isolationId, isDeIsolated, deIsolatedBy);
    ref.invalidateSelf();
    ref.invalidate(ptwListProvider);
    ref.invalidate(ptwKpiProvider);
  }

  /// Update safety checklist items for this permit
  Future<void> updateChecklist(List<PtwChecklistModel> checklistItems) async {
    final current = state.value;
    if (current == null) return;
    final updatedPermit = current.copyWith(checklistItems: checklistItems);
    await savePermit(updatedPermit);
  }

  /// Execute guarded workflow status transition on this permit
  Future<WorkflowTransitionResult> transitionStatus(
    PtwStatus targetStatus, {
    String? comments,
    String? approverName,
    String? approverRole,
    String? signaturePath,
    Uint8List? signatureBytes,
    String? rejectionReason,
  }) async {
    final current = state.value;
    if (current == null) {
      return WorkflowTransitionResult.denied(
        fromStatus: PtwStatus.draft,
        toStatus: targetStatus,
        errors: ['ไม่พบข้อมูลใบอนุญาต'],
      );
    }

    final validationResult = PtwWorkflowEngine.validateTransition(
      currentPermit: current,
      targetStatus: targetStatus,
      rejectionReason: rejectionReason ?? comments,
      signatoryName: approverName,
      signatureBytes: signatureBytes,
      signaturePath: signaturePath,
    );

    if (!validationResult.isAllowed) {
      return validationResult;
    }

    final updatedPermit = PtwWorkflowEngine.applyTransition(
      current,
      targetStatus,
      signatoryName: approverName,
      signatoryRole: approverRole,
      signaturePath: signaturePath,
      comments: comments ?? rejectionReason,
    );

    final saved = await savePermit(updatedPermit);
    state = AsyncData(saved);

    return validationResult;
  }
}

/// Riverpod Family Provider for single PTW detail
final ptwDetailProvider = AsyncNotifierProvider.family<PtwDetailNotifier, PtwModel?, String>(
  PtwDetailNotifier.new,
);
