import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/electrical_inspection_model.dart';

class ElectricalRepository {
  final DatabaseHelper _dbHelper;

  ElectricalRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

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
}
