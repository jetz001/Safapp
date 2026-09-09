import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/accident_models.dart';

class AccidentRepository {
  final DatabaseHelper _dbHelper;

  AccidentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // File Persistence (Photos & Evidence)
  // --------------------------------------------------------------------------
  Future<String?> persistFile(String sourcePath, {String prefix = 'accident_doc'}) async {
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return sourcePath;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'accident_evidence'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetFile = File(p.join(targetDir.path, filename));

      await srcFile.copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      return sourcePath;
    }
  }

  // --------------------------------------------------------------------------
  // Accident Investigations
  // --------------------------------------------------------------------------
  Future<List<AccidentInvestigation>> getAllInvestigations() async {
    final db = await _dbHelper.database;
    var res = await db.rawQuery('''
      SELECT ai.*,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id) as capa_count,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id AND aca.status = 'COMPLETED') as completed_capa_count
      FROM accident_investigations ai
      ORDER BY ai.incident_date DESC, ai.id DESC
    ''');
    if (res.isEmpty) {
      await seedInitialNearMiss();
      res = await db.rawQuery('''
        SELECT ai.*,
          (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id) as capa_count,
          (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id AND aca.status = 'COMPLETED') as completed_capa_count
        FROM accident_investigations ai
        ORDER BY ai.incident_date DESC, ai.id DESC
      ''');
    }
    return res.map((m) => AccidentInvestigation.fromMap(m)).toList();
  }

  Future<AccidentInvestigation?> getInvestigationById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT ai.*,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id) as capa_count,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id AND aca.status = 'COMPLETED') as completed_capa_count
      FROM accident_investigations ai
      WHERE ai.id = ?
    ''', [id]);
    if (res.isEmpty) return null;
    return AccidentInvestigation.fromMap(res.first);
  }

  Future<int> saveInvestigation(AccidentInvestigation investigation, {List<String>? newPhotos}) async {
    final db = await _dbHelper.database;
    List<String> finalPhotos = List.from(investigation.photoPaths);

    if (newPhotos != null && newPhotos.isNotEmpty) {
      for (final pth in newPhotos) {
        if (!finalPhotos.contains(pth)) {
          final saved = await persistFile(pth, prefix: 'incident_photo');
          if (saved != null) finalPhotos.add(saved);
        }
      }
    }

    final toSave = investigation.copyWith(photoPaths: finalPhotos);
    final map = toSave.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();

    if (toSave.id != null) {
      await db.update('accident_investigations', map, where: 'id = ?', whereArgs: [toSave.id]);
      return toSave.id!;
    } else {
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('accident_investigations', map);
    }
  }

  Future<void> deleteInvestigation(int id) async {
    final db = await _dbHelper.database;
    await db.delete('accident_investigations', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // CAPA Actions
  // --------------------------------------------------------------------------
  Future<List<AccidentCapaAction>> getActionsByInvestigationId(int investigationId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'accident_capa_actions',
      where: 'investigation_id = ?',
      whereArgs: [investigationId],
      orderBy: 'target_date ASC',
    );
    return res.map((m) => AccidentCapaAction.fromMap(m)).toList();
  }

  Future<List<AccidentCapaAction>> getAllActions() async {
    final db = await _dbHelper.database;
    final res = await db.query('accident_capa_actions', orderBy: 'target_date ASC');
    return res.map((m) => AccidentCapaAction.fromMap(m)).toList();
  }

  Future<int> saveAction(AccidentCapaAction action, {String? newEvidencePhoto}) async {
    final db = await _dbHelper.database;
    String? finalEvidence = action.evidencePhotoPath;
    if (newEvidencePhoto != null) {
      finalEvidence = await persistFile(newEvidencePhoto, prefix: 'capa_evidence');
    }

    final toSave = action.copyWith(evidencePhotoPath: finalEvidence);
    final map = toSave.toMap();

    if (toSave.id != null) {
      await db.update('accident_capa_actions', map, where: 'id = ?', whereArgs: [toSave.id]);
      return toSave.id!;
    } else {
      return await db.insert('accident_capa_actions', map);
    }
  }

  Future<void> deleteAction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('accident_capa_actions', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // INITIAL SEEDING (REAL STATUTORY DATA)
  // --------------------------------------------------------------------------
  Future<void> seedInitialNearMiss() async {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final dateStr = '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';

    final incident = AccidentInvestigation(
      eventNo: 'NM-2026-001',
      eventType: 'NEAR_MISS',
      incidentTitle: 'สะเก็ดไฟจากการเจียรโครงเหล็กกระเด็นใกล้ถังทินเนอร์ (เกือบเกิดเพลิงไหม้)',
      incidentDate: dateStr,
      incidentTime: '14:30',
      incidentLocation: 'โรงประกอบเชื่อม 2 (Fabrication Workshop 2)',
      employeeType: 'EMPLOYEE',
      injuredPersonName: 'นายอนุชา ขยันงาน',
      injuredPersonPosition: 'ช่างเชื่อมประกอบ',
      injuredPersonDepartment: 'ฝ่ายซ่อมบำรุงและโครงสร้าง',
      daysLost: 0,
      medicalExpense: 0.0,
      propertyDamageCost: 0.0,
      machineInvolved: 'เครื่องเจียรมือถือ 4 นิ้ว (Angle Grinder)',
      chemicalInvolved: 'ทินเนอร์ผสมสี (Thinner Solvent)',
      workProcessInvolved: 'งานเจียรตกแต่งแนวเชื่อมโครงสร้างเหล็กรองรับสายพานลำเลียง',
      description5w1h: 'ขณะช่างซ่อมบำรุงทำการเจียรแต่งแนวเชื่อมโครงเหล็ก สะเก็ดไฟเกิดกระเด็นข้ามไปตกใกล้ถังทินเนอร์ล้างสีซึ่งเปิดฝาทิ้งไว้ เคราะห์ดีที่เพื่อนร่วมงานเห็นจึงรีบใช้ผ้าชุบน้ำเข้าคลุมและปิดฝาถังได้ทันท่วงที ไม่มีผู้ได้รับบาดเจ็บหรือทรัพย์สินเสียหาย',
      timelineEvents: [
        AccidentTimelineItem(time: '14:15', action: 'เปิดถังทินเนอร์เพื่อล้างแปรงทาสี แล้วลืมปิดฝากลับคืน'),
        AccidentTimelineItem(time: '14:28', action: 'เริ่มใช้เครื่องเจียรแต่งแนวเชื่อมโดยไม่ได้กางฉากกั้นสะเก็ดไฟ'),
        AccidentTimelineItem(time: '14:30', action: 'สะเก็ดไฟพุ่งเข้าหาถังทินเนอร์ เพื่อนร่วมงานตะโกนเตือนและเข้าดับสะเก็ดไฟทันที'),
      ],
      unsafeActs: [
        'ทำงานก่อประกายไฟโดยไม่ตรวจสอบและเคลื่อนย้ายสารเคมีไวไฟในรัศมี 10 เมตร',
        'เปิดฝาถังสารเคมีไวไฟทิ้งไว้หลังเสร็จสิ้นการใช้งาน',
      ],
      unsafeConditions: [
        'ไม่มีฉากกั้นสะเก็ดไฟ (Welding / Grinding Fire Blanket Screen)',
        'ไม่มีถังดับเพลิงมือถือประจำจุดงานร้อนในระยะ 5 เมตร',
      ],
      managementErrors: [
        'การตรวจสอบหน้างานก่อนเริ่มงานร้อน (Hot Work Pre-check) ยังไม่รัดกุม',
      ],
      rootCauseSummary: 'ขาดการตัดแยกสารเคมีไวไฟก่อนปฏิบัติงานเจียรประกายไฟ และขาดอุปกรณ์กั้นสะเก็ดไฟประจำจุด',
      applicableLaws: [
        'พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ มาตรา ๑๔',
        'กฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัยฯ เกี่ยวกับอัคคีภัย พ.ศ. ๒๕๕๕',
      ],
      inspectorName: 'นางสาวพัชราภรณ์ สุขสวัสดิ์',
      inspectorPosition: 'จป.วิชาชีพ',
      employerAcknowledgedDate: dateStr,
      status: 'INVESTIGATING',
    );

    final id = await saveInvestigation(incident);

    // Seed 2 CAPA actions
    final capa1 = AccidentCapaAction(
      investigationId: id,
      controlHierarchy: 'ENGINEERING',
      actionDescription: 'ติดตั้งฉากกันสะเก็ดไฟ (Fire Blanket) และเคลื่อนย้ายถังทินเนอร์เข้าตู้เก็บสารเคมีนิรภัย (Safety Flammable Cabinet)',
      responsiblePerson: 'นายช่างซ่อมบำรุง / หัวหน้างานโครงสร้าง',
      targetDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      status: 'COMPLETED',
      completedDate: dateStr,
      notes: 'จัดเก็บสารไวไฟเข้าตู้ Safety Cabinet เรียบร้อย และนำฉากกั้นสะเก็ดไฟมาประจำจุดแล้ว',
    );
    await saveAction(capa1);

    final capa2 = AccidentCapaAction(
      investigationId: id,
      controlHierarchy: 'ADMINISTRATIVE',
      actionDescription: 'จัด Safety Talk ทบทวนกฎระเบียบงานร้อน (Hot Work) และตรวจสอบพื้นที่ก่อนปฏิบัติงานทุกเช้า',
      responsiblePerson: 'นางสาวพัชราภรณ์ สุขสวัสดิ์ (จป.วิชาชีพ)',
      targetDate: '${now.year}-${(now.month == 12 ? 1 : now.month + 1).toString().padLeft(2, '0')}-10',
      status: 'IN_PROGRESS',
    );
    await saveAction(capa2);
  }
}
