import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/contractor_models.dart';

class ContractorRepository {
  final DatabaseHelper _dbHelper;

  ContractorRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // 1. CONTRACTOR COMPANIES
  // --------------------------------------------------------------------------
  Future<List<ContractorCompany>> getAllContractors() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM contractor_workers w WHERE w.contractor_id = c.id) as worker_count,
        (SELECT COUNT(*) FROM contractor_violations v WHERE v.contractor_id = c.id) as violation_count
      FROM contractors c
      ORDER BY c.status = 'ACTIVE' DESC, c.company_name ASC
    ''');
    return maps.map((m) => ContractorCompany.fromMap(m)).toList();
  }

  Future<ContractorCompany?> getContractorById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM contractor_workers w WHERE w.contractor_id = c.id) as worker_count,
        (SELECT COUNT(*) FROM contractor_violations v WHERE v.contractor_id = c.id) as violation_count
      FROM contractors c
      WHERE c.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return ContractorCompany.fromMap(maps.first);
  }

  Future<int> saveContractor(ContractorCompany company) async {
    final db = await _dbHelper.database;
    if (company.id != null && company.id! > 0) {
      await db.update(
        'contractors',
        company.toMap(),
        where: 'id = ?',
        whereArgs: [company.id],
      );
      return company.id!;
    } else {
      return await db.insert('contractors', company.toMap());
    }
  }

  Future<void> deleteContractor(int id) async {
    final db = await _dbHelper.database;
    await db.delete('contractors', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // 2. CONTRACTOR WORKERS
  // --------------------------------------------------------------------------
  Future<List<ContractorWorker>> getAllWorkers({int? contractorId}) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT w.*, c.company_name
      FROM contractor_workers w
      LEFT JOIN contractors c ON w.contractor_id = c.id
    ''';
    List<dynamic> args = [];
    if (contractorId != null && contractorId > 0) {
      sql += ' WHERE w.contractor_id = ?';
      args.add(contractorId);
    }
    sql += ' ORDER BY w.worker_name ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((m) => ContractorWorker.fromMap(m)).toList();
  }

  Future<ContractorWorker?> getWorkerById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT w.*, c.company_name
      FROM contractor_workers w
      LEFT JOIN contractors c ON w.contractor_id = c.id
      WHERE w.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return ContractorWorker.fromMap(maps.first);
  }

  Future<int> saveWorker(ContractorWorker worker) async {
    final db = await _dbHelper.database;
    if (worker.id != null && worker.id! > 0) {
      await db.update(
        'contractor_workers',
        worker.toMap(),
        where: 'id = ?',
        whereArgs: [worker.id],
      );
      return worker.id!;
    } else {
      return await db.insert('contractor_workers', worker.toMap());
    }
  }

  Future<void> deleteWorker(int id) async {
    final db = await _dbHelper.database;
    await db.delete('contractor_workers', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // 3. CONTRACTOR VIOLATIONS
  // --------------------------------------------------------------------------
  Future<List<ContractorViolation>> getAllViolations({int? contractorId}) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT v.*, c.company_name, w.worker_name
      FROM contractor_violations v
      LEFT JOIN contractors c ON v.contractor_id = c.id
      LEFT JOIN contractor_workers w ON v.worker_id = w.id
    ''';
    List<dynamic> args = [];
    if (contractorId != null && contractorId > 0) {
      sql += ' WHERE v.contractor_id = ?';
      args.add(contractorId);
    }
    sql += ' ORDER BY v.incident_date DESC, v.id DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((m) => ContractorViolation.fromMap(m)).toList();
  }

  Future<int> saveViolation(ContractorViolation violation) async {
    final db = await _dbHelper.database;
    int id;
    if (violation.id != null && violation.id! > 0) {
      await db.update(
        'contractor_violations',
        violation.toMap(),
        where: 'id = ?',
        whereArgs: [violation.id],
      );
      id = violation.id!;
    } else {
      id = await db.insert('contractor_violations', violation.toMap());

      // Deduct score from company if specified
      if (violation.scoreDeducted > 0) {
        await db.rawUpdate('''
          UPDATE contractors 
          SET safety_score = MAX(0, safety_score - ?) 
          WHERE id = ?
        ''', [violation.scoreDeducted, violation.contractorId]);
      }
    }
    return id;
  }

  Future<void> deleteViolation(int id) async {
    final db = await _dbHelper.database;
    await db.delete('contractor_violations', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // FILE STORAGE HELPER
  // --------------------------------------------------------------------------
  Future<String?> persistFile(String sourcePath, {required String prefix}) async {
    final srcFile = File(sourcePath);
    if (!await srcFile.exists()) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'ContractorFiles'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetFileName = '${prefix}_$timestamp$ext';
    final targetFile = File(p.join(targetDir.path, targetFileName));

    await srcFile.copy(targetFile.path);
    return targetFile.path;
  }
}
