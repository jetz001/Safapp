import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents an individual measured sampling point within Form สอ.๓ ๒๕๖๕.
class Sor3SamplingPointItem {
  final int? id;
  final String pointCode; // e.g. "SP-01"
  final String workAreaName; // e.g. "แผนกผสมเคมี อาคาร 3"
  final String? processDescription; // e.g. "การตวงและเทตัวทำละลายลงถังผสม"
  final int exposedWorkersCount;
  final String? ppeUsed; // e.g. "หน้ากากไส้กรองสารเคมี Organic Vapor, ถุงมือ Nitrile"
  final String chemicalName;
  final String casNumber;
  final String samplingType; // 'TWA_8HR', 'STEL_15MIN', 'CEILING', 'AREA', 'PERSONAL'
  final int samplingDurationMinutes;
  final double? airVolumeLiters;
  final String? samplingMethod; // e.g. "NIOSH Method 1501"
  final String? analyticalMethod; // e.g. "GC-FID"
  final double measuredValue;
  final String unit; // 'ppm' or 'mg/m3'
  final double tlvStandardValue;
  final String evaluationResult; // 'PASS', 'ACTION_LEVEL', 'FAIL'
  final String? notes;

  const Sor3SamplingPointItem({
    this.id,
    required this.pointCode,
    required this.workAreaName,
    this.processDescription,
    this.exposedWorkersCount = 1,
    this.ppeUsed,
    required this.chemicalName,
    required this.casNumber,
    this.samplingType = 'TWA_8HR',
    this.samplingDurationMinutes = 480,
    this.airVolumeLiters,
    this.samplingMethod = 'NIOSH Method 1501',
    this.analyticalMethod = 'GC-FID',
    required this.measuredValue,
    this.unit = 'ppm',
    required this.tlvStandardValue,
    required this.evaluationResult,
    this.notes,
  });

  bool get isPass => evaluationResult.toUpperCase() == 'PASS';
  bool get isActionLevel => evaluationResult.toUpperCase() == 'ACTION_LEVEL';
  bool get isExceeded => evaluationResult.toUpperCase() == 'FAIL' || evaluationResult.toUpperCase() == 'EXCEEDED';

  double get ratioPercentage => tlvStandardValue > 0 ? (measuredValue / tlvStandardValue) * 100.0 : 0.0;

  Color get statusBadgeColor {
    if (isPass) return const Color(0xFF10B981);
    if (isActionLevel) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color get statusBadgeBackgroundColor {
    if (isPass) return const Color(0xFFECFDF5);
    if (isActionLevel) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
  }

  String get statusBadgeLabelTh {
    if (isPass) return 'ผ่านเกณฑ์มาตรฐาน (ปกติ)';
    if (isActionLevel) return 'ผ่านเกณฑ์แต่ถึงระดับปฏิบัติการ (Action Level > 50%)';
    return 'ไม่ผ่านเกณฑ์มาตรฐาน (เกินขีดจำกัด)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'point_code': pointCode,
      'work_area_name': workAreaName,
      'process_description': processDescription,
      'exposed_workers_count': exposedWorkersCount,
      'ppe_used': ppeUsed,
      'chemical_name': chemicalName,
      'cas_number': casNumber,
      'sampling_type': samplingType,
      'sampling_duration_minutes': samplingDurationMinutes,
      'air_volume_liters': airVolumeLiters,
      'sampling_method': samplingMethod,
      'analytical_method': analyticalMethod,
      'measured_value': measuredValue,
      'unit': unit,
      'tlv_standard_value': tlvStandardValue,
      'evaluation_result': evaluationResult,
      'notes': notes,
    };
  }

  factory Sor3SamplingPointItem.fromMap(Map<String, dynamic> map) {
    return Sor3SamplingPointItem(
      id: map['id'] as int?,
      pointCode: (map['point_code'] ?? 'SP-01').toString(),
      workAreaName: (map['work_area_name'] ?? '').toString(),
      processDescription: map['process_description']?.toString(),
      exposedWorkersCount: (map['exposed_workers_count'] as num?)?.toInt() ?? 1,
      ppeUsed: map['ppe_used']?.toString(),
      chemicalName: (map['chemical_name'] ?? '').toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      samplingType: (map['sampling_type'] ?? 'TWA_8HR').toString(),
      samplingDurationMinutes: (map['sampling_duration_minutes'] as num?)?.toInt() ?? 480,
      airVolumeLiters: (map['air_volume_liters'] as num?)?.toDouble(),
      samplingMethod: map['sampling_method']?.toString(),
      analyticalMethod: map['analytical_method']?.toString(),
      measuredValue: (map['measured_value'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] ?? 'ppm').toString(),
      tlvStandardValue: (map['tlv_standard_value'] as num?)?.toDouble() ?? 0.0,
      evaluationResult: (map['evaluation_result'] ?? 'PASS').toString(),
      notes: map['notes']?.toString(),
    );
  }

  Sor3SamplingPointItem copyWith({
    int? id,
    String? pointCode,
    String? workAreaName,
    String? processDescription,
    int? exposedWorkersCount,
    String? ppeUsed,
    String? chemicalName,
    String? casNumber,
    String? samplingType,
    int? samplingDurationMinutes,
    double? airVolumeLiters,
    String? samplingMethod,
    String? analyticalMethod,
    double? measuredValue,
    String? unit,
    double? tlvStandardValue,
    String? evaluationResult,
    String? notes,
  }) {
    return Sor3SamplingPointItem(
      id: id ?? this.id,
      pointCode: pointCode ?? this.pointCode,
      workAreaName: workAreaName ?? this.workAreaName,
      processDescription: processDescription ?? this.processDescription,
      exposedWorkersCount: exposedWorkersCount ?? this.exposedWorkersCount,
      ppeUsed: ppeUsed ?? this.ppeUsed,
      chemicalName: chemicalName ?? this.chemicalName,
      casNumber: casNumber ?? this.casNumber,
      samplingType: samplingType ?? this.samplingType,
      samplingDurationMinutes: samplingDurationMinutes ?? this.samplingDurationMinutes,
      airVolumeLiters: airVolumeLiters ?? this.airVolumeLiters,
      samplingMethod: samplingMethod ?? this.samplingMethod,
      analyticalMethod: analyticalMethod ?? this.analyticalMethod,
      measuredValue: measuredValue ?? this.measuredValue,
      unit: unit ?? this.unit,
      tlvStandardValue: tlvStandardValue ?? this.tlvStandardValue,
      evaluationResult: evaluationResult ?? this.evaluationResult,
      notes: notes ?? this.notes,
    );
  }
}

/// Comprehensive Model representing Form สอ.๓ ๒๕๖๕ (Atmospheric Measurement Report)
/// Conforming to DLPW Notification on Atmospheric Measurement & Form สอ.๓ (No. 2) B.E. 2565.
class ChemicalMeasurementSor3Model {
  final int? id;
  final String documentNo;
  final String assessmentDate;
  final String workplaceArea;
  final String? samplingPointDescription;
  final String chemicalName;
  final String casNumber;
  final String samplingType; // 'TWA_8HR', 'STEL_15MIN', 'CEILING'
  final int samplingDurationMinutes;
  final String samplingMethod;
  final double measuredValue;
  final String unit; // 'ppm' or 'mg/m3'
  final double tlvStandardValue;
  final String evaluationResult; // 'PASS', 'ACTION_LEVEL', 'FAIL'

  // Surveyor Certification: Section 9 (Juridical Entity) or Section 11 (Individual)
  final String serviceProviderName;
  final String surveyorType; // 'SECTION_9' or 'SECTION_11'
  final String? serviceProviderM9RegNo; // e.g. "นบ. 001-2563"
  final String? serviceProviderM11CertNo; // e.g. "บ. 015-2562"
  final String? surveyorValidTo;
  final String? surveyorQualification;
  final String? samplingOfficerName;
  final String? analystName;
  final String? analysisLaboratory;

  // Environmental & Weather Conditions
  final String? weatherCondition;
  final double? temperatureCelsius;
  final double? relativeHumidity;

  // Recommendations & Actions
  final String? correctiveAction;
  final String? certificatePdfPath;
  final List<Sor3SamplingPointItem> samplingPoints;

  final String status; // 'APPROVED', 'PENDING', 'DRAFT'
  final String? createdAt;
  final String? updatedAt;

  const ChemicalMeasurementSor3Model({
    this.id,
    required this.documentNo,
    required this.assessmentDate,
    required this.workplaceArea,
    this.samplingPointDescription,
    required this.chemicalName,
    required this.casNumber,
    this.samplingType = 'TWA_8HR',
    this.samplingDurationMinutes = 480,
    this.samplingMethod = 'NIOSH Method 1501 / GC-FID',
    required this.measuredValue,
    this.unit = 'ppm',
    required this.tlvStandardValue,
    required this.evaluationResult,
    required this.serviceProviderName,
    this.surveyorType = 'SECTION_9',
    this.serviceProviderM9RegNo,
    this.serviceProviderM11CertNo,
    this.surveyorValidTo,
    this.surveyorQualification,
    this.samplingOfficerName,
    this.analystName,
    this.analysisLaboratory,
    this.weatherCondition,
    this.temperatureCelsius,
    this.relativeHumidity,
    this.correctiveAction,
    this.certificatePdfPath,
    this.samplingPoints = const [],
    this.status = 'APPROVED',
    this.createdAt,
    this.updatedAt,
  });

  bool get isPass => evaluationResult.toUpperCase() == 'PASS';
  bool get isActionLevel => evaluationResult.toUpperCase() == 'ACTION_LEVEL';
  bool get isExceeded => evaluationResult.toUpperCase() == 'FAIL' || evaluationResult.toUpperCase() == 'EXCEEDED';

  double get ratioPercentage => tlvStandardValue > 0 ? (measuredValue / tlvStandardValue) * 100.0 : 0.0;

  Color get statusBadgeColor {
    if (isPass) return const Color(0xFF10B981);
    if (isActionLevel) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color get statusBadgeBackgroundColor {
    if (isPass) return const Color(0xFFECFDF5);
    if (isActionLevel) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
  }

  String get statusBadgeLabelTh {
    if (isPass) return 'ผ่านเกณฑ์มาตรฐาน';
    if (isActionLevel) return 'ผ่านเกณฑ์ (Action Level > 50%)';
    return 'ไม่ผ่านเกณฑ์ (เกินมาตรฐาน)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_no': documentNo,
      'assessment_date': assessmentDate,
      'workplace_area': workplaceArea,
      'sampling_point_description': samplingPointDescription ?? (samplingPoints.isNotEmpty ? jsonEncode(samplingPoints.map((s) => s.toMap()).toList()) : null),
      'chemical_name': chemicalName,
      'cas_number': casNumber,
      'sampling_type': samplingType,
      'sampling_duration_minutes': samplingDurationMinutes,
      'sampling_method': samplingMethod,
      'measured_value': measuredValue,
      'unit': unit,
      'tlv_standard_value': tlvStandardValue,
      'evaluation_result': evaluationResult,
      'service_provider_name': serviceProviderName,
      'service_provider_m9_reg_no': serviceProviderM9RegNo,
      'service_provider_m11_cert_no': serviceProviderM11CertNo,
      'sampling_officer_name': samplingOfficerName,
      'analyst_name': analystName,
      'analysis_laboratory': analysisLaboratory,
      'weather_condition': weatherCondition,
      'temperature_celsius': temperatureCelsius,
      'relative_humidity': relativeHumidity,
      'corrective_action': correctiveAction,
      'certificate_pdf_path': certificatePdfPath,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ChemicalMeasurementSor3Model.fromMap(Map<String, dynamic> map) {
    List<Sor3SamplingPointItem> points = [];
    final rawPoints = map['sampling_point_description']?.toString();
    if (rawPoints != null && rawPoints.startsWith('[')) {
      try {
        final decoded = jsonDecode(rawPoints);
        if (decoded is List) {
          points = decoded.map((p) => Sor3SamplingPointItem.fromMap(Map<String, dynamic>.from(p))).toList();
        }
      } catch (_) {}
    }

    final m9 = map['service_provider_m9_reg_no']?.toString();
    final m11 = map['service_provider_m11_cert_no']?.toString();
    final surveyorType = (m11 != null && m11.isNotEmpty && (m9 == null || m9.isEmpty)) ? 'SECTION_11' : 'SECTION_9';

    return ChemicalMeasurementSor3Model(
      id: map['id'] as int?,
      documentNo: (map['document_no'] ?? '').toString(),
      assessmentDate: (map['assessment_date'] ?? '').toString(),
      workplaceArea: (map['workplace_area'] ?? '').toString(),
      samplingPointDescription: rawPoints != null && rawPoints.startsWith('[') ? null : rawPoints,
      chemicalName: (map['chemical_name'] ?? '').toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      samplingType: (map['sampling_type'] ?? 'TWA_8HR').toString(),
      samplingDurationMinutes: (map['sampling_duration_minutes'] as num?)?.toInt() ?? 480,
      samplingMethod: (map['sampling_method'] ?? 'NIOSH Method 1501 / GC-FID').toString(),
      measuredValue: (map['measured_value'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] ?? 'ppm').toString(),
      tlvStandardValue: (map['tlv_standard_value'] as num?)?.toDouble() ?? 0.0,
      evaluationResult: (map['evaluation_result'] ?? 'PASS').toString(),
      serviceProviderName: (map['service_provider_name'] ?? '').toString(),
      surveyorType: surveyorType,
      serviceProviderM9RegNo: m9,
      serviceProviderM11CertNo: m11,
      samplingOfficerName: map['sampling_officer_name']?.toString(),
      analystName: map['analyst_name']?.toString(),
      analysisLaboratory: map['analysis_laboratory']?.toString(),
      weatherCondition: map['weather_condition']?.toString(),
      temperatureCelsius: (map['temperature_celsius'] as num?)?.toDouble(),
      relativeHumidity: (map['relative_humidity'] as num?)?.toDouble(),
      correctiveAction: map['corrective_action']?.toString(),
      certificatePdfPath: map['certificate_pdf_path']?.toString(),
      samplingPoints: points,
      status: (map['status'] ?? 'APPROVED').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  ChemicalMeasurementSor3Model copyWith({
    int? id,
    String? documentNo,
    String? assessmentDate,
    String? workplaceArea,
    String? samplingPointDescription,
    String chemicalName = '',
    String casNumber = '',
    String? samplingType,
    int? samplingDurationMinutes,
    String? samplingMethod,
    double? measuredValue,
    String? unit,
    double? tlvStandardValue,
    String? evaluationResult,
    String? serviceProviderName,
    String? surveyorType,
    String? serviceProviderM9RegNo,
    String? serviceProviderM11CertNo,
    String? surveyorValidTo,
    String? surveyorQualification,
    String? samplingOfficerName,
    String? analystName,
    String? analysisLaboratory,
    String? weatherCondition,
    double? temperatureCelsius,
    double? relativeHumidity,
    String? correctiveAction,
    String? certificatePdfPath,
    List<Sor3SamplingPointItem>? samplingPoints,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChemicalMeasurementSor3Model(
      id: id ?? this.id,
      documentNo: documentNo ?? this.documentNo,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      workplaceArea: workplaceArea ?? this.workplaceArea,
      samplingPointDescription: samplingPointDescription ?? this.samplingPointDescription,
      chemicalName: chemicalName.isNotEmpty ? chemicalName : this.chemicalName,
      casNumber: casNumber.isNotEmpty ? casNumber : this.casNumber,
      samplingType: samplingType ?? this.samplingType,
      samplingDurationMinutes: samplingDurationMinutes ?? this.samplingDurationMinutes,
      samplingMethod: samplingMethod ?? this.samplingMethod,
      measuredValue: measuredValue ?? this.measuredValue,
      unit: unit ?? this.unit,
      tlvStandardValue: tlvStandardValue ?? this.tlvStandardValue,
      evaluationResult: evaluationResult ?? this.evaluationResult,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      surveyorType: surveyorType ?? this.surveyorType,
      serviceProviderM9RegNo: serviceProviderM9RegNo ?? this.serviceProviderM9RegNo,
      serviceProviderM11CertNo: serviceProviderM11CertNo ?? this.serviceProviderM11CertNo,
      surveyorValidTo: surveyorValidTo ?? this.surveyorValidTo,
      surveyorQualification: surveyorQualification ?? this.surveyorQualification,
      samplingOfficerName: samplingOfficerName ?? this.samplingOfficerName,
      analystName: analystName ?? this.analystName,
      analysisLaboratory: analysisLaboratory ?? this.analysisLaboratory,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      certificatePdfPath: certificatePdfPath ?? this.certificatePdfPath,
      samplingPoints: samplingPoints ?? this.samplingPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
