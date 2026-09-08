import 'dart:convert';

/// Dashboard KPI Metrics Model for PTW High-Risk Operations
class PtwKpiSummaryModel {
  final int totalPermits;
  final int activeCount;
  final int pendingCount;
  final int draftCount;
  final int extendedCount;
  final int closedCount;
  final int overdueCount;
  final int hotWorkCount;
  final int confinedSpaceCount;
  final int workingAtHeightCount;
  final int electricalLotoCount;
  final int excavationLiftingCount;
  final int gasTestAnomalyCount;
  final int lotoPendingDeIsolationCount;
  final double complianceRatePercent;

  const PtwKpiSummaryModel({
    this.totalPermits = 0,
    this.activeCount = 0,
    this.pendingCount = 0,
    this.draftCount = 0,
    this.extendedCount = 0,
    this.closedCount = 0,
    this.overdueCount = 0,
    this.hotWorkCount = 0,
    this.confinedSpaceCount = 0,
    this.workingAtHeightCount = 0,
    this.electricalLotoCount = 0,
    this.excavationLiftingCount = 0,
    this.gasTestAnomalyCount = 0,
    this.lotoPendingDeIsolationCount = 0,
    this.complianceRatePercent = 100.0,
  });

  factory PtwKpiSummaryModel.empty() => const PtwKpiSummaryModel();

  Map<String, dynamic> toMap() {
    return {
      'total_permits': totalPermits,
      'active_count': activeCount,
      'pending_count': pendingCount,
      'draft_count': draftCount,
      'extended_count': extendedCount,
      'closed_count': closedCount,
      'overdue_count': overdueCount,
      'hot_work_count': hotWorkCount,
      'confined_space_count': confinedSpaceCount,
      'working_at_height_count': workingAtHeightCount,
      'electrical_loto_count': electricalLotoCount,
      'excavation_lifting_count': excavationLiftingCount,
      'gas_test_anomaly_count': gasTestAnomalyCount,
      'loto_pending_de_isolation_count': lotoPendingDeIsolationCount,
      'compliance_rate_percent': complianceRatePercent,
    };
  }

  factory PtwKpiSummaryModel.fromMap(Map<String, dynamic> map) {
    return PtwKpiSummaryModel(
      totalPermits: (map['total_permits'] as num?)?.toInt() ?? 0,
      activeCount: (map['active_count'] as num?)?.toInt() ?? 0,
      pendingCount: (map['pending_count'] as num?)?.toInt() ?? 0,
      draftCount: (map['draft_count'] as num?)?.toInt() ?? 0,
      extendedCount: (map['extended_count'] as num?)?.toInt() ?? 0,
      closedCount: (map['closed_count'] as num?)?.toInt() ?? 0,
      overdueCount: (map['overdue_count'] as num?)?.toInt() ?? 0,
      hotWorkCount: (map['hot_work_count'] as num?)?.toInt() ?? 0,
      confinedSpaceCount: (map['confined_space_count'] as num?)?.toInt() ?? 0,
      workingAtHeightCount: (map['working_at_height_count'] as num?)?.toInt() ?? 0,
      electricalLotoCount: (map['electrical_loto_count'] as num?)?.toInt() ?? 0,
      excavationLiftingCount: (map['excavation_lifting_count'] as num?)?.toInt() ?? 0,
      gasTestAnomalyCount: (map['gas_test_anomaly_count'] as num?)?.toInt() ?? 0,
      lotoPendingDeIsolationCount: (map['loto_pending_de_isolation_count'] as num?)?.toInt() ?? 0,
      complianceRatePercent: (map['compliance_rate_percent'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory PtwKpiSummaryModel.fromJson(Map<String, dynamic> json) => PtwKpiSummaryModel.fromMap(json);

  PtwKpiSummaryModel copyWith({
    int? totalPermits,
    int? activeCount,
    int? pendingCount,
    int? draftCount,
    int? extendedCount,
    int? closedCount,
    int? overdueCount,
    int? hotWorkCount,
    int? confinedSpaceCount,
    int? workingAtHeightCount,
    int? electricalLotoCount,
    int? excavationLiftingCount,
    int? gasTestAnomalyCount,
    int? lotoPendingDeIsolationCount,
    double? complianceRatePercent,
  }) {
    return PtwKpiSummaryModel(
      totalPermits: totalPermits ?? this.totalPermits,
      activeCount: activeCount ?? this.activeCount,
      pendingCount: pendingCount ?? this.pendingCount,
      draftCount: draftCount ?? this.draftCount,
      extendedCount: extendedCount ?? this.extendedCount,
      closedCount: closedCount ?? this.closedCount,
      overdueCount: overdueCount ?? this.overdueCount,
      hotWorkCount: hotWorkCount ?? this.hotWorkCount,
      confinedSpaceCount: confinedSpaceCount ?? this.confinedSpaceCount,
      workingAtHeightCount: workingAtHeightCount ?? this.workingAtHeightCount,
      electricalLotoCount: electricalLotoCount ?? this.electricalLotoCount,
      excavationLiftingCount: excavationLiftingCount ?? this.excavationLiftingCount,
      gasTestAnomalyCount: gasTestAnomalyCount ?? this.gasTestAnomalyCount,
      lotoPendingDeIsolationCount: lotoPendingDeIsolationCount ?? this.lotoPendingDeIsolationCount,
      complianceRatePercent: complianceRatePercent ?? this.complianceRatePercent,
    );
  }

  @override
  String toString() => 'PtwKpiSummaryModel(total: $totalPermits, active: $activeCount, pending: $pendingCount, overdue: $overdueCount, compliance: ${complianceRatePercent.toStringAsFixed(1)}%)';
}
