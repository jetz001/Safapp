import '../enums/cpo_member_role.dart';
import '../../data/models/cpo_committee_model.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../data/datasources/cpo_statutory_standards.dart';

class CpoComplianceResult {
  final bool isCompliant;
  final int employeeCount;
  final int requiredTotal;
  final int actualTotal;
  final int requiredChair;
  final int actualChair;
  final int requiredEmployerRep;
  final int actualEmployerRep;
  final int requiredEmployeeRep;
  final int actualEmployeeRep;
  final int requiredSecretary;
  final int actualSecretary;
  final List<String> errorMessages;
  final List<String> warnings;

  const CpoComplianceResult({
    required this.isCompliant,
    required this.employeeCount,
    required this.requiredTotal,
    required this.actualTotal,
    required this.requiredChair,
    required this.actualChair,
    required this.requiredEmployerRep,
    required this.actualEmployerRep,
    required this.requiredEmployeeRep,
    required this.actualEmployeeRep,
    required this.requiredSecretary,
    required this.actualSecretary,
    this.errorMessages = const [],
    this.warnings = const [],
  });

  String get summaryText {
    if (employeeCount < 50) {
      return 'สถานประกอบการมีลูกจ้าง $employeeCount คน (ไม่เกิน ๕๐ คน กฎหมายไม่บังคับจัดตั้ง แต่สามารถมีได้ตามความเหมาะสม)';
    }
    if (isCompliant) {
      return 'สัดส่วนและจำนวนกรรมการ คปอ. สอดคล้องตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕ ครบถ้วน ($actualTotal/$requiredTotal คน)';
    }
    return 'สัดส่วนหรือจำนวนกรรมการยังไม่ครบตามเกณฑ์กฎหมาย (มี $actualTotal/$requiredTotal คน): ${errorMessages.join(", ")}';
  }
}

class CpoStatutoryEvaluator {
  /// ตรวจสอบความถูกต้องของสัดส่วนคณะกรรมการ คปอ. ตามกฎกระทรวง จป./คปอ. ๒๕๖๕
  static CpoComplianceResult evaluateQuota({
    required int employeeCount,
    required List<CpoMemberModel> members,
  }) {
    final quota = CpoStatutoryStandards.calculateQuota(employeeCount);
    final reqTotal = quota['total']!;
    final reqChair = quota['chair']!;
    final reqEmployer = quota['employer_rep']!;
    final reqEmployee = quota['employee_rep']!;
    final reqSec = quota['secretary']!;

    if (reqTotal == 0) {
      return CpoComplianceResult(
        isCompliant: true,
        employeeCount: employeeCount,
        requiredTotal: 0,
        actualTotal: members.length,
        requiredChair: 0,
        actualChair: members.where((m) => m.cpoRole == CpoMemberRole.chair).length,
        requiredEmployerRep: 0,
        actualEmployerRep: members.where((m) => m.cpoRole == CpoMemberRole.employerRep).length,
        requiredEmployeeRep: 0,
        actualEmployeeRep: members.where((m) => m.cpoRole == CpoMemberRole.employeeRep).length,
        requiredSecretary: 0,
        actualSecretary: members.where((m) => m.cpoRole == CpoMemberRole.secretary).length,
        warnings: ['จำนวนลูกจ้างน้อยกว่า ๕๐ คน ไม่เข้าข่ายบังคับตามกฎกระทรวง ข้อ ๒๒'],
      );
    }

    final actualChair = members.where((m) => m.cpoRole == CpoMemberRole.chair).length;
    final actualEmployer = members.where((m) => m.cpoRole == CpoMemberRole.employerRep).length;
    final actualEmployee = members.where((m) => m.cpoRole == CpoMemberRole.employeeRep).length;
    final actualSec = members.where((m) => m.cpoRole == CpoMemberRole.secretary).length;
    final actualTotal = members.length;

    final errors = <String>[];
    final warnings = <String>[];

    if (actualChair < reqChair) {
      errors.add('ขาดประธาน คปอ. (ต้องการอย่างน้อย $reqChair คน)');
    }
    if (actualEmployer < reqEmployer) {
      errors.add('ผู้แทนนายจ้างระดับบังคับบัญชาไม่ครบ (มี $actualEmployer จากต้องการ $reqEmployer คน)');
    }
    if (actualEmployee < reqEmployee) {
      errors.add('ผู้แทนลูกจ้างจากการเลือกตั้งไม่ครบ (มี $actualEmployee จากต้องการ $reqEmployee คน)');
    }
    if (actualSec < reqSec) {
      errors.add('ขาดเลขานุการ คปอ. จป.วิชาชีพ (ต้องการอย่างน้อย $reqSec คน)');
    }
    if (actualTotal < reqTotal) {
      errors.add('จำนวนกรรมการรวมไม่ถึงเกณฑ์ขั้นต่ำ (มี $actualTotal จากต้องการ $reqTotal คน)');
    }

    final isCompliant = errors.isEmpty;

    return CpoComplianceResult(
      isCompliant: isCompliant,
      employeeCount: employeeCount,
      requiredTotal: reqTotal,
      actualTotal: actualTotal,
      requiredChair: reqChair,
      actualChair: actualChair,
      requiredEmployerRep: reqEmployer,
      actualEmployerRep: actualEmployer,
      requiredEmployeeRep: reqEmployee,
      actualEmployeeRep: actualEmployee,
      requiredSecretary: reqSec,
      actualSecretary: actualSec,
      errorMessages: errors,
      warnings: warnings,
    );
  }

  /// ตรวจสอบองค์ประชุม (Quorum): ต้องไม่น้อยกว่ากึ่งหนึ่ง และต้องมีตัวแทนนายจ้างและตัวแทนลูกจ้างอย่างน้อยฝ่ายละ 1 คน
  static bool evaluateQuorum({
    required int totalMembers,
    required List<CpoAttendeeModel> attendees,
  }) {
    if (totalMembers <= 0) return true;
    final presentAttendees = attendees.where((a) => a.isPresent).toList();
    if (presentAttendees.length < (totalMembers / 2.0).ceil()) {
      return false;
    }
    // Check both employer side and employee side
    final hasEmployerSide = presentAttendees.any((a) =>
        a.roleLabel.contains('นายจ้าง') || a.roleLabel.contains('ประธาน') || a.roleLabel.contains('บังคับบัญชา'));
    final hasEmployeeSide = presentAttendees.any((a) =>
        a.roleLabel.contains('ลูกจ้าง'));

    return hasEmployerSide && hasEmployeeSide;
  }

  /// ประเมินความถี่การประชุมประจำปี (กฎหมายกำหนดอย่างน้อย ๑ ครั้งต่อเดือน / ๑๒ ครั้งต่อปี)
  static Map<String, dynamic> evaluateMeetingFrequency({
    required List<CpoMeetingModel> meetingsInYear,
    int targetYearCount = 12,
  }) {
    final completedMeetings = meetingsInYear.where((m) => m.status.name == 'completed').length;
    final scheduledMeetings = meetingsInYear.where((m) => m.status.name == 'scheduled' || m.status.name == 'inProgress').length;
    final totalMeetings = completedMeetings + scheduledMeetings;
    final percent = ((completedMeetings / targetYearCount) * 100.0).clamp(0.0, 100.0);

    return {
      'completed_count': completedMeetings,
      'total_count': totalMeetings,
      'target_count': targetYearCount,
      'is_statutory_met': completedMeetings >= targetYearCount,
      'completion_percentage': percent,
      'remaining_needed': (targetYearCount - completedMeetings).clamp(0, targetYearCount),
    };
  }
}
