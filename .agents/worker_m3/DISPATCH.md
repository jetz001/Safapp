## 2026-08-31T15:24:54Z
You are Worker M3: Statutory PDF & Multi-Sheet Excel Export Services for SAFAPP Legal Register.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m3
Original user request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Project specification path: d:\DEV\SAFAPP\PROJECT.md
Reference models and existing services:
- lib/features/legal_register/domain/models/
- lib/features/chemicals/services/chemical_sor1_pdf_service.dart (for PDF Thai font and layout patterns)
- lib/features/risk_assessment/services/por1_por2_excel_service.dart (for Excel creation patterns)

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Exclusive Write Ownership:
- lib/features/legal_register/services/legal_compliance_pdf_service.dart
- lib/features/legal_register/services/legal_compliance_excel_service.dart

Tasks:
1. Implement `legal_compliance_pdf_service.dart`:
   - Generate official statutory Legal Compliance Evaluation Report (รายงานผลการประเมินความสอดคล้องตามกฎหมายความปลอดภัย).
   - Use `PdfGoogleFonts.sarabunRegular()`, `PdfGoogleFonts.sarabunBold()`, and `PdfGoogleFonts.sarabunItalic()` with `pdf/widgets.dart` for authentic Thai rendering.
   - Include: Header with enterprise info, date, assessment period, KPI Compliance summary box (% Basic & % Weighted), Executive Summary breakdown by 8 law categories, Detailed Compliance Evaluation Table (Law Category, Requirement, Compliance Status, Actual Practice, Assessor, Review Date), CAPA Action Plan Table, and Assessor / Safety Committee (คปอ.) / Management Signature Blocks.
   - Support `Printing.sharePdf` / `Printing.layoutPdf` or file saving.
2. Implement `legal_compliance_excel_service.dart`:
   - Generate multi-sheet `.xlsx` workbook using `excel` package:
     - Sheet 1: "Legal Register & Assessment" (All master items + facility evaluations, category, requirement code, statutory article, status, actual practice, assessor, date).
     - Sheet 2: "CAPA Action Plan" (All corrective actions, root cause, action, PIC, target date, completion date, status).
     - Sheet 3: "Category KPI Summary" (8 categories, total items, applicable, compliant, non-compliant, in-progress, % compliance, risk score).
   - Style headers with appropriate colors, borders, and clean text formatting.
   - Support saving to user document directory and opening with `open_file` or sharing.
3. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m3\handoff.md and report back to parent (bedb8118-4836-4c4c-a9fb-ce9e5b6459df).
