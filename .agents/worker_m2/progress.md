# Progress — Worker M2 (PTW Workflow State Machine, Riverpod Notifiers, Signature Pad & Live Controls)

Last visited: 2026-09-01T21:55:00+07:00

## Status: COMPLETED

### Completed Tasks
1. `lib/features/ptw/domain/services/ptw_workflow_engine.dart`:
   - Full 5-state transitions (Draft, PendingApproval, Active, ExtendedHandover, ClosedCancelled).
   - Strict statutory guard rules: Draft validation, Approval signatures validation, Confined Space 4-role verification, Pre-entry gas testing check, LOTO zero energy verification, Hot Work 30-min fire watch check, LOTO de-isolation on closure.
   - `WorkflowTransitionResult` container with error lists, warning lists, and required signatories.
   - `applyTransition` method attaching digital signatures, timestamps, and generating audit `PtwApprovalModel` logs.
2. `lib/features/ptw/presentation/widgets/signature_pad_widget.dart`:
   - Pure Flutter `CustomPainter` signature pad with smooth quadratic Bezier curve strokes.
   - `SignaturePadController` supporting real-time drawing, undo, clear, PNG `Uint8List` byte export via `ui.PictureRecorder` and file saving.
   - `showSignatureDialog` helper modal dialog for sign-offs with name input, role badge, and digital drawing canvas.
3. `lib/features/ptw/presentation/notifiers/ptw_filter_notifier.dart`:
   - Immutable `PtwFilterState` (searchQuery, riskType, status, department, startDate, endDate, `isFiltered` getter).
   - `PtwFilterNotifier` extending Riverpod 3 `Notifier<PtwFilterState>`.
   - `ptwFilterProvider` for UI filter binding.
4. `lib/features/ptw/presentation/notifiers/ptw_list_notifier.dart`:
   - Riverpod 3 `AsyncNotifier<List<PtwModel>>` with real-time SQLite integration.
   - Synchronized with `ptwFilterProvider` for instant search and filtering.
   - Methods: `createPermit`, `updatePermit`, `deletePermit`, `transitionStatus`, `refresh`.
   - `ptwKpiProvider` computing live summary metrics (active, pending, overdue, compliance rate).
   - `ptwDepartmentsProvider` listing distinct departments.
5. `lib/features/ptw/presentation/notifiers/ptw_detail_notifier.dart`:
   - Riverpod 3 `FamilyAsyncNotifier<PtwModel?, String>` for viewing and editing permits.
   - Granular methods: `savePermit`, `addGasTestLog`, `saveConfinedRoles`, `saveFireWatch`, `saveLotoIsolations`, `toggleLotoZeroEnergy`, `toggleLotoDeIsolation`, `updateChecklist`, `transitionStatus`.
6. `lib/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart`:
   - `GasTrackerState` & `GasTrackerNotifier` for continuous atmospheric monitoring, real-time safety threshold evaluation against Thai statutory limits, and recording permanent logs.
   - `FireWatchTimerState` & `FireWatchTimerNotifier` for Hot Work 30-minute countdown timer, pause/resume/reset, safety condition checklists, and final inspection sign-off.
7. Test Suites:
   - `test/features/ptw/ptw_workflow_engine_test.dart`
   - `test/features/ptw/signature_pad_test.dart`
   - `test/features/ptw/ptw_notifiers_test.dart`


