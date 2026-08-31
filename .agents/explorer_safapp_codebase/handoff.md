# Handoff Report: SAFAPP Codebase Exploration & Architectural Blueprint for Chemical & SDS Management Module

**Author**: Explorer Subagent (`explorer_safapp_codebase`)  
**Target Recipient**: Parent Orchestrator  
**Date**: 2026-08-31T20:45:00+07:00  
**Status**: Self-Contained Hard Handoff  

---

## 1. Observation

Direct observations from the SAFAPP codebase inspection:

### 1.1 Project Configuration & Dependencies (`pubspec.yaml`)
- **App Name & SDK**: `safety_superapp`, Flutter SDK `^3.11.5`, Material 3 enabled (`uses-material-design: true`).
- **State Management**: `flutter_riverpod: ^3.3.2` with root `ProviderScope` in `lib/main.dart` (lines 7-11).
- **Persistence & Database**: 
  - `sqflite_common_ffi: ^2.4.0+3` and `sqlite3_flutter_libs: ^0.6.0+eol` for cross-platform desktop/Windows SQLite FFI support (`lib/core/database/database_helper.dart` lines 23-26).
  - `path: ^1.9.1` and `path_provider: ^2.1.6`.
  - Database file location: `getApplicationDocumentsDirectory() / SafetySuperapp / safety_superapp_v1.db` (Schema Version: 4).
- **Document Handling & PDF**:
  - `pdf: ^3.12.0` (generation) & `printing: ^5.14.3` (printing, layout, and Google Fonts Sarabun for official Thai documents).
  - `syncfusion_flutter_pdfviewer: ^33.2.13` (`SfPdfViewer.file` used for PDF previews).
  - `file_picker: ^11.0.3` (used for selecting PDFs, images, and Excel spreadsheets).
  - `excel: ^4.0.6` (Excel import/export).
- **Styling & UI**:
  - `google_fonts: ^8.2.1` (configured with `GoogleFonts.promptTextTheme` across the entire app in `lib/main.dart:23`).
  - `fl_chart: ^1.2.0` (used for interactive statistics and KPI charts).
  - `cupertino_icons: ^1.0.8`.

### 1.2 Architecture & Directory Layout (`lib/`)
The codebase follows Feature-Driven Clean Architecture with standard directory layout:
```
lib/
├── main.dart
├── core/
│   ├── data/ (e.g. thai_address_data.dart)
│   ├── database/ (database_helper.dart)
│   ├── providers/ (database_provider.dart)
│   └── widgets/ (app_shell.dart, glass_container.dart, thai_address_cascade_widget.dart)
└── features/
    ├── audit_inspection/
    ├── chemicals/ (CURRENTLY PLACEHOLDER in chemicals_page.dart, 32 lines)
    ├── contractor/
    ├── dashboard/
    ├── emergency/
    ├── employee/
    ├── environment/
    ├── health_hygiene/ (Gold standard reference module)
    ├── landing/
    ├── legal_register/
    ├── near_miss_incident/
    ├── ppe_asl/
    ├── ptw/
    ├── risk_assessment/
    ├── safety_manual/
    ├── settings/
    └── sms_setup/
```

### 1.3 Module Structure Convention (Reference: `health_hygiene` & `risk_assessment`)
Each fully-featured module adheres to a consistent 4-layer structure:
1. **`domain/models/<feature>_models.dart`**:
   - Immutable data classes with typed fields, default parameters, null safety.
   - Serialization methods: `toMap()` (with JSON encoding for nested lists/maps) and `fromMap()` (with safe parsing).
   - `copyWith()` method for immutability.
   - Rich UI helper getters (e.g., Thai status labels, badges, color mapping, percentage calculation).
2. **`data/repositories/<feature>_repository.dart`**:
   - Instantiated with `DatabaseHelper` singleton.
   - Handles SQL queries (`rawQuery`, `insert`, `update`, `delete`).
   - Handles file copying and persistence to `Documents/SafetySuperapp/<module_folder>/` using timestamped file naming.
3. **`presentation/providers/<feature>_providers.dart`**:
   - Built on `flutter_riverpod` using `AsyncNotifier<List<T>>` and `AsyncNotifierProvider`.
   - Methods like `saveItem()`, `deleteItem()` with automatic `ref.invalidateSelf()` and cascade invalidation of related providers.
4. **`presentation/pages/<feature>_page.dart`**:
   - `ConsumerStatefulWidget` with segmented navigation tabs (`_selectedTab`), KPI metric cards at the top, filter bars, search fields, empty states, card lists, and action buttons.
5. **`presentation/widgets/<feature>_dialogs.dart`**:
   - Form dialogs using `GlobalKey<FormState>()`, `TextFormField`, `DropdownButtonFormField`, `FilePicker`, and custom decorations.
   - Document viewers (`HealthReportViewerDialog` / `ContractorDocViewerPage`) integrating `SfPdfViewer.file` and `InteractiveViewer` for images.
6. **`services/<feature>_pdf_service.dart`**:
   - PDF document generator using `pw.Document()`, `PdfGoogleFonts.sarabunRegular()`, `sarabunBold()`, and `sarabunItalic()`.
   - Renders official Thai government headers, tables, badges, signature blocks, and triggers `Printing.layoutPdf()`.

### 1.4 Current State of Chemicals Module
- `lib/features/chemicals/presentation/pages/chemicals_page.dart` is currently a 32-line placeholder Scaffold with text *"รายการสารเคมี และสถานะการหมดอายุของ SDS จะแสดงที่นี่"*.
- `lib/core/database/database_helper.dart` does NOT yet contain chemical tables (`chemical_master_1516`, `chemical_tlv_324`, `chemical_inventory`, `chemical_sds_sor1`, `chemical_measurement_sor3`).
- Navigation item 10 in `AppShell` (`Icons.science_outlined`, label `'สารเคมี'`) links directly to `ChemicalsPage`.

### 1.5 Existing Tests (`test/`)
- `test/risk_matrix_test.dart` contains unit tests using `flutter_test` asserting risk calculation, severity levels, and Thai labels for Ministerial Announcement 2567.

---

## 2. Logic Chain

1. **Architecture Compatibility**: Because SAFAPP already has well-established conventions demonstrated in `health_hygiene` and `risk_assessment`, the Chemical & SDS module should strictly follow the identical directory structure (`data/`, `domain/`, `presentation/`, `services/`), naming patterns, Riverpod provider conventions, and database management patterns.
2. **Offline & Desktop Performance**: With 1,516 chemicals in Master Data and 324 TLV entries, storing them in local SQLite tables (with indexing on `name_th`, `name_en`, and `cas_number`) or bundled Dart lookup sets ensures sub-millisecond autocomplete responsiveness on Windows desktop without requiring internet connectivity.
3. **Legal Compliance (ราชกิจจานุเบกษา)**:
   - **R1 (Inventory & SDS Tracking)**: Needs status derivation logic based on `sds_issue_date` vs current date and review cycle (e.g. 3 or 5 years) -> `NORMAL` (Active / สีเขียว), `NEAR_EXPIRE` (Within 90-180 days / สีส้ม), `EXPIRED` (Overdue / สีแดง).
   - **R2 (แบบ สอ.๑ - SDS 16 หัวข้อ)**: Must implement all 16 standard GHS sections as structured models so users can either input structured fields or view generated official PDFs compliant with the Department of Labour Protection and Welfare.
   - **R3 (แบบ สอ.๓ ๒๕๖๕)**: Must allow logging air measurements, automatically matching CAS No. against the 324 TLV list (TWA, STEL, Ceiling), evaluating whether `measured_value <= tlv_standard_value` (`PASS` / `FAIL`), recording Section 9/11 registered inspection agency credentials, and exporting the official สอ.๓ PDF.
   - **R4 (คลังเอกสารกฎหมาย)**: Can be integrated as the 4th tab in `ChemicalsPage`, providing direct access to the 5 key Thai safety laws, summaries, and PDF viewers.
   - **R5 (Agent Skill)**: Must be structured in `.gemini/config/skills/thai-chemical-safety-law/` with `SKILL.md` and a standalone Python CLI script supporting `search`, `get-tlv`, `get-law`, and `verify-sds` returning JSON for `D:\DEV\AgentResearch`.

---

## 3. Caveats

- **Caveat 1**: Master Data for 1,516 chemicals and 324 TLVs should be bundled into a dedicated data file or SQLite seed script to avoid large initial network downloads and ensure instant offline access.
- **Caveat 2**: Database schema update in `DatabaseHelper` should use version increment (e.g. Version 5) and include table creation in both `_onCreate` and `_onUpgrade` / `_onOpen` for seamless backward compatibility.
- **Caveat 3**: File attachments (SDS PDFs, safety photos, measurement lab certificates) must be saved into `Documents/SafetySuperapp/chemicals/` to prevent broken paths when temporary files are moved or deleted.

---

## 4. Conclusion & Recommended Architecture

### 4.1 Recommended File & Directory Layout

```
lib/features/chemicals/
├── data/
│   ├── datasources/
│   │   ├── chemical_1516_master_data.dart    # 1,516 chemical list (Thai, Eng, CAS, Class)
│   │   ├── chemical_324_tlv_data.dart         # 324 TLV threshold list (TWA, STEL, Ceiling)
│   │   └── chemical_laws_data.dart            # Full text & summary of 5 Gazette laws
│   └── repositories/
│       └── chemical_repository.dart           # SQLite CRUD, queries, file persistence
├── domain/
│   └── models/
│       ├── chemical_master_model.dart         # 1,516 master item model
│       ├── chemical_tlv_model.dart            # 324 TLV model & evaluation logic
│       ├── chemical_inventory_model.dart      # Inventory register & SDS expiry calculation
│       ├── chemical_sds_sor1_model.dart       # แบบ สอ.๑ (16 GHS sections)
│       └── chemical_measurement_sor3_model.dart # แบบ สอ.๓ ๒๕๖๕ (Air monitoring & M.9/M.11)
├── presentation/
│   ├── pages/
│   │   └── chemicals_page.dart                # Main 4-Tab Screen with Hero banner & KPIs
│   ├── providers/
│   │   └── chemical_providers.dart            # Riverpod Notifiers (Inventory, สอ.๑, สอ.๓, Search)
│   └── widgets/
│       ├── chemical_inventory_form_dialog.dart # New/Edit chemical inventory dialog + autocomplete
│       ├── sds_sor1_editor_dialog.dart        # 16-section สอ.๑ multi-step wizard / editor dialog
│       ├── sds_sor3_measurement_dialog.dart   # สอ.๓ measurement record & TLV matcher dialog
│       ├── chemical_doc_viewer_dialog.dart    # PDF / Image viewer (SfPdfViewer)
│       ├── chemical_autocomplete_field.dart   # Instant autocomplete for 1,516 chemicals
│       ├── ghs_pictogram_selector.dart        # Visual 9 GHS pictograms selector
│       └── nfpa_diamond_widget.dart           # NFPA 704 standard 4-color diamond widget
└── services/
    ├── chemical_sor1_pdf_service.dart         # Official สอ.๑ PDF generator (Sarabun font)
    └── chemical_sor3_pdf_service.dart         # Official สอ.๓ ๒๕๖๕ PDF generator

test/
└── chemical_management_test.dart              # Unit tests for TLV matching, SDS expiry, models
```

---

### 4.2 SQLite Database Schema Design

Add to `DatabaseHelper` (`lib/core/database/database_helper.dart`):

```sql
-- 1. ทะเบียนสารเคมีที่ครอบครองในสถานประกอบการ & ติดตาม SDS
CREATE TABLE IF NOT EXISTS chemical_inventory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seq_no INTEGER,
  trade_name TEXT NOT NULL,
  chemical_name_th TEXT NOT NULL,
  chemical_name_en TEXT NOT NULL,
  cas_number TEXT NOT NULL,
  un_number TEXT,
  storage_location TEXT NOT NULL,
  physical_state TEXT NOT NULL,          -- SOLID, LIQUID, GAS
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,                    -- kg, liters, drums, cylinders, tons
  max_capacity REAL,
  container_type TEXT,
  manufacturer_supplier TEXT,
  hazard_class TEXT,
  ghs_pictograms TEXT,                   -- JSON array of pictogram codes
  register_date TEXT NOT NULL,
  sds_issue_date TEXT NOT NULL,
  sds_expiry_years INTEGER DEFAULT 3,    -- Cycle (3 or 5 years)
  sds_file_path TEXT,                    -- Attached SDS PDF
  label_image_path TEXT,                 -- Attached container label image
  notes TEXT,
  status TEXT DEFAULT 'ACTIVE',          -- ACTIVE, INACTIVE, DISPOSED
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. ข้อมูลความปลอดภัยสารเคมีอันตราย (แบบ สอ.๑ - SDS 16 หัวข้อ)
CREATE TABLE IF NOT EXISTS chemical_sds_sor1 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  inventory_id INTEGER,
  trade_name TEXT NOT NULL,
  chemical_formula TEXT,
  cas_number TEXT NOT NULL,
  un_number TEXT,
  manufacturer_importer_info TEXT,        -- Section 1
  ghs_classification TEXT,               -- Section 2
  ghs_pictograms TEXT,                   -- Section 2 (JSON)
  signal_word TEXT,                      -- Section 2 (DANGER / WARNING)
  hazard_statements TEXT,                -- Section 2
  precautionary_statements TEXT,          -- Section 2
  ingredients_json TEXT,                 -- Section 3 (List of ingredients with %, TLV, LD50)
  first_aid_json TEXT,                   -- Section 4 (Inhalation, Skin, Eye, Ingestion)
  fire_fighting_json TEXT,               -- Section 5 (Extinguishing media, hazards, PPE)
  accidental_release_json TEXT,          -- Section 6
  handling_storage_json TEXT,            -- Section 7
  exposure_controls_json TEXT,           -- Section 8 (TLV/PEL, PPE requirements)
  physical_chemical_json TEXT,           -- Section 9 (Appearance, pH, Flash point, etc.)
  stability_reactivity_json TEXT,        -- Section 10
  toxicological_json TEXT,               -- Section 11 (LD50/LC50, Carcinogenicity)
  ecological_json TEXT,                  -- Section 12 (LC50/EC50, biodegradability)
  disposal_json TEXT,                    -- Section 13
  transport_json TEXT,                   -- Section 14 (UN No, Class, Packing Group)
  regulatory_json TEXT,                  -- Section 15 (Hazardous Substance Act, DGLP)
  other_info_json TEXT,                  -- Section 16 (References, notes)
  nfpa_health INTEGER DEFAULT 0,         -- NFPA 704 Blue (0-4)
  nfpa_flammability INTEGER DEFAULT 0,   -- NFPA 704 Red (0-4)
  nfpa_instability INTEGER DEFAULT 0,    -- NFPA 704 Yellow (0-4)
  nfpa_special TEXT,                     -- NFPA 704 White (W, OX, SA, COR)
  status TEXT DEFAULT 'COMPLETED',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (inventory_id) REFERENCES chemical_inventory(id) ON DELETE SET NULL
);

-- 3. รายงานผลการตรวจวัดระดับความเข้มข้นในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕)
CREATE TABLE IF NOT EXISTS chemical_measurement_sor3 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_no TEXT NOT NULL UNIQUE,      -- Document number (e.g. SOR3-2569-001)
  assessment_date TEXT NOT NULL,
  workplace_area TEXT NOT NULL,          -- Department / Process / Room
  sampling_point_description TEXT,
  chemical_name TEXT NOT NULL,
  cas_number TEXT NOT NULL,
  sampling_type TEXT DEFAULT 'TWA_8HR',  -- TWA_8HR, STEL_15MIN, CEILING
  sampling_duration_minutes INTEGER,
  sampling_method TEXT,                  -- NIOSH, OSHA, etc.
  measured_value REAL NOT NULL,
  unit TEXT NOT NULL,                    -- ppm, mg/m3
  tlv_standard_value REAL NOT NULL,
  evaluation_result TEXT NOT NULL,       -- PASS (ไม่เกิน), FAIL (เกินขีดจำกัด)
  service_provider_name TEXT NOT NULL,   -- หน่วยตรวจวัดตาม ม.๙ หรือ ม.๑๑
  service_provider_m9_reg_no TEXT,       -- เลขทะเบียนขึ้นทะเบียนตาม ม.๙
  service_provider_m11_cert_no TEXT,     -- เลขที่ใบสำคัญขึ้นทะเบียนตาม ม.๑๑
  sampling_officer_name TEXT,
  analyst_name TEXT,
  analysis_laboratory TEXT,
  weather_condition TEXT,
  temperature_celsius REAL,
  relative_humidity REAL,
  corrective_action TEXT,
  certificate_pdf_path TEXT,             -- Attached Lab Analysis Report / Certificate
  status TEXT DEFAULT 'APPROVED',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

### 4.3 Key Domain Models & Business Logic

#### 1. SDS Expiry Status Calculation (`ChemicalInventory`)
```dart
enum SdsStatus { normal, nearExpire, expired }

extension ChemicalInventoryStatus on ChemicalInventory {
  DateTime get sdsIssueDateTime => DateTime.tryParse(sdsIssueDate) ?? DateTime.now();
  DateTime get sdsExpiryDate => DateTime(
    sdsIssueDateTime.year + sdsExpiryYears,
    sdsIssueDateTime.month,
    sdsIssueDateTime.day,
  );

  int get daysUntilExpiry => sdsExpiryDate.difference(DateTime.now()).inDays;

  SdsStatus get sdsStatus {
    if (daysUntilExpiry < 0) return SdsStatus.expired;
    if (daysUntilExpiry <= 180) return SdsStatus.nearExpire;
    return SdsStatus.normal;
  }

  String get sdsStatusLabel {
    switch (sdsStatus) {
      case SdsStatus.normal: return '🟢 ปกติ (Valid)';
      case SdsStatus.nearExpire: return '🟡 ใกล้หมดอายุ (Review Needed)';
      case SdsStatus.expired: return '🔴 หมดอายุ (Expired)';
    }
  }
}
```

#### 2. TLV Auto-Evaluation Logic (`ChemicalMeasurementSor3`)
```dart
enum EvaluationResult { pass, fail }

class TlvEvaluationEngine {
  static EvaluationResult evaluate({
    required double measuredValue,
    required double tlvStandardValue,
  }) {
    return measuredValue <= tlvStandardValue ? EvaluationResult.pass : EvaluationResult.fail;
  }

  static String resultLabel(EvaluationResult result) {
    return result == EvaluationResult.pass ? '✅ ไม่เกินขีดจำกัด (PASS)' : '⚠️ เกินขีดจำกัดตามกฎหมาย (FAIL)';
  }
}
```

---

### 4.4 Agent Skill: `thai-chemical-safety-law` Specification

- **Location**: `.gemini/config/skills/thai-chemical-safety-law/`
- **Files**:
  - `SKILL.md`: Detailed skill metadata, instructions, parameters, and examples.
  - `scripts/chemical_law_cli.py`: Standalone CLI tool.
  - `data/chemicals_1516.json`: Full 1,516 chemicals database.
  - `data/tlv_324.json`: 324 TLV threshold database.
  - `data/laws_summary.json`: Summary & full text of the 5 Gazette safety laws.
- **CLI Commands**:
  ```bash
  python chemical_law_cli.py search "toluene"
  python chemical_law_cli.py get-tlv --cas "108-88-3"
  python chemical_law_cli.py get-law --topic "sor1"
  python chemical_law_cli.py verify-sds --file "sds_data.json"
  ```
- **Output Format**: Structured JSON compatible with `D:\DEV\AgentResearch` automated multi-agent analysis scripts.

---

## 5. Verification Method

To verify the codebase analysis and future implementation:
1. **Analyze Dependency & Build Integrity**:
   - Inspect `pubspec.yaml` to ensure all required packages (`pdf`, `printing`, `syncfusion_flutter_pdfviewer`, `file_picker`, `flutter_riverpod`, `sqflite_common_ffi`) are present and compatible with Dart `^3.11.5`.
2. **Execute Unit Tests**:
   - Test command: `flutter test test/chemical_management_test.dart`
   - Should verify:
     - 1,516 chemical search by Thai, English, and CAS Number.
     - 324 TLV threshold matching and evaluation against measured concentrations.
     - SDS expiration calculation for normal, near-expired (<=180 days), and expired dates.
     - Serialization and deserialization of all 16 สอ.๑ sections.
     - สอ.๓ ๒๕๖๕ air measurement calculation and M.9/M.11 validation.
3. **Inspect Implementation Artifacts**:
   - Verify `lib/features/chemicals/` contains `data/`, `domain/`, `presentation/`, and `services/`.
   - Verify `AppShell` navigation tab 10 links to the complete 4-tab `ChemicalsPage`.
   - Verify `.gemini/config/skills/thai-chemical-safety-law/SKILL.md` is present and functional with `scripts/chemical_law_cli.py`.
