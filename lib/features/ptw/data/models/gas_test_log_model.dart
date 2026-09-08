import 'dart:convert';

/// Gas Test Monitoring Log for Confined Space Entry under Thai OSH Regulation B.E. 2562 (ข้อ ๗)
///
/// Statutory Limits:
/// - Oxygen (O2): 19.5% - 23.5%
/// - Flammable Gas (LEL): < 10%
/// - Carbon Monoxide (CO): < 25 ppm
/// - Hydrogen Sulfide (H2S): < 10 ppm
class GasTestLogModel {
  final int? id;
  final String logId; // e.g. "GAS-PTW-2026-001-01"
  final String ptwNumber; // Reference to PtwModel.ptwNumber
  final String testStage; // 'PRE_ENTRY', 'CONTINUOUS', 'POST_WORK'
  final String testTimestamp; // ISO 8601 or YYYY-MM-DDTHH:mm:ss
  final String locationPoint; // e.g. "ก้นถังไซโล จุดตรวจที่ 1 (ระดับลึก 3 เมตร)"
  final double oxygenPercent; // O2 (%) - standard: 19.5 - 23.5%
  final double combustiblePercentLel; // LEL (%) - standard: < 10%
  final double carbonMonoxidePpm; // CO (ppm) - standard: < 25 ppm
  final double hydrogenSulfidePpm; // H2S (ppm) - standard: < 10 ppm
  final double? toxicOtherPpm; // Other toxic gases (optional)
  final String? toxicOtherName; // Name of other gas e.g. "NH3", "SO2", "Cl2"
  final String testerName; // ชื่อผู้ตรวจวัด
  final String? testerCertNo; // เลขที่ใบรับรองผู้ตรวจวัดบรรยากาศ
  final String detectorModel; // ยี่ห้อ/รุ่นเครื่องตรวจวัด e.g. "Dräger X-am 5000"
  final String detectorSerialNo; // หมายเลขเครื่องตรวจวัด
  final String lastCalibrationDate; // วันที่สอบเทียบล่าสุด (YYYY-MM-DD)
  final bool isSafe; // Evaluated result
  final String? safetyRemarks; // หมายเหตุ/คำเตือน
  final String? signaturePath; // ลายเซ็นผู้ตรวจวัด
  final String? createdAt;

  const GasTestLogModel({
    this.id,
    required this.logId,
    required this.ptwNumber,
    required this.testStage,
    required this.testTimestamp,
    required this.locationPoint,
    required this.oxygenPercent,
    required this.combustiblePercentLel,
    required this.carbonMonoxidePpm,
    required this.hydrogenSulfidePpm,
    this.toxicOtherPpm,
    this.toxicOtherName,
    required this.testerName,
    this.testerCertNo,
    required this.detectorModel,
    required this.detectorSerialNo,
    required this.lastCalibrationDate,
    required this.isSafe,
    this.safetyRemarks,
    this.signaturePath,
    this.createdAt,
  });

  bool get isPreEntry => testStage.toUpperCase() == 'PRE_ENTRY';
  bool get isContinuous => testStage.toUpperCase() == 'CONTINUOUS';

  /// Statutory Validation Rule for Confined Space Atmosphere
  static bool evaluateSafety({
    required double o2,
    required double lel,
    required double co,
    required double h2s,
    double? otherToxic,
    double otherToxicLimit = 0.0,
  }) {
    final bool o2Safe = (o2 >= 19.5 && o2 <= 23.5);
    final bool lelSafe = (lel < 10.0);
    final bool coSafe = (co < 25.0);
    final bool h2sSafe = (h2s < 10.0);
    final bool otherSafe = (otherToxic == null || otherToxicLimit <= 0.0 || otherToxic < otherToxicLimit);
    return o2Safe && lelSafe && coSafe && h2sSafe && otherSafe;
  }

  /// List of human-readable warnings for hazard violations
  List<String> get hazardWarnings {
    final List<String> warnings = [];
    if (oxygenPercent < 19.5) {
      warnings.add('ออกซิเจนต่ำเกินไป (${oxygenPercent.toStringAsFixed(1)}% < 19.5%): เสี่ยงหมดสติและขาดอากาศหายใจ');
    } else if (oxygenPercent > 23.5) {
      warnings.add('ออกซิเจนสูงเกินไป (${oxygenPercent.toStringAsFixed(1)}% > 23.5%): เพิ่มความเสี่ยงเพลิงไหม้และการระเบิดรุนแรง');
    }
    if (combustiblePercentLel >= 10.0) {
      warnings.add('ก๊าซ/ไอระเหยไวไฟเกินเกณฑ์ (${combustiblePercentLel.toStringAsFixed(1)}% LEL >= 10%): เสี่ยงต่อการระเบิด');
    }
    if (carbonMonoxidePpm >= 25.0) {
      warnings.add('คาร์บอนมอนอกไซด์เกินเกณฑ์ (${carbonMonoxidePpm.toStringAsFixed(1)} ppm >= 25 ppm): เสี่ยงต่อภาวะขาดก๊าซออกซิเจนเฉียบพลัน');
    }
    if (hydrogenSulfidePpm >= 10.0) {
      warnings.add('ไฮโดรเจนซัลไฟด์เกินเกณฑ์ (${hydrogenSulfidePpm.toStringAsFixed(1)} ppm >= 10 ppm): เสี่ยงก๊าซไข่เน่าเป็นพิษรุนแรง');
    }
    return warnings;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'log_id': logId,
      'ptw_number': ptwNumber,
      'test_stage': testStage,
      'test_timestamp': testTimestamp,
      'location_point': locationPoint,
      'oxygen_percent': oxygenPercent,
      'combustible_percent_lel': combustiblePercentLel,
      'carbon_monoxide_ppm': carbonMonoxidePpm,
      'hydrogen_sulfide_ppm': hydrogenSulfidePpm,
      'toxic_other_ppm': toxicOtherPpm,
      'toxic_other_name': toxicOtherName,
      'tester_name': testerName,
      'tester_cert_no': testerCertNo,
      'detector_model': detectorModel,
      'detector_serial_no': detectorSerialNo,
      'last_calibration_date': lastCalibrationDate,
      'is_safe': isSafe ? 1 : 0,
      'safety_remarks': safetyRemarks,
      'signature_path': signaturePath,
      'created_at': createdAt,
    };
  }

  factory GasTestLogModel.fromMap(Map<String, dynamic> map) {
    return GasTestLogModel(
      id: map['id'] as int?,
      logId: map['log_id']?.toString() ?? '',
      ptwNumber: map['ptw_number']?.toString() ?? '',
      testStage: map['test_stage']?.toString() ?? 'PRE_ENTRY',
      testTimestamp: map['test_timestamp']?.toString() ?? '',
      locationPoint: map['location_point']?.toString() ?? '',
      oxygenPercent: (map['oxygen_percent'] as num?)?.toDouble() ?? 20.9,
      combustiblePercentLel: (map['combustible_percent_lel'] as num?)?.toDouble() ?? 0.0,
      carbonMonoxidePpm: (map['carbon_monoxide_ppm'] as num?)?.toDouble() ?? 0.0,
      hydrogenSulfidePpm: (map['hydrogen_sulfide_ppm'] as num?)?.toDouble() ?? 0.0,
      toxicOtherPpm: (map['toxic_other_ppm'] as num?)?.toDouble(),
      toxicOtherName: map['toxic_other_name']?.toString(),
      testerName: map['tester_name']?.toString() ?? '',
      testerCertNo: map['tester_cert_no']?.toString(),
      detectorModel: map['detector_model']?.toString() ?? '',
      detectorSerialNo: map['detector_serial_no']?.toString() ?? '',
      lastCalibrationDate: map['last_calibration_date']?.toString() ?? '',
      isSafe: (map['is_safe'] == 1 || map['is_safe'] == true),
      safetyRemarks: map['safety_remarks']?.toString(),
      signaturePath: map['signature_path']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory GasTestLogModel.fromJson(Map<String, dynamic> json) => GasTestLogModel.fromMap(json);

  GasTestLogModel copyWith({
    int? id,
    String? logId,
    String? ptwNumber,
    String? testStage,
    String? testTimestamp,
    String? locationPoint,
    double? oxygenPercent,
    double? combustiblePercentLel,
    double? carbonMonoxidePpm,
    double? hydrogenSulfidePpm,
    double? toxicOtherPpm,
    String? toxicOtherName,
    String? testerName,
    String? testerCertNo,
    String? detectorModel,
    String? detectorSerialNo,
    String? lastCalibrationDate,
    bool? isSafe,
    String? safetyRemarks,
    String? signaturePath,
    String? createdAt,
  }) {
    return GasTestLogModel(
      id: id ?? this.id,
      logId: logId ?? this.logId,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      testStage: testStage ?? this.testStage,
      testTimestamp: testTimestamp ?? this.testTimestamp,
      locationPoint: locationPoint ?? this.locationPoint,
      oxygenPercent: oxygenPercent ?? this.oxygenPercent,
      combustiblePercentLel: combustiblePercentLel ?? this.combustiblePercentLel,
      carbonMonoxidePpm: carbonMonoxidePpm ?? this.carbonMonoxidePpm,
      hydrogenSulfidePpm: hydrogenSulfidePpm ?? this.hydrogenSulfidePpm,
      toxicOtherPpm: toxicOtherPpm ?? this.toxicOtherPpm,
      toxicOtherName: toxicOtherName ?? this.toxicOtherName,
      testerName: testerName ?? this.testerName,
      testerCertNo: testerCertNo ?? this.testerCertNo,
      detectorModel: detectorModel ?? this.detectorModel,
      detectorSerialNo: detectorSerialNo ?? this.detectorSerialNo,
      lastCalibrationDate: lastCalibrationDate ?? this.lastCalibrationDate,
      isSafe: isSafe ?? this.isSafe,
      safetyRemarks: safetyRemarks ?? this.safetyRemarks,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'GasTestLogModel(logId: $logId, ptwNumber: $ptwNumber, O2: $oxygenPercent%, LEL: $combustiblePercentLel%, CO: $carbonMonoxidePpm, H2S: $hydrogenSulfidePpm, isSafe: $isSafe)';
}
