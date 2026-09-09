import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/sop_model.dart';

class SopRepository {
  final DatabaseHelper _dbHelper;

  SopRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  Future<List<SopModel>> getSops({String? category, String? searchQuery}) async {
    final db = await _db;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (category != null && category != 'ALL') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('(doc_code LIKE ? OR title LIKE ? OR purpose LIKE ? OR precautions LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'safety_manual_sops',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'doc_code ASC',
    );

    return results.map((m) => SopModel.fromMap(m)).toList();
  }

  Future<SopModel?> getSopById(int id) async {
    final db = await _db;
    final results = await db.query(
      'safety_manual_sops',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SopModel.fromMap(results.first);
  }

  Future<int> insertSop(SopModel sop) async {
    final db = await _db;
    return await db.insert(
      'safety_manual_sops',
      sop.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSop(SopModel sop) async {
    if (sop.id == null) return 0;
    final db = await _db;
    return await db.update(
      'safety_manual_sops',
      sop.toMap(),
      where: 'id = ?',
      whereArgs: [sop.id],
    );
  }

  Future<int> deleteSop(int id) async {
    final db = await _db;
    return await db.delete(
      'safety_manual_sops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSopStatus(int id, String status) async {
    final db = await _db;
    return await db.update(
      'safety_manual_sops',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
