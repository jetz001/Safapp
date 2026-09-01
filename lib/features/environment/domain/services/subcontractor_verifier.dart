import '../models/subcontractor_model.dart';

/// Validation status code for subcontractor licensing credentials.
enum SubcontractorValidationStatus {
  valid,
  expired,
  invalidPrefixMismatch,
  invalidFormat,
  missingInformation;

  String get labelTh {
    switch (this) {
      case SubcontractorValidationStatus.valid:
        return 'เอกสารและเลขทะเบียนถูกต้องตามกฎหมาย';
      case SubcontractorValidationStatus.expired:
        return 'ใบอนุญาต/การขึ้นทะเบียนหมดอายุแล้ว';
      case SubcontractorValidationStatus.invalidPrefixMismatch:
        return 'คำนำหน้าเลขทะเบียนไม่ตรงตามประเภท (ม.๙ ต้องเป็น "นบ." / ม.๑๑ ต้องเป็น "บ.")';
      case SubcontractorValidationStatus.invalidFormat:
        return 'รูปแบบเลขทะเบียนไม่ถูกต้อง';
      case SubcontractorValidationStatus.missingInformation:
        return 'ข้อมูลจำเป็นไม่ครบถ้วน';
    }
  }
}

/// Detailed validation result for subcontractor verification.
class SubcontractorValidationResult {
  final bool isValid;
  final SubcontractorValidationStatus status;
  final String messageTh;
  final String? registrationNumber;
  final SubcontractorType subcontractorType;
  final int? daysRemaining;

  const SubcontractorValidationResult({
    required this.isValid,
    required this.status,
    required this.messageTh,
    this.registrationNumber,
    required this.subcontractorType,
    this.daysRemaining,
  });
}

/// Statutory Verification Service for Outsource Service Providers (ม.๙ นบ. & ม.๑๑ บ.).
class SubcontractorVerifier {
  SubcontractorVerifier._();

  /// Validates a subcontractor model or registration credentials against statutory rules.
  static SubcontractorValidationResult validate({
    required SubcontractorType type,
    required String licenseNumber,
    DateTime? expireDate,
    String? surveyorName,
    String? certifierName,
  }) {
    final reg = licenseNumber.trim();
    if (reg.isEmpty) {
      return SubcontractorValidationResult(
        isValid: false,
        status: SubcontractorValidationStatus.missingInformation,
        messageTh: 'กรุณาระบุเลขทะเบียนหรือเลขที่ใบอนุญาตผู้ให้บริการ',
        registrationNumber: reg,
        subcontractorType: type,
      );
    }

    // 1. Prefix Validation
    if (type == SubcontractorType.section9Individual) {
      if (!reg.startsWith('นบ.') && !reg.startsWith('นบ')) {
        return SubcontractorValidationResult(
          isValid: false,
          status: SubcontractorValidationStatus.invalidPrefixMismatch,
          messageTh: 'ผู้ขึ้นทะเบียนบุคคลธรรมดาตามมาตรา ๙ ต้องมีเลขทะเบียนขึ้นต้นด้วย "นบ." (เช่น นบ. 0123-45/2566)',
          registrationNumber: reg,
          subcontractorType: type,
        );
      }
    } else if (type == SubcontractorType.section11Juristic) {
      if (!reg.startsWith('บ.') && !reg.startsWith('บ ')) {
        return SubcontractorValidationResult(
          isValid: false,
          status: SubcontractorValidationStatus.invalidPrefixMismatch,
          messageTh: 'นิติบุคคลผู้ได้รับใบอนุญาตตามมาตรา ๑๑ ต้องมีเลขที่ใบอนุญาตขึ้นต้นด้วย "บ." (เช่น บ. 0045-12/2565)',
          registrationNumber: reg,
          subcontractorType: type,
        );
      }
    }

    // 2. Expiration Validation
    int? daysRemaining;
    if (expireDate != null) {
      final today = DateTime.now();
      final expDay = DateTime(expireDate.year, expireDate.month, expireDate.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      daysRemaining = expDay.difference(todayDay).inDays;

      if (daysRemaining < 0) {
        return SubcontractorValidationResult(
          isValid: false,
          status: SubcontractorValidationStatus.expired,
          messageTh: 'ใบอนุญาต/การขึ้นทะเบียนหมดอายุแล้วเมื่อ ${expireDate.toIso8601String().split('T').first}',
          registrationNumber: reg,
          subcontractorType: type,
          daysRemaining: daysRemaining,
        );
      }
    }

    return SubcontractorValidationResult(
      isValid: true,
      status: SubcontractorValidationStatus.valid,
      messageTh: 'เลขทะเบียน $reg ถูกต้องตามกฎหมาย ${type.labelTh}',
      registrationNumber: reg,
      subcontractorType: type,
      daysRemaining: daysRemaining,
    );
  }

  /// Calculates statutory deadlines from the measurement date (Section 15 OSH Act 2554).
  /// - Workplace posting deadline: Measurement Date + 15 Calendar Days
  /// - DLPW Submission deadline: Measurement Date + 30 Calendar Days
  static ({DateTime postingDeadline, DateTime submissionDeadline}) calculateStatutoryDeadlines(
    DateTime measurementDate,
  ) {
    final posting = measurementDate.add(const Duration(days: 15));
    final submission = measurementDate.add(const Duration(days: 30));
    return (postingDeadline: posting, submissionDeadline: submission);
  }
}
