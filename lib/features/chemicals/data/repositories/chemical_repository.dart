import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/chemical_master_model.dart';
import '../../domain/models/chemical_tlv_model.dart';
import '../../domain/models/chemical_inventory_model.dart';
import '../../domain/models/chemical_sds_sor1_model.dart';
import '../../domain/models/chemical_measurement_sor3_model.dart';
import '../../domain/models/chemical_laws_model.dart';
import '../datasources/chemical_1516_master_data.dart';
import '../datasources/chemical_324_tlv_data.dart';
import '../datasources/chemical_laws_data.dart';

/// Repository handling SQLite persistence, local file management, and statutory master data queries.
class ChemicalRepository {
  final DatabaseHelper _dbHelper;

  ChemicalRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // --------------------------------------------------------------------------
  // 1. File Persistence for SDS PDFs, Photos & Lab Certificates
  // --------------------------------------------------------------------------

  /// Persists an external file (PDF/Image) to the app's dedicated `SafetySuperapp/chemicals/` storage directory.
  Future<String?> persistChemicalAttachment(
    String sourcePath, {
    String prefix = 'chem_sds',
  }) async {
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return sourcePath;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'chemicals'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetFile = File(p.join(targetDir.path, filename));

      await srcFile.copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      debugPrint('Error persisting chemical attachment: $e');
      return sourcePath;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Chemical Inventory Register (CRUD & Queries)
  // --------------------------------------------------------------------------

  /// Retrieves all chemical inventory records with optional filtering.
  Future<List<ChemicalInventoryItem>> getAllInventory({
    String? query,
    String? status,
    String? location,
    SdsExpiryStatus? expiryFilter,
  }) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM chemical_inventory';
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'ALL') {
      whereClauses.add('status = ?');
      args.add(status);
    }

    if (location != null && location.isNotEmpty && location != 'ALL') {
      whereClauses.add('storage_location = ?');
      args.add(location);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(trade_name LIKE ? OR chemical_name_th LIKE ? OR chemical_name_en LIKE ? OR cas_number LIKE ?)');
      args.addAll([q, q, q, q]);
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY id DESC';

    final res = await db.rawQuery(sql, args);
    var list = res.map((m) => ChemicalInventoryItem.fromMap(m)).toList();

    // In-memory filter for computed SDS expiry status
    if (expiryFilter != null) {
      list = list.where((item) => item.sdsStatus == expiryFilter).toList();
    }

    return list;
  }

  /// Retrieves a single chemical inventory record by ID.
  Future<ChemicalInventoryItem?> getInventoryById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'chemical_inventory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return ChemicalInventoryItem.fromMap(res.first);
  }

  /// Saves (Inserts or Updates) a chemical inventory item with file persistence.
  Future<int> saveInventory(
    ChemicalInventoryItem item, {
    String? newSdsPath,
    String? newLabelPath,
  }) async {
    final db = await _dbHelper.database;

    String? finalSdsPath = item.sdsFilePath;
    if (newSdsPath != null && newSdsPath.isNotEmpty && newSdsPath != item.sdsFilePath) {
      finalSdsPath = await persistChemicalAttachment(newSdsPath, prefix: 'sds_${item.casNumber.replaceAll(RegExp(r'[^0-9]'), '')}');
    }

    String? finalLabelPath = item.labelImagePath;
    if (newLabelPath != null && newLabelPath.isNotEmpty && newLabelPath != item.labelImagePath) {
      finalLabelPath = await persistChemicalAttachment(newLabelPath, prefix: 'label_${item.casNumber.replaceAll(RegExp(r'[^0-9]'), '')}');
    }

    final updatedItem = item.copyWith(
      sdsFilePath: finalSdsPath,
      labelImagePath: finalLabelPath,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final map = updatedItem.toMap();

    if (updatedItem.id == null || updatedItem.id == 0) {
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('chemical_inventory', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'chemical_inventory',
        map,
        where: 'id = ?',
        whereArgs: [updatedItem.id],
      );
      return updatedItem.id!;
    }
  }

  /// Deletes a chemical inventory record by ID.
  Future<int> deleteInventory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'chemical_inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetches unique list of storage locations in the system for dropdown filtering.
  Future<List<String>> getDistinctStorageLocations() async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('SELECT DISTINCT storage_location FROM chemical_inventory WHERE storage_location IS NOT NULL AND storage_location != "" ORDER BY storage_location ASC');
    return res.map((m) => (m['storage_location'] ?? '').toString()).toList();
  }

  /// Returns KPI statistics summary for the Chemical Dashboard.
  Future<({int total, int validSds, int nearExpiry, int expired, double totalQtySolidKg, double totalQtyLiquidL})> getInventoryKpiStats() async {
    final items = await getAllInventory();

    int validSds = 0;
    int nearExpiry = 0;
    int expired = 0;
    double solidKg = 0.0;
    double liquidL = 0.0;

    for (final item in items) {
      if (item.isExpired) {
        expired++;
      } else if (item.isExpiringSoon) {
        nearExpiry++;
      } else if (item.sdsStatus == SdsExpiryStatus.normal) {
        validSds++;
      }

      if (item.physicalState.toUpperCase() == 'SOLID') {
        solidKg += item.quantity;
      } else if (item.physicalState.toUpperCase() == 'LIQUID') {
        liquidL += item.quantity;
      }
    }

    return (
      total: items.length,
      validSds: validSds,
      nearExpiry: nearExpiry,
      expired: expired,
      totalQtySolidKg: solidKg,
      totalQtyLiquidL: liquidL,
    );
  }

  // --------------------------------------------------------------------------
  // 3. Form สอ.๑ (SDS 16 Sections) CRUD & Queries
  // --------------------------------------------------------------------------

  /// Retrieves all Form สอ.๑ records with optional query and status filters.
  Future<List<ChemicalSdsSor1Model>> getAllSdsSor1({
    String? query,
    String? status,
  }) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM chemical_sds_sor1';
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'ALL') {
      whereClauses.add('status = ?');
      args.add(status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(trade_name LIKE ? OR cas_number LIKE ? OR chemical_formula LIKE ?)');
      args.addAll([q, q, q]);
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY id DESC';

    final res = await db.rawQuery(sql, args);
    return res.map((m) => ChemicalSdsSor1Model.fromMap(m)).toList();
  }

  /// Retrieves a Form สอ.๑ record by primary key ID.
  Future<ChemicalSdsSor1Model?> getSdsSor1ById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'chemical_sds_sor1',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return ChemicalSdsSor1Model.fromMap(res.first);
  }

  /// Retrieves a Form สอ.๑ record by linked chemical_inventory ID.
  Future<ChemicalSdsSor1Model?> getSdsSor1ByInventoryId(int inventoryId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'chemical_sds_sor1',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return ChemicalSdsSor1Model.fromMap(res.first);
  }

  /// Retrieves a Form สอ.๑ record by CAS number.
  Future<ChemicalSdsSor1Model?> getSdsSor1ByCas(String cas) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'chemical_sds_sor1',
      where: 'cas_number = ?',
      whereArgs: [cas],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return ChemicalSdsSor1Model.fromMap(res.first);
  }

  /// Saves (Inserts or Updates) a Form สอ.๑ record in SQLite.
  Future<int> saveSdsSor1(ChemicalSdsSor1Model item) async {
    final db = await _dbHelper.database;

    final updated = item.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );

    final map = updated.toMap();

    if (updated.id == null || updated.id == 0) {
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('chemical_sds_sor1', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'chemical_sds_sor1',
        map,
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      return updated.id!;
    }
  }

  /// Deletes a Form สอ.๑ record by ID.
  Future<int> deleteSdsSor1(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'chemical_sds_sor1',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------------------------------------------------
  // 4. Form สอ.๓ ๒๕๖๕ (Atmospheric Measurement) CRUD & Queries
  // --------------------------------------------------------------------------

  /// Retrieves all Form สอ.๓ measurement records with optional search query and evaluation filter.
  Future<List<ChemicalMeasurementSor3Model>> getAllMeasurementSor3({
    String? query,
    String? resultFilter,
  }) async {
    final db = await _dbHelper.database;
    String sql = 'SELECT * FROM chemical_measurement_sor3';
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (resultFilter != null && resultFilter.isNotEmpty && resultFilter != 'ALL') {
      whereClauses.add('evaluation_result = ?');
      args.add(resultFilter);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(document_no LIKE ? OR chemical_name LIKE ? OR cas_number LIKE ? OR workplace_area LIKE ? OR service_provider_name LIKE ?)');
      args.addAll([q, q, q, q, q]);
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    sql += ' ORDER BY id DESC';

    final res = await db.rawQuery(sql, args);
    return res.map((m) => ChemicalMeasurementSor3Model.fromMap(m)).toList();
  }

  /// Retrieves a single Form สอ.๓ measurement record by ID.
  Future<ChemicalMeasurementSor3Model?> getMeasurementSor3ById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'chemical_measurement_sor3',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return ChemicalMeasurementSor3Model.fromMap(res.first);
  }

  /// Saves (Inserts or Updates) a Form สอ.๓ measurement record with optional certificate file persistence.
  Future<int> saveMeasurementSor3(
    ChemicalMeasurementSor3Model item, {
    String? newCertPath,
  }) async {
    final db = await _dbHelper.database;

    String? finalCertPath = item.certificatePdfPath;
    if (newCertPath != null && newCertPath.isNotEmpty && newCertPath != item.certificatePdfPath) {
      finalCertPath = await persistChemicalAttachment(newCertPath, prefix: 'sor3_cert_${item.documentNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}');
    }

    final updated = item.copyWith(
      certificatePdfPath: finalCertPath,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final map = updated.toMap();

    if (updated.id == null || updated.id == 0) {
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('chemical_measurement_sor3', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'chemical_measurement_sor3',
        map,
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      return updated.id!;
    }
  }

  /// Deletes a Form สอ.๓ measurement record by ID.
  Future<int> deleteMeasurementSor3(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'chemical_measurement_sor3',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns KPI statistics summary for Form สอ.๓ Measurements.
  Future<({int total, int passCount, int actionLevelCount, int failCount})> getMeasurementKpiStats() async {
    final items = await getAllMeasurementSor3();

    int pass = 0;
    int actionLevel = 0;
    int fail = 0;

    for (final item in items) {
      if (item.isPass) {
        pass++;
      } else if (item.isActionLevel) {
        actionLevel++;
      } else {
        fail++;
      }
    }

    return (
      total: items.length,
      passCount: pass,
      actionLevelCount: actionLevel,
      failCount: fail,
    );
  }

  // --------------------------------------------------------------------------
  // 5. Master Data 1,516 Chemicals & 324 TLVs Lookups
  // --------------------------------------------------------------------------

  /// Fast Autocomplete Search across 1,516 hazardous substances.
  List<ChemicalMasterItem> searchMasterChemicals(String query, {int limit = 25}) {
    return Chemical1516MasterData.search(query, limit: limit);
  }

  /// Exact CAS lookup in 1,516 master database.
  ChemicalMasterItem? getMasterChemicalByCas(String cas) {
    return Chemical1516MasterData.findByCas(cas);
  }

  /// Fast search across 324 occupational exposure TLVs.
  List<ChemicalTlvItem> searchTlv(String query, {int limit = 20}) {
    return Chemical324TlvData.search(query, limit: limit);
  }

  /// Exact CAS lookup in 324 TLV standards database.
  ChemicalTlvItem? getTlvByCas(String cas) {
    return Chemical324TlvData.findByCas(cas);
  }

  // --------------------------------------------------------------------------
  // 6. Thai Royal Gazette Legal Reference Library
  // --------------------------------------------------------------------------

  List<ChemicalLawItem> getAllLaws() => ChemicalLawsData.laws;

  List<ChemicalLawItem> searchLaws(String query) => ChemicalLawsData.search(query);

  ChemicalLawItem? getLawById(String id) => ChemicalLawsData.getById(id);
}
