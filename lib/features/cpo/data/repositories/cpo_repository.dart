import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/cpo_committee_model.dart';
import '../models/cpo_election_model.dart';
import '../models/cpo_meeting_model.dart';
import '../models/cpo_action_item_model.dart';
import '../models/cpo_distribution_model.dart';
import '../datasources/cpo_statutory_standards.dart';

class CpoRepository {
  final DatabaseHelper _dbHelper;

  CpoRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  // ══════════════════════════════════════════════════════════════════════════
  // 1. CPO Terms & Committee Members
  // ══════════════════════════════════════════════════════════════════════════

  Future<CpoTermModel?> getActiveTerm() async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'cpo_terms',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (res.isEmpty) return null;
    final term = CpoTermModel.fromMap(res.first);
    final members = await getMembersByTermId(term.id!);
    return term.copyWith(members: members);
  }

  Future<List<CpoTermModel>> getAllTerms() async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_terms', orderBy: 'id DESC');
    final list = <CpoTermModel>[];
    for (final m in res) {
      final term = CpoTermModel.fromMap(m);
      final members = await getMembersByTermId(term.id!);
      list.add(term.copyWith(members: members));
    }
    return list;
  }

  Future<List<CpoMemberModel>> getMembersByTermId(int termId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'cpo_members',
      where: 'term_id = ?',
      whereArgs: [termId],
      orderBy: 'id ASC',
    );
    return res.map((m) => CpoMemberModel.fromMap(m)).toList();
  }

  Future<int> saveTerm(CpoTermModel term) async {
    final db = await _dbHelper.database;
    if (term.id != null) {
      await db.update('cpo_terms', term.toMap(), where: 'id = ?', whereArgs: [term.id]);
      return term.id!;
    } else {
      return await db.insert('cpo_terms', term.toMap());
    }
  }

  Future<int> addMember(CpoMemberModel member) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_members', member.toMap());
  }

  Future<void> updateMember(CpoMemberModel member) async {
    final db = await _dbHelper.database;
    await db.update('cpo_members', member.toMap(), where: 'id = ?', whereArgs: [member.id]);
  }

  Future<void> deleteMember(int memberId) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_members', where: 'id = ?', whereArgs: [memberId]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Elections & กกต.
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<CpoElectionModel>> getAllElections() async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_elections', orderBy: 'id DESC');
    final list = <CpoElectionModel>[];
    for (final r in res) {
      final id = (r['id'] as num).toInt();
      final officers = await getElectionOfficers(id);
      final candidates = await getElectionCandidates(id);
      list.add(CpoElectionModel.fromMap(r, officers: officers, candidates: candidates));
    }
    return list;
  }

  Future<CpoElectionModel?> getElectionById(int electionId) async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_elections', where: 'id = ?', whereArgs: [electionId]);
    if (res.isEmpty) return null;
    final officers = await getElectionOfficers(electionId);
    final candidates = await getElectionCandidates(electionId);
    return CpoElectionModel.fromMap(res.first, officers: officers, candidates: candidates);
  }

  Future<List<CpoElectionOfficerModel>> getElectionOfficers(int electionId) async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_election_officers', where: 'election_id = ?', whereArgs: [electionId]);
    return res.map((m) => CpoElectionOfficerModel.fromMap(m)).toList();
  }

  Future<List<CpoCandidateModel>> getElectionCandidates(int electionId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'cpo_election_candidates',
      where: 'election_id = ?',
      whereArgs: [electionId],
      orderBy: 'candidate_no ASC',
    );
    return res.map((m) => CpoCandidateModel.fromMap(m)).toList();
  }

  Future<int> saveElection(CpoElectionModel election) async {
    final db = await _dbHelper.database;
    if (election.id != null) {
      await db.update('cpo_elections', election.toMap(), where: 'id = ?', whereArgs: [election.id]);
      return election.id!;
    } else {
      return await db.insert('cpo_elections', election.toMap());
    }
  }

  Future<int> addElectionOfficer(CpoElectionOfficerModel officer) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_election_officers', officer.toMap());
  }

  Future<void> deleteElectionOfficer(int officerId) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_election_officers', where: 'id = ?', whereArgs: [officerId]);
  }

  Future<int> addCandidate(CpoCandidateModel candidate) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_election_candidates', candidate.toMap());
  }

  Future<void> updateCandidate(CpoCandidateModel candidate) async {
    final db = await _dbHelper.database;
    await db.update('cpo_election_candidates', candidate.toMap(), where: 'id = ?', whereArgs: [candidate.id]);
  }

  Future<void> deleteCandidate(int candidateId) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_election_candidates', where: 'id = ?', whereArgs: [candidateId]);
  }

  Future<void> tallyElectionResults(int electionId, {int? requiredReps}) async {
    final db = await _dbHelper.database;
    final election = await getElectionById(electionId);
    if (election == null) return;
    final repsCount = requiredReps ?? election.requiredRepsCount;

    final candidates = await getElectionCandidates(electionId);
    candidates.sort((a, b) => b.votesReceived.compareTo(a.votesReceived));

    for (int i = 0; i < candidates.length; i++) {
      final rank = i + 1;
      final isElected = rank <= repsCount && candidates[i].votesReceived > 0;
      await db.update(
        'cpo_election_candidates',
        {
          'rank_order': rank,
          'is_elected': isElected ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [candidates[i].id],
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. Meetings & 6 Agendas
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<CpoMeetingModel>> getAllMeetings({String? year}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> res;
    if (year != null && year.isNotEmpty) {
      res = await db.query('cpo_meetings', where: 'meeting_year = ?', whereArgs: [year], orderBy: 'meeting_no DESC');
    } else {
      res = await db.query('cpo_meetings', orderBy: 'id DESC');
    }
    final list = <CpoMeetingModel>[];
    for (final m in res) {
      final id = (m['id'] as num).toInt();
      final attendees = await getMeetingAttendees(id);
      final agendas = await getMeetingAgendas(id);
      list.add(CpoMeetingModel.fromMap(m, attendees: attendees, agendas: agendas));
    }
    return list;
  }

  Future<CpoMeetingModel?> getMeetingById(int meetingId) async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_meetings', where: 'id = ?', whereArgs: [meetingId]);
    if (res.isEmpty) return null;
    final attendees = await getMeetingAttendees(meetingId);
    final agendas = await getMeetingAgendas(meetingId);
    return CpoMeetingModel.fromMap(res.first, attendees: attendees, agendas: agendas);
  }

  Future<List<CpoAttendeeModel>> getMeetingAttendees(int meetingId) async {
    final db = await _dbHelper.database;
    final res = await db.query('cpo_meeting_attendees', where: 'meeting_id = ?', whereArgs: [meetingId]);
    return res.map((m) => CpoAttendeeModel.fromMap(m)).toList();
  }

  Future<List<CpoAgendaModel>> getMeetingAgendas(int meetingId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'cpo_meeting_agendas',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
      orderBy: 'agenda_no ASC',
    );
    return res.map((m) => CpoAgendaModel.fromMap(m)).toList();
  }

  Future<int> createMeetingWithStandardAgendas(CpoMeetingModel meeting, {List<CpoMemberModel>? termMembers}) async {
    final db = await _dbHelper.database;
    final meetingId = await db.insert('cpo_meetings', meeting.toMap());

    // 1. Seed 6 Standard Agendas
    for (final std in CpoStatutoryStandards.standardAgendas) {
      final agendaNo = std['agenda_no'] as int;
      final title = std['title'] as String;
      final defaultContent = std['default_content'] as String;

      await db.insert('cpo_meeting_agendas', {
        'meeting_id': meetingId,
        'agenda_no': agendaNo,
        'agenda_title': title,
        'discussion_content': defaultContent,
        'resolution_content': agendaNo == 1 || agendaNo == 4 ? 'รับทราบ' : (agendaNo == 2 ? 'รับรองรายงานการประชุม' : ''),
        'is_approved': 1,
        'sort_order': agendaNo,
      });
    }

    // 2. Populate attendees from term members if provided
    if (termMembers != null && termMembers.isNotEmpty) {
      for (final mem in termMembers) {
        await db.insert('cpo_meeting_attendees', {
          'meeting_id': meetingId,
          'employee_id': mem.employeeId,
          'attendee_name': mem.fullName,
          'role_label': mem.cpoRole.labelTh,
          'department': mem.department,
          'is_present': 1,
        });
      }
      await db.update(
        'cpo_meetings',
        {'total_invited': termMembers.length, 'total_attended': termMembers.length},
        where: 'id = ?',
        whereArgs: [meetingId],
      );
    }

    return meetingId;
  }

  Future<void> updateMeeting(CpoMeetingModel meeting) async {
    final db = await _dbHelper.database;
    await db.update('cpo_meetings', meeting.toMap(), where: 'id = ?', whereArgs: [meeting.id]);
  }

  Future<void> deleteMeeting(int meetingId) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_meetings', where: 'id = ?', whereArgs: [meetingId]);
  }

  Future<void> updateAgenda(CpoAgendaModel agenda) async {
    final db = await _dbHelper.database;
    await db.update('cpo_meeting_agendas', agenda.toMap(), where: 'id = ?', whereArgs: [agenda.id]);
  }

  Future<void> saveAttendee(CpoAttendeeModel attendee) async {
    final db = await _dbHelper.database;
    if (attendee.id != null) {
      await db.update('cpo_meeting_attendees', attendee.toMap(), where: 'id = ?', whereArgs: [attendee.id]);
    } else {
      await db.insert('cpo_meeting_attendees', attendee.toMap());
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. Action Items & Follow-up
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<CpoActionItemModel>> getAllActionItems({int? meetingId, String? status}) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (meetingId != null && status != null) {
      whereClause = 'meeting_id = ? AND status = ?';
      whereArgs = [meetingId, status];
    } else if (meetingId != null) {
      whereClause = 'meeting_id = ?';
      whereArgs = [meetingId];
    } else if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status];
    }

    final res = await db.query('cpo_action_items', where: whereClause, whereArgs: whereArgs, orderBy: 'id DESC');
    return res.map((m) => CpoActionItemModel.fromMap(m)).toList();
  }

  Future<int> saveActionItem(CpoActionItemModel item) async {
    final db = await _dbHelper.database;
    if (item.id != null) {
      await db.update('cpo_action_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
      return item.id!;
    } else {
      return await db.insert('cpo_action_items', item.toMap());
    }
  }

  Future<void> updateActionItemStatus(int id, String status, {int progress = 0, String? notes, String? completedDate}) async {
    final db = await _dbHelper.database;
    await db.update(
      'cpo_action_items',
      {
        'status': status,
        'progress_percent': progress,
        if (notes != null) 'resolution_notes': notes,
        if (completedDate != null) 'completed_date': completedDate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteActionItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_action_items', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. Distribution Logs
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<CpoDistributionModel>> getDistributionLogs([int? meetingId]) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'cpo_distribution_logs',
      where: meetingId != null ? 'meeting_id = ?' : null,
      whereArgs: meetingId != null ? [meetingId] : null,
      orderBy: 'id DESC',
    );
    return res.map((m) => CpoDistributionModel.fromMap(m)).toList();
  }

  Future<int> addDistributionLog(CpoDistributionModel log) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_distribution_logs', log.toMap());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. Cross-Module Data Pull & Next Meeting Agenda Roll-Forward
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> fetchMonthlySafetyStats(String monthDate) async {
    final db = await _dbHelper.database;

    int incidentCount = 0;
    int nearMissCount = 0;
    int ptwCount = 0;
    int openCapaCount = 0;

    try {
      final resEvents = await db.rawQuery(
        'SELECT event_type, COUNT(*) as cnt FROM safety_events GROUP BY event_type',
      );
      for (final r in resEvents) {
        final type = r['event_type']?.toString().toUpperCase() ?? '';
        final cnt = (r['cnt'] as num?)?.toInt() ?? 0;
        if (type.contains('NEAR')) {
          nearMissCount += cnt;
        } else {
          incidentCount += cnt;
        }
      }
    } catch (_) {}

    try {
      final resPtw = await db.rawQuery('SELECT COUNT(*) as cnt FROM ptw_permits');
      ptwCount = (resPtw.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final resCapa = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM cpo_action_items WHERE status = 'PENDING' OR status = 'IN_PROGRESS'",
      );
      openCapaCount = (resCapa.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    return {
      'incident_count': incidentCount,
      'near_miss_count': nearMissCount,
      'ptw_count': ptwCount,
      'open_capa_count': openCapaCount,
      'summary_text': 'สถิติประจำเดือน: อุบัติเหตุ $incidentCount ครั้ง, เหตุการณ์เกือบเกิดอุบัติเหตุ (Near Miss) $nearMissCount ครั้ง, ใบอนุญาตทำงานเสี่ยงสูง (PTW) $ptwCount ฉบับ, งานติดตามค้างอยู่ $openCapaCount รายการ',
    };
  }

  Future<String> getRolledForwardAgenda3Content(int? previousMeetingId) async {
    if (previousMeetingId == null) {
      return 'ไม่มีเรื่องสืบเนื่องจากการประชุมครั้งก่อนหน้า';
    }
    final db = await _dbHelper.database;
    final pendingItems = await db.query(
      'cpo_action_items',
      where: "meeting_id = ? AND (status = 'PENDING' OR status = 'IN_PROGRESS' OR status = 'OVERDUE')",
      whereArgs: [previousMeetingId],
    );

    if (pendingItems.isEmpty) {
      return 'มาตรการและงานที่ได้รับมอบหมายจากการประชุมครั้งก่อนหน้า ดำเนินการเสร็จสิ้นครบถ้วนทุกรายการ';
    }

    final buffer = StringBuffer('ติดตามความคืบหน้าเรื่องที่ได้รับมอบหมายจากการประชุมครั้งก่อนหน้า:\n');
    for (int i = 0; i < pendingItems.length; i++) {
      final item = CpoActionItemModel.fromMap(pendingItems[i]);
      buffer.writeln('${i + 1}. [${item.itemCode}] ${item.title}');
      buffer.writeln('   ผู้รับผิดชอบ: ${item.responsiblePerson} (กำหนดเสร็จ: ${item.dueDate})');
      buffer.writeln('   สถานะปัจจุบัน: ${item.status.labelTh} (คืบหน้า ${item.progressPercent}%)');
    }
    return buffer.toString();
  }
}
