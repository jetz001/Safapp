import 'dart:convert';
import 'environment_standard_model.dart';

/// Overall compliance evaluation status for a measurement point.
enum EnvironmentEvaluationStatus {
  pass,
  actionLevel,
  fail;

  String toDbCode() {
    switch (this) {
      case EnvironmentEvaluationStatus.pass:
        return 'PASS';
      case EnvironmentEvaluationStatus.actionLevel:
        return 'ACTION_LEVEL';
      case EnvironmentEvaluationStatus.fail:
        return 'FAIL';
    }
  }

  static EnvironmentEvaluationStatus fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'PASS':
      case 'COMPLIANT':
        return EnvironmentEvaluationStatus.pass;
      case 'ACTION_LEVEL':
      case 'ACTION_LEVEL_HCP':
      case 'WATCH':
        return EnvironmentEvaluationStatus.actionLevel;
      case 'FAIL':
      case 'EXCEEDED':
      case 'EXCEEDED_STANDARD':
      case 'NON_COMPLIANT':
        return EnvironmentEvaluationStatus.fail;
      default:
        return EnvironmentEvaluationStatus.pass;
    }
  }

  String get labelTh {
    switch (this) {
      case EnvironmentEvaluationStatus.pass:
        return 'ผ่านเกณฑ์มาตรฐาน';
      case EnvironmentEvaluationStatus.actionLevel:
        return 'เฝ้าระวัง (Action Level >= 85 dBA)';
      case EnvironmentEvaluationStatus.fail:
        return 'เกินเกณฑ์มาตรฐาน (ต้องปรับปรุง CAPA)';
    }
  }
}

/// Noise measurement classification.
enum NoiseMeasurementType {
  leq8hrTwa,
  areaNoise,
  peakSoundLevel;

  String toDbCode() {
    switch (this) {
      case NoiseMeasurementType.leq8hrTwa:
        return 'LEQ_8HR_TWA';
      case NoiseMeasurementType.areaNoise:
        return 'AREA_NOISE';
      case NoiseMeasurementType.peakSoundLevel:
        return 'PEAK_SOUND_LEVEL';
    }
  }

  static NoiseMeasurementType fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'LEQ_8HR_TWA':
      case 'PERSONAL_TWA':
      case 'TWA':
        return NoiseMeasurementType.leq8hrTwa;
      case 'AREA_NOISE':
      case 'AREA':
        return NoiseMeasurementType.areaNoise;
      case 'PEAK_SOUND_LEVEL':
      case 'PEAK':
        return NoiseMeasurementType.peakSoundLevel;
      default:
        return NoiseMeasurementType.leq8hrTwa;
    }
  }

  String get labelTh {
    switch (this) {
      case NoiseMeasurementType.leq8hrTwa:
        return 'เสียงเฉลี่ย 8 ชม. (Leq 8-hr TWA)';
      case NoiseMeasurementType.areaNoise:
        return 'เสียงตามพื้นที่ (Area Noise)';
      case NoiseMeasurementType.peakSoundLevel:
        return 'เสียงกระทบ/กระแทก (Peak dB)';
    }
  }
}

/// Heat solar exposure classification for WBGT calculation.
enum HeatSolarExposure {
  indoorNoSolar,
  outdoorWithSolar;

  String toDbCode() {
    switch (this) {
      case HeatSolarExposure.indoorNoSolar:
        return 'INDOOR_NO_SOLAR';
      case HeatSolarExposure.outdoorWithSolar:
        return 'OUTDOOR_WITH_SOLAR';
    }
  }

  static HeatSolarExposure fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'INDOOR_NO_SOLAR':
      case 'INDOOR':
        return HeatSolarExposure.indoorNoSolar;
      case 'OUTDOOR_WITH_SOLAR':
      case 'OUTDOOR':
        return HeatSolarExposure.outdoorWithSolar;
      default:
        return HeatSolarExposure.indoorNoSolar;
    }
  }

  String get labelTh {
    switch (this) {
      case HeatSolarExposure.indoorNoSolar:
        return 'ในร่ม / ไม่มีแสงแดดส่องถึง (0.7 NWB + 0.3 GT)';
      case HeatSolarExposure.outdoorWithSolar:
        return 'กลางแจ้ง / มีแสงแดดส่องถึง (0.7 NWB + 0.2 GT + 0.1 DB)';
    }
  }
}

/// Model representing a single Environmental Sampling & Measurement Point (จุดตรวจวัด).
class EnvironmentPointModel {
  final int? id;
  final String pointId; // e.g. 'PT-ENV-LIGHT-001'
  final String sessionId; // e.g. 'ENV-SESS-2026-001'
  final EnvironmentFactorType factorType;
  final String department;
  final String locationName;
  final String? taskOrMachineName;
  final EnvironmentEvaluationStatus evaluationStatus;
  final String? notes;
  final String? capaId;
  final String? createdAt;
  final String? updatedAt;

  // --- Lighting Specific Fields ---
  final String? lightCategoryCode;
  final String? lightTaskDescription;
  final double? lightMeasuredLux;
  final double? lightStandardMinLux;
  final double? lightSurroundingLux;
  final bool? lightIsCompliant;

  // --- Noise Specific Fields ---
  final NoiseMeasurementType? noiseMeasurementType;
  final double? noiseMeasuredDba;
  final double? noisePeakDb;
  final double? noiseExposureDurationHours;
  final double? noiseDosePercent;
  final double noiseStandardTwaLimit; // Default 86.0
  final double noiseActionLevelThreshold; // Default 85.0
  final double noiseContinuousCeilingLimit; // Default 115.0
  final double noisePeakLimit; // Default 140.0
  final bool noiseIsHcpRequired;
  final String? noiseEvaluationTier; // 'NORMAL', 'ACTION_LEVEL_HCP', 'EXCEEDED_STANDARD'

  // --- Heat Specific Fields ---
  final HeatSolarExposure? heatSolarExposure;
  final double? heatNwbCelsius;
  final double? heatGtCelsius;
  final double? heatDbCelsius;
  final double? heatCalculatedWbgt;
  final WorkloadLevel? heatWorkloadType;
  final double? heatMetabolicRateKcalHr;
  final double? heatStandardLimitWbgt;
  final bool? heatIsCompliant;

  const EnvironmentPointModel({
    this.id,
    required this.pointId,
    required this.sessionId,
    required this.factorType,
    required this.department,
    required this.locationName,
    this.taskOrMachineName,
    required this.evaluationStatus,
    this.notes,
    this.capaId,
    this.createdAt,
    this.updatedAt,
    // Light
    this.lightCategoryCode,
    this.lightTaskDescription,
    this.lightMeasuredLux,
    this.lightStandardMinLux,
    this.lightSurroundingLux,
    this.lightIsCompliant,
    // Noise
    this.noiseMeasurementType,
    this.noiseMeasuredDba,
    this.noisePeakDb,
    this.noiseExposureDurationHours,
    this.noiseDosePercent,
    this.noiseStandardTwaLimit = 86.0,
    this.noiseActionLevelThreshold = 85.0,
    this.noiseContinuousCeilingLimit = 115.0,
    this.noisePeakLimit = 140.0,
    this.noiseIsHcpRequired = false,
    this.noiseEvaluationTier,
    // Heat
    this.heatSolarExposure,
    this.heatNwbCelsius,
    this.heatGtCelsius,
    this.heatDbCelsius,
    this.heatCalculatedWbgt,
    this.heatWorkloadType,
    this.heatMetabolicRateKcalHr,
    this.heatStandardLimitWbgt,
    this.heatIsCompliant,
  });

  bool get isPass => evaluationStatus == EnvironmentEvaluationStatus.pass;
  bool get isActionLevel => evaluationStatus == EnvironmentEvaluationStatus.actionLevel;
  bool get isFail => evaluationStatus == EnvironmentEvaluationStatus.fail;

  bool get requiresHearingConservation {
    if (factorType == EnvironmentFactorType.noise) {
      return noiseIsHcpRequired ||
          evaluationStatus == EnvironmentEvaluationStatus.actionLevel ||
          (noiseMeasuredDba != null && noiseMeasuredDba! >= 85.0);
    }
    return false;
  }

  bool get requiresCapa => isFail || isActionLevel;

  String get summaryValueDisplay {
    switch (factorType) {
      case EnvironmentFactorType.light:
        return '${lightMeasuredLux?.toStringAsFixed(1) ?? "-"} Lux (เกณฑ์ >= ${lightStandardMinLux?.toStringAsFixed(0) ?? "-"})';
      case EnvironmentFactorType.noise:
        if (noiseMeasurementType == NoiseMeasurementType.peakSoundLevel) {
          return '${noisePeakDb?.toStringAsFixed(1) ?? "-"} Peak dB (เกณฑ์ <= ${noisePeakLimit.toStringAsFixed(0)})';
        }
        return '${noiseMeasuredDba?.toStringAsFixed(1) ?? "-"} dBA (เกณฑ์ <= ${noiseStandardTwaLimit.toStringAsFixed(0)})';
      case EnvironmentFactorType.heat:
        return 'WBGT ${heatCalculatedWbgt?.toStringAsFixed(2) ?? "-"} °C (เกณฑ์ <= ${heatStandardLimitWbgt?.toStringAsFixed(1) ?? "-"} °C)';
    }
  }

  EnvironmentPointModel copyWith({
    int? id,
    String? pointId,
    String? sessionId,
    EnvironmentFactorType? factorType,
    String? department,
    String? locationName,
    String? taskOrMachineName,
    EnvironmentEvaluationStatus? evaluationStatus,
    String? notes,
    String? capaId,
    String? createdAt,
    String? updatedAt,
    String? lightCategoryCode,
    String? lightTaskDescription,
    double? lightMeasuredLux,
    double? lightStandardMinLux,
    double? lightSurroundingLux,
    bool? lightIsCompliant,
    NoiseMeasurementType? noiseMeasurementType,
    double? noiseMeasuredDba,
    double? noisePeakDb,
    double? noiseExposureDurationHours,
    double? noiseDosePercent,
    double? noiseStandardTwaLimit,
    double? noiseActionLevelThreshold,
    double? noiseContinuousCeilingLimit,
    double? noisePeakLimit,
    bool? noiseIsHcpRequired,
    String? noiseEvaluationTier,
    HeatSolarExposure? heatSolarExposure,
    double? heatNwbCelsius,
    double? heatGtCelsius,
    double? heatDbCelsius,
    double? heatCalculatedWbgt,
    WorkloadLevel? heatWorkloadType,
    double? heatMetabolicRateKcalHr,
    double? heatStandardLimitWbgt,
    bool? heatIsCompliant,
  }) {
    return EnvironmentPointModel(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      sessionId: sessionId ?? this.sessionId,
      factorType: factorType ?? this.factorType,
      department: department ?? this.department,
      locationName: locationName ?? this.locationName,
      taskOrMachineName: taskOrMachineName ?? this.taskOrMachineName,
      evaluationStatus: evaluationStatus ?? this.evaluationStatus,
      notes: notes ?? this.notes,
      capaId: capaId ?? this.capaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lightCategoryCode: lightCategoryCode ?? this.lightCategoryCode,
      lightTaskDescription: lightTaskDescription ?? this.lightTaskDescription,
      lightMeasuredLux: lightMeasuredLux ?? this.lightMeasuredLux,
      lightStandardMinLux: lightStandardMinLux ?? this.lightStandardMinLux,
      lightSurroundingLux: lightSurroundingLux ?? this.lightSurroundingLux,
      lightIsCompliant: lightIsCompliant ?? this.lightIsCompliant,
      noiseMeasurementType: noiseMeasurementType ?? this.noiseMeasurementType,
      noiseMeasuredDba: noiseMeasuredDba ?? this.noiseMeasuredDba,
      noisePeakDb: noisePeakDb ?? this.noisePeakDb,
      noiseExposureDurationHours: noiseExposureDurationHours ?? this.noiseExposureDurationHours,
      noiseDosePercent: noiseDosePercent ?? this.noiseDosePercent,
      noiseStandardTwaLimit: noiseStandardTwaLimit ?? this.noiseStandardTwaLimit,
      noiseActionLevelThreshold: noiseActionLevelThreshold ?? this.noiseActionLevelThreshold,
      noiseContinuousCeilingLimit: noiseContinuousCeilingLimit ?? this.noiseContinuousCeilingLimit,
      noisePeakLimit: noisePeakLimit ?? this.noisePeakLimit,
      noiseIsHcpRequired: noiseIsHcpRequired ?? this.noiseIsHcpRequired,
      noiseEvaluationTier: noiseEvaluationTier ?? this.noiseEvaluationTier,
      heatSolarExposure: heatSolarExposure ?? this.heatSolarExposure,
      heatNwbCelsius: heatNwbCelsius ?? this.heatNwbCelsius,
      heatGtCelsius: heatGtCelsius ?? this.heatGtCelsius,
      heatDbCelsius: heatDbCelsius ?? this.heatDbCelsius,
      heatCalculatedWbgt: heatCalculatedWbgt ?? this.heatCalculatedWbgt,
      heatWorkloadType: heatWorkloadType ?? this.heatWorkloadType,
      heatMetabolicRateKcalHr: heatMetabolicRateKcalHr ?? this.heatMetabolicRateKcalHr,
      heatStandardLimitWbgt: heatStandardLimitWbgt ?? this.heatStandardLimitWbgt,
      heatIsCompliant: heatIsCompliant ?? this.heatIsCompliant,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'point_id': pointId,
      'session_id': sessionId,
      'factor_type': factorType.toDbCode(),
      'department': department,
      'location_name': locationName,
      'task_or_machine_name': taskOrMachineName,
      'evaluation_status': evaluationStatus.toDbCode(),
      'notes': notes,
      'capa_id': capaId,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
      // Light
      'light_category_code': lightCategoryCode,
      'light_task_description': lightTaskDescription,
      'light_measured_lux': lightMeasuredLux,
      'light_standard_min_lux': lightStandardMinLux,
      'light_surrounding_lux': lightSurroundingLux,
      'light_is_compliant': lightIsCompliant == null ? null : (lightIsCompliant! ? 1 : 0),
      // Noise
      'noise_measurement_type': noiseMeasurementType?.toDbCode(),
      'noise_measured_dba': noiseMeasuredDba,
      'noise_peak_db': noisePeakDb,
      'noise_exposure_duration_hours': noiseExposureDurationHours,
      'noise_dose_percent': noiseDosePercent,
      'noise_standard_twa_limit': noiseStandardTwaLimit,
      'noise_action_level_threshold': noiseActionLevelThreshold,
      'noise_continuous_ceiling_limit': noiseContinuousCeilingLimit,
      'noise_peak_limit': noisePeakLimit,
      'noise_is_hcp_required': noiseIsHcpRequired ? 1 : 0,
      'noise_evaluation_tier': noiseEvaluationTier,
      // Heat
      'heat_solar_exposure': heatSolarExposure?.toDbCode(),
      'heat_nwb_celsius': heatNwbCelsius,
      'heat_gt_celsius': heatGtCelsius,
      'heat_db_celsius': heatDbCelsius,
      'heat_calculated_wbgt': heatCalculatedWbgt,
      'heat_workload_type': heatWorkloadType?.toDbCode(),
      'heat_metabolic_rate_kcal_hr': heatMetabolicRateKcalHr,
      'heat_standard_limit_wbgt': heatStandardLimitWbgt,
      'heat_is_compliant': heatIsCompliant == null ? null : (heatIsCompliant! ? 1 : 0),
    };
  }

  factory EnvironmentPointModel.fromMap(Map<String, dynamic> map) {
    return EnvironmentPointModel(
      id: map['id'] as int?,
      pointId: map['point_id'] as String? ?? map['pointId'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? map['sessionId'] as String? ?? '',
      factorType: EnvironmentFactorType.fromDbCode(
        map['factor_type'] as String? ?? map['factorType'] as String? ?? 'LIGHT',
      ),
      department: map['department'] as String? ?? '',
      locationName: map['location_name'] as String? ?? map['locationName'] as String? ?? '',
      taskOrMachineName: map['task_or_machine_name'] as String? ?? map['taskOrMachineName'] as String?,
      evaluationStatus: EnvironmentEvaluationStatus.fromDbCode(
        map['evaluation_status'] as String? ?? map['evaluationStatus'] as String?,
      ),
      notes: map['notes'] as String?,
      capaId: map['capa_id'] as String? ?? map['capaId'] as String?,
      createdAt: map['created_at'] as String? ?? map['createdAt'] as String?,
      updatedAt: map['updated_at'] as String? ?? map['updatedAt'] as String?,
      // Light
      lightCategoryCode: map['light_category_code'] as String? ?? map['lightCategoryCode'] as String?,
      lightTaskDescription: map['light_task_description'] as String? ?? map['lightTaskDescription'] as String?,
      lightMeasuredLux: (map['light_measured_lux'] as num?)?.toDouble() ??
          (map['lightMeasuredLux'] as num?)?.toDouble(),
      lightStandardMinLux: (map['light_standard_min_lux'] as num?)?.toDouble() ??
          (map['lightStandardMinLux'] as num?)?.toDouble(),
      lightSurroundingLux: (map['light_surrounding_lux'] as num?)?.toDouble() ??
          (map['lightSurroundingLux'] as num?)?.toDouble(),
      lightIsCompliant: map['light_is_compliant'] == 1 || map['light_is_compliant'] == true || map['lightIsCompliant'] == true,
      // Noise
      noiseMeasurementType: map['noise_measurement_type'] != null
          ? NoiseMeasurementType.fromDbCode(map['noise_measurement_type'] as String)
          : (map['noiseMeasurementType'] != null
              ? NoiseMeasurementType.fromDbCode(map['noiseMeasurementType'] as String)
              : null),
      noiseMeasuredDba: (map['noise_measured_dba'] as num?)?.toDouble() ??
          (map['noiseMeasuredDba'] as num?)?.toDouble(),
      noisePeakDb: (map['noise_peak_db'] as num?)?.toDouble() ?? (map['noisePeakDb'] as num?)?.toDouble(),
      noiseExposureDurationHours: (map['noise_exposure_duration_hours'] as num?)?.toDouble() ??
          (map['noiseExposureDurationHours'] as num?)?.toDouble(),
      noiseDosePercent: (map['noise_dose_percent'] as num?)?.toDouble() ??
          (map['noiseDosePercent'] as num?)?.toDouble(),
      noiseStandardTwaLimit: (map['noise_standard_twa_limit'] as num?)?.toDouble() ??
          (map['noiseStandardTwaLimit'] as num?)?.toDouble() ??
          86.0,
      noiseActionLevelThreshold: (map['noise_action_level_threshold'] as num?)?.toDouble() ??
          (map['noiseActionLevelThreshold'] as num?)?.toDouble() ??
          85.0,
      noiseContinuousCeilingLimit: (map['noise_continuous_ceiling_limit'] as num?)?.toDouble() ??
          (map['noiseContinuousCeilingLimit'] as num?)?.toDouble() ??
          115.0,
      noisePeakLimit: (map['noise_peak_limit'] as num?)?.toDouble() ??
          (map['noisePeakLimit'] as num?)?.toDouble() ??
          140.0,
      noiseIsHcpRequired: map['noise_is_hcp_required'] == 1 ||
          map['noise_is_hcp_required'] == true ||
          map['noiseIsHcpRequired'] == true,
      noiseEvaluationTier: map['noise_evaluation_tier'] as String? ?? map['noiseEvaluationTier'] as String?,
      // Heat
      heatSolarExposure: map['heat_solar_exposure'] != null
          ? HeatSolarExposure.fromDbCode(map['heat_solar_exposure'] as String)
          : (map['heatSolarExposure'] != null
              ? HeatSolarExposure.fromDbCode(map['heatSolarExposure'] as String)
              : null),
      heatNwbCelsius: (map['heat_nwb_celsius'] as num?)?.toDouble() ??
          (map['heatNwbCelsius'] as num?)?.toDouble(),
      heatGtCelsius: (map['heat_gt_celsius'] as num?)?.toDouble() ??
          (map['heatGtCelsius'] as num?)?.toDouble(),
      heatDbCelsius: (map['heat_db_celsius'] as num?)?.toDouble() ??
          (map['heatDbCelsius'] as num?)?.toDouble(),
      heatCalculatedWbgt: (map['heat_calculated_wbgt'] as num?)?.toDouble() ??
          (map['heatCalculatedWbgt'] as num?)?.toDouble(),
      heatWorkloadType: map['heat_workload_type'] != null
          ? WorkloadLevel.fromDbCode(map['heat_workload_type'] as String)
          : (map['heatWorkloadType'] != null
              ? WorkloadLevel.fromDbCode(map['heatWorkloadType'] as String)
              : null),
      heatMetabolicRateKcalHr: (map['heat_metabolic_rate_kcal_hr'] as num?)?.toDouble() ??
          (map['heatMetabolicRateKcalHr'] as num?)?.toDouble(),
      heatStandardLimitWbgt: (map['heat_standard_limit_wbgt'] as num?)?.toDouble() ??
          (map['heatStandardLimitWbgt'] as num?)?.toDouble(),
      heatIsCompliant: map['heat_is_compliant'] == 1 || map['heat_is_compliant'] == true || map['heatIsCompliant'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory EnvironmentPointModel.fromJson(String source) =>
      EnvironmentPointModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
