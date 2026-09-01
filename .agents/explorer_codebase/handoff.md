# Codebase Architecture Exploration — Handoff Report

## 1. Observation

Direct observations from codebase inspection across `pubspec.yaml`, `lib/`, `test/`, and `.agents/ORIGINAL_REQUEST.md`:

1. **Flutter & Riverpod Version**:
   - `pubspec.yaml` lines 37-49:
     - `flutter_riverpod: ^3.3.2`
     - `sqflite_common_ffi: ^2.4.0+3`
     - `sqlite3_flutter_libs: ^0.6.0+eol`
     - `path: ^1.9.1` & `path_provider: ^2.1.6`
     - `excel: ^4.0.6`
     - `file_picker: ^11.0.3`
     - `syncfusion_flutter_pdfviewer: ^33.2.13`
     - `google_fonts: ^8.2.1`
     - `fl_chart: ^1.2.0`
     - `pdf: ^3.12.0` & `printing: ^5.14.3`
2. **Entry Point & App Shell**:
   - `lib/main.dart` lines 6-30: App root wrapped in `ProviderScope`, Material 3 enabled, `GoogleFonts.promptTextTheme` applied, initial screen is `const AppShell()`.
   - `lib/core/widgets/app_shell.dart` lines 59, 150: Index 11 is `const EnvironmentPage()`, mapped to icon `Icons.thermostat_outlined` / `Icons.thermostat` with label `'สิ่งแวดล้อม'`.
   - `lib/features/environment/presentation/pages/environment_page.dart` lines 1-22: Currently a minimal 22-line placeholder `StatelessWidget`.
3. **Database Architecture**:
   - `lib/core/database/database_helper.dart` lines 8-48, 830-942: SQLite database using `sqflite_common_ffi` initialized for desktop with `sqfliteFfiInit()`. Version is currently `version: 6`. Storage path is `getApplicationDocumentsDirectory() / 'SafetySuperapp' / 'safety_superapp_v1.db'`. Table schema creation is separated into modular helper methods (`_createRiskAssessmentTables`, `_createChemicalTables`, `_createLegalTables`) with index creation and auto-seeding.
   - `lib/core/providers/database_provider.dart` lines 5-8: Single global `FutureProvider<Database>` returning `DatabaseHelper().database`.
4. **State Management & Feature Structure**:
   - `lib/features/legal_register/presentation/providers/legal_register_providers.dart` lines 18-263: Implements Riverpod v3 with `NotifierProvider` for query/filters (`LegalSearchQueryNotifier`, `LegalCategoryFilterNotifier`, `LegalStatusFilterNotifier`), `AsyncNotifierProvider` for collections (`LegalAssessmentListNotifier`, `LegalMasterListNotifier`, `LegalCapaListNotifier`), and `FutureProvider` for stats (`legalComplianceKpiProvider`).
   - Mutations call repository methods, then `ref.invalidateSelf()` and `ref.invalidate(legalComplianceKpiProvider)`.
5. **Document Generation & Exporters**:
   - `lib/features/legal_register/services/legal_compliance_pdf_service.dart` lines 18-780: PDF report generation using `pdf: ^3.12.0` with `PdfGoogleFonts.sarabunRegular()`, `sarabunBold()`, and `sarabunItalic()`. A4 Landscape orientation, multi-page tables, and 3-tier signature blocks. Preview and print handled via `Printing.layoutPdf(...)`.
   - `lib/features/legal_register/services/legal_compliance_excel_service.dart` lines 15-338: Multi-sheet `.xlsx` generation using `excel: ^4.0.6` with `TextCellValue`, `IntCellValue`, `DoubleCellValue`, saved to `Documents/SafetySuperapp/exports/`.
   - In-app PDF viewing uses `SfPdfViewer.file(...)` or `SfPdfViewer.memory(...)` (e.g. `lib/features/legal_register/presentation/widgets/legal_gazette_viewer_dialog.dart` line 572).
   - Attachment picker uses `FilePicker.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: [...])` with file persistence to `Documents/SafetySuperapp/<module>/` via `File.copy()`.
6. **Testing Setup**:
   - `test/` directory contains unit, repository, and widget tests (`legal_register_models_and_repo_test.dart`, `legal_register_ui_test.dart`, `chemical_management_test.dart`).
   - Widget tests mock Riverpod providers by providing `_MockNotifier` implementations overriding `AsyncNotifierProvider`.

---

## 2. Logic Chain

1. **Architecture Consistency**: Because all existing safety modules (`legal_register`, `chemicals`, `contractor`, `health_hygiene`) follow the exact same feature-first DDD pattern (`data/`, `domain/models/`, `presentation/pages/`, `presentation/providers/`, `presentation/widgets/`, `services/`), the Environmental Monitoring module (`lib/features/environment/`) must adopt this identical architectural layout to ensure seamless maintainability and zero friction.
2. **Database Version Migration**: Since `DatabaseHelper` is currently at `version: 6`, introducing the 4 new environmental tables (`environment_standards_master`, `environment_sessions`, `environment_measurement_points`, `environment_capa`) requires bumping the database version to `version: 7` in `DatabaseHelper` and adding `_createEnvironmentTables(db)` in `_onCreate`, `_onUpgrade`, and `_onOpen`.
3. **Statutory Standards Pre-Seeding**: Following the established pattern from `SafetyLegal8CategoriesData` and `_seedDefaultLegalData`, master environmental standards (Lighting Lux thresholds from 2018 notification, Noise 8-hr TWA limit 86 dBA, Action Level 85 dBA from 2018 notification, and Heat WBGT limits 34°C, 32°C, 30°C from 2016/2020 notifications) should be defined in a static data source and automatically seeded into SQLite when table count is 0.
4. **Interactive 4-Tab Page Layout**: `EnvironmentPage` at `AppShell` index 11 should be structured with 4 tabs:
   - Tab 1: แดชบอร์ด & รอบการตรวจวัด / Subcontractor (ม.๙ / ม.๑๑)
   - Tab 2: ตารางผลตรวจวัดรายจุด (แสงสว่าง, เสียง, ความร้อน WBGT) พร้อมระบบคำนวณและประเมินผลอัตโนมัติ
   - Tab 3: แผนการปรับปรุงแก้ไข CAPA & โครงการอนุรักษ์การได้ยิน (Hearing Conservation Program)
   - Tab 4: คลังกฎหมายราชกิจจานุเบกษา (พ.ร.บ. ๒๕๕๔, กฎกระทรวงฯ ๒๕๕๙, ประกาศกรมฯ ๒๕๖๑, ๒๕๖๓)
5. **Document Export Parity**: Creating `EnvironmentPdfService` (using `PdfGoogleFonts.sarabun` with official DLPW tables and 3-tier signatures) and `EnvironmentExcelService` (generating 3-sheet audit workbooks) directly fulfills Requirements R5 and Acceptance Criteria A2.
6. **Agent Skill Alignment**: Building the Agent Skill `thai-environmental-safety-law` with `SKILL.md` + Python CLI in `.gemini/config/skills/thai-environmental-safety-law` and helper in `D:\DEV\AgentResearch\Scripts\thai_env_helper.py` satisfies Requirement R6 and Acceptance Criteria A3.

---

## 3. Caveats

- **No Caveats.** All architectural layers, dependencies, state management patterns, UI widgets, storage helpers, export services, and test suites have been inspected directly in the local filesystem.

---

## 4. Conclusion

The SAFAPP Flutter codebase is well-structured, robust, and completely ready for the implementation of the Environmental Monitoring Module. The module can be built with 100% architectural parity with the existing `legal_register` and `chemicals` features by following the comprehensive specifications documented in `d:\DEV\SAFAPP\.agents\explorer_codebase\analysis.md`.

---

## 5. Verification Method

To independently verify the findings in this report:

1. **Inspect Dependencies & Configs**:
   - `view_file` on `d:\DEV\SAFAPP\pubspec.yaml` (verify Riverpod, sqflite, fl_chart, pdf, excel, printing, file_picker).
   - `view_file` on `d:\DEV\SAFAPP\lib\main.dart` and `d:\DEV\SAFAPP\lib\core\widgets\app_shell.dart`.
2. **Inspect Database & Reference Modules**:
   - `view_file` on `d:\DEV\SAFAPP\lib\core\database\database_helper.dart` (verify versioning and migration patterns).
   - `view_file` on `d:\DEV\SAFAPP\lib\features\legal_register\presentation\providers\legal_register_providers.dart` (verify Riverpod 3 provider patterns).
   - `view_file` on `d:\DEV\SAFAPP\lib\features\legal_register\services\legal_compliance_pdf_service.dart` and `legal_compliance_excel_service.dart` (verify document generation).
3. **Inspect Test Structure**:
   - `view_file` on `d:\DEV\SAFAPP\test\legal_register_models_and_repo_test.dart` and `test/legal_register_ui_test.dart` (verify mock notifier pattern and unit/widget test structures).
4. **Invalidation Conditions**:
   - If Flutter SDK or Riverpod is upgraded to a breaking major release requiring API changes.
   - If the database engine is replaced with another ORM (e.g. Isar/Hive instead of SQLite).
