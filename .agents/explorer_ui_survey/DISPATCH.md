## 2026-09-01T21:35:36+07:00
You are Explorer 2: UI, Navigation, Export & Test Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\explorer_ui_survey\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md thoroughly.
2. Investigate the existing SAFAPP codebase in d:\DEV\SAFAPP to identify:
   - Navigation and routing structure, sidebar / bottom bar / app bar integration for PtwPage.
   - UI component library, design system, theme colors, typography, cards, tables, wizard forms.
   - Dependencies in pubspec.yaml: signature pad widgets, pdf, printing, qr_flutter, excel, path_provider, etc. Note any missing or existing packages.
   - Test framework in test/ folder, mock data patterns, test utilities.
   - UI Architecture for PtwPage with 4 tabs:
     * Tab 1: PTW Dashboard & Register (KPI cards, filterable data table, status badges, action buttons)
     * Tab 2: Create / Edit Wizard (Step-by-step form: General Info -> Risk Selection -> Safety Checklist -> Workers & LOTO -> Emergency Plan -> Signatures)
     * Tab 3: Live Site Safety Controls (Real-time Gas Test Logger, 30-min Fire Watch Countdown Timer, LOTO Verification, Handover Sign-off)
     * Tab 4: Legal Reference Library (Viewer for 5 key Thai safety ministerial regulations + PDF preview)
   - PDF & Excel export implementation strategy for official government format with QR code.
3. Write your detailed analysis to d:\DEV\SAFAPP\.agents\explorer_ui_survey\analysis.md.
4. Write your self-contained handoff to d:\DEV\SAFAPP\.agents\explorer_ui_survey\handoff.md following the Handoff Protocol.
5. Send a completion message back to parent.
