# BRIEFING — 2026-08-31T20:59:15+07:00

## Mission
Implement Milestone 3 (Form สอ.๑ - SDS 16 Sections & PDF Export) and Milestone 4 (Form สอ.๓ ๒๕๖๕ - Atmospheric Measurement & PDF Export), including models, SQLite CRUD, UI editors/dialogs, PDF services with Sarabun font and Printing layout, and Tab 2 / Tab 3 UI upgrades in SAFAPP.

## 🔒 My Identity
- Archetype: Implementation Worker
- Roles: implementer, qa, specialist
- Working directory: d:\DEV\SAFAPP\.agents\worker_m3_m4\
- Original parent: 24f757fa-f31c-43d6-9b79-a6bad51e1b38
- Milestone: M3 (Form สอ.๑) & M4 (Form สอ.๓ ๒๕๖๕)

## 🔒 Key Constraints
- Pure genuine logic: NO hardcoded test results, NO dummy/facade implementations.
- Complete 16 GHS headings for Form สอ.๑ conforming to DLPW Notification B.E. 2556.
- Form สอ.๓ compliant with Revised Notification B.E. 2565 (Sections 1 to 6, Section 9/11 certs, sampling points with automatic TLV evaluation against 324 standard limits).
- Official PDF generators for both forms using `pdf`, `printing`, `pdf/widgets`, and Thai font fallback / Sarabun font.
- Comprehensive unit tests in `test/chemical_management_test.dart`.

## Current Parent
- Conversation ID: 24f757fa-f31c-43d6-9b79-a6bad51e1b38
- Updated: 2026-08-31T20:59:15+07:00

## Task Summary
- **What to build**:
  1. `ChemicalSdsSor1Model` & `ChemicalMeasurementSor3Model` (+ Sampling Points model).
  2. SQLite CRUD methods in `ChemicalRepository` for `chemical_sds_sor1` and `chemical_measurement_sor3`.
  3. Riverpod AsyncNotifiers & providers in `chemical_providers.dart`.
  4. `SdsSor1EditorDialog` (tabbed 16 GHS sections, ingredient list, GHS pictograms, NFPA diamond).
  5. `SdsSor3MeasurementDialog` (survey details, Section 9/11 surveyor info, sampling point rows with instant TLV lookup and Pass/Fail evaluation).
  6. `ChemicalSor1PdfService` (Statutory Form สอ.๑ PDF generator).
  7. `ChemicalSor3PdfService` (Statutory Form สอ.๓ ๒๕๖๕ PDF generator).
  8. Upgrade `ChemicalsPage` Tab 2 & Tab 3 with live data lists, filters, action bars, detail cards, and PDF export buttons.
  9. Add test suites to `test/chemical_management_test.dart`.

## Key Decisions Made
- Implemented comprehensive 16 GHS sections in `ChemicalSdsSor1Model` and nested JSON serialization for ingredients, first aid, firefighting, spill cleanup, exposure limits, physical properties, toxicology, and transport info.
- Implemented `ChemicalMeasurementSor3Model` with full support for Section 9 (Juridical Entity) and Section 11 (Individual) certifications per OSH Act B.E. 2554 and Revised Notification B.E. 2565.
- Implemented statutory PDF generators using `PdfGoogleFonts.sarabunRegular()`, `PdfGoogleFonts.sarabunBold()`, and `Printing.layoutPdf()`.
- Upgraded `ChemicalsPage` Tab 2 and Tab 3 with live database-driven cards, filtering, dialog editors, and instant PDF generation.

## Artifact Index
- `lib/features/chemicals/domain/models/chemical_sds_sor1_model.dart`
- `lib/features/chemicals/domain/models/chemical_measurement_sor3_model.dart`
- `lib/features/chemicals/data/repositories/chemical_repository.dart`
- `lib/features/chemicals/presentation/providers/chemical_providers.dart`
- `lib/features/chemicals/presentation/widgets/sds_sor1_editor_dialog.dart`
- `lib/features/chemicals/presentation/widgets/sds_sor3_measurement_dialog.dart`
- `lib/features/chemicals/services/chemical_sor1_pdf_service.dart`
- `lib/features/chemicals/services/chemical_sor3_pdf_service.dart`
- `lib/features/chemicals/presentation/pages/chemicals_page.dart`
- `test/chemical_management_test.dart`
