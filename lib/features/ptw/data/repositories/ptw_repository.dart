import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/ptw_status.dart';
import '../models/ptw_model.dart';
import '../models/gas_test_log_model.dart';
import '../models/confined_role_model.dart';
import '../models/fire_watch_model.dart';
import '../models/loto_isolation_model.dart';
import '../models/ptw_checklist_model.dart';
import '../models/ptw_approval_model.dart';
import '../models/ptw_kpi_summary_model.dart';

/// SQLite Data Repository for Permit to Work (PTW) Module
class PtwRepository {
  final DatabaseHelper _dbHelper;

  PtwRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // ====================================================
  // PTW Permit Master CRUD & Queries
  // ====================================================

  /// Fetch permits with optional filters (Search query, Risk type, Status, Department, Date range)
  Future<List<PtwModel>> getAllPermits({
    String? searchQuery,
    HighRiskType? riskTypeFilter,
    PtwStatus? statusFilter,
    String? departmentFilter,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('(ptw_number LIKE ? OR work_title LIKE ? OR applicant_name LIKE ? OR specific_location LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    if (riskTypeFilter != null) {
      whereClauses.add('primary_risk_type = ?');
      whereArgs.add(riskTypeFilter.toDbCode());
    }

    if (statusFilter != null) {
      whereClauses.add('status = ?');
      whereArgs.add(statusFilter.toDbCode());
    }

    if (departmentFilter != null && departmentFilter.trim().isNotEmpty && departmentFilter != 'ALL') {
      whereClauses.add('applicant_department = ?');
      whereArgs.add(departmentFilter.trim());
    }

    if (startDate != null && startDate.isNotEmpty) {
      whereClauses.add('work_start_date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null && endDate.isNotEmpty) {
      whereClauses.add('work_start_date <= ?');
      whereArgs.add(endDate);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final maps = await db.query(
      'ptw_permits',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC, id DESC',
    );

    if (maps.isEmpty && whereClauses.isEmpty) {
      final totalCnt = await db.rawQuery('SELECT COUNT(*) as cnt FROM ptw_permits');
      if ((totalCnt.first['cnt'] as int? ?? 0) == 0) {
        await seedInitialPtw();
        return await getAllPermits();
      }
    }

    final List<PtwModel> permits = [];
    for (final map in maps) {
      final ptwNumber = map['ptw_number']?.toString() ?? '';
      final childData = await _fetchChildDatasets(db, ptwNumber);
      permits.add(PtwModel.fromMap(
        map,
        gasLogs: childData.gasLogs,
        roles: childData.roles,
        fireWatchData: childData.fireWatch,
        lotoItems: childData.lotoItems,
        checklists: childData.checklists,
        approvals: childData.approvals,
      ));
    }
    return permits;
  }

  /// Get single permit by unique PTW Number with all relational child datasets
  Future<PtwModel?> getPermitByNumber(String ptwNumber) async {
    final db = await _db;
    final maps = await db.query(
      'ptw_permits',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final childData = await _fetchChildDatasets(db, ptwNumber);
    return PtwModel.fromMap(
      maps.first,
      gasLogs: childData.gasLogs,
      roles: childData.roles,
      fireWatchData: childData.fireWatch,
      lotoItems: childData.lotoItems,
      checklists: childData.checklists,
      approvals: childData.approvals,
    );
  }

  /// Get single permit by database auto-increment ID
  Future<PtwModel?> getPermitById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'ptw_permits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final ptwNumber = maps.first['ptw_number']?.toString() ?? '';
    final childData = await _fetchChildDatasets(db, ptwNumber);
    return PtwModel.fromMap(
      maps.first,
      gasLogs: childData.gasLogs,
      roles: childData.roles,
      fireWatchData: childData.fireWatch,
      lotoItems: childData.lotoItems,
      checklists: childData.checklists,
      approvals: childData.approvals,
    );
  }

  /// Save or update a Permit and all its relational child items within a database transaction
  Future<PtwModel> savePermit(PtwModel permit) async {
    final db = await _db;
    return await db.transaction<PtwModel>((txn) async {
      final nowStr = DateTime.now().toIso8601String();
      final masterMap = permit.toMap();

      // Check if existing record
      final existing = await txn.query(
        'ptw_permits',
        columns: ['id', 'created_at'],
        where: 'ptw_number = ?',
        whereArgs: [permit.ptwNumber],
      );

      int permitId;
      if (existing.isNotEmpty) {
        permitId = (existing.first['id'] as num).toInt();
        masterMap['updated_at'] = nowStr;
        masterMap['created_at'] = existing.first['created_at'] ?? nowStr;
        await txn.update(
          'ptw_permits',
          masterMap,
          where: 'id = ?',
          whereArgs: [permitId],
        );
      } else {
        masterMap['created_at'] = permit.createdAt ?? nowStr;
        masterMap['updated_at'] = nowStr;
        permitId = await txn.insert('ptw_permits', masterMap);
      }

      final ptwNo = permit.ptwNumber;

      // 1. Gas Test Logs
      if (permit.gasTestLogs.isNotEmpty) {
        for (final gasLog in permit.gasTestLogs) {
          final gasMap = gasLog.toMap();
          gasMap['ptw_number'] = ptwNo;
          await txn.insert(
            'ptw_gas_test_logs',
            gasMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 2. Confined Space Roles
      if (permit.confinedRoles.isNotEmpty) {
        for (final role in permit.confinedRoles) {
          final roleMap = role.toMap();
          roleMap['ptw_number'] = ptwNo;
          await txn.insert(
            'ptw_confined_roles',
            roleMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 3. Fire Watch
      if (permit.fireWatch != null) {
        final fwMap = permit.fireWatch!.toMap();
        fwMap['ptw_number'] = ptwNo;
        await txn.insert(
          'ptw_fire_watches',
          fwMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. LOTO Isolations
      if (permit.lotoIsolations.isNotEmpty) {
        for (final loto in permit.lotoIsolations) {
          final lotoMap = loto.toMap();
          lotoMap['ptw_number'] = ptwNo;
          await txn.insert(
            'ptw_loto_isolations',
            lotoMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 5. Checklists
      if (permit.checklistItems.isNotEmpty) {
        await txn.delete('ptw_checklists', where: 'ptw_number = ?', whereArgs: [ptwNo]);
        for (final item in permit.checklistItems) {
          final chkMap = item.toMap();
          chkMap['ptw_number'] = ptwNo;
          await txn.insert('ptw_checklists', chkMap);
        }
      }

      // 6. Approval Logs
      if (permit.approvalLogs.isNotEmpty) {
        for (final app in permit.approvalLogs) {
          final appMap = app.toMap();
          appMap['ptw_number'] = ptwNo;
          await txn.insert(
            'ptw_approval_logs',
            appMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      return permit.copyWith(id: permitId, updatedAt: nowStr);
    });
  }

  /// Delete a permit and all associated child data
  Future<int> deletePermit(String ptwNumber) async {
    final db = await _db;
    return await db.transaction<int>((txn) async {
      await txn.delete('ptw_gas_test_logs', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      await txn.delete('ptw_confined_roles', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      await txn.delete('ptw_fire_watches', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      await txn.delete('ptw_loto_isolations', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      await txn.delete('ptw_checklists', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      await txn.delete('ptw_approval_logs', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      return await txn.delete('ptw_permits', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
    });
  }

  // ====================================================
  // Child Relation Operations
  // ====================================================

  /// Add a new Gas Test log to a permit
  Future<GasTestLogModel> addGasTestLog(String ptwNumber, GasTestLogModel log) async {
    final db = await _db;
    final logMap = log.toMap();
    logMap['ptw_number'] = ptwNumber;
    logMap['created_at'] = DateTime.now().toIso8601String();
    final id = await db.insert('ptw_gas_test_logs', logMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return log.copyWith(id: id);
  }

  /// Fetch all gas test logs for a permit
  Future<List<GasTestLogModel>> getGasTestLogs(String ptwNumber) async {
    final db = await _db;
    final maps = await db.query(
      'ptw_gas_test_logs',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'test_timestamp ASC, id ASC',
    );
    return maps.map((m) => GasTestLogModel.fromMap(m)).toList();
  }

  /// Save or replace Confined Space 4 roles
  Future<void> saveConfinedRoles(String ptwNumber, List<ConfinedRoleModel> roles) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('ptw_confined_roles', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      for (final role in roles) {
        final map = role.toMap();
        map['ptw_number'] = ptwNumber;
        await txn.insert('ptw_confined_roles', map);
      }
    });
  }

  /// Save or update Fire Watch record
  Future<void> saveFireWatch(String ptwNumber, FireWatchModel fireWatch) async {
    final db = await _db;
    final map = fireWatch.toMap();
    map['ptw_number'] = ptwNumber;
    await db.insert('ptw_fire_watches', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Save or replace LOTO isolation points
  Future<void> saveLotoIsolations(String ptwNumber, List<LotoIsolationModel> isolations) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('ptw_loto_isolations', where: 'ptw_number = ?', whereArgs: [ptwNumber]);
      for (final item in isolations) {
        final map = item.toMap();
        map['ptw_number'] = ptwNumber;
        await txn.insert('ptw_loto_isolations', map);
      }
    });
  }

  /// Toggle Zero Energy Verification on a LOTO point
  Future<void> toggleLotoZeroEnergy(String isolationId, bool isVerified, String verifiedBy) async {
    final db = await _db;
    final nowStr = DateTime.now().toIso8601String();
    await db.update(
      'ptw_loto_isolations',
      {
        'is_zero_energy_verified': isVerified ? 1 : 0,
        'verified_by': verifiedBy,
        'verified_timestamp': isVerified ? nowStr : null,
      },
      where: 'isolation_id = ?',
      whereArgs: [isolationId],
    );
  }

  /// Toggle De-isolation on a LOTO point at permit closure
  Future<void> toggleLotoDeIsolation(String isolationId, bool isDeIsolated, String deIsolatedBy) async {
    final db = await _db;
    final nowStr = DateTime.now().toIso8601String();
    await db.update(
      'ptw_loto_isolations',
      {
        'is_de_isolated': isDeIsolated ? 1 : 0,
        'de_isolated_by': deIsolatedBy,
        'de_isolated_timestamp': isDeIsolated ? nowStr : null,
      },
      where: 'isolation_id = ?',
      whereArgs: [isolationId],
    );
  }

  /// Add an audit log entry for status change / sign-off
  Future<PtwApprovalModel> addApprovalLog(PtwApprovalModel approval) async {
    final db = await _db;
    final map = approval.toMap();
    final id = await db.insert('ptw_approval_logs', map, conflictAlgorithm: ConflictAlgorithm.replace);
    return approval.copyWith(id: id);
  }

  /// Update Permit Status and record audit log
  Future<void> updatePermitStatus(
    String ptwNumber,
    PtwStatus newStatus, {
    String? comments,
    String? approverName,
    String? approverRole,
    String? signaturePath,
  }) async {
    final db = await _db;
    final nowStr = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'ptw_permits',
        {
          'status': newStatus.toDbCode(),
          'updated_at': nowStr,
        },
        where: 'ptw_number = ?',
        whereArgs: [ptwNumber],
      );

      final approvalLog = PtwApprovalModel(
        approvalId: 'APR-${DateTime.now().millisecondsSinceEpoch}',
        ptwNumber: ptwNumber,
        approvalStage: newStatus.toDbCode(),
        approverRole: approverRole ?? 'SYSTEM',
        approverName: approverName ?? 'Admin',
        action: 'UPDATE_STATUS_TO_${newStatus.toDbCode()}',
        timestamp: nowStr,
        comments: comments,
        signaturePath: signaturePath,
      );
      await txn.insert('ptw_approval_logs', approvalLog.toMap());
    });
  }

  // ====================================================
  // Dashboard & KPI Analytics Engine
  // ====================================================

  /// Compute high-performance KPI summary directly from SQLite
  Future<PtwKpiSummaryModel> getKpiSummary() async {
    final db = await _db;

    // 1. Master permit status & risk counts
    final permitMaps = await db.query('ptw_permits');
    final int total = permitMaps.length;
    int active = 0;
    int pending = 0;
    int draft = 0;
    int extended = 0;
    int closed = 0;
    int overdue = 0;
    int hotWork = 0;
    int confined = 0;
    int height = 0;
    int electrical = 0;
    int excavation = 0;

    final now = DateTime.now();

    for (final map in permitMaps) {
      final status = PtwStatus.fromDbCode(map['status']?.toString());
      final risk = HighRiskType.fromDbCode(map['primary_risk_type']?.toString());

      switch (status) {
        case PtwStatus.active:
          active++;
          break;
        case PtwStatus.pendingApproval:
          pending++;
          break;
        case PtwStatus.draft:
          draft++;
          break;
        case PtwStatus.extendedHandover:
          extended++;
          break;
        case PtwStatus.closedCancelled:
          closed++;
          break;
      }

      switch (risk) {
        case HighRiskType.hotWork:
          hotWork++;
          break;
        case HighRiskType.confinedSpace:
          confined++;
          break;
        case HighRiskType.workingAtHeight:
          height++;
          break;
        case HighRiskType.electricalLoto:
          electrical++;
          break;
        case HighRiskType.excavationLifting:
          excavation++;
          break;
      }

      // Check overdue for active & extended permits
      if (status == PtwStatus.active || status == PtwStatus.extendedHandover) {
        final endDate = map['work_end_date']?.toString() ?? '';
        final endTime = map['work_end_time']?.toString() ?? '';
        final extHours = (map['extension_hours'] as num?)?.toInt() ?? 0;
        try {
          final endDt = DateTime.parse('${endDate}T$endTime:00').add(Duration(hours: extHours));
          if (now.isAfter(endDt)) {
            overdue++;
          }
        } catch (_) {}
      }
    }

    // 2. Gas test anomalies (is_safe == 0)
    final gasAnomalyRes = await db.rawQuery('SELECT COUNT(*) as count FROM ptw_gas_test_logs WHERE is_safe = 0');
    final int gasAnomalies = (gasAnomalyRes.first['count'] as num?)?.toInt() ?? 0;

    // 3. LOTO pending de-isolation in active permits
    final lotoPendingRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ptw_loto_isolations l
      INNER JOIN ptw_permits p ON l.ptw_number = p.ptw_number
      WHERE l.is_de_isolated = 0 AND p.status IN ('ACTIVE', 'EXTENDED_HANDOVER')
    ''');
    final int lotoPending = (lotoPendingRes.first['count'] as num?)?.toInt() ?? 0;

    // 4. Compliance Rate Calculation
    double complianceRate = 100.0;
    if (total > 0) {
      final int nonCompliantFactors = overdue + gasAnomalies;
      final double penalty = (nonCompliantFactors / total) * 100.0;
      complianceRate = (100.0 - penalty).clamp(0.0, 100.0);
    }

    return PtwKpiSummaryModel(
      totalPermits: total,
      activeCount: active,
      pendingCount: pending,
      draftCount: draft,
      extendedCount: extended,
      closedCount: closed,
      overdueCount: overdue,
      hotWorkCount: hotWork,
      confinedSpaceCount: confined,
      workingAtHeightCount: height,
      electricalLotoCount: electrical,
      excavationLiftingCount: excavation,
      gasTestAnomalyCount: gasAnomalies,
      lotoPendingDeIsolationCount: lotoPending,
      complianceRatePercent: complianceRate,
    );
  }

  /// Generate a unique, formatted PTW Number (e.g. PTW-20260901-001)
  Future<String> generateNextPtwNumber(HighRiskType riskType) async {
    final db = await _db;
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final datePrefix = '$year$month$day';

    final prefix = 'PTW-$datePrefix';
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ptw_permits WHERE ptw_number LIKE ?',
      ['$prefix%'],
    );
    final count = ((res.first['count'] as num?)?.toInt() ?? 0) + 1;
    final seq = count.toString().padLeft(3, '0');
    return '$prefix-$seq';
  }

  // ====================================================
  // Private Helper: Fetch All Child Datasets
  // ====================================================
  Future<_PtwChildData> _fetchChildDatasets(Database db, String ptwNumber) async {
    // Gas Logs
    final gasMaps = await db.query(
      'ptw_gas_test_logs',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'test_timestamp ASC, id ASC',
    );
    final gasLogs = gasMaps.map((m) => GasTestLogModel.fromMap(m)).toList();

    // Confined Roles
    final roleMaps = await db.query(
      'ptw_confined_roles',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'id ASC',
    );
    final roles = roleMaps.map((m) => ConfinedRoleModel.fromMap(m)).toList();

    // Fire Watch
    final fwMaps = await db.query(
      'ptw_fire_watches',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      limit: 1,
    );
    final fireWatch = fwMaps.isNotEmpty ? FireWatchModel.fromMap(fwMaps.first) : null;

    // LOTO Isolations
    final lotoMaps = await db.query(
      'ptw_loto_isolations',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'id ASC',
    );
    final lotoItems = lotoMaps.map((m) => LotoIsolationModel.fromMap(m)).toList();

    // Checklists
    final chkMaps = await db.query(
      'ptw_checklists',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'id ASC',
    );
    final checklists = chkMaps.map((m) => PtwChecklistModel.fromMap(m)).toList();

    // Approval Logs
    final appMaps = await db.query(
      'ptw_approval_logs',
      where: 'ptw_number = ?',
      whereArgs: [ptwNumber],
      orderBy: 'timestamp ASC, id ASC',
    );
    final approvals = appMaps.map((m) => PtwApprovalModel.fromMap(m)).toList();

    return _PtwChildData(
      gasLogs: gasLogs,
      roles: roles,
      fireWatch: fireWatch,
      lotoItems: lotoItems,
      checklists: checklists,
      approvals: approvals,
    );
  }

  // =========================================================================
  // INITIAL SEEDING (REAL STATUTORY DATA)
  // =========================================================================

  Future<void> seedInitialPtw() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final samplePermit = PtwModel(
      ptwNumber: 'PTW-2026-001',
      workTitle: 'งานเชื่อมตัดโครงสร้างเหล็กซ่อมบำรุงสายพานลำเลียง Main Conveyor Line A',
      workDescription: 'เชื่อมเสริมความแข็งแรงโครงสร้างเหล็กสายพานลำเลียงชิ้นส่วน พร้อมติดตั้งฉากกั้นสะเก็ดไฟและถังดับเพลิงประจำจุด',
      primaryRiskType: HighRiskType.hotWork,
      status: PtwStatus.active,
      applicantName: 'นายสมเกียรติ มั่นคง',
      applicantDepartment: 'ฝ่ายซ่อมบำรุงเครื่องจักร',
      applicantPhone: '089-123-4567',
      applicantType: 'EMPLOYEE',
      plantArea: 'อาคารโรงงาน 1 (Main Production Hall)',
      specificLocation: 'สายพานลำเลียง Line A บริเวณหน้าเตาชุบ',
      workerCount: 3,
      workerNames: const ['นายสมเกียรติ มั่นคง', 'นายประสิทธิ์ ระวังภัย', 'นายวิชัย ว่องไว'],
      requestDate: todayStr,
      workStartDate: todayStr,
      workEndDate: todayStr,
      workStartTime: '08:30',
      workEndTime: '17:00',
      emergencyRescuePlan: 'กรณีเกิดเหตุเพลิงไหม้ ใช้ถังดับเพลิง CO2/Dry Chemical ประจำจุด หากควบคุมไม่ได้ให้กดปุ่ม Fire Alarm เสา 14 และอพยพไปจุดรวมพล 1',
      requiredPpeList: 'หน้ากากเชื่อม, ถุงมือหนังยาว, แว่นตานิรภัย, รองเท้าหัวเหล็ก, ที่อุดหูลดเสียง',
      specialPrecautions: 'เคลื่อนย้ายสารไวไฟในรัศมี 10 เมตร, กางผ้ากันไฟ (Fire Blanket) คลุมรอบพื้นที่, มีผู้เฝ้าระวังไฟ (Fire Watch) ประจำตลอดเวลาทำงานและหลังเสร็จงาน 30 นาที',
      authorizerName: 'นายสมชาย เจริญสุขวัฒนา',
      safetyOfficerName: 'นางสาวพัชราภรณ์ สุขสวัสดิ์ (จป.วิชาชีพ)',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await savePermit(samplePermit);
  }
}

class _PtwChildData {
  final List<GasTestLogModel> gasLogs;
  final List<ConfinedRoleModel> roles;
  final FireWatchModel? fireWatch;
  final List<LotoIsolationModel> lotoItems;
  final List<PtwChecklistModel> checklists;
  final List<PtwApprovalModel> approvals;

  const _PtwChildData({
    required this.gasLogs,
    required this.roles,
    this.fireWatch,
    required this.lotoItems,
    required this.checklists,
    required this.approvals,
  });
}
