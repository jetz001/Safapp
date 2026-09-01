import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/environment_standard_model.dart';
import '../domain/models/subcontractor_model.dart';
import '../domain/models/environment_session_model.dart';
import '../domain/models/environment_point_model.dart';
import '../domain/models/environment_capa_model.dart';
import '../domain/models/environment_kpi_summary.dart';
import '../domain/services/environmental_evaluator.dart';
import 'environmental_standards_data.dart';

/// Repository handling SQLite persistence, multi-category attachments,
/// statutory master data, sampling points, CAPA tracking, and KPI calculations
/// for SAFAPP Environmental Monitoring.
class EnvironmentRepository {
  final DatabaseHelper _dbHelper;

  EnvironmentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // 1. Multi-Category Attachment Management
  // --------------------------------------------------------------------------

  /// Persists an external file (PDF Report, Calibration Cert, License, Site Photo)
  /// to the app's dedicated `SafetySuperapp/environment/` directory.
  Future<String?> persistEnvironmentAttachment(
    String sourcePath, {
    String prefix = 'env_doc',
  }) async {
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return sourcePath;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'environment'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetFile = File(p.join(targetDir.path, filename));

      await srcFile.copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      debugPrint('Error persisting environment attachment: $e');
      return sourcePath;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Master Environmental Standards Catalog
  // --------------------------------------------------------------------------

  /// Retrieves statutory standards with optional factor type and keyword filters.
  Future<List<EnvironmentStandardModel>> getAllStandards({
    EnvironmentFactorType? factorType,
    String? keyword,
  }) async {
    try {
      final db = await _dbHelper.database;
      String sql = 'SELECT * FROM environment_standards_master';
      final List<String> whereClauses = [];
      final List<dynamic> args = [];

      if (factorType != null) {
        whereClauses.add('factor_type = ?');
        args.add(factorType.toDbCode());
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final q = '%${keyword.trim()}%';
        whereClauses.add(
          '(standard_id LIKE ? OR category_name_th LIKE ? OR category_name_en LIKE ? OR task_description LIKE ? OR reference_law_title LIKE ? OR reference_article LIKE ?)',
        );
        args.addAll([q, q, q, q, q, q]);
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql += ' ORDER BY sort_order ASC, id ASC';

      final res = await db.rawQuery(sql, args);
      if (res.isNotEmpty) {
        return res.map((m) => EnvironmentStandardModel.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint('Warning fetching standards from DB, falling back to static data: $e');
    }

    // Fallback to static catalog
    return EnvironmentalStandardsData.search(
      keyword ?? '',
      factorType: factorType,
    );
  }

  /// Retrieves a standard item by ID
  Future<EnvironmentStandardModel?> getStandardById(String standardId) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query(
        'environment_standards_master',
        where: 'standard_id = ?',
        whereArgs: [standardId],
      );
      if (res.isNotEmpty) {
        return EnvironmentStandardModel.fromMap(res.first);
      }
    } catch (e) {
      debugPrint('Error fetching standard by ID from DB: $e');
    }
    return EnvironmentalStandardsData.findById(standardId);
  }

  // --------------------------------------------------------------------------
  // 3. Environmental Monitoring Sessions (รอบการตรวจวัด & ผู้ตรวจวัด)
  // --------------------------------------------------------------------------

  /// Retrieves all measurement sessions with optional year, status, and keyword filters.
  Future<List<EnvironmentSessionModel>> getAllSessions({
    int? yearBe,
    EnvironmentSessionStatus? status,
    String? keyword,
  }) async {
    try {
      final db = await _dbHelper.database;
      String sql = 'SELECT * FROM environment_sessions';
      final List<String> whereClauses = [];
      final List<dynamic> args = [];

      if (yearBe != null) {
        whereClauses.add('session_year_be = ?');
        args.add(yearBe);
      }

      if (status != null) {
        whereClauses.add('status = ?');
        args.add(status.toDbCode());
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final q = '%${keyword.trim()}%';
        whereClauses.add(
          '(session_id LIKE ? OR session_title LIKE ? OR location_plant LIKE ? OR workplace_name LIKE ? OR subcontractor_company_name LIKE ? OR subcontractor_reg_number LIKE ? OR surveyor_name LIKE ? OR certifier_name LIKE ?)',
        );
        args.addAll([q, q, q, q, q, q, q, q]);
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql += ' ORDER BY measurement_date DESC, id DESC';

      final res = await db.rawQuery(sql, args);
      return res.map((m) => EnvironmentSessionModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching environment sessions: $e');
      return [];
    }
  }

  /// Retrieves a single session by session_id.
  Future<EnvironmentSessionModel?> getSessionById(String sessionId) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query(
        'environment_sessions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      if (res.isNotEmpty) {
        return EnvironmentSessionModel.fromMap(res.first);
      }
    } catch (e) {
      debugPrint('Error fetching session by ID: $e');
    }
    return null;
  }

  /// Saves (insert or update) an environmental session.
  Future<int> saveSession(EnvironmentSessionModel session) async {
    final db = await _dbHelper.database;
    final map = session.toMap();

    if (session.id != null) {
      map['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'environment_sessions',
        map,
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } else {
      // Check by session_id
      final existing = await db.query(
        'environment_sessions',
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
      );
      if (existing.isNotEmpty) {
        map['updated_at'] = DateTime.now().toIso8601String();
        return await db.update(
          'environment_sessions',
          map,
          where: 'session_id = ?',
          whereArgs: [session.sessionId],
        );
      } else {
        return await db.insert('environment_sessions', map);
      }
    }
  }

  /// Deletes a session and its associated points and CAPA actions.
  Future<int> deleteSession(String sessionId) async {
    final db = await _dbHelper.database;
    await db.delete('environment_capa', where: 'session_id = ?', whereArgs: [sessionId]);
    await db.delete('environment_measurement_points', where: 'session_id = ?', whereArgs: [sessionId]);
    return await db.delete('environment_sessions', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // --------------------------------------------------------------------------
  // 4. Environmental Sampling Points (ผลตรวจวัดรายจุด แสง เสียง ความร้อน)
  // --------------------------------------------------------------------------

  /// Retrieves sampling points for a session or globally.
  Future<List<EnvironmentPointModel>> getPoints({
    String? sessionId,
    EnvironmentFactorType? factorType,
    EnvironmentEvaluationStatus? status,
    String? keyword,
  }) async {
    try {
      final db = await _dbHelper.database;
      String sql = 'SELECT * FROM environment_measurement_points';
      final List<String> whereClauses = [];
      final List<dynamic> args = [];

      if (sessionId != null && sessionId.isNotEmpty) {
        whereClauses.add('session_id = ?');
        args.add(sessionId);
      }

      if (factorType != null) {
        whereClauses.add('factor_type = ?');
        args.add(factorType.toDbCode());
      }

      if (status != null) {
        whereClauses.add('evaluation_status = ?');
        args.add(status.toDbCode());
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final q = '%${keyword.trim()}%';
        whereClauses.add(
          '(point_id LIKE ? OR department LIKE ? OR location_name LIKE ? OR task_or_machine_name LIKE ? OR notes LIKE ?)',
        );
        args.addAll([q, q, q, q, q]);
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql += ' ORDER BY id ASC';

      final res = await db.rawQuery(sql, args);
      return res.map((m) => EnvironmentPointModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching environment points: $e');
      return [];
    }
  }

  /// Retrieves a point by point_id.
  Future<EnvironmentPointModel?> getPointById(String pointId) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query(
        'environment_measurement_points',
        where: 'point_id = ?',
        whereArgs: [pointId],
      );
      if (res.isNotEmpty) {
        return EnvironmentPointModel.fromMap(res.first);
      }
    } catch (e) {
      debugPrint('Error fetching point by ID: $e');
    }
    return null;
  }

  /// Saves (insert or update) an environmental sampling point.
  Future<int> savePoint(EnvironmentPointModel point) async {
    final db = await _dbHelper.database;
    final map = point.toMap();

    if (point.id != null) {
      map['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'environment_measurement_points',
        map,
        where: 'id = ?',
        whereArgs: [point.id],
      );
    } else {
      final existing = await db.query(
        'environment_measurement_points',
        where: 'point_id = ?',
        whereArgs: [point.pointId],
      );
      if (existing.isNotEmpty) {
        map['updated_at'] = DateTime.now().toIso8601String();
        return await db.update(
          'environment_measurement_points',
          map,
          where: 'point_id = ?',
          whereArgs: [point.pointId],
        );
      } else {
        return await db.insert('environment_measurement_points', map);
      }
    }
  }

  /// Saves a batch of measurement points in a single transaction.
  Future<void> saveBatchPoints(List<EnvironmentPointModel> points) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final pt in points) {
      batch.insert(
        'environment_measurement_points',
        pt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Deletes a measurement point and any associated CAPA.
  Future<int> deletePoint(String pointId) async {
    final db = await _dbHelper.database;
    await db.delete('environment_capa', where: 'point_id = ?', whereArgs: [pointId]);
    return await db.delete(
      'environment_measurement_points',
      where: 'point_id = ?',
      whereArgs: [pointId],
    );
  }

  // --------------------------------------------------------------------------
  // 5. Environmental CAPA & Hearing Conservation Plans
  // --------------------------------------------------------------------------

  /// Retrieves CAPA action plans with optional session, status, and factor filters.
  Future<List<EnvironmentCapaModel>> getCapas({
    String? sessionId,
    String? status,
    EnvironmentFactorType? factorType,
    String? keyword,
  }) async {
    try {
      final db = await _dbHelper.database;
      String sql = 'SELECT * FROM environment_capa';
      final List<String> whereClauses = [];
      final List<dynamic> args = [];

      if (sessionId != null && sessionId.isNotEmpty) {
        whereClauses.add('session_id = ?');
        args.add(sessionId);
      }

      if (factorType != null) {
        whereClauses.add('factor_type = ?');
        args.add(factorType.toDbCode());
      }

      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        if (status.toUpperCase() == 'OVERDUE') {
          final today = DateTime.now().toIso8601String().split('T').first;
          whereClauses.add("status != 'COMPLETED' AND target_date < ?");
          args.add(today);
        } else {
          whereClauses.add('status = ?');
          args.add(status.toUpperCase());
        }
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final q = '%${keyword.trim()}%';
        whereClauses.add(
          '(capa_id LIKE ? OR action_title LIKE ? OR hazard_description LIKE ? OR root_cause LIKE ? OR pic_name LIKE ? OR pic_department LIKE ?)',
        );
        args.addAll([q, q, q, q, q, q]);
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql += ' ORDER BY target_date ASC, id ASC';

      final res = await db.rawQuery(sql, args);
      return res.map((m) => EnvironmentCapaModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching environment CAPAs: $e');
      return [];
    }
  }

  /// Retrieves a single CAPA item by capa_id.
  Future<EnvironmentCapaModel?> getCapaById(String capaId) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query(
        'environment_capa',
        where: 'capa_id = ?',
        whereArgs: [capaId],
      );
      if (res.isNotEmpty) {
        return EnvironmentCapaModel.fromMap(res.first);
      }
    } catch (e) {
      debugPrint('Error fetching CAPA by ID: $e');
    }
    return null;
  }

  /// Saves (insert or update) an environmental CAPA item.
  Future<int> saveCapa(EnvironmentCapaModel capa) async {
    final db = await _dbHelper.database;
    final map = capa.toMap();

    if (capa.id != null) {
      map['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'environment_capa',
        map,
        where: 'id = ?',
        whereArgs: [capa.id],
      );
    } else {
      final existing = await db.query(
        'environment_capa',
        where: 'capa_id = ?',
        whereArgs: [capa.capaId],
      );
      if (existing.isNotEmpty) {
        map['updated_at'] = DateTime.now().toIso8601String();
        return await db.update(
          'environment_capa',
          map,
          where: 'capa_id = ?',
          whereArgs: [capa.capaId],
        );
      } else {
        return await db.insert('environment_capa', map);
      }
    }
  }

  /// Deletes a CAPA item by capa_id.
  Future<int> deleteCapa(String capaId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'environment_capa',
      where: 'capa_id = ?',
      whereArgs: [capaId],
    );
  }

  // --------------------------------------------------------------------------
  // 6. Aggregate KPI Metrics Calculation
  // --------------------------------------------------------------------------

  /// Calculates KPI summary for a specific measurement session.
  Future<EnvironmentKpiSummary> getSessionKpi(String sessionId) async {
    final points = await getPoints(sessionId: sessionId);
    final capas = await getCapas(sessionId: sessionId);
    return EnvironmentalEvaluator.calculateKpi(points, capas: capas);
  }

  /// Calculates overall composite KPI summary across all sessions.
  Future<EnvironmentKpiSummary> getOverallKpi() async {
    final points = await getPoints();
    final capas = await getCapas();
    return EnvironmentalEvaluator.calculateKpi(points, capas: capas);
  }
}
