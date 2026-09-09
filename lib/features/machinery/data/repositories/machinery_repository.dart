import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/crane_inspection_model.dart';
import '../models/boiler_inspection_model.dart';
import '../models/machinery_asset_model.dart';

class MachineryRepository {
  final DatabaseHelper _dbHelper;

  MachineryRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper();

  // ================= CRANE INSPECTIONS (ปจ.๑ / ปจ.๒) =================
  Future<List<CraneInspectionModel>> getCraneInspections() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'machinery_crane_inspections',
      orderBy: 'inspection_date DESC',
    );
    return results.map((m) => CraneInspectionModel.fromMap(m)).toList();
  }

  Future<int> insertCraneInspection(CraneInspectionModel inspection) async {
    final db = await _dbHelper.database;
    return await db.insert('machinery_crane_inspections', inspection.toMap());
  }

  Future<int> updateCraneInspection(CraneInspectionModel inspection) async {
    if (inspection.id == null) return 0;
    final db = await _dbHelper.database;
    return await db.update(
      'machinery_crane_inspections',
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  Future<int> deleteCraneInspection(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'machinery_crane_inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= BOILER INSPECTIONS (หม้อน้ำ & ภาชนะรับแรงดัน) =================
  Future<List<BoilerInspectionModel>> getBoilerInspections() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'machinery_boiler_inspections',
      orderBy: 'inspection_date DESC',
    );
    return results.map((m) => BoilerInspectionModel.fromMap(m)).toList();
  }

  Future<int> insertBoilerInspection(BoilerInspectionModel inspection) async {
    final db = await _dbHelper.database;
    return await db.insert('machinery_boiler_inspections', inspection.toMap());
  }

  Future<int> updateBoilerInspection(BoilerInspectionModel inspection) async {
    if (inspection.id == null) return 0;
    final db = await _dbHelper.database;
    return await db.update(
      'machinery_boiler_inspections',
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  Future<int> deleteBoilerInspection(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'machinery_boiler_inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= MACHINERY & LIFTING ASSETS =================
  Future<List<MachineryAssetModel>> getMachineryAssets({String? category}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'machinery_assets',
      where: category != null && category != 'ALL' ? 'category = ?' : null,
      whereArgs: category != null && category != 'ALL' ? [category] : null,
      orderBy: 'created_at DESC',
    );
    return results.map((m) => MachineryAssetModel.fromMap(m)).toList();
  }

  Future<int> insertMachineryAsset(MachineryAssetModel asset) async {
    final db = await _dbHelper.database;
    return await db.insert('machinery_assets', asset.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMachineryAsset(MachineryAssetModel asset) async {
    if (asset.id == null) return 0;
    final db = await _dbHelper.database;
    return await db.update(
      'machinery_assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> deleteMachineryAsset(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'machinery_assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAssetStatus(int id, String newStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      'machinery_assets',
      {'status': newStatus, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
