# Project: High-Risk Permit to Work (PTW) System & Thai Safety Law Agent Skill

## Architecture
The PTW module in SAFAPP is architected around a layered, reactive, clean-architecture pattern powered by **Flutter Riverpod 3**, persistent **SQLite v8**, statutory **Thai Safety Legal Evaluators**, pure Flutter **Signature Canvas**, vector **QR Code generation**, official **DLPW A4 PDF & Excel Exporters**, and an external **Agent Skill (`thai-ptw-safety-law`)** for multi-agent safety reasoning.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   SAFAPP UI LAYER                                      │
│  PtwPage (AppShell Index 5)                                                            │
│  ├── Tab 1: PtwDashboardTab (KPI Cards, Filter Bar, Responsive Data Table, Actions)   │
│  ├── Tab 2: PtwWizardTab (6-Step Guided Creation: Info -> Risk -> Check -> Sign)       │
│  ├── Tab 3: PtwLiveControlsTab (Gas Tracker, 30-min Fire Watch, LOTO Verify, Handover) │
│  └── Tab 4: PtwLegalLibraryTab (5 Royal Gazette Regulations Viewer & Search)           │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                           STATE MANAGEMENT & CONTROLLER LAYER                          │
│  - ptwListProvider (AsyncNotifier)         - ptwFilterProvider (Notifier)              │
│  - ptwDetailProvider (Family AsyncNotifier) - ptwKpiProvider (Provider)                │
│  - liveGasLogsProvider (Notifier)          - fireWatchTimerProvider (StateNotifier)   │
│  - PtwWorkflowEngine (5-State Guarded State Machine)                                   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                           DOMAIN & BUSINESS LOGIC LAYER                                │
│  - PtwModel, GasTestLogModel, ConfinedRoleModel, FireWatchModel, LotoIsolationModel    │
│  - Enums: HighRiskType (5), PtwStatus (5), EnergyType (5), ConfinedRoleType (4)        │
│  - PtwSafetyEvaluator: O2 (19.5-23.5%), LEL (<10%), CO (<25ppm), H2S (<10ppm)         │
│                        Fire Watch (>=30m), LOTO Zero Energy, 4-Role Completeness       │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                           DATA ACCESS & EXPORT SERVICES                                │
│  - DatabaseHelper (SQLite v8 Migration: 6 Relational Tables with Foreign Keys)         │
│  - PtwRepository (CRUD, Transactional Child Updates, Filters, Relational Joins)        │
│  - PtwPdfExporter (Official DLPW A4 Format, Signature Images, Vector QR Code)          │
│  - PtwExcelExporter (5-Sheet Analytics Workbook)                                       │
│  - SignaturePadWidget (CustomPainter -> Uint8List PNG Bytes)                           │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                       MULTI-AGENT SKILL & PYTHON TOOLING LAYER                         │
│  - C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\ (SKILL.md, CLI, Engine)   │
│  - D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py (Dual-Mode Python API)              │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | High-Risk PTW Models & Enums | 5 high-risk types, 5 workflow statuses, domain entities with JSON/DB mapping | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Statutory Safety Evaluator | Gas safety (O2, LEL, CO, H2S), 4-role check, 30m fire watch, zero-energy rules | M1 | ORIGINAL_REQUEST §R1, R3 |
| 3 | SQLite Schema v8 Migration | 6 relational tables with foreign keys and index optimization | M1 | Explorer 1 Survey |
| 4 | PtwRepository & Data Access | Complete CRUD and reactive query integration with SQLite v8 | M1 | Explorer 1 Survey |
| 5 | 5-State Workflow State Machine | Guarded transitions (Draft -> Pending -> Active -> Extended -> Closed) | M2 | ORIGINAL_REQUEST §R2 |
| 6 | Digital Signature Canvas | Pure Flutter CustomPainter signature pad exporting PNG bytes | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Riverpod 3 State Layer | AsyncNotifier providers for list, filters, details, KPIs, live controls | M2 | Explorer 1 & 2 Survey |
| 8 | Live Site Safety Controls | Continuous Gas Tracker, 30-min Fire Watch Timer, LOTO zero-energy logger | M3 | ORIGINAL_REQUEST §R3 |
| 9 | PtwPage 4-Tab Interface | Dashboard, Create/Edit Wizard, Live Controls, Legal Library | M3 | ORIGINAL_REQUEST §R4 |
| 10 | Interactive Dialogs & Details | Comprehensive detail modal, approval sign-off, live tool modal | M3 | Explorer 2 Survey |
| 11 | Official DLPW PDF Generator | A4 certificate conforming to Labor Department standard with QR Code | M4 | ORIGINAL_REQUEST §R5 |
| 12 | Screen QR Code Component | Vector QR Code renderer for on-site mobile audit | M4 | ORIGINAL_REQUEST §R5 |
| 13 | Multi-Sheet Excel Exporter | 5-sheet analytics workbook for PTW registers and safety audits | M4 | ORIGINAL_REQUEST §R5 |
| 14 | Agent Skill `thai-ptw-safety-law` | SKILL.md, CLI script with 5 subcommands, rule engine, unit tests | M5 | ORIGINAL_REQUEST §R6 |
| 15 | Multi-Agent Helper Script | `thai_ptw_helper.py` in `D:\DEV\AgentResearch\Scripts\` | M5 | ORIGINAL_REQUEST §R6 |
| 16 | E2E 4-Tier Test Suite | Tier 1-4 tests (Flutter & Python) ensuring 100% test pass rate | M6 | ORIGINAL_REQUEST §A4 |
| 17 | Adversarial Hardening (Tier 5) | Stress tests, boundary attacks, and forensic audit verification | M6 | Project Pattern |
| 18 | Multi-Hazard ERP Builder (6 Pillars) | 5 hazard types, 6 statutory sub-plans, smart industry presets | M7 | Statutory B.E. 2555 |
| 19 | Drill Management & Form สปร. ๔ | Annual drill SLA countdown, live timer, headcount, DLPW PDF & Excel | M7 | Clause 30 & SPR 4 |
| 20 | Agent Skill `thai-emergency-response-plan` | SKILL.md, CLI subcommands (calc quota, extinguishers, audit drill) | M7 | Workflow Skill Creator |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Core Models, Evaluators & DB v8 | Domain models, enums, `PtwSafetyEvaluator`, SQLite v8 schema, `PtwRepository` | none | DONE |
| M2 | State Machine, Riverpod & Signatures | `PtwWorkflowEngine`, Riverpod notifiers, `SignaturePadWidget`, Live controllers | M1 | IN_PROGRESS |
| M3 | PtwPage 4-Tab UI & Live Controls | Dashboard, 6-Step Wizard, Live Controls, Legal Reference Library, Dialogs | M2 | PLANNED |
| M4 | Official PDF with QR & Excel Export | DLPW A4 PDF generator, embedded QR code, `PtwExcelExporter` | M3 | PLANNED |
| M5 | Thai PTW Agent Skill & Python Helper | `thai-ptw-safety-law` skill, CLI subcommands, `thai_ptw_helper.py`, Python tests | none | DONE |
| M6 | E2E Testing & Final Verification | 4-Tier Flutter/Python test suites, adversarial stress tests, 100% pass | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts

### 1. HighRiskType & PtwStatus Enums
```dart
enum HighRiskType {
  hotWork('Hot Work (งานประกายไฟ/ความร้อน)', Icons.local_fire_department, Color(0xFFEA580C)),
  confinedSpace('Confined Space (งานในที่อับอากาศ)', Icons.compress, Color(0xFF7C3AED)),
  workingAtHeight('Working at Height (งานบนที่สูง)', Icons.height, Color(0xFF0284C7)),
  electricalLoto('Electrical & LOTO (งานไฟฟ้าและการตัดแยกพลังงาน)', Icons.bolt, Color(0xFFEAB308)),
  excavationLifting('Excavation & Lifting (งานขุดเจาะและยกเคลื่อนย้าย)', Icons.construction, Color(0xFF16A34A));
}

enum PtwStatus {
  draft('Draft (ร่างคำขอ)', Color(0xFF64748B)),
  pendingApproval('Pending Approval (รออนุมัติ)', Color(0xFFD97706)),
  active('Active (กำลังปฏิบัติงาน)', Color(0xFF059669)),
  extendedHandover('Extended / Handover (ต่อเวลา/ส่งมอบ)', Color(0xFF2563EB)),
  closedCancelled('Closed / Cancelled (ปิดงาน/ยกเลิก)', Color(0xFF475569));
}
```

### 2. PtwSafetyEvaluator Contract
```dart
class PtwSafetyEvaluator {
  static GasEvaluationResult evaluateGasLevels({
    required double oxygenPercent, // 19.5% - 23.5%
    required double combustibleLelPercent, // < 10.0%
    required double carbonMonoxidePpm, // < 25.0 ppm
    required double hydrogenSulfidePpm, // < 10.0 ppm
  });

  static ConfinedRoleEvaluationResult evaluateConfinedSpaceRoles(
    List<ConfinedRoleModel> roles,
  );

  static FireWatchEvaluationResult evaluateFireWatch({
    required DateTime hotWorkEndTime,
    required DateTime fireWatchCheckedTime,
    required bool hasFireExtinguisher,
  });

  static LotoEvaluationResult evaluateLotoIsolations(
    List<LotoIsolationModel> isolations,
  );

  static bool isOverdue(PtwModel permit, {DateTime? currentTime});
}
```

### 3. PtwWorkflowEngine Contract
```dart
class PtwWorkflowEngine {
  static WorkflowTransitionResult validateTransition({
    required PtwModel currentPermit,
    required PtwStatus targetStatus,
    String? rejectionReason,
    String? signatoryName,
    Uint8List? signatureBytes,
  });
}
```

### 4. Agent Skill CLI Interface
```bash
python thai_ptw_cli.py validate-ptw --input-json <path>
python thai_ptw_cli.py eval-gas --o2 <val> --lel <val> --co <val> --h2s <val>
python thai_ptw_cli.py verify-confined-roles --roles-json <path>
python thai_ptw_cli.py get-checklist --risk-type <hot_work|confined_space|height|loto|excavation>
python thai_ptw_cli.py get-ptw-law --query <law_name>
```

## Code Layout
```
lib/
├── core/
│   └── database/
│       └── database_helper.dart                      [Modified: v7 -> v8 upgrade]
└── features/
    └── ptw/
        ├── data/
        │   ├── models/
        │   │   ├── ptw_model.dart                    [M1: Core permit entity]
        │   │   ├── gas_test_log_model.dart           [M1: Gas testing records]
        │   │   ├── confined_role_model.dart          [M1: 4-role registry entity]
        │   │   ├── fire_watch_model.dart             [M1: Hot work monitoring log]
        │   │   ├── loto_isolation_model.dart         [M1: Energy isolation record]
        │   │   ├── ptw_checklist_model.dart          [M1: Safety checklist entity]
        │   │   └── ptw_kpi_summary_model.dart        [M1: Analytics summary model]
        │   └── repositories/
        │       └── ptw_repository.dart               [M1: SQLite CRUD & queries]
        ├── domain/
        │   ├── enums/
        │   │   ├── high_risk_type.dart               [M1: 5 High-risk categories]
        │   │   ├── ptw_status.dart                   [M1: 5 Workflow statuses]
        │   │   ├── energy_type.dart                  [M1: LOTO energy classifications]
        │   │   └── confined_role_type.dart           [M1: 4 Statutory roles]
        │   └── services/
        │       ├── ptw_safety_evaluator.dart         [M1: Statutory rule engine]
        │       └── ptw_workflow_engine.dart          [M2: State machine guards]
        ├── presentation/
        │   ├── notifiers/
        │   │   ├── ptw_list_notifier.dart            [M2: Riverpod list provider]
        │   │   ├── ptw_filter_notifier.dart          [M2: Search/Filter state]
        │   │   └── ptw_live_controls_notifier.dart   [M2: Gas & Timer state]
        │   ├── pages/
        │   │   └── ptw_page.dart                     [M3: 4-Tab Main Host Page]
        │   ├── tabs/
        │   │   ├── ptw_dashboard_tab.dart            [M3: Tab 1: KPI & Register]
        │   │   ├── ptw_wizard_tab.dart               [M3: Tab 2: 6-Step Wizard]
        │   │   ├── ptw_live_controls_tab.dart        [M3: Tab 3: Site Controls]
        │   │   └── ptw_legal_library_tab.dart        [M3: Tab 4: Legal Reference]
        │   └── widgets/
        │       ├── signature_pad_widget.dart         [M2: CustomPainter Pad]
        │       ├── ptw_kpi_card.dart                 [M3: Summary Metrics]
        │       ├── ptw_status_chip.dart              [M3: Colored Badge]
        │       ├── ptw_detail_dialog.dart            [M3: Full View Dialog]
        │       ├── gas_test_logger_card.dart         [M3: Gas Level Input]
        │       ├── fire_watch_timer_card.dart        [M3: 30-min Countdown]
        │       └── ptw_qr_viewer_widget.dart         [M4: Vector QR Display]
        └── services/
            ├── ptw_pdf_exporter.dart                 [M4: Official DLPW A4 PDF]
            └── ptw_excel_exporter.dart               [M4: 5-Sheet Excel Exporter]

skills/thai-ptw-safety-law/ (and C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\)
├── SKILL.md                                          [M5: Skill Metadata & Instructions]
├── pyproject.toml                                    [M5: Python Packaging]
├── scripts/
│   ├── thai_ptw_cli.py                              [M5: CLI Subcommands]
│   ├── thai_ptw_engine.py                           [M5: Legal Rule Engine]
│   └── thai_ptw_helper.py                           [M5: Local Helper]
└── tests/
    └── test_thai_ptw_skill.py                        [M5: 15+ Automated Unit Tests]

D:\DEV\AgentResearch\Scripts/
└── thai_ptw_helper.py                                [M5: Multi-Agent Dual-Mode Helper]

test/
└── features/
    └── ptw/
        ├── ptw_models_test.dart                      [M6: Domain entity unit tests]
        ├── ptw_safety_evaluator_test.dart            [M6: Statutory threshold tests]
        ├── ptw_workflow_engine_test.dart             [M6: State machine transition tests]
        ├── ptw_repository_test.dart                  [M6: Database CRUD & join tests]
        ├── ptw_notifiers_test.dart                   [M6: Riverpod state tests]
        ├── ptw_export_test.dart                      [M6: PDF & Excel generator tests]
        └── ptw_page_widget_test.dart                 [M6: Full UI & 4-Tab Widget tests]
```
