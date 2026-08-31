## 2026-08-31T13:46:10Z

You are the Implementation Worker for Milestone 1 (Master Data & Schema) and Milestone 2 (Chemical Register, SDS Tracking & Tab 1/Tab 4 UI).

Working Directory: d:\DEV\SAFAPP\.agents\worker_m1_m2\
Project Workspace: d:\DEV\SAFAPP\
Read the original request at: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Read the project specification at: d:\DEV\SAFAPP\PROJECT.md
Read the survey handoffs at:
- d:\DEV\SAFAPP\.agents\explorer_safapp_codebase\handoff.md
- d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

File Ownership:
You exclusively own and will create/modify:
- lib/core/database/database_helper.dart (Update to Version 5 with tables for chemical_inventory, chemical_sds_sor1, chemical_measurement_sor3)
- lib/features/chemicals/data/datasources/chemical_1516_master_data.dart (Comprehensive 1,516 regulated chemicals with Thai, English, CAS No.)
- lib/features/chemicals/data/datasources/chemical_324_tlv_data.dart (Comprehensive 324 TLV standards with TWA, STEL, Ceiling, ppm, mg/m3)
- lib/features/chemicals/data/datasources/chemical_laws_data.dart (7 Thai Royal Gazette chemical safety laws and summaries)
- lib/features/chemicals/data/repositories/chemical_repository.dart (CRUD, queries, SQLite persistence, file storage for attachments)
- lib/features/chemicals/domain/models/chemical_master_model.dart
- lib/features/chemicals/domain/models/chemical_tlv_model.dart (with TLV evaluation engine)
- lib/features/chemicals/domain/models/chemical_inventory_model.dart (with SDS expiry calculation and status badges)
- lib/features/chemicals/domain/models/chemical_laws_model.dart
- lib/features/chemicals/presentation/providers/chemical_providers.dart (Riverpod providers for inventory, search, stats, filter)
- lib/features/chemicals/presentation/pages/chemicals_page.dart (Complete 4-Tab UI: Tab 1 ทะเบียนสารเคมี & SDS Tracking, Tab 2 สอ.๑ placeholder/card, Tab 3 สอ.๓ placeholder/card, Tab 4 คลังเอกสารกฎหมาย)
- lib/features/chemicals/presentation/widgets/chemical_inventory_form_dialog.dart (Add/Edit inventory with Autocomplete, quantity, storage location, dates, file picker)
- lib/features/chemicals/presentation/widgets/chemical_autocomplete_field.dart (Fast sub-50ms search by Thai, EN, or CAS)
- lib/features/chemicals/presentation/widgets/chemical_doc_viewer_dialog.dart (SfPdfViewer and Image viewer for attached SDS and certificates)
- lib/features/chemicals/presentation/widgets/ghs_pictogram_selector.dart (9 visual GHS pictograms)
- lib/features/chemicals/presentation/widgets/nfpa_diamond_widget.dart (4-color NFPA 704 standard diamond)
