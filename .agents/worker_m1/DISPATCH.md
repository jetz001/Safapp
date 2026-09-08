## 2026-09-01T21:40:40Z
You are Worker M1: PTW Core Domain Models, Safety Evaluator, SQLite v8 Migration & Repository Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m1\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Context & Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md and d:\DEV\SAFAPP\PROJECT.md.
2. Review d:\DEV\SAFAPP\.agents\explorer_core_survey\analysis.md for exact specifications.
3. Implement the following files in d:\DEV\SAFAPP:
   - `lib/features/ptw/domain/enums/high_risk_type.dart` (5 types: hotWork, confinedSpace, workingAtHeight, electricalLoto, excavationLifting with Thai labels, icons, and theme colors)
   - `lib/features/ptw/domain/enums/ptw_status.dart` (5 statuses: draft, pendingApproval, active, extendedHandover, closedCancelled with Thai labels and colors)
   - `lib/features/ptw/domain/enums/energy_type.dart` (electrical, pneumatic, hydraulic, chemical, mechanical, thermal, other)
   - `lib/features/ptw/domain/enums/confined_role_type.dart` (authorizer, supervisor, attendant, entrant)
   - `lib/features/ptw/data/models/ptw_model.dart` (Comprehensive permit entity with JSON/Map serialization, copyWith, getters like isOverdue, hasValidGasTest, etc.)
   - `lib/features/ptw/data/models/gas_test_log_model.dart` (O2, LEL, CO, H2S, testTime, testerName, preEntry vs continuous, isSafe)
   - `lib/features/ptw/data/models/confined_role_model.dart` (roleType, personName, certificateNo, certExpiryDate, contactNo)
   - `lib/features/ptw/data/models/fire_watch_model.dart` (watcherName, hotWorkEndTime, checkTime, durationMinutes, isSafe, extinguisherReady)
   - `lib/features/ptw/data/models/loto_isolation_model.dart` (energyType, isolationPoint, tagNo, padlockNo, appliedBy, zeroEnergyVerified, verificationMethod)
   - `lib/features/ptw/data/models/ptw_checklist_model.dart` (category, itemText, isCompliant, notes, checkedBy)
   - `lib/features/ptw/data/models/ptw_kpi_summary_model.dart` (KPI metrics)
   - `lib/features/ptw/data/models/ptw_approval_model.dart` (approval audit log)
   - `lib/features/ptw/domain/services/ptw_safety_evaluator.dart` (Exact legal rules: O2 19.5-23.5%, LEL <10%, CO <25ppm, H2S <10ppm, Fire Watch >=30min, LOTO zero-energy, 4-role completeness)
   - `lib/core/database/database_helper.dart` (Bump version to 8, add upgrade logic creating ptw_permits, ptw_gas_test_logs, ptw_confined_roles, ptw_fire_watches, ptw_loto_isolations, ptw_checklists, ptw_approval_logs)
   - `lib/features/ptw/data/repositories/ptw_repository.dart` (SQLite CRUD, joins, child relation persistence, filtering, KPI calculations)
4. Verify by running unit tests or flutter test commands on your changes.
5. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m1\handoff.md following the Handoff Protocol.
6. Send completion message to parent.

