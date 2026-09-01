import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safety_superapp/core/database/database_helper.dart';
import 'package:safety_superapp/features/environment/data/environment_repository.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_session_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';

/// Test wrapper for DatabaseHelper injecting an in-memory test database.
class TestDatabaseHelper implements DatabaseHelper {
  final Database _testDb;

  TestDatabaseHelper(this._testDb);

  @override
  Future<Database> get database async => _testDb;

  @override
  Future<void> close() async {
    await _testDb.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database testDb;
  late EnvironmentRepository repo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (db, version) async {
          // Create required environment tables for tests
          await db.execute('''
            CREATE TABLE IF NOT EXISTS environment_standards_master (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              standard_id TEXT NOT NULL UNIQUE,
              factor_type TEXT NOT NULL,
              category_code TEXT NOT NULL,
              category_name_th TEXT NOT NULL,
              category_name_en TEXT NOT NULL,
              task_description TEXT NOT NULL,
              min_lux REAL,
              max_lux REAL,
              surrounding_lux_ratio REAL,
              noise_twa_limit_dba REAL,
              noise_action_level_dba REAL,
              noise_ceiling_limit_dba REAL,
              noise_peak_limit_db REAL,
              workload_type TEXT,
              metabolic_rate_kcal_hr REAL,
              wbgt_limit_celsius REAL,
              reference_law_title TEXT NOT NULL,
              reference_article TEXT NOT NULL,
              notes TEXT,
              sort_order INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS environment_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id TEXT NOT NULL UNIQUE,
              session_title TEXT NOT NULL,
              session_year_be INTEGER NOT NULL,
              session_year_ad INTEGER NOT NULL,
              measurement_date TEXT NOT NULL,
              report_received_date TEXT,
              posting_deadline TEXT,
              submission_deadline TEXT,
              location_plant TEXT NOT NULL,
              workplace_name TEXT NOT NULL,
              workplace_address TEXT,
              objective TEXT NOT NULL,
              subcontractor_type TEXT NOT NULL,
              subcontractor_id TEXT,
              subcontractor_company_name TEXT NOT NULL,
              subcontractor_reg_number TEXT NOT NULL,
              surveyor_name TEXT NOT NULL,
              surveyor_license_no TEXT,
              certifier_name TEXT NOT NULL,
              certifier_reg_no TEXT,
              pdf_report_path TEXT,
              calibration_cert_paths TEXT,
              subcontractor_license_path TEXT,
              site_photo_paths TEXT,
              status TEXT NOT NULL DEFAULT 'PLANNED',
              notes TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS environment_measurement_points (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              point_id TEXT NOT NULL UNIQUE,
              session_id TEXT NOT NULL,
              factor_type TEXT NOT NULL,
              department TEXT NOT NULL,
              location_name TEXT NOT NULL,
              task_or_machine_name TEXT,
              evaluation_status TEXT NOT NULL DEFAULT 'PASS',
              notes TEXT,
              capa_id TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
              light_category_code TEXT,
              light_task_description TEXT,
              light_measured_lux REAL,
              light_standard_min_lux REAL,
              light_surrounding_lux REAL,
              light_is_compliant INTEGER,
              noise_measurement_type TEXT,
              noise_measured_dba REAL,
              noise_peak_db REAL,
              noise_exposure_duration_hours REAL,
              noise_dose_percent REAL,
              noise_standard_twa_limit REAL DEFAULT 86.0,
              noise_action_level_threshold REAL DEFAULT 85.0,
              noise_continuous_ceiling_limit REAL DEFAULT 115.0,
              noise_peak_limit REAL DEFAULT 140.0,
              noise_is_hcp_required INTEGER DEFAULT 0,
              noise_evaluation_tier TEXT,
              heat_solar_exposure TEXT,
              heat_nwb_celsius REAL,
              heat_gt_celsius REAL,
              heat_db_celsius REAL,
              heat_calculated_wbgt REAL,
              heat_workload_type TEXT,
              heat_metabolic_rate_kcal_hr REAL,
              heat_standard_limit_wbgt REAL,
              heat_is_compliant INTEGER,
              FOREIGN KEY (session_id) REFERENCES environment_sessions(session_id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS environment_capa (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              capa_id TEXT NOT NULL UNIQUE,
              point_id TEXT,
              session_id TEXT NOT NULL,
              factor_type TEXT NOT NULL,
              action_title TEXT NOT NULL,
              hazard_description TEXT NOT NULL,
              root_cause TEXT NOT NULL,
              engineering_control TEXT,
              administrative_control TEXT,
              ppe_control TEXT,
              pic_name TEXT NOT NULL,
              pic_department TEXT,
              target_date TEXT NOT NULL,
              completed_date TEXT,
              status TEXT NOT NULL DEFAULT 'PENDING',
              hearing_program_enrolled INTEGER DEFAULT 0,
              evidence_file_path TEXT,
              supervisor_acknowledged_date TEXT,
              notes TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (session_id) REFERENCES environment_sessions(session_id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    repo = EnvironmentRepository(dbHelper: TestDatabaseHelper(testDb));
  });

  tearDown(() async {
    await testDb.close();
  });

  // =========================================================================
  // 1. Master Standards Tests
  // =========================================================================
  group('1. Master Standards Queries', () {
    test('getAllStandards fallback returns static data when DB is empty', () async {
      final standards = await repo.getAllStandards();
      expect(standards.length, greaterThanOrEqualTo(14));
    });

    test('getStandardById retrieves specific standard', () async {
      final item = await repo.getStandardById('LIGHT-CAT1-02');
      expect(item, isNotNull);
      expect(item!.minLux, 50.0);
    });
  });

  // =========================================================================
  // 2. Session CRUD Tests
  // =========================================================================
  group('2. Session CRUD Operations', () {
    test('Save and retrieve session roundtrip', () async {
      final session = EnvironmentSessionModel(
        sessionId: 'ENV-SESS-2026-001',
        sessionTitle: 'การตรวจวัดสิ่งแวดล้อม 2569',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'โรงงานระยอง',
        workplaceName: 'บริษัท ไทย ออโต้พาร์ท จำกัด',
        objective: 'ตรวจวัดประจำปี 2569',
        subcontractorType: SubcontractorType.section11Juristic,
        subcontractorCompanyName: 'บริษัท เซฟตี้ไทย คอนซัลแตนท์ จำกัด',
        subcontractorRegNumber: 'บ. 0088-02/2565',
        surveyorName: 'นาย สุรชัย ตรวจวัด',
        certifierName: 'ดร. รับรอง สิ่งแวดล้อม',
        status: EnvironmentSessionStatus.measured,
      );

      final insertId = await repo.saveSession(session);
      expect(insertId, greaterThan(0));

      final fetched = await repo.getSessionById('ENV-SESS-2026-001');
      expect(fetched, isNotNull);
      expect(fetched!.sessionTitle, 'การตรวจวัดสิ่งแวดล้อม 2569');
      expect(fetched.subcontractorRegNumber, 'บ. 0088-02/2565');
      expect(fetched.status, EnvironmentSessionStatus.measured);

      final all = await repo.getAllSessions();
      expect(all.length, 1);
    });

    test('Update existing session', () async {
      final session = EnvironmentSessionModel(
        sessionId: 'ENV-SESS-2026-002',
        sessionTitle: 'Session 2',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'Plant 2',
        workplaceName: 'Company 2',
        objective: 'Obj 2',
        subcontractorType: SubcontractorType.section9Individual,
        subcontractorCompanyName: 'บุคคลธรรมดา',
        subcontractorRegNumber: 'นบ. 0012-01/2566',
        surveyorName: 'Surveyor 2',
        certifierName: 'Certifier 2',
        status: EnvironmentSessionStatus.planned,
      );

      await repo.saveSession(session);

      final updated = session.copyWith(
        status: EnvironmentSessionStatus.reportPosted,
        sessionTitle: 'Session 2 (Updated)',
      );
      await repo.saveSession(updated);

      final fetched = await repo.getSessionById('ENV-SESS-2026-002');
      expect(fetched!.status, EnvironmentSessionStatus.reportPosted);
      expect(fetched.sessionTitle, 'Session 2 (Updated)');
    });

    test('Delete session cascades points and capas', () async {
      await repo.saveSession(
        EnvironmentSessionModel(
          sessionId: 'ENV-SESS-DEL',
          sessionTitle: 'Delete Test',
          sessionYearBe: 2569,
          sessionYearAd: 2026,
          measurementDate: '2026-09-01',
          locationPlant: 'Plant',
          workplaceName: 'Company',
          objective: 'Obj',
          subcontractorType: SubcontractorType.section11Juristic,
          subcontractorCompanyName: 'Subcon',
          subcontractorRegNumber: 'บ. 0001/2565',
          surveyorName: 'Surveyor',
          certifierName: 'Certifier',
        ),
      );

      await repo.savePoint(
        EnvironmentPointModel(
          pointId: 'PT-DEL-1',
          sessionId: 'ENV-SESS-DEL',
          factorType: EnvironmentFactorType.light,
          department: 'Dep',
          locationName: 'Loc',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
        ),
      );

      await repo.saveCapa(
        EnvironmentCapaModel(
          capaId: 'CAPA-DEL-1',
          sessionId: 'ENV-SESS-DEL',
          factorType: EnvironmentFactorType.light,
          actionTitle: 'Capa Title',
          hazardDescription: 'Hazard',
          rootCause: 'Root',
          picName: 'PIC',
          targetDate: '2026-10-01',
        ),
      );

      await repo.deleteSession('ENV-SESS-DEL');

      final session = await repo.getSessionById('ENV-SESS-DEL');
      final points = await repo.getPoints(sessionId: 'ENV-SESS-DEL');
      final capas = await repo.getCapas(sessionId: 'ENV-SESS-DEL');

      expect(session, isNull);
      expect(points.isEmpty, isTrue);
      expect(capas.isEmpty, isTrue);
    });
  });

  // =========================================================================
  // 3. Point CRUD Tests
  // =========================================================================
  group('3. Measurement Points CRUD Operations', () {
    test('Save single point and retrieve by pointId', () async {
      final point = EnvironmentPointModel(
        pointId: 'PT-LIGHT-01',
        sessionId: 'SESS-01',
        factorType: EnvironmentFactorType.light,
        department: 'Production',
        locationName: 'Assembly Table 1',
        evaluationStatus: EnvironmentEvaluationStatus.pass,
        lightCategoryCode: 'LIGHT_CAT2',
        lightTaskDescription: 'งานประกอบทั่วไป',
        lightMeasuredLux: 380.0,
        lightStandardMinLux: 300.0,
        lightIsCompliant: true,
      );

      await repo.savePoint(point);

      final fetched = await repo.getPointById('PT-LIGHT-01');
      expect(fetched, isNotNull);
      expect(fetched!.lightMeasuredLux, 380.0);
      expect(fetched.department, 'Production');
      expect(fetched.evaluationStatus, EnvironmentEvaluationStatus.pass);
    });

    test('Batch save measurement points', () async {
      final batch = [
        EnvironmentPointModel(
          pointId: 'PT-BATCH-1',
          sessionId: 'SESS-02',
          factorType: EnvironmentFactorType.light,
          department: 'Dep 1',
          locationName: 'Loc 1',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
        ),
        EnvironmentPointModel(
          pointId: 'PT-BATCH-2',
          sessionId: 'SESS-02',
          factorType: EnvironmentFactorType.noise,
          department: 'Dep 2',
          locationName: 'Loc 2',
          evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
          noiseMeasuredDba: 85.2,
          noiseIsHcpRequired: true,
        ),
      ];

      await repo.saveBatchPoints(batch);

      final points = await repo.getPoints(sessionId: 'SESS-02');
      expect(points.length, 2);
    });

    test('Delete measurement point', () async {
      await repo.savePoint(
        EnvironmentPointModel(
          pointId: 'PT-TO-DELETE',
          sessionId: 'SESS-03',
          factorType: EnvironmentFactorType.heat,
          department: 'Dep',
          locationName: 'Loc',
          evaluationStatus: EnvironmentEvaluationStatus.fail,
        ),
      );

      await repo.deletePoint('PT-TO-DELETE');
      final fetched = await repo.getPointById('PT-TO-DELETE');
      expect(fetched, isNull);
    });
  });

  // =========================================================================
  // 4. CAPA CRUD Tests
  // =========================================================================
  group('4. CAPA Action Plans CRUD Operations', () {
    test('Save, update, and fetch CAPA item', () async {
      final capa = EnvironmentCapaModel(
        capaId: 'CAPA-001',
        pointId: 'PT-NOISE-01',
        sessionId: 'SESS-01',
        factorType: EnvironmentFactorType.noise,
        actionTitle: 'ติดตั้งแผงกั้นเสียงและตรวจการได้ยิน',
        hazardDescription: 'เสียง 86.5 dBA เกินเกณฑ์มาตรฐาน',
        rootCause: 'เครื่องจักรเก่า ขาดการบำรุงรักษา',
        picName: 'นาย ช่างกล',
        targetDate: '2026-10-15',
        status: 'PENDING',
        hearingProgramEnrolled: true,
      );

      await repo.saveCapa(capa);

      final fetched = await repo.getCapaById('CAPA-001');
      expect(fetched, isNotNull);
      expect(fetched!.actionTitle, 'ติดตั้งแผงกั้นเสียงและตรวจการได้ยิน');
      expect(fetched.hearingProgramEnrolled, isTrue);

      final completed = capa.copyWith(
        status: 'COMPLETED',
        completedDate: '2026-09-15',
      );
      await repo.saveCapa(completed);

      final updated = await repo.getCapaById('CAPA-001');
      expect(updated!.status, 'COMPLETED');
      expect(updated.completedDate, '2026-09-15');
    });

    test('Delete CAPA item', () async {
      await repo.saveCapa(
        EnvironmentCapaModel(
          capaId: 'CAPA-DEL-2',
          sessionId: 'SESS-01',
          factorType: EnvironmentFactorType.heat,
          actionTitle: 'Capa to del',
          hazardDescription: 'Hazard',
          rootCause: 'Root',
          picName: 'PIC',
          targetDate: '2026-10-01',
        ),
      );

      await repo.deleteCapa('CAPA-DEL-2');
      final fetched = await repo.getCapaById('CAPA-DEL-2');
      expect(fetched, isNull);
    });
  });

  // =========================================================================
  // 5. KPI Aggregation via Repository
  // =========================================================================
  group('5. Repository KPI Aggregation', () {
    test('getSessionKpi returns calculated KPI for a session', () async {
      await repo.savePoint(
        EnvironmentPointModel(
          pointId: 'PT-KPI-1',
          sessionId: 'SESS-KPI',
          factorType: EnvironmentFactorType.light,
          department: 'Dept 1',
          locationName: 'Loc 1',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
        ),
      );
      await repo.savePoint(
        EnvironmentPointModel(
          pointId: 'PT-KPI-2',
          sessionId: 'SESS-KPI',
          factorType: EnvironmentFactorType.noise,
          department: 'Dept 2',
          locationName: 'Loc 2',
          evaluationStatus: EnvironmentEvaluationStatus.fail,
        ),
      );

      final kpi = await repo.getSessionKpi('SESS-KPI');
      expect(kpi.totalPoints, 2);
      expect(kpi.passedPoints, 1);
      expect(kpi.failedPoints, 1);
      expect(kpi.compliancePercentage, 50.0);
    });
  });
}
