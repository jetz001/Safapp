# Project: Safety Legal Register & Compliance Evaluation Module for SAFAPP

## Architecture
Clean Architecture with Flutter + Riverpod 3 + SQLite FFI (Windows/Linux/Mobile):
- **Domain Layer (`lib/features/legal_register/domain/models/`)**:
  - `LegalMasterItemModel`: 8 Thai Royal Gazette laws metadata & 32 statutory compliance checklist items.
  - `LegalComplianceAssessmentModel`: Facility-specific evaluation record (status, actual practice, assessor, review date, evidence attachments).
  - `LegalCapaModel`: Corrective & Preventive Action plan for non-compliant/in-progress items (root cause, action, PIC, target date, status, verification).
  - `LegalComplianceStatsModel`: % Basic Compliance, % Risk-Weighted Compliance, status counters.
- **Data Layer (`lib/features/legal_register/data/`)**:
  - `safety_legal_8_categories_data.dart`: Master seed dataset (32 items across 8 Royal Gazette laws).
  - `legal_register_repository.dart`: SQLite CRUD, assessment updates, CAPA lifecycle management, file attachments.
  - `lib/core/database/database_helper.dart`: Table schemas (`safety_legal_master`, `safety_legal_assessments`, `safety_legal_capa`) with foreign keys and cascade delete.
- **Presentation Layer (`lib/features/legal_register/presentation/`)**:
  - `legal_page.dart`: Main screen with TabBar (3 tabs: ทะเบียนและการประเมินความสอดคล้อง, คลังกฎหมายราชกิจจานุเบกษา, แผนการปรับปรุงแก้ไข CAPA).
  - `providers/legal_register_providers.dart`: Riverpod 3 StateNotifiers (`legalItemListProvider`, `legalAssessmentListProvider`, `legalCapaListProvider`, `legalStatsProvider`, `legalFilterProvider`).
  - `widgets/`:
    - `legal_kpi_dashboard.dart`: % Compliance summary cards, circular indicators, risk status chips.
    - `legal_filter_bar.dart`: Keyword search, law category chips, compliance status dropdown.
    - `legal_assessment_dialog.dart`: Evaluation form with status selector, actual practice input, and file attachment picker.
    - `legal_capa_dialog.dart`: CAPA creation/edit form with root cause, action, PIC, target date, and closure notes.
    - `legal_gazette_viewer_dialog.dart`: Royal Gazette detail & embedded PDF previewer.
- **Services Layer (`lib/features/legal_register/services/`)**:
  - `legal_compliance_pdf_service.dart`: Statutory compliance report generator using `pdf` + `PdfGoogleFonts.sarabun*`.
  - `legal_compliance_excel_service.dart`: 3-sheet Excel workbook generator (Assessments, CAPA Action Plan, Category Statistics).
- **Agent Skill & Multi-Agent Integration**:
  - `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register` & `d:\DEV\SAFAPP\skills\thai-safety-legal-register`: Standard Agent Skill (`SKILL.md`, CLI tool with `search`, `get-law`, `evaluate`, `capa-summary`, engine, offline JSON datasets).
  - `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`: Dual-mode Python helper for multi-agent workflows.

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Master Safety Legal Catalog | 8 Thai Royal Gazette laws & 32 statutory compliance checklist items | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Data Models & DB Schema | SQLite tables, migrations, JSON serialization, and entity models | M1 | ORIGINAL_REQUEST §R1, R2 |
| 3 | Repository & Riverpod State | CRUD operations, compliance stats calculation, reactive providers | M1 | ORIGINAL_REQUEST §R2 |
| 4 | Legal Register & Assessment Tab | Interactive evaluation table/cards, status selection, actual practice notes, assessor info | M2 | ORIGINAL_REQUEST §R2 |
| 5 | Royal Gazette Repository Tab | Searchable legal reference library, summary, penalty criteria, PDF viewer | M2 | ORIGINAL_REQUEST §R4 |
| 6 | CAPA Action Plan Tab | Corrective & Preventive Action manager, overdue alerts, PIC assignment, closure workflow | M2 | ORIGINAL_REQUEST §R3 |
| 7 | KPI Dashboard & Filtering | % Compliance Index, risk-weighted score, category filters, status chips | M2 | ORIGINAL_REQUEST §R2 |
| 8 | PDF Statutory Report Export | Official Thai Sarabun font PDF export of compliance evaluation & CAPA | M3 | ORIGINAL_REQUEST §R4 |
| 9 | Excel Multi-Sheet Export | 3-sheet `.xlsx` report export for audits and executive reporting | M3 | ORIGINAL_REQUEST §R4 |
| 10 | Agent Skill `thai-safety-legal-register` | SKILL.md, PEP 723 CLI script, standalone JSON data, test suite | M4 | ORIGINAL_REQUEST §R5 |
| 11 | AgentResearch Helper Script | `thai_safety_legal_helper.py` in `D:\DEV\AgentResearch\Scripts\` | M4 | ORIGINAL_REQUEST §R5 |
| 12 | Comprehensive Unit & E2E Tests | 100% test pass on calculations, filters, CAPA lifecycle, Flutter build & CLI tests | M5 | ORIGINAL_REQUEST §A4 |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Models, Master Seed & Data Layer | Entity models, SQLite tables in `DatabaseHelper`, seed catalog (8 laws, 32 items), repository, Riverpod providers | none | PLANNED |
| M2 | SAFAPP Flutter UI & Interactive Tabs | `LegalPage` (3 tabs), KPI dashboard, search/filter bar, assessment dialog, CAPA dialog, gazette viewer | M1 | PLANNED |
| M3 | Statutory PDF & Multi-Sheet Excel Exporters | `legal_compliance_pdf_service.dart`, `legal_compliance_excel_service.dart`, export actions in UI | M1, M2 | PLANNED |
| M4 | Agent Skill & AgentResearch Integration | `thai-safety-legal-register` skill in `.gemini/config/skills/` and `skills/`, CLI script, helper in `AgentResearch/Scripts/` | none | PLANNED |
| M5 | E2E Testing Suite & Hardening Verification | Unit tests in Flutter (`test/legal_register_test.dart`), Skill CLI tests, 100% test pass, adversarial coverage | M1, M2, M3, M4 | PLANNED |

---

## Interface Contracts

### `LegalRegisterRepository` ↔ Presentation / Providers
- `Future<List<LegalMasterItemModel>> getAllMasterItems({String? category, String? keyword})`
- `Future<List<LegalComplianceAssessmentModel>> getAllAssessments({String? status, String? category})`
- `Future<void> saveAssessment(LegalComplianceAssessmentModel assessment)`
- `Future<List<LegalCapaModel>> getAllCapa({String? status})`
- `Future<void> saveCapa(LegalCapaModel capa)`
- `Future<void> deleteCapa(String id)`
- `Future<LegalComplianceStatsModel> calculateStats()`

### Export Services ↔ Presentation
- `Future<Uint8List> generateCompliancePdf({required List<LegalMasterItemModel> masterItems, required List<LegalComplianceAssessmentModel> assessments, required List<LegalCapaModel> capas, required LegalComplianceStatsModel stats})`
- `Future<List<int>> generateComplianceExcel({required List<LegalMasterItemModel> masterItems, required List<LegalComplianceAssessmentModel> assessments, required List<LegalCapaModel> capas, required LegalComplianceStatsModel stats})`

### Agent Skill CLI Interface
- `python scripts/thai_safety_legal_cli.py search --keyword <text> --category <cat> --json`
- `python scripts/thai_safety_legal_cli.py get-law --law-id <id> --json`
- `python scripts/thai_safety_legal_cli.py evaluate --profile-file <json> --json`
- `python scripts/thai_safety_legal_cli.py capa-summary --assessment-file <json> --json`

---

## Code Layout
```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart             (SQLite schema update for legal_register)
│   └── widgets/
│       └── app_shell.dart                   (Route/Tab index 15 to LegalPage)
└── features/
    └── legal_register/
        ├── data/
        │   ├── safety_legal_8_categories_data.dart
        │   └── legal_register_repository.dart
        ├── domain/
        │   └── models/
        │       ├── legal_master_item_model.dart
        │       ├── legal_compliance_assessment_model.dart
        │       ├── legal_capa_model.dart
        │       └── legal_compliance_stats_model.dart
        ├── presentation/
        │   ├── pages/
        │   │   └── legal_page.dart
        │   ├── providers/
        │   │   └── legal_register_providers.dart
        │   └── widgets/
        │       ├── legal_kpi_dashboard.dart
        │       ├── legal_filter_bar.dart
        │       ├── legal_assessment_dialog.dart
        │       ├── legal_capa_dialog.dart
        │       └── legal_gazette_viewer_dialog.dart
        └── services/
            ├── legal_compliance_pdf_service.dart
            └── legal_compliance_excel_service.dart

skills/thai-safety-legal-register/ (and C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register/)
├── SKILL.md
├── pyproject.toml
├── scripts/
│   ├── thai_safety_legal_cli.py
│   ├── thai_safety_legal_engine.py
│   ├── thai_safety_legal_helper.py
│   └── data/
│       ├── safety_laws_catalog.json
│       ├── compliance_criteria.json
│       └── capa_templates.json
└── tests/
    └── test_thai_safety_legal_skill.py

D:\DEV\AgentResearch\Scripts/
└── thai_safety_legal_helper.py

test/
├── legal_register_test.dart
└── legal_register_adversarial_challenge_test.dart
```
