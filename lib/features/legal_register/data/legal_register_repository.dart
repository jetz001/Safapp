import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/models/legal_master_item_model.dart';
import '../domain/models/legal_compliance_assessment_model.dart';
import '../domain/models/legal_capa_model.dart';
import '../domain/models/legal_compliance_stats_model.dart';
import 'safety_legal_8_categories_data.dart';

/// Repository handling SQLite persistence, evidence file storage,
/// statutory master data, and compliance KPI calculations for SAFAPP Legal Register.
class LegalRegisterRepository {
  final DatabaseHelper _dbHelper;

  LegalRegisterRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // 1. Evidence File Storage Management
  // --------------------------------------------------------------------------

  /// Persists an external file (PDF / Photo / Certificate) to the app's dedicated
  /// `SafetySuperapp/legal/` storage directory.
  Future<String?> persistLegalAttachment(
    String sourcePath, {
    String prefix = 'legal_evidence',
  }) async {
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return sourcePath;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'legal'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetFile = File(p.join(targetDir.path, filename));

      await srcFile.copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      debugPrint('Error persisting legal attachment: $e');
      return sourcePath;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Master Legal Catalog (32 Items & 8 Laws)
  // --------------------------------------------------------------------------

  /// Retrieves master statutory items from SQLite with optional keyword and category filters.
  /// Falls back to static dataset if database table is not yet initialized.
  Future<List<LegalMasterItemModel>> getAllMasterItems({
    String? category,
    String? keyword,
  }) async {
    try {
      final db = await _dbHelper.database;
      String sql = 'SELECT * FROM safety_legal_master';
      final List<String> whereClauses = [];
      final List<dynamic> args = [];

      if (category != null && category.isNotEmpty && category.toUpperCase() != 'ALL') {
        whereClauses.add('category = ?');
        args.add(category);
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final q = '%${keyword.trim()}%';
        whereClauses.add('(item_id LIKE ? OR title LIKE ? OR description LIKE ? OR article_no LIKE ? OR law_name_th LIKE ? OR compliance_criteria LIKE ? OR penalty_summary LIKE ?)');
        args.addAll([q, q, q, q, q, q, q]);
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql += ' ORDER BY sort_order ASC, id ASC';

      final res = await db.rawQuery(sql, args);
      if (res.isNotEmpty) {
        return res.map((m) => LegalMasterItemModel.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint('Warning fetching master items from DB, falling back to static data: $e');
    }

    // Fallback to in-memory dataset
    return SafetyLegal8CategoriesData.search(keyword ?? '', category: category);
  }

  /// Retrieves a single master item by its unique ITEM-ID (e.g. 'ITEM-OSH-001').
  Future<LegalMasterItemModel?> getMasterItemById(String itemId) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query(
        'safety_legal_master',
        where: 'item_id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return LegalMasterItemModel.fromMap(res.first);
      }
    } catch (e) {
      debugPrint('Error getting master item by ID: $e');
    }
    return SafetyLegal8CategoriesData.findByItemId(itemId);
  }

  // --------------------------------------------------------------------------
  // 3. Compliance Assessments (Facility Legal Register) CRUD & Queries
  // --------------------------------------------------------------------------

  /// Retrieves facility legal assessments with flexible search and filtering.
  Future<List<LegalComplianceAssessmentModel>> getAllAssessments({
    String? query,
    String? category,
    String? status,
    bool? onlyApplicable,
  }) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM safety_legal_assessments';
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (category != null && category.isNotEmpty && category.toUpperCase() != 'ALL') {
      whereClauses.add('category = ?');
      args.add(category);
    }

    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      whereClauses.add('compliance_status = ?');
      args.add(status);
    }

    if (onlyApplicable == true) {
      whereClauses.add('is_applicable = 1');
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(requirement_code LIKE ? OR requirement_title LIKE ? OR requirement_details LIKE ? OR actual_practice LIKE ? OR law_title_th LIKE ? OR evaluator_name LIKE ?)');
      args.addAll([q, q, q, q, q, q]);
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY id ASC';

    final res = await db.rawQuery(sql, args);
    return res.map((m) => LegalComplianceAssessmentModel.fromMap(m)).toList();
  }

  /// Retrieves a single assessment by primary key ID.
  Future<LegalComplianceAssessmentModel?> getAssessmentById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'safety_legal_assessments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return LegalComplianceAssessmentModel.fromMap(res.first);
  }

  /// Retrieves a single assessment by statutory requirement code.
  Future<LegalComplianceAssessmentModel?> getAssessmentByRequirementCode(String code) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'safety_legal_assessments',
      where: 'requirement_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return LegalComplianceAssessmentModel.fromMap(res.first);
  }

  /// Saves (Inserts or Updates) an assessment record with optional evidence file persistence.
  Future<int> saveAssessment(
    LegalComplianceAssessmentModel item, {
    List<String>? newEvidencePaths,
  }) async {
    final db = await _dbHelper.database;

    List<String> finalEvidencePaths = List.from(item.evidenceFilePaths);
    if (newEvidencePaths != null && newEvidencePaths.isNotEmpty) {
      final persisted = <String>[];
      for (final p in newEvidencePaths) {
        if (p.isNotEmpty) {
          final savedPath = await persistLegalAttachment(
            p,
            prefix: 'ev_${item.requirementCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
          );
          if (savedPath != null) {
            persisted.add(savedPath);
          }
        }
      }
      finalEvidencePaths = persisted;
    }

    final updated = item.copyWith(
      evidenceFilePaths: finalEvidencePaths,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final map = updated.toMap();

    if (updated.id == null || updated.id == 0) {
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('safety_legal_assessments', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'safety_legal_assessments',
        map,
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      return updated.id!;
    }
  }

  /// Deletes an assessment by ID.
  Future<int> deleteAssessment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'safety_legal_assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Resets or re-seeds all default assessments from the master catalog.
  Future<void> resetDefaultAssessments() async {
    final db = await _dbHelper.database;
    await db.delete('safety_legal_assessments');
    final defaults = SafetyLegal8CategoriesData.generateDefaultAssessments();
    for (final a in defaults) {
      await db.insert('safety_legal_assessments', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --------------------------------------------------------------------------
  // 4. CAPA Action Plans (Corrective & Preventive Action) CRUD & Queries
  // --------------------------------------------------------------------------

  /// Retrieves all CAPA action plans with optional query, status, assessmentId, and overdue filtering.
  Future<List<LegalCapaModel>> getAllCapa({
    String? query,
    String? status,
    int? assessmentId,
    bool? overdueOnly,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT c.*, 
             a.requirement_code,
             a.requirement_title,
             a.category,
             a.law_title_th AS law_title
      FROM safety_legal_capa c
      LEFT JOIN safety_legal_assessments a ON c.assessment_id = a.id
    ''';

    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (assessmentId != null && assessmentId > 0) {
      whereClauses.add('c.assessment_id = ?');
      args.add(assessmentId);
    }

    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      whereClauses.add('c.status = ?');
      args.add(status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(c.action_title LIKE ? OR c.root_cause LIKE ? OR c.corrective_action LIKE ? OR c.pic_name LIKE ? OR a.requirement_title LIKE ?)');
      args.addAll([q, q, q, q, q]);
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY c.id DESC';

    final res = await db.rawQuery(sql, args);
    var list = res.map((m) => LegalCapaModel.fromMap(m)).toList();

    if (overdueOnly == true) {
      list = list.where((c) => c.isOverdue).toList();
    }

    return list;
  }

  /// Retrieves a single CAPA item by ID with joined assessment details.
  Future<LegalCapaModel?> getCapaById(int id) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT c.*, 
             a.requirement_code,
             a.requirement_title,
             a.category,
             a.law_title_th AS law_title
      FROM safety_legal_capa c
      LEFT JOIN safety_legal_assessments a ON c.assessment_id = a.id
      WHERE c.id = ?
      LIMIT 1
    ''';
    final res = await db.rawQuery(sql, [id]);
    if (res.isEmpty) return null;
    return LegalCapaModel.fromMap(res.first);
  }

  /// Retrieves all CAPA items linked to a specific assessment ID.
  Future<List<LegalCapaModel>> getCapaByAssessmentId(int assessmentId) async {
    return getAllCapa(assessmentId: assessmentId);
  }

  /// Saves (Inserts or Updates) a CAPA item with optional file persistence.
  Future<int> saveCapa(
    LegalCapaModel item, {
    String? newEvidencePath,
    bool updateParentAssessmentStatus = true,
  }) async {
    final db = await _dbHelper.database;

    String? finalEvidencePath = item.evidenceFilePath;
    if (newEvidencePath != null && newEvidencePath.isNotEmpty && newEvidencePath != item.evidenceFilePath) {
      finalEvidencePath = await persistLegalAttachment(
        newEvidencePath,
        prefix: 'capa_ev_${item.assessmentId}',
      );
    }

    final updated = item.copyWith(
      evidenceFilePath: finalEvidencePath,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final map = updated.toMap();
    int capaId;

    if (updated.id == null || updated.id == 0) {
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      capaId = await db.insert('safety_legal_capa', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'safety_legal_capa',
        map,
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      capaId = updated.id!;
    }

    // Auto-update assessment status when CAPA is created or modified
    if (updateParentAssessmentStatus && updated.assessmentId > 0) {
      final assessment = await getAssessmentById(updated.assessmentId);
      if (assessment != null) {
        if (updated.isCompleted) {
          // Check if all CAPAs for this assessment are completed
          final allCapas = await getCapaByAssessmentId(updated.assessmentId);
          final allDone = allCapas.isNotEmpty && allCapas.every((c) => c.isCompleted);
          if (allDone && assessment.complianceStatus != 'COMPLIANT') {
            await saveAssessment(assessment.copyWith(complianceStatus: 'COMPLIANT'));
          }
        } else if (assessment.complianceStatus == 'NOT_APPLICABLE' || assessment.complianceStatus == 'NON_COMPLIANT') {
          await saveAssessment(assessment.copyWith(complianceStatus: 'IN_PROGRESS'));
        }
      }
    }

    return capaId;
  }

  /// Deletes a CAPA item by ID.
  Future<int> deleteCapa(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'safety_legal_capa',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes a CAPA item, setting status to COMPLETED and updating completed date.
  Future<int> closeCapa(int id, {String? completedDate, String? notes}) async {
    final capa = await getCapaById(id);
    if (capa == null) return 0;

    final closed = capa.copyWith(
      status: 'COMPLETED',
      completedDate: completedDate ?? DateTime.now().toIso8601String().substring(0, 10),
      notes: notes != null ? '${capa.notes ?? ''}\n$notes'.trim() : capa.notes,
    );

    return await saveCapa(closed);
  }

  // --------------------------------------------------------------------------
  // 5. Compliance KPI Calculations
  // --------------------------------------------------------------------------

  /// Computes live compliance statistics (Basic % CI, Risk-Weighted % WCI,
  /// CAPA breakdown, and per-category metrics).
  Future<LegalComplianceStatsModel> calculateStats({String? category}) async {
    final assessments = await getAllAssessments(category: category);
    final capas = await getAllCapa();
    return LegalComplianceStatsModel.calculate(
      assessments: assessments,
      capas: capas,
    );
  }
}
