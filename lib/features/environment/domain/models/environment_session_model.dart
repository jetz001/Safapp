import 'dart:convert';
import 'subcontractor_model.dart';

/// Status of an environmental measurement session.
enum EnvironmentSessionStatus {
  planned,
  measured,
  reportPosted,
  submittedToDlpw,
  closed;

  String toDbCode() {
    switch (this) {
      case EnvironmentSessionStatus.planned:
        return 'PLANNED';
      case EnvironmentSessionStatus.measured:
        return 'MEASURED';
      case EnvironmentSessionStatus.reportPosted:
        return 'REPORT_POSTED';
      case EnvironmentSessionStatus.submittedToDlpw:
        return 'SUBMITTED_TO_DLPW';
      case EnvironmentSessionStatus.closed:
        return 'CLOSED';
    }
  }

  static EnvironmentSessionStatus fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'PLANNED':
      case 'DRAFT':
        return EnvironmentSessionStatus.planned;
      case 'MEASURED':
      case 'COMPLETED':
        return EnvironmentSessionStatus.measured;
      case 'REPORT_POSTED':
        return EnvironmentSessionStatus.reportPosted;
      case 'SUBMITTED_TO_DLPW':
      case 'SUBMITTED':
      case 'APPROVED':
        return EnvironmentSessionStatus.submittedToDlpw;
      case 'CLOSED':
        return EnvironmentSessionStatus.closed;
      default:
        return EnvironmentSessionStatus.planned;
    }
  }

  String get labelTh {
    switch (this) {
      case EnvironmentSessionStatus.planned:
        return 'วางแผนการตรวจวัด';
      case EnvironmentSessionStatus.measured:
        return 'ตรวจวัดเรียบร้อย';
      case EnvironmentSessionStatus.reportPosted:
        return 'ปิดประกาศผลแล้ว (ภายใน 15 วัน)';
      case EnvironmentSessionStatus.submittedToDlpw:
        return 'ส่งรายงานต่อกรมฯ แล้ว (ภายใน 30 วัน)';
      case EnvironmentSessionStatus.closed:
        return 'เสร็จสมบูรณ์/ปิดรอบ';
    }
  }
}

/// Model representing an Annual/Periodic Environmental Monitoring Session (รอบการตรวจวัด).
class EnvironmentSessionModel {
  final int? id;
  final String sessionId; // e.g. 'ENV-SESS-2026-001'
  final String sessionTitle;
  final int sessionYearBe; // e.g. 2569
  final int sessionYearAd; // e.g. 2026
  final String measurementDate; // YYYY-MM-DD
  final String? reportReceivedDate; // YYYY-MM-DD
  final String? postingDeadline; // measurementDate + 15 days (Section 15 OSH Act)
  final String? submissionDeadline; // measurementDate + 30 days (Section 15 OSH Act)
  final String locationPlant;
  final String workplaceName;
  final String? workplaceAddress;
  final String objective;
  final SubcontractorType subcontractorType;
  final String? subcontractorId;
  final String subcontractorCompanyName;
  final String subcontractorRegNumber;
  final String surveyorName;
  final String? surveyorLicenseNo;
  final String certifierName;
  final String? certifierRegNo;
  final String? pdfReportPath;
  final List<String> calibrationCertPaths;
  final String? subcontractorLicensePath;
  final List<String> sitePhotoPaths;
  final EnvironmentSessionStatus status;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const EnvironmentSessionModel({
    this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.sessionYearBe,
    required this.sessionYearAd,
    required this.measurementDate,
    this.reportReceivedDate,
    this.postingDeadline,
    this.submissionDeadline,
    required this.locationPlant,
    required this.workplaceName,
    this.workplaceAddress,
    required this.objective,
    required this.subcontractorType,
    this.subcontractorId,
    required this.subcontractorCompanyName,
    required this.subcontractorRegNumber,
    required this.surveyorName,
    this.surveyorLicenseNo,
    required this.certifierName,
    this.certifierRegNo,
    this.pdfReportPath,
    this.calibrationCertPaths = const [],
    this.subcontractorLicensePath,
    this.sitePhotoPaths = const [],
    this.status = EnvironmentSessionStatus.planned,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate 15-day workplace posting deadline according to Section 15 of OSH Act 2554.
  static String calculatePostingDeadline(String measurementDateStr) {
    try {
      final date = DateTime.parse(measurementDateStr);
      final deadline = date.add(const Duration(days: 15));
      return deadline.toIso8601String().split('T').first;
    } catch (_) {
      return '';
    }
  }

  /// Calculate 30-day DLPW agency submission deadline according to Section 15 & Cl. 15.
  static String calculateSubmissionDeadline(String measurementDateStr) {
    try {
      final date = DateTime.parse(measurementDateStr);
      final deadline = date.add(const Duration(days: 30));
      return deadline.toIso8601String().split('T').first;
    } catch (_) {
      return '';
    }
  }

  /// Effective 15-day posting deadline (falls back to calculation)
  String get effectivePostingDeadline =>
      (postingDeadline != null && postingDeadline!.isNotEmpty)
          ? postingDeadline!
          : calculatePostingDeadline(measurementDate);

  /// Effective 30-day DLPW submission deadline (falls back to calculation)
  String get effectiveSubmissionDeadline =>
      (submissionDeadline != null && submissionDeadline!.isNotEmpty)
          ? submissionDeadline!
          : calculateSubmissionDeadline(measurementDate);

  /// Check if posting deadline has passed without posting
  bool get isPostingOverdue {
    if (status == EnvironmentSessionStatus.reportPosted ||
        status == EnvironmentSessionStatus.submittedToDlpw ||
        status == EnvironmentSessionStatus.closed) {
      return false;
    }
    final dl = postingDeadline ?? calculatePostingDeadline(measurementDate);
    if (dl.isEmpty) return false;
    try {
      final dlDate = DateTime.parse(dl);
      return DateTime.now().isAfter(dlDate);
    } catch (_) {
      return false;
    }
  }

  /// Check if DLPW submission deadline has passed without submitting
  bool get isSubmissionOverdue {
    if (status == EnvironmentSessionStatus.submittedToDlpw ||
        status == EnvironmentSessionStatus.closed) {
      return false;
    }
    final dl = submissionDeadline ?? calculateSubmissionDeadline(measurementDate);
    if (dl.isEmpty) return false;
    try {
      final dlDate = DateTime.parse(dl);
      return DateTime.now().isAfter(dlDate);
    } catch (_) {
      return false;
    }
  }

  EnvironmentSessionModel copyWith({
    int? id,
    String? sessionId,
    String? sessionTitle,
    int? sessionYearBe,
    int? sessionYearAd,
    String? measurementDate,
    String? reportReceivedDate,
    String? postingDeadline,
    String? submissionDeadline,
    String? locationPlant,
    String? workplaceName,
    String? workplaceAddress,
    String? objective,
    SubcontractorType? subcontractorType,
    String? subcontractorId,
    String? subcontractorCompanyName,
    String? subcontractorRegNumber,
    String? surveyorName,
    String? surveyorLicenseNo,
    String? certifierName,
    String? certifierRegNo,
    String? pdfReportPath,
    List<String>? calibrationCertPaths,
    String? subcontractorLicensePath,
    List<String>? sitePhotoPaths,
    EnvironmentSessionStatus? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return EnvironmentSessionModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      sessionYearBe: sessionYearBe ?? this.sessionYearBe,
      sessionYearAd: sessionYearAd ?? this.sessionYearAd,
      measurementDate: measurementDate ?? this.measurementDate,
      reportReceivedDate: reportReceivedDate ?? this.reportReceivedDate,
      postingDeadline: postingDeadline ?? this.postingDeadline,
      submissionDeadline: submissionDeadline ?? this.submissionDeadline,
      locationPlant: locationPlant ?? this.locationPlant,
      workplaceName: workplaceName ?? this.workplaceName,
      workplaceAddress: workplaceAddress ?? this.workplaceAddress,
      objective: objective ?? this.objective,
      subcontractorType: subcontractorType ?? this.subcontractorType,
      subcontractorId: subcontractorId ?? this.subcontractorId,
      subcontractorCompanyName: subcontractorCompanyName ?? this.subcontractorCompanyName,
      subcontractorRegNumber: subcontractorRegNumber ?? this.subcontractorRegNumber,
      surveyorName: surveyorName ?? this.surveyorName,
      surveyorLicenseNo: surveyorLicenseNo ?? this.surveyorLicenseNo,
      certifierName: certifierName ?? this.certifierName,
      certifierRegNo: certifierRegNo ?? this.certifierRegNo,
      pdfReportPath: pdfReportPath ?? this.pdfReportPath,
      calibrationCertPaths: calibrationCertPaths ?? this.calibrationCertPaths,
      subcontractorLicensePath: subcontractorLicensePath ?? this.subcontractorLicensePath,
      sitePhotoPaths: sitePhotoPaths ?? this.sitePhotoPaths,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'session_title': sessionTitle,
      'session_year_be': sessionYearBe,
      'session_year_ad': sessionYearAd,
      'measurement_date': measurementDate,
      'report_received_date': reportReceivedDate,
      'posting_deadline': postingDeadline ?? calculatePostingDeadline(measurementDate),
      'submission_deadline': submissionDeadline ?? calculateSubmissionDeadline(measurementDate),
      'location_plant': locationPlant,
      'workplace_name': workplaceName,
      'workplace_address': workplaceAddress,
      'objective': objective,
      'subcontractor_type': subcontractorType.toDbCode(),
      'subcontractor_id': subcontractorId,
      'subcontractor_company_name': subcontractorCompanyName,
      'subcontractor_reg_number': subcontractorRegNumber,
      'surveyor_name': surveyorName,
      'surveyor_license_no': surveyorLicenseNo,
      'certifier_name': certifierName,
      'certifier_reg_no': certifierRegNo,
      'pdf_report_path': pdfReportPath,
      'calibration_cert_paths': json.encode(calibrationCertPaths),
      'subcontractor_license_path': subcontractorLicensePath,
      'site_photo_paths': json.encode(sitePhotoPaths),
      'status': status.toDbCode(),
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory EnvironmentSessionModel.fromMap(Map<String, dynamic> map) {
    List<String> certPaths = [];
    final rawCerts = map['calibration_cert_paths'] ?? map['calibrationCertPaths'];
    if (rawCerts is String && rawCerts.isNotEmpty) {
      try {
        final decoded = json.decode(rawCerts);
        if (decoded is List) {
          certPaths = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        certPaths = [rawCerts];
      }
    } else if (rawCerts is List) {
      certPaths = rawCerts.map((e) => e.toString()).toList();
    }

    List<String> photoPaths = [];
    final rawPhotos = map['site_photo_paths'] ?? map['sitePhotoPaths'];
    if (rawPhotos is String && rawPhotos.isNotEmpty) {
      try {
        final decoded = json.decode(rawPhotos);
        if (decoded is List) {
          photoPaths = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        photoPaths = [rawPhotos];
      }
    } else if (rawPhotos is List) {
      photoPaths = rawPhotos.map((e) => e.toString()).toList();
    }

    final measDate = map['measurement_date'] as String? ?? map['measurementDate'] as String? ?? '';

    return EnvironmentSessionModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String? ?? map['sessionId'] as String? ?? '',
      sessionTitle: map['session_title'] as String? ?? map['sessionTitle'] as String? ?? '',
      sessionYearBe: map['session_year_be'] as int? ??
          map['sessionYearBe'] as int? ??
          map['session_year'] as int? ??
          (DateTime.now().year + 543),
      sessionYearAd: map['session_year_ad'] as int? ??
          map['sessionYearAd'] as int? ??
          DateTime.now().year,
      measurementDate: measDate,
      reportReceivedDate: map['report_received_date'] as String? ?? map['reportReceivedDate'] as String?,
      postingDeadline: map['posting_deadline'] as String? ??
          map['postingDeadline'] as String? ??
          (measDate.isNotEmpty ? calculatePostingDeadline(measDate) : null),
      submissionDeadline: map['submission_deadline'] as String? ??
          map['submissionDeadline'] as String? ??
          (measDate.isNotEmpty ? calculateSubmissionDeadline(measDate) : null),
      locationPlant: map['location_plant'] as String? ?? map['locationPlant'] as String? ?? '',
      workplaceName: map['workplace_name'] as String? ?? map['workplaceName'] as String? ?? '',
      workplaceAddress: map['workplace_address'] as String? ?? map['workplaceAddress'] as String?,
      objective: map['objective'] as String? ?? '',
      subcontractorType: SubcontractorType.fromDbCode(
        map['subcontractor_type'] as String? ?? map['subcontractorType'] as String?,
      ),
      subcontractorId: map['subcontractor_id'] as String? ?? map['subcontractorId'] as String?,
      subcontractorCompanyName: map['subcontractor_company_name'] as String? ??
          map['subcontractorCompanyName'] as String? ??
          '',
      subcontractorRegNumber: map['subcontractor_reg_number'] as String? ??
          map['subcontractorRegNumber'] as String? ??
          '',
      surveyorName: map['surveyor_name'] as String? ?? map['surveyorName'] as String? ?? '',
      surveyorLicenseNo: map['surveyor_license_no'] as String? ?? map['surveyorLicenseNo'] as String?,
      certifierName: map['certifier_name'] as String? ?? map['certifierName'] as String? ?? '',
      certifierRegNo: map['certifier_reg_no'] as String? ?? map['certifierRegNo'] as String?,
      pdfReportPath: map['pdf_report_path'] as String? ?? map['pdfReportPath'] as String?,
      calibrationCertPaths: certPaths,
      subcontractorLicensePath: map['subcontractor_license_path'] as String? ??
          map['subcontractorLicensePath'] as String?,
      sitePhotoPaths: photoPaths,
      status: EnvironmentSessionStatus.fromDbCode(
        map['status'] as String?,
      ),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String? ?? map['createdAt'] as String?,
      updatedAt: map['updated_at'] as String? ?? map['updatedAt'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory EnvironmentSessionModel.fromJson(String source) =>
      EnvironmentSessionModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
