import 'dart:convert';

/// Parameter types for environmental standards.
enum EnvironmentFactorType {
  light,
  noise,
  heat;

  String toDbCode() {
    switch (this) {
      case EnvironmentFactorType.light:
        return 'LIGHT';
      case EnvironmentFactorType.noise:
        return 'NOISE';
      case EnvironmentFactorType.heat:
        return 'HEAT';
    }
  }

  static EnvironmentFactorType fromDbCode(String code) {
    switch (code.toUpperCase()) {
      case 'LIGHT':
        return EnvironmentFactorType.light;
      case 'NOISE':
        return EnvironmentFactorType.noise;
      case 'HEAT':
      case 'HEAT_WBGT':
        return EnvironmentFactorType.heat;
      default:
        return EnvironmentFactorType.light;
    }
  }

  String get labelTh {
    switch (this) {
      case EnvironmentFactorType.light:
        return 'แสงสว่าง';
      case EnvironmentFactorType.noise:
        return 'เสียง';
      case EnvironmentFactorType.heat:
        return 'ความร้อน (WBGT)';
    }
  }
}

/// Workload level classification for heat stress (DLPW 2559 / 2563).
enum WorkloadLevel {
  light,
  moderate,
  heavy;

  String toDbCode() {
    switch (this) {
      case WorkloadLevel.light:
        return 'LIGHT';
      case WorkloadLevel.moderate:
        return 'MODERATE';
      case WorkloadLevel.heavy:
        return 'HEAVY';
    }
  }

  static WorkloadLevel fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'LIGHT':
        return WorkloadLevel.light;
      case 'MODERATE':
      case 'MEDIUM':
        return WorkloadLevel.moderate;
      case 'HEAVY':
        return WorkloadLevel.heavy;
      default:
        return WorkloadLevel.moderate;
    }
  }

  String get labelTh {
    switch (this) {
      case WorkloadLevel.light:
        return 'งานเบา (<= 200 kcal/hr)';
      case WorkloadLevel.moderate:
        return 'งานปานกลาง (200 - 350 kcal/hr)';
      case WorkloadLevel.heavy:
        return 'งานหนัก (> 350 kcal/hr)';
    }
  }

    double get statutoryLimitCelsius {
    switch (this) {
      case WorkloadLevel.light:
        return 34.0;
      case WorkloadLevel.moderate:
        return 32.0;
      case WorkloadLevel.heavy:
        return 30.0;
    }
  }

  double get standardLimitWbgt => statutoryLimitCelsius;
}

/// Model representing an Environmental Standard item (Lighting catalog, Noise limit, Heat WBGT limit)
/// conforming to Thai Ministerial Regulations & DLPW Notifications (2559, 2561, 2563).
class EnvironmentStandardModel {
  final int? id;
  final String standardId; // e.g. 'LIGHT-CAT1-01', 'NOISE-TWA-8HR', 'HEAT-MODERATE'
  final EnvironmentFactorType factorType;
  final String categoryCode; // e.g. 'LIGHT_CAT1', 'NOISE_STD', 'HEAT_STD'
  final String categoryNameTh;
  final String categoryNameEn;
  final String taskDescription;
  final double? minLux;

  /// Compatibility alias for standardId
  String get standardCode => standardId;

  /// Compatibility alias for primary standard limit (Lux, dBA, or WBGT)
  double get standardLimit => minLux ?? noiseTwaLimitDba ?? wbgtLimitCelsius ?? 0.0;
  final double? maxLux;
  final double? surroundingLuxRatio; // e.g. 0.333 (1/3)
  final double? noiseTwaLimitDba; // Default 86.0
  final double? noiseActionLevelDba; // Default 85.0
  final double? noiseCeilingLimitDba; // Default 115.0
  final double? noisePeakLimitDb; // Default 140.0
  final WorkloadLevel? workLoadType;
  final double? metabolicRateKcalHr;
  final double? wbgtLimitCelsius; // 34.0, 32.0, 30.0
  final String referenceLawTitle;
  final String referenceArticle;
  final String? notes;
  final int sortOrder;

  const EnvironmentStandardModel({
    this.id,
    required this.standardId,
    required this.factorType,
    required this.categoryCode,
    required this.categoryNameTh,
    required this.categoryNameEn,
    required this.taskDescription,
    this.minLux,
    this.maxLux,
    this.surroundingLuxRatio,
    this.noiseTwaLimitDba,
    this.noiseActionLevelDba,
    this.noiseCeilingLimitDba,
    this.noisePeakLimitDb,
    this.workLoadType,
    this.metabolicRateKcalHr,
    this.wbgtLimitCelsius,
    required this.referenceLawTitle,
    required this.referenceArticle,
    this.notes,
    this.sortOrder = 0,
  });

  EnvironmentStandardModel copyWith({
    int? id,
    String? standardId,
    EnvironmentFactorType? factorType,
    String? categoryCode,
    String? categoryNameTh,
    String? categoryNameEn,
    String? taskDescription,
    double? minLux,
    double? maxLux,
    double? surroundingLuxRatio,
    double? noiseTwaLimitDba,
    double? noiseActionLevelDba,
    double? noiseCeilingLimitDba,
    double? noisePeakLimitDb,
    WorkloadLevel? workLoadType,
    double? metabolicRateKcalHr,
    double? wbgtLimitCelsius,
    String? referenceLawTitle,
    String? referenceArticle,
    String? notes,
    int? sortOrder,
  }) {
    return EnvironmentStandardModel(
      id: id ?? this.id,
      standardId: standardId ?? this.standardId,
      factorType: factorType ?? this.factorType,
      categoryCode: categoryCode ?? this.categoryCode,
      categoryNameTh: categoryNameTh ?? this.categoryNameTh,
      categoryNameEn: categoryNameEn ?? this.categoryNameEn,
      taskDescription: taskDescription ?? this.taskDescription,
      minLux: minLux ?? this.minLux,
      maxLux: maxLux ?? this.maxLux,
      surroundingLuxRatio: surroundingLuxRatio ?? this.surroundingLuxRatio,
      noiseTwaLimitDba: noiseTwaLimitDba ?? this.noiseTwaLimitDba,
      noiseActionLevelDba: noiseActionLevelDba ?? this.noiseActionLevelDba,
      noiseCeilingLimitDba: noiseCeilingLimitDba ?? this.noiseCeilingLimitDba,
      noisePeakLimitDb: noisePeakLimitDb ?? this.noisePeakLimitDb,
      workLoadType: workLoadType ?? this.workLoadType,
      metabolicRateKcalHr: metabolicRateKcalHr ?? this.metabolicRateKcalHr,
      wbgtLimitCelsius: wbgtLimitCelsius ?? this.wbgtLimitCelsius,
      referenceLawTitle: referenceLawTitle ?? this.referenceLawTitle,
      referenceArticle: referenceArticle ?? this.referenceArticle,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'standard_id': standardId,
      'factor_type': factorType.toDbCode(),
      'category_code': categoryCode,
      'category_name_th': categoryNameTh,
      'category_name_en': categoryNameEn,
      'task_description': taskDescription,
      'min_lux': minLux,
      'max_lux': maxLux,
      'surrounding_lux_ratio': surroundingLuxRatio,
      'noise_twa_limit_dba': noiseTwaLimitDba,
      'noise_action_level_dba': noiseActionLevelDba,
      'noise_ceiling_limit_dba': noiseCeilingLimitDba,
      'noise_peak_limit_db': noisePeakLimitDb,
      'workload_type': workLoadType?.toDbCode(),
      'metabolic_rate_kcal_hr': metabolicRateKcalHr,
      'wbgt_limit_celsius': wbgtLimitCelsius,
      'reference_law_title': referenceLawTitle,
      'reference_article': referenceArticle,
      'notes': notes,
      'sort_order': sortOrder,
    };
  }

  factory EnvironmentStandardModel.fromMap(Map<String, dynamic> map) {
    return EnvironmentStandardModel(
      id: map['id'] as int?,
      standardId: map['standard_id'] as String? ?? map['standardId'] as String? ?? '',
      factorType: EnvironmentFactorType.fromDbCode(
        map['factor_type'] as String? ?? map['factorType'] as String? ?? 'LIGHT',
      ),
      categoryCode: map['category_code'] as String? ?? map['categoryCode'] as String? ?? '',
      categoryNameTh: map['category_name_th'] as String? ?? map['categoryNameTh'] as String? ?? '',
      categoryNameEn: map['category_name_en'] as String? ?? map['categoryNameEn'] as String? ?? '',
      taskDescription: map['task_description'] as String? ?? map['taskDescription'] as String? ?? '',
      minLux: (map['min_lux'] as num?)?.toDouble() ?? (map['minLux'] as num?)?.toDouble(),
      maxLux: (map['max_lux'] as num?)?.toDouble() ?? (map['maxLux'] as num?)?.toDouble(),
      surroundingLuxRatio: (map['surrounding_lux_ratio'] as num?)?.toDouble() ??
          (map['surroundingLuxRatio'] as num?)?.toDouble(),
      noiseTwaLimitDba: (map['noise_twa_limit_dba'] as num?)?.toDouble() ??
          (map['noiseTwaLimitDba'] as num?)?.toDouble(),
      noiseActionLevelDba: (map['noise_action_level_dba'] as num?)?.toDouble() ??
          (map['noiseActionLevelDba'] as num?)?.toDouble(),
      noiseCeilingLimitDba: (map['noise_ceiling_limit_dba'] as num?)?.toDouble() ??
          (map['noiseCeilingLimitDba'] as num?)?.toDouble(),
      noisePeakLimitDb: (map['noise_peak_limit_db'] as num?)?.toDouble() ??
          (map['noisePeakLimitDb'] as num?)?.toDouble(),
      workLoadType: map['workload_type'] != null
          ? WorkloadLevel.fromDbCode(map['workload_type'] as String)
          : (map['workLoadType'] != null
              ? WorkloadLevel.fromDbCode(map['workLoadType'] as String)
              : null),
      metabolicRateKcalHr: (map['metabolic_rate_kcal_hr'] as num?)?.toDouble() ??
          (map['metabolicRateKcalHr'] as num?)?.toDouble(),
      wbgtLimitCelsius: (map['wbgt_limit_celsius'] as num?)?.toDouble() ??
          (map['wbgtLimitCelsius'] as num?)?.toDouble(),
      referenceLawTitle: map['reference_law_title'] as String? ?? map['referenceLawTitle'] as String? ?? '',
      referenceArticle: map['reference_article'] as String? ?? map['referenceArticle'] as String? ?? '',
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? map['sortOrder'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory EnvironmentStandardModel.fromJson(String source) =>
      EnvironmentStandardModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
