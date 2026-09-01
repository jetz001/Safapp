import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/environment_repository.dart';
import '../../domain/models/environment_standard_model.dart';
import '../../domain/models/environment_session_model.dart';
import '../../domain/models/environment_point_model.dart';
import '../../domain/models/environment_capa_model.dart';
import '../../domain/models/environment_kpi_summary.dart';

/// Provider for EnvironmentRepository singleton instance.
final environmentRepoProvider = Provider<EnvironmentRepository>((ref) {
  return EnvironmentRepository();
});

// ----------------------------------------------------------------------------
// 1. UI & Filter State Notifiers (Riverpod 3 NotifierProvider)
// ----------------------------------------------------------------------------

/// Search query string for measurement points and sessions
class EnvSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}

final envSearchQueryProvider =
    NotifierProvider<EnvSearchQueryNotifier, String>(EnvSearchQueryNotifier.new);

/// Factor type filter ('ALL', 'LIGHT', 'NOISE', 'HEAT')
class EnvFactorFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}

final envFactorFilterProvider =
    NotifierProvider<EnvFactorFilterNotifier, String>(EnvFactorFilterNotifier.new);

/// Compliance status filter ('ALL', 'PASS', 'ACTION_LEVEL', 'FAIL')
class EnvStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}

final envStatusFilterProvider =
    NotifierProvider<EnvStatusFilterNotifier, String>(EnvStatusFilterNotifier.new);

/// Active main navigation tab (0: Dashboard/Sessions, 1: Points, 2: CAPA & HCP, 3: Gazette Library)
class EnvSelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  @override
  set state(int val) => super.state = val;
}

final envSelectedTabProvider =
    NotifierProvider<EnvSelectedTabNotifier, int>(EnvSelectedTabNotifier.new);

/// Currently selected session ID for filtering points ('ALL' or session_id)
class EnvSelectedSessionIdNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}

final envSelectedSessionIdProvider =
    NotifierProvider<EnvSelectedSessionIdNotifier, String>(EnvSelectedSessionIdNotifier.new);

/// Year BE filter for sessions (null = All years)
class EnvSelectedYearFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  @override
  set state(int? val) => super.state = val;
  void reset() => super.state = null;
}

final envSelectedYearFilterProvider =
    NotifierProvider<EnvSelectedYearFilterNotifier, int?>(EnvSelectedYearFilterNotifier.new);

/// Search query for CAPA items
class EnvCapaSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}

final envCapaSearchQueryProvider =
    NotifierProvider<EnvCapaSearchQueryNotifier, String>(EnvCapaSearchQueryNotifier.new);

/// Status filter for CAPA items ('ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE')
class EnvCapaStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}

final envCapaStatusFilterProvider =
    NotifierProvider<EnvCapaStatusFilterNotifier, String>(EnvCapaStatusFilterNotifier.new);

/// Search query for Gazette Library
class EnvGazetteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}

final envGazetteSearchQueryProvider =
    NotifierProvider<EnvGazetteSearchQueryNotifier, String>(EnvGazetteSearchQueryNotifier.new);

// ----------------------------------------------------------------------------
// 2. Entity List Notifiers (AsyncNotifierProvider)
// ----------------------------------------------------------------------------

/// List notifier for environmental measurement sessions
class EnvironmentSessionListNotifier extends AsyncNotifier<List<EnvironmentSessionModel>> {
  @override
  Future<List<EnvironmentSessionModel>> build() async {
    final repo = ref.watch(environmentRepoProvider);
    final year = ref.watch(envSelectedYearFilterProvider);
    final query = ref.watch(envSearchQueryProvider);

    return await repo.getAllSessions(
      yearBe: year,
      keyword: query,
    );
  }

  Future<void> saveSession(EnvironmentSessionModel session) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.saveSession(session);
      ref.invalidateSelf();
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.deleteSession(sessionId);
      ref.invalidateSelf();
      ref.invalidate(envPointListProvider);
      ref.invalidate(envCapaListProvider);
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final envSessionListProvider =
    AsyncNotifierProvider<EnvironmentSessionListNotifier, List<EnvironmentSessionModel>>(
  EnvironmentSessionListNotifier.new,
);

/// List notifier for sampling points
class EnvironmentPointListNotifier extends AsyncNotifier<List<EnvironmentPointModel>> {
  @override
  Future<List<EnvironmentPointModel>> build() async {
    final repo = ref.watch(environmentRepoProvider);
    final selectedSessionId = ref.watch(envSelectedSessionIdProvider);
    final factorCode = ref.watch(envFactorFilterProvider);
    final statusCode = ref.watch(envStatusFilterProvider);
    final query = ref.watch(envSearchQueryProvider);

    EnvironmentFactorType? factorType;
    if (factorCode != 'ALL') {
      factorType = EnvironmentFactorType.fromDbCode(factorCode);
    }

    EnvironmentEvaluationStatus? status;
    if (statusCode != 'ALL') {
      status = EnvironmentEvaluationStatus.fromDbCode(statusCode);
    }

    final sessionId = (selectedSessionId == 'ALL' || selectedSessionId.isEmpty)
        ? null
        : selectedSessionId;

    return await repo.getPoints(
      sessionId: sessionId,
      factorType: factorType,
      status: status,
      keyword: query,
    );
  }

  Future<void> savePoint(EnvironmentPointModel point) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.savePoint(point);

      // Auto-create CAPA for non-compliant or action level points if not already present
      if (point.requiresCapa && (point.capaId == null || point.capaId!.isEmpty)) {
        final autoCapaId = 'CAPA-${point.pointId}';
        final capa = EnvironmentCapaModel(
          capaId: autoCapaId,
          pointId: point.pointId,
          sessionId: point.sessionId,
          factorType: point.factorType,
          actionTitle: 'ปรับปรุงแก้ไขผลตรวจวัด ${point.factorType.labelTh} (${point.locationName})',
          hazardDescription: 'จุดตรวจวัด ${point.pointId} ${point.summaryValueDisplay} ${point.evaluationStatus.labelTh}',
          rootCause: 'ผลการตรวจวัดไม่สอดคล้องตามเกณฑ์มาตรฐานหรืออยู่ในระดับเฝ้าระวัง Action Level',
          picName: 'จป.วิชาชีพ / หัวหน้าแผนก',
          targetDate: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first,
          status: 'PENDING',
          hearingProgramEnrolled: point.requiresHearingConservation,
        );
        await repo.saveCapa(capa);
      }

      ref.invalidateSelf();
      ref.invalidate(envCapaListProvider);
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveBatchPoints(List<EnvironmentPointModel> points) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.saveBatchPoints(points);
      ref.invalidateSelf();
      ref.invalidate(envCapaListProvider);
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePoint(String pointId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.deletePoint(pointId);
      ref.invalidateSelf();
      ref.invalidate(envCapaListProvider);
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final envPointListProvider =
    AsyncNotifierProvider<EnvironmentPointListNotifier, List<EnvironmentPointModel>>(
  EnvironmentPointListNotifier.new,
);

/// List notifier for CAPA items & Hearing Conservation
class EnvironmentCapaListNotifier extends AsyncNotifier<List<EnvironmentCapaModel>> {
  @override
  Future<List<EnvironmentCapaModel>> build() async {
    final repo = ref.watch(environmentRepoProvider);
    final selectedSessionId = ref.watch(envSelectedSessionIdProvider);
    final status = ref.watch(envCapaStatusFilterProvider);
    final query = ref.watch(envCapaSearchQueryProvider);

    final sessionId = (selectedSessionId == 'ALL' || selectedSessionId.isEmpty)
        ? null
        : selectedSessionId;

    return await repo.getCapas(
      sessionId: sessionId,
      status: status,
      keyword: query,
    );
  }

  Future<void> saveCapa(EnvironmentCapaModel capa) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.saveCapa(capa);
      ref.invalidateSelf();
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCapa(String capaId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(environmentRepoProvider);
      await repo.deleteCapa(capaId);
      ref.invalidateSelf();
      ref.invalidate(envKpiSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final envCapaListProvider =
    AsyncNotifierProvider<EnvironmentCapaListNotifier, List<EnvironmentCapaModel>>(
  EnvironmentCapaListNotifier.new,
);

// ----------------------------------------------------------------------------
// 3. KPI Summary & Detail Providers
// ----------------------------------------------------------------------------

/// Provider computing real-time KPI metrics for the active session or overall
final envKpiSummaryProvider = FutureProvider<EnvironmentKpiSummary>((ref) async {
  final repo = ref.watch(environmentRepoProvider);
  final selectedSessionId = ref.watch(envSelectedSessionIdProvider);

  if (selectedSessionId != 'ALL' && selectedSessionId.isNotEmpty) {
    return await repo.getSessionKpi(selectedSessionId);
  } else {
    return await repo.getOverallKpi();
  }
});

/// Provider fetching all master statutory standards
final envStandardsListProvider = FutureProvider<List<EnvironmentStandardModel>>((ref) async {
  final repo = ref.watch(environmentRepoProvider);
  final factorCode = ref.watch(envFactorFilterProvider);

  EnvironmentFactorType? factorType;
  if (factorCode != 'ALL') {
    factorType = EnvironmentFactorType.fromDbCode(factorCode);
  }

  return await repo.getAllStandards(factorType: factorType);
});

/// Provider for retrieving a single session by session_id
final envSessionDetailProvider =
    FutureProvider.family<EnvironmentSessionModel?, String>((ref, sessionId) async {
  final repo = ref.watch(environmentRepoProvider);
  return await repo.getSessionById(sessionId);
});
