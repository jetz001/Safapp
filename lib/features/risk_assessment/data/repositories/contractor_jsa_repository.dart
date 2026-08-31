import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/contractor_jsa_models.dart';

class ContractorJsaRepository {
  final DatabaseHelper _dbHelper;

  ContractorJsaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<ContractorJsaDocument>> getAllDocuments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contractor_jsa_documents',
      orderBy: 'assessment_date DESC, id DESC',
    );
    return maps.map((m) => ContractorJsaDocument.fromMap(m)).toList();
  }

  Future<ContractorJsaDocument?> getDocumentById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contractor_jsa_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ContractorJsaDocument.fromMap(maps.first);
  }

  Future<int> saveDocument(ContractorJsaDocument doc) async {
    final db = await _dbHelper.database;
    if (doc.id != null && doc.id! > 0) {
      await db.update(
        'contractor_jsa_documents',
        doc.toMap(),
        where: 'id = ?',
        whereArgs: [doc.id],
      );
      return doc.id!;
    } else {
      return await db.insert('contractor_jsa_documents', doc.toMap());
    }
  }

  Future<void> deleteDocument(int id) async {
    final db = await _dbHelper.database;
    final doc = await getDocumentById(id);
    if (doc != null) {
      for (final filePath in doc.filePaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    await db.delete(
      'contractor_jsa_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Copies files from their original picked locations into the app's persistent storage
  Future<List<String>> persistPickedFiles(List<String> sourcePaths) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'ContractorDocuments'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final List<String> persistentPaths = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < sourcePaths.length; i++) {
      final srcPath = sourcePaths[i];
      final srcFile = File(srcPath);
      if (await srcFile.exists()) {
        final ext = p.extension(srcPath);
        final baseName = p.basenameWithoutExtension(srcPath).replaceAll(RegExp(r'[^\w\.-]'), '_');
        final targetFileName = 'contractor_${timestamp}_${i + 1}_$baseName$ext';
        final targetFile = File(p.join(targetDir.path, targetFileName));

        await srcFile.copy(targetFile.path);
        persistentPaths.add(targetFile.path);
      } else {
        // If already in target directory or remote
        persistentPaths.add(srcPath);
      }
    }

    return persistentPaths;
  }
}
