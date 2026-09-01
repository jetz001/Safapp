import 'dart:convert';
import 'environment_standard_model.dart';
import 'environment_point_model.dart';
import 'environment_capa_model.dart';

/// Aggregated KPI Metrics for Environmental Monitoring Module.
class EnvironmentKpiSummary {
  final int totalPoints;
  final int lightPoints;
  final int noisePoints;
  final int heatPoints;

  final int passedPoints;
  final int actionLevelPoints;
  final int failedPoints;

  final int lightPassed;
  final int lightFailed;

  final int noiseNormal;
  final int noiseActionLevel;
  final int noiseExceeded;

  final int heatPassed;
  final int heatFailed;

  final int hcpRequiredCount;
  final int capaRequiredCount;
  final int capaTotalCount;
  final int capaCompletedCount;
  final int capaPendingCount;
  final int capaOverdueCount;

  final double compliancePercentage;
  final double lightCompliancePercentage;
  final double noiseCompliancePercentage;
  final double heatCompliancePercentage;
  final String calculatedAt;

  const EnvironmentKpiSummary({
    required this.totalPoints,
    required this.lightPoints,
    required this.noisePoints,
    required this.heatPoints,
    required this.passedPoints,
    required this.actionLevelPoints,
    required this.failedPoints,
    required this.lightPassed,
    required this.lightFailed,
    required this.noiseNormal,
    required this.noiseActionLevel,
    required this.noiseExceeded,
    required this.heatPassed,
    required this.heatFailed,
    required this.hcpRequiredCount,
    required this.capaRequiredCount,
    this.capaTotalCount = 0,
    this.capaCompletedCount = 0,
    this.capaPendingCount = 0,
    this.capaOverdueCount = 0,
    required this.compliancePercentage,
    required this.lightCompliancePercentage,
    required this.noiseCompliancePercentage,
    required this.heatCompliancePercentage,
    required this.calculatedAt,
  });

  /// Factory to calculate comprehensive KPI summary from lists of measurement points and CAPAs.
  factory EnvironmentKpiSummary.calculate({
    required List<EnvironmentPointModel> points,
    List<EnvironmentCapaModel>? capas,
  }) {
    final totalPoints = points.length;

    int lightPoints = 0;
    int noisePoints = 0;
    int heatPoints = 0;

    int passedPoints = 0;
    int actionLevelPoints = 0;
    int failedPoints = 0;

    int lightPassed = 0;
    int lightFailed = 0;

    int noiseNormal = 0;
    int noiseActionLevel = 0;
    int noiseExceeded = 0;

    int heatPassed = 0;
    int heatFailed = 0;

    int hcpRequiredCount = 0;
    int capaRequiredCount = 0;

    for (final pt in points) {
      if (pt.isPass) {
        passedPoints++;
      } else if (pt.isActionLevel) {
        actionLevelPoints++;
      } else if (pt.isFail) {
        failedPoints++;
      }

      if (pt.requiresCapa) {
        capaRequiredCount++;
      }

      switch (pt.factorType) {
        case EnvironmentFactorType.light:
          lightPoints++;
          if (pt.isPass) {
            lightPassed++;
          } else {
            lightFailed++;
          }
          break;

        case EnvironmentFactorType.noise:
          noisePoints++;
          if (pt.isPass) {
            noiseNormal++;
          } else if (pt.isActionLevel) {
            noiseActionLevel++;
          } else {
            noiseExceeded++;
          }
          if (pt.requiresHearingConservation) {
            hcpRequiredCount++;
          }
          break;

        case EnvironmentFactorType.heat:
          heatPoints++;
          if (pt.isPass) {
            heatPassed++;
          } else {
            heatFailed++;
          }
          break;
      }
    }

    int capaTotal = 0;
    int capaCompleted = 0;
    int capaPending = 0;
    int capaOverdue = 0;

    if (capas != null && capas.isNotEmpty) {
      capaTotal = capas.length;
      for (final c in capas) {
        if (c.isCompleted) {
          capaCompleted++;
        } else if (c.isOverdue) {
          capaOverdue++;
        } else {
          capaPending++;
        }
      }
    }

    double round1(double val) => (val * 10).roundToDouble() / 10;

    final overallComp = totalPoints == 0
        ? 100.0
        : round1((passedPoints / totalPoints) * 100.0);

    final lightComp = lightPoints == 0
        ? 100.0
        : round1((lightPassed / lightPoints) * 100.0);

    final noiseComp = noisePoints == 0
        ? 100.0
        : round1((noiseNormal / noisePoints) * 100.0);

    final heatComp = heatPoints == 0
        ? 100.0
        : round1((heatPassed / heatPoints) * 100.0);

    return EnvironmentKpiSummary(
      totalPoints: totalPoints,
      lightPoints: lightPoints,
      noisePoints: noisePoints,
      heatPoints: heatPoints,
      passedPoints: passedPoints,
      actionLevelPoints: actionLevelPoints,
      failedPoints: failedPoints,
      lightPassed: lightPassed,
      lightFailed: lightFailed,
      noiseNormal: noiseNormal,
      noiseActionLevel: noiseActionLevel,
      noiseExceeded: noiseExceeded,
      heatPassed: heatPassed,
      heatFailed: heatFailed,
      hcpRequiredCount: hcpRequiredCount,
      capaRequiredCount: capaRequiredCount,
      capaTotalCount: capaTotal,
      capaCompletedCount: capaCompleted,
      capaPendingCount: capaPending,
      capaOverdueCount: capaOverdue,
      compliancePercentage: overallComp,
      lightCompliancePercentage: lightComp,
      noiseCompliancePercentage: noiseComp,
      heatCompliancePercentage: heatComp,
      calculatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_points': totalPoints,
      'light_points': lightPoints,
      'noise_points': noisePoints,
      'heat_points': heatPoints,
      'passed_points': passedPoints,
      'action_level_points': actionLevelPoints,
      'failed_points': failedPoints,
      'light_passed': lightPassed,
      'light_failed': lightFailed,
      'noise_normal': noiseNormal,
      'noise_action_level': noiseActionLevel,
      'noise_exceeded': noiseExceeded,
      'heat_passed': heatPassed,
      'heat_failed': heatFailed,
      'hcp_required_count': hcpRequiredCount,
      'capa_required_count': capaRequiredCount,
      'capa_total_count': capaTotalCount,
      'capa_completed_count': capaCompletedCount,
      'capa_pending_count': capaPendingCount,
      'capa_overdue_count': capaOverdueCount,
      'compliance_percentage': compliancePercentage,
      'light_compliance_percentage': lightCompliancePercentage,
      'noise_compliance_percentage': noiseCompliancePercentage,
      'heat_compliance_percentage': heatCompliancePercentage,
      'calculated_at': calculatedAt,
    };
  }

  factory EnvironmentKpiSummary.fromMap(Map<String, dynamic> map) {
    return EnvironmentKpiSummary(
      totalPoints: map['total_points'] as int? ?? 0,
      lightPoints: map['light_points'] as int? ?? 0,
      noisePoints: map['noise_points'] as int? ?? 0,
      heatPoints: map['heat_points'] as int? ?? 0,
      passedPoints: map['passed_points'] as int? ?? 0,
      actionLevelPoints: map['action_level_points'] as int? ?? 0,
      failedPoints: map['failed_points'] as int? ?? 0,
      lightPassed: map['light_passed'] as int? ?? 0,
      lightFailed: map['light_failed'] as int? ?? 0,
      noiseNormal: map['noise_normal'] as int? ?? 0,
      noiseActionLevel: map['noise_action_level'] as int? ?? 0,
      noiseExceeded: map['noise_exceeded'] as int? ?? 0,
      heatPassed: map['heat_passed'] as int? ?? 0,
      heatFailed: map['heat_failed'] as int? ?? 0,
      hcpRequiredCount: map['hcp_required_count'] as int? ?? 0,
      capaRequiredCount: map['capa_required_count'] as int? ?? 0,
      capaTotalCount: map['capa_total_count'] as int? ?? 0,
      capaCompletedCount: map['capa_completed_count'] as int? ?? 0,
      capaPendingCount: map['capa_pending_count'] as int? ?? 0,
      capaOverdueCount: map['capa_overdue_count'] as int? ?? 0,
      compliancePercentage: (map['compliance_percentage'] as num?)?.toDouble() ?? 100.0,
      lightCompliancePercentage: (map['light_compliance_percentage'] as num?)?.toDouble() ?? 100.0,
      noiseCompliancePercentage: (map['noise_compliance_percentage'] as num?)?.toDouble() ?? 100.0,
      heatCompliancePercentage: (map['heat_compliance_percentage'] as num?)?.toDouble() ?? 100.0,
      calculatedAt: map['calculated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => json.encode(toMap());

  factory EnvironmentKpiSummary.fromJson(String source) =>
      EnvironmentKpiSummary.fromMap(json.decode(source) as Map<String, dynamic>);
}
