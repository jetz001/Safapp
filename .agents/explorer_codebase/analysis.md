# SAFAPP Environmental Monitoring Module — Codebase Architecture Exploration Report

## Executive Summary
This architectural exploration provides an in-depth analysis of the SAFAPP Flutter codebase (`safety_superapp`), establishing the foundational patterns, dependencies, database schema, state management paradigm, document generation pipelines, UI component hierarchy, and testing strategies. This report serves as the complete technical blueprint for implementing the **Environmental Monitoring Module (การตรวจวัดสภาพแวดล้อม: แสงสว่าง, เสียง, ความร้อน WBGT)** conforming to Thai Occupational Safety, Health and Environment Legislation (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวงความร้อน แสงสว่าง และเสียง ๒๕๕๙, และประกาศกรมสวัสดิการและคุ้มครองแรงงาน ๒๕๖๑, ๒๕๖๓).

---

## 1. Project Architecture & Dependency Analysis

### 1.1 Dependency Stack (`pubspec.yaml`)
| Package | Version | Purpose in SAFAPP | Usage Pattern / Notes |
|---|---|---|---|
| `flutter` | SDK | Core Flutter Framework | Material 3 enabled |
| `flutter_riverpod` | `^3.3.2` | Reactive State Management | `Notifier`, `AsyncNotifier`, `FutureProvider`, `Provider` |
| `sqflite_common_ffi` | `^2.4.0+3` | Cross-Platform SQLite Engine | Initialized with `sqfliteFfiInit()` & `databaseFactoryFfi` for Desktop |
| `sqlite3_flutter_libs` | `^0.6.0+eol` | Native SQLite Binaries | Windows / Desktop C library support |
| `path` & `path_provider` | `^1.9.1` / `^2.1.6` | Filesystem Navigation | Persistent document storage under `Documents/SafetySuperapp/` |
| `pdf` & `printing` | `^3.12.0` / `^5.14.3` | Statutory PDF Report Generation | `PdfGoogleFonts.sarabunRegular()`, A4 layout, printing/sharing |
| `excel` | `^4.0.6` | Multi-Sheet Audit Spreadsheet | Workbooks with `TextCellValue`, `IntCellValue`, `DoubleCellValue` |
| `syncfusion_flutter_pdfviewer` | `^33.2.13` | In-App PDF Viewing | Interactive preview of official gazettes, certificates, and reports |
| `file_picker` | `^11.0.3` | Multi-file Attachment Engine | Custom extensions filter (`pdf`, `png`, `jpg`, `xlsx`, `docx`) |
| `fl_chart` | `^1.2.0` | Executive KPI Visualizations | Donut pie charts (`PieChart`), Bar charts, Gauge meters |
| `google_fonts` | `^8.2.1` | Typography & Localization | Google Fonts `Prompt` text theme across the entire application |
| `cupertino_icons` | `^1.0.8` | Secondary Icons | iOS / Cupertino icon support |

### 1.2 Module Organization (`lib/`)
The codebase strictly adheres to **Feature-First Domain-Driven Design (DDD)**:

```
lib/
├── core/
│   ├── data/
│   │   └── thai_address_data.dart            # Thai 77 provinces, districts, subdistricts, zipcodes
│   ├── database/
│   │   └── database_helper.dart              # Central SQLite helper, migrations, table creations
│   ├── providers/
│   │   └── database_provider.dart            # Global SQLite database FutureProvider
│   └── widgets/
│       ├── app_shell.dart                    # Main navigation shell with sidebar NavigationRail
│       ├── glass_container.dart              # Glassmorphic frosted glass container
│       └── thai_address_cascade_widget.dart  # 3-tier cascading address picker with auto zip-code
├── features/
│   ├── audit_inspection/
│   ├── chemicals/                            # Chemical inventory, SDS Sor.1, Sor.3 measurements
│   ├── contractor/                           # Contractor directory, workers, passes, violations
│   ├── dashboard/                            # Central safety metrics & executive dashboard
│   ├── emergency/
│   ├── employee/                             # Employees, training courses, safety committees
│   ├── environment/                          # Environmental Monitoring Module (target feature)
│   │   └── presentation/pages/environment_page.dart # Current placeholder
│   ├── health_hygiene/                       # Employee health checks, audiograms, surveillance
│   ├── landing/                              # Landing hub & navigation router
│   ├── legal_register/                       # Legal Register & Compliance Evaluation (Reference Module)
│   ├── near_miss_incident/                   # Near-miss forms, incident investigations, RCA
│   ├── ppe_asl/
│   ├── ptw/                                  # Permit to Work
│   ├── risk_assessment/                      # JSA, Por.1, Por.2 risk control plans
│   ├── safety_manual/
│   ├── settings/
│   └── sms_setup/
└── main.dart                                 # Application entrypoint with ProviderScope & Prompt theme
```

---

## 2. Navigation, Routing & Shell Architecture

### 2.1 Top-Level Navigation (`AppShell`)
- Located in `lib/core/widgets/app_shell.dart`.
- Uses a **Glassmorphic Sidebar NavigationRail** (`width: 100px`) inside a `GlassContainer(blur: 30, opacity: 0.4)` over a soft gradient background (`#E0F2FE` -> `#F3E8FF` -> `#FCE7F3`).
- **Environmental Monitoring** is destination index **11**:
  - Icon: `Icons.thermostat_outlined` / `Icons.thermostat`
  - Label: `'สิ่งแวดล้อม'`
  - Target Page: `const EnvironmentPage()`

### 2.2 Feature-Level Navigation Pattern
Each feature page (e.g. `LegalPage`, `ChemicalsPage`) uses a **Material 3 TabBar & TabBarView** driven by a `TabController` with `SingleTickerProviderStateMixin`:
- Synchronizes with a Riverpod `NotifierProvider` for selected tab index (e.g. `envSelectedTabProvider`).
- Provides clean separation across functional workflows (e.g. Dashboard & Sessions, Point Measurements, CAPA & Hearing Conservation, Royal Gazette Library).

---

## 3. State Management Paradigm (Riverpod v3)

SAFAPP utilizes Riverpod v3 with the following established structure:

```
[ UI Layer: ConsumerStatefulWidget / ConsumerWidget ]
        │                       ▲
        │ ref.watch / ref.read  │ AsyncValue (data / loading / error)
        ▼                       │
[ Providers: Notifier / AsyncNotifier / FutureProvider ]
        │                       ▲
        │ Invokes repository    │ Returns domain models / stats
        ▼                       │
[ Repository Layer: Data & Database Helper ]
        │                       ▲
        │ SQL queries / CRUD    │ SQLite Rows / Filesystem bytes
        ▼                       │
[ Persistence Layer: SQLite (sqflite_ffi) & Filesystem (Documents/SafetySuperapp/) ]
```

### 3.1 Standard Provider Declarations
1. **Filter State Notifiers (`NotifierProvider`)**:
   - `searchQueryProvider`: Query text (`String`) with `state = val` and `clear()`.
   - `categoryFilterProvider` / `sessionFilterProvider`: Filter choices (`String` / `int`) with `reset()`.
   - `selectedTabProvider`: Active tab index (`int`).
2. **Entity List Notifiers (`AsyncNotifierProvider`)**:
   - Manages lists of records (e.g. `EnvironmentSessionListNotifier`, `EnvironmentPointListNotifier`, `EnvironmentCapaListNotifier`).
   - `build()` method watches query and filter providers, querying the repository asynchronously.
   - Mutating methods (`saveSession`, `deletePoint`, `closeCapa`) invalidate `ref.invalidateSelf()` and related KPI providers (`ref.invalidate(envKpiProvider)`).
3. **KPI & Aggregate Providers (`FutureProvider`)**:
   - Watches the repository and computes composite statistics dynamically (`EnvironmentStatsModel.calculate(...)`).
4. **Detail Lookups (`FutureProvider.family<T, Key>`)**:
   - Watches individual records by primary key or session ID.

---

## 4. Data Storage & Persistence Layer

### 4.1 SQLite Engine Architecture (`DatabaseHelper`)
- Defined in `lib/core/database/database_helper.dart`.
- Platform initialization:
  ```dart
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  ```
- Storage Location: `getApplicationDocumentsDirectory() / 'SafetySuperapp' / 'safety_superapp_v1.db'`.
- Database version: `version: 6` (Migrate to `version: 7` for Environment module).
- Automatic lifecycle execution: `_onCreate`, `_onUpgrade`, `_onOpen` with defensive `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`.

### 4.2 Storage Schema for Environmental Monitoring
The database requires tables to support Requirements R1-R4:

1. **`environment_standards_master`**:
   - Catalog of statutory standards from Royal Gazette 2559, 2561, 2563.
   - Fields: `id`, `standard_type` ('LIGHT', 'NOISE', 'HEAT'), `category_name`, `task_description`, `min_lux_value`, `max_lux_value`, `noise_twa_limit_dba` (86.0), `noise_action_level_dba` (85.0), `noise_peak_limit_db` (140.0), `wbgt_indoor_formula`, `wbgt_outdoor_formula`, `work_load_type` ('LIGHT', 'MEDIUM', 'HEAVY'), `wbgt_limit_celsius` (34.0, 32.0, 30.0), `reference_law_title`.

2. **`environment_sessions`**:
   - Annual/periodic monitoring sessions.
   - Fields: `id`, `session_title`, `session_year`, `measurement_date`, `location_plant`, `objective`, `subcontractor_type` ('M9_INDIVIDUAL' / 'M11_JURISTIC'), `subcontractor_company_name`, `subcontractor_reg_number`, `surveyor_name`, `surveyor_license_no`, `certifier_name`, `certifier_reg_no`, `pdf_report_path`, `calibration_cert_paths` (JSON list), `subcontractor_license_path`, `site_photo_paths` (JSON list), `status` ('DRAFT', 'COMPLETED', 'APPROVED'), `created_at`, `updated_at`.

3. **`environment_measurement_points`**:
   - Detailed point measurements across the 3 physical parameters.
   - Fields: `id`, `session_id` (FK), `point_code`, `department_area`, `parameter_type` ('LIGHT', 'NOISE', 'HEAT'), `task_or_machine_name`, `light_measured_lux`, `light_standard_min_lux`, `noise_measurement_type` ('AREA', 'PERSONAL_TWA', 'PEAK'), `noise_measured_dba`, `noise_duration_hours`, `noise_standard_limit_dba`, `heat_location_condition` ('INDOOR', 'OUTDOOR'), `heat_nwb_celsius`, `heat_gt_celsius`, `heat_db_celsius`, `heat_calculated_wbgt`, `heat_work_load` ('LIGHT', 'MEDIUM', 'HEAVY'), `heat_standard_limit_celsius`, `evaluation_result` ('PASS', 'ACTION_LEVEL', 'EXCEEDED'), `requires_hearing_conservation` (INT 0/1), `requires_capa` (INT 0/1), `notes`, `created_at`, `updated_at`.

4. **`environment_capa`**:
   - Corrective actions and hearing conservation tracking.
   - Fields: `id`, `point_id` (FK), `session_id`, `parameter_type`, `action_title`, `hazard_description`, `engineering_control`, `administrative_control`, `ppe_control`, `pic_name`, `pic_department`, `target_date`, `completed_date`, `status` ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE'), `hearing_program_enrolled` (INT 0/1), `evidence_file_path`, `notes`, `created_at`, `updated_at`.

### 4.3 Multi-Category Attachment Management
In `LegalRegisterRepository` and `ChemicalRepository`, files picked via `FilePicker` are persisted to a designated folder:
```dart
Future<String?> persistAttachment(String sourcePath, {String prefix = 'env_doc'}) async {
  final srcFile = File(sourcePath);
  if (!await srcFile.exists()) return sourcePath;

  final appDocDir = await getApplicationDocumentsDirectory();
  final targetDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'environment'));
  if (!await targetDir.exists()) await targetDir.create(recursive: true);

  final ext = p.extension(sourcePath);
  final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
  final targetFile = File(p.join(targetDir.path, filename));

  await srcFile.copy(targetFile.path);
  return targetFile.path;
}
```

---

## 5. Document & Report Generation Architecture

### 5.1 Official PDF Export (`pdf` & `printing`)
The SAFAPP standard for statutory PDF generation includes:
- **Font Support**: `PdfGoogleFonts.sarabunRegular()`, `sarabunBold()`, and `sarabunItalic()` loaded asynchronously.
- **Page Layout**: `pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape)` for wide tabular layouts with headers, footers, and page numbers.
- **Statutory Sections**:
  1. Executive header with organization profile, tax ID, session metadata.
  2. KPI dashboard summary boxes (% Compliance, Pass/Action Level/Exceeded counters).
  3. Master parameter tables: Lighting Lux, Noise dBA (Action Level >= 85 dBA flagged), Heat WBGT calculations.
  4. Outsource Service Provider certification block (Section 9/11 compliance).
  5. CAPA Action Plan & Hearing Conservation Program status.
  6. 3-Tier Endorsement & Signature block: (1) Measuring Officer / Outsource Certifier (ม.๙ / ม.๑๑), (2) Safety Officer (จป.วิชาชีพ) / คปอ., (3) Authorized Management.

### 5.2 Multi-Sheet Excel Export (`excel`)
- **Engine**: `excel: ^4.0.6` generating native `.xlsx` files.
- **Sheet Architecture**:
  - `Sheet 1: Environmental KPI & Sessions`: Session overview, Subcontractor credentials, KPI summary.
  - `Sheet 2: Point Measurements (Light, Noise, Heat)`: Comprehensive raw measurement data with automatic pass/fail formulas.
  - `Sheet 3: CAPA & Hearing Conservation`: Engineering/Administrative/PPE controls, PIC, target dates, completion status.
- **File Output**: Written to `Documents/SafetySuperapp/exports/`.

---

## 6. UI Patterns & Component Catalog

### 6.1 Layout & Visual Theme
- **Theme Seed**: `#1E3A8A` (Deep Navy) with Google Fonts `Prompt`.
- **Status Color Coding**:
  - **Pass / Normal (ผ่านเกณฑ์)**: `#10B981` (Emerald Green) / Background `#ECFDF5`
  - **Action Level / Surveillance (เฝ้าระวัง >= 85 dBA / > 50% Limit)**: `#F59E0B` (Amber) / Background `#FFFBEB`
  - **Exceeded / Non-Compliant (เกินเกณฑ์มาตรฐาน)**: `#EF4444` (Crimson Red) / Background `#FEF2F2`
  - **Not Applicable / Draft**: `#6B7280` (Cool Gray) / Background `#F3F4F6`

### 6.2 Existing Core Component Library
1. **KPI Dashboard Cards**:
   - Dual-gauge donut charts (`PieChart` from `fl_chart`) for Overall % Compliance and Parameter Breakdown.
   - Metric cards with status counts and warning chips for critical thresholds.
2. **Filter & Search Bar (`FilterBar`)**:
   - Search `TextField`, Parameter choice chips (All, Light, Noise, Heat), Status dropdown, and Export buttons (PDF & Excel).
3. **Point Measurement Table & Cards**:
   - Grouped cards displaying point code, department, work task, measured value vs statutory standard, formula breakdown, and colored evaluation badge.
4. **Interactive Modals & Dialogs**:
   - `EnvironmentSessionDialog`: Form for session details, subcontractor selection (Section 9 vs 11), and multi-document attachment dropzone with preview buttons.
   - `EnvironmentPointDialog`: Parameter-specific form with live auto-evaluation (calculating WBGT dynamically from NWB, GT, DB and assessing against metabolic workload; matching Lux against standard table; flagging Hearing Conservation for noise >= 85 dBA).
   - `EnvironmentCapaDialog`: Hierarchy of controls (Engineering, Admin, PPE), PIC, target date, and hearing program status.
   - `GazetteViewerDialog`: Tab 1 structured legal breakdown; Tab 2 interactive `SfPdfViewer` or simulated Royal Gazette parchment.

---

## 7. Testing Setup & Validation Methodology

### 7.1 Test Framework
- Test suites reside in `test/`.
- Key files include `legal_register_models_and_repo_test.dart`, `legal_register_ui_test.dart`, `chemical_management_test.dart`, and `chemical_adversarial_challenge_test.dart`.

### 7.2 Required Environmental Test Suites
To satisfy Acceptance Criteria A4, four dedicated test groups must be constructed:
1. **Mathematical & Statutory Formula Tests**:
   - WBGT Indoor calculation: $0.7 \times NWB + 0.3 \times GT$
   - WBGT Outdoor calculation: $0.7 \times NWB + 0.2 \times GT + 0.1 \times DB$
   - Workload limit assessment (Light $\le 34^\circ\text{C}$, Medium $\le 32^\circ\text{C}$, Heavy $\le 30^\circ\text{C}$)
   - Lighting Lux standard threshold lookups across all workplace types (50, 100, 200, 300, 400, 800, 1000 Lux).
   - Noise evaluation: Normal $\le 85\text{ dBA}$, Action Level $85\text{--}86\text{ dBA}$ (triggers Hearing Conservation), Exceeded $> 86\text{ dBA}$ (8-hr TWA), Peak $> 140\text{ dB}$, Continuous $> 115\text{ dBA}$.
2. **Repository & SQLite CRUD Tests**:
   - Sessions, point measurements, and CAPA storage round-trips.
   - Foreign key integrity and cascading deletes.
3. **KPI & Statistics Aggregator Tests**:
   - Overall % Compliance, Parameter-specific compliance rates, zero-denominator edge cases.
4. **Widget & Main Page UI Tests**:
   - 4-Tab navigation testing with Riverpod mock `AsyncNotifier` overrides.
   - Live form input validation and dialog rendering.

---

## 8. Multi-Agent Skill Integration (`thai-environmental-safety-law`)

In alignment with Requirement R6:
- **Skill Location**: `.gemini/config/skills/thai-environmental-safety-law/SKILL.md`
- **CLI Script**: `.gemini/config/skills/thai-environmental-safety-law/scripts/thai_env_cli.py`
- **AgentResearch Helper**: `D:\DEV\AgentResearch\Scripts\thai_env_helper.py`
- **CLI Commands Supported**:
  - `search-light <query>`: Lookup minimum lux standards.
  - `eval-noise <dba> [--type area|twa|peak]`: Evaluate noise level and hearing conservation triggers.
  - `calc-wbgt --nwb <val> --gt <val> [--db <val>] [--outdoor] [--workload light|medium|heavy]`: Compute WBGT and evaluate compliance.
  - `eval-session <json_file>`: Batch evaluation of an entire measurement session.

---

## 9. Implementation Roadmap & Checklist

| Phase | Component | Key Files to Create / Modify |
|---|---|---|
| **Phase 1: Domain & Data** | Master Standards, Models, SQLite Schema v7, Repository | `lib/core/database/database_helper.dart`<br>`lib/features/environment/domain/models/`<br>`lib/features/environment/data/` |
| **Phase 2: State Management** | Riverpod Notifiers, Filter State, KPI Engine | `lib/features/environment/presentation/providers/environment_providers.dart` |
| **Phase 3: Presentation UI** | 4-Tab Environment Page, Dialogs, KPI Dashboard, Filter Bar | `lib/features/environment/presentation/pages/environment_page.dart`<br>`lib/features/environment/presentation/widgets/` |
| **Phase 4: Document Exporters** | Official PDF & Excel Services, Gazette Viewer | `lib/features/environment/services/environment_pdf_service.dart`<br>`lib/features/environment/services/environment_excel_service.dart` |
| **Phase 5: Agent Skill** | Skill definition, Python CLI, AgentResearch helper | `.gemini/config/skills/thai-environmental-safety-law/`<br>`D:\DEV\AgentResearch\Scripts/` |
| **Phase 6: Quality Assurance** | Comprehensive Unit, Model, KPI, and UI Tests | `test/environment_models_and_repo_test.dart`<br>`test/environment_ui_test.dart`<br>`test/environment_adversarial_challenge_test.dart` |
