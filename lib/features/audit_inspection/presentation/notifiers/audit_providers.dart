import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../safety_manual/presentation/notifiers/manual_providers.dart';
import '../../data/repositories/audit_repository.dart';
import '../../domain/models/audit_models.dart';

// Repository Provider
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository();
});

// Cross-Module Evidence Provider
final crossModuleEvidenceProvider = FutureProvider<CrossModuleEvidenceSummary>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return await repo.fetchCrossModuleEvidence();
});

// All Audit Sessions
final auditSessionsProvider = AsyncNotifierProvider<AuditSessionsNotifier, List<AuditSession>>(() {
  return AuditSessionsNotifier();
});

class AuditSessionsNotifier extends AsyncNotifier<List<AuditSession>> {
  @override
  Future<List<AuditSession>> build() async {
    final repo = ref.watch(auditRepositoryProvider);
    return await repo.getAllSessions();
  }

  Future<AuditSession> createSession({
    required String title,
    required String leadAuditor,
    String? auditorTeam,
    required String scope,
    String? auditDate,
  }) async {
    final repo = ref.read(auditRepositoryProvider);
    final factoryScope = ref.read(factoryScopeProvider).asData?.value;

    final session = await repo.createSession(
      title: title,
      leadAuditor: leadAuditor,
      auditorTeam: auditorTeam,
      scope: scope,
      factoryScope: factoryScope,
      auditDate: auditDate,
    );

    ref.invalidateSelf();
    ref.invalidate(auditKpiStatsProvider);
    ref.read(activeSessionIdProvider.notifier).setSessionId(session.id);
    return session;
  }

  Future<void> deleteSession(int id) async {
    final repo = ref.read(auditRepositoryProvider);
    await repo.deleteSession(id);
    ref.invalidateSelf();
    ref.invalidate(auditKpiStatsProvider);
    
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == id) {
      ref.read(activeSessionIdProvider.notifier).setSessionId(null);
    }
  }
}

// Active Session ID
final activeSessionIdProvider = NotifierProvider<ActiveSessionIdNotifier, int?>(() {
  return ActiveSessionIdNotifier();
});

class ActiveSessionIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setSessionId(int? id) => state = id;
}

// Active Session Object
final activeAuditSessionProvider = Provider<AuditSession?>((ref) {
  final activeId = ref.watch(activeSessionIdProvider);
  if (activeId == null) return null;
  final sessionsAsync = ref.watch(auditSessionsProvider);
  return sessionsAsync.asData?.value.where((s) => s.id == activeId).firstOrNull;
});

// Active Session Checklist Items Notifier
final activeChecklistNotifierProvider =
    AsyncNotifierProvider<ActiveChecklistNotifier, List<AuditChecklistItem>>(() {
  return ActiveChecklistNotifier();
});

class ActiveChecklistNotifier extends AsyncNotifier<List<AuditChecklistItem>> {
  @override
  Future<List<AuditChecklistItem>> build() async {
    final activeId = ref.watch(activeSessionIdProvider);
    if (activeId == null) return [];
    final repo = ref.watch(auditRepositoryProvider);
    return await repo.getChecklistItems(activeId);
  }

  Future<void> updateItemStatus(AuditChecklistItem item, String newStatus, {String? notes, String? suggestedAction}) async {
    final repo = ref.read(auditRepositoryProvider);
    final updated = item.copyWith(
      resultStatus: newStatus,
      auditorNotes: notes ?? item.auditorNotes,
      suggestedAction: suggestedAction ?? item.suggestedAction,
    );
    await repo.updateChecklistItem(updated);
    
    // Refresh items and session stats
    ref.invalidateSelf();
    ref.invalidate(auditSessionsProvider);
    ref.invalidate(auditKpiStatsProvider);
  }
}

// Findings / CAPA Provider for Active Session
final activeFindingsProvider = FutureProvider<List<AuditFindingCapa>>((ref) async {
  final activeId = ref.watch(activeSessionIdProvider);
  if (activeId == null) return [];
  final repo = ref.watch(auditRepositoryProvider);
  return await repo.getFindings(activeId);
});

// All CAR / CAPA Findings across all sessions
final allAuditFindingsProvider = AsyncNotifierProvider<AllAuditFindingsNotifier, List<AuditFindingCapa>>(() {
  return AllAuditFindingsNotifier();
});

class AllAuditFindingsNotifier extends AsyncNotifier<List<AuditFindingCapa>> {
  @override
  Future<List<AuditFindingCapa>> build() async {
    final repo = ref.watch(auditRepositoryProvider);
    return await repo.getAllFindings();
  }

  Future<void> saveFinding(AuditFindingCapa finding) async {
    final repo = ref.read(auditRepositoryProvider);
    await repo.saveFinding(finding);
    ref.invalidateSelf();
    ref.invalidate(activeFindingsProvider);
    ref.invalidate(auditKpiStatsProvider);
  }

  Future<void> deleteFinding(int id) async {
    final repo = ref.read(auditRepositoryProvider);
    await repo.deleteFinding(id);
    ref.invalidateSelf();
    ref.invalidate(activeFindingsProvider);
    ref.invalidate(auditKpiStatsProvider);
  }
}

// KPI Stats Provider
final auditKpiStatsProvider = FutureProvider<AuditKpiStats>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return await repo.getKpiStats();
});
