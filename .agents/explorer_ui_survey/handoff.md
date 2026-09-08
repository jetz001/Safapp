# Handoff Report: UI, Navigation, Export & Test Survey for Permit to Work (PTW)

**Author**: Explorer 2: UI, Navigation, Export & Test Specialist  
**Working Directory**: `d:\DEV\SAFAPP\.agents\explorer_ui_survey\`  
**Target Module**: Permit to Work (`PtwPage` in `lib/features/ptw/`)  
**Date**: 2026-09-01T21:40:00Z  
**Type**: Hard Handoff (Investigation & Architecture Survey Complete)

---

## 1. Observation

1. **Routing & Sidebar Registration**:
   - In `lib/core/widgets/app_shell.dart:53`, destination index 5 maps to `const PtwPage()`.
   - In `lib/core/widgets/app_shell.dart:144`, sidebar destination `Icons.assignment_turned_in_outlined` (unselected) / `Icons.assignment_turned_in` (selected) has label `'PTW'`.
   - In `lib/features/ptw/presentation/pages/ptw_page.dart:1-33`, the current page is a placeholder with a simple AppBar and Text widget.

2. **UI Design System & Theming**:
   - `lib/main.dart:19-28` sets `ThemeData` with `seedColor: const Color(0xFF1E3A8A)` (Navy Blue), `useMaterial3: true`, and `GoogleFonts.promptTextTheme`.
   - `lib/core/widgets/glass_container.dart` is used for glassmorphic styling (blur 30, opacity 0.4).
   - Other feature modules (`features/environment`, `features/chemicals`, `features/legal_register`) follow a 3-tab or 4-tab interactive architecture with KPI cards, filter bars, responsive data tables, step-by-step dialogs/wizards, and official PDF/Excel exporters.

3. **Pubspec Dependencies**:
   - `pubspec.yaml:30-49` contains:
     - `flutter_riverpod: ^3.3.2`
     - `sqflite_common_ffi: ^2.4.0+3`
     - `sqlite3_flutter_libs: ^0.6.0+eol`
     - `path: ^1.9.1` & `path_provider: ^2.1.6`
     - `excel: ^4.0.6`
     - `file_picker: ^11.0.3`
     - `syncfusion_flutter_pdfviewer: ^33.2.13`
     - `google_fonts: ^8.2.1`
     - `fl_chart: ^1.2.0`
     - `pdf: ^3.12.0`
     - `printing: ^5.14.3`
   - Digital signatures can be implemented via pure Flutter `CustomPainter` + `PictureRecorder` -> PNG bytes (`Uint8List`) without third-party package dependencies.
   - QR Code is supported directly in `pdf` via `pw.BarcodeWidget(barcode: pw.Barcode.qrCode())` for PDFs and `Barcode.qrCode()` / pure canvas painter on Flutter UI screens.

4. **Database & Migrations**:
   - `lib/core/database/database_helper.dart:43` currently runs version 7 (`version: 7`).
   - PTW module requires migration to database version 8 (`version: 8`) with tables: `ptw_requests`, `ptw_checklists`, `ptw_gas_test_logs`, `ptw_confined_roles`, `ptw_loto_isolations`, `ptw_fire_watch_logs`, and `ptw_approval_logs`.

5. **Test Framework & Utilities**:
   - `test/` directory contains 12 existing test suites (`test/features/environment/`, `test/chemical_management_test.dart`, `test/legal_register_ui_test.dart`).
   - Riverpod provider overriding pattern (`ProviderScope(overrides: [provider.overrideWith(...)])`) and widget tester pump/settle are established across all UI tests.

---

## 2. Logic Chain

1. **From Observation 1 (Routing)**: `PtwPage` is already positioned at index 5 of `AppShell`. Developing `PtwPage` with 4 statutory tabs directly populates the existing navigation slot without breaking sidebar routing or deep links.
2. **From Observation 2 (Design System)**: Reusing `GoogleFonts.prompt()`, primary Navy `#1E3A8A`, Glassmorphism, and standard status chip styling ensures seamless UI consistency with the rest of SAFAPP.
3. **From Observation 3 (Pubspec & Zero-Dependency Components)**:
   - For Digital Signatures: A custom `SignaturePadWidget` using Flutter `CustomPainter` provides instant touch/mouse pen tracking, undo/clear, and PNG byte export with zero external dependency risk.
   - For QR Codes: In PDF, `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), ...)` generates standard vector QR codes. On UI screens, a canvas matrix renderer draws the QR code cleanly for mobile inspection.
   - For PDF/Excel: `pdf`/`printing` and `excel` packages are fully capable of generating official DLPW-compliant PDF certificates and 5-sheet `.xlsx` summary workbooks.
4. **From Observation 4 (Database Migration)**: Bumping SQLite version from 7 to 8 in `database_helper.dart` with dedicated PTW tables guarantees structured persistence for all 5 high-risk types, gas logs, 4-party roles, and LOTO tags.
5. **From Observation 5 (Test Infrastructure)**: Structuring unit tests in `test/features/ptw/` using established Riverpod mock notifiers and boundary test cases will provide 100% test coverage and ensure continuous pass rates.

---

## 3. Caveats

1. **Hardware / Bluetooth Gas Detectors**: The live gas logger is designed for manual input and simulated sensor logging. Direct Bluetooth Low Energy (BLE) hardware gas sensor integration is out of scope for this milestone.
2. **Mobile Camera QR Scanner**: The system provides on-screen QR code display and official PDF printout with QR code for mobile inspection. Embedded in-app camera barcode scanning can be hooked into standard camera plugins if requested later.
3. **No other caveats.**

---

## 4. Conclusion

The UI, navigation, dependency, and testing architecture for `PtwPage` is fully designed and ready for implementation. The proposed solution delivers:
- **Navigation**: Integrated at `AppShell` index 5 with instant sidebar switching.
- **4 Statutory Interactive Tabs**:
  * Tab 1: PTW Dashboard & Register (KPI cards, filterable register, status badges, action buttons)
  * Tab 2: Create / Edit PTW Wizard (6-step guided form: General Info -> Risk Selection -> Safety Checklist -> Workers & LOTO -> Emergency Plan -> 4-Party Signatures)
  * Tab 3: Live Site Safety Controls (Real-time Gas Test Logger, 30-min Fire Watch Countdown Timer, LOTO Verification, Handover Sign-off)
  * Tab 4: Legal Reference Library (Searchable repository for 5 key Thai safety ministerial regulations + DLPW Notifications + PDF preview)
- **Digital Signatures & QR Code**: Zero-dependency pure Flutter `SignaturePadWidget` and high-resolution embedded QR codes.
- **Export Services**: Official DLPW A4 PDF certificate generator and 5-sheet `.xlsx` summary exporter.
- **Test Suite**: Comprehensive unit, widget, and adversarial tests under `test/features/ptw/`.

---

## 5. Verification Method

1. **Inspect Analysis Report**:
   - Read `d:\DEV\SAFAPP\.agents\explorer_ui_survey\analysis.md` for full component specifications, color palettes, step definitions, and exporter blueprints.
2. **Inspect Codebase References**:
   - View `lib/core/widgets/app_shell.dart:53` and line 144 to confirm navigation index 5.
   - View `lib/features/environment/presentation/pages/environment_page.dart` for tab controller and export action pattern.
   - View `lib/features/environment/services/environment_pdf_exporter.dart` and `environment_excel_exporter.dart` for export implementation models.
   - View `test/features/environment/environment_page_widget_test.dart` for Riverpod test mocking conventions.
3. **Invalidation Conditions**:
   - If `AppShell` changes navigation index 5 or removes `NavigationRail`.
   - If Thai ministerial regulations alter statutory gas thresholds ($O_2 \notin [19.5, 23.5]$, $LEL \ge 10\%$, $CO \ge 25\text{ ppm}$, $H_2S \ge 10\text{ ppm}$) or Hot Work fire watch duration ($< 30\text{ min}$).
