import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../../safety_manual/data/models/factory_scope_model.dart';
import '../../domain/models/audit_models.dart';
import '../datasources/audit_master_checklist_data.dart';

class AuditRepository {
  final DatabaseHelper _dbHelper;

  AuditRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // =========================================================================
  // SESSIONS
  // =========================================================================

  Future<List<AuditSession>> getAllSessions() async {
    final db = await _db;
    final maps = await db.query('audit_sessions', orderBy: 'id DESC');
    if (maps.isEmpty) {
      await seedInitialAuditSession();
      final freshMaps = await db.query('audit_sessions', orderBy: 'id DESC');
      return freshMaps.map((m) => AuditSession.fromMap(m)).toList();
    }
    return maps.map((m) => AuditSession.fromMap(m)).toList();
  }

  Future<AuditSession?> getSessionById(int id) async {
    final db = await _db;
    final maps = await db.query('audit_sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return AuditSession.fromMap(maps.first);
  }

  Future<AuditSession> createSession({
    required String title,
    required String leadAuditor,
    String? auditorTeam,
    required String scope, // 'SMS_2565' or 'INTEGRATED'
    FactoryScopeModel? factoryScope,
    String? auditDate,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final dateStr = auditDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Generate Audit No
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM audit_sessions');
    final nextSeq = (countRes.first['cnt'] as int? ?? 0) + 1;
    final auditNo = 'AUD-${now.year}-${nextSeq.toString().padLeft(3, '0')}';

    // Fetch cross-module evidence for auto-filling
    final evidence = await fetchCrossModuleEvidence();

    // Insert Session
    final sessionMap = {
      'audit_no': auditNo,
      'audit_title': title,
      'audit_date': dateStr,
      'lead_auditor': leadAuditor,
      'auditor_team': auditorTeam,
      'audit_scope': scope,
      'status': 'IN_PROGRESS',
      'total_items': 0,
      'conform_count': 0,
      'minor_nc_count': 0,
      'major_nc_count': 0,
      'na_count': 0,
      'compliance_percentage': 0.0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final sessionId = await db.insert('audit_sessions', sessionMap);

    // Determine which templates to include
    final templatesToInclude = <AuditMasterItemTemplate>[];
    for (final t in AuditMasterChecklistData.masterTemplates) {
      if (t.scopeFlag == 'CORE') {
        templatesToInclude.add(t);
      } else if (scope == 'INTEGRATED') {
        final scopeCfg = factoryScope ?? const FactoryScopeModel();
        bool include = false;
        switch (t.scopeFlag) {
          case 'BOILER':
            include = scopeCfg.hasBoiler;
            break;
          case 'CRANE':
            include = scopeCfg.hasCrane;
            break;
          case 'CHEMICAL':
            include = scopeCfg.hasChemical;
            break;
          case 'CONFINED_SPACE':
            include = scopeCfg.hasConfinedSpace;
            break;
          case 'ELECTRICAL_LOTO':
            include = scopeCfg.hasElectricalLoto;
            break;
          case 'EMERGENCY_FIRE':
            include = scopeCfg.hasEmergencyFire;
            break;
          case 'PPE':
            include = scopeCfg.hasPpe;
            break;
          default:
            include = true;
        }
        if (include) templatesToInclude.add(t);
      }
    }

    // Insert items in batch
    final batch = db.batch();
    for (var i = 0; i < templatesToInclude.length; i++) {
      final t = templatesToInclude[i];
      String? evidenceText;

      // Smart auto-evidence matching
      switch (t.sourceModule) {
        case 'ELECTRICAL':
          if (evidence.electricalInspectionCount > 0) {
            evidenceText = '⚡ พบประวัติการตรวจรับรองไฟฟ้า ${evidence.electricalInspectionCount} รายการ (สถานะ: มีบันทึกในระบบ)';
          }
          break;
        case 'MACHINERY':
          if (t.scopeFlag == 'CRANE' && evidence.craneInspectionCount > 0) {
            evidenceText = '🏗️ พบทะเบียนปั้นจั่น/ตรวจรับรอง ${evidence.craneInspectionCount} รายการ (ปจ.๑/ปจ.๒)';
          } else if (t.scopeFlag == 'BOILER' && evidence.boilerInspectionCount > 0) {
            evidenceText = '🔥 พบทะเบียนหม้อน้ำ/ตรวจทดสอบ ${evidence.boilerInspectionCount} รายการ';
          }
          break;
        case 'CHEMICALS':
          if (evidence.chemicalCount > 0) {
            evidenceText = '🧪 พบบัญชีสารเคมีอันตรายและ SDS ${evidence.chemicalCount} รายการ';
          }
          break;
        case 'ENVIRONMENT':
          if (evidence.environmentSurveyCount > 0) {
            evidenceText = '🌡️ พบประวัติการตรวจวัดสภาพแวดล้อม (แสง/เสียง/ความร้อน) ${evidence.environmentSurveyCount} รายการ';
          }
          break;
        case 'PTW':
          if (evidence.ptwActiveCount > 0) {
            evidenceText = '📋 พบใบอนุญาตทำงานเสี่ยงสูง (PTW) ในระบบ ${evidence.ptwActiveCount} ฉบับ';
          }
          break;
        case 'EMERGENCY':
          if (evidence.emergencyPlanCount > 0) {
            evidenceText = '🚒 พบแผนระงับเหตุฉุกเฉิน ERP / บันทึกซ้อมดับเพลิง (สปร.๔) ในระบบ';
          }
          break;
        case 'NEAR_MISS':
          if (evidence.incidentCount > 0) {
            evidenceText = '🛡️ พบรายงานเหตุการณ์และการสอบสวนอุบัติเหตุ ${evidence.incidentCount} เคส';
          }
          break;
        case 'EMPLOYEE_CPO':
          if (evidence.cpoMeetingCount > 0) {
            evidenceText = '👥 พบประวัติการประชุม คปอ. ประจำเดือน ${evidence.cpoMeetingCount} ครั้ง';
          }
          break;
        case 'PPE_ASL':
          if (evidence.ppeItemCount > 0) {
            evidenceText = '🦺 พบคลังรายการ PPE และบัญชีผู้ขาย ASL ${evidence.ppeItemCount} รายการ';
          }
          break;
      }

      batch.insert('audit_checklist_items', {
        'audit_session_id': sessionId,
        'category_code': t.categoryCode,
        'category_title': t.categoryTitle,
        'clause_no': t.clauseNo,
        'item_title': t.itemTitle,
        'requirement_description': t.requirementDescription,
        'legal_reference': t.legalReference,
        'source_module': t.sourceModule,
        'evidence_summary': evidenceText,
        'result_status': 'UNAUDITED',
        'sort_order': i + 1,
      });
    }

    await batch.commit(noResult: true);

    // Update total items count
    await db.update(
      'audit_sessions',
      {'total_items': templatesToInclude.length},
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return (await getSessionById(sessionId))!;
  }

  Future<void> deleteSession(int id) async {
    final db = await _db;
    await db.delete('audit_findings_capa', where: 'audit_session_id = ?', whereArgs: [id]);
    await db.delete('audit_checklist_items', where: 'audit_session_id = ?', whereArgs: [id]);
    await db.delete('audit_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================================
  // CHECKLIST ITEMS
  // =========================================================================

  Future<List<AuditChecklistItem>> getChecklistItems(int sessionId) async {
    final db = await _db;
    final maps = await db.query(
      'audit_checklist_items',
      where: 'audit_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => AuditChecklistItem.fromMap(m)).toList();
  }

  Future<void> updateChecklistItem(AuditChecklistItem item) async {
    final db = await _db;
    await db.update(
      'audit_checklist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Recalculate session compliance stats
    await _recalculateSessionStats(item.auditSessionId);
  }

  Future<void> _recalculateSessionStats(int sessionId) async {
    final db = await _db;
    final items = await getChecklistItems(sessionId);
    
    int conform = 0;
    int minorNc = 0;
    int majorNc = 0;
    int na = 0;

    for (final it in items) {
      switch (it.resultStatus) {
        case 'CONFORM':
          conform++;
          break;
        case 'MINOR_NC':
          minorNc++;
          break;
        case 'MAJOR_NC':
          majorNc++;
          break;
        case 'NA':
          na++;
          break;
      }
    }

    final auditableCount = items.length - na;
    final double compliancePercentage = auditableCount > 0
        ? ((conform / auditableCount) * 100.0)
        : 0.0;

    final isAllAudited = items.every((i) => i.resultStatus != 'UNAUDITED');
    final status = isAllAudited ? 'COMPLETED' : 'IN_PROGRESS';

    await db.update(
      'audit_sessions',
      {
        'conform_count': conform,
        'minor_nc_count': minorNc,
        'major_nc_count': majorNc,
        'na_count': na,
        'compliance_percentage': double.parse(compliancePercentage.toStringAsFixed(1)),
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // =========================================================================
  // CAR / CAPA FINDINGS
  // =========================================================================

  Future<List<AuditFindingCapa>> getFindings(int sessionId) async {
    final db = await _db;
    final maps = await db.query(
      'audit_findings_capa',
      where: 'audit_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id DESC',
    );
    return maps.map((m) => AuditFindingCapa.fromMap(m)).toList();
  }

  Future<List<AuditFindingCapa>> getAllFindings() async {
    final db = await _db;
    final maps = await db.query('audit_findings_capa', orderBy: 'id DESC');
    return maps.map((m) => AuditFindingCapa.fromMap(m)).toList();
  }

  Future<void> saveFinding(AuditFindingCapa finding) async {
    final db = await _db;
    if (finding.id == null) {
      // Auto-generate Finding No if empty
      String fNo = finding.findingNo;
      if (fNo.isEmpty) {
        final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM audit_findings_capa');
        final nextSeq = (countRes.first['cnt'] as int? ?? 0) + 1;
        fNo = 'CAR-${DateTime.now().year}-${nextSeq.toString().padLeft(3, '0')}';
      }
      final map = finding.copyWith(findingNo: fNo, createdAt: DateTime.now().toIso8601String()).toMap();
      await db.insert('audit_findings_capa', map);
    } else {
      await db.update(
        'audit_findings_capa',
        finding.toMap(),
        where: 'id = ?',
        whereArgs: [finding.id],
      );
    }
  }

  Future<void> deleteFinding(int id) async {
    final db = await _db;
    await db.delete('audit_findings_capa', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================================
  // KPI STATS
  // =========================================================================

  Future<AuditKpiStats> getKpiStats() async {
    final sessions = await getAllSessions();
    final findings = await getAllFindings();

    final totalSessions = sessions.length;
    final completedSessions = sessions.where((s) => s.isCompleted).length;
    final activeSessions = sessions.where((s) => !s.isCompleted).length;

    double avgRate = 0.0;
    if (sessions.isNotEmpty) {
      final totalPct = sessions.fold<double>(0.0, (sum, s) => sum + s.compliancePercentage);
      avgRate = double.parse((totalPct / sessions.length).toStringAsFixed(1));
    }

    final totalConform = sessions.fold<int>(0, (sum, s) => sum + s.conformCount);
    final totalMinorNc = sessions.fold<int>(0, (sum, s) => sum + s.minorNcCount);
    final totalMajorNc = sessions.fold<int>(0, (sum, s) => sum + s.majorNcCount);

    final openCapa = findings.where((f) => f.status != 'CLOSED').length;
    final closedCapa = findings.where((f) => f.status == 'CLOSED').length;

    return AuditKpiStats(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      activeSessions: activeSessions,
      averageComplianceRate: avgRate,
      totalConform: totalConform,
      totalMinorNc: totalMinorNc,
      totalMajorNc: totalMajorNc,
      totalOpenCapa: openCapa,
      totalClosedCapa: closedCapa,
    );
  }

  // =========================================================================
  // CROSS-MODULE EVIDENCE ENGINE
  // =========================================================================

  Future<CrossModuleEvidenceSummary> fetchCrossModuleEvidence() async {
    final db = await _db;
    int elecCount = 0;
    int craneCount = 0;
    int boilerCount = 0;
    int chemCount = 0;
    int ptwCount = 0;
    int envCount = 0;
    int erpCount = 0;
    int incCount = 0;
    int cpoCount = 0;
    int ppeCount = 0;

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM electrical_inspections');
      elecCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM crane_inspections');
      craneCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM boiler_inspections');
      boilerCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM chemicals');
      chemCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM ptw_permits');
      ptwCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM environmental_sessions');
      envCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM emergency_plans');
      erpCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM accident_investigations');
      incCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM cpo_meetings');
      cpoCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    try {
      final r = await db.rawQuery('SELECT COUNT(*) as cnt FROM ppe_items');
      ppeCount = r.isNotEmpty ? (r.first['cnt'] as int? ?? 0) : 0;
    } catch (_) {}

    return CrossModuleEvidenceSummary(
      electricalInspectionCount: elecCount,
      hasRecentElectricalCert: elecCount > 0,
      craneInspectionCount: craneCount,
      boilerInspectionCount: boilerCount,
      chemicalCount: chemCount,
      ptwActiveCount: ptwCount,
      environmentSurveyCount: envCount,
      emergencyPlanCount: erpCount,
      incidentCount: incCount,
      cpoMeetingCount: cpoCount,
      ppeItemCount: ppeCount,
    );
  }

  // =========================================================================
  // INITIAL SEEDING (REAL STATUTORY DATA)
  // =========================================================================

  Future<void> seedInitialAuditSession() async {
    final db = await _db;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final sessionMap = {
      'audit_no': 'AUD-2026-001',
      'audit_title': 'ตรวจประเมินระบบการจัดการความปลอดภัยประจำปี ๒๕๖๙ (SMS Audit 2565)',
      'audit_date': dateStr,
      'lead_auditor': 'นางสาวพัชราภรณ์ สุขสวัสดิ์ (จป.วิชาชีพ)',
      'auditor_team': 'คณะกรรมการ คปอ. และทีมผู้ตรวจประเมินภายใน',
      'audit_scope': 'INTEGRATED',
      'status': 'IN_PROGRESS',
      'total_items': AuditMasterChecklistData.masterTemplates.length,
      'conform_count': 0,
      'minor_nc_count': 0,
      'major_nc_count': 0,
      'na_count': 0,
      'compliance_percentage': 0.0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final sessionId = await db.insert('audit_sessions', sessionMap);
    final templates = AuditMasterChecklistData.masterTemplates;

    int? envItemId;
    int? craneItemId;

    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      String status = 'CONFORM';
      double score = 5.0;
      String? finding;

      if (t.sourceModule == 'ENVIRONMENT') {
        status = 'MINOR_NC';
        score = 2.0;
        finding = 'จุดปฏิบัติงานแผนก Pressing Line 2 ระดับเสียงเฉลี่ย 86.5 dBA เกินมาตรฐาน 85 dBA ยังไม่ได้ติดป้ายเตือนและจัดทำโครงการอนุรักษ์การได้ยิน (HCP) ให้ครบถ้วน';
      } else if (t.scopeFlag == 'CRANE') {
        status = 'MINOR_NC';
        score = 2.0;
        finding = 'ปั้นจั่นเหนือศีรษะ 5 ตัน แผนกคลังสินค้า ครบรอบทดสอบโหลด ปจ.๑ สิ้นเดือนนี้ อยู่ระหว่างประสานงานสามัญวิศวกร';
      } else {
        finding = 'มีเอกสาร ขั้นตอนปฏิบัติ และการดำเนินการสอดคล้องตามกฎหมายครบถ้วน';
      }

      final itemId = await db.insert('audit_checklist_items', {
        'audit_session_id': sessionId,
        'category_code': t.categoryCode,
        'category_title': t.categoryTitle,
        'clause_no': t.clauseNo,
        'item_title': t.itemTitle,
        'requirement_description': t.requirementDescription,
        'legal_reference': t.legalReference,
        'source_module': t.sourceModule,
        'evidence_summary': 'ตรวจสอบเอกสารและสังเกตการณ์หน้างานจริง',
        'result_status': status,
        'compliance_score': score,
        'finding_notes': finding,
        'sort_order': i + 1,
      });

      if (t.sourceModule == 'ENVIRONMENT') {
        envItemId = itemId;
      } else if (t.scopeFlag == 'CRANE') {
        craneItemId = itemId;
      }
    }

    await _recalculateSessionStats(sessionId);

    // Insert 2 realistic CAR items
    if (envItemId != null) {
      await db.insert('audit_findings_capa', {
        'audit_session_id': sessionId,
        'checklist_item_id': envItemId,
        'car_no': 'CAR-2026-001',
        'finding_details': 'จุดปฏิบัติงานแผนก Pressing Line 2 ระดับเสียงเฉลี่ย 86.5 dBA เกินค่ามาตรฐาน 85 dBA ยังไม่ได้ติดป้ายเตือนและกำหนดมาตรการอนุรักษ์การได้ยินให้ครบถ้วน',
        'severity': 'MINOR_NC',
        'root_cause': 'การปรับเพิ่มกำลังการผลิตทำให้เสียงเครื่องปั๊มชิ้นส่วนดังขึ้น แต่ยังไม่ได้ทบทวนการประเมินสิ่งแวดล้อมและการจัดโซนควบคุม',
        'corrective_action': 'จัดทำโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program), ติดตั้งป้ายเตือนสวมใส่ PPE ลดเสียง (Ear Plug/Muff) และแจกจ่ายอุปกรณ์ป้องกัน',
        'preventive_action': 'กำหนดรอบตรวจวัดระดับเสียงทุก 6 เดือน และบำรุงรักษาเครื่องจักรลดการสั่นสะเทือน',
        'responsible_person': 'นายวิศวกร ซ่อมบำรุง / จป.วิชาชีพ',
        'target_date': '${now.year}-${(now.month == 12 ? 1 : now.month + 1).toString().padLeft(2, '0')}-15',
        'status': 'IN_PROGRESS',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }

    if (craneItemId != null) {
      await db.insert('audit_findings_capa', {
        'audit_session_id': sessionId,
        'checklist_item_id': craneItemId,
        'car_no': 'CAR-2026-002',
        'finding_details': 'ปั้นจั่นเหนือศีรษะ (Overhead Crane 5 Ton) แผนกคลังสินค้า ครบรอบการตรวจสอบและทดสอบประจำปี (แบบ ปจ.๑)',
        'severity': 'MINOR_NC',
        'root_cause': 'อยู่ระหว่างรอคิวเข้าตรวจของสามัญวิศวกรเครื่องกล',
        'corrective_action': 'นัดหมายสามัญวิศวกรเครื่องกลเพื่อทำการทดสอบพิกัดการยก (Load Test) และออกใบรับรอง แบบ ปจ.๑',
        'preventive_action': 'จัดทำตารางแจ้งเตือนล่วงหน้า 60 วันในระบบ Safapp Asset Master',
        'responsible_person': 'หัวหน้าแผนกคลังสินค้าและซ่อมบำรุง',
        'target_date': '${now.year}-${(now.month == 12 ? 1 : now.month + 1).toString().padLeft(2, '0')}-05',
        'status': 'OPEN',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }
}
