# BRIEFING — 2026-09-01T15:00:00Z

## Mission
Implement Worker M3: PTW 4-Tab UI, 6-Step Wizard, Live Site Controls, Legal Library, Dialogs & Widgets for SAFAPP.

## 🔒 My Identity
- Archetype: Worker M3
- Roles: implementer, qa, specialist
- Working directory: d:\DEV\SAFAPP\.agents\worker_m3\
- Original parent: 38d8ec0b-4091-472e-9010-6d2bb11b29e0
- Milestone: M3 (PTW 4-Tab UI & Live Controls)

## 🔒 Key Constraints
- High-risk PTW module covering 5 core risk types under Thai OSH Legislation.
- 4 Tabs in PtwPage: Dashboard & Register, 6-Step Wizard, Live Site Controls, Legal Reference Library.
- High-fidelity glassmorphic UI matching SAFAPP theme and design patterns.
- Pure Flutter components with Riverpod 3, SQLite v8 repository, and Digital Signature Canvas.
- Genuine implementation with no hardcoded test shortcuts. Full test pass rate.

## Current Parent
- Conversation ID: 38d8ec0b-4091-472e-9010-6d2bb11b29e0
- Updated: 2026-09-01T15:00:00Z

## Task Summary
- **What to build**:
  - `lib/features/ptw/presentation/widgets/ptw_kpi_card.dart`
  - `lib/features/ptw/presentation/widgets/ptw_status_chip.dart`
  - `lib/features/ptw/presentation/widgets/gas_test_logger_card.dart`
  - `lib/features/ptw/presentation/widgets/fire_watch_timer_card.dart`
  - `lib/features/ptw/presentation/widgets/ptw_detail_dialog.dart`
  - `lib/features/ptw/presentation/tabs/ptw_dashboard_tab.dart` (Tab 1)
  - `lib/features/ptw/presentation/tabs/ptw_wizard_tab.dart` (Tab 2)
  - `lib/features/ptw/presentation/tabs/ptw_live_controls_tab.dart` (Tab 3)
  - `lib/features/ptw/presentation/tabs/ptw_legal_library_tab.dart` (Tab 4)
  - `lib/features/ptw/presentation/pages/ptw_page.dart` (Main page with 4 tabs)
  - `test/features/ptw/ptw_page_widget_test.dart` (Widget test suite)
- **Success criteria**: All widgets and tabs render properly, interactive flows work, unit & widget tests pass 100%.

## Change Tracker
- **Files modified**: Initializing M3 components
- **Build status**: Ready to implement
- **Pending issues**: None

## Quality Status
- **Build/test result**: In progress
- **Lint status**: 0 violations
- **Tests added/modified**: `test/features/ptw/ptw_page_widget_test.dart`

## Loaded Skills
- **Source**: C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\SKILL.md
- **Core methodology**: Thai PTW statutory rules, Confined Space 4 roles & gas testing limits, Hot work 30m fire watch, LOTO zero-energy verification.
