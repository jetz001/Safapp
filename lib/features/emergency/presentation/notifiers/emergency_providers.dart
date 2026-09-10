import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/emergency_plan_model.dart';
import '../../data/models/drill_session_model.dart';
import '../../data/models/electrical_inspection_model.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';

/// Provider for Emergency SQLite Repository
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
});

/// Filter state for Emergency Management
class EmergencyFilterState {
  final HazardType? hazardType;
  final PlanStatus? status;
  final int? drillYear;
  final String searchQuery;

  const EmergencyFilterState({
    this.hazardType,
    this.status,
    this.drillYear,
    this.searchQuery = '',
  });

  EmergencyFilterState copyWith({
    HazardType? Function()? hazardType,
    PlanStatus? Function()? status,
    int? Function()? drillYear,
    String? searchQuery,
  }) {
    return EmergencyFilterState(
      hazardType: hazardType != null ? hazardType() : this.hazardType,
      status: status != null ? status() : this.status,
      drillYear: drillYear != null ? drillYear() : this.drillYear,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EmergencyFilterNotifier extends Notifier<EmergencyFilterState> {
  @override
  EmergencyFilterState build() => const EmergencyFilterState();

  void setHazardFilter(HazardType? hazard) {
    state = state.copyWith(hazardType: () => hazard);
  }

  void setStatusFilter(PlanStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setYearFilter(int? year) {
    state = state.copyWith(drillYear: () => year);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const EmergencyFilterState();
  }
}

final emergencyFilterProvider = NotifierProvider<EmergencyFilterNotifier, EmergencyFilterState>(
  EmergencyFilterNotifier.new,
);

/// Riverpod 3 AsyncNotifier managing Emergency Plans list
class EmergencyPlanListNotifier extends AsyncNotifier<List<EmergencyPlanModel>> {
  @override
  Future<List<EmergencyPlanModel>> build() async {
    final repo = ref.watch(emergencyRepositoryProvider);
    final filter = ref.watch(emergencyFilterProvider);

    final all = await repo.getAllPlans(
      hazardType: filter.hazardType,
      status: filter.status,
    );

    if (filter.searchQuery.trim().isEmpty) return all;
    final query = filter.searchQuery.toLowerCase();
    return all.where((p) =>
      p.planTitle.toLowerCase().contains(query) ||
      p.companyName.toLowerCase().contains(query) ||
      p.fireCommanderName.toLowerCase().contains(query)
    ).toList();
  }

  Future<int> savePlan(EmergencyPlanModel plan) async {
    final repo = ref.read(emergencyRepositoryProvider);
    int id;
    if (plan.id == null) {
      id = await repo.insertPlan(plan);
    } else {
      await repo.updatePlan(plan);
      id = plan.id!;
    }
    final savedPlan = plan.copyWith(id: id);
    final current = state.value ?? [];
    final index = current.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final updated = List<EmergencyPlanModel>.from(current);
      updated[index] = savedPlan;
      state = AsyncValue.data(updated);
    } else {
      state = AsyncValue.data([savedPlan, ...current]);
    }
    return id;
  }

  Future<int> deletePlan(int id) async {
    final repo = ref.read(emergencyRepositoryProvider);
    final count = await repo.deletePlan(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((p) => p.id != id).toList());
    return count;
  }

  /// เติมแม่แบบสำหรับประเภทภัยที่ยังไม่มีในระบบ
  Future<int> loadMissingPresets() async {
    final repo = ref.read(emergencyRepositoryProvider);
    final count = await repo.seedMissingPresets();
    ref.invalidateSelf();
    return count;
  }

  /// บันทึกแม่แบบตามประเภทภัยที่เลือกเข้าสู่ระบบ
  Future<int> addPreset(HazardType hazardType) async {
    final repo = ref.read(emergencyRepositoryProvider);
    final id = await repo.insertPresetForHazard(hazardType);
    ref.invalidateSelf();
    return id;
  }
}


final emergencyPlanListProvider = AsyncNotifierProvider<EmergencyPlanListNotifier, List<EmergencyPlanModel>>(
  EmergencyPlanListNotifier.new,
);

/// Riverpod 3 AsyncNotifier managing Drill Sessions list
class DrillSessionListNotifier extends AsyncNotifier<List<DrillSessionModel>> {
  @override
  Future<List<DrillSessionModel>> build() async {
    final repo = ref.watch(emergencyRepositoryProvider);
    final filter = ref.watch(emergencyFilterProvider);

    final all = await repo.getAllDrills(
      year: filter.drillYear,
      hazardType: filter.hazardType,
    );

    if (filter.searchQuery.trim().isEmpty) return all;
    final query = filter.searchQuery.toLowerCase();
    return all.where((d) =>
      d.drillTitle.toLowerCase().contains(query) ||
      d.incidentLocation.toLowerCase().contains(query) ||
      d.organizerName.toLowerCase().contains(query)
    ).toList();
  }

  Future<int> saveDrill(DrillSessionModel drill) async {
    final repo = ref.read(emergencyRepositoryProvider);
    int id;
    if (drill.id == null) {
      id = await repo.insertDrill(drill);
    } else {
      await repo.updateDrill(drill);
      id = drill.id!;
    }
    ref.invalidateSelf();
    return id;
  }

  Future<int> deleteDrill(int id) async {
    final repo = ref.read(emergencyRepositoryProvider);
    final count = await repo.deleteDrill(id);
    ref.invalidateSelf();
    return count;
  }
}

final drillSessionListProvider = AsyncNotifierProvider<DrillSessionListNotifier, List<DrillSessionModel>>(
  DrillSessionListNotifier.new,
);

/// Riverpod 3 AsyncNotifier managing Electrical Inspections list
class ElectricalInspectionListNotifier extends AsyncNotifier<List<ElectricalInspectionModel>> {
  @override
  Future<List<ElectricalInspectionModel>> build() async {
    final repo = ref.watch(emergencyRepositoryProvider);
    final filter = ref.watch(emergencyFilterProvider);

    final all = await repo.getAllElectricalInspections();

    if (filter.searchQuery.trim().isEmpty) return all;
    final query = filter.searchQuery.toLowerCase();
    return all.where((e) =>
      e.inspectorName.toLowerCase().contains(query) ||
      e.inspectorLicenseNo.toLowerCase().contains(query) ||
      (e.contractorCompany?.toLowerCase().contains(query) ?? false) ||
      (e.companyName?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  Future<int> saveInspection(ElectricalInspectionModel record) async {
    final repo = ref.read(emergencyRepositoryProvider);
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
    final repo = ref.read(emergencyRepositoryProvider);
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

/// KPI Summary Model
class EmergencyKpiSummary {
  final int totalPlansCount;
  final int activePlansCount;
  final int totalDrillsConducted;
  final int currentYearDrills;
  final double averageParticipationRate;
  final int daysUntilAnnualDrillDue;
  final bool isAnnualDrillOverdue;
  final int pendingSpr4Submissions;
  final DrillSessionModel? latestDrill;
  final ElectricalInspectionModel? latestElectricalInspection;

  const EmergencyKpiSummary({
    required this.totalPlansCount,
    required this.activePlansCount,
    required this.totalDrillsConducted,
    required this.currentYearDrills,
    required this.averageParticipationRate,
    required this.daysUntilAnnualDrillDue,
    required this.isAnnualDrillOverdue,
    required this.pendingSpr4Submissions,
    this.latestDrill,
    this.latestElectricalInspection,
  });
}

/// Provider for Dashboard KPI Analytics
final emergencyKpiProvider = Provider<EmergencyKpiSummary>((ref) {
  final plansAsync = ref.watch(emergencyPlanListProvider);
  final drillsAsync = ref.watch(drillSessionListProvider);
  final electricalAsync = ref.watch(electricalInspectionListProvider);

  final plans = plansAsync.value ?? [];
  final drills = drillsAsync.value ?? [];
  final electricalList = electricalAsync.value ?? [];
  final latestElectrical = electricalList.isNotEmpty ? electricalList.first : null;

  final totalPlans = plans.length;
  final activePlans = plans.where((p) => p.status == PlanStatus.active).length;
  final totalDrills = drills.length;

  final currentYear = DateTime.now().year;
  final currentYearDrills = drills.where((d) => d.drillYear == currentYear).length;

  double totalRate = 0.0;
  for (final d in drills) {
    totalRate += d.participationRatePercent > 0
        ? d.participationRatePercent
        : (d.totalWorkersOnSite > 0 ? (d.participatedCount / d.totalWorkersOnSite) * 100 : 100);
  }
  final avgRate = drills.isNotEmpty ? (totalRate / drills.length) : 0.0;

  // Annual Drill SLA: Law mandates drill at least once a year (Clause 30)
  DrillSessionModel? latest;
  int daysRemaining = 365;
  bool isOverdue = false;

  if (drills.isNotEmpty) {
    latest = drills.first;
    try {
      final latestDate = DateTime.parse(latest.drillDate);
      final nextDueDate = DateTime(latestDate.year + 1, latestDate.month, latestDate.day);
      final now = DateTime.now();
      final diff = nextDueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      daysRemaining = diff;
      isOverdue = diff < 0;
    } catch (_) {}
  } else {
    isOverdue = true;
    daysRemaining = 0;
  }

  final pendingSpr4 = drills.where((d) => d.spr4SubmissionStatus != Spr4SubmissionStatus.submitted).length;

  return EmergencyKpiSummary(
    totalPlansCount: totalPlans,
    activePlansCount: activePlans,
    totalDrillsConducted: totalDrills,
    currentYearDrills: currentYearDrills,
    averageParticipationRate: avgRate,
    daysUntilAnnualDrillDue: daysRemaining,
    isAnnualDrillOverdue: isOverdue,
    pendingSpr4Submissions: pendingSpr4,
    latestDrill: latest,
    latestElectricalInspection: latestElectrical,
  );
});

/// Manages the currently selected Emergency Plan for editing in ERP Builder
class SelectedErpPlanNotifier extends Notifier<EmergencyPlanModel?> {
  @override
  EmergencyPlanModel? build() => null;

  void selectPlan(EmergencyPlanModel? plan) {
    state = plan;
  }
}

final selectedErpPlanProvider = NotifierProvider<SelectedErpPlanNotifier, EmergencyPlanModel?>(
  SelectedErpPlanNotifier.new,
);

