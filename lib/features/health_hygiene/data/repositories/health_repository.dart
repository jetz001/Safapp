import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/health_models.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;

  HealthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // File Persistence (Individual & Bulk PDF Reports)
  // --------------------------------------------------------------------------
  Future<String?> persistPdfFile(String sourcePath, {String prefix = 'health_doc'}) async {
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return sourcePath;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'health_reports'));
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
  // Individual Health Records
  // --------------------------------------------------------------------------
  Future<List<EmployeeHealthRecord>> getAllHealthRecords({int? employeeId}) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT ehr.*,
        e.employee_code, e.full_name, e.department, e.position, e.national_id, e.photo_path
      FROM employee_health_records ehr
      INNER JOIN employees e ON ehr.employee_id = e.id
    ''';
    List<dynamic> args = [];
    if (employeeId != null) {
      sql += ' WHERE ehr.employee_id = ?';
      args.add(employeeId);
    }
    sql += ' ORDER BY ehr.checkup_date DESC, ehr.id DESC';

    final res = await db.rawQuery(sql, args);
    return res.map((m) => EmployeeHealthRecord.fromMap(m)).toList();
  }

  Future<EmployeeHealthRecord?> getHealthRecordById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT ehr.*,
        e.employee_code, e.full_name, e.department, e.position, e.national_id, e.photo_path
      FROM employee_health_records ehr
      INNER JOIN employees e ON ehr.employee_id = e.id
      WHERE ehr.id = ?
    ''', [id]);
    if (res.isEmpty) return null;
    return EmployeeHealthRecord.fromMap(res.first);
  }

  Future<int> saveHealthRecord(EmployeeHealthRecord record, {String? newPdfPath}) async {
    final db = await _dbHelper.database;
    String? finalPdf = record.pdfFilePath;
    if (newPdfPath != null && newPdfPath.isNotEmpty) {
      finalPdf = await persistPdfFile(newPdfPath, prefix: 'emp_health_${record.employeeId}');
    }

    final toSave = record.copyWith(pdfFilePath: finalPdf);
    final map = toSave.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();

    if (toSave.id != null) {
      await db.update('employee_health_records', map, where: 'id = ?', whereArgs: [toSave.id]);
      return toSave.id!;
    } else {
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('employee_health_records', map);
    }
  }

  Future<void> deleteHealthRecord(int id) async {
    final db = await _dbHelper.database;
    await db.delete('employee_health_records', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // Company Bulk Health Reports (เล่มรวม รพ.)
  // --------------------------------------------------------------------------
  Future<List<CompanyHealthBulkReport>> getAllBulkReports() async {
    final db = await _dbHelper.database;
    final res = await db.query('company_health_bulk_reports', orderBy: 'report_year DESC, checkup_date DESC');
    return res.map((m) => CompanyHealthBulkReport.fromMap(m)).toList();
  }

  Future<int> saveBulkReport(CompanyHealthBulkReport report, {String? newPdfPath}) async {
    final db = await _dbHelper.database;
    String finalPdf = report.pdfFilePath;
    if (newPdfPath != null && newPdfPath.isNotEmpty) {
      final saved = await persistPdfFile(newPdfPath, prefix: 'bulk_report_${report.reportYear}');
      if (saved != null) finalPdf = saved;
    }

    final map = report.toMap();
    map['pdf_file_path'] = finalPdf;

    if (report.id != null) {
      await db.update('company_health_bulk_reports', map, where: 'id = ?', whereArgs: [report.id]);
      return report.id!;
    } else {
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('company_health_bulk_reports', map);
    }
  }

  Future<void> deleteBulkReport(int id) async {
    final db = await _dbHelper.database;
    await db.delete('company_health_bulk_reports', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // Medical Surveillance Follow-ups
  // --------------------------------------------------------------------------
  Future<List<MedicalSurveillanceFollowup>> getAllFollowups() async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT msf.*,
        e.employee_code, e.full_name, e.department,
        ehr.checkup_date
      FROM medical_surveillance_followups msf
      INNER JOIN employees e ON msf.employee_id = e.id
      INNER JOIN employee_health_records ehr ON msf.health_record_id = ehr.id
      ORDER BY msf.status = 'OPEN' DESC, msf.target_date ASC
    ''');
    return res.map((m) => MedicalSurveillanceFollowup.fromMap(m)).toList();
  }

  Future<int> saveFollowup(MedicalSurveillanceFollowup followup) async {
    final db = await _dbHelper.database;
    final map = followup.toMap();

    if (followup.id != null) {
      await db.update('medical_surveillance_followups', map, where: 'id = ?', whereArgs: [followup.id]);
      return followup.id!;
    } else {
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('medical_surveillance_followups', map);
    }
  }

  Future<void> deleteFollowup(int id) async {
    final db = await _dbHelper.database;
    await db.delete('medical_surveillance_followups', where: 'id = ?', whereArgs: [id]);
  }
}
