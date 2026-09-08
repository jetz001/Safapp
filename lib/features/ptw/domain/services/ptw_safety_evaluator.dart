import '../enums/high_risk_type.dart';
import '../enums/ptw_status.dart';
import '../enums/confined_role_type.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/gas_test_log_model.dart';
import '../../data/models/confined_role_model.dart';
import '../../data/models/fire_watch_model.dart';
import '../../data/models/loto_isolation_model.dart';

/// Result container for safety rule validations
class PtwValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const PtwValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory PtwValidationResult.success({List<String> warnings = const []}) =>
      PtwValidationResult(isValid: true, errors: const [], warnings: warnings);

  factory PtwValidationResult.failure(List<String> errors, {List<String> warnings = const []}) =>
      PtwValidationResult(isValid: false, errors: errors, warnings: warnings);
}

/// Statutory Safety Rules & Compliance Evaluation Engine for High-Risk PTW
/// Codified according to Thai Royal Gazette Ministerial Regulations
class PtwSafetyEvaluator {
  // Statutory Gas Concentration Limits (กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗)
  static const double minOxygen = 19.5; // %
  static const double maxOxygen = 23.5; // %
  static const double maxLel = 10.0; // % LEL
  static const double maxCoPpm = 25.0; // ppm
  static const double maxH2sPpm = 10.0; // ppm

  // Statutory Fire Watch Post-Work Time (กฎกระทรวงอัคคีภัย ๒๕๕๕)
  static const int minFireWatchMinutes = 30;

  // Statutory Cleared Radius for Hot Work
  static const double minHotWorkClearedRadiusMeters = 11.0;

  // Statutory Height Threshold (กฎกระทรวงงานบนที่สูง ๒๕๖๔)
  static const double heightThresholdMeters = 2.0;

  // Statutory Trench Excavation Depth Threshold (กฎกระทรวงงานดินขุด ๒๕๖๔)
  static const double excavationDepthThresholdMeters = 1.5;

  /// Evaluate atmospheric test safety against Thai Confined Space Law
  static PtwValidationResult evaluateAtmosphere({
    required double oxygenPercent,
    required double combustiblePercentLel,
    required double carbonMonoxidePpm,
    required double hydrogenSulfidePpm,
    double? otherToxicPpm,
    double otherToxicLimit = 0.0,
  }) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (oxygenPercent < minOxygen) {
      errors.add('ระดับออกซิเจนต่ำกว่าเกณฑ์ (${oxygenPercent.toStringAsFixed(1)}% < $minOxygen%): บรรยากาศอันตรายเสี่ยงหมดสติ/เสียชีวิต');
    } else if (oxygenPercent > maxOxygen) {
      errors.add('ระดับออกซิเจนสูงกว่าเกณฑ์ (${oxygenPercent.toStringAsFixed(1)}% > $maxOxygen%): บรรยากาศเพิ่มความเสี่ยงเพลิงไหม้รุนแรง');
    }

    if (combustiblePercentLel >= maxLel) {
      errors.add('ก๊าซหรือไอระเหยไวไฟเกินเกณฑ์ (${combustiblePercentLel.toStringAsFixed(1)}% LEL >= $maxLel%): เสี่ยงต่อการระเบิด');
    } else if (combustiblePercentLel >= 5.0) {
      warnings.add('ตรวจพบก๊าซไวไฟระดับเฝ้าระวัง (${combustiblePercentLel.toStringAsFixed(1)}% LEL)');
    }

    if (carbonMonoxidePpm >= maxCoPpm) {
      errors.add('ก๊าซคาร์บอนมอนอกไซด์เกินเกณฑ์ (${carbonMonoxidePpm.toStringAsFixed(1)} ppm >= $maxCoPpm ppm): ก๊าซพิษอันตราย');
    }

    if (hydrogenSulfidePpm >= maxH2sPpm) {
      errors.add('ก๊าซไฮโดรเจนซัลไฟด์เกินเกณฑ์ (${hydrogenSulfidePpm.toStringAsFixed(1)} ppm >= $maxH2sPpm ppm): ก๊าซไข่เน่าเป็นพิษรุนแรง');
    }

    if (otherToxicPpm != null && otherToxicLimit > 0.0 && otherToxicPpm >= otherToxicLimit) {
      errors.add('สารเคมีอันตรายอื่นๆ เกินเกณฑ์มาตรฐาน (${otherToxicPpm.toStringAsFixed(1)} >= $otherToxicLimit ppm)');
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Evaluate Confined Space 4-Role Completeness under Ministerial Regulation B.E. 2562 (ข้อ ๙-๑๒)
  static PtwValidationResult evaluateConfinedSpaceRoles(List<ConfinedRoleModel> roles) {
    final List<String> errors = [];
    final List<String> warnings = [];

    final authList = roles.where((r) => r.roleType == ConfinedRoleType.authorizer).toList();
    final supList = roles.where((r) => r.roleType == ConfinedRoleType.supervisor).toList();
    final attList = roles.where((r) => r.roleType == ConfinedRoleType.attendant).toList();
    final entList = roles.where((r) => r.roleType == ConfinedRoleType.entrant).toList();

    if (authList.isEmpty) {
      errors.add('ขาดผู้อนุญาต (Authorizer) ตามกฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๙');
    } else {
      for (final a in authList) {
        if (!a.isCertificateValid) {
          errors.add('ใบประกาศผู้อนุญาต (${a.personName}) ไม่ถูกต้องหรือหมดอายุ');
        }
      }
    }

    if (supList.isEmpty) {
      errors.add('ขาดผู้ควบคุมงาน (Supervisor) ตามกฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๐');
    } else {
      for (final s in supList) {
        if (!s.isCertificateValid) {
          errors.add('ใบประกาศผู้ควบคุมงาน (${s.personName}) ไม่ถูกต้องหรือหมดอายุ');
        }
      }
    }

    if (attList.isEmpty) {
      errors.add('ขาดผู้ช่วยเหลือ/เฝ้าระวังทางเข้าออก (Attendant) ตามกฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๑');
    } else {
      for (final att in attList) {
        if (!att.isCertificateValid) {
          errors.add('ใบประกาศผู้ช่วยเหลือ (${att.personName}) ไม่ถูกต้องหรือหมดอายุ');
        }
      }
    }

    if (entList.isEmpty) {
      errors.add('ขาดผู้ปฏิบัติงานในที่อับอากาศ (Entrant) ตามกฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๒');
    } else {
      for (final ent in entList) {
        if (!ent.isCertificateValid) {
          errors.add('ใบประกาศผู้ปฏิบัติงาน (${ent.personName}) ไม่ถูกต้องหรือหมดอายุ');
        }
      }
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Evaluate Hot Work Fire Watch & Post-Work Monitoring under Ministerial Regulation B.E. 2555
  static PtwValidationResult evaluateFireWatch(FireWatchModel? fireWatch) {
    if (fireWatch == null) {
      return PtwValidationResult.failure(['ไม่ได้บันทึกข้อมูลผู้เฝ้าระวังไฟและมาตรการป้องกันอัคคีภัย']);
    }

    final List<String> errors = [];
    final List<String> warnings = [];

    if (fireWatch.fireWatcherName.trim().isEmpty) {
      errors.add('ต้องระบุชื่อผู้เฝ้าระวังไฟ (Fire Watcher)');
    }

    if (!fireWatch.extinguisherInspectedReady) {
      errors.add('เครื่องดับเพลิงยังไม่ได้รับการตรวจสอบความพร้อมใช้งาน');
    }

    if (fireWatch.clearedRadiusMeters < minHotWorkClearedRadiusMeters &&
        !fireWatch.fireBlanketInstalled &&
        !fireWatch.combustibleMaterialProtected) {
      errors.add('รัศมีเคลียร์วัสดุติดไฟน้อยกว่า $minHotWorkClearedRadiusMeters เมตร โดยไม่มีผ้ากันสะเก็ดไฟหรือวัสดุป้องกัน');
    }

    if (fireWatch.postWorkWatchDurationMinutes < minFireWatchMinutes) {
      errors.add('ระยะเวลาเฝ้าระวังหลังเลิกงานต้องไม่น้อยกว่า $minFireWatchMinutes นาที (ตรวจวัดได้: ${fireWatch.postWorkWatchDurationMinutes} นาที)');
    }

    if (!fireWatch.isPostWorkAreaSafe) {
      errors.add('พื้นที่หลังเลิกงานยังไม่ได้รับการยืนยันว่าปลอดภัยจากความร้อนคุกรุ่น');
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Evaluate Lockout/Tagout (LOTO) Energy Isolation under Electrical Regulation B.E. 2558
  static PtwValidationResult evaluateLoto(List<LotoIsolationModel> isolations, {bool requireDeIsolation = false}) {
    if (isolations.isEmpty) {
      return PtwValidationResult.failure(['ต้องระบุจุดตัดแยกพลังงาน (LOTO Isolation Point) อย่างน้อย 1 จุด']);
    }

    final List<String> errors = [];
    final List<String> warnings = [];

    for (final iso in isolations) {
      if (iso.equipmentTagNo.trim().isEmpty) {
        errors.add('ต้องระบุรหัสเครื่องจักร/อุปกรณ์ (Tag No.)');
      }
      if (iso.padlockTagNo.trim().isEmpty) {
        errors.add('ต้องระบุหมายเลขแม่กุญแจสำหรับ ${iso.equipmentTagNo}');
      }
      if (!iso.isZeroEnergyVerified) {
        errors.add('จุดตัดแยก ${iso.equipmentTagNo} ยังไม่ได้รับการทดสอบพลังงานเป็นศูนย์ (Zero Energy Verification)');
      }
      if (requireDeIsolation && !iso.isDeIsolated) {
        errors.add('จุดตัดแยก ${iso.equipmentTagNo} ยังไม่ได้ทำการปลดล็อกคืนสภาพ (De-isolation)');
      }
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Guard Rule 1: Validate if Draft can be submitted to Pending Approval
  static PtwValidationResult canSubmitDraft(PtwModel permit) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (permit.workTitle.trim().isEmpty) errors.add('ต้องระบุชื่องานที่ขออนุญาต');
    if (permit.plantArea.trim().isEmpty) errors.add('ต้องระบุพื้นที่/โรงงาน');
    if (permit.specificLocation.trim().isEmpty) errors.add('ต้องระบุตำแหน่งงานเฉพาะเจาะจง');
    if (permit.workStartDate.trim().isEmpty || permit.workStartTime.trim().isEmpty) {
      errors.add('ต้องระบุวันและเวลาเริ่มต้นปฏิบัติงาน');
    }
    if (permit.workEndDate.trim().isEmpty || permit.workEndTime.trim().isEmpty) {
      errors.add('ต้องระบุวันและเวลาสิ้นสุดปฏิบัติงาน');
    }
    if (permit.applicantName.trim().isEmpty) errors.add('ต้องระบุชื่อผู้ขออนุญาต');
    if (permit.applicantSignaturePath == null || permit.applicantSignaturePath!.isEmpty) {
      errors.add('ต้องมีลายเซ็นดิจิทัลของผู้ขออนุญาต');
    }

    // Check mandatory checklist items
    if (permit.checklistItems.isNotEmpty) {
      final mandatoryIncomplete = permit.checklistItems
          .where((c) => c.isMandatory && c.result != 'YES')
          .map((c) => c.questionTh)
          .toList();
      if (mandatoryIncomplete.isNotEmpty) {
        errors.add('มีรายการ Checklist บังคับที่ยังไม่ผ่านการตรวจสอบ: ${mandatoryIncomplete.length} รายการ');
      }
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Guard Rule 2: Validate if Pending Approval can be activated
  static PtwValidationResult canApproveToActive(PtwModel permit) {
    final List<String> errors = [];
    final List<String> warnings = [];

    // Draft completeness check
    final draftCheck = canSubmitDraft(permit);
    if (!draftCheck.isValid) {
      errors.addAll(draftCheck.errors);
    }

    // Signatures from Safety Officer & Authorizer
    if (permit.safetyOfficerSignaturePath == null || permit.safetyOfficerSignaturePath!.isEmpty) {
      errors.add('ต้องมีลายเซ็นดิจิทัลของเจ้าหน้าที่ความปลอดภัย (จป.วิชาชีพ)');
    }
    if (permit.authorizerSignaturePath == null || permit.authorizerSignaturePath!.isEmpty) {
      errors.add('ต้องมีลายเซ็นดิจิทัลของผู้อนุญาตตามกฎหมาย');
    }

    // Confined space specific checks
    if (permit.isConfinedSpaceWork) {
      final roleCheck = evaluateConfinedSpaceRoles(permit.confinedRoles);
      if (!roleCheck.isValid) errors.addAll(roleCheck.errors);

      final preEntryGas = permit.gasTestLogs.where((g) => g.testStage == 'PRE_ENTRY').toList();
      if (preEntryGas.isEmpty) {
        errors.add('ต้องทำการตรวจวัดบรรยากาศก่อนเข้าทำงาน (Pre-entry Gas Test)');
      } else {
        final lastPreEntry = preEntryGas.last;
        final gasCheck = evaluateAtmosphere(
          oxygenPercent: lastPreEntry.oxygenPercent,
          combustiblePercentLel: lastPreEntry.combustiblePercentLel,
          carbonMonoxidePpm: lastPreEntry.carbonMonoxidePpm,
          hydrogenSulfidePpm: lastPreEntry.hydrogenSulfidePpm,
          otherToxicPpm: lastPreEntry.toxicOtherPpm,
        );
        if (!gasCheck.isValid) errors.addAll(gasCheck.errors);
      }
    }

    // LOTO specific checks
    if (permit.isElectricalLotoWork) {
      final lotoCheck = evaluateLoto(permit.lotoIsolations, requireDeIsolation: false);
      if (!lotoCheck.isValid) errors.addAll(lotoCheck.errors);
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Guard Rule 3: Validate if Permit can be extended or handed over
  static PtwValidationResult canExtendHandover(PtwModel permit) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (permit.status != PtwStatus.active && permit.status != PtwStatus.extendedHandover) {
      errors.add('สามารถขอต่อเวลาหรือส่งมอบงานได้เฉพาะใบอนุญาตที่อยู่ในสถานะเปิดทำงาน (Active) เท่านั้น');
    }

    if (permit.extensionHours <= 0) {
      errors.add('ต้องระบุจำนวนชั่วโมงที่ขอต่อเวลา (> 0 ชั่วโมง)');
    }

    if (permit.extensionReason == null || permit.extensionReason!.trim().isEmpty) {
      errors.add('ต้องระบุเหตุผลความจำเป็นในการขอต่อเวลา');
    }

    if (permit.handoverSignaturePath == null || permit.handoverSignaturePath!.isEmpty) {
      errors.add('ต้องมีลายเซ็นผู้รับมอบงาน/ผู้ขอต่อเวลา');
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }

  /// Guard Rule 4: Validate if Permit can be closed or cancelled
  static PtwValidationResult canClosePermit(PtwModel permit) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (permit.closureSignaturePath == null || permit.closureSignaturePath!.isEmpty) {
      errors.add('ต้องมีลายเซ็นดิจิทัลของผู้ตรวจสอบปิดงาน');
    }

    // Hot work 30-min fire watch check
    if (permit.isHotWork) {
      final fwCheck = evaluateFireWatch(permit.fireWatch);
      if (!fwCheck.isValid) errors.addAll(fwCheck.errors);
    }

    // LOTO de-isolation check
    if (permit.isElectricalLotoWork) {
      final lotoCheck = evaluateLoto(permit.lotoIsolations, requireDeIsolation: true);
      if (!lotoCheck.isValid) errors.addAll(lotoCheck.errors);
    }

    if (errors.isNotEmpty) {
      return PtwValidationResult.failure(errors, warnings: warnings);
    }
    return PtwValidationResult.success(warnings: warnings);
  }
}
