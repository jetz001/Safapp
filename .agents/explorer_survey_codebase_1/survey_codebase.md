# SAFAPP Codebase & Flutter Architecture Survey Report
**Target Module**: Safety Legal Register & Compliance Evaluation (ระบบทะเบียนและการประเมินความสอดคล้องตามกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน)
**Author**: Explorer Survey Agent
**Date**: 2026-08-31
**Working Directory**: `d:\DEV\SAFAPP\.agents\explorer_survey_codebase_1`

---

## 1. Executive Summary & Codebase Architecture

The **SAFAPP** application is a comprehensive Occupational Safety, Health, and Environment (OSH&E / จป. & คปอ.) SuperApp built with **Flutter Desktop & Mobile** (Dart SDK `^3.11.5`). It manages industrial safety workflows, regulatory compliance, risk assessments, contractor management, occupational health surveillance, and hazardous chemical management under Thai Ministry of Labour (DLPW) and Ministry of Industry (DIW) statutory standards.

### 1.1 Architecture Pattern & Project Topology
The codebase strictly adheres to **Feature-First Clean Architecture**, divided into four standard horizontal layers per feature module:

```
d:\DEV\SAFAPP\
├── pubspec.yaml                 # Core dependencies (Riverpod 3, Sqflite FFI, Syncfusion, Excel, PDF, etc.)
├── analysis_options.yaml        # Flutter recommended lints
├── lib/
│   ├── main.dart                # ProviderScope entry point, Prompt Google Font theme
│   ├── core/                    # Cross-cutting foundational infrastructure
│   │   ├── database/            # DatabaseHelper (SQLite v5 with desktop FFI factory)
│   │   ├── providers/           # databaseProvider
│   │   ├── data/                # Thai administrative address cascade data
│   │   └── widgets/             # AppShell (Sidebar NavigationRail), GlassContainer
│   └── features/                # 17 Independent domain feature packages
│       ├── landing/             # Portal Hub, Live KPI cards, quick actions, 15-module directory
│       ├── sms_setup/           # Company profiles, Safety expert (ม.๓๓), DLPW registration
│       ├── dashboard/           # Global executive safety analytics & fl_chart graphs
│       ├── near_miss_incident/  # Accident investigation, 5W1H, RCA, CAPA, official PDF
│       ├── risk_assessment/     # JSA, Por 1 (ปอ.๑), Por 2 (ปอ.๒), interactive matrix, PDF/Excel
│       ├── ptw/                 # Permit-To-Work high-risk authorizations
│       ├── audit_inspection/    # Safety inspection checklists
│       ├── employee/            # Employee master records, statutory training courses, committees
│       ├── contractor/          # Contractor directory, workers, safety induction passes
│       ├── health_hygiene/      # Medical checkups, risk factor surveillance, fit-to-work
│       ├── chemicals/           # 1,516 chemicals seed, 324 TLVs, Form สอ.๑ & สอ.๓ ๒๕๖๕
│       ├── environment/         # Waste, air, water, emissions monitoring
│       ├── ppe_asl/             # PPE inventory, ASL distribution matrix
│       ├── emergency/           # Fire drills, emergency response plans
│       ├── safety_manual/       # SOPs and standard safety procedures
│       ├── legal_register/      # [TARGET MODULE] Safety Legal Register & Compliance Assessment
│       └── settings/            # System backup, preferences, user accounts
├── skills/                      # Standalone Agent Skills (e.g., thai-chemical-safety-law)
└── test/                        # Automated unit, integration, and adversarial challenge suites
```

---

## 2. Package Dependencies & Tech Stack Analysis

Inspecting `pubspec.yaml` reveals the complete production technology stack:

| Package | Version | Purpose in SAFAPP | Usage Pattern in Target Module |
|---|---|---|---|
| `flutter_riverpod` | `^3.3.2` | Primary Reactive State Management | `Notifier`, `AsyncNotifier`, `NotifierProvider`, `AsyncNotifierProvider`, `FutureProvider` |
| `sqflite_common_ffi` | `^2.4.0+3` | Offline Desktop SQLite engine | Native SQLite FFI initialization in Windows/Desktop environments |
| `sqlite3_flutter_libs` | `^0.6.0+eol` | Bundled SQLite binaries | Embedded C SQLite libraries for desktop runtime |
| `path` & `path_provider` | `^1.9.1` / `^2.1.6` | Filesystem & document directories | Storing database files and attached evidence (`SafetySuperapp/legal/`) |
| `syncfusion_flutter_pdfviewer` | `^33.2.13` | In-app document viewer | Interactive viewer for Royal Gazette PDFs & uploaded audit evidence |
| `pdf` & `printing` | `^3.12.0` / `^5.14.3` | Statutory PDF generation | High-fidelity statutory reports with Thai `PdfGoogleFonts.sarabunRegular/Bold` |
| `excel` | `^4.0.6` | Spreadsheet import/export | Multi-tab `.xlsx` workbook generation for Legal Register & CAPA |
| `file_picker` | `^11.0.3` | Document attachment picker | Selecting local PDF documents, certificates, inspection photos |
| `fl_chart` | `^1.2.0` | Analytics & Data Visualization | Pie charts, bar graphs, % compliance progress gauges |
| `google_fonts` | `^8.2.1` | Typography | Modern Prompt font family across the UI |

---

## 3. Existing State Management & Navigation Design Patterns

### 3.1 Riverpod 3 Architecture Pattern
SAFAPP strictly implements Riverpod 3 notifier architectures:
1. **Filtering & UI State**:
   ```dart
   class LegalSearchQueryNotifier extends Notifier<String> {
     @override
     String build() => '';
     @override
     set state(String val) => super.state = val;
   }
   final legalSearchQueryProvider = NotifierProvider<LegalSearchQueryNotifier, String>(LegalSearchQueryNotifier.new);
   ```
2. **Async Data Collections & CRUD**:
   ```dart
   class LegalAssessmentListNotifier extends AsyncNotifier<List<LegalComplianceAssessmentModel>> {
     @override
     Future<List<LegalComplianceAssessmentModel>> build() async {
       final repo = ref.watch(legalRepoProvider);
       final query = ref.watch(legalSearchQueryProvider);
       final category = ref.watch(legalCategoryFilterProvider);
       final status = ref.watch(legalStatusFilterProvider);
       return await repo.getAllAssessments(query: query, category: category, status: status);
     }
     Future<int> saveAssessment(LegalComplianceAssessmentModel item, {String? newEvidencePath}) async {
       final repo = ref.read(legalRepoProvider);
       final id = await repo.saveAssessment(item, newEvidencePath: newEvidencePath);
       ref.invalidateSelf();
       ref.invalidate(legalComplianceKpiProvider);
       return id;
     }
   }
   ```
3. **Reactive Computed KPI Stats**:
   `FutureProvider` or `Provider` watching repository or async lists to compute:
   - Total applicable legal items
   - % Compliance Score = `(Compliant Count / (Total - Not Applicable)) * 100`
   - Non-compliant & In-progress items requiring CAPA
   - Overdue CAPA count

### 3.2 Navigation & Routing Integration
- **`AppShell` (`lib/core/widgets/app_shell.dart`)**:
  - `NavigationRail` index **15** routes directly to `LegalPage()` with icon `Icons.gavel_rounded` and label `'กฎหมาย'`.
- **`LandingPage` (`lib/features/landing/presentation/pages/landing_page.dart`)**:
  - Module Category 4: *หมวดที่ ๔: การบริหารจัดการ & กฎหมาย (Governance & Compliance)* routes item `'ทะเบียนกฎหมายความปลอดภัย'` to `targetIndex: 15`.
  - Quick action card and KPI widget can also link directly to index 15.

---

## 4. Safety Legal Register Module Design Blueprint

The Safety Legal Register module (`lib/features/legal_register/`) must provide end-to-end statutory compliance management covering 8 core Thai safety regulations.

### 4.1 Required Directory & File Structure
```
lib/features/legal_register/
├── data/
│   ├── datasources/
│   │   └── safety_legal_8_categories_data.dart     # Master dataset containing 8 Royal Gazette laws & 40+ statutory articles
│   └── repositories/
│       └── legal_register_repository.dart           # SQLite CRUD, file persistence, compliance KPI aggregation
├── domain/
│   └── models/
│       ├── legal_master_item_model.dart             # Law master definition & provisions
│       ├── legal_compliance_assessment_model.dart   # Facility compliance evaluation record
│       ├── legal_capa_model.dart                    # CAPA action items & root cause tracking
│       └── legal_compliance_stats_model.dart        # Aggregated KPI & compliance index metrics
├── presentation/
│   ├── pages/
│   │   └── legal_page.dart                          # 3 Main statutory tabs with KPI summary banner
│   ├── providers/
│   │   └── legal_register_providers.dart            # Riverpod 3 notifiers for filters, list, CAPA, KPIs
│   └── widgets/
│       ├── legal_assessment_dialog.dart             # Form for evaluating compliance and attaching evidence
│       ├── legal_capa_dialog.dart                   # Form for creating/editing CAPA action plans
│       ├── legal_compliance_kpi_card.dart           # Visual KPI cards (% compliance, pie chart, breakdown)
│       ├── legal_doc_viewer_dialog.dart             # SfPdfViewer / image modal for evidence and gazette files
│       └── legal_filter_bar.dart                    # Interactive search, category, and status filter chips
└── services/
    ├── legal_compliance_pdf_service.dart            # Statutory compliance report generator (Sarabun font)
    └── legal_compliance_excel_service.dart          # Multi-sheet Excel workbook export (.xlsx)
```

---

## 5. SQLite Database Schema Specification

Upgrading SQLite schema in `DatabaseHelper` (`lib/core/database/database_helper.dart`):

### 5.1 Tables Definition
```sql
-- 1. Master Legal Catalog (กฎหมายแม่บทและข้อกำหนดราชกิจจานุเบกษา)
CREATE TABLE IF NOT EXISTS safety_legal_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  law_code TEXT NOT NULL UNIQUE,          -- เช่น 'ACT-2554', 'MR-SAFETY-OFFICER-2565', 'MR-CHEM-2556'
  law_title_th TEXT NOT NULL,
  law_title_en TEXT NOT NULL,
  category TEXT NOT NULL,                -- 'ACT_2554', 'SAFETY_OFFICER', 'CHEMICAL', 'FIRE', 'ELECTRICAL', 'MACHINERY', 'ENVIRONMENT', 'HEALTH_SURVEILLANCE'
  issuing_authority TEXT NOT NULL,       -- 'DLPW (กรมสวัสดิการและคุ้มครองแรงงาน)', 'DIW', ฯลฯ
  gazette_date TEXT NOT NULL,
  gazette_volume TEXT,
  gazette_part TEXT,
  summary TEXT NOT NULL,
  key_provisions_json TEXT NOT NULL,     -- JSON Array of articles/sub-requirements
  pdf_asset_path TEXT,
  sort_order INTEGER DEFAULT 0
);

-- 2. Compliance Evaluation (ทะเบียนและการประเมินความสอดคล้องระดับสถานประกอบการ)
CREATE TABLE IF NOT EXISTS safety_legal_assessments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  master_law_id INTEGER,
  requirement_code TEXT NOT NULL,         -- เช่น 'SEC-16-TRAIN', 'CHEM-SOR1-16GHS', 'FIRE-EVAC-40'
  requirement_title TEXT NOT NULL,
  requirement_details TEXT NOT NULL,
  category TEXT NOT NULL,
  is_applicable INTEGER DEFAULT 1,        -- 1 = เกี่ยวข้อง, 0 = ไม่เกี่ยวข้อง (Not Applicable)
  compliance_status TEXT NOT NULL,        -- 'COMPLIANT', 'NON_COMPLIANT', 'IN_PROGRESS', 'NOT_APPLICABLE'
  actual_practice TEXT,                   -- การปฏิบัติจริงของสถานประกอบการ
  evaluated_date TEXT NOT NULL,
  next_review_date TEXT,
  evaluator_name TEXT NOT NULL,           -- จป.วิชาชีพ / คปอ. / ผู้จัดการ
  evaluator_role TEXT,
  department TEXT,
  evidence_file_paths TEXT,               -- Comma or JSON array of persisted file paths
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (master_law_id) REFERENCES safety_legal_master(id) ON DELETE SET NULL
);

-- 3. CAPA Action Plans (แผนการปรับปรุงแก้ไขข้อบกพร่องทางกฎหมาย)
CREATE TABLE IF NOT EXISTS safety_legal_capa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  assessment_id INTEGER NOT NULL,
  action_title TEXT NOT NULL,
  root_cause TEXT NOT NULL,               -- สาเหตุรากเหง้า
  corrective_action TEXT NOT NULL,        -- มาตรการแก้ไข (Corrective Action)
  preventive_action TEXT,                 -- มาตรการป้องกันการเกิดซ้ำ (Preventive Action)
  pic_name TEXT NOT NULL,                 -- ผู้รับผิดชอบดำเนินการ (Person In Charge)
  pic_department TEXT,
  target_date TEXT NOT NULL,              -- กำหนดเสร็จ (YYYY-MM-DD)
  completed_date TEXT,
  status TEXT DEFAULT 'PENDING',          -- 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE'
  evidence_file_path TEXT,
  supervisor_acknowledged_date TEXT,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (assessment_id) REFERENCES safety_legal_assessments(id) ON DELETE CASCADE
);
```

---

## 6. Master Legal Catalog (8 Categories of Thai Royal Gazette Laws)

The seed dataset in `safety_legal_8_categories_data.dart` covers:

| # | Regulation Category | Official Thai Title | Gazette Year / Volume | Key Enforced Requirements |
|---|---|---|:---:|---|
| **1** | **พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔** | พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ | ๒๕๕๔ (เล่ม ๑๒๘ ตอน ๔ ก) | มาตรา ๑๔ (แจ้งสิทธิ/อันตราย), มาตรา ๑๖ (ฝึกอบรมลูกจ้างใหม่), มาตรา ๓๒ (การประเมินอันตราย), มาตรา ๓๔ (แจ้งอุบัติเหตุ/เพลิงไหม้) |
| **2** | **จป. & คปอ. ๒๕๖๕** | กฎกระทรวงการจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕ | ๒๕๖๕ (เล่ม ๑๓๙ ตอน ๓๗ ก) | การแต่งตั้ง จป.บริหาร/หัวหน้างาน/วิชาชีพ, การจัดตั้ง คปอ. (ลูกจ้าง ๕๐ คนขึ้นไป), การประชุม คปอ. ประจำเดือน, การรายงาน จป. (สป.๑/จป.ว) |
| **3** | **สารเคมีอันตราย ๒๕๕๖** | กฎกระทรวงกำหนดมาตรฐานฯ สารเคมีอันตราย พ.ศ. ๒๕๕๖ | ๒๕๕๖ (เล่ม ๑๓๐ ตอน ๑๑๓ ก) | บัญชีรายชื่อสารเคมีอันตราย (๑,๕๑๖ รายการ), SDS ๑๖ ข้อ (แบบ สอ.๑), ตรวจวัดบรรยากาศการทำงาน (แบบ สอ.๓ ๒๕๖๕), ตรวจสุขภาพตามปัจจัยเสี่ยงเคมี |
| **4** | **อัคคีภัย ๒๕๕๕** | กฎกระทรวงกำหนดมาตรฐานฯ การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ | ๒๕๕๖ (เล่ม ๑๓๐ ตอน ๒ ก) | การจัดให้มีอุปกรณ์ดับเพลิงมือถือ, แผนป้องกันและระงับอัคคีภัย, การฝึกซ้อมดับเพลิงและอพยพหนีไฟประจำปี (ลูกจ้างไม่น้อยกว่า ๔๐%), ทางหนีไฟ |
| **5** | **ไฟฟ้า ๒๕๕๘** | กฎกระทรวงกำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ | ๒๕๕๘ (เล่ม ๑๓๒ ตอน ๑๑ ก) | การตรวจสอบและรับรองระบบไฟฟ้าประจำปีโดยวิศวกร, แผนผังวงจรไฟฟ้า (Single Line Diagram), ระบบต่อลงดิน (Grounding), ป้ายเตือนอันตรายไฟฟ้า |
| **6** | **เครื่องจักร ปั้นจั่น หม้อน้ำ ๒๕๖๔** | กฎกระทรวงกำหนดมาตรฐานฯ เครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔ | ๒๕๖๔ (เล่ม ๑๓๘ ตอน ๕๙ ก) | การ์ดป้องกันส่วนหมุนเครื่องจักร, การตรวจทดสอบปั้นจั่น/เครนตามระยะ (แบบ ปจ.๑/ปจ.๒), การอบรมผู้บังคับปั้นจั่น ๔ ผู้, การตรวจทดสอบหม้อน้ำ (Boiler) |
| **7** | **สภาพแวดล้อม (แสง เสียง ความร้อน) ๒๕๕๙** | กฎกระทรวงกำหนดมาตรฐานฯ ความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ | ๒๕๕๙ (เล่ม ๑๓๓ ตอน ๙๑ ก) | ตรวจวัดระดับความเข้มของแสงสว่าง (Lux), ตรวจวัดระดับเสียงเฉลี่ย 8 ชม. (Leq 85 dBA) และโครงการอนุรักษ์การได้ยิน (HCP), ตรวจวัดดัชนี WBGT |
| **8** | **ตรวจสุขภาพตามปัจจัยเสี่ยง ๒๕๖๓** | กฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓ | ๒๕๖๓ (เล่ม ๑๓๗ ตอน ๘๐ ก) | การตรวจสุขภาพแรกเข้า (ภายใน ๓๐ วัน), การตรวจสุขภาพประจำปีตามปัจจัยเสี่ยง, การบันทึกสมุดผลตรวจสุขภาพ (แบบ จป.ส), การแจ้งผลตรวจให้ลูกจ้างทราบ |

---

## 7. Compliance Engine & Calculation Logic

### 7.1 Compliance Index Formula
$$\text{Compliance Index (\%)} = \frac{\text{Compliant Count}}{\text{Total Applicable Items}} \times 100$$
Where:
- $\text{Total Applicable Items} = \text{Total Requirements} - \text{Not Applicable Count}$
- If $\text{Total Applicable Items} == 0$, $\text{Compliance Index} = 100.0\%$

### 7.2 Status Transition Rules
- **COMPLIANT (สอดคล้อง)**: Full implementation documented with valid evidence files.
- **NON_COMPLIANT (ไม่สอดคล้อง)**: Action required; automatically flags creation of a `LegalCapaModel`.
- **IN_PROGRESS (อยู่ระหว่างดำเนินการ)**: Action in progress; links to an open CAPA with an active target date.
- **NOT_APPLICABLE (ไม่เกี่ยวข้อง)**: Excluded from compliance score calculation.

### 7.3 Overdue CAPA Calculation
- If $\text{status} \ne \text{COMPLETED}$ and $\text{targetDate} < \text{DateTime.now()}$, status evaluates dynamically to $\text{OVERDUE}$.

---

## 8. Export Services & Statutory Reporting Architecture

### 8.1 Statutory PDF Export Service (`legal_compliance_pdf_service.dart`)
- **Headers & Fonts**: Multi-page layout formatted to A4 with official DLPW header, company profile metadata, and Sarabun Thai font.
- **Contents**:
  1. Executive Summary Table (% Compliance, total items, breakdown by category).
  2. Detailed Assessment Register (Category, statutory requirement, actual practice, compliance status badge, evaluator signature box).
  3. CAPA Action Plan Summary (Root cause, corrective measure, PIC, deadline, completion status).

### 8.2 Excel Multi-Sheet Export Service (`legal_compliance_excel_service.dart`)
- **Sheet 1 (`ทะเบียนประเมินกฎหมาย`)**: All statutory items with columns: ลำดับ, หมวดกฎหมาย, ชื่อกฎหมาย, ข้อกำหนด, การปฏิบัติจริง, สถานะความสอดคล้อง, ผู้ประเมิน, วันที่ประเมิน.
- **Sheet 2 (`แผนปรับปรุงแก้ไข CAPA`)**: Columns: ลำดับ, ข้อกฎหมายที่เกี่ยวข้อง, สาเหตุรากเหง้า, มาตรการแก้ไข, มาตรการป้องกัน, ผู้รับผิดชอบ, กำหนดเสร็จ, สถานะ.
- **Sheet 3 (`สรุปดัชนี KPI`)**: Compliance percentage breakdown per category.

---

## 9. Agent Skill & Multi-Agent Integration Architecture

### 9.1 Agent Skill: `thai-safety-legal-register`
- Location: `d:\DEV\SAFAPP\skills\thai-safety-legal-register\` and `.gemini\config\skills\thai-safety-legal-register\`
- Standard: PEP 723 CLI script (`thai_safety_legal_cli.py`) supporting:
  - `search -q <query> [-c <category>]`: Search legal requirements and gazette citations.
  - `get-law -i <law_code>`: Retrieve full statutory provisions and enforcement guidelines.
  - `evaluate -c <json_payload>`: Automated compliance evaluation based on workplace inputs.
  - `capa-summary -c <json_payload>`: Generate recommended CAPA measures for non-compliant items.

### 9.2 AgentResearch Integration
- Location: `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`
- Exposes `ThaiSafetyLegalHelper` class with both direct import fallback and subprocess CLI execution for research, writing, advisor, and QA agents.

---

## 10. Test Strategy & Quality Assurance Blueprints

### 10.1 Flutter Automated Test Suite
- `test/legal_register_test.dart`:
  1. **Master Catalog Verification**: Validates presence of all 8 Thai law categories and complete provision models.
  2. **Compliance Engine Calculations**: 100% compliant, mixed status, all N/A, zero division protection, floating-point precision.
  3. **CAPA Overdue & Status Engine**: Tests transitions between PENDING, IN_PROGRESS, COMPLETED, and OVERDUE.
  4. **PDF & Excel Generation**: Generates non-empty document bytes without throwing exceptions.
- `test/legal_register_adversarial_challenge_test.dart`:
  1. Empty search strings, special characters, whitespace trimming.
  2. Boundary dates (leap years, past dates, far-future dates).
  3. Extreme compliance distributions (100% non-compliant, 100% N/A).

---

## 11. Implementation Action Plan & Milestones

| Milestone | Scope | Deliverables |
|---|---|---|
| **M1: Master Data & SQLite Schema** | Seeds & DB tables | `safety_legal_8_categories_data.dart`, `DatabaseHelper` schema upgrade, Domain models |
| **M2: Repository & Riverpod Providers** | Data layer & State management | `legal_register_repository.dart`, `legal_register_providers.dart` |
| **M3: UI Presentation & Dialogs** | 3-Tab UI, Dialogs, KPI Cards | `legal_page.dart`, `legal_assessment_dialog.dart`, `legal_capa_dialog.dart`, `legal_doc_viewer_dialog.dart` |
| **M4: Reporting & Export Services** | PDF & Excel exports | `legal_compliance_pdf_service.dart`, `legal_compliance_excel_service.dart` |
| **M5: Agent Skill & AgentResearch** | CLI & Multi-agent helper | `skills/thai-safety-legal-register/`, `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py` |
| **M6: Verification & Test Suites** | Full test coverage & build test | `test/legal_register_test.dart`, `test/legal_register_adversarial_challenge_test.dart` |
