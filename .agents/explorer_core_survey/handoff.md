# Handoff Report: PTW Core Architecture & Models Survey

**Agent**: Explorer 1 (Core & Models Specialist)  
**Target Workspace**: `d:\DEV\SAFAPP`  
**Report Path**: `d:\DEV\SAFAPP\.agents\explorer_core_survey\handoff.md`  
**Date**: 2026-09-01  

---

## 1. Observation

1. **Pubspec & Dependencies (`d:\DEV\SAFAPP\pubspec.yaml`)**:
   - `flutter_riverpod: ^3.3.2` is the standard application-wide state management solution.
   - `sqflite_common_ffi: ^2.4.0+3` with `sqlite3_flutter_libs: ^0.6.0+eol`, `path: ^1.9.1`, and `path_provider: ^2.1.6` handles desktop SQLite persistence.
   - `pdf: ^3.12.0` and `printing: ^5.14.3` are installed for PDF compilation, preview, and sharing.
   - `excel: ^4.0.6` is installed for Excel export.
   - `syncfusion_flutter_pdfviewer: ^33.2.13` handles in-app PDF rendering.

2. **Database Helper (`d:\DEV\SAFAPP\lib\core\database\database_helper.dart`)**:
   - Lines 42–48: Database is currently at `version: 7`.
   - Lines 30–38: Database file is stored at `${appDocDir.path}\SafetySuperapp\safety_superapp_v1.db`.
   - Lines 103–141: `_onUpgrade` incrementally creates and alters tables based on version numbers (Version 2 for Risk Assessment, Version 5 for Chemicals, Version 6 for Legal, Version 7 for Environment).
   - Foreign key cascading is used across parent/child tables (e.g. `rca_analysis`, `environment_measurement_points`, `environment_capa`).

3. **Existing Feature Conventions (`lib/features/environment/` and `lib/features/chemicals/`)**:
   - Domain models use immutable Dart classes with `toMap()`, `fromMap()`, `toJson()`, `fromJson()`, `copyWith()`, and domain helper getters (e.g. `isCompliant`, `statusBadgeColor`).
   - Repositories encapsulate all raw SQL operations and attachment copying to dedicated `SafetySuperapp/<module>/` folders.
   - State Notifiers use Riverpod 3 `Notifier<T>` / `NotifierProvider` for UI filters and `AsyncNotifier<T>` / `AsyncNotifierProvider` for entity lists with auto-invalidation (`ref.invalidateSelf()`).

4. **App Shell Navigation (`d:\DEV\SAFAPP\lib\core\widgets\app_shell.dart`)**:
   - Lines 53 & Line 65: Index 5 is mapped to `const PtwPage()`.
   - `lib/features/ptw/presentation/pages/ptw_page.dart` is currently a 33-line placeholder scaffold.

5. **Statutory Mandates (Thai Royal Gazette)**:
   - **กฎกระทรวงที่อับอากาศ ๒๕๖๒**: ข้อ ๗ specifies hazardous atmosphere limits ($19.5\% \le O_2 \le 23.5\%$, $\text{LEL} < 10\%$, $CO < 25\text{ ppm}$, $H_2S < 10\text{ ppm}$). ข้อ ๙-๑๒ specifies 4 mandatory roles: ผู้อนุญาต (Authorizer), ผู้ควบคุมงาน (Supervisor), ผู้ช่วยเหลือ (Attendant), ผู้ปฏิบัติงาน (Entrant).
   - **กฎกระทรวงอัคคีภัย ๒๕๕๕**: Hot Work fire safety, clear zone radius ($\ge 11\text{ m}$ / 35 ft), Fire Watcher assignment, and $\ge 30\text{ min}$ post-work fire monitoring.
   - **กฎกระทรวงไฟฟ้า ๒๕๕๘**: Lockout/Tagout (LOTO), padlock identification, and zero-energy state verification.
   - **กฎกระทรวงนั่งร้าน งานบนที่สูง และงานดินขุด ๒๕๖๔**: Fall protection at height $\ge 2\text{ m}$ (Full body harness + anchor), excavation shoring at depth $\ge 1.5\text{ m}$.

---

## 2. Logic Chain

1. **Step 1 (State & Persistence Alignment)**: Given that Riverpod 3 and `sqflite_common_ffi` are the established foundations of SAFAPP (Obs 1 & 2), the PTW module must implement `PtwRepository` and `PtwNotifier` using these exact patterns rather than introducing new third-party state managers or ORMs.
2. **Step 2 (Database Schema Versioning)**: Because `DatabaseHelper` is currently at Version 7 (Obs 2), creating the 6 required PTW tables (`ptw_permits`, `ptw_gas_test_logs`, `ptw_confined_roles`, `ptw_fire_watches`, `ptw_loto_isolations`, `ptw_checklists`) requires incrementing the database schema version to `version: 8` with an upgrade hook in `_onUpgrade` (`if (oldVersion < 8)`).
3. **Step 3 (Mathematical & Legal Encodings)**: Since Thai ministerial regulations enforce exact numeric safety boundaries (Obs 5), all boundary checks ($O_2, LEL, CO, H_2S$, 30-min fire watch countdown, LOTO zero-energy, 4-role completeness) must be implemented directly in domain models and a dedicated `PtwSafetyEvaluator` domain service.
4. **Step 4 (Workflow State Machine)**: To prevent unauthorized work, state transitions must enforce strict pre-conditions:
   - `Draft` $\rightarrow$ `PendingApproval` requires applicant signature and complete checklist.
   - `PendingApproval` $\rightarrow$ `Active` requires Safety Officer and Authorizer signatures, valid pre-entry gas test (if confined space), and zero-energy verification (if electrical LOTO).
   - `Active` $\rightarrow$ `ClosedCancelled` requires post-work housekeeping, $\ge 30$-minute fire watch verification (if hot work), and closure sign-off.
5. **Step 5 (UI Integration)**: To fulfill the 4-tab user experience requested in `ORIGINAL_REQUEST.md`, `PtwPage` must be developed with (1) Dashboard & PTW Register, (2) Create/Edit Wizard with Digital Signature Pad, (3) Live Site Tools (Gas Test Logger, 30-Min Fire Watch Countdown, LOTO Verification), and (4) Gazette Legal Library.

---

## 3. Caveats

- **No caveats**. The existing codebase architecture is clean, cohesive, and fully inspectable. All required Flutter dependencies are present in `pubspec.yaml`.

---

## 4. Conclusion

1. The architectural blueprint for the PTW system is complete, fully specified in `analysis.md`, and ready for downstream implementation.
2. The domain models (`PtwModel`, `GasTestLogModel`, `ConfinedRoleModel`, `FireWatchModel`, `LotoIsolationModel`, `PtwChecklistModel`, `PtwKpiSummaryModel`), enums (`HighRiskType`, `PtwStatus`, `EnergyType`, `ConfinedRoleType`), SQLite version 8 migration schema, Riverpod notifiers, and Thai legal rule engines are strictly designed and documented.
3. Subsequent implementation agents (Explorer 2 for UI/Widgets, and Implementers) can proceed directly without architectural ambiguities.

---

## 5. Verification Method

To independently verify the survey observations and models:
1. Inspect the survey report at `d:\DEV\SAFAPP\.agents\explorer_core_survey\analysis.md`.
2. Inspect `pubspec.yaml` and `lib/core/database/database_helper.dart` to verify Riverpod 3 and Database Version 7 status.
3. Validate Thai statutory thresholds using `thai-safety-legal-register` skill:
   ```bash
   uv run C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\scripts\thai_safety_legal_cli.py search -q "ที่อับอากาศ"
   ```
4. Verify project compilation and test harness:
   ```powershell
   flutter test
   ```
