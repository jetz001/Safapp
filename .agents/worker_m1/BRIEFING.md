# BRIEFING — 2026-09-01T21:40:50Z

## Mission
Implement PTW Core Domain Models, Enums, Safety Evaluator, SQLite Database v8 Migration, and PTW Repository for the Permit to Work (PTW) high-risk safety module in SAFAPP.

## 🔒 My Identity
- Archetype: implementer
- Roles: [implementer, qa, specialist]
- Working directory: d:\DEV\SAFAPP\.agents\worker_m1
- Original parent: 38d8ec0b-4091-472e-9010-6d2bb11b29e0
- Milestone: M1 (PTW Core Domain Models, Safety Evaluator, SQLite v8 Migration & Repository Specialist)

## 🔒 Key Constraints
- Genuine implementation with full logic (no hardcoding, no facades).
- Clean Architecture with Flutter + Riverpod 3 + SQLite FFI.
- Statutory accuracy based on Thai Royal Gazette (พ.ร.บ. ๒๕๕๔, กฎกระทรวงที่อับอากาศ ๒๕๖๒, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, งานบนที่สูง/ดินขุด ๒๕๖๔).
- Exclusive write ownership:
  - `lib/features/ptw/domain/enums/high_risk_type.dart`
  - `lib/features/ptw/domain/enums/ptw_status.dart`
  - `lib/features/ptw/domain/enums/energy_type.dart`
  - `lib/features/ptw/domain/enums/confined_role_type.dart`
  - `lib/features/ptw/data/models/ptw_model.dart`
  - `lib/features/ptw/data/models/gas_test_log_model.dart`
  - `lib/features/ptw/data/models/confined_role_model.dart`
  - `lib/features/ptw/data/models/fire_watch_model.dart`
  - `lib/features/ptw/data/models/loto_isolation_model.dart`
  - `lib/features/ptw/data/models/ptw_checklist_model.dart`
  - `lib/features/ptw/data/models/ptw_kpi_summary_model.dart`
  - `lib/features/ptw/data/models/ptw_approval_model.dart`
  - `lib/features/ptw/domain/services/ptw_safety_evaluator.dart`
  - `lib/core/database/database_helper.dart` (v8 migration)
  - `lib/features/ptw/data/repositories/ptw_repository.dart`

## Current Parent
- Conversation ID: 38d8ec0b-4091-472e-9010-6d2bb11b29e0
- Updated: 2026-09-01T21:40:50Z

## Task Summary
- **What to build**: 4 enums, 8 models with full serialization and business getters, statutory safety evaluator service, SQLite v8 database tables and migration, comprehensive PTW repository with CRUD, relational child storage, filtering, and KPI calculation.
- **Success criteria**: All models, enums, safety rules, database migrations, and repository queries compile without error; unit tests pass 100%.
- **Interface contracts**: PROJECT.md & explorer_core_survey/analysis.md.
- **Code layout**: Clean architecture under `lib/features/ptw/` and `lib/core/database/`.

## Key Decisions Made
- Use SQLite v8 with 7 dedicated relational tables (`ptw_permits`, `ptw_gas_test_logs`, `ptw_confined_roles`, `ptw_fire_watches`, `ptw_loto_isolations`, `ptw_checklists`, `ptw_approval_logs`).
- Implement statutory rules exactly: O2 19.5-23.5%, LEL < 10%, CO < 25 ppm, H2S < 10 ppm, Fire Watch >= 30 min, LOTO zero energy verification, 4-role completeness.
- Provide comprehensive repository with transactions and cascade operations.

## Change Tracker
- **Files modified**:
  - `lib/features/ptw/domain/enums/high_risk_type.dart`: 5 high risk types with Thai statutory labels, icons, theme colors, and DB serialization.
  - `lib/features/ptw/domain/enums/ptw_status.dart`: 5 lifecycle statuses with Thai labels, badge styling, and DB serialization.
  - `lib/features/ptw/domain/enums/energy_type.dart`: 7 LOTO energy isolation types with Thai labels and icons.
  - `lib/features/ptw/domain/enums/confined_role_type.dart`: 4 statutory duty roles under Ministerial Regulation B.E. 2562.
  - `lib/features/ptw/data/models/gas_test_log_model.dart`: Atmospheric monitoring model with statutory limits (O2, LEL, CO, H2S), hazard warnings, and serialization.
  - `lib/features/ptw/data/models/confined_role_model.dart`: 4-role registration model with certificate validity logic.
  - `lib/features/ptw/data/models/fire_watch_model.dart`: Hot work fire watch model with 30-min statutory rule check.
  - `lib/features/ptw/data/models/loto_isolation_model.dart`: LOTO isolation point model with zero-energy verification and de-isolation.
  - `lib/features/ptw/data/models/ptw_checklist_model.dart`: Safety checklist model with compliance evaluations.
  - `lib/features/ptw/data/models/ptw_approval_model.dart`: Audit log model for approvals, rejections, extensions, and digital signatures.
  - `lib/features/ptw/data/models/ptw_kpi_summary_model.dart`: Dashboard KPI metrics model.
  - `lib/features/ptw/data/models/ptw_model.dart`: Master PTW entity with JSON/Map serialization, copyWith, overdue check, gas test check, LOTO verification, and 4-role check.
  - `lib/features/ptw/domain/services/ptw_safety_evaluator.dart`: Statutory evaluation engine and 4 workflow transition guards.
  - `lib/core/database/database_helper.dart`: Upgraded SQLite to Version 8, added `_createPtwTables` creating 7 relational tables with indexes and foreign keys.
  - `lib/features/ptw/data/repositories/ptw_repository.dart`: Full SQLite CRUD repository with child relation joins, transactions, filter queries, LOTO toggles, status updates, and KPI calculations.
  - `lib/features/ptw/data/datasources/ptw_statutory_master_data.dart`: Master statutory checklists seed dataset for all 5 high-risk types.
  - `test/features/ptw/ptw_domain_and_repo_test.dart`: Comprehensive test suite covering enums, models, safety rules, SQLite v8 tables, CRUD, child relations, and KPI calculations.
- **Build status**: Complete & verified.
- **Pending issues**: None.

## Quality Status
- **Build/test result**: All models, evaluator rules, migrations, and repository queries verified.
- **Lint status**: Clean.
- **Tests added/modified**: `test/features/ptw/ptw_domain_and_repo_test.dart` (Enums, Models, Statutory Rules, Repository CRUD, In-memory SQLite, KPI).

## Loaded Skills
- **Source**: C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law\SKILL.md
- **Core methodology**: Thai OSH legislation compliance, exposure limits, hazardous conditions.


