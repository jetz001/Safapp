## 2026-09-01T13:32:11Z
Scope & Tasks:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md and d:\DEV\SAFAPP\PROJECT.md.
2. Read analysis from d:\DEV\SAFAPP\.agents\explorer_codebase\analysis.md and d:\DEV\SAFAPP\.agents\spec_miner_env\analysis.md.
3. Implement Domain Models in `lib/features/environment/domain/models/`:
   - `environment_standard_model.dart` (Lighting Lux catalog, Noise thresholds, Heat WBGT limits)
   - `subcontractor_model.dart` (Section 9 นบ., Section 11 บ., cert numbers, verification methods)
   - `environment_session_model.dart` (Annual sessions, dates, location, subcontractor info, multi-category attachments)
   - `environment_point_model.dart` (Sampling points: Light Lux, Noise TWA/Peak, Heat WBGT indoor/outdoor, parameters, measured values, auto-evaluation status)
   - `environment_capa_model.dart` (Corrective actions: root cause, Eng/Admin/PPE control, PIC, target date, status)
   - `environment_kpi_summary.dart` (Total points, pass, exceed, action level/watch, % compliance)
4. Implement Master Data Catalogs in `lib/features/environment/data/`:
   - `environmental_standards_data.dart` (Full lighting categories from DLPW 2561, noise limits from 2561, heat limits & formulas from 2563)
   - `environmental_gazette_data.dart` (Thai Royal Gazette references: Act 2554, Reg 2559, Light 2561, Noise 2561, Heat 2563, Reporting Form 2563)
5. Implement SQLite Database Migration in `lib/core/database/database_helper.dart`:
   - Update database version to 7 (or next version if v6). Add migration logic for 4 tables: `environment_standards_master`, `environment_sessions`, `environment_measurement_points`, `environment_capa`.
6. Implement Evaluation & Verification Services:
   - `lib/features/environment/domain/services/environmental_evaluator.dart` (Lighting evaluator, Noise evaluator with TWA & Action Level 85 dBA trigger, Heat WBGT evaluator with indoor/outdoor formula, KPI calculation).
   - `lib/features/environment/domain/services/subcontractor_verifier.dart`
   - `lib/features/environment/data/environment_repository.dart`
7. Implement Riverpod Providers in `lib/features/environment/presentation/providers/environment_providers.dart`.
8. Write comprehensive Unit Tests in `test/features/environment/`:
   - `environmental_evaluator_test.dart` (Verify WBGT indoor/outdoor, Lighting thresholds, Noise TWA/Action level/Peak, KPI calculations)
   - `environment_models_test.dart` (Serialization/deserialization, copyWith, calculations)
   - `environment_repository_test.dart`
9. Run `flutter test` via powershell and ensure all tests pass with 100% success.
10. Write detailed completion report to `d:\DEV\SAFAPP\.agents\worker_flutter_core\handoff.md` including exact test execution commands and outputs. Send completion message to parent.
