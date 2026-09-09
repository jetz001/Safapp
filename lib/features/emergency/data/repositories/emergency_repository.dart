import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';
import '../models/emergency_plan_model.dart';
import '../models/drill_session_model.dart';
import '../models/electrical_inspection_model.dart';
import '../datasources/emergency_presets_data.dart';

class EmergencyRepository {
  final DatabaseHelper _dbHelper;

  EmergencyRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // ==========================================
  // 1. EMERGENCY PLANS (ERP)
  // ==========================================

  Future<List<EmergencyPlanModel>> getAllPlans({
    HazardType? hazardType,
    PlanStatus? status,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (hazardType != null) {
      whereClauses.add('hazard_type = ?');
      whereArgs.add(hazardType.code);
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.code);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'emergency_plans',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    // If table is empty, auto-seed default Fire and Chemical presets
    if (maps.isEmpty && hazardType == null && status == null) {
      await seedDefaultPlans();
      return getAllPlans();
    }

    return maps.map((e) => EmergencyPlanModel.fromMap(e)).toList();
  }

  Future<EmergencyPlanModel?> getPlanById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'emergency_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EmergencyPlanModel.fromMap(maps.first);
  }

  Future<EmergencyPlanModel?> getActivePlan(HazardType hazardType) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'emergency_plans',
      where: 'hazard_type = ? AND status = ?',
      whereArgs: [hazardType.code, PlanStatus.active.code],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return EmergencyPlanModel.fromMap(maps.first);

    // Fallback to any latest plan of this hazard
    final anyMaps = await db.query(
      'emergency_plans',
      where: 'hazard_type = ?',
      whereArgs: [hazardType.code],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (anyMaps.isNotEmpty) return EmergencyPlanModel.fromMap(anyMaps.first);

    return null;
  }

  Future<int> insertPlan(EmergencyPlanModel plan) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'emergency_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePlan(EmergencyPlanModel plan) async {
    if (plan.id == null) throw ArgumentError('Cannot update plan without ID');
    final db = await _dbHelper.database;
    return await db.update(
      'emergency_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deletePlan(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'emergency_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> seedDefaultPlans() async {
    final firePlan = EmergencyPresetsData.getPreset(
      hazardType: HazardType.fire,
      businessType: BusinessType.factory,
    );
    await insertPlan(firePlan);

    final chemPlan = EmergencyPresetsData.getPreset(
      hazardType: HazardType.chemicalSpill,
      businessType: BusinessType.chemicalStorage,
    );
    await insertPlan(chemPlan);
  }

  // ==========================================
  // 2. DRILL SESSIONS (สปร. ๔)
  // ==========================================

  Future<List<DrillSessionModel>> getAllDrills({
    int? year,
    HazardType? hazardType,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (year != null) {
      whereClauses.add('drill_year = ?');
      whereArgs.add(year);
    }
    if (hazardType != null) {
      whereClauses.add('hazard_type = ?');
      whereArgs.add(hazardType.code);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'emergency_drill_sessions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'drill_date DESC, id DESC',
    );

    final result = <DrillSessionModel>[];
    for (final m in maps) {
      final drillId = m['id'] as int;
      final attachments = await getAttachmentsForDrill(drillId);
      result.add(DrillSessionModel.fromMap(m, attachments: attachments));
    }
    return result;
  }

  Future<DrillSessionModel?> getDrillById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'emergency_drill_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final attachments = await getAttachmentsForDrill(id);
    return DrillSessionModel.fromMap(maps.first, attachments: attachments);
  }

  Future<DrillSessionModel?> getLatestDrill({HazardType? hazardType}) async {
    final db = await _dbHelper.database;
    final where = hazardType != null ? 'hazard_type = ?' : null;
    final args = hazardType != null ? [hazardType.code] : null;

    final maps = await db.query(
      'emergency_drill_sessions',
      where: where,
      whereArgs: args,
      orderBy: 'drill_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final id = maps.first['id'] as int;
    final attachments = await getAttachmentsForDrill(id);
    return DrillSessionModel.fromMap(maps.first, attachments: attachments);
  }

  Future<int> insertDrill(DrillSessionModel drill) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'emergency_drill_sessions',
      drill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDrill(DrillSessionModel drill) async {
    if (drill.id == null) throw ArgumentError('Cannot update drill without ID');
    final db = await _dbHelper.database;
    return await db.update(
      'emergency_drill_sessions',
      drill.toMap(),
      where: 'id = ?',
      whereArgs: [drill.id],
    );
  }

  Future<int> deleteDrill(int id) async {
    final db = await _dbHelper.database;
    await db.delete('emergency_drill_attachments', where: 'drill_id = ?', whereArgs: [id]);
    return await db.delete('emergency_drill_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // 3. DRILL ATTACHMENTS
  // ==========================================

  Future<List<DrillAttachmentModel>> getAttachmentsForDrill(int drillId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'emergency_drill_attachments',
      where: 'drill_id = ?',
      whereArgs: [drillId],
      orderBy: 'id ASC',
    );
    return maps.map((e) => DrillAttachmentModel.fromMap(e)).toList();
  }

  Future<int> insertAttachment(DrillAttachmentModel attachment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'emergency_drill_attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteAttachment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('emergency_drill_attachments', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // 4. ELECTRICAL INSPECTIONS (แบบ ๕๖๒๘๙ / ม.๑๒)
  // ==========================================

  Future<List<ElectricalInspectionModel>> getAllElectricalInspections() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'electrical_inspection_records',
      orderBy: 'inspection_date DESC',
    );
    return maps.map((e) => ElectricalInspectionModel.fromMap(e)).toList();
  }

  Future<ElectricalInspectionModel?> getLatestElectricalInspection() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'electrical_inspection_records',
      orderBy: 'inspection_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ElectricalInspectionModel.fromMap(maps.first);
  }

  Future<ElectricalInspectionModel?> getElectricalInspectionById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'electrical_inspection_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ElectricalInspectionModel.fromMap(maps.first);
  }

  Future<int> insertElectricalInspection(ElectricalInspectionModel record) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'electrical_inspection_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateElectricalInspection(ElectricalInspectionModel record) async {
    if (record.id == null) throw ArgumentError('Cannot update record without ID');
    final db = await _dbHelper.database;
    return await db.update(
      'electrical_inspection_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteElectricalInspection(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'electrical_inspection_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
