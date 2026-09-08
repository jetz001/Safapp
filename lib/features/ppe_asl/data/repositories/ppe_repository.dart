import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/ppe_item_model.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../../domain/models/asl_supplier_model.dart';

class PpeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────────────────────
  // 1. PPE Master Items
  // ─────────────────────────────────────────────────────────────

  Future<List<PpeItem>> getAllPpeItems({
    String? category,
    String? searchQuery,
    bool? lowStockOnly,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = "status = 'ACTIVE'";
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'ALL') {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClause += ' AND (name LIKE ? OR code LIKE ? OR standard_cert LIKE ?)';
      whereArgs.addAll([query, query, query]);
    }

    if (lowStockOnly == true) {
      whereClause += ' AND current_stock <= min_stock';
    }

    final res = await db.query(
      'ppe_items',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'category ASC, code ASC',
    );

    return res.map((e) => PpeItem.fromMap(e)).toList();
  }

  Future<PpeItem?> getPpeItemById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query('ppe_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return PpeItem.fromMap(res.first);
  }

  Future<int> insertPpeItem(PpeItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('ppe_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updatePpeItem(PpeItem item) async {
    final db = await _dbHelper.database;
    return await db.update('ppe_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deletePpeItem(int id) async {
    final db = await _dbHelper.database;
    // Soft delete to preserve historical transactions
    return await db.update('ppe_items', {'status': 'INACTIVE'}, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Stock Card / Transactions
  // ─────────────────────────────────────────────────────────────

  Future<List<PpeTransaction>> getTransactions({
    int? ppeId,
    String? type,
    String? searchQuery,
    int limit = 200,
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    List<String> conditions = [];
    if (ppeId != null) {
      conditions.add('ppe_id = ?');
      whereArgs.add(ppeId);
    }
    if (type != null && type.isNotEmpty && type != 'ALL') {
      conditions.add('transaction_type = ?');
      whereArgs.add(type);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      conditions.add('(transaction_no LIKE ? OR ppe_name LIKE ? OR recipient_name LIKE ? OR department LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    final res = await db.query(
      'ppe_stock_transactions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'transaction_date DESC, id DESC',
      limit: limit,
    );

    return res.map((e) => PpeTransaction.fromMap(e)).toList();
  }

  Future<String> generateNextTransactionNo() async {
    final now = DateTime.now();
    final prefix = 'TX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ppe_stock_transactions WHERE transaction_no LIKE '$prefix%'",
    );
    final count = (res.first['count'] as int? ?? 0) + 1;
    return '$prefix-${count.toString().padLeft(3, '0')}';
  }

  Future<int> recordTransaction(PpeTransaction tx) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Fetch current stock
      final itemRes = await txn.query('ppe_items', where: 'id = ?', whereArgs: [tx.ppeId], limit: 1);
      if (itemRes.isEmpty) {
        throw Exception('ไม่พบรายการอุปกรณ์ PPE รหัส ID ${tx.ppeId}');
      }
      final currentStock = (itemRes.first['current_stock'] as num?)?.toInt() ?? 0;

      // 2. Calculate new stock
      int newStock = currentStock;
      if (tx.transactionType == PpeTransactionType.stockIn || tx.transactionType == PpeTransactionType.returned) {
        newStock += tx.quantity;
      } else if (tx.transactionType == PpeTransactionType.stockOut) {
        newStock -= tx.quantity;
        if (newStock < 0) newStock = 0; // Prevent negative
      } else if (tx.transactionType == PpeTransactionType.adjust) {
        newStock = tx.quantity; // Adjust directly sets balance
      }

      // 3. Update PPE current_stock
      await txn.update(
        'ppe_items',
        {
          'current_stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tx.ppeId],
      );

      // 4. Insert transaction with updated balanceAfter
      final finalTx = PpeTransaction(
        id: tx.id,
        transactionNo: tx.transactionNo.isNotEmpty ? tx.transactionNo : await generateNextTransactionNo(),
        ppeId: tx.ppeId,
        ppeCode: tx.ppeCode,
        ppeName: tx.ppeName,
        transactionType: tx.transactionType,
        quantity: tx.quantity,
        balanceAfter: newStock,
        transactionDate: tx.transactionDate,
        recipientType: tx.recipientType,
        recipientId: tx.recipientId,
        recipientName: tx.recipientName,
        department: tx.department,
        cpoMeetingRef: tx.cpoMeetingRef,
        ptwRef: tx.ptwRef,
        supplierId: tx.supplierId,
        supplierName: tx.supplierName,
        notes: tx.notes,
        recordedBy: tx.recordedBy,
        createdAt: DateTime.now().toIso8601String(),
      );

      return await txn.insert('ppe_stock_transactions', finalTx.toMap());
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Approved Supplier List (ASL)
  // ─────────────────────────────────────────────────────────────

  Future<List<AslSupplier>> getAllSuppliers({String? status, String? searchQuery}) async {
    final db = await _dbHelper.database;
    String whereClause = "status = 'ACTIVE'";
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status != 'ALL') {
      whereClause += ' AND evaluation_status = ?';
      whereArgs.add(status);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClause += ' AND (company_name LIKE ? OR code LIKE ? OR supplied_categories LIKE ?)';
      whereArgs.addAll([query, query, query]);
    }

    final res = await db.query(
      'ppe_suppliers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'rating DESC, company_name ASC',
    );

    return res.map((e) => AslSupplier.fromMap(e)).toList();
  }

  Future<int> insertSupplier(AslSupplier supplier) async {
    final db = await _dbHelper.database;
    return await db.insert('ppe_suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSupplier(AslSupplier supplier) async {
    final db = await _dbHelper.database;
    return await db.update('ppe_suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await _dbHelper.database;
    return await db.update('ppe_suppliers', {'status': 'INACTIVE'}, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Analytics & Summary Metrics
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await _dbHelper.database;

    final totalItemsRes = await db.rawQuery(
      "SELECT COUNT(*) as total, SUM(current_stock) as total_units, SUM(current_stock * unit_cost) as total_val FROM ppe_items WHERE status = 'ACTIVE'",
    );
    final totalItems = (totalItemsRes.first['total'] as int?) ?? 0;
    final totalUnits = (totalItemsRes.first['total_units'] as num?)?.toInt() ?? 0;
    final totalValue = (totalItemsRes.first['total_val'] as num?)?.toDouble() ?? 0.0;

    final lowStockRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ppe_items WHERE status = 'ACTIVE' AND current_stock <= min_stock AND current_stock > 0",
    );
    final lowStockCount = (lowStockRes.first['count'] as int?) ?? 0;

    final outOfStockRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ppe_items WHERE status = 'ACTIVE' AND current_stock <= 0",
    );
    final outOfStockCount = (outOfStockRes.first['count'] as int?) ?? 0;

    final aslCountRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ppe_suppliers WHERE status = 'ACTIVE' AND evaluation_status = 'APPROVED'",
    );
    final approvedSupplierCount = (aslCountRes.first['count'] as int?) ?? 0;

    // Monthly issuance count (current month)
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final issuedRes = await db.rawQuery(
      "SELECT SUM(quantity) as total_issued FROM ppe_stock_transactions WHERE transaction_type = 'OUT' AND transaction_date LIKE '$monthPrefix%'",
    );
    final monthlyIssuedCount = (issuedRes.first['total_issued'] as num?)?.toInt() ?? 0;

    return {
      'totalItems': totalItems,
      'totalUnits': totalUnits,
      'totalValue': totalValue,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'approvedSupplierCount': approvedSupplierCount,
      'monthlyIssuedCount': monthlyIssuedCount,
    };
  }
}
