import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../features/legal_register/data/safety_legal_8_categories_data.dart';
import '../../features/environment/data/environmental_standards_data.dart';

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
        version: 7,
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
  }

  Future<void> _onOpen(Database db) async {
    await _createRiskAssessmentTables(db);
    await _createChemicalTables(db);
    await _createLegalTables(db);
    await _createEnvironmentTables(db);
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
}
