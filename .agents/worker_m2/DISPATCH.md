## 2026-08-31T15:24:54Z
You are Worker M2: SAFAPP Flutter UI (LegalPage, 3 Tabs, KPI Dashboard, Assessment Dialogs, CAPA Action Plan, Gazette Library).
...

## 2026-09-01T14:48:52Z
You are Worker M2: PTW Workflow State Machine, Riverpod State Notifiers, Signature Pad & Live Controllers Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m2\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md, d:\DEV\SAFAPP\PROJECT.md, and inspect M1 files in `lib/features/ptw/`.
2. Implement:
   - `lib/features/ptw/domain/services/ptw_workflow_engine.dart`: 5-state transitions (Draft, PendingApproval, Active, ExtendedHandover, ClosedCancelled) with strict guard rules.
   - `lib/features/ptw/presentation/widgets/signature_pad_widget.dart`: Pure Flutter `CustomPainter` signature pad with clear, undo, and PNG `Uint8List` export, plus a signature dialog helper.
   - `lib/features/ptw/presentation/notifiers/ptw_list_notifier.dart`: Riverpod 3 `AsyncNotifier` managing list, creation, status transitions, deletes, and auto-refresh.
   - `lib/features/ptw/presentation/notifiers/ptw_filter_notifier.dart`: Filter state notifier for search, risk type, status, and date range.
   - `lib/features/ptw/presentation/notifiers/ptw_detail_notifier.dart`: Detail state notifier for viewing and editing a single permit.
   - `lib/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart`: Real-time state management for continuous gas logging and 30-minute fire watch countdown timer with alert status.
3. Verify your implementation by running Flutter tests on the new services and notifiers.
4. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m2\handoff.md.
5. Send completion message to parent.
