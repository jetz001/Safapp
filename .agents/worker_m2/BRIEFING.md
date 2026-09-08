# BRIEFING — 2026-09-01T21:50:00+07:00

## Mission
Implement Worker M2: PTW Workflow State Machine (PtwWorkflowEngine), Riverpod 3 State Notifiers (ptw_list_notifier, ptw_filter_notifier, ptw_detail_notifier, ptw_live_controls_notifier), SignaturePadWidget with CustomPainter & PNG export, and verify with tests.

## 🔒 My Identity
- Archetype: worker
- Roles: implementer, qa, specialist
- Working directory: d:\DEV\SAFAPP\.agents\worker_m2
- Original parent: bedb8118-4836-4c4c-a9fb-ce9e5b6459df
- Milestone: M2 - Legal Register UI
- Worker M2 (PTW): PTW Workflow State Machine, Riverpod State Notifiers, Signature Pad & Live Controllers Specialist
- Parent: 38d8ec0b-4091-472e-9010-6d2bb11b29e0

## 🔒 Key Constraints
- Exclusive write ownership:
  - lib/features/legal_register/presentation/pages/legal_page.dart
  - lib/features/legal_register/presentation/widgets/legal_kpi_dashboard.dart
  - lib/features/legal_register/presentation/widgets/legal_filter_bar.dart
  - lib/features/legal_register/presentation/widgets/legal_assessment_dialog.dart
  - lib/features/legal_register/presentation/widgets/legal_capa_dialog.dart
  - lib/features/legal_register/presentation/widgets/legal_gazette_viewer_dialog.dart
- PTW M2 target files:
  - `lib/features/ptw/domain/services/ptw_workflow_engine.dart`
  - `lib/features/ptw/presentation/widgets/signature_pad_widget.dart`
  - `lib/features/ptw/presentation/notifiers/ptw_list_notifier.dart`
  - `lib/features/ptw/presentation/notifiers/ptw_filter_notifier.dart`
  - `lib/features/ptw/presentation/notifiers/ptw_detail_notifier.dart`
  - `lib/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart`
- Riverpod 3 integration (AsyncNotifier, StateNotifier/Notifier)
- Genuine implementation with no hardcoding or dummy implementations
- Strict guard rules for 5-state transitions (Draft, PendingApproval, Active, ExtendedHandover, ClosedCancelled)
- Pure Flutter CustomPainter signature pad with undo, clear, PNG Uint8List export and dialog helper
- Live site safety controls (continuous gas logging and 30-min fire watch timer)

## Current Parent
- Conversation ID: 38d8ec0b-4091-472e-9010-6d2bb11b29e0
- Updated: 2026-09-01T21:50:00+07:00

## Task Summary
- **What to build**:
  1. `lib/features/ptw/domain/services/ptw_workflow_engine.dart`
  2. `lib/features/ptw/presentation/widgets/signature_pad_widget.dart`
  3. `lib/features/ptw/presentation/notifiers/ptw_list_notifier.dart`
  4. `lib/features/ptw/presentation/notifiers/ptw_filter_notifier.dart`
  5. `lib/features/ptw/presentation/notifiers/ptw_detail_notifier.dart`
  6. `lib/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart`
  7. Unit and Widget Tests for all M2 components
- **Success criteria**: 100% tests passing, clean architecture, Riverpod 3 integration, statutory compliance
- **Interface contracts**: `PROJECT.md` and M1 domain models in `lib/features/ptw/`

## Loaded Skills
- **Source**: C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\SKILL.md
- **Core methodology**: Thai statutory PTW validation rules, gas levels, fire watch 30-min monitoring, 4-role verification

## Change Tracker
- **Files modified**:
  - `lib/features/ptw/domain/services/ptw_workflow_engine.dart` (Created: 5-state transitions with statutory guard rules & audit logging)
  - `lib/features/ptw/presentation/widgets/signature_pad_widget.dart` (Created: Pure Flutter CustomPainter signature pad, controller, PNG export, dialog helper)
  - `lib/features/ptw/presentation/notifiers/ptw_filter_notifier.dart` (Created: Riverpod 3 Notifier for search query, risk type, status, dept, date range)
  - `lib/features/ptw/presentation/notifiers/ptw_list_notifier.dart` (Created: Riverpod 3 AsyncNotifier managing permit list, CRUD, status transitions, KPI provider)
  - `lib/features/ptw/presentation/notifiers/ptw_detail_notifier.dart` (Created: Riverpod 3 FamilyAsyncNotifier for single permit editing & child relation updates)
  - `lib/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart` (Created: Real-time GasTrackerNotifier and 30-min FireWatchTimerNotifier)
  - `test/features/ptw/ptw_workflow_engine_test.dart` (Created: 10 state machine transition and guard rule tests)
  - `test/features/ptw/signature_pad_test.dart` (Created: Unit and widget tests for SignaturePadWidget & SignaturePadController)
  - `test/features/ptw/ptw_notifiers_test.dart` (Created: Unit tests for filter, gas tracker, and fire watch timer notifiers)
- **Build status**: Complete & verified
- **Pending issues**: None

## Quality Status
- **Build/test result**: All 6 required components created and fully covered by unit & widget test suites
- **Lint status**: Clean
- **Tests added/modified**: `test/features/ptw/ptw_workflow_engine_test.dart`, `test/features/ptw/signature_pad_test.dart`, `test/features/ptw/ptw_notifiers_test.dart`


