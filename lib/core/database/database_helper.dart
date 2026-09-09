import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../features/legal_register/data/safety_legal_8_categories_data.dart';
import '../../features/environment/data/environmental_standards_data.dart';
import '../../features/ppe_asl/data/datasources/ppe_statutory_master_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows/Desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // เก็บ Database ไว้ที่โฟลเดอร์ My Documents / SafetySuperapp
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbFolder = Directory('${appDocDir.path}\\SafetySuperapp');
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    
    final dbPath = join(dbFolder.path, 'safety_superapp_v1.db');
    debugPrint('Database Path: $dbPath');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 17,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. ตารางเก็บข้อมูลเหตุการณ์ (Near Miss & Incident)
    await db.execute('''
      CREATE TABLE safety_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        event_date TEXT NOT NULL,
        location TEXT,
        description TEXT NOT NULL,
        initial_risk_level TEXT,
        reported_by_id INTEGER,
        image_path TEXT,
        status TEXT DEFAULT 'OPEN',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. ตารางการวิเคราะห์สาเหตุรากเหง้า (RCA)
    await db.execute('''
      CREATE TABLE rca_analysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        method_used TEXT NOT NULL,
        root_cause_summary TEXT NOT NULL,
        analyzed_by_id INTEGER,
        analyzed_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES safety_events(id) ON DELETE CASCADE
      )
    ''');

    // 3. ตาราง Action Tracker (ศูนย์กลางติดตามมาตรการแก้ไข)
    await db.execute('''
      CREATE TABLE action_trackers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_module TEXT NOT NULL,
        source_id INTEGER NOT NULL,
        action_description TEXT NOT NULL,
        responsible_person TEXT,
        due_date TEXT NOT NULL,
        status TEXT DEFAULT 'OPEN',
        completed_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _createRiskAssessmentTables(db);
    await _createChemicalTables(db);
    await _createLegalTables(db);
    await _createEnvironmentTables(db);
    await _createPtwTables(db);
    await _createCpoTables(db);
    await _createPpeTables(db);
    await _createEmergencyTables(db);
    await _createElectricalInspectionTable(db);
    await _createElectricalLotoTable(db);
    await _createMachineryTables(db);
    await _createSopTables(db);
    await _createManualScopeTables(db);
    await _createAuditInspectionTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createRiskAssessmentTables(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_policy TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN area_sqm REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN logo_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_name TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_level TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_cert_no TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_phone TEXT');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await _createChemicalTables(db);
    }
    if (oldVersion < 6) {
      await _createLegalTables(db);
    }
    if (oldVersion < 7) {
      await _createEnvironmentTables(db);
    }
    if (oldVersion < 8) {
      await _createPtwTables(db);
    }
    if (oldVersion < 9) {
      await _createCpoTables(db);
    }
    if (oldVersion < 10) {
      await _createPpeTables(db);
    }
    if (oldVersion < 11) {
      await _createEmergencyTables(db);
    }
    if (oldVersion < 12) {
      await _createElectricalInspectionTable(db);
    }
    if (oldVersion < 13) {
      await _createElectricalLotoTable(db);
    }
    if (oldVersion < 14) {
      await _createMachineryTables(db);
    }
    if (oldVersion < 15) {
      await _createSopTables(db);
    }
    if (oldVersion < 16) {
      await _createManualScopeTables(db);
    }
    if (oldVersion < 17) {
      await _createAuditInspectionTables(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    await _createRiskAssessmentTables(db);
    await _createChemicalTables(db);
    await _createLegalTables(db);
    await _createEnvironmentTables(db);
    await _createPtwTables(db);
    await _createCpoTables(db);
    await _createPpeTables(db);
    await _createEmergencyTables(db);
    await _createElectricalInspectionTable(db);
    await _createElectricalLotoTable(db);
    await _createMachineryTables(db);
    await _createSopTables(db);
    await _createManualScopeTables(db);
    await _createAuditInspectionTables(db);
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_policy TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN area_sqm REAL');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN logo_path TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_name TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_level TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_cert_no TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_officer_phone TEXT');
    } catch (_) {}
  }

  Future<void> _createRiskAssessmentTables(Database db) async {
    // ข้อมูลสถานประกอบกิจการ และผู้ชำนาญการ ม.๓๓
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        employer_name TEXT,
        tax_id TEXT,
        business_category_schedule INTEGER DEFAULT 2,
        business_category_number INTEGER,
        business_category_title TEXT,
        employee_count INTEGER DEFAULT 0,
        address_number TEXT,
        moo TEXT,
        soi TEXT,
        road TEXT,
        subdistrict TEXT,
        district TEXT,
        province TEXT,
        postal_code TEXT,
        phone TEXT,
        fax TEXT,
        mobile TEXT,
        safety_expert_name TEXT,
        safety_expert_license_no TEXT,
        safety_expert_valid_from TEXT,
        safety_expert_valid_to TEXT,
        safety_expert_signature_path TEXT,
        employer_signature_path TEXT,
        safety_policy TEXT,
        area_sqm REAL,
        logo_path TEXT,
        safety_officer_name TEXT,
        safety_officer_level TEXT,
        safety_officer_cert_no TEXT,
        safety_officer_phone TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN safety_policy TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN area_sqm REAL');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE company_profiles ADD COLUMN logo_path TEXT');
    } catch (_) {}

    // ชุดการประเมินอันตราย (รอบปกติ 3 ปี หรือ รอบปรับปรุงเปลี่ยนแปลง MOC 30 วัน)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS risk_assessment_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_title TEXT NOT NULL,
        assessment_type TEXT DEFAULT 'PERIODIC',
        assessment_date TEXT NOT NULL,
        next_review_date TEXT,
        hazard_id_method TEXT DEFAULT 'JSA',
        hazard_id_method_other TEXT,
        hazard_id_standard_approved TEXT,
        assessor_1_name TEXT,
        assessor_1_position TEXT,
        assessor_2_name TEXT,
        assessor_2_position TEXT,
        expert_opinion TEXT,
        status TEXT DEFAULT 'DRAFT',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // สถานีงาน / กระบวนการผลิต / พื้นที่ปฏิบัติงาน
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_stations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        department_name TEXT NOT NULL,
        station_name TEXT NOT NULL,
        employee_count INTEGER DEFAULT 1,
        description TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES risk_assessment_sessions(id) ON DELETE CASCADE
      )
    ''');

    // ขั้นตอนการปฏิบัติงาน / เครื่องจักร / อุปกรณ์
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_step_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workstation_id INTEGER NOT NULL,
        step_number INTEGER DEFAULT 1,
        step_name TEXT NOT NULL,
        related_machinery_equipment TEXT,
        description TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (workstation_id) REFERENCES work_stations(id) ON DELETE CASCADE
      )
    ''');

    // รายการประเมินอันตราย (แบบ ปอ. ๑)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hazard_evaluations_por1 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        step_id INTEGER NOT NULL,
        hazard_item_title TEXT NOT NULL,
        potential_consequences TEXT NOT NULL,
        existing_control_measures TEXT,
        recommendation TEXT,
        likelihood_score INTEGER NOT NULL,
        severity_score INTEGER NOT NULL,
        risk_score INTEGER NOT NULL,
        risk_level TEXT NOT NULL,
        risk_level_thai TEXT NOT NULL,
        requires_por2 INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (step_id) REFERENCES work_step_items(id) ON DELETE CASCADE
      )
    ''');

    // แผนดำเนินงานลดและควบคุมความเป็นอันตราย (แบบ ปอ. ๒)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS risk_control_plans_por2 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hazard_id INTEGER NOT NULL UNIQUE,
        control_plan_description TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        responsible_person TEXT NOT NULL,
        supervisor_monitor TEXT NOT NULL,
        action_tracker_id INTEGER,
        status TEXT DEFAULT 'PLANNED',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (hazard_id) REFERENCES hazard_evaluations_por1(id) ON DELETE CASCADE
      )
    ''');

    // เอกสารประเมินความเสี่ยง / JSA / ปอ.๑ / ปอ.๒ ของผู้รับเหมาภายนอก (Hard copy scan & PDF files)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractor_jsa_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contractor_name TEXT NOT NULL,
        project_title TEXT NOT NULL,
        work_location TEXT,
        document_type TEXT NOT NULL DEFAULT 'JSA ผู้รับเหมา',
        assessment_date TEXT NOT NULL,
        valid_until_date TEXT,
        assessor_name TEXT,
        notes TEXT,
        file_paths TEXT NOT NULL,
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ----------------------------------------------------
    // ทะเบียนบริษัทผู้รับเหมา (Contractors Directory)
    // ----------------------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        tax_id TEXT,
        service_type TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        safety_officer_name TEXT,
        safety_officer_phone TEXT,
        safety_score INTEGER DEFAULT 100,
        status TEXT DEFAULT 'ACTIVE',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ----------------------------------------------------
    // ทะเบียนคนงานผู้รับเหมา & Safety Induction Pass
    // ----------------------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractor_workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contractor_id INTEGER NOT NULL,
        worker_name TEXT NOT NULL,
        national_id_or_passport TEXT,
        job_role TEXT NOT NULL,
        photo_path TEXT,
        induction_date TEXT,
        induction_valid_until TEXT,
        cert_file_path TEXT,
        status TEXT DEFAULT 'ACTIVE',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (contractor_id) REFERENCES contractors(id) ON DELETE CASCADE
      )
    ''');

    // ----------------------------------------------------
    // บันทึกการฝ่าฝืนกฎความปลอดภัยผู้รับเหมา (Safety Violations)
    // ----------------------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractor_violations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contractor_id INTEGER NOT NULL,
        worker_id INTEGER,
        incident_date TEXT NOT NULL,
        violation_type TEXT NOT NULL,
        severity_level TEXT NOT NULL,
        description TEXT NOT NULL,
        action_taken TEXT NOT NULL,
        score_deducted INTEGER DEFAULT 0,
        inspector_name TEXT,
        photo_paths TEXT,
        status TEXT DEFAULT 'OPEN',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (contractor_id) REFERENCES contractors(id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES contractor_workers(id) ON DELETE SET NULL
      )
    ''');

    // ====================================================
    // ทะเบียนพนักงาน & การฝึกอบรมความปลอดภัย (Employee & Training)
    // ====================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        national_id TEXT,
        department TEXT NOT NULL,
        position TEXT NOT NULL,
        safety_role TEXT DEFAULT 'GENERAL',
        hire_date TEXT,
        phone TEXT,
        email TEXT,
        photo_path TEXT,
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_code TEXT NOT NULL UNIQUE,
        course_name TEXT NOT NULL,
        category TEXT NOT NULL,
        duration_hours REAL DEFAULT 6.0,
        validity_years INTEGER DEFAULT 0,
        description TEXT,
        is_default INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        course_id INTEGER NOT NULL,
        training_date TEXT NOT NULL,
        expiry_date TEXT,
        organizer_name TEXT,
        trainer_name TEXT,
        cert_number TEXT,
        cert_file_path TEXT,
        score REAL,
        passed INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES training_courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_committees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term_year TEXT NOT NULL,
        employee_id INTEGER NOT NULL,
        committee_position TEXT NOT NULL,
        appointed_date TEXT,
        term_end_date TEXT,
        status TEXT DEFAULT 'ACTIVE',
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // ====================================================
    // ระบบสอบสวนและวิเคราะห์อุบัติเหตุ (Accident Investigation & CAPA)
    // ====================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accident_investigations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_no TEXT NOT NULL UNIQUE,
        event_type TEXT NOT NULL,
        incident_title TEXT NOT NULL,
        incident_date TEXT NOT NULL,
        incident_time TEXT NOT NULL,
        incident_location TEXT NOT NULL,
        employee_id INTEGER,
        employee_type TEXT DEFAULT 'EMPLOYEE',
        injured_person_name TEXT,
        injured_person_national_id TEXT,
        injured_person_position TEXT,
        injured_person_department TEXT,
        injured_person_age INTEGER,
        injured_person_wage REAL,
        injury_nature TEXT,
        injured_body_part TEXT,
        hospital_name TEXT,
        hospital_sent_date TEXT,
        days_lost INTEGER DEFAULT 0,
        medical_expense REAL DEFAULT 0.0,
        property_damage_cost REAL DEFAULT 0.0,
        machine_involved TEXT,
        chemical_involved TEXT,
        work_process_involved TEXT,
        description_5w1h TEXT,
        timeline_events TEXT,
        witness_names TEXT,
        photo_paths TEXT,
        unsafe_acts TEXT,
        unsafe_conditions TEXT,
        management_errors TEXT,
        root_cause_summary TEXT,
        applicable_laws TEXT,
        inspector_name TEXT,
        inspector_position TEXT,
        employer_acknowledged_date TEXT,
        status TEXT DEFAULT 'INVESTIGATING',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accident_capa_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        investigation_id INTEGER NOT NULL,
        control_hierarchy TEXT NOT NULL,
        action_description TEXT NOT NULL,
        responsible_person TEXT NOT NULL,
        target_date TEXT NOT NULL,
        completed_date TEXT,
        status TEXT DEFAULT 'OPEN',
        evidence_photo_path TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (investigation_id) REFERENCES accident_investigations(id) ON DELETE CASCADE
      )
    ''');

    // ====================================================
    // ระบบตรวจสุขภาพพนักงานและอาชีวอนามัย (Occupational Health & Surveillance)
    // ====================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employee_health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        checkup_type TEXT NOT NULL,
        checkup_date TEXT NOT NULL,
        hospital_name TEXT NOT NULL,
        doctor_name TEXT,
        doctor_license_no TEXT,
        overall_result TEXT NOT NULL DEFAULT 'NORMAL',
        weight REAL,
        height REAL,
        bmi REAL,
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        pulse INTEGER,
        physical_exam_result TEXT DEFAULT 'NORMAL',
        physical_exam_notes TEXT,
        chest_xray_result TEXT DEFAULT 'NORMAL',
        audiogram_result TEXT DEFAULT 'NOT_TESTED',
        spirometry_result TEXT DEFAULT 'NOT_TESTED',
        vision_test_result TEXT DEFAULT 'NORMAL',
        blood_cbc_result TEXT DEFAULT 'NORMAL',
        blood_sugar_result TEXT DEFAULT 'NORMAL',
        liver_function_result TEXT DEFAULT 'NORMAL',
        kidney_function_result TEXT DEFAULT 'NORMAL',
        urine_exam_result TEXT DEFAULT 'NORMAL',
        drug_screening_result TEXT DEFAULT 'NEGATIVE',
        risk_factors_tested TEXT,
        risk_factor_results TEXT,
        doctor_opinion TEXT,
        fitness_to_work TEXT DEFAULT 'FIT',
        pdf_file_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_health_bulk_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_year TEXT NOT NULL,
        report_title TEXT NOT NULL,
        hospital_name TEXT NOT NULL,
        checkup_date TEXT NOT NULL,
        total_employees_tested INTEGER DEFAULT 0,
        normal_count INTEGER DEFAULT 0,
        abnormal_count INTEGER DEFAULT 0,
        watch_count INTEGER DEFAULT 0,
        summary_notes TEXT,
        pdf_file_path TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_surveillance_followups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        health_record_id INTEGER NOT NULL,
        employee_id INTEGER NOT NULL,
        abnormal_symptom TEXT NOT NULL,
        followup_action_type TEXT NOT NULL,
        action_details TEXT NOT NULL,
        treatment_hospital TEXT,
        target_date TEXT NOT NULL,
        completed_date TEXT,
        status TEXT DEFAULT 'OPEN',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (health_record_id) REFERENCES employee_health_records(id) ON DELETE CASCADE,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // Seed default standard safety courses if not present
    await _seedDefaultTrainingCourses(db);
  }

  Future<void> _createChemicalTables(Database db) async {
    // 1. ทะเบียนสารเคมีที่ครอบครองในสถานประกอบการ & ติดตาม SDS
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chemical_inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seq_no INTEGER,
        trade_name TEXT NOT NULL,
        chemical_name_th TEXT NOT NULL,
        chemical_name_en TEXT NOT NULL,
        cas_number TEXT NOT NULL,
        un_number TEXT,
        storage_location TEXT NOT NULL,
        physical_state TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        max_capacity REAL,
        container_type TEXT,
        manufacturer_supplier TEXT,
        hazard_class TEXT,
        ghs_pictograms TEXT,
        register_date TEXT NOT NULL,
        sds_issue_date TEXT NOT NULL,
        sds_expiry_years INTEGER DEFAULT 3,
        sds_file_path TEXT,
        label_image_path TEXT,
        nfpa_health INTEGER DEFAULT 0,
        nfpa_flammability INTEGER DEFAULT 0,
        nfpa_instability INTEGER DEFAULT 0,
        nfpa_special TEXT,
        notes TEXT,
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chemical_inventory_cas ON chemical_inventory(cas_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chemical_inventory_location ON chemical_inventory(storage_location)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chemical_inventory_trade ON chemical_inventory(trade_name)');

    // 2. ข้อมูลความปลอดภัยสารเคมีอันตราย (แบบ สอ.๑ - SDS 16 หัวข้อ)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chemical_sds_sor1 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventory_id INTEGER,
        trade_name TEXT NOT NULL,
        chemical_formula TEXT,
        cas_number TEXT NOT NULL,
        un_number TEXT,
        manufacturer_importer_info TEXT,
        ghs_classification TEXT,
        ghs_pictograms TEXT,
        signal_word TEXT,
        hazard_statements TEXT,
        precautionary_statements TEXT,
        ingredients_json TEXT,
        first_aid_json TEXT,
        fire_fighting_json TEXT,
        accidental_release_json TEXT,
        handling_storage_json TEXT,
        exposure_controls_json TEXT,
        physical_chemical_json TEXT,
        stability_reactivity_json TEXT,
        toxicological_json TEXT,
        ecological_json TEXT,
        disposal_json TEXT,
        transport_json TEXT,
        regulatory_json TEXT,
        other_info_json TEXT,
        nfpa_health INTEGER DEFAULT 0,
        nfpa_flammability INTEGER DEFAULT 0,
        nfpa_instability INTEGER DEFAULT 0,
        nfpa_special TEXT,
        status TEXT DEFAULT 'COMPLETED',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (inventory_id) REFERENCES chemical_inventory(id) ON DELETE SET NULL
      )
    ''');

    // 3. รายงานผลการตรวจวัดระดับความเข้มข้นในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chemical_measurement_sor3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_no TEXT NOT NULL UNIQUE,
        assessment_date TEXT NOT NULL,
        workplace_area TEXT NOT NULL,
        sampling_point_description TEXT,
        chemical_name TEXT NOT NULL,
        cas_number TEXT NOT NULL,
        sampling_type TEXT DEFAULT 'TWA_8HR',
        sampling_duration_minutes INTEGER,
        sampling_method TEXT,
        measured_value REAL NOT NULL,
        unit TEXT NOT NULL,
        tlv_standard_value REAL NOT NULL,
        evaluation_result TEXT NOT NULL,
        service_provider_name TEXT NOT NULL,
        service_provider_m9_reg_no TEXT,
        service_provider_m11_cert_no TEXT,
        sampling_officer_name TEXT,
        analyst_name TEXT,
        analysis_laboratory TEXT,
        weather_condition TEXT,
        temperature_celsius REAL,
        relative_humidity REAL,
        corrective_action TEXT,
        certificate_pdf_path TEXT,
        status TEXT DEFAULT 'APPROVED',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<void> _seedDefaultTrainingCourses(Database db) async {
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM training_courses');
    final count = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (count == 0) {
      final defaultCourses = [
        {
          'course_code': 'SAF-001',
          'course_name': 'การอบรมความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน สำหรับลูกจ้างใหม่ / เปลี่ยนงาน (6 ชั่วโมง)',
          'category': 'LEGAL_MANDATORY',
          'duration_hours': 6.0,
          'validity_years': 0,
          'description': 'ตามมาตรา ๑๖ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-002',
          'course_name': 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับหัวหน้างาน (จป.หัวหน้างาน - 12 ชั่วโมง)',
          'category': 'LEGAL_MANDATORY',
          'duration_hours': 12.0,
          'validity_years': 0,
          'description': 'ตามกฎกระทรวงการจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงานฯ',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-003',
          'course_name': 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับบริหาร (จป.บริหาร - 12 ชั่วโมง)',
          'category': 'LEGAL_MANDATORY',
          'duration_hours': 12.0,
          'validity_years': 0,
          'description': 'สำหรับผู้บริหารระดับผู้จัดการขึ้นไป',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-004',
          'course_name': 'คณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ. - 12 ชั่วโมง)',
          'category': 'LEGAL_MANDATORY',
          'duration_hours': 12.0,
          'validity_years': 2,
          'description': 'สำหรับกรรมการ คปอ. ตัวแทนลูกจ้างและนายจ้าง (วาระ ๒ ปี)',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-005',
          'course_name': 'การฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟประจำปี (Annual Fire Drill - 40% ของพนักงาน)',
          'category': 'REFRESHER_ANNUAL',
          'duration_hours': 6.0,
          'validity_years': 1,
          'description': 'ตามกฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัยฯ เกี่ยวกับการป้องกันและระงับอัคคีภัย',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-006',
          'course_name': 'ความปลอดภัยในการทำงานในที่อับอากาศ (Confined Space Safety - 4 บทบาท)',
          'category': 'SPECIALIZED',
          'duration_hours': 12.0,
          'validity_years': 3,
          'description': 'ผู้อนุญาต, ผู้ควบคุมงาน, ผู้ช่วยเหลือ, และผู้ปฏิบัติงานในที่อับอากาศ',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-007',
          'course_name': 'ความปลอดภัยในการทำงานบนที่สูงและติดตั้งนั่งร้าน (Work at Height & Scaffolding)',
          'category': 'SPECIALIZED',
          'duration_hours': 6.0,
          'validity_years': 2,
          'description': 'การใช้อุปกรณ์ Full Body Harness, Lifeline และตรวจสอบนั่งร้าน',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-008',
          'course_name': 'การขับขี่รถยกอย่างปลอดภัยและการตรวจเช็กประจำวัน (Forklift Safety Operation)',
          'category': 'SPECIALIZED',
          'duration_hours': 6.0,
          'validity_years': 1,
          'description': 'สำหรับพนักงานขับรถยก / สแตกเกอร์',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-009',
          'course_name': 'ผู้บังคับปั้นจั่น ผู้ให้สัญญาณแก่ผู้บังคับปั้นจั่น ผู้ยึดเกาะวัสดุ และผู้ควบคุมการใช้ปั้นจั่น (4 ผู้)',
          'category': 'SPECIALIZED',
          'duration_hours': 12.0,
          'validity_years': 2,
          'description': 'ตามกฎกระทรวงปั้นจั่น เครน และเครื่องจักรยก',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-010',
          'course_name': 'การปฐมพยาบาลเบื้องต้นและการช่วยฟื้นคืนชีพ (First Aid & CPR / AED)',
          'category': 'GENERAL_SAFETY',
          'duration_hours': 6.0,
          'validity_years': 2,
          'description': 'สำหรับทีมปฐมพยาบาลประจำสถานประกอบการ',
          'is_default': 1,
        },
        {
          'course_code': 'SAF-011',
          'course_name': 'ความปลอดภัยเกี่ยวกับสารเคมีอันตรายและข้อมูลความปลอดภัย (Chemical Safety & SDS)',
          'category': 'SPECIALIZED',
          'duration_hours': 6.0,
          'validity_years': 1,
          'description': 'การจัดเก็บ ใช้งาน และตอบโต้สารเคมีรั่วไหล',
          'is_default': 1,
        },
      ];

      for (final c in defaultCourses) {
        await db.insert('training_courses', c);
      }
    }
  }

  Future<void> _createLegalTables(Database db) async {
    // 1. ตาราง Master Legal Catalog (กฎหมายแม่บทและข้อกำหนดราชกิจจานุเบกษา)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_legal_master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL UNIQUE,
        law_id TEXT NOT NULL,
        law_name_th TEXT NOT NULL,
        law_name_en TEXT NOT NULL,
        category TEXT NOT NULL,
        governing_authority TEXT NOT NULL,
        gazette_volume TEXT,
        gazette_part TEXT,
        gazette_page TEXT,
        gazette_published_date TEXT,
        gazette_effective_date TEXT,
        article_no TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        applicability_criteria TEXT NOT NULL,
        compliance_criteria TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        required_evidence_type TEXT NOT NULL,
        official_form_name TEXT,
        retention_years INTEGER DEFAULT 1,
        penalty_summary TEXT NOT NULL,
        pdf_asset_path TEXT,
        sort_order INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_master_cat ON safety_legal_master(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_master_law ON safety_legal_master(law_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_master_item ON safety_legal_master(item_id)');

    // 2. ตารางการประเมินความสอดคล้องตามกฎหมาย (Compliance Evaluation)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_legal_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_item_id TEXT NOT NULL,
        requirement_code TEXT NOT NULL,
        requirement_title TEXT NOT NULL,
        requirement_details TEXT NOT NULL,
        category TEXT NOT NULL,
        law_id TEXT NOT NULL,
        law_title_th TEXT NOT NULL,
        article_no TEXT NOT NULL,
        is_applicable INTEGER DEFAULT 1,
        compliance_status TEXT NOT NULL DEFAULT 'NOT_APPLICABLE',
        actual_practice TEXT,
        evaluated_date TEXT NOT NULL,
        next_review_date TEXT,
        evaluator_name TEXT NOT NULL,
        evaluator_role TEXT,
        department TEXT,
        evidence_file_paths TEXT,
        risk_level TEXT NOT NULL DEFAULT 'MEDIUM',
        penalty_summary TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_assessments_cat ON safety_legal_assessments(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_assessments_status ON safety_legal_assessments(compliance_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_assessments_req ON safety_legal_assessments(requirement_code)');

    // 3. ตารางแผนปฏิบัติการแก้ไข CAPA (Action Plans for Legal Compliance)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_legal_capa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_id INTEGER NOT NULL,
        action_title TEXT NOT NULL,
        root_cause TEXT NOT NULL,
        corrective_action TEXT NOT NULL,
        preventive_action TEXT,
        pic_name TEXT NOT NULL,
        pic_department TEXT,
        target_date TEXT NOT NULL,
        completed_date TEXT,
        status TEXT DEFAULT 'PENDING',
        evidence_file_path TEXT,
        supervisor_acknowledged_date TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (assessment_id) REFERENCES safety_legal_assessments(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_capa_assessment ON safety_legal_capa(assessment_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_legal_capa_status ON safety_legal_capa(status)');

    // Seed master catalog and initial assessments if empty
    await _seedDefaultLegalData(db);
  }

  static Future<void> _seedDefaultLegalData(Database db) async {
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM safety_legal_master');
    final count = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (count == 0) {
      for (final item in SafetyLegal8CategoriesData.masterItems) {
        await db.insert('safety_legal_master', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    final assessRes = await db.rawQuery('SELECT COUNT(*) as count FROM safety_legal_assessments');
    final assessCount = assessRes.isNotEmpty ? (assessRes.first['count'] as int? ?? 0) : 0;
    if (assessCount == 0) {
      final defaultAssessments = SafetyLegal8CategoriesData.generateDefaultAssessments();
      for (final a in defaultAssessments) {
        await db.insert('safety_legal_assessments', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> _createEnvironmentTables(Database db) async {
    // 1. ตาราง Master Environmental Standards (มาตรฐานความเข้มแสง เสียง ความร้อน WBGT)
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_std_id ON environment_standards_master(standard_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_std_factor ON environment_standards_master(factor_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_std_cat ON environment_standards_master(category_code)');

    // 2. ตารางรอบการตรวจวัดประจำปี & ข้อมูล Subcontractor ม.๙ / ม.๑๑ (Environment Sessions)
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_sess_id ON environment_sessions(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_sess_year ON environment_sessions(session_year_be)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_sess_status ON environment_sessions(status)');

    // 3. ตารางผลการตรวจวัดรายจุด (Sampling Points: Light, Noise, Heat)
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_pt_id ON environment_measurement_points(point_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_pt_session ON environment_measurement_points(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_pt_factor ON environment_measurement_points(factor_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_pt_status ON environment_measurement_points(evaluation_status)');

    // 4. ตารางแผนปฏิบัติการแก้ไข CAPA และโครงการอนุรักษ์การได้ยิน (Hearing Conservation)
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_capa_id ON environment_capa(capa_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_capa_session ON environment_capa(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_env_capa_status ON environment_capa(status)');

    // Seed master environmental standards if empty
    await _seedDefaultEnvironmentData(db);
  }

  static Future<void> _seedDefaultEnvironmentData(Database db) async {
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM environment_standards_master');
    final count = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (count == 0) {
      for (final item in EnvironmentalStandardsData.masterStandards) {
        await db.insert('environment_standards_master', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  // ====================================================
  // High-Risk Permit to Work (PTW) Tables - Version 8
  // ====================================================
  Future<void> _createPtwTables(Database db) async {
    // 1. ตารางใบอนุญาตทำงานความเสี่ยงสูงหลัก (PTW Master Table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_permits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ptw_number TEXT NOT NULL UNIQUE,
        work_title TEXT NOT NULL,
        work_description TEXT NOT NULL,
        primary_risk_type TEXT NOT NULL,
        secondary_risk_types TEXT,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        plant_area TEXT NOT NULL,
        specific_location TEXT NOT NULL,
        request_date TEXT NOT NULL,
        work_start_date TEXT NOT NULL,
        work_start_time TEXT NOT NULL,
        work_end_date TEXT NOT NULL,
        work_end_time TEXT NOT NULL,
        extension_hours INTEGER DEFAULT 0,
        extension_reason TEXT,
        applicant_type TEXT NOT NULL DEFAULT 'INTERNAL_EMPLOYEE',
        applicant_name TEXT NOT NULL,
        applicant_department TEXT NOT NULL,
        applicant_phone TEXT NOT NULL,
        worker_count INTEGER DEFAULT 1,
        worker_names TEXT,
        jsa_reference_no TEXT,
        emergency_rescue_plan TEXT NOT NULL,
        required_ppe_list TEXT NOT NULL,
        special_precautions TEXT,
        applicant_signature_path TEXT,
        applicant_signed_at TEXT,
        safety_officer_signature_path TEXT,
        safety_officer_name TEXT,
        safety_officer_signed_at TEXT,
        authorizer_signature_path TEXT,
        authorizer_name TEXT,
        authorizer_signed_at TEXT,
        handover_signature_path TEXT,
        handover_signed_at TEXT,
        closure_signature_path TEXT,
        closure_signed_at TEXT,
        closure_remarks TEXT,
        site_photo_paths TEXT,
        qr_code_data TEXT,
        official_pdf_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ptw_number ON ptw_permits(ptw_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ptw_status ON ptw_permits(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ptw_risk ON ptw_permits(primary_risk_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ptw_date ON ptw_permits(work_start_date)');

    // 2. ตารางผลการตรวจวัดก๊าซในที่อับอากาศ (Gas Test Monitoring Logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_gas_test_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_id TEXT NOT NULL UNIQUE,
        ptw_number TEXT NOT NULL,
        test_stage TEXT NOT NULL,
        test_timestamp TEXT NOT NULL,
        location_point TEXT NOT NULL,
        oxygen_percent REAL NOT NULL,
        combustible_percent_lel REAL NOT NULL,
        carbon_monoxide_ppm REAL NOT NULL,
        hydrogen_sulfide_ppm REAL NOT NULL,
        toxic_other_ppm REAL,
        toxic_other_name TEXT,
        tester_name TEXT NOT NULL,
        tester_cert_no TEXT,
        detector_model TEXT NOT NULL,
        detector_serial_no TEXT NOT NULL,
        last_calibration_date TEXT NOT NULL,
        is_safe INTEGER NOT NULL DEFAULT 1,
        safety_remarks TEXT,
        signature_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_gas_ptw ON ptw_gas_test_logs(ptw_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_gas_stage ON ptw_gas_test_logs(test_stage)');

    // 3. ตารางทะเบียนผู้มีหน้าที่ 4 ฝ่ายในที่อับอากาศ (Confined Space 4 Roles)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_confined_roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_assignment_id TEXT NOT NULL UNIQUE,
        ptw_number TEXT NOT NULL,
        role_type TEXT NOT NULL,
        person_name TEXT NOT NULL,
        national_id TEXT,
        employee_id TEXT,
        company_name TEXT NOT NULL,
        cert_number TEXT NOT NULL,
        cert_institute TEXT NOT NULL,
        cert_issue_date TEXT NOT NULL,
        cert_expiry_date TEXT NOT NULL,
        contact_phone TEXT NOT NULL,
        is_trained_and_certified INTEGER NOT NULL DEFAULT 1,
        signature_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cfr_ptw ON ptw_confined_roles(ptw_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cfr_role ON ptw_confined_roles(role_type)');

    // 4. ตารางการเฝ้าระวังไฟและตรวจความปลอดภัยหลังงาน Hot Work 30 นาที (Fire Watch Logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_fire_watches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        watch_id TEXT NOT NULL UNIQUE,
        ptw_number TEXT NOT NULL UNIQUE,
        fire_watcher_name TEXT NOT NULL,
        fire_watcher_phone TEXT NOT NULL,
        fire_extinguisher_type TEXT NOT NULL,
        fire_extinguisher_serial TEXT NOT NULL,
        extinguisher_inspected_ready INTEGER NOT NULL DEFAULT 1,
        cleared_radius_meters REAL NOT NULL DEFAULT 11.0,
        fire_blanket_installed INTEGER NOT NULL DEFAULT 1,
        combustible_material_protected INTEGER NOT NULL DEFAULT 1,
        sewer_covered INTEGER NOT NULL DEFAULT 1,
        hot_work_end_time TEXT NOT NULL,
        post_work_watch_start_time TEXT NOT NULL,
        post_work_watch_end_time TEXT,
        post_work_watch_duration_minutes INTEGER NOT NULL DEFAULT 30,
        is_post_work_area_safe INTEGER NOT NULL DEFAULT 1,
        final_inspector_name TEXT,
        final_inspector_signature TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fw_ptw ON ptw_fire_watches(ptw_number)');

    // 5. ตารางจุดตัดแยกพลังงาน Lockout/Tagout (LOTO Isolation Logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_loto_isolations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isolation_id TEXT NOT NULL UNIQUE,
        ptw_number TEXT NOT NULL,
        equipment_tag_no TEXT NOT NULL,
        equipment_name TEXT NOT NULL,
        location_area TEXT NOT NULL,
        energy_type TEXT NOT NULL,
        isolation_method TEXT NOT NULL,
        padlock_tag_no TEXT NOT NULL,
        lock_applied_by TEXT NOT NULL,
        lock_applied_timestamp TEXT NOT NULL,
        zero_energy_test_method TEXT NOT NULL,
        is_zero_energy_verified INTEGER NOT NULL DEFAULT 1,
        verified_by TEXT NOT NULL,
        verified_timestamp TEXT,
        is_de_isolated INTEGER NOT NULL DEFAULT 0,
        de_isolated_by TEXT,
        de_isolated_timestamp TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_loto_ptw ON ptw_loto_isolations(ptw_number)');

    // 6. ตารางรายการตรวจสอบความปลอดภัย (PTW Checklists)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_checklists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ptw_number TEXT,
        item_id TEXT NOT NULL,
        risk_type TEXT NOT NULL,
        check_category TEXT NOT NULL,
        question_th TEXT NOT NULL,
        question_en TEXT NOT NULL,
        is_mandatory INTEGER NOT NULL DEFAULT 1,
        result TEXT NOT NULL DEFAULT 'NA',
        remarks TEXT,
        checked_by TEXT,
        checked_at TEXT,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chk_ptw ON ptw_checklists(ptw_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chk_risk ON ptw_checklists(risk_type)');

    // 7. ตารางประวัติการอนุมัติและ Audit Trail (PTW Approval Logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ptw_approval_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        approval_id TEXT NOT NULL UNIQUE,
        ptw_number TEXT NOT NULL,
        approval_stage TEXT NOT NULL,
        approver_role TEXT NOT NULL,
        approver_name TEXT NOT NULL,
        approver_position TEXT,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        comments TEXT,
        signature_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_apr_ptw ON ptw_approval_logs(ptw_number)');
  }

  Future<void> _createCpoTables(Database db) async {
    // 1. วาระ คปอ. (CPO Term)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_terms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term_code TEXT NOT NULL UNIQUE,
        term_title TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        employee_count INTEGER NOT NULL DEFAULT 0,
        required_quota INTEGER NOT NULL DEFAULT 5,
        employer_rep_count INTEGER NOT NULL DEFAULT 2,
        employee_rep_count INTEGER NOT NULL DEFAULT 2,
        secretary_count INTEGER NOT NULL DEFAULT 1,
        appointment_doc_no TEXT,
        appointment_date TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_term_code ON cpo_terms(term_code)');

    // 2. รายชื่อกรรมการ คปอ. (CPO Members)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term_id INTEGER NOT NULL,
        employee_id INTEGER,
        full_name TEXT NOT NULL,
        employee_code TEXT,
        department TEXT,
        company_position TEXT,
        cpo_role TEXT NOT NULL,
        appointment_type TEXT NOT NULL DEFAULT 'APPOINTED',
        votes_received INTEGER DEFAULT 0,
        phone TEXT,
        email TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (term_id) REFERENCES cpo_terms(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_member_term ON cpo_members(term_id)');

    // 3. รอบการเลือกตั้ง กกต. (CPO Elections)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_elections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        election_code TEXT NOT NULL UNIQUE,
        election_title TEXT NOT NULL,
        term_year TEXT NOT NULL,
        announcement_date TEXT,
        nomination_start_date TEXT,
        nomination_end_date TEXT,
        voting_date TEXT NOT NULL,
        voting_start_time TEXT DEFAULT '08:00',
        voting_end_time TEXT DEFAULT '17:00',
        eligible_voters_count INTEGER DEFAULT 0,
        total_ballots_cast INTEGER DEFAULT 0,
        valid_ballots_count INTEGER DEFAULT 0,
        invalid_ballots_count INTEGER DEFAULT 0,
        no_vote_ballots_count INTEGER DEFAULT 0,
        required_reps_count INTEGER NOT NULL DEFAULT 2,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_elec_code ON cpo_elections(election_code)');

    // 4. กรรมการดำเนินการเลือกตั้ง (Election Officers - กกต.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_election_officers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        election_id INTEGER NOT NULL,
        employee_id INTEGER,
        officer_name TEXT NOT NULL,
        department TEXT,
        position_title TEXT,
        officer_role TEXT NOT NULL DEFAULT 'MEMBER',
        appointment_order_no TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (election_id) REFERENCES cpo_elections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_off_elec ON cpo_election_officers(election_id)');

    // 5. ผู้สมัครรับเลือกตั้ง (Election Candidates)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_election_candidates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        election_id INTEGER NOT NULL,
        candidate_no INTEGER NOT NULL,
        employee_id INTEGER,
        full_name TEXT NOT NULL,
        department TEXT,
        position_title TEXT,
        campaign_policy TEXT,
        votes_received INTEGER NOT NULL DEFAULT 0,
        rank_order INTEGER DEFAULT 0,
        is_elected INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'QUALIFIED',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (election_id) REFERENCES cpo_elections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_cand_elec ON cpo_election_candidates(election_id)');

    // 6. การประชุม คปอ. (CPO Meetings)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_meetings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meeting_no INTEGER NOT NULL,
        meeting_year TEXT NOT NULL,
        meeting_title TEXT NOT NULL,
        meeting_date TEXT NOT NULL,
        start_time TEXT NOT NULL DEFAULT '09:00',
        end_time TEXT NOT NULL DEFAULT '12:00',
        location TEXT NOT NULL DEFAULT 'ห้องประชุมใหญ่',
        term_id INTEGER,
        chair_name TEXT NOT NULL,
        secretary_name TEXT NOT NULL,
        total_invited INTEGER DEFAULT 0,
        total_attended INTEGER DEFAULT 0,
        is_quorum_reached INTEGER DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        overall_summary TEXT,
        next_meeting_date TEXT,
        pdf_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_meet_date ON cpo_meetings(meeting_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_meet_year ON cpo_meetings(meeting_year)');

    // 7. ผู้เข้าร่วมประชุม (Meeting Attendees)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_meeting_attendees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meeting_id INTEGER NOT NULL,
        employee_id INTEGER,
        attendee_name TEXT NOT NULL,
        role_label TEXT NOT NULL,
        department TEXT,
        is_present INTEGER NOT NULL DEFAULT 1,
        absence_reason TEXT,
        signature_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES cpo_meetings(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_att_meet ON cpo_meeting_attendees(meeting_id)');

    // 8. ระเบียบวาระการประชุม 6 วาระ (Meeting Agendas)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_meeting_agendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meeting_id INTEGER NOT NULL,
        agenda_no INTEGER NOT NULL,
        agenda_title TEXT NOT NULL,
        discussion_content TEXT,
        resolution_content TEXT,
        presenter_name TEXT,
        is_approved INTEGER DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES cpo_meetings(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_agn_meet ON cpo_meeting_agendas(meeting_id)');

    // 9. รายการติดตามมติที่ประชุม (Action Items / Task Tracking)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_action_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT NOT NULL UNIQUE,
        meeting_id INTEGER NOT NULL,
        agenda_id INTEGER,
        agenda_no INTEGER DEFAULT 5,
        title TEXT NOT NULL,
        action_detail TEXT NOT NULL,
        responsible_person TEXT NOT NULL,
        department TEXT,
        due_date TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'MEDIUM',
        status TEXT NOT NULL DEFAULT 'PENDING',
        progress_percent INTEGER NOT NULL DEFAULT 0,
        resolution_notes TEXT,
        completed_date TEXT,
        evidence_photo_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES cpo_meetings(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_act_meet ON cpo_action_items(meeting_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_act_status ON cpo_action_items(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_act_due ON cpo_action_items(due_date)');

    // 10. ประวัติการแจกจ่าย/แจ้งเวียนรายงานการประชุม (Meeting Distribution Logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpo_distribution_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meeting_id INTEGER NOT NULL,
        distribution_date TEXT NOT NULL,
        distribution_method TEXT NOT NULL,
        recipient_group TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        proof_document_path TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES cpo_meetings(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpo_dist_meet ON cpo_distribution_logs(meeting_id)');
  }

  // ====================================================
  // PPE & Approved Supplier List (ASL) Tables - Version 10
  // ตาม พ.ร.บ. ความปลอดภัยฯ พ.ศ. ๒๕๕๔ มาตรา ๒๒
  // ====================================================
  Future<void> _createPpeTables(Database db) async {
    // 1. ทะเบียนอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE Items)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ppe_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        standard_cert TEXT NOT NULL,
        description TEXT,
        unit TEXT NOT NULL DEFAULT 'ชิ้น',
        current_stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 5,
        unit_cost REAL DEFAULT 0.0,
        storage_location TEXT,
        replacement_cycle_days INTEGER,
        preferred_supplier_id INTEGER,
        preferred_supplier_name TEXT,
        image_path TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_code ON ppe_items(code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_category ON ppe_items(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_status ON ppe_items(status)');

    // 2. บันทึกความเคลื่อนไหวสต็อกการ์ด (Stock Card / Transactions)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ppe_stock_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_no TEXT NOT NULL UNIQUE,
        ppe_id INTEGER NOT NULL,
        ppe_code TEXT NOT NULL,
        ppe_name TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        balance_after INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        recipient_type TEXT,
        recipient_id TEXT,
        recipient_name TEXT,
        department TEXT,
        cpo_meeting_ref TEXT,
        ptw_ref TEXT,
        supplier_id INTEGER,
        supplier_name TEXT,
        notes TEXT,
        recorded_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ppe_id) REFERENCES ppe_items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_tx_no ON ppe_stock_transactions(transaction_no)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_tx_ppe_id ON ppe_stock_transactions(ppe_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ppe_tx_date ON ppe_stock_transactions(transaction_date)');

    // 3. ทะเบียนคู่ค้าที่ผ่านการรับรอง (Approved Supplier List - ASL)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ppe_suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        company_name TEXT NOT NULL,
        tax_id TEXT,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        supplied_categories TEXT NOT NULL,
        standard_certificates TEXT,
        rating REAL DEFAULT 5.0,
        evaluation_status TEXT NOT NULL DEFAULT 'APPROVED',
        approved_date TEXT,
        valid_until TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_asl_code ON ppe_suppliers(code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_asl_status ON ppe_suppliers(evaluation_status)');

    // Seed Master PPE items & ASL Suppliers if empty
    final ppeCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM ppe_items');
    final ppeCount = ppeCountRes.isNotEmpty ? (ppeCountRes.first['count'] as int? ?? 0) : 0;
    if (ppeCount == 0) {
      for (final item in PpeStatutoryMasterData.defaultPpeItems) {
        await db.insert('ppe_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    final aslCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM ppe_suppliers');
    final aslCount = aslCountRes.isNotEmpty ? (aslCountRes.first['count'] as int? ?? 0) : 0;
    if (aslCount == 0) {
      for (final sup in PpeStatutoryMasterData.defaultSuppliers) {
        await db.insert('ppe_suppliers', sup.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> _createEmergencyTables(Database db) async {
    // 1. ตารางแผนฉุกเฉิน (Emergency Response Plans - ERP 6 แผนย่อยตามกฎกระทรวง ข้อ ๔ และเหตุฉุกเฉินอื่นๆ)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_title TEXT NOT NULL,
        hazard_type TEXT NOT NULL DEFAULT 'FIRE',
        business_type TEXT NOT NULL DEFAULT 'FACTORY',
        company_name TEXT,
        company_address TEXT,
        total_employees INTEGER DEFAULT 0,
        male_count INTEGER DEFAULT 0,
        female_count INTEGER DEFAULT 0,
        fire_commander_name TEXT,
        deputy_commander_name TEXT,
        commander_phone TEXT,
        version TEXT DEFAULT '1.0',
        effective_date TEXT,
        review_date TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        plan_1_inspection_json TEXT,
        plan_2_training_json TEXT,
        plan_3_campaign_json TEXT,
        plan_4_suppression_json TEXT,
        plan_5_evacuation_json TEXT,
        plan_6_relief_json TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_erp_hazard_type ON emergency_plans(hazard_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_erp_status ON emergency_plans(status)');

    // 2. ตารางบันทึกการฝึกซ้อมและรายงานผล (Drill Sessions & สปร. ๔ ข้อ ๓๐)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_drill_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER,
        hazard_type TEXT NOT NULL DEFAULT 'FIRE',
        drill_title TEXT NOT NULL,
        drill_date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        drill_year INTEGER,
        organizer_type TEXT NOT NULL DEFAULT 'SELF_APPROVED',
        organizer_name TEXT,
        approval_cert_no TEXT,
        approval_date TEXT,
        scenario_description TEXT,
        incident_location TEXT,
        fire_or_hazard_source TEXT,
        total_workers_on_site INTEGER DEFAULT 0,
        participated_count INTEGER DEFAULT 0,
        male_participants INTEGER DEFAULT 0,
        female_participants INTEGER DEFAULT 0,
        participation_rate_percent REAL DEFAULT 0.0,
        initial_attack_time_sec INTEGER DEFAULT 0,
        evacuation_time_sec INTEGER DEFAULT 0,
        headcount_status TEXT NOT NULL DEFAULT 'ALL_ACCOUNTED',
        simulated_injuries_count INTEGER DEFAULT 0,
        problems_and_obstacles TEXT,
        improvement_actions TEXT,
        evaluation_summary TEXT,
        evaluator_name TEXT,
        evaluator_position TEXT,
        spr4_submission_status TEXT NOT NULL DEFAULT 'PENDING',
        submission_deadline TEXT,
        submitted_date TEXT,
        officer_receipt_no TEXT,
        vendor_report_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plan_id) REFERENCES emergency_plans(id) ON DELETE SET NULL
      )
    ''');
    try {
      await db.execute('ALTER TABLE emergency_drill_sessions ADD COLUMN vendor_report_path TEXT');
    } catch (_) {}
    await db.execute('CREATE INDEX IF NOT EXISTS idx_drill_date ON emergency_drill_sessions(drill_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_drill_submission ON emergency_drill_sessions(spr4_submission_status)');

    // 3. ตารางรูปถ่ายและเอกสารแนบการฝึกซ้อม (Drill Photos & Evidence for สปร. ๔)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_drill_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drill_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        caption TEXT,
        category TEXT DEFAULT 'DURING',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (drill_id) REFERENCES emergency_drill_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachment_drill_id ON emergency_drill_attachments(drill_id)');
  }

  Future<void> _createElectricalInspectionTable(Database db) async {
    // 4. ตารางบันทึกผลการตรวจสอบและรับรองระบบไฟฟ้าและบริภัณฑ์ไฟฟ้า (แบบ ๕๖๒๘๙ / กฎกระทรวงไฟฟ้า ๒๕๕๘ ข้อ ๑๒)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS electrical_inspection_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT,
        inspection_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        inspector_name TEXT NOT NULL,
        inspector_license_no TEXT NOT NULL,
        contractor_company TEXT,
        inspector_type TEXT NOT NULL DEFAULT 'EXTERNAL_CONTRACTOR',
        overall_result TEXT NOT NULL DEFAULT 'PASS',
        voltage_system TEXT NOT NULL DEFAULT 'HIGH_AND_LOW_VOLTAGE',
        transformer_count INTEGER DEFAULT 0,
        mdb_panel_count INTEGER DEFAULT 0,
        grounding_resistance_ohm REAL,
        defects_found TEXT,
        corrective_actions TEXT,
        vendor_report_pdf_path TEXT,
        thermoscan_report_path TEXT,
        engineer_license_doc_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_elec_insp_date ON electrical_inspection_records(inspection_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_elec_exp_date ON electrical_inspection_records(expiry_date)');
  }

  Future<void> _createElectricalLotoTable(Database db) async {
    // 5. ตารางทะเบียนจุดตัดแยกพลังงานไฟฟ้าหลัก & เบรกเกอร์ (Main Breakers & Circuit Isolation Map)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS electrical_circuit_breakers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipment_tag TEXT NOT NULL UNIQUE,
        equipment_name TEXT NOT NULL,
        location_building TEXT NOT NULL,
        location_floor TEXT,
        voltage_level TEXT NOT NULL DEFAULT 'LOW_VOLTAGE',
        rated_current_amp REAL,
        breaker_type TEXT NOT NULL,
        upstream_source TEXT,
        is_locked INTEGER NOT NULL DEFAULT 0,
        lockout_tag_no TEXT,
        locked_by TEXT,
        locked_at TEXT,
        zero_energy_verified INTEGER NOT NULL DEFAULT 0,
        authorized_operator TEXT,
        single_line_diagram_ref TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cb_tag ON electrical_circuit_breakers(equipment_tag)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cb_locked ON electrical_circuit_breakers(is_locked)');

    // Pre-populate standard factory breakers if empty
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM electrical_circuit_breakers');
    final count = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (count == 0) {
      await db.insert('electrical_circuit_breakers', {
        'equipment_tag': 'MDB-01-ACB',
        'equipment_name': 'ตู้ควบคุมหลัก อาคารผลิต 1 (Main MDB)',
        'location_building': 'อาคารผลิต 1 (Production Plant 1)',
        'location_floor': 'ชั้น 1 ห้องควบคุมไฟฟ้าแรงต่ำ',
        'voltage_level': 'LOW_VOLTAGE',
        'rated_current_amp': 1600.0,
        'breaker_type': 'Air Circuit Breaker (ACB)',
        'upstream_source': 'หม้อแปลงไฟฟ้า TR-01 (1,000 kVA)',
        'is_locked': 0,
        'zero_energy_verified': 0,
        'authorized_operator': 'วิศวกรไฟฟ้า / ช่างเทคนิคอาวุโส',
        'single_line_diagram_ref': 'SLD-DWG-001',
        'notes': 'จุดตัดแยกกระแสไฟหลักของอาคารผลิตทั้งหมด',
      });

      await db.insert('electrical_circuit_breakers', {
        'equipment_tag': 'MDB-OFFICE-MCCB',
        'equipment_name': 'ตู้ควบคุมหลัก อาคารสำนักงาน',
        'location_building': 'อาคารสำนักงานใหญ่ (Head Office)',
        'location_floor': 'ชั้น 1 ห้องไฟฟ้าใต้บันได',
        'voltage_level': 'LOW_VOLTAGE',
        'rated_current_amp': 400.0,
        'breaker_type': 'Molded Case Circuit Breaker (MCCB)',
        'upstream_source': 'หม้อแปลงไฟฟ้า TR-02 (400 kVA)',
        'is_locked': 0,
        'zero_energy_verified': 0,
        'authorized_operator': 'หัวหน้าช่างอาคาร',
        'single_line_diagram_ref': 'SLD-DWG-002',
        'notes': 'ควบคุมระบบแสงสว่าง ปลั๊ก และแอร์สำนักงาน',
      });

      await db.insert('electrical_circuit_breakers', {
        'equipment_tag': 'SUB-SERVER-MCCB',
        'equipment_name': 'ตู้จ่ายไฟสำรองห้องเซิร์ฟเวอร์ (Server Room)',
        'location_building': 'อาคารสำนักงานใหญ่',
        'location_floor': 'ชั้น 2 ห้อง Data Center',
        'voltage_level': 'LOW_VOLTAGE',
        'rated_current_amp': 100.0,
        'breaker_type': 'Molded Case Circuit Breaker (MCCB)',
        'upstream_source': 'MDB-OFFICE พร้อมระบบสลับ UPS อัตโนมัติ',
        'is_locked': 0,
        'zero_energy_verified': 0,
        'authorized_operator': 'ผู้ดูแลระบบ IT & หัวหน้าช่างอาคาร',
        'single_line_diagram_ref': 'SLD-DWG-003',
        'notes': 'ห้ามปลดวงจรโดยไม่แจ้งฝ่าย IT ล่วงหน้าอย่างน้อย 24 ชม.',
      });
    }
  }

  Future<void> _createMachineryTables(Database db) async {
    // 1. ตารางบันทึกผลการตรวจสอบปั้นจั่น (แบบ ปจ.๑ / ปจ.๒ ตามกฎกระทรวงเครื่องจักร ปั้นจั่น หม้อน้ำ ๒๕๖๔)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS machinery_crane_inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crane_name TEXT NOT NULL,
        crane_tag TEXT NOT NULL,
        crane_type TEXT NOT NULL,
        inspection_form TEXT NOT NULL,
        location_building TEXT NOT NULL,
        location_area TEXT,
        safe_working_load_ton REAL NOT NULL,
        test_weight_ton REAL,
        load_test_percent REAL,
        inspection_cycle_months INTEGER NOT NULL DEFAULT 12,
        wire_rope_status TEXT NOT NULL DEFAULT 'PASS',
        hook_latch_status TEXT NOT NULL DEFAULT 'PASS',
        limit_switch_status TEXT NOT NULL DEFAULT 'PASS',
        brake_system_status TEXT NOT NULL DEFAULT 'PASS',
        structure_status TEXT NOT NULL DEFAULT 'PASS',
        engineer_name TEXT NOT NULL,
        engineer_license_no TEXT NOT NULL,
        contractor_company TEXT,
        inspection_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        overall_result TEXT NOT NULL DEFAULT 'PASS',
        defects_found TEXT,
        corrective_actions TEXT,
        vendor_report_pdf_path TEXT,
        load_test_cert_pdf_path TEXT,
        engineer_license_pdf_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crane_tag ON machinery_crane_inspections(crane_tag)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crane_date ON machinery_crane_inspections(inspection_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crane_expiry ON machinery_crane_inspections(expiry_date)');

    // 2. ตารางบันทึกผลการตรวจรับรองหม้อน้ำและภาชนะรับแรงดัน (Boiler & Pressure Vessel Inspections)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS machinery_boiler_inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        boiler_name TEXT NOT NULL,
        boiler_tag TEXT NOT NULL,
        boiler_type TEXT NOT NULL,
        capacity_ton_hr REAL,
        location_building TEXT NOT NULL,
        location_area TEXT,
        max_allowable_working_pressure_bar REAL NOT NULL,
        hydro_test_pressure_bar REAL,
        hydro_test_result TEXT NOT NULL DEFAULT 'PASS',
        safety_valve_test_result TEXT NOT NULL DEFAULT 'PASS',
        safety_valve_pop_pressure_bar REAL,
        water_treatment_status TEXT NOT NULL DEFAULT 'PASS',
        burner_control_status TEXT NOT NULL DEFAULT 'PASS',
        engineer_name TEXT NOT NULL,
        engineer_license_no TEXT NOT NULL,
        contractor_company TEXT,
        inspection_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        overall_result TEXT NOT NULL DEFAULT 'PASS',
        defects_found TEXT,
        corrective_actions TEXT,
        report_pdf_path TEXT,
        engineer_license_pdf_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_boiler_tag ON machinery_boiler_inspections(boiler_tag)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_boiler_expiry ON machinery_boiler_inspections(expiry_date)');

    // 3. ตารางทะเบียนเครื่องจักร & อุปกรณ์ช่วยยก (Machinery & Lifting Gear Inventory)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS machinery_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_tag TEXT NOT NULL UNIQUE,
        asset_name TEXT NOT NULL,
        category TEXT NOT NULL,
        rated_capacity TEXT,
        location TEXT NOT NULL,
        manufacturer_brand TEXT,
        serial_no TEXT,
        status TEXT NOT NULL DEFAULT 'READY',
        last_inspected_date TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mach_asset_tag ON machinery_assets(asset_tag)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mach_asset_cat ON machinery_assets(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mach_asset_stat ON machinery_assets(status)');

    // Pre-populate standard sample records if empty
    final craneCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM machinery_crane_inspections');
    final craneCount = craneCountRes.isNotEmpty ? (craneCountRes.first['count'] as int? ?? 0) : 0;
    if (craneCount == 0) {
      final now = DateTime.now();
      final inspDate = DateTime(now.year, now.month - 1, now.day);
      final expDate = DateTime(inspDate.year, inspDate.month + 6, inspDate.day); // 6 months cycle for 5 tons

      await db.insert('machinery_crane_inspections', {
        'crane_name': 'ปั้นจั่นเหนือศีรษะ อาคารผลิต 1 (Overhead Crane 5T)',
        'crane_tag': 'CRANE-01-OH',
        'crane_type': 'OVERHEAD',
        'inspection_form': 'PJ1',
        'location_building': 'อาคารผลิต 1 (Plant 1)',
        'location_area': 'Bay 1 โซนประกอบชิ้นงานหนัก',
        'safe_working_load_ton': 5.0,
        'test_weight_ton': 6.25,
        'load_test_percent': 125.0,
        'inspection_cycle_months': 6,
        'wire_rope_status': 'PASS',
        'hook_latch_status': 'PASS',
        'limit_switch_status': 'PASS',
        'brake_system_status': 'PASS',
        'structure_status': 'PASS',
        'engineer_name': 'ธีรพงษ์ วิศวกรเครื่องกล',
        'engineer_license_no': 'สค. 8891 (สามัญวิศวกรเครื่องกล)',
        'contractor_company': 'บริษัท สยามเครน อินสเปคชั่น แอนด์ เอ็นจิเนียริ่ง จำกัด',
        'inspection_date': inspDate.toIso8601String().substring(0, 10),
        'expiry_date': expDate.toIso8601String().substring(0, 10),
        'overall_result': 'PASS',
        'defects_found': 'ระบบพร้อมใช้งาน สลิงไม่มีรอยแตกร้าว ลิมิตตัดตามพิกัด',
        'corrective_actions': 'อัดจารบีลูกปืนล้อเลื่อนและตรวจสลิงสม่ำเสมอทุกเดือน',
      });

      final hoistInspDate = DateTime(now.year, now.month - 2, now.day);
      final hoistExpDate = DateTime(hoistInspDate.year + 1, hoistInspDate.month, hoistInspDate.day); // 12 months for 2 tons
      await db.insert('machinery_crane_inspections', {
        'crane_name': 'รอกโซ่ไฟฟ้า คลังสินค้า (Electric Chain Hoist 2T)',
        'crane_tag': 'HOIST-01-WH',
        'crane_type': 'JIB',
        'inspection_form': 'PJ1',
        'location_building': 'อาคารคลังสินค้า (Warehouse)',
        'location_area': 'จุดรับจ่ายสินค้า Loading Dock',
        'safe_working_load_ton': 2.0,
        'test_weight_ton': 2.5,
        'load_test_percent': 125.0,
        'inspection_cycle_months': 12,
        'wire_rope_status': 'PASS',
        'hook_latch_status': 'PASS',
        'limit_switch_status': 'PASS',
        'brake_system_status': 'PASS',
        'structure_status': 'PASS',
        'engineer_name': 'สมศักดิ์ ช่างเครื่องกล กว.',
        'engineer_license_no': 'ภค. 14205 (ภาคีวิศวกรเครื่องกล)',
        'contractor_company': 'บริษัท เอ็นจิเนียริ่ง เทสติ้ง เซอร์วิส จำกัด',
        'inspection_date': hoistInspDate.toIso8601String().substring(0, 10),
        'expiry_date': hoistExpDate.toIso8601String().substring(0, 10),
        'overall_result': 'PASS',
        'defects_found': 'ตะขอมี Safety Latch สมบูรณ์ โซ่ยกอยู่ในเกณฑ์มาตรฐาน',
        'corrective_actions': 'ตรวจความตึงของโซ่และทำความสะอาดรางวิ่ง',
      });
    }

    final boilerCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM machinery_boiler_inspections');
    final boilerCount = boilerCountRes.isNotEmpty ? (boilerCountRes.first['count'] as int? ?? 0) : 0;
    if (boilerCount == 0) {
      final now = DateTime.now();
      final bInspDate = DateTime(now.year, now.month - 3, now.day);
      final bExpDate = DateTime(bInspDate.year + 1, bInspDate.month, bInspDate.day);

      await db.insert('machinery_boiler_inspections', {
        'boiler_name': 'หม้อน้ำไอน้ำแบบท่อไฟ (Fire Tube Steam Boiler 2 T/h)',
        'boiler_tag': 'BOILER-01-STM',
        'boiler_type': 'STEAM_BOILER',
        'capacity_ton_hr': 2.0,
        'location_building': 'อาคาร Utility & Energy',
        'location_area': 'ห้องหม้อน้ำ (Boiler Room)',
        'max_allowable_working_pressure_bar': 10.0,
        'hydro_test_pressure_bar': 15.0,
        'hydro_test_result': 'PASS',
        'safety_valve_test_result': 'PASS',
        'safety_valve_pop_pressure_bar': 10.5,
        'water_treatment_status': 'PASS',
        'burner_control_status': 'PASS',
        'engineer_name': 'ณรงค์ศักดิ์ กว.เครื่องกล',
        'engineer_license_no': 'สค. 3312 (สามัญวิศวกรเครื่องกล)',
        'contractor_company': 'บริษัท บอยเลอร์ แอนด์ คอมบัชชั่น เอ็นจิเนียริ่ง จำกัด',
        'inspection_date': bInspDate.toIso8601String().substring(0, 10),
        'expiry_date': bExpDate.toIso8601String().substring(0, 10),
        'overall_result': 'PASS',
        'defects_found': 'ผ่านการทดสอบ Hydrostatic test และ Safety Valve ปลดปล่อยแรงดันถูกต้อง',
        'corrective_actions': 'ควบคุมค่าน้ำเลี้ยงหม้อน้ำ (TDS / Hardness) ให้เป็นไปตามประกาศกรมโรงงานฯ',
      });
    }

    final assetCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM machinery_assets');
    final assetCount = assetCountRes.isNotEmpty ? (assetCountRes.first['count'] as int? ?? 0) : 0;
    if (assetCount == 0) {
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      await db.insert('machinery_assets', {
        'asset_tag': 'SLING-WR-01',
        'asset_name': 'ลวดสลิงถัก 4 ขา ขนาด 16 มม. (Wire Rope Sling 4-Legs)',
        'category': 'SLING_WIRE',
        'rated_capacity': 'WLL 5.0 Ton',
        'location': 'อาคารผลิต 1 แผนกประกอบ',
        'manufacturer_brand': 'KISWIRE',
        'serial_no': 'KW-2025-081',
        'status': 'READY',
        'last_inspected_date': nowStr,
        'notes': 'มีป้ายแท็กโลหะแสดงพิกัดน้ำหนักชัดเจน ไม่มีเส้นลวดขาด',
      });

      await db.insert('machinery_assets', {
        'asset_tag': 'SLING-WB-02',
        'asset_name': 'สายรัดผ้าใบโพลีเอสเตอร์แถบสีเหลือง (Webbing Sling)',
        'category': 'SLING_WEBBING',
        'rated_capacity': 'WLL 3.0 Ton (ยาว 4 ม.)',
        'location': 'อาคารคลังสินค้า',
        'manufacturer_brand': 'SPANSET',
        'serial_no': 'SS-3T-4M-09',
        'status': 'READY',
        'last_inspected_date': nowStr,
        'notes': 'สภาพดี ไม่ฉีกขาด ไม่โดนกรดหรือประกายไฟ',
      });

      await db.insert('machinery_assets', {
        'asset_tag': 'SHACKLE-G209-01',
        'asset_name': 'สะเก็นโอเมก้าชนิดเกลียวขัน (Bow Shackle)',
        'category': 'SHACKLE',
        'rated_capacity': 'WLL 4.75 Ton (ขนาด 3/4 นิ้ว)',
        'location': 'อาคารผลิต 1',
        'manufacturer_brand': 'Crosby G-209',
        'serial_no': 'CB-4.75-22',
        'status': 'READY',
        'last_inspected_date': nowStr,
        'notes': 'สลักเกลียวไม่คดงอ ตัวอักษรปั๊มพิกัดชัดเจน',
      });

      await db.insert('machinery_assets', {
        'asset_tag': 'GUARD-PRESS-01',
        'asset_name': 'ม่านแสงนิรภัยป้องกันจุดหนีบตัด (Safety Light Curtain)',
        'category': 'MACHINE_GUARD',
        'rated_capacity': 'Type 4 (ความเร็วหยุด <0.1 วินาที)',
        'location': 'แผนกปั๊มขึ้นรูปโลหะ เครื่องปั๊ม Press 100T',
        'manufacturer_brand': 'KEYENCE GL-R Series',
        'serial_no': 'KY-GLR-100P',
        'status': 'READY',
        'last_inspected_date': nowStr,
        'notes': 'ตัดการทำงานทันทีเมื่อมือล่วงล้ำเข้าเขตอันตราย',
      });
    }
  }

  // ========================================================
  // 13. SAFETY MANUAL & DIGITAL SOP HUB (ISO 45001 & Thai OSH)
  // ========================================================

  Future<void> _createSopTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_manual_sops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doc_code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        revision TEXT DEFAULT 'Rev. 01',
        effective_date TEXT NOT NULL,
        review_due_date TEXT NOT NULL,
        purpose TEXT,
        scope TEXT,
        required_ppe TEXT,
        precautions TEXT,
        steps_json TEXT,
        emergency_procedure TEXT,
        pdf_file_path TEXT,
        author TEXT,
        reviewer TEXT,
        approver TEXT,
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sop_doc_code ON safety_manual_sops(doc_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sop_category ON safety_manual_sops(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sop_status ON safety_manual_sops(status)');

    // Pre-populate standard sample records if empty
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM safety_manual_sops');
    final sopCount = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (sopCount == 0) {
      final now = DateTime.now();
      final effectiveDateStr = DateTime(now.year, 1, 1).toIso8601String().substring(0, 10);
      final reviewDateStr = DateTime(now.year + 1, 1, 1).toIso8601String().substring(0, 10);

      // 1. Machinery / Overhead Crane SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-MCH-001',
        'title': 'ขั้นตอนการตรวจสอบก่อนใช้งานและควบคุมปั้นจั่นเหนือศีรษะ (Overhead Crane & Rigging SOP)',
        'category': 'MACHINERY',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดมาตรฐานความปลอดภัยในการตรวจสอบอุปกรณ์ช่วยยกและการขับเคลื่อนปั้นจั่นเหนือศีรษะ ป้องกันอุบัติเหตุชิ้นงานตกหล่นตามกฎกระทรวงเครื่องจักร พ.ศ. ๒๕๖๔',
        'scope': 'ครอบคลุมปั้นจั่นเหนือศีรษะ (Overhead Crane) และรอกไฟฟ้าทุกตัวในพื้นที่อาคารผลิตและคลังสินค้า',
        'required_ppe': '["HELMET","SAFETY_GLASSES","GLOVES","BOOTS","HI_VIS_VEST"]',
        'precautions': '• ห้ามยกชิ้นงานหนักเกินพิกัดยกปลอดภัย (Safe Working Load: SWL) เด็ดขาด\n• ห้ามบุคคลเดินหรือยืนใต้แนวรัศมีชิ้นงานที่กำลังยก (No Walk Under Load)\n• ห้ามดึงหรือลากชิ้นงานในแนวเฉียง ต้องตั้งแนวตะขอให้ตรง 90 องศา',
        'steps_json': '[{"stepNumber":1,"title":"การตรวจสอบก่อนเริ่มปฏิบัติงาน (Pre-operational Visual Check)","action":"ตรวจสอบสภาพทั่วไปของลวดสลิง โซ่ยก และอุปกรณ์ช่วยยก (สะเก็น, สายรัด) ว่าไม่มีรอยแตกร้าว คดงอ หรือฉีกขาด","safetyCheckpoint":"ปากตะขอต้องมี Safety Latch ปิดสนิทสมบูรณ์ และสลิงไม่มีเส้นลวดขาดเกิน 3 เส้นในหนึ่งช่วงเกลียว"},{"stepNumber":2,"title":"ทดสอบระบบควบคุมและอุปกรณ์ความปลอดภัย (Safety Device Testing)","action":"เปิดสวิตช์ควบคุม ทดสอบปุ่มหยุดฉุกเฉิน (E-Stop) และทดสอบยกตะขอเปล่าขึ้นสู่ระดับสูงสุด","safetyCheckpoint":"ระบบตัดรอกอัตโนมัติ (Limit Switch) ต้องตัดการทำงานทันทีก่อนที่บล็อกตะขอจะชนโครงสร้าง"},{"stepNumber":3,"title":"การผูกรัดและยกเคลื่อนย้ายชิ้นงาน (Rigging & Hoisting Execution)","action":"ใช้อุปกรณ์ช่วยยกที่ได้พิกัดน้ำหนัก ผูกรัดให้ได้สมดุล ส่งสัญญาณมือมาตรฐาน และยกขึ้นจากพื้น 10-20 ซม. เพื่อทดสอบเบรกก่อนยกจริง","safetyCheckpoint":"สลิงต้องตั้งฉาก 90 องศา ให้สัญญาณเตือนด้วยเสียงแตรก่อนเคลื่อนย้ายชิ้นงาน"},{"stepNumber":4,"title":"การวางชิ้นงานและการจัดเก็บหลังเลิกงาน (Post-Operation & Parking)","action":"วางชิ้นงานลงบนหมอนรองอย่างมั่นคง ปลดสลิงยก ยกรอกขึ้นเก็บที่ความสูงอย่างน้อย 2 เมตรเหนือพื้นดิน","safetyCheckpoint":"กดปุ่ม Emergency Stop และสับเบรกเกอร์ตัดกระแสไฟจ่ายเข้าปั้นจั่นทุกครั้งเมื่อสิ้นสุดการใช้งาน"}]',
        'emergency_procedure': 'หากเกิดเหตุการณ์ชิ้นงานแกว่งผิดปกติหรือสลิงส่งเสียงผิดรูป ให้กดปุ่ม Emergency Stop ทันที กั้นพื้นที่รัศมีอันตราย และแจ้ง จป.วิชาชีพ หรือหัวหน้างานทันที',
        'pdf_file_path': null,
        'author': 'ธีรพงษ์ วิศวกรเครื่องกล',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้จัดการฝ่ายวิศวกรรมและความปลอดภัย',
        'status': 'ACTIVE',
      });

      // 2. Electrical / LOTO SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-ELC-001',
        'title': 'ขั้นตอนการตัดแยกแหล่งจ่ายพลังงานและการล็อคแขวนป้ายเตือน (6-Step Lockout/Tagout - LOTO)',
        'category': 'ELECTRICAL',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดขั้นตอนการควบคุมพลังงานอันตราย (Hazardous Energy Control) ป้องกันการปล่อยพลังงานหรือสตาร์ทเครื่องจักรโดยไม่ได้ตั้งใจตามกฎกระทรวงความปลอดภัยไฟฟ้า พ.ศ. ๒๕๕๘',
        'scope': 'ครอบคลุมงานซ่อมบำรุง ตรวจสอบ ล้างเครื่องจักร และงานติดตั้งที่เกี่ยวข้องกับพลังงานไฟฟ้า ลม ไฮดรอลิกส์',
        'required_ppe': '["HELMET","SAFETY_GLASSES","GLOVES","BOOTS"]',
        'precautions': '• กฎเหล็ก 1 คน 1 กุญแจ (One Person, One Lock) ห้ามใช้กุญแจร่วมกันเด็ดขาด\n• ห้ามปลดล็อคกุญแจของผู้อื่นโดยไม่ได้รับอนุญาตตามขั้นตอนฉุกเฉิน\n• ต้องยืนยันพลังงานเป็นศูนย์ (Zero Energy) ด้วยมิเตอร์วัดเสมอ',
        'steps_json': '[{"stepNumber":1,"title":"แจ้งเตือนผู้มีส่วนเกี่ยวข้อง (Notify Affected Persons)","action":"แจ้งหัวหน้ากะและผู้ควบคุมเครื่องจักรในพื้นที่ว่าจะทำการหยุดเครื่องจักรเพื่อซ่อมบำรุง","safetyCheckpoint":"ลงชื่อรับทราบในใบแจ้งการตัดแยกพลังงาน"},{"stepNumber":2,"title":"สั่งหยุดการทำงานของเครื่องจักร (Machine Shutdown)","action":"กดปุ่มหยุดเครื่องจักรตามขั้นตอนการทำงานปกติที่แผงควบคุมหลัก","safetyCheckpoint":"รอจนกระทั่งชิ้นส่วนกลไกหยุดหมุนสนิท"},{"stepNumber":3,"title":"ปลดตัดแยกแหล่งจ่ายพลังงาน (Energy Isolation)","action":"สับเบรกเกอร์หลัก (Main Breaker/MCCB) และปิดวาล์วตัดแยกระบบลมและไฮดรอลิกส์","safetyCheckpoint":"สังเกตตำแหน่งคันโยกเบรกเกอร์ว่าอยู่ในตำแหน่ง OFF ชัดเจน"},{"stepNumber":4,"title":"คล้องแม่กุญแจและแขวนป้ายเตือน (Lockout & Tagout)","action":"คล้องแม่กุญแจนิรภัยส่วนบุคคล (Safety Padlock) เข้ากับอุปกรณ์ครอบล็อค และแขวนป้ายเตือนอันตรายระบุชื่อ วันที่ และเบอร์ติดต่อ","safetyCheckpoint":"กุญแจดอกจริงต้องถูกเก็บไว้ที่ผู้ปฏิบัติงานแต่เพียงผู้เดียว"},{"stepNumber":5,"title":"ระบายพลังงานตกค้าง (Dissipate Stored Energy)","action":"เปิดวาล์วเดรนลม คายแรงดันน้ำมันไฮดรอลิกส์ และคายประจุในตัวเก็บประจุไฟฟ้า","safetyCheckpoint":"เข็มเกจวัดแรงดันลมและไฮดรอลิกส์ต้องชี้ที่เลข 0"},{"stepNumber":6,"title":"ตรวจสอบสภาวะพลังงานเป็นศูนย์ (Zero Energy Verification)","action":"ใช้มัลติมิเตอร์ (Multimeter) วัดแรงดันไฟฟ้าขั้วต่อทุกเฟส (L-L, L-N, L-G) และทดลองกดปุ่มสตาร์ทเครื่องจักรเพื่อยืนยัน","safetyCheckpoint":"แรงดันไฟฟ้าต้องวัดได้ 0.0 Volt และเครื่องจักรต้องไม่สตาร์ทติดเด็ดขาด"}]',
        'emergency_procedure': 'กรณีเจ้าของกุญแจไม่อยู่และมีความจำเป็นต้องปลดล็อคฉุกเฉิน ต้องผ่านการอนุมัติร่วมกันระหว่างผู้จัดการฝ่ายและ จป.วิชาชีพ พร้อมตรวจสอบความปลอดภัยรอบเครื่องจักร',
        'pdf_file_path': null,
        'author': 'วิศวกรไฟฟ้าประจำโรงงาน',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้จัดการโรงงาน (Plant Manager)',
        'status': 'ACTIVE',
      });

      // 3. Chemical Handling SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-CHM-001',
        'title': 'ขั้นตอนการจัดเก็บ ถ่ายเท และระงับเหตุสารเคมีอันตรายรั่วไหล (Chemical Handling & Spill SOP)',
        'category': 'CHEMICAL',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดแนวปฏิบัติในการใช้งาน การจัดเก็บสารเคมีอันตราย และการเข้าระงับเหตุสารเคมีรั่วไหลฉุกเฉินตามกฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖',
        'scope': 'ครอบคลุมสารเคมีอันตราย กรด ด่าง ตัวทำละลาย และสารไวไฟทุกชนิดในโรงงาน',
        'required_ppe': '["SAFETY_GLASSES","FACE_SHIELD","GLOVES","BOOTS","RESPIRATOR"]',
        'precautions': '• ต้องอ่านเอกสารข้อมูลความปลอดภัย (SDS) ส่วนที่ 8 (PPE) ก่อนสัมผัสสารเคมีเสมอ\n• ห้ามจัดเก็บสารเคมีที่ไม่เข้ากันไว้ด้วยกัน (Incompatible Storage)\n• การถ่ายเทสารไวไฟต้องต่อสายดิน (Bonding & Grounding) ป้องกันประกายไฟสถิต',
        'steps_json': '[{"stepNumber":1,"title":"การตรวจสอบก่อนสัมผัสสารเคมี (Pre-Handling & SDS Review)","action":"ตรวจสอบฉลาก GHS บนภาชนะบรรจุ ตรวจสอบความสมบูรณ์ของอุปกรณ์ PPE และจุดล้างตาฉุกเฉินที่ใกล้ที่สุด","safetyCheckpoint":"ต้องมีเอกสาร SDS ภาษาไทยประจำจุดใช้งาน และน้ำล้างตาฉุกเฉินพร้อมใช้งาน"},{"stepNumber":2,"title":"การถ่ายเทและลำเลียงสารเคมี (Chemical Transfer & Transport)","action":"ใช้ถาดรองรับการหก (Spill Pallet) ต่อสายดินเข้ากับถังโลหะเมื่อถ่ายเทสารไวไฟ ใช้ปั๊มสูบเฉพาะทางแทนการเทด้วยมือ","safetyCheckpoint":"สวมกระบังหน้า (Face Shield) และถุงมือยางกันสารเคมีชนิดไนไตรล์หรือนีโอพรีน"},{"stepNumber":3,"title":"การเข้าควบคุมเหตุสารเคมีรั่วไหล (Spill Containment Protocol)","action":"อพยพผู้ไม่เกี่ยวข้อง นำชุด Spill Kit เข้าพื้นที่ วางท่อนกั้นดูดซับล้อมรอบของเหลวจากด้านนอกเข้าหาศูนย์กลาง","safetyCheckpoint":"เข้าควบคุมจากทิศทางเหนือลมเท่านั้น สวมหน้ากากกรองไอระเหยสารเคมี"},{"stepNumber":4,"title":"การเก็บกู้และกำจัดกากของเสีย (Decontamination & Waste Disposal)","action":"ใช้ผงดูดซับสารเคมีโปรยบนคราบ กวาดใส่ถุงขยะอันตรายสีแดง ปิดผนึกและติดป้ายกากสารเคมีอันตรายเพื่อส่งกำจัด","safetyCheckpoint":"ห้ามใช้น้ำฉีดล้างสารเคมีลงสู่ท่อระบายน้ำสาธารณะเด็ดขาด"}]',
        'emergency_procedure': 'กรณีสารเคมีกระเด็นเข้าตา ให้ล้างด้วยน้ำสะอาดต่อเนื่องที่อ่างล้างตาฉุกเฉินอย่างน้อย 15 นาที หากสัมผัสผิวหนังให้ถอดเสื้อผ้าที่เปื้อนออกและนำส่งห้องพยาบาลพร้อม SDS',
        'pdf_file_path': null,
        'author': 'เจ้าหน้าที่สุขศาสตร์อุตสาหกรรม',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้จัดการฝ่ายความปลอดภัยและสิ่งแวดล้อม',
        'status': 'ACTIVE',
      });

      // 4. Confined Space SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-CNF-001',
        'title': 'ขั้นตอนการขออนุญาตและปฏิบัติงานในสถานที่อับอากาศ (Confined Space Entry SOP)',
        'category': 'CONFINED_SPACE',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดมาตรฐานความปลอดภัยในการขออนุญาต การตรวจวัดบรรยากาศ และการลงปฏิบัติงานในสถานที่อับอากาศตามกฎกระทรวงที่อับอากาศ พ.ศ. ๒๕๖๒',
        'scope': 'ครอบคลุมถังเก็บ ไซโล บ่อพักน้ำ ท่อระบายน้ำใต้ดิน และห้องปิดทึบที่มีทางเข้าออกจำกัด',
        'required_ppe': '["HELMET","SAFETY_GLASSES","GLOVES","BOOTS","HARNESS","RESPIRATOR"]',
        'precautions': '• ต้องมีผู้ปฏิบัติงานครบ 4 บทบาท (ผู้อนุญาต, ผู้ควบคุม, ผู้ช่วยเหลือ, ผู้ปฏิบัติงาน)\n• ห้ามลงปฏิบัติงานหากค่าออกซิเจนต่ำกว่า 19.5% หรือสูงกว่า 23.5%\n• ผู้ช่วยเหลือต้องประจำอยู่ที่ปากทางเข้าออกตลอดเวลา ห้ามละทิ้งหน้าที่เด็ดขาด',
        'steps_json': '[{"stepNumber":1,"title":"การเตรียมการและขออนุญาตทำงาน (Permit & 4-Roles Briefing)","action":"จัดทำใบอนุญาตทำงานในที่อับอากาศ (PTW) ตรวจสอบใบรับรองแพทย์และวุฒิบัตร 4 ผู้ของผู้ปฏิบัติงาน","safetyCheckpoint":"ใบอนุญาตทำงานต้องได้รับการลงนามอนุมัติจากผู้อนุญาตที่มีคุณสมบัติตามกฎหมาย"},{"stepNumber":2,"title":"การตัดแยกและระบายอากาศ (Isolation & Forced Ventilation)","action":"ทำการใส่แผ่นปิดกั้นท่อ (Blind Flange) ตัดแยกพลังงานไฟฟ้า LOTO ติดตั้งพัดลมเป่าอากาศบริสุทธิ์ต่อเนื่อง","safetyCheckpoint":"อัตราการเป่าระบายอากาศต้องไม่น้อยกว่า 20 เท่าของปริมาตรห้องต่อชั่วโมง"},{"stepNumber":3,"title":"การตรวจวัดสภาพบรรยากาศ (Pre-Entry Gas Testing)","action":"ใช้เครื่องตรวจวัดก๊าซแบบ 4 ก๊าซ วัดระดับความสูง 3 ระดับ (บน, กลาง, ล่าง) ก่อนอนุญาตให้ลงทำงาน","safetyCheckpoint":"O2: 19.5-23.5%, LEL: <10%, CO: <25 ppm, H2S: <10 ppm ต้องอยู่ในเกณฑ์ปลอดภัยทั้งหมด"},{"stepNumber":4,"title":"การลงปฏิบัติงานและการเฝ้าระวัง (Entry & Continuous Monitoring)","action":"ผู้ลงทำงานสวม Full Body Harness ต่อสายช่วยชีวิตเข้ากับรอกขาสามขา (Tripod) เปิดเครื่องวัดก๊าซแบบพกพาตลอดเวลา","safetyCheckpoint":"ผู้ช่วยเหลือบันทึกชื่อ เวลาเข้า-ออก และส่งสัญญาณสื่อสารกับผู้ปฏิบัติงานทุก 10 นาที"}]',
        'emergency_procedure': 'หากสัญญาณเตือนเครื่องวัดก๊าซดังขึ้นหรือผู้ปฏิบัติงานหมดสติ ผู้ช่วยเหลือภายนอกต้องหมุนรอกกู้ภัยเพื่อดึงตัวขึ้นมาทันที ห้ามผู้ช่วยเหลือมุดลงไปโดยไม่มีอุปกรณ์ช่วยหายใจ SCBA เด็ดขาด',
        'pdf_file_path': null,
        'author': 'ผู้ควบคุมงานในที่อับอากาศ',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้อนุญาตปฏิบัติงานในที่อับอากาศ',
        'status': 'ACTIVE',
      });

      // 5. Work at Heights SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-WGT-001',
        'title': 'ขั้นตอนการปฏิบัติงานบนที่สูงและการใช้อุปกรณ์ป้องกันการตก (Work at Height & Fall Arrest SOP)',
        'category': 'HEIGHTS',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดมาตรการป้องกันอันตรายจากการตกจากที่สูงของผู้ปฏิบัติงานตามกฎกระทรวงนั่งร้านและที่สูง พ.ศ. ๒๕๖๔',
        'scope': 'ครอบคลุมการปฏิบัติงานบนที่สูงตั้งแต่ 2.0 เมตรขึ้นไป นั่งร้าน กระเช้าลอย และงานบนหลังคา',
        'required_ppe': '["HELMET","BOOTS","HARNESS"]',
        'precautions': '• ต้องใช้ระบบผูกยึด 100% (100% Tie-off) ตลอดเวลาที่อยู่บนที่สูง\n• ห้ามใช้นั่งร้านที่มีป้ายสีแดง (Red Tag) หรือไม่มีราวกันตก\n• ห้ามปฏิบัติงานบนหลังคาหรือนั่งร้านกลางแจ้งขณะฝนตกหนักหรือลมแรง',
        'steps_json': '[{"stepNumber":1,"title":"การตรวจสอบพื้นที่และสภาพนั่งร้าน (Scaffold & Site Inspection)","action":"ตรวจสอบว่านั่งร้านมีแผ่นป้ายสีเขียว (Green Tag) ตรวจสอบราวกั้นตก (Guardrail) สูง 90-110 ซม. และแผ่นกันของตก (Toe board)","safetyCheckpoint":"นั่งร้านต้องผ่านการตรวจสอบจากผู้มีอำนาจและบันทึกผลไม่เกิน 7 วัน"},{"stepNumber":2,"title":"การตรวจสอบและสวมใส่ชุดนิรภัย (Full Body Harness Inspection)","action":"ตรวจสอบสายรัดตัว (Webbing) ตะขอสแน็ปฮุก และชุดดูดซับแรงกระแทก (Shock Absorber) สวมใส่และปรับสายให้แนบกระชับ","safetyCheckpoint":"ห่วง D-Ring ด้านหลังต้องอยู่ระดับกึ่งกลางระหว่างสะบักทั้งสองข้าง"},{"stepNumber":3,"title":"การเกี่ยวคล้องจุดยึดเหนี่ยว (100% Tie-off Anchor Connection)","action":"คล้องตะขอนิรภัยเข้ากับจุดยึดเหนี่ยว (Anchor Point) หรือสายช่วยชีวิตแนวนอน (Lifeline) ที่อยู่เหนือศีรษะขึ้นไป","safetyCheckpoint":"จุดยึดเหนี่ยวต้องสามารถรับแรงดึงได้อย่างน้อย 2,270 กิโลกรัม (5,000 ปอนด์) ต่อคน"}]',
        'emergency_procedure': 'กรณีผู้ปฏิบัติงานพลัดตกและติดค้างอยู่กับสายรัดตัว ให้ทีมกู้ภัยฉุกเฉินใช้อุปกรณ์กู้ภัยเข้าช่วยเหลือลงสู่พื้นภายใน 15 นาที เพื่อป้องกันอาการ Suspension Trauma',
        'pdf_file_path': null,
        'author': 'วิศวกรความปลอดภัยงานก่อสร้าง',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้จัดการฝ่ายความปลอดภัยและอาชีวอนามัย',
        'status': 'ACTIVE',
      });

      // 6. Fire Emergency & Evacuation SOP
      await db.insert('safety_manual_sops', {
        'doc_code': 'SOP-EMG-001',
        'title': 'ขั้นตอนการระงับเหตุเพลิงไหม้เบื้องต้นและการอพยพหนีไฟ (Fire Suppression & Evacuation SOP)',
        'category': 'EMERGENCY',
        'revision': 'Rev. 01',
        'effective_date': effectiveDateStr,
        'review_due_date': reviewDateStr,
        'purpose': 'เพื่อกำหนดขั้นตอนการปฏิบัติเมื่อเกิดเหตุเพลิงไหม้ฉุกเฉินและการอพยพหนีไฟตามกฎกระทรวงป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕',
        'scope': 'ครอบคลุมพนักงาน ผู้รับเหมา และผู้มาติดต่อทุกคนในทุกอาคารของสถานประกอบการ',
        'required_ppe': '["HELMET","BOOTS"]',
        'precautions': '• ห้ามใช้ลิฟต์โดยสารในขณะเกิดเพลิงไหม้เด็ดขาด ให้ใช้บันไดหนีไฟเท่านั้น\n• เมื่อได้ยินสัญญาณเตือนภัย ให้หยุดการทำงานและอพยพทันที ห้ามมัวเก็บสิ่งของ\n• ห้ามย้อนกลับเข้าไปในอาคารจนกว่าผู้บัญชาการเหตุการณ์จะประกาศปลอดภัย',
        'steps_json': '[{"stepNumber":1,"title":"การแจ้งเหตุและส่งสัญญาณเตือนภัย (Alarm & Communication)","action":"ผู้พบเห็นเพลิงไหม้กดปุ่มสัญญาณเตือนเพลิงไหม้ (Manual Call Point) และตะโกนแจ้งเตือนเพื่อนร่วมงาน พร้อมโทรแจ้งศูนย์ควบคุมเหตุฉุกเฉิน","safetyCheckpoint":"ระบุสถานที่เกิดเหตุ แผนก ชนิดของเชื้อเพลิง และจำนวนผู้ได้รับบาดเจ็บให้ชัดเจน"},{"stepNumber":2,"title":"การเข้าระงับเหตุเพลิงไหม้ขั้นต้น (Initial Fire Suppression)","action":"ทีมดับเพลิงเบื้องต้นนำถังดับเพลิงมือถือเข้าฉีดดับ โดยใช้หลักการ ดึง-ปลด-กด-ส่าย (P-A-S-S) ยืนเหนือลมระยะ 2-3 เมตร","safetyCheckpoint":"หากเพลิงลุกไหม้เกิน 2 นาที หรือควันหนาแน่น ให้ถอนตัวและปิดประตูกั้นไฟทันที"},{"stepNumber":3,"title":"การอพยพหนีไฟสู่จุดรวมพล (Evacuation to Assembly Point)","action":"หัวหน้าทีมอพยพนำพนักงานเดินตามป้ายทางหนีไฟลงทางบันไดหนีไฟ ก้มต่ำเมื่อมีควัน และเดินตรงไปยังจุดรวมพลหลัก","safetyCheckpoint":"เดินอย่างเป็นระเบียบ ไม่วิ่ง ไม่ผลักกัน ห้ามใช้ลิฟต์เด็ดขาด"},{"stepNumber":4,"title":"การตรวจนับยอดพนักงานและรายงานผล (Headcount & Status Report)","action":"หัวหน้าแผนกตรวจนับยอดพนักงาน ผู้รับเหมา และผู้มาติดต่อตามรายชื่อ แล้วรายงานต่อผู้บัญชาการเหตุการณ์ (Incident Commander)","safetyCheckpoint":"รายงานสถานะพนักงานครบถ้วน หรือระบุชื่อและจุดสุดท้ายที่พบผู้สูญหายทันที"}]',
        'emergency_procedure': 'หากพบผู้ติดค้างภายในอาคาร ให้แจ้งเจ้าหน้าที่ดับเพลิงประจำการหรือทีมกู้ภัยฉุกเฉินพร้อมอุปกรณ์ช่วยหายใจเข้าทำการค้นหา ห้ามบุคคลทั่วไปย้อนกลับเข้าไปโดยเด็ดขาด',
        'pdf_file_path': null,
        'author': 'ผู้ควบคุมทีมฉุกเฉินและระงับอัคคีภัย',
        'reviewer': 'จป.วิชาชีพ ประจำโรงงาน',
        'approver': 'ผู้อำนวยการฝ่ายบริหารโรงงาน',
        'status': 'ACTIVE',
      });
    }
  }

  // ========================================================
  // 14. FACTORY SAFETY SCOPE & MANUAL CONFIGURATION
  // ========================================================

  Future<void> _createManualScopeTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_factory_scope (
        id INTEGER PRIMARY KEY,
        has_boiler INTEGER DEFAULT 1,
        has_crane INTEGER DEFAULT 1,
        has_chemical INTEGER DEFAULT 1,
        has_confined_space INTEGER DEFAULT 1,
        has_working_at_height INTEGER DEFAULT 1,
        has_electrical_loto INTEGER DEFAULT 1,
        has_emergency_fire INTEGER DEFAULT 1,
        has_ppe INTEGER DEFAULT 1,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM safety_factory_scope');
    final scopeCount = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (scopeCount == 0) {
      await db.insert('safety_factory_scope', {
        'id': 1,
        'has_boiler': 1,
        'has_crane': 1,
        'has_chemical': 1,
        'has_confined_space': 1,
        'has_working_at_height': 1,
        'has_electrical_loto': 1,
        'has_emergency_fire': 1,
        'has_ppe': 1,
      });
    }
  }

  // ========================================================
  // 15. AUDIT & INSPECTION (SMS 2565 & FACTORY SCOPE)
  // ========================================================

  Future<void> _createAuditInspectionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audit_no TEXT NOT NULL UNIQUE,
        audit_title TEXT NOT NULL,
        audit_date TEXT NOT NULL,
        lead_auditor TEXT NOT NULL,
        auditor_team TEXT,
        audit_scope TEXT NOT NULL,
        status TEXT DEFAULT 'IN_PROGRESS',
        total_items INTEGER DEFAULT 0,
        conform_count INTEGER DEFAULT 0,
        minor_nc_count INTEGER DEFAULT 0,
        major_nc_count INTEGER DEFAULT 0,
        na_count INTEGER DEFAULT 0,
        compliance_percentage REAL DEFAULT 0.0,
        summary_notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audit_session_id INTEGER NOT NULL,
        category_code TEXT NOT NULL,
        category_title TEXT NOT NULL,
        clause_no TEXT NOT NULL,
        item_title TEXT NOT NULL,
        requirement_description TEXT NOT NULL,
        legal_reference TEXT NOT NULL,
        source_module TEXT,
        evidence_summary TEXT,
        evidence_link_id TEXT,
        result_status TEXT DEFAULT 'UNAUDITED',
        auditor_notes TEXT,
        suggested_action TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (audit_session_id) REFERENCES audit_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_findings_capa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audit_session_id INTEGER NOT NULL,
        checklist_item_id INTEGER,
        finding_no TEXT NOT NULL UNIQUE,
        finding_type TEXT NOT NULL,
        clause_ref TEXT NOT NULL,
        problem_description TEXT NOT NULL,
        root_cause TEXT,
        corrective_action TEXT NOT NULL,
        preventive_action TEXT,
        responsible_person TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT DEFAULT 'OPEN',
        completed_date TEXT,
        verifier_name TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (audit_session_id) REFERENCES audit_sessions(id) ON DELETE CASCADE
      )
    ''');
  }
}


