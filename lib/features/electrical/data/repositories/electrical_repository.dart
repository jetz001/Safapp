import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/electrical_inspection_model.dart';
import '../models/circuit_breaker_model.dart';

class ElectricalRepository {
  final DatabaseHelper _dbHelper;

  ElectricalRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // ========================================================
  // 1. ANNUAL INSPECTION (ม.๑๒ / แบบ ๕๖๒๘๙)
  // ========================================================

  Future<List<ElectricalInspectionModel>> getElectricalInspections() async {
    final db = await _db;
    final maps = await db.query(
      'electrical_inspection_records',
      orderBy: 'inspection_date DESC',
    );
    return maps.map((m) => ElectricalInspectionModel.fromMap(m)).toList();
  }

  Future<ElectricalInspectionModel?> getLatestElectricalInspection() async {
    final db = await _db;
    final maps = await db.query(
      'electrical_inspection_records',
      orderBy: 'inspection_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ElectricalInspectionModel.fromMap(maps.first);
  }

  Future<int> insertElectricalInspection(ElectricalInspectionModel record) async {
    final db = await _db;
    return await db.insert('electrical_inspection_records', record.toMap());
  }

  Future<int> updateElectricalInspection(ElectricalInspectionModel record) async {
    final db = await _db;
    return await db.update(
      'electrical_inspection_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteElectricalInspection(int id) async {
    final db = await _db;
    return await db.delete(
      'electrical_inspection_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================================
  // 2. CIRCUIT BREAKERS & LOTO ISOLATION POINTS
  // ========================================================

  Future<List<CircuitBreakerModel>> getCircuitBreakers() async {
    final db = await _db;
    final maps = await db.query(
      'electrical_circuit_breakers',
      orderBy: 'equipment_tag ASC',
    );
    return maps.map((m) => CircuitBreakerModel.fromMap(m)).toList();
  }

  Future<int> insertCircuitBreaker(CircuitBreakerModel breaker) async {
    final db = await _db;
    return await db.insert('electrical_circuit_breakers', breaker.toMap());
  }

  Future<int> updateCircuitBreaker(CircuitBreakerModel breaker) async {
    final db = await _db;
    return await db.update(
      'electrical_circuit_breakers',
      breaker.toMap(),
      where: 'id = ?',
      whereArgs: [breaker.id],
    );
  }

  Future<int> deleteCircuitBreaker(int id) async {
    final db = await _db;
    return await db.delete(
      'electrical_circuit_breakers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleBreakerLock({
    required int id,
    required bool isLocked,
    String? lockoutTagNo,
    String? lockedBy,
    bool? zeroEnergyVerified,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'electrical_circuit_breakers',
      {
        'is_locked': isLocked ? 1 : 0,
        'lockout_tag_no': isLocked ? lockoutTagNo : null,
        'locked_by': isLocked ? lockedBy : null,
        'locked_at': isLocked ? now : null,
        'zero_energy_verified': isLocked ? (zeroEnergyVerified == true ? 1 : 0) : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
