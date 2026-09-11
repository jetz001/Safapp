import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import '../models/cpo_committee_model.dart';
import '../models/cpo_election_model.dart';
import '../models/cpo_meeting_model.dart';
import '../models/cpo_action_item_model.dart';
import '../models/cpo_distribution_model.dart';
import '../datasources/cpo_statutory_standards.dart';
import '../../domain/enums/cpo_action_status.dart';

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

  Future<void> deleteElection(int electionId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('cpo_election_candidates', where: 'election_id = ?', whereArgs: [electionId]);
      await txn.delete('cpo_election_officers', where: 'election_id = ?', whereArgs: [electionId]);
      await txn.delete('cpo_elections', where: 'id = ?', whereArgs: [electionId]);
    });
  }

  Future<int> addElectionOfficer(CpoElectionOfficerModel officer) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_election_officers', officer.toMap());
  }

  Future<void> updateElectionOfficer(CpoElectionOfficerModel officer) async {
    final db = await _dbHelper.database;
    await db.update('cpo_election_officers', officer.toMap(), where: 'id = ?', whereArgs: [officer.id]);
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

  Future<int> createMeetingWithStandardAgendas(CpoMeetingModel meeting, {List<CpoMemberModel>? termMembers, bool seedAgendas = true}) async {
    final db = await _dbHelper.database;
    final meetingId = await db.insert('cpo_meetings', meeting.toMap());

    // 1. Seed 6 Standard Agendas
    if (seedAgendas) {
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
    await db.delete('cpo_meeting_agendas', where: 'meeting_id = ?', whereArgs: [meetingId]);
    await db.delete('cpo_meeting_attendees', where: 'meeting_id = ?', whereArgs: [meetingId]);
    await db.delete('cpo_action_items', where: 'meeting_id = ?', whereArgs: [meetingId]);
  }

  Future<int> addAgenda(CpoAgendaModel agenda) async {
    final db = await _dbHelper.database;
    return await db.insert('cpo_meeting_agendas', agenda.toMap());
  }

  Future<void> deleteAgenda(int agendaId) async {
    final db = await _dbHelper.database;
    await db.delete('cpo_meeting_agendas', where: 'id = ?', whereArgs: [agendaId]);
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
        'resolution_notes': ?notes,
        'completed_date': ?completedDate,
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

  /// ดึง/แปลงมติและเรื่องย่อยจากวาระที่ ๔ และ ๕ สร้างเป็น Action Item อัตโนมัติ
  Future<int> syncActionItemsFromAgendas(int meetingId) async {
    final db = await _dbHelper.database;
    // 1. Fetch meeting
    final meetingMaps = await db.query('cpo_meetings', where: 'id = ?', whereArgs: [meetingId]);
    if (meetingMaps.isEmpty) return 0;
    final meetingMap = meetingMaps.first;
    final meetingYear = meetingMap['meeting_year']?.toString() ?? '${DateTime.now().year + 543}';
    final meetingNo = (meetingMap['meeting_no'] as num?)?.toInt() ?? 1;
    final meetingDate = meetingMap['meeting_date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10);

    // 2. Fetch agendas 4 and 5 for this meeting
    final agendaMaps = await db.query(
      'cpo_meeting_agendas',
      where: 'meeting_id = ? AND agenda_no IN (4, 5)',
      whereArgs: [meetingId],
      orderBy: 'agenda_no ASC',
    );

    // 3. Fetch existing action items for this meeting to prevent duplicates
    final existingActions = await getAllActionItems(meetingId: meetingId);
    final existingTitles = existingActions.map((a) => a.title.trim().toLowerCase()).toSet();
    final existingCodes = existingActions.map((a) => a.itemCode.trim().toLowerCase()).toSet();

    int createdCount = 0;
    final parsedMeetingDate = DateTime.tryParse(meetingDate) ?? DateTime.now();
    final defaultDue = parsedMeetingDate.add(const Duration(days: 30)).toIso8601String().substring(0, 10);

    for (final agMap in agendaMaps) {
      final agendaId = agMap['id'] as int?;
      final agendaNo = (agMap['agenda_no'] as num?)?.toInt() ?? 5;
      final agendaTitle = agMap['agenda_title']?.toString() ?? '';
      final disc = agMap['discussion_content']?.toString() ?? '';
      final res = agMap['resolution_content']?.toString() ?? '';
      final presenter = agMap['presenter_name']?.toString() ?? '';

      final subTopics = _extractSubTopicsForSync(disc, res, presenter, agendaNo);

      for (int i = 0; i < subTopics.length; i++) {
        final st = subTopics[i];
        final subNo = st['sub_no']?.isNotEmpty == true ? st['sub_no']! : '$agendaNo.${i + 1}';
        final rawTitle = st['title']?.trim() ?? '';
        final taskTitle = rawTitle.isNotEmpty
            ? '$subNo $rawTitle'
            : '$subNo $agendaTitle';

        final itemCode = 'ACT-$meetingYear-$meetingNo-${agendaNo}_${i + 1}';

        // Avoid duplication
        if (existingCodes.contains(itemCode.toLowerCase()) ||
            existingTitles.contains(taskTitle.toLowerCase()) ||
            (rawTitle.isNotEmpty && existingTitles.contains(rawTitle.toLowerCase()))) {
          continue;
        }

        final discussion = st['discussion']?.trim() ?? '';
        final resolution = st['resolution']?.trim() ?? '';
        final pic = (st['presenter']?.trim().isNotEmpty == true)
            ? st['presenter']!.trim()
            : 'คณะกรรมการ คปอ.';

        if (discussion.isEmpty && resolution.isEmpty && rawTitle.isEmpty) {
          continue;
        }

        final actionDetail = StringBuffer();
        if (discussion.isNotEmpty) {
          actionDetail.writeln(discussion);
        }
        if (resolution.isNotEmpty) {
          if (actionDetail.isNotEmpty) actionDetail.writeln('\n');
          actionDetail.write('มติที่ประชุม: $resolution');
        } else {
          if (actionDetail.isNotEmpty) actionDetail.writeln('\n');
          actionDetail.write('มติที่ประชุม: รับทราบและติดตามผลการดำเนินงาน');
        }

        final priority = (discussion.contains('อันตราย') ||
                discussion.contains('อุบัติเหตุ') ||
                resolution.contains('เร่งด่วน') ||
                resolution.contains('อนุมัติ'))
            ? 'HIGH'
            : 'MEDIUM';

        final images = st['images'] as List<String>? ?? [];

        final item = CpoActionItemModel(
          itemCode: itemCode,
          meetingId: meetingId,
          agendaId: agendaId,
          agendaNo: agendaNo,
          title: taskTitle,
          actionDetail: actionDetail.toString(),
          responsiblePerson: pic,
          dueDate: defaultDue,
          priority: priority,
          status: CpoActionStatus.pending,
          evidencePhotoPath: images.isNotEmpty ? images.first : null,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await saveActionItem(item);
        existingTitles.add(taskTitle.toLowerCase());
        existingCodes.add(itemCode.toLowerCase());
        createdCount++;
      }
    }
    return createdCount;
  }

  List<Map<String, dynamic>> _extractSubTopicsForSync(
    String disc,
    String res,
    String defaultPresenter,
    int agendaNo,
  ) {
    final match = RegExp(r'<!--SUB_ITEMS_JSON:(.*?)-->', dotAll: true).firstMatch(disc);
    if (match != null) {
      try {
        final jsonString = match.group(1)!;
        final List<dynamic> list = jsonDecode(jsonString);
        if (list.isNotEmpty) {
          return list.map((item) {
            final m = item as Map<String, dynamic>;
            final rawImages = m['images'];
            final List<String> imgs = [];
            if (rawImages is List) {
              for (final img in rawImages) {
                if (img != null && img.toString().isNotEmpty) {
                  imgs.add(img.toString());
                }
              }
            }
            return {
              'sub_no': m['sub_no']?.toString() ?? '',
              'title': m['title']?.toString() ?? '',
              'discussion': m['discussion']?.toString() ?? '',
              'resolution': m['resolution']?.toString() ?? '',
              'presenter': m['presenter']?.toString() ?? defaultPresenter,
              'images': imgs,
            };
          }).toList();
        }
      } catch (_) {}
    }

    final cleanDisc = disc.replaceAll(RegExp(r'<!--SUB_ITEMS_JSON:[\s\S]*?-->'), '').trim();
    if (cleanDisc.isEmpty && res.isEmpty) return [];

    return [
      {
        'sub_no': '$agendaNo.1',
        'title': '',
        'discussion': cleanDisc,
        'resolution': res,
        'presenter': defaultPresenter,
        'images': <String>[],
      }
    ];
  }

  Future<int> syncActionItemsFromAllMeetings({int? specificMeetingId}) async {
    final db = await _dbHelper.database;
    List<int> meetingIds = [];
    if (specificMeetingId != null) {
      meetingIds = [specificMeetingId];
    } else {
      final meetings = await db.query('cpo_meetings', orderBy: 'id DESC');
      meetingIds = meetings.map((m) => (m['id'] as num).toInt()).toList();
    }

    int totalSynced = 0;
    for (final mId in meetingIds) {
      totalSynced += await syncActionItemsFromAgendas(mId);
    }
    return totalSynced;
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
