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
    final res = await db.rawQuery('''
      SELECT ai.*,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id) as capa_count,
        (SELECT COUNT(*) FROM accident_capa_actions aca WHERE aca.investigation_id = ai.id AND aca.status = 'COMPLETED') as completed_capa_count
      FROM accident_investigations ai
      ORDER BY ai.incident_date DESC, ai.id DESC
    ''');
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
}
