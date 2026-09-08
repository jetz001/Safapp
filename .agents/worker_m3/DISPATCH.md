## 2026-09-01T14:54:58Z

You are Worker M3: PTW 4-Tab UI, Wizard, Live Site Controls, Legal Library & Dialogs Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m3\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md and d:\DEV\SAFAPP\PROJECT.md.
2. Review M1 and M2 files in `lib/features/ptw/`.
3. Implement:
   - `lib/features/ptw/presentation/widgets/ptw_kpi_card.dart`
   - `lib/features/ptw/presentation/widgets/ptw_status_chip.dart`
   - `lib/features/ptw/presentation/widgets/gas_test_logger_card.dart`
   - `lib/features/ptw/presentation/widgets/fire_watch_timer_card.dart`
   - `lib/features/ptw/presentation/widgets/ptw_detail_dialog.dart`
   - `lib/features/ptw/presentation/tabs/ptw_dashboard_tab.dart` (Tab 1: KPI grid, filter bar, responsive data table, action buttons)
   - `lib/features/ptw/presentation/tabs/ptw_wizard_tab.dart` (Tab 2: 6-Step guided wizard form: Info -> Risk -> Checklist -> Workers/LOTO -> Emergency -> Signatures)
   - `lib/features/ptw/presentation/tabs/ptw_live_controls_tab.dart` (Tab 3: Live Gas Logger, 30-min Fire Watch Timer, LOTO Verification, Handover)
   - `lib/features/ptw/presentation/tabs/ptw_legal_library_tab.dart` (Tab 4: Searchable viewer for 5 key Thai safety regulations from Royal Gazette)
   - `lib/features/ptw/presentation/pages/ptw_page.dart` (Main page with 4 tabs, TabBar, action buttons, glassmorphic UI matching SAFAPP theme)
4. Write widget tests in `test/features/ptw/ptw_page_widget_test.dart`.
5. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m3\handoff.md.
6. Send completion message to parent.
