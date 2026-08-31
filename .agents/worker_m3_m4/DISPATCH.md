## 2026-08-31T20:53:50Z

You are the Implementation Worker for Milestone 3 (Form สอ.๑ - SDS 16 Sections & PDF) and Milestone 4 (Form สอ.๓ ๒๕๖๕ - Atmospheric Measurement & PDF).

Working Directory: d:\DEV\SAFAPP\.agents\worker_m3_m4\
Project Workspace: d:\DEV\SAFAPP\
Read the original request at: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Read the project specification at: d:\DEV\SAFAPP\PROJECT.md
Read the survey handoffs and M1/M2 handoff at:
- d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\handoff.md
- d:\DEV\SAFAPP\.agents\worker_m1_m2\handoff.md

File Ownership:
You exclusively own and will create/modify:
- lib/features/chemicals/domain/models/chemical_sds_sor1_model.dart (Complete 16 GHS sections model, serialization, NFPA, pictograms)
- lib/features/chemicals/domain/models/chemical_measurement_sor3_model.dart (สอ.๓ model, Section 9/11 registration, sampling points, TLV auto-evaluation, serialization)
- lib/features/chemicals/data/repositories/chemical_repository.dart (Add methods for สอ.๑ and สอ.๓ CRUD operations in SQLite)
- lib/features/chemicals/presentation/providers/chemical_providers.dart (Add providers for สอ.๑ and สอ.๓ lists, filters, actions)
- lib/features/chemicals/presentation/widgets/sds_sor1_editor_dialog.dart (Multi-section / tabbed editor for entering all 16 GHS sections)
- lib/features/chemicals/presentation/widgets/sds_sor3_measurement_dialog.dart (Form for recording workplace air monitoring, Section 9/11 certs, sampling points with automatic TLV comparison and Pass/Fail evaluation)
- lib/features/chemicals/services/chemical_sor1_pdf_service.dart (Statutory Form สอ.๑ PDF generator using pdf, printing, and Sarabun font)
- lib/features/chemicals/services/chemical_sor3_pdf_service.dart (Statutory Form สอ.๓ ๒๕๖๕ PDF generator using pdf, printing, and Sarabun font)
- lib/features/chemicals/presentation/pages/chemicals_page.dart (Upgrade Tab 2 and Tab 3 with live data lists, filter bars, action buttons, view details, and PDF export buttons)
- test/chemical_management_test.dart (Add unit tests verifying สอ.๑ serialization, สอ.๓ sampling points & TLV matching, and PDF service generation)
