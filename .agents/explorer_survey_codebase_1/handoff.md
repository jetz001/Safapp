# Handoff Report: SAFAPP Codebase & Flutter Architecture Survey

**Agent**: Explorer Survey Agent (`explorer_survey_codebase_1`)  
**Mission**: Survey the SAFAPP codebase, Flutter architecture, dependencies, state management, navigation, and export services, and provide an architectural blueprint for the Safety Legal Register & Compliance Evaluation module.  
**Date**: 2026-08-31  
**Handoff Type**: Hard (Task complete)

---

## 1. Observation

1. **Flutter Dependencies & SDK Setup**:
   - In `d:\DEV\SAFAPP\pubspec.yaml` (lines 30-49):
     - `flutter_riverpod: ^3.3.2`
     - `sqflite_common_ffi: ^2.4.0+3`
     - `sqlite3_flutter_libs: ^0.6.0+eol`
     - `path: ^1.9.1`, `path_provider: ^2.1.6`
     - `excel: ^4.0.6`
     - `file_picker: ^11.0.3`
     - `syncfusion_flutter_pdfviewer: ^33.2.13`
     - `google_fonts: ^8.2.1`
     - `fl_chart: ^1.2.0`
     - `pdf: ^3.12.0`
     - `printing: ^5.14.3`
2. **App Shell & Routing**:
   - In `d:\DEV\SAFAPP\lib\core\widgets\app_shell.dart` (lines 63, 154):
     - Page list index 15 holds `const LegalPage()`.
     - Sidebar `NavigationRailDestination` index 15 displays `Icon(Icons.gavel_outlined)` with label `'กฎหมาย'`.
   - In `d:\DEV\SAFAPP\lib\features\landing\presentation\pages\landing_page.dart` (line 697):
     - `_ModuleItem(name: 'ทะเบียนกฎหมายความปลอดภัย', targetIndex: 15)` connects the main portal card to `LegalPage()`.
   - In `d:\DEV\SAFAPP\lib\features\legal_register\presentation\pages\legal_page.dart` (lines 3-21):
     - Currently a placeholder `StatelessWidget` returning basic text.
3. **Database Architecture**:
   - In `d:\DEV\SAFAPP\lib\core\database\database_helper.dart` (lines 21-47):
     - Uses `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi;` on Windows/Linux.
     - Database stored at `appDocDir/SafetySuperapp/safety_superapp_v1.db` (current version: 5).
     - Provides dedicated helper methods `_createRiskAssessmentTables`, `_createChemicalTables`, and default seeders.
4. **State Management & Feature Reference Precedent**:
   - In `d:\DEV\SAFAPP\lib\features\chemicals\presentation\providers\chemical_providers.dart` (lines 19-152):
     - Riverpod 3 notifiers (`Notifier`, `AsyncNotifier`) paired with `NotifierProvider` and `AsyncNotifierProvider` are standard.
     - Repository pattern handles SQLite transactions and filesystem file copy (`SafetySuperapp/<module>/`).
5. **Reporting & PDF/Excel Export Architecture**:
   - In `d:\DEV\SAFAPP\lib\features\chemicals\services\chemical_sor1_pdf_service.dart` (lines 19-27):
     - Uses `PdfGoogleFonts.sarabunRegular()`, `PdfGoogleFonts.sarabunBold()`, and `PdfGoogleFonts.sarabunItalic()` with `pdf/widgets.dart` for flawless Thai font rendering.
   - In `d:\DEV\SAFAPP\lib\features\risk_assessment\services\por1_por2_excel_service.dart` (lines 4-20):
     - Uses `excel.Excel.createExcel()` to generate multi-sheet `.xlsx` files with `TextCellValue` and `IntCellValue`.
6. **Agent Skill & AgentResearch Integration**:
   - In `d:\DEV\SAFAPP\skills\thai-chemical-safety-law\SKILL.md` (lines 1-30) and `D:\DEV\AgentResearch\Scripts\thai_chem_helper.py` (lines 1-60):
     - Agent skills use PEP 723 CLI scripts with `search`, `get-tlv`/`get-law`, and `verify-sds`.
     - Multi-Agent research helpers in `D:\DEV\AgentResearch\Scripts\` provide programmatic Python wrappers with direct import and subprocess fallback.

---

## 2. Logic Chain

1. **Requirement Mapping**:
   - The user request requires developing the Safety Legal Register module covering 8 Thai Royal Gazette safety regulations, compliance evaluation, CAPA management, and PDF/Excel export, plus a `thai-safety-legal-register` Agent Skill.
2. **Architectural Consistency**:
   - Based on the existing feature implementations (`chemicals`, `risk_assessment`, `employee`), the new `legal_register` module must adopt the four-layer Clean Architecture:
     - `data/`: `safety_legal_8_categories_data.dart`, `legal_register_repository.dart`
     - `domain/`: `legal_master_item_model.dart`, `legal_compliance_assessment_model.dart`, `legal_capa_model.dart`, `legal_compliance_stats_model.dart`
     - `presentation/`: `legal_page.dart` (3 Tabs: Register & Evaluation, Gazette Library, CAPA Action Plan), `legal_register_providers.dart`, custom dialogs (`assessment`, `capa`, `doc_viewer`, `filter_bar`, `kpi_card`)
     - `services/`: `legal_compliance_pdf_service.dart`, `legal_compliance_excel_service.dart`
3. **Database Schema Strategy**:
   - To avoid conflicts and support offline operation, `DatabaseHelper` should create three dedicated tables: `safety_legal_master`, `safety_legal_assessments`, and `safety_legal_capa`, with foreign keys and cascade delete on CAPA.
4. **Export & Visual Standards**:
   - PDF generation will use `PdfGoogleFonts.sarabun*` to guarantee Thai character rendering.
   - Excel export will produce a 3-sheet workbook: Register & Assessment, CAPA Action Plan, and Category KPI Summary.
5. **Skill Integration**:
   - Skill `thai-safety-legal-register` should be located in `skills/thai-safety-legal-register/` and `.gemini/config/skills/thai-safety-legal-register/`, accompanied by `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`.

---

## 3. Caveats

- **No Caveats**: The codebase was thoroughly surveyed without blockers. All existing patterns, database helpers, Riverpod providers, navigation indexes, and export services were directly examined.

---

## 4. Conclusion

The SAFAPP Flutter codebase is in a clean, highly structured state with all necessary packages (`flutter_riverpod`, `sqflite_common_ffi`, `pdf`, `printing`, `excel`, `fl_chart`, `syncfusion_flutter_pdfviewer`) already installed and configured. 

The implementation of the **Safety Legal Register & Compliance Evaluation** module can proceed immediately across 6 coordinated milestones:
- **M1**: Master data seed (8 categories) & SQLite database tables in `DatabaseHelper`.
- **M2**: `LegalRegisterRepository` and Riverpod 3 notifiers/providers.
- **M3**: `LegalPage` (3 tabs: ทะเบียนและประเมินความสอดคล้อง, คลังกฎหมายราชกิจจานุเบกษา, แผน CAPA) and dialog widgets.
- **M4**: Official statutory PDF generator (`legal_compliance_pdf_service.dart`) and Excel generator (`legal_compliance_excel_service.dart`).
- **M5**: Agent Skill `thai-safety-legal-register` & helper in `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`.
- **M6**: Automated test suites in `test/legal_register_test.dart` and `test/legal_register_adversarial_challenge_test.dart`.

---

## 5. Verification Method

To independently verify this codebase survey:
1. Inspect the survey report at `d:\DEV\SAFAPP\.agents\explorer_survey_codebase_1\survey_codebase.md`.
2. Inspect `pubspec.yaml` to confirm dependency versions.
3. Inspect `lib/core/widgets/app_shell.dart` and `lib/features/landing/presentation/pages/landing_page.dart` to verify navigation index 15 mapping to `LegalPage()`.
4. Inspect `lib/core/database/database_helper.dart` to confirm SQLite FFI and migration structure.
5. Verify test infrastructure readiness in `test/`.
