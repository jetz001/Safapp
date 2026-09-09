import 'dart:math';
import '../enums/emergency_enums.dart';
import '../../data/models/emergency_plan_model.dart';
import '../../data/models/drill_session_model.dart';

class EmergencyEvaluator {
  /// ๑. คำนวณโควตาการฝึกอบรมดับเพลิงขั้นต้น (กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๒๗)
  /// "นายจ้างต้องจัดให้ลูกจ้างไม่น้อยกว่าร้อยละ ๔๐ ของจำนวนลูกจ้างในแต่ละแผนกรับการฝึกอบรมการดับเพลิงขั้นต้น"
  static TrainingQuotaResult evaluateBasicFireTraining({
    required int totalEmployees,
    required int currentlyTrained,
    double statutoryPercent = 40.0,
  }) {
    if (totalEmployees <= 0) {
      return TrainingQuotaResult(
        totalEmployees: 0,
        requiredQuota: 0,
        currentlyTrained: currentlyTrained,
        shortfall: 0,
        currentPercent: 0.0,
        isCompliant: true,
        message: 'ยังไม่มีการระบุจำนวนพนักงาน',
      );
    }

    final requiredQuota = (totalEmployees * (statutoryPercent / 100.0)).ceil();
    final shortfall = max(0, requiredQuota - currentlyTrained);
    final currentPercent = (currentlyTrained / totalEmployees) * 100.0;
    final isCompliant = currentlyTrained >= requiredQuota;

    final message = isCompliant
        ? 'ผ่านเกณฑ์กฎหมาย: อบรมแล้ว ${currentPercent.toStringAsFixed(1)}% (เป้าหมายตามกฎหมาย >= $statutoryPercent%)'
        : 'ต่ำกว่าเกณฑ์กฎหมาย: ขาดอีก $shortfall คน เพื่อให้ครบ $statutoryPercent% ($requiredQuota คน)';

    return TrainingQuotaResult(
      totalEmployees: totalEmployees,
      requiredQuota: requiredQuota,
      currentlyTrained: currentlyTrained,
      shortfall: shortfall,
      currentPercent: currentPercent,
      isCompliant: isCompliant,
      message: message,
    );
  }

  /// ๒. คำนวณจำนวนเครื่องดับเพลิงและระยะติดตั้ง (กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๑๑ & ประกาศกรมฯ)
  /// เกณฑ์:
  /// - อันตรายน้อย (Light): 1 เครื่อง ต่อพื้นที่ไม่เกิน 150-200 ตร.ม. ระยะเข้าถึง <= 20 ม.
  /// - อันตรายปานกลาง (Medium): 1 เครื่อง ต่อพื้นที่ไม่เกิน 100-150 ตร.ม. ระยะเข้าถึง <= 20 ม.
  /// - อันตรายมาก (High): 1 เครื่อง ต่อพื้นที่ไม่เกิน 70-100 ตร.ม. ระยะเข้าถึง <= 15 ม.
  /// - ความสูงในการติดตั้ง: ส่วนบนสุดของตัวถังต้องสูงจากพื้นไม่เกิน ๑.๕๐ เมตร
  static ExtinguisherCalcResult evaluateExtinguishers({
    required double areaSqm,
    String hazardLevel = 'MEDIUM', // 'LIGHT', 'MEDIUM', 'HIGH'
  }) {
    double sqmPerUnit;
    double maxTravelDistanceMeters;
    String minFireRating;

    switch (hazardLevel.toUpperCase()) {
      case 'LIGHT':
        sqmPerUnit = 150.0;
        maxTravelDistanceMeters = 20.0;
        minFireRating = '1-A / 5-B';
        break;
      case 'HIGH':
        sqmPerUnit = 70.0;
        maxTravelDistanceMeters = 15.0;
        minFireRating = '4-A / 40-B';
        break;
      case 'MEDIUM':
      default:
        sqmPerUnit = 100.0;
        maxTravelDistanceMeters = 20.0;
        minFireRating = '2-A / 10-B';
        break;
    }

    final recommendedUnits = (areaSqm / sqmPerUnit).ceil();
    return ExtinguisherCalcResult(
      areaSqm: areaSqm,
      hazardLevel: hazardLevel,
      recommendedUnits: max(1, recommendedUnits),
      maxTravelDistanceMeters: maxTravelDistanceMeters,
      maxInstallationHeightMeters: 1.50,
      minFireRating: minFireRating,
      legalRuleSummary: 'ติดตั้ง ๑ เครื่อง ต่อพื้นที่ไม่เกิน $sqmPerUnit ตร.ม. ระยะเดินเข้าถึงไม่เกิน $maxTravelDistanceMeters เมตร และส่วนบนสุดสูงจากพื้นไม่เกิน ๑.๕๐ เมตร',
    );
  }

  /// ๓. ประเมินความสอดคล้องของการฝึกซ้อมและกำหนดส่งแบบ สปร. ๔ (ข้อ ๓๐)
  static DrillComplianceResult evaluateDrillCompliance(DrillSessionModel drill, {DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final issues = <String>[];
    final recommendations = <String>[];

    // 1. ตรวจสอบผู้จัดซ้อม
    if (drill.organizerType == DrillOrganizerType.selfApproved && drill.approvalCertNo.trim().isEmpty) {
      issues.add('กรณีนายจ้างจัดฝึกซ้อมเอง ต้องยื่นขอความเห็นชอบล่วงหน้าอย่างน้อย ๓๐ วัน และระบุเลขที่หนังสือเห็นชอบ');
    }

    // 2. ตรวจสอบอัตราเข้าร่วม
    if (drill.totalWorkersOnSite > 0) {
      final rate = (drill.participatedCount / drill.totalWorkersOnSite) * 100.0;
      if (rate < 90.0) {
        recommendations.add('อัตราเข้าร่วมซ้อมอยู่ที่ ${rate.toStringAsFixed(1)}% ควรจัดอบรม/ซ้อมย่อยเสริมสำหรับผู้ที่ติดงานหรือไม่สามารถเข้าร่วม');
      }
    }

    // 3. ตรวจสอบกำหนดส่ง สปร. ๔ (ภายใน 30 วันนับแต่วันซ้อมเสร็จ)
    bool isOverdue = false;
    int daysRemaining = 0;
    try {
      final deadline = DateTime.parse(drill.submissionDeadline);
      final diff = deadline.difference(DateTime(now.year, now.month, now.day)).inDays;
      daysRemaining = diff;
      if (diff < 0 && drill.spr4SubmissionStatus != Spr4SubmissionStatus.submitted) {
        isOverdue = true;
        issues.add('เกินกำหนดเวลายื่นแบบ สปร. ๔ ต่อพนักงานตรวจความปลอดภัยมาแล้ว ${diff.abs()} วัน (กฎหมายกำหนดภายใน ๓๐ วัน)');
      }
    } catch (_) {}

    // 4. ตรวจสอบเวลาอพยพ (Evacuation Time Benchmark)
    // อาคารทั่วไปควรไม่เกิน 3-5 นาที (180 - 300 วินาที)
    if (drill.evacuationTimeSec > 300) {
      recommendations.add('เวลาอพยพ ${drill.evacuationTimeSec} วินาที (> ๕ นาที) สูงกว่าเกณฑ์แนะนำ ควรซักซ้อมความคุ้นเคยกับเส้นทางหนีไฟ');
    }

    return DrillComplianceResult(
      isCompliant: issues.isEmpty,
      isOverdue: isOverdue,
      daysRemainingToSubmitSpr4: daysRemaining,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// ๔. ประเมินความครบถ้วนของเล่มแผนฉุกเฉิน (๖ แผนย่อยตามข้อ ๔)
  static PlanAuditResult evaluatePlanCompleteness(EmergencyPlanModel plan) {
    final missingPillars = <String>[];
    int score = 0;

    // 1. ตรวจตรา
    if (plan.inspectionPlan.items.isNotEmpty) {
      score += 15;
    } else {
      missingPillars.add('แผนการตรวจตรา: ยังไม่มีรายการจุดตรวจตราหรือความถี่');
    }

    // 2. อบรม
    if (plan.trainingPlan.courses.isNotEmpty) {
      score += 15;
    } else {
      missingPillars.add('แผนการอบรม: ยังไม่มีการกำหนดหลักสูตรอบรมดับเพลิงขั้นต้น');
    }

    // 3. รณรงค์
    if (plan.campaignPlan.activities.isNotEmpty) {
      score += 10;
    } else {
      missingPillars.add('แผนการรณรงค์: ยังไม่มีกิจกรรมส่งเสริมความปลอดภัย');
    }

    // 4. ดับเพลิง/ระงับเหตุ
    if (plan.suppressionPlan.regularShiftTeam.isNotEmpty && plan.fireCommanderName.isNotEmpty) {
      score += 25;
    } else {
      missingPillars.add('แผนการดับเพลิง: ขาดโครงสร้างทีมระงับเหตุหรือชื่อผู้อำนวยการ');
    }

    // 5. อพยพหนีไฟ
    if (plan.evacuationPlan.assemblyPoints.isNotEmpty) {
      score += 20;
    } else {
      missingPillars.add('แผนอพยพหนีไฟ: ยังไม่ได้กำหนดจุดรวมพล (Assembly Point)');
    }

    // 6. บรรเทาทุกข์
    if (plan.reliefPlan.governmentContacts.isNotEmpty) {
      score += 15;
    } else {
      missingPillars.add('แผนบรรเทาทุกข์: ขาดรายชื่อและเบอร์ติดต่อหน่วยงานภายนอก (199/รพ./ตำรวจ)');
    }

    return PlanAuditResult(
      completenessScore: score, // 0 - 100
      isFullyCompliant: score >= 80 && missingPillars.isEmpty,
      missingPillars: missingPillars,
    );
  }
}

class TrainingQuotaResult {
  final int totalEmployees;
  final int requiredQuota;
  final int currentlyTrained;
  final int shortfall;
  final double currentPercent;
  final bool isCompliant;
  final String message;

  const TrainingQuotaResult({
    required this.totalEmployees,
    required this.requiredQuota,
    required this.currentlyTrained,
    required this.shortfall,
    required this.currentPercent,
    required this.isCompliant,
    required this.message,
  });
}

class ExtinguisherCalcResult {
  final double areaSqm;
  final String hazardLevel;
  final int recommendedUnits;
  final double maxTravelDistanceMeters;
  final double maxInstallationHeightMeters;
  final String minFireRating;
  final String legalRuleSummary;

  const ExtinguisherCalcResult({
    required this.areaSqm,
    required this.hazardLevel,
    required this.recommendedUnits,
    required this.maxTravelDistanceMeters,
    required this.maxInstallationHeightMeters,
    required this.minFireRating,
    required this.legalRuleSummary,
  });
}

class DrillComplianceResult {
  final bool isCompliant;
  final bool isOverdue;
  final int daysRemainingToSubmitSpr4;
  final List<String> issues;
  final List<String> recommendations;

  const DrillComplianceResult({
    required this.isCompliant,
    required this.isOverdue,
    required this.daysRemainingToSubmitSpr4,
    required this.issues,
    required this.recommendations,
  });
}

class PlanAuditResult {
  final int completenessScore;
  final bool isFullyCompliant;
  final List<String> missingPillars;

  const PlanAuditResult({
    required this.completenessScore,
    required this.isFullyCompliant,
    required this.missingPillars,
  });
}
