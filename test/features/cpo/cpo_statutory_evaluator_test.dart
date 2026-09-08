import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/cpo/data/datasources/cpo_statutory_standards.dart';
import 'package:safety_superapp/features/cpo/domain/enums/cpo_member_role.dart';
import 'package:safety_superapp/features/cpo/domain/services/cpo_statutory_evaluator.dart';
import 'package:safety_superapp/features/cpo/data/models/cpo_committee_model.dart';
import 'package:safety_superapp/features/cpo/data/models/cpo_meeting_model.dart';

import 'package:safety_superapp/features/cpo/domain/enums/cpo_meeting_status.dart';

void main() {
  group('CpoStatutoryStandards Quota Calculation', () {
    test('Under 50 employees -> Not mandatory (all 0)', () {
      final quota = CpoStatutoryStandards.calculateQuota(45);
      expect(quota['total'], 0);
      expect(quota['chair'], 0);
      expect(quota['employer_rep'], 0);
      expect(quota['employee_rep'], 0);
      expect(quota['secretary'], 0);
    });

    test('50 - 99 employees -> >= 5 members (Chair 1, Employer 1, Employee 2, Sec 1)', () {
      final quota = CpoStatutoryStandards.calculateQuota(75);
      expect(quota['total'], 5);
      expect(quota['chair'], 1);
      expect(quota['employer_rep'], 1);
      expect(quota['employee_rep'], 2);
      expect(quota['secretary'], 1);
    });

    test('100 - 499 employees -> >= 7 members (Chair 1, Employer 2, Employee 3, Sec 1)', () {
      final quota = CpoStatutoryStandards.calculateQuota(250);
      expect(quota['total'], 7);
      expect(quota['chair'], 1);
      expect(quota['employer_rep'], 2);
      expect(quota['employee_rep'], 3);
      expect(quota['secretary'], 1);
    });

    test('>= 500 employees -> >= 11 members (Chair 1, Employer 4, Employee 5, Sec 1)', () {
      final quota = CpoStatutoryStandards.calculateQuota(1200);
      expect(quota['total'], 11);
      expect(quota['chair'], 1);
      expect(quota['employer_rep'], 4);
      expect(quota['employee_rep'], 5);
      expect(quota['secretary'], 1);
    });
  });

  group('CpoStatutoryEvaluator evaluateQuota', () {
    test('Compliant committee for 120 employees (requires 7 members)', () {
      final members = [
        CpoMemberModel(termId: 1, fullName: 'ประธาน วินัย', cpoRole: CpoMemberRole.chair),
        CpoMemberModel(termId: 1, fullName: 'นายจ้าง สมนึก', cpoRole: CpoMemberRole.employerRep),
        CpoMemberModel(termId: 1, fullName: 'นายจ้าง วิชัย', cpoRole: CpoMemberRole.employerRep),
        CpoMemberModel(termId: 1, fullName: 'ลูกจ้าง สมศรี', cpoRole: CpoMemberRole.employeeRep),
        CpoMemberModel(termId: 1, fullName: 'ลูกจ้าง บุญมี', cpoRole: CpoMemberRole.employeeRep),
        CpoMemberModel(termId: 1, fullName: 'ลูกจ้าง ชูเกียรติ', cpoRole: CpoMemberRole.employeeRep),
        CpoMemberModel(termId: 1, fullName: 'จป.ว. จริยา', cpoRole: CpoMemberRole.secretary),
      ];

      final result = CpoStatutoryEvaluator.evaluateQuota(
        employeeCount: 120,
        members: members,
      );

      expect(result.isCompliant, isTrue);
      expect(result.errorMessages, isEmpty);
      expect(result.actualTotal, 7);
      expect(result.requiredTotal, 7);
    });

    test('Non-compliant committee missing employee representatives', () {
      final members = [
        CpoMemberModel(termId: 1, fullName: 'ประธาน วินัย', cpoRole: CpoMemberRole.chair),
        CpoMemberModel(termId: 1, fullName: 'นายจ้าง สมนึก', cpoRole: CpoMemberRole.employerRep),
        CpoMemberModel(termId: 1, fullName: 'นายจ้าง วิชัย', cpoRole: CpoMemberRole.employerRep),
        CpoMemberModel(termId: 1, fullName: 'ลูกจ้าง สมศรี', cpoRole: CpoMemberRole.employeeRep), // only 1, needs 3
        CpoMemberModel(termId: 1, fullName: 'จป.ว. จริยา', cpoRole: CpoMemberRole.secretary),
      ];

      final result = CpoStatutoryEvaluator.evaluateQuota(
        employeeCount: 150,
        members: members,
      );

      expect(result.isCompliant, isFalse);
      expect(result.errorMessages.any((msg) => msg.contains('ผู้แทนลูกจ้างจากการเลือกตั้งไม่ครบ')), isTrue);
      expect(result.errorMessages.any((msg) => msg.contains('จำนวนกรรมการรวมไม่ถึงเกณฑ์ขั้นต่ำ')), isTrue);
    });
  });

  group('CpoStatutoryEvaluator evaluateQuorum', () {
    test('Quorum met when >= 50% present with both employer and employee sides', () {
      final attendees = [
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ประธาน สุรชัย', roleLabel: 'ประธาน คปอ.', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง อำนาจ', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง วารี', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'นายจ้าง มั่นคง', roleLabel: 'ผู้แทนนายจ้าง', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'จป.ว. สมหญิง', roleLabel: 'เลขานุการ คปอ.', isPresent: false),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง ชนะ', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: false),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'นายจ้าง ปราโมทย์', roleLabel: 'ผู้แทนนายจ้าง', isPresent: false),
      ];

      final isMet = CpoStatutoryEvaluator.evaluateQuorum(
        totalMembers: 7,
        attendees: attendees,
      );

      expect(isMet, isTrue);
    });

    test('Quorum fails when less than 50% attend', () {
      final attendees = [
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ประธาน สุรชัย', roleLabel: 'ประธาน คปอ.', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง อำนาจ', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'นายจ้าง มั่นคง', roleLabel: 'ผู้แทนนายจ้าง', isPresent: false),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'จป.ว. สมหญิง', roleLabel: 'เลขานุการ คปอ.', isPresent: false),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง ชนะ', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: false),
      ];

      final isMet = CpoStatutoryEvaluator.evaluateQuorum(
        totalMembers: 5,
        attendees: attendees, // only 2 out of 5 (40%)
      );

      expect(isMet, isFalse);
    });

    test('Quorum fails when no employee representatives attend', () {
      final attendees = [
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ประธาน สุรชัย', roleLabel: 'ประธาน คปอ.', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'นายจ้าง มั่นคง', roleLabel: 'ผู้แทนนายจ้างระดับบังคับบัญชา', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'นายจ้าง สามารถ', roleLabel: 'ผู้แทนนายจ้างระดับบังคับบัญชา', isPresent: true),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง ก', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: false),
        CpoAttendeeModel(meetingId: 1, attendeeName: 'ลูกจ้าง ข', roleLabel: 'ผู้แทนลูกจ้าง', isPresent: false),
      ];

      final isMet = CpoStatutoryEvaluator.evaluateQuorum(
        totalMembers: 5,
        attendees: attendees,
      );

      // 3 of 5 (60%) but 0 employee side!
      expect(isMet, isFalse);
    });
  });

  group('CpoStatutoryEvaluator evaluateMeetingFrequency', () {
    test('Calculates 12 meetings statutory requirement correctly', () {
      final meetings = List.generate(
        10,
        (i) => CpoMeetingModel(
          termId: 1,
          meetingNo: i + 1,
          meetingYear: '2567',
          meetingTitle: 'ประชุม คปอ. ครั้งที่ ${i + 1}',
          meetingDate: '2024-${(i + 1).toString().padLeft(2, "0")}-15',
          chairName: 'ประธาน',
          secretaryName: 'เลขานุการ',
          status: CpoMeetingStatus.completed,
          agendas: const [],
          attendees: const [],
        ),
      );

      final result = CpoStatutoryEvaluator.evaluateMeetingFrequency(meetingsInYear: meetings);
      expect(result['completed_count'], 10);
      expect(result['target_count'], 12);
      expect(result['is_statutory_met'], isFalse);
      expect(result['remaining_needed'], 2);
      expect((result['completion_percentage'] as double).round(), 83);
    });
  });
}
