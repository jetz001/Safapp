import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/cpo/data/datasources/cpo_statutory_standards.dart';
import 'package:safety_superapp/features/cpo/data/models/cpo_committee_model.dart';
import 'package:safety_superapp/features/cpo/data/models/cpo_election_model.dart';
import 'package:safety_superapp/features/cpo/data/models/cpo_action_item_model.dart';
import 'package:safety_superapp/features/cpo/domain/enums/cpo_member_role.dart';
import 'package:safety_superapp/features/cpo/domain/enums/cpo_election_status.dart';
import 'package:safety_superapp/features/cpo/domain/enums/cpo_action_status.dart';

void main() {
  group('CpoStatutoryStandards Agendas', () {
    test('Standard agendas contain exactly 6 agendas defined in Labour Dept manual', () {
      final agendas = CpoStatutoryStandards.getStandard6Agendas();
      expect(agendas.length, 6);
      expect(agendas[0]['agenda_no'], 1);
      expect(agendas[0]['title'], contains('เรื่องที่ประธานแจ้งให้ที่ประชุมทราบ'));
      expect(agendas[1]['agenda_no'], 2);
      expect(agendas[1]['title'], contains('รับรองรายงานการประชุมครั้งที่ผ่านมา'));
      expect(agendas[2]['agenda_no'], 3);
      expect(agendas[2]['title'], contains('สืบเนื่องจากการประชุมครั้งที่แล้ว'));
      expect(agendas[3]['agenda_no'], 4);
      expect(agendas[3]['title'], contains('เพื่อทราบ'));
      expect(agendas[4]['agenda_no'], 5);
      expect(agendas[4]['title'], contains('เพื่อพิจารณา'));
      expect(agendas[5]['agenda_no'], 6);
      expect(agendas[5]['title'], contains('เรื่องอื่นๆ'));
    });
  });

  group('Cpo Models Serialization and Helper tests', () {
    test('CpoTermModel toMap and fromMap', () {
      final term = CpoTermModel(
        id: 10,
        termCode: 'TERM-2567-01',
        termTitle: 'วาระ คปอ. 2567-2569',
        startDate: '2024-01-01',
        endDate: '2026-01-01',
        employeeCount: 220,
        status: 'ACTIVE',
      );

      final map = term.toMap();
      final from = CpoTermModel.fromMap(map);

      expect(from.id, 10);
      expect(from.termTitle, 'วาระ คปอ. 2567-2569');
      expect(from.employeeCount, 220);
      expect(from.isActive, isTrue);
    });

    test('CpoMemberModel role labels', () {
      final m1 = CpoMemberModel(termId: 1, fullName: 'นาย สมชาย', cpoRole: CpoMemberRole.chair);
      final m2 = CpoMemberModel(termId: 1, fullName: 'นาย สมนึก', cpoRole: CpoMemberRole.employerRep);
      final m3 = CpoMemberModel(termId: 1, fullName: 'น.ส. สวย', cpoRole: CpoMemberRole.employeeRep);
      final m4 = CpoMemberModel(termId: 1, fullName: 'นาย วิชาชีพ', cpoRole: CpoMemberRole.secretary);

      expect(m1.cpoRole.thaiLabel, contains('ประธาน'));
      expect(m2.cpoRole.thaiLabel, contains('ผู้แทนนายจ้าง'));
      expect(m3.cpoRole.thaiLabel, contains('ผู้แทนลูกจ้าง'));
      expect(m4.cpoRole.thaiLabel, contains('เลขานุการ'));
    });

    test('CpoElectionModel and Candidate serialization', () {
      final election = CpoElectionModel(
        id: 1,
        electionCode: 'ELC-2567-01',
        electionTitle: 'เลือกตั้งผู้แทนลูกจ้าง 2567',
        termYear: '2567',
        votingDate: '2024-03-15',
        requiredRepsCount: 3,
        eligibleVotersCount: 300,
        status: CpoElectionStatus.voting,
        candidates: [
          const CpoCandidateModel(
            id: 1,
            electionId: 1,
            candidateNo: 1,
            fullName: 'นาย กิตติ',
            votesReceived: 45,
            isElected: true,
          ),
        ],
        officers: [
          const CpoElectionOfficerModel(
            id: 1,
            electionId: 1,
            officerName: 'นาย ประธาน กกต.',
            officerRole: 'CHAIR',
          ),
        ],
      );

      final map = election.toMap();
      final from = CpoElectionModel.fromMap(map, candidates: election.candidates, officers: election.officers);

      expect(from.electionCode, 'ELC-2567-01');
      expect(from.requiredRepsCount, 3);
      expect(from.status, CpoElectionStatus.voting);
      expect(from.candidates.length, 1);
      expect(from.candidates.first.isElected, isTrue);
      expect(from.officers.first.officerRoleLabel, contains('ประธาน กกต.'));
    });

    test('CpoActionItemModel isOverdue calculation', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      final tomorrow = DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10);

      final overdueItem = CpoActionItemModel(
        id: 1,
        itemCode: 'ACT-01',
        meetingId: 1,
        title: 'ติดตั้งการ์ดป้องกันเครื่องจักร',
        actionDetail: 'ติดตั้งการ์ดรอบสายพาน',
        responsiblePerson: 'สมชาย',
        dueDate: yesterday,
        status: CpoActionStatus.pending,
      );

      final notOverdueItem = CpoActionItemModel(
        id: 2,
        itemCode: 'ACT-02',
        meetingId: 1,
        title: 'จัดทำป้ายเตือน',
        actionDetail: 'จัดทำป้ายเตือนอันตราย',
        responsiblePerson: 'วิชัย',
        dueDate: tomorrow,
        status: CpoActionStatus.inProgress,
      );

      final completedItem = CpoActionItemModel(
        id: 3,
        itemCode: 'ACT-03',
        meetingId: 1,
        title: 'อบรมสารเคมี',
        actionDetail: 'จัดอบรมการใช้สารเคมี',
        responsiblePerson: 'สมศรี',
        dueDate: yesterday,
        status: CpoActionStatus.completed,
      );

      expect(overdueItem.isOverdue, isTrue);
      expect(notOverdueItem.isOverdue, isFalse);
      expect(completedItem.isOverdue, isFalse); // completed is never overdue
    });
  });
}
