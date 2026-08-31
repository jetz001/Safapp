# Progress — Worker M2 (Legal UI)

Last visited: 2026-08-31T22:30:00+07:00

## Status: COMPLETED

### Completed Tasks
1. `lib/features/legal_register/presentation/widgets/legal_kpi_dashboard.dart`:
   - % Basic Compliance (CI %) & % Risk-Weighted Compliance (WCI %)
   - PieChart radial gauges, status metric count chips (Compliant, Non-Compliant, In-Progress, N/A, Open CAPA, Overdue CAPA)
   - High-Risk Non-Compliance alert banner
   - 8 Thai statutory categories breakdown grid with progress bars and interactive category filter selection.
2. `lib/features/legal_register/presentation/widgets/legal_filter_bar.dart`:
   - Keyword search textfield with clear button
   - 8 Category filter chips (All + 8 Thai Royal Gazette regulations)
   - Compliance status and CAPA status dropdown selectors
   - Native PDF export with `pdf` and `printing` (Sarabun font, KPI summary, full table)
   - Formatted Excel .xlsx export with `excel` (Assessments sheet + CAPA Action Plans sheet)
   - Reset filters button.
3. `lib/features/legal_register/presentation/widgets/legal_assessment_dialog.dart`:
   - Interactive compliance status selector (Compliant, Non-Compliant, In-Progress, Not Applicable)
   - Applicability switch
   - Actual practice notes input
   - Evaluator metadata (Name, Role, Department)
   - Evaluated date and Next review date pickers
   - Multi-file evidence picker using `file_picker` (PDF, images, certificates)
   - Quick-create CAPA trigger button when status is Non-Compliant or In-Progress
   - Riverpod persistence via `legalAssessmentListProvider.notifier.saveAssessment(...)`.
4. `lib/features/legal_register/presentation/widgets/legal_capa_dialog.dart`:
   - Linked legal assessment selector / pre-filled context
   - Action title, Root cause analysis (5-Whys), Corrective action, Preventive action
   - PIC name and department
   - Target completion date and completed date pickers
   - Status selector (Pending, In Progress, Completed)
   - Evidence file attachment picker
   - Closure verification notes
   - Riverpod persistence via `legalCapaListProvider.notifier.saveCapa(...)`.
5. `lib/features/legal_register/presentation/widgets/legal_gazette_viewer_dialog.dart`:
   - Royal Gazette publication citation (เล่ม/ตอน/หน้า/ประกาศวันที่/บังคับใช้วันที่)
   - Article number, statutory description, applicability criteria, compliance criteria
   - Evidence type and official government form name (สอ.๑, สปร.๕, etc.)
   - Statutory penalty clauses with high-visibility warning box
   - Dual tabs: Full details and Royal Gazette document paper layout simulation / PDF viewer
   - Print provision button using `Printing.layoutPdf`
   - One-tap "ประเมินความสอดคล้องข้อนี้" button.
6. `lib/features/legal_register/presentation/pages/legal_page.dart`:
   - 3 Full interactive tabs:
     - Tab 1: "ทะเบียนและการประเมินความสอดคล้อง" (Legal Register & Compliance Assessment)
     - Tab 2: "คลังกฎหมายราชกิจจานุเบกษา" (Royal Gazette Legal Repository - 8 Regulations & 32 Items)
     - Tab 3: "แผนการปรับปรุงแก้ไข (CAPA)" (CAPA Action Plan Tracker)
   - Floating action button to open new CAPA
   - Empty state handling with filter reset and seed defaults options
   - Modern SAFAPP theme (teal `#0D9488`, navy `#0F172A`, slate `#1E293B`, rounded cards, clean typography).
7. `test/legal_register_ui_test.dart`:
   - 6 test groups verifying all widgets, dialogs, tab switching, and Riverpod provider interactions.
