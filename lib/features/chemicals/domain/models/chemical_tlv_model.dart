import 'package:flutter/material.dart';

/// Evaluation status for workplace atmospheric chemical concentration.
enum TlvEvalStatus {
  /// Concentration <= 50% of TLV (Safe / Normal)
  pass,

  /// Concentration is between 50% and 100% of TLV (Action Level / Surveillance Required)
  actionLevel,

  /// Concentration exceeds 100% of TLV (Exceeded / Danger / Statutory Violation)
  exceeded,
}

/// Model representing a standard Threshold Limit Value (TLV) under
/// DLPW Notification B.E. 2560 (324 regulated substances).
class ChemicalTlvItem {
  final int sequenceNo;
  final String thaiName;
  final String englishName;
  final String? casNumber;
  final double? twaPpm;
  final double? twaMgM3;
  final double? stelPpm;
  final double? stelMgM3;
  final double? ceilingPpm;
  final double? ceilingMgM3;
  final bool skinNotation;
  final String? carcinogenCategory;
  final String? notes;

  const ChemicalTlvItem({
    required this.sequenceNo,
    required this.thaiName,
    required this.englishName,
    this.casNumber,
    this.twaPpm,
    this.twaMgM3,
    this.stelPpm,
    this.stelMgM3,
    this.ceilingPpm,
    this.ceilingMgM3,
    this.skinNotation = false,
    this.carcinogenCategory,
    this.notes,
  });

  ChemicalTlvItem copyWith({
    int? sequenceNo,
    String? thaiName,
    String? englishName,
    String? casNumber,
    double? twaPpm,
    double? twaMgM3,
    double? stelPpm,
    double? stelMgM3,
    double? ceilingPpm,
    double? ceilingMgM3,
    bool? skinNotation,
    String? carcinogenCategory,
    String? notes,
  }) {
    return ChemicalTlvItem(
      sequenceNo: sequenceNo ?? this.sequenceNo,
      thaiName: thaiName ?? this.thaiName,
      englishName: englishName ?? this.englishName,
      casNumber: casNumber ?? this.casNumber,
      twaPpm: twaPpm ?? this.twaPpm,
      twaMgM3: twaMgM3 ?? this.twaMgM3,
      stelPpm: stelPpm ?? this.stelPpm,
      stelMgM3: stelMgM3 ?? this.stelMgM3,
      ceilingPpm: ceilingPpm ?? this.ceilingPpm,
      ceilingMgM3: ceilingMgM3 ?? this.ceilingMgM3,
      skinNotation: skinNotation ?? this.skinNotation,
      carcinogenCategory: carcinogenCategory ?? this.carcinogenCategory,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sequence_no': sequenceNo,
      'thai_name': thaiName,
      'english_name': englishName,
      'cas_number': casNumber,
      'twa_ppm': twaPpm,
      'twa_mg_m3': twaMgM3,
      'stel_ppm': stelPpm,
      'stel_mg_m3': stelMgM3,
      'ceiling_ppm': ceilingPpm,
      'ceiling_mg_m3': ceilingMgM3,
      'skin_notation': skinNotation ? 1 : 0,
      'carcinogen_category': carcinogenCategory,
      'notes': notes,
    };
  }

  factory ChemicalTlvItem.fromMap(Map<String, dynamic> map) {
    return ChemicalTlvItem(
      sequenceNo: map['sequence_no'] is int
          ? map['sequence_no'] as int
          : int.tryParse(map['sequence_no']?.toString() ?? '0') ?? 0,
      thaiName: (map['thai_name'] ?? '').toString(),
      englishName: (map['english_name'] ?? '').toString(),
      casNumber: map['cas_number']?.toString(),
      twaPpm: map['twa_ppm'] != null ? double.tryParse(map['twa_ppm'].toString()) : null,
      twaMgM3: map['twa_mg_m3'] != null ? double.tryParse(map['twa_mg_m3'].toString()) : null,
      stelPpm: map['stel_ppm'] != null ? double.tryParse(map['stel_ppm'].toString()) : null,
      stelMgM3: map['stel_mg_m3'] != null ? double.tryParse(map['stel_mg_m3'].toString()) : null,
      ceilingPpm: map['ceiling_ppm'] != null ? double.tryParse(map['ceiling_ppm'].toString()) : null,
      ceilingMgM3: map['ceiling_mg_m3'] != null ? double.tryParse(map['ceiling_mg_m3'].toString()) : null,
      skinNotation: map['skin_notation'] == 1 || map['skin_notation'] == true,
      carcinogenCategory: map['carcinogen_category']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  /// Returns the applicable limit based on measurement type and unit.
  /// When [molecularWeight] is provided and the standard limit is only published in the
  /// alternative unit, it converts the limit dynamically. Otherwise returns null.
  double? getStandardLimit({
    required String type,
    required String unit,
    double? molecularWeight,
  }) {
    final t = type.toUpperCase();
    final u = unit.toUpperCase();
    final isPpm = u.contains('PPM');

    double? ppmLimit;
    double? mgM3Limit;

    if (t.contains('CEILING')) {
      ppmLimit = ceilingPpm;
      mgM3Limit = ceilingMgM3;
    } else if (t.contains('STEL')) {
      ppmLimit = stelPpm;
      mgM3Limit = stelMgM3;
    } else {
      // Default to TWA (8-hr)
      ppmLimit = twaPpm;
      mgM3Limit = twaMgM3;
    }

    if (isPpm) {
      if (ppmLimit != null) return ppmLimit;
      if (mgM3Limit != null && molecularWeight != null && molecularWeight > 0) {
        return TlvEvaluationEngine.mgM3ToPpm(mgM3Limit, molecularWeight);
      }
      return null;
    } else {
      // mg/m³ or other mass concentration unit
      if (mgM3Limit != null) return mgM3Limit;
      if (ppmLimit != null && molecularWeight != null && molecularWeight > 0) {
        return TlvEvaluationEngine.ppmToMgM3(ppmLimit, molecularWeight);
      }
      return null;
    }
  }

  String get summaryLabel {
    final parts = <String>[];
    if (twaPpm != null) parts.add('TWA: $twaPpm ppm');
    if (twaMgM3 != null) parts.add('TWA: $twaMgM3 mg/m³');
    if (stelPpm != null) parts.add('STEL: $stelPpm ppm');
    if (ceilingPpm != null) parts.add('Ceiling: $ceilingPpm ppm');
    if (ceilingMgM3 != null) parts.add('Ceiling: $ceilingMgM3 mg/m³');
    if (skinNotation) parts.add('Skin Notation (ผิวหนัง)');
    return parts.isEmpty ? 'ไม่มีขีดจำกัดเฉพาะ' : parts.join(' | ');
  }
}

/// Result of evaluating a measured chemical concentration against statutory TLV limits.
class TlvEvaluationResult {
  final TlvEvalStatus status;
  final double measuredValue;
  final double? standardLimit;
  final String unit;
  final double? ratio;
  final String messageTh;
  final String messageEn;

  const TlvEvaluationResult({
    required this.status,
    required this.measuredValue,
    this.standardLimit,
    required this.unit,
    this.ratio,
    required this.messageTh,
    required this.messageEn,
  });

  bool get isPass => status == TlvEvalStatus.pass;
  bool get isActionLevel => status == TlvEvalStatus.actionLevel;
  bool get isExceeded => status == TlvEvalStatus.exceeded;

  Color get statusColor {
    switch (status) {
      case TlvEvalStatus.pass:
        return const Color(0xFF10B981); // Emerald Green
      case TlvEvalStatus.actionLevel:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case TlvEvalStatus.exceeded:
        return const Color(0xFFEF4444); // Red
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case TlvEvalStatus.pass:
        return const Color(0xFFECFDF5);
      case TlvEvalStatus.actionLevel:
        return const Color(0xFFFFFBEB);
      case TlvEvalStatus.exceeded:
        return const Color(0xFFFEF2F2);
    }
  }

  String get statusBadgeLabelTh {
    switch (status) {
      case TlvEvalStatus.pass:
        return 'ไม่เกินขีดจำกัด (PASS)';
      case TlvEvalStatus.actionLevel:
        return 'ระดับเฝ้าระวัง (ACTION LEVEL)';
      case TlvEvalStatus.exceeded:
        return 'เกินขีดจำกัดตามกฎหมาย (EXCEEDED)';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TlvEvalStatus.pass:
        return Icons.check_circle_rounded;
      case TlvEvalStatus.actionLevel:
        return Icons.warning_amber_rounded;
      case TlvEvalStatus.exceeded:
        return Icons.error_rounded;
    }
  }
}

/// Industrial hygiene evaluation engine conforming to Thai Royal Gazette standards.
class TlvEvaluationEngine {
  /// Evaluates a single measured concentration against a standard threshold.
  static TlvEvaluationResult evaluate({
    required double measuredValue,
    required double? standardLimit,
    required String unit,
  }) {
    if (standardLimit == null || standardLimit <= 0) {
      return TlvEvaluationResult(
        status: TlvEvalStatus.pass,
        measuredValue: measuredValue,
        standardLimit: standardLimit,
        unit: unit,
        ratio: null,
        messageTh: 'ไม่มีค่าขีดจำกัดความเข้มข้นระบุไว้ในกฎหมาย',
        messageEn: 'No statutory threshold limit specified',
      );
    }

    final ratio = measuredValue / standardLimit;

    if (measuredValue <= (0.5 * standardLimit)) {
      return TlvEvaluationResult(
        status: TlvEvalStatus.pass,
        measuredValue: measuredValue,
        standardLimit: standardLimit,
        unit: unit,
        ratio: ratio,
        messageTh: 'ปกติ ไม่เกินร้อยละ 50 ของขีดจำกัดความเข้มข้น (${(ratio * 100).toStringAsFixed(1)}% ของ TLV)',
        messageEn: 'Normal (<= 50% TLV limit: ${(ratio * 100).toStringAsFixed(1)}%)',
      );
    } else if (measuredValue <= standardLimit) {
      return TlvEvaluationResult(
        status: TlvEvalStatus.actionLevel,
        measuredValue: measuredValue,
        standardLimit: standardLimit,
        unit: unit,
        ratio: ratio,
        messageTh: 'ระดับเฝ้าระวัง (Action Level: ${(ratio * 100).toStringAsFixed(1)}% ของ TLV - ควรตรวจติดตามสม่ำเสมอ)',
        messageEn: 'Action Level (50% - 100% TLV: ${(ratio * 100).toStringAsFixed(1)}%)',
      );
    } else {
      final exceedPct = ((ratio - 1.0) * 100).toStringAsFixed(1);
      return TlvEvaluationResult(
        status: TlvEvalStatus.exceeded,
        measuredValue: measuredValue,
        standardLimit: standardLimit,
        unit: unit,
        ratio: ratio,
        messageTh: 'เกินขีดจำกัดความเข้มข้นตามกฎหมาย (เกินเกณฑ์ $exceedPct% - ต้องปรับปรุงทันที)',
        messageEn: 'Exceeded statutory TLV limit by $exceedPct% (Action required)',
      );
    }
  }

  /// Evaluates using a specific ChemicalTlvItem and sampling type.
  static TlvEvaluationResult evaluateWithTlvItem({
    required ChemicalTlvItem tlvItem,
    required String samplingType, // 'TWA_8HR', 'STEL_15MIN', 'CEILING'
    required String unit, // 'ppm', 'mg/m3'
    required double measuredValue,
    double? molecularWeight,
  }) {
    final limit = tlvItem.getStandardLimit(
      type: samplingType,
      unit: unit,
      molecularWeight: molecularWeight,
    );
    return evaluate(
      measuredValue: measuredValue,
      standardLimit: limit,
      unit: unit,
    );
  }

  /// Converts gas/vapor concentration from ppm to mg/m³ at 25°C, 1 atm:
  /// Formula: mg/m³ = (ppm × Molecular Weight) / 24.45
  static double ppmToMgM3(double ppm, double molecularWeight) {
    if (molecularWeight <= 0) return ppm;
    return (ppm * molecularWeight) / 24.45;
  }

  /// Converts concentration from mg/m³ to ppm at 25°C, 1 atm:
  /// Formula: ppm = (mg/m³ × 24.45) / Molecular Weight
  static double mgM3ToPpm(double mgM3, double molecularWeight) {
    if (molecularWeight <= 0) return mgM3;
    return (mgM3 * 24.45) / molecularWeight;
  }

  /// Calculates Chemical Mixture Additive Exposure Index:
  /// Formula: Em = Sum(C_i / TLV_i)
  /// If Em <= 1.0 -> Compliant; If Em > 1.0 -> Exceeded
  static ({double index, bool isExceeded, String message}) evaluateMixture({
    required List<({double measured, double tlv})> components,
  }) {
    if (components.isEmpty) {
      return (index: 0.0, isExceeded: false, message: 'ไม่มีข้อมูลสารผสม');
    }

    double totalIndex = 0.0;
    for (final c in components) {
      if (c.tlv > 0) {
        totalIndex += (c.measured / c.tlv);
      }
    }

    final isExceeded = totalIndex > 1.0;
    final msg = isExceeded
        ? 'ดัชนีสารผสม Em = ${totalIndex.toStringAsFixed(2)} เกินเกณฑ์มาตรฐานรวม (> 1.0)'
        : 'ดัชนีสารผสม Em = ${totalIndex.toStringAsFixed(2)} อยู่ในเกณฑ์มาตรฐาน (<= 1.0)';

    return (index: totalIndex, isExceeded: isExceeded, message: msg);
  }
}
