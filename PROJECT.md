# Project: SAFAPP Environmental Monitoring & Thai Environmental Safety Law

## Architecture
- **Layering**: Clean Architecture / Feature-First Domain-Driven Design under `lib/features/environment/`
  - `domain/`: Models (`EnvironmentStandardModel`, `SubcontractorModel`, `EnvironmentSessionModel`, `EnvironmentPointModel`, `EnvironmentCapaModel`), Enums, Interfaces, Evaluation Calculators.
  - `data/`: SQLite Database migration (v6 -> v7 in `database_helper.dart`), Repositories, Master Data Catalogs (`environmental_standards_data.dart`, `environmental_gazette_data.dart`).
  - `presentation/`: Riverpod State Notifiers (`environment_providers.dart`), `EnvironmentPage`, 4 Tabs (`EnvironmentDashboardTab`, `EnvironmentPointsTab`, `EnvironmentCapaTab`, `EnvironmentGazetteTab`), Dialogs/Modals, KPI Widgets.
  - `services/`: `EnvironmentPdfExporter`, `EnvironmentExcelExporter`, `EnvironmentAttachmentManager`.
- **Navigation**: Registered in `AppShell` at navigation index 11 (`Icons.thermostat_outlined` / `Icons.thermostat`, label "สิ่งแวดล้อม").
- **Agent Skill & Multi-Agent Helper**:
  - Agent Skill: `skills/thai-environmental-safety-law/` (`SKILL.md`, `pyproject.toml`, `scripts/thai_env_cli.py`, `scripts/thai_env_engine.py`, `scripts/thai_env_helper.py`, `tests/test_thai_env_skill.py`, `tests/test_adversarial_skill.py`).
  - AgentResearch Helper: `D:\DEV\AgentResearch\Scripts\thai_env_helper.py`.

## Feature Inventory
| # | Feature | Description | Milestone | Source | Status |
|---|---------|-------------|-----------|--------|:------:|
| 1 | F1: Master Environmental Standards | Complete lighting Lux, noise 86 dBA/85 dBA, heat WBGT 34/32/30°C catalog | M1 | Survey / Law | **DONE** |
| 2 | F2: Data Models & SQLite v7 | Domain models, JSON serialization, SQLite v6->v7 migration & repository | M1 | Codebase | **DONE** |
| 3 | F3: Sessions & Subcontractor | Annual sessions, Subcontractor Sec 9 (นบ.) / Sec 11 (บ.), multi-attachments | M2 | Requirements | **DONE** |
| 4 | F4: Point Auto-Evaluation Engine | Calculation & evaluation engine for Light, Noise (TWA/Action level), Heat WBGT | M2 | Law / Formulas | **DONE** |
| 5 | F5: CAPA & Hearing Conservation | Auto-CAPA creation, 3-tier controls (Eng/Admin/PPE), Hearing Conservation tracking | M3 | Requirements | **DONE** |
| 6 | F6: UI EnvironmentPage & 4 Tabs | Flutter UI with 4 tabs, KPI cards, sampling tables, modals, AppShell index 11 | M3 | UX / Figma | **DONE** |
| 7 | F7: Official PDF/Excel Exporters | DLPW 6-section PDF report with Sarabun font & multi-sheet Excel exporter | M4 | Requirements | **DONE** |
| 8 | F8: Agent Skill & AgentResearch | `thai-environmental-safety-law` skill & `thai_env_helper.py` with 14 tests | M5 | Agent Research | **DONE** |
| 9 | F9: E2E Testing & Forensic Audit | Unit, widget, E2E tests, Challenger stress test & Forensic Integrity Audit | M6 | Acceptance | **DONE** |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|:------:|
| M1 | Master Standards & Models | Domain models, JSON serialization, Master static catalog, SQLite v7 migration | none | **DONE** |
| M2 | Core Evaluation & Services | Evaluation calculators (Light, Noise, WBGT), KPI Aggregator, Repository & Services | M1 | **DONE** |
| M3 | UI Presentation & CAPA | EnvironmentPage (4 Tabs), Riverpod providers, Modals, Forms, AppShell | M2 | **DONE** |
| M4 | Attachments & PDF/Excel Export | Multi-category attachment manager, PDF Sarabun generator, Excel exporter | M2, M3 | **DONE** |
| M5 | Agent Skill & CLI Helper | SKILL.md, CLI engine/scripts, AgentResearch helper, 14 Python unit tests | M1, M2 | **DONE** |
| M6 | E2E Testing & Audit Hardening | Full Flutter test suite (100% pass), Challenger verification, Forensic Audit | M1-M5 | **DONE** |

## Interface Contracts
### 1. Evaluation Engine Contract
```dart
class EnvironmentalEvaluator {
  static LightEvaluationResult evaluateLighting({
    required double measuredLux,
    required String standardId,
    double? surroundingLux,
  });

  static NoiseEvaluationResult evaluateNoise({
    required double measuredDba,
    required NoiseMeasurementType type, // area, personalTwa, peak
    double durationHours = 8.0,
    double? peakDb,
  });

  static HeatEvaluationResult evaluateHeat({
    required double nwb,
    required double gt,
    double? db,
    required bool isOutdoor,
    required WorkloadLevel workload, // light, moderate, heavy
  });

  static EnvironmentKpiSummary calculateKpi(List<EnvironmentPointModel> points, [List<EnvironmentCapaModel>? capas]);
}
```

### 2. Subcontractor Verification Contract
```dart
class SubcontractorVerifier {
  static SubcontractorValidationResult validate({
    required SubcontractorType type, // section9Individual, section11Juristic
    required String licenseNumber,
    DateTime? expirationDate,
  });
}
```

### 3. Agent Skill CLI Contract
```bash
python thai_env_cli.py search-light [--category CAT] [--query QUERY] [-v LUX] [-s SURROUNDING_LUX]
python thai_env_cli.py eval-noise -v MEASURED_DBA [-t DURATION_HOURS] [--peak-db PEAK_DB]
python thai_env_cli.py calc-wbgt --nwb NWB --gt GT [--db DB] [--outdoor] -w {light|moderate|heavy}
python thai_env_cli.py eval-session [--input-file JSON_FILE] [--format {json|table}]
python thai_env_cli.py verify-subcontractor -t {section_9_individual|section_11_juristic} -n LICENSE_NO [-e EXP_DATE]
python thai_env_cli.py get-env-law [-t LAW_TYPE] [-s SECTION]
```

## Code Layout
- `lib/features/environment/domain/models/`:
  - `environment_standard_model.dart`
  - `subcontractor_model.dart`
  - `environment_session_model.dart`
  - `environment_point_model.dart`
  - `environment_capa_model.dart`
  - `environment_kpi_summary.dart`
- `lib/features/environment/domain/services/`:
  - `environmental_evaluator.dart`
  - `subcontractor_verifier.dart`
- `lib/features/environment/data/`:
  - `environmental_standards_data.dart`
  - `environmental_gazette_data.dart`
  - `environment_repository.dart`
- `lib/features/environment/presentation/`:
  - `providers/environment_providers.dart`
  - `pages/environment_page.dart`
  - `screens/environment_page.dart`
  - `tabs/environment_dashboard_tab.dart`
  - `tabs/environment_points_tab.dart`
  - `tabs/environment_capa_tab.dart`
  - `tabs/environment_gazette_tab.dart`
  - `widgets/`: KPI cards, point dialogs, session dialogs, attachment list, preview dialogs.
- `lib/features/environment/services/`:
  - `environment_pdf_exporter.dart`
  - `environment_excel_exporter.dart`
- `lib/core/database/database_helper.dart` (migration to v7)
- `lib/core/widgets/app_shell.dart` (navigation item index 11)
- `test/features/environment/`:
  - `environmental_evaluator_test.dart`
  - `environment_models_test.dart`
  - `environment_repository_test.dart`
  - `environment_exporters_test.dart`
  - `environment_page_widget_test.dart`
  - `environmental_adversarial_stress_test.dart`
- Agent Skill:
  - `skills/thai-environmental-safety-law/SKILL.md`
  - `skills/thai-environmental-safety-law/pyproject.toml`
  - `skills/thai-environmental-safety-law/scripts/thai_env_cli.py`
  - `skills/thai-environmental-safety-law/scripts/thai_env_engine.py`
  - `skills/thai-environmental-safety-law/scripts/thai_env_helper.py`
  - `skills/thai-environmental-safety-law/scripts/data/standards.json`
  - `skills/thai-environmental-safety-law/tests/test_thai_env_skill.py`
  - `skills/thai-environmental-safety-law/tests/test_adversarial_skill.py`
- AgentResearch:
  - `D:\DEV\AgentResearch\Scripts\thai_env_helper.py`
