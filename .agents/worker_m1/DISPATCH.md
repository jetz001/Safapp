## 2026-08-31T15:19:36Z
You are Worker M1: Data Models, Master Seed Data & Repository for SAFAPP Legal Register.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m1
Original user request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Project specification path: d:\DEV\SAFAPP\PROJECT.md
Survey reports for reference:
- d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\legal_spec.md
- d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\safety_legal_catalog.json
- d:\DEV\SAFAPP\.agents\explorer_survey_codebase_1\survey_codebase.md

Your Exclusive Write Ownership:
- lib/features/legal_register/domain/models/legal_master_item_model.dart
- lib/features/legal_register/domain/models/legal_compliance_assessment_model.dart
- lib/features/legal_register/domain/models/legal_capa_model.dart
- lib/features/legal_register/domain/models/legal_compliance_stats_model.dart
- lib/features/legal_register/data/safety_legal_8_categories_data.dart
- lib/features/legal_register/data/legal_register_repository.dart
- lib/features/legal_register/presentation/providers/legal_register_providers.dart
- lib/core/database/database_helper.dart (safely update to add legal_register SQLite tables: safety_legal_master, safety_legal_assessments, safety_legal_capa, and seed insertion on first run)

Tasks:
1. Implement the 4 domain models with full serialization (toJson / fromMap / toMap / copyWith / fromJson).
2. Implement safety_legal_8_categories_data.dart containing the authoritative 32 master items across 8 Thai Royal Gazette laws (พ.ร.บ. ๒๕๕๔, จป./คปอ. ๒๕๖๕, สารเคมี ๒๕๕๖, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, เครื่องจักร/ปั้นจั่น ๒๕๖๔, สิ่งแวดล้อมแสงเสียง ๒๕๕๙, ตรวจสุขภาพ ๒๕๖๓).
3. Update DatabaseHelper with table creation and migrations for legal register.
4. Implement LegalRegisterRepository with full SQLite persistence, filtering, assessment state transitions, CAPA creation/deletion, and compliance KPI calculations (both Basic % and Risk-Weighted %).
5. Implement Riverpod 3 StateNotifiers / Notifiers and providers in legal_register_providers.dart.
6. Verify your implementation by running Flutter tests/analyzers if applicable.
7. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m1\handoff.md and report back to parent (bedb8118-4836-4c4c-a9fb-ce9e5b6459df).
