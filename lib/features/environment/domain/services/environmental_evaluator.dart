import 'dart:math' as math;
import '../models/environment_standard_model.dart';
import '../models/environment_point_model.dart';
import '../models/environment_capa_model.dart';
import '../models/environment_kpi_summary.dart';
import '../../data/environmental_standards_data.dart';

/// Result object for Lighting evaluation.
class LightEvaluationResult {
  final double measuredLux;
  final double standardMinLux;
  final double? surroundingLux;
  final double? surroundingRatio;
  final bool isCompliant;
  final bool hasSurroundingWarning;
  final double deficitLux;
  final EnvironmentEvaluationStatus status;
  final String summaryTh;

  const LightEvaluationResult({
    required this.measuredLux,
    required this.standardMinLux,
    this.surroundingLux,
    this.surroundingRatio,
    required this.isCompliant,
    required this.hasSurroundingWarning,
    required this.deficitLux,
    required this.status,
    required this.summaryTh,
  });
}

/// Result object for Noise evaluation.
class NoiseEvaluationResult {
  final double measuredDba;
  final double? peakDb;
  final double exposureDurationHours;
  final double permissibleDurationHours;
  final double noiseDosePercent;
  final double twa8hrDba;
  final bool isCeilingExceeded;
  final bool isPeakExceeded;
  final bool isStandardExceeded;
  final bool isHcpRequired;
  final String evaluationTier; // 'NORMAL', 'ACTION_LEVEL_HCP', 'EXCEEDED_STANDARD'
  final EnvironmentEvaluationStatus status;
  final String summaryTh;

  const NoiseEvaluationResult({
    required this.measuredDba,
    this.peakDb,
    required this.exposureDurationHours,
    required this.permissibleDurationHours,
    required this.noiseDosePercent,
    required this.twa8hrDba,
    required this.isCeilingExceeded,
    required this.isPeakExceeded,
    required this.isStandardExceeded,
    required this.isHcpRequired,
    required this.evaluationTier,
    required this.status,
    required this.summaryTh,
  });
}

/// Result object for Heat WBGT evaluation.
class HeatEvaluationResult {
  final double nwb;
  final double gt;
  final double? db;
  final bool isOutdoor;
  final double calculatedWbgt;
  final WorkloadLevel workload;
  final double standardLimitCelsius;
  final bool isCompliant;
  final double exceededMargin;
  final EnvironmentEvaluationStatus status;
  final String formulaDescription;
  final String summaryTh;

  const HeatEvaluationResult({
    required this.nwb,
    required this.gt,
    this.db,
    required this.isOutdoor,
    required this.calculatedWbgt,
    required this.workload,
    required this.standardLimitCelsius,
    required this.isCompliant,
    required this.exceededMargin,
    required this.status,
    required this.formulaDescription,
    required this.summaryTh,
  });
}

/// Core statutory calculation and auto-evaluation engine for SAFAPP Environmental Monitoring.
class EnvironmentalEvaluator {
  EnvironmentalEvaluator._();

  // =========================================================================
  // 1. Lighting Evaluation Engine (DLPW B.E. 2561)
  // =========================================================================

  /// Evaluates lighting intensity (Lux) at the workstation against the statutory standard.
  static LightEvaluationResult evaluateLighting({
    required double measuredLux,
    String? standardId,
    double? standardMinLux,
    double? surroundingLux,
  }) {
    double minLux = standardMinLux ?? 300.0;

    if (standardId != null && standardId.isNotEmpty) {
      final std = EnvironmentalStandardsData.findById(standardId);
      if (std != null && std.minLux != null) {
        minLux = std.minLux!;
      }
    }

    final isCompliant = measuredLux >= minLux;
    final deficitLux = isCompliant ? 0.0 : (minLux - measuredLux);

    bool surroundingWarning = false;
    double? ratio;
    if (surroundingLux != null && measuredLux > 0) {
      ratio = surroundingLux / measuredLux;
      // DLPW Notification 2561 Category 3: Surrounding area must be >= 1/3 (0.333) of task area
      if (ratio < 0.333) {
        surroundingWarning = true;
      }
    }

    final status = isCompliant
        ? EnvironmentEvaluationStatus.pass
        : EnvironmentEvaluationStatus.fail;

    String summary;
    if (isCompliant) {
      summary = 'ผ่านเกณฑ์มาตรฐาน (${measuredLux.toStringAsFixed(1)} >= $minLux Lux)';
      if (surroundingWarning) {
        summary += ' *ข้อควรระวัง: ความสว่างบริเวณรอบข้าง (${surroundingLux?.toStringAsFixed(1)} Lux) ต่ำกว่า ๑ ใน ๓ ของจุดทำงาน';
      }
    } else {
      summary = 'ไม่ผ่านเกณฑ์มาตรฐาน: ขาดอีก ${deficitLux.toStringAsFixed(1)} Lux (วัดได้ ${measuredLux.toStringAsFixed(1)} / มาตรฐาน $minLux Lux)';
    }

    return LightEvaluationResult(
      measuredLux: measuredLux,
      standardMinLux: minLux,
      surroundingLux: surroundingLux,
      surroundingRatio: ratio,
      isCompliant: isCompliant,
      hasSurroundingWarning: surroundingWarning,
      deficitLux: deficitLux,
      status: status,
      summaryTh: summary,
    );
  }

  // =========================================================================
  // 2. Noise Evaluation Engine (DLPW B.E. 2561 & Reg 2559)
  // =========================================================================

  /// Calculates permissible noise exposure duration in hours using DLPW 3-dB exchange rate formula:
  /// T = 8 / 2^((L - 86) / 3)
  static double calculatePermissibleDuration(double measuredDba) {
    if (measuredDba >= 115.0) {
      // 115 dBA ceiling: 28.125 seconds = 28.125 / 3600 hours = 0.0078125 hours
      return 28.125 / 3600.0;
    }
    final power = (measuredDba - 86.0) / 3.0;
    return 8.0 / math.pow(2.0, power);
  }

  /// Calculates cumulative Noise Dose (%) for a given sound level and exposure duration.
  static double calculateNoiseDose(double measuredDba, double exposureHours) {
    final permissible = calculatePermissibleDuration(measuredDba);
    if (permissible <= 0) return 1000.0;
    return (exposureHours / permissible) * 100.0;
  }

  /// Calculates 8-Hour Time-Weighted Average (TWA) from cumulative Noise Dose (%).
  /// TWA = 86 + (3 / log10(2)) * log10(Dose / 100) = 86 + 9.965784 * log10(Dose / 100)
  static double calculateNoiseTwa(double dosePercent) {
    if (dosePercent <= 0) return 0.0;
    const factor = 9.965784284662087; // 3.0 / log10(2.0)
    final log10Val = math.log(dosePercent / 100.0) / math.ln10;
    return 86.0 + factor * log10Val;
  }

  /// Calculates composite Dose & TWA from multiple exposure periods.
  static ({double totalDose, double twa8hr}) calculateMultiExposureTwa(
    List<({double dba, double durationHours})> exposures,
  ) {
    double totalDose = 0.0;
    for (final exp in exposures) {
      totalDose += calculateNoiseDose(exp.dba, exp.durationHours);
    }
    final twa = calculateNoiseTwa(totalDose);
    return (totalDose: totalDose, twa8hr: twa);
  }

  /// Comprehensive noise compliance and Hearing Conservation Program (HCP) evaluator.
  static NoiseEvaluationResult evaluateNoise({
    required double measuredDba,
    required NoiseMeasurementType type,
    double durationHours = 8.0,
    double? peakDb,
  }) {
    final permissibleDuration = calculatePermissibleDuration(measuredDba);
    final dose = calculateNoiseDose(measuredDba, durationHours);
    final twa = (type == NoiseMeasurementType.leq8hrTwa && durationHours == 8.0)
        ? measuredDba
        : calculateNoiseTwa(dose);

    final isCeilingExceeded = measuredDba >= 115.0;
    final isPeakExceeded = peakDb != null && peakDb > 140.0;

    // Standard limits: TWA <= 86.0 dBA, Peak <= 140.0 dB, Continuous < 115.0 dBA
    final isStandardExceeded = isCeilingExceeded ||
        isPeakExceeded ||
        twa > 86.0 ||
        dose > 100.0;

    // Action level (HCP Trigger): TWA >= 85.0 dBA or Dose >= 79.37% (or measured >= 85.0 for 8hr)
    final isHcpRequired = twa >= 85.0 || dose >= 79.37 || measuredDba >= 85.0;

    String tier;
    EnvironmentEvaluationStatus status;
    String summary;

    if (isStandardExceeded) {
      tier = 'EXCEEDED_STANDARD';
      status = EnvironmentEvaluationStatus.fail;
      if (isPeakExceeded) {
        summary = 'เกินเกณฑ์มาตรฐานขั้นวิกฤต: เสียงกระทบ/กระแทก ($peakDb dB Peak) เกินเพดาน 140 dB';
      } else if (isCeilingExceeded) {
        summary = 'เกินเกณฑ์มาตรฐานขั้นวิกฤต: ระดับเสียงต่อเนื่อง ($measuredDba dBA) เกินเพดานสูงสุด 115 dBA';
      } else {
        summary = 'เกินเกณฑ์มาตรฐานกฎหมาย: เสียงเฉลี่ย 8 ชม. (${twa.toStringAsFixed(1)} dBA) เกิน 86 dBA (Dose ${dose.toStringAsFixed(1)}%)';
      }
    } else if (isHcpRequired) {
      tier = 'ACTION_LEVEL_HCP';
      status = EnvironmentEvaluationStatus.actionLevel;
      summary = 'เฝ้าระวัง Action Level: เสียงเฉลี่ย 8 ชม. (${twa.toStringAsFixed(1)} dBA) ถึงเกณฑ์ 85 dBA บังคับจัดทำโครงการอนุรักษ์การได้ยิน';
    } else {
      tier = 'NORMAL';
      status = EnvironmentEvaluationStatus.pass;
      summary = 'ปกติ ผ่านเกณฑ์มาตรฐาน: เสียงเฉลี่ย 8 ชม. (${twa.toStringAsFixed(1)} dBA <= 85 dBA)';
    }

    return NoiseEvaluationResult(
      measuredDba: measuredDba,
      peakDb: peakDb,
      exposureDurationHours: durationHours,
      permissibleDurationHours: permissibleDuration,
      noiseDosePercent: dose,
      twa8hrDba: twa,
      isCeilingExceeded: isCeilingExceeded,
      isPeakExceeded: isPeakExceeded,
      isStandardExceeded: isStandardExceeded,
      isHcpRequired: isHcpRequired,
      evaluationTier: tier,
      status: status,
      summaryTh: summary,
    );
  }

  // =========================================================================
  // 3. Heat WBGT Evaluation Engine (DLPW B.E. 2563 & Reg 2559)
  // =========================================================================

  /// Calculates WBGT temperature based on indoor/outdoor solar radiation formula:
  /// - Indoor (No Solar): 0.7 * NWB + 0.3 * GT
  /// - Outdoor (With Solar): 0.7 * NWB + 0.2 * GT + 0.1 * DB
  static double calculateWbgt({
    required double nwb,
    required double gt,
    double? db,
    required bool isOutdoor,
  }) {
    if (isOutdoor) {
      final dryBulb = db ?? gt;
      final val = 0.7 * nwb + 0.2 * gt + 0.1 * dryBulb;
      return (val * 100).roundToDouble() / 100;
    } else {
      final val = 0.7 * nwb + 0.3 * gt;
      return (val * 100).roundToDouble() / 100;
    }
  }

  /// Comprehensive Heat WBGT evaluator against metabolic workload thresholds.
  static HeatEvaluationResult evaluateHeat({
    required double nwb,
    required double gt,
    double? db,
    required bool isOutdoor,
    required WorkloadLevel workload,
  }) {
    final wbgt = calculateWbgt(
      nwb: nwb,
      gt: gt,
      db: db,
      isOutdoor: isOutdoor,
    );

    final limit = workload.statutoryLimitCelsius;
    final isCompliant = wbgt <= limit;
    final margin = isCompliant ? 0.0 : (wbgt - limit);

    final status = isCompliant
        ? EnvironmentEvaluationStatus.pass
        : EnvironmentEvaluationStatus.fail;

    final formulaStr = isOutdoor
        ? 'WBGT กลางแจ้ง = 0.7($nwb) + 0.2($gt) + 0.1(${db ?? gt}) = $wbgt °C'
        : 'WBGT ในร่ม = 0.7($nwb) + 0.3($gt) = $wbgt °C';

    String summary;
    if (isCompliant) {
      summary = 'ผ่านเกณฑ์มาตรฐาน: ค่า WBGT $wbgt °C ไม่เกินเกณฑ์ ${workload.labelTh} ($limit °C)';
    } else {
      summary = 'เกินเกณฑ์มาตรฐาน: ค่า WBGT $wbgt °C เกินเกณฑ์ ${workload.labelTh} ($limit °C) อยู่ ${margin.toStringAsFixed(2)} °C';
    }

    return HeatEvaluationResult(
      nwb: nwb,
      gt: gt,
      db: db,
      isOutdoor: isOutdoor,
      calculatedWbgt: wbgt,
      workload: workload,
      standardLimitCelsius: limit,
      isCompliant: isCompliant,
      exceededMargin: margin,
      status: status,
      formulaDescription: formulaStr,
      summaryTh: summary,
    );
  }

  /// Calculates Time-Weighted Average WBGT and Metabolic Rate for multi-task work cycles (DLPW 2563 Cl. 6).
  static ({
    double twaWbgt,
    double twaMetabolicRate,
    WorkloadLevel effectiveWorkload,
    bool isCompliant,
  }) calculateTimeWeightedWbgt(
    List<({double wbgt, double minutes, double metabolicRate})> stages,
  ) {
    if (stages.isEmpty) {
      return (
        twaWbgt: 0.0,
        twaMetabolicRate: 0.0,
        effectiveWorkload: WorkloadLevel.light,
        isCompliant: true,
      );
    }

    double totalMinutes = 0.0;
    double weightedWbgtSum = 0.0;
    double weightedMetaSum = 0.0;

    for (final s in stages) {
      totalMinutes += s.minutes;
      weightedWbgtSum += (s.wbgt * s.minutes);
      weightedMetaSum += (s.metabolicRate * s.minutes);
    }

    if (totalMinutes <= 0) {
      return (
        twaWbgt: 0.0,
        twaMetabolicRate: 0.0,
        effectiveWorkload: WorkloadLevel.light,
        isCompliant: true,
      );
    }

    final avgWbgt = (weightedWbgtSum / totalMinutes * 100).roundToDouble() / 100;
    final avgMeta = (weightedMetaSum / totalMinutes * 10).roundToDouble() / 10;

    WorkloadLevel effectiveLevel;
    if (avgMeta <= 200.0) {
      effectiveLevel = WorkloadLevel.light;
    } else if (avgMeta <= 350.0) {
      effectiveLevel = WorkloadLevel.moderate;
    } else {
      effectiveLevel = WorkloadLevel.heavy;
    }

    final isCompliant = avgWbgt <= effectiveLevel.statutoryLimitCelsius;

    return (
      twaWbgt: avgWbgt,
      twaMetabolicRate: avgMeta,
      effectiveWorkload: effectiveLevel,
      isCompliant: isCompliant,
    );
  }

  // =========================================================================
  // 4. Overall KPI Summary Calculation
  // =========================================================================

  /// Calculates composite KPI metrics across points and CAPA actions.
  static EnvironmentKpiSummary calculateKpi(
    List<EnvironmentPointModel> points, {
    List<EnvironmentCapaModel>? capas,
  }) {
    return EnvironmentKpiSummary.calculate(points: points, capas: capas);
  }
}
