# PTW Module UI, Navigation, Export & Test Architecture Analysis Report

**Target Project**: SAFAPP (Safety Superapp) — `d:\DEV\SAFAPP`  
**Investigator**: Explorer 2: UI, Navigation, Export & Test Specialist  
**Timestamp**: 2026-09-01T21:40:00Z  
**Scope**: User Interface, App Shell Navigation, Reusable Component Library, Pubspec Dependencies, Testing Infrastructure, 4-Tab `PtwPage` Architecture, Digital Signature Pad, On-screen & PDF QR Code, Official DLPW PDF Exporter, and Multi-Sheet Excel Exporter.

---

## 1. Executive Summary

This investigation surveys the Flutter UI framework, theme design system, navigation routes, dependency packages, test infrastructure, and export subsystems of SAFAPP to design the **Permit to Work (PTW) Module** (`PtwPage`).

The PTW module will be seamlessly integrated into `AppShell` at navigation index 5 (`Icons.assignment_turned_in`), conforming 100% to Thai statutory requirements:
1. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔** (ม.๘, ม.๑๔, ม.๑๖, ม.๒๒, ม.๒๓, ม.๓๒)
2. **กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัยฯ ในสถานที่อับอากาศ พ.ศ. ๒๕๖๒** (เกณฑ์ O2 19.5-23.5%, LEL <10%, CO <25 ppm, H2S <10 ppm, ทะเบียนผู้มีหน้าที่ 4 ฝ่าย, แผนฉุกเฉินและกู้ภัย)
3. **กฎกระทรวง การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕** (Hot Work, ผู้เฝ้าระวังไฟ Fire Watcher, การตรวจสอบความปลอดภัยหลังเลิกงานไม่น้อยกว่า 30 นาที)
4. **กฎกระทรวง ความปลอดภัยเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘** (Lockout/Tagout - LOTO, ตรวจสอบพลังงานตกค้าง Zero Energy Verification)
5. **กฎกระทรวง นั่งร้าน งานบนที่สูง และงานดินขุด พ.ศ. ๒๕๖๔** (งานสูงเกิน 2 ม., Full Body Harness, ขุดดินลึกเกิน 1.5 ม.)
6. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบหนังสืออนุญาตให้ลูกจ้างทำงานในที่อับอากาศ**

---

## 2. Codebase Architecture & Navigation Integration

### 2.1 Navigation & Routing Structure
- **Root Entry Point**: `lib/main.dart` wraps the application in `ProviderScope` and launches `AppShell` with Google Fonts `Prompt`.
- **App Shell Navigation**: `lib/core/widgets/app_shell.dart` hosts a glassmorphic sidebar (`GlassContainer` + `NavigationRail`) with 17 registered destinations:
  ```dart
  // app_shell.dart (Index 5)
  NavigationRailDestination(
    icon: Icon(Icons.assignment_turned_in_outlined),
    selectedIcon: Icon(Icons.assignment_turned_in),
    label: Text('PTW'),
  )
  ```
- **Page Registration**: `_pages[5]` maps directly to `const PtwPage()`.
- **Cross-module Deep Linking**: `LandingPage` (Index 0) supports rapid routing via `onNavigate(5)` directly into `PtwPage`.

### 2.2 Design System & Visual Language
- **Seed & Primary Palette**:
  - `Primary Navy`: `#1E3A8A` (AppBar, active buttons, table headers)
  - `Dark Slate Background`: `#0F172A` / `#1E293B`
  - `Light Canvas Background`: `#F8FAFC` / `#F1F5F9`
  - `Glass Effect`: `GlassContainer` with blur radius 30, opacity 0.4, border radius 24.
- **PTW Status Badge Palette**:
  | Status | Background | Text/Border | Meaning & Usage |
  |--------|------------|-------------|-----------------|
  | `DRAFT` | `#F1F5F9` | `#475569` | ร่างคำขอโดยผู้ขอใบอนุญาต |
  | `PENDING_APPROVAL` | `#FEF3C7` | `#D97706` | ส่งคำขอ รอตรวจสอบ JSA และอนุมัติ |
  | `ACTIVE` | `#DCFCE7` | `#16A34A` | เปิดงานแล้ว มีผลบังคับใช้ตามช่วงเวลา |
  | `EXTENDED_HANDOVER` | `#DBEAFE` | `#2563EB` | ส่งมอบพื้นที่ / ต่อเวลาทำงาน |
  | `CLOSED` | `#E2E8F0` | `#334155` | ปิดงานสมบูรณ์ เคลียร์พื้นที่เรียบร้อย |
  | `CANCELLED` / `OVERDUE` | `#FEE2E2` | `#DC2626` | ยกเลิกคำขอ / เกินกำหนดเวลาทำงาน |

- **High-Risk PTW Type Palette**:
  | Risk Type | Color Theme | Icon | Key Safety Regulations |
  |-----------|-------------|------|------------------------|
  | **Hot Work** | Orange `#EA580C` | `Icons.local_fire_department_rounded` | กฎกระทรวงอัคคีภัย ๒๕๕๕ (Fire Watch 30 นาที) |
  | **Confined Space** | Purple `#7C3AED` | `Icons.sensor_door_rounded` | กฎกระทรวงที่อับอากาศ ๒๕๖๒ (Gas Testing & 4 ฝ่าย) |
  | **Working at Height** | Sky Blue `#0284C7` | `Icons.height_rounded` | กฎกระทรวงงานบนที่สูง ๒๕๖๔ (> 2 เมตร, Lifeline) |
  | **Electrical & LOTO** | Rose `#E11D48` | `Icons.electrical_services_rounded` | กฎกระทรวงไฟฟ้า ๒๕๕๘ (Lockout/Tagout, Zero Energy) |
  | **Excavation & Lifting** | Amber/Teal `#0D9488` | `Icons.agriculture_rounded` | กฎกระทรวงงานดินขุด ๒๕๖๔ (> 1.5 เมตร, ปั้นจั่น) |

- **Typography**: `GoogleFonts.prompt()` text hierarchy across all titles, sub-headers, KPI counters, and tables.

---

## 3. Dependency Inventory & Package Strategy

### 3.1 Pubspec.yaml Existing Packages
| Package | Version | PTW Utilization |
|---------|---------|-----------------|
| `flutter_riverpod` | `^3.3.2` | State management for PTW list, active permit, countdown timers, gas logs |
| `sqflite_common_ffi` | `^2.4.0+3` | Local database storage on Windows/Desktop |
| `sqlite3_flutter_libs` | `^0.6.0+eol` | Desktop SQLite native C binaries |
| `pdf` | `^3.12.0` | Official DLPW PDF generation + built-in `pw.BarcodeWidget(barcode: pw.Barcode.qrCode())` |
| `printing` | `^5.14.3` | `PdfGoogleFonts.sarabunRegular()`, `sarabunBold()`, `sarabunItalic()` + print/preview |
| `excel` | `^4.0.6` | Multi-sheet `.xlsx` summary and detailed register export |
| `syncfusion_flutter_pdfviewer` | `^33.2.13` | Legal Reference Library (Tab 4) PDF gazette viewer |
| `path_provider` & `path` | `^2.1.6`, `^1.9.1` | Local file management in `ApplicationDocuments/SafetySuperapp/exports` |
| `fl_chart` | `^1.2.0` | KPI analytics, gas trend graphs, permit distribution charts |
| `google_fonts` | `^8.2.1` | Thai Prompt typography |

### 3.2 Signature Pad & QR Code Strategy (Zero Dependency / Pure Flutter)
1. **Digital Signature Pad**:
   - Implemented natively via `CustomPainter` with smooth cubic bezier curve interpolation, pointer gesture tracking, stroke width adjustment, clear/undo functions, and `PictureRecorder.endRecording().toImage()` exporting directly to PNG bytes (`Uint8List`).
   - **Advantage**: 100% platform compatible (Windows desktop, macOS, Linux, Web, Android, iOS), zero third-party dependency conflicts, sub-millisecond responsiveness.
2. **QR Code Generation**:
   - **In Official PDF**: Uses `pdf` package's native `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: payload)` - built directly into `pdf/widgets.dart`.
   - **On Flutter UI Screen**: Uses a pure Flutter `QrCodePainter` (or barcode canvas renderer using `pdf`'s `Barcode.qrCode().draw()`) allowing site workers to scan with smartphones and inspect active permit validity in real-time.

---

## 4. Detailed UI Architecture for `PtwPage` (4 Statutory Tabs)

```
PtwPage (Scaffold + PreferredSize TabBar)
 ├── AppBar: Title, Filter Dropdowns, Export PDF/Excel, "+ ขอใบอนุญาต (Create PTW)"
 └── TabBarView (4 Tabs)
      ├── Tab 1: PTW Dashboard & Register (PtwDashboardTab)
      │    ├── KPI Metric Cards (Total, Active, Pending, Overdue, Closed)
      │    ├── Quick Filter Bar (Search, Status Chip, Risk Type, Date Range)
      │    └── Filterable Data Table / Responsive Card Register
      │
      ├── Tab 2: Create / Edit PTW Wizard (PtwWizardTab / Wizard Dialog)
      │    ├── Step 1: ข้อมูลทั่วไปและพื้นที่ปฏิบัติงาน (General Info)
      │    ├── Step 2: เลือกประเภทความเสี่ยงสูง (High-Risk Categories 1-5)
      │    ├── Step 3: รายการตรวจสอบความปลอดภัย (Statutory Safety Checklist)
      │    ├── Step 4: ผู้ปฏิบัติงาน ทะเบียน 4 ฝ่าย และ LOTO (Workers, 4-Roles, LOTO)
      │    ├── Step 5: แผนฉุกเฉินและการกู้ภัย (Emergency & Rescue Plan)
      │    └── Step 6: การลงนาม 4 ฝ่ายและส่งขออนุมัติ (Digital Signatures & Submission)
      │
      ├── Tab 3: เครื่องมือหน้างานเรียลไทม์ (PtwLiveSafetyTab)
      │    ├── Active Permit Selector & Live Status Banner
      │    ├── Real-time Gas Test Logger (O2, LEL, CO, H2S Auto-evaluation & History)
      │    ├── 30-Minute Fire Watch Countdown Timer (Live Tick + Log Sheet)
      │    ├── LOTO Isolation Zero-Energy Verification Check
      │    └── Shift Handover & Extension Sign-off
      │
      └── Tab 4: คลังกฎหมายราชกิจจานุเบกษา (PtwLegalLibraryTab)
           ├── 5 Key Ministerial Regulations + DLPW Official Gazette Texts
           ├── Statutory Threshold Reference Cards (Gas Limits, Height, Fire Watch)
           └── PDF Viewer & Gazette Downloader Dialog
```

---

### 4.1 Tab 1: PTW Dashboard & Register (`PtwDashboardTab`)

#### A. KPI Metric Cards
1. **ทั้งหมด (Total PTWs)**: Blue accent, displays total permits created.
2. **กำลังปฏิบัติงาน (Active / In Progress)**: Emerald Green accent with pulsing live indicator.
3. **รอการอนุมัติ (Pending Approval)**: Amber accent, flags permits awaiting Safety Officer / Authorizer approval.
4. **เกินเวลา / เตือนภัย (Overdue Alert)**: Red accent, flags permits past expiry time without closure.
5. **ปิดงานแล้ว (Closed / Completed)**: Slate Grey accent, confirmed post-work inspection.

#### B. Filter & Search Controls
- Instant search by: Permit Number (e.g. `PTW-2026-001`), Job Title, Location/Plant, Contractor Name.
- Status Filter Chips: `ทั้งหมด`, `ร่างคำขอ (Draft)`, `รออนุมัติ (Pending)`, `เปิดงาน (Active)`, `ส่งมอบ/ต่อเวลา (Extended)`, `ปิดงาน (Closed)`.
- Risk Category Dropdown: `ทุกประเภท`, `Hot Work`, `Confined Space`, `Working at Height`, `Electrical & LOTO`, `Excavation & Lifting`.

#### C. Data Table / Card Columns
- **Permit No & QR Action**: Displays PTW ID with mini QR code button.
- **Risk Category Badges**: Color-coded badges indicating which high-risk types are active.
- **Work Title & Department**: Description of work, contractor company, and plant area.
- **Validity Period**: Start time - End time with live countdown indicator if active.
- **Gas & Safety State**: Quick indicator of Gas Test status and LOTO status.
- **Workflow Status Badge**: Rich status chip with icon.
- **Action Buttons**:
  - `ดูรายละเอียด / แก้ไข (View/Edit)`
  - `พิมพ์ใบอนุญาต PDF (Print PDF)`
  - `เครื่องมือหน้างาน (Open Live Safety Controls)`
  - `อนุมัติ / ปิดงาน (Approve / Close)`

---

### 4.2 Tab 2: Create / Edit PTW Wizard (`PtwWizardTab`)

A structured 6-step guided wizard ensuring full compliance before submission:

#### Step 1: General Info & Work Description (ข้อมูลทั่วไป)
- Permit Number (Auto-generated: `PTW-YYYY-XXXX`), Revision Number.
- Job Title & Detailed Scope of Work.
- Plant / Building / Specific Area / Department.
- Work Type: Internal Maintenance vs. Subcontractor.
- Contractor Company Name, Supervisor Name, Emergency Contact Phone.
- Work Schedule: Validity Start Date/Time & Validity End Date/Time.

#### Step 2: High-Risk Category Selection (เลือกประเภทงานความเสี่ยงสูง)
Multi-select toggles with dynamic form expansion for selected risks:
1. **Hot Work (งานประกายไฟ/ความร้อน)**: Welding, Cutting, Grinding, Sandblasting. Requires Fire Watcher assignment & fire extinguisher type.
2. **Confined Space (งานในที่อับอากาศ)**: Silo, Manhole, Tank, Underground Pipe. Requires Pre-entry gas test & 4-role registration.
3. **Working at Height (งานบนที่สูง)**: Height > 2 meters, scaffolding, roof, man-basket. Requires harness & anchor point inspection.
4. **Electrical & LOTO (งานไฟฟ้าและตัดแยกพลังงาน)**: High/Low voltage, circuit breakers, valves. Requires Lockout tag number and zero-energy test method.
5. **Excavation & Lifting (งานขุดเจาะและยกเคลื่อนย้าย)**: Excavation depth > 1.5 meters, shoring, cranes/rigging. Requires soil stability check and crane certification.

#### Step 3: Statutory Safety Checklist (รายการตรวจสอบความปลอดภัยตามกฎหมาย)
Categorized checklist with Pass / Fail / N/A options:
- Atmospheric & Ventilation controls (พัดลมดูดอากาศ, การระบายอากาศต่อเนื่อง)
- Fire Prevention controls (การกั้นผ้ากันไฟ, เคลียร์เชื้อเพลิงในรัศมี ๑๐ เมตร, ถังดับเพลิงประจำจุด)
- Fall Protection controls (การตรวจนั่งร้าน, ราวกั้น, จุดยึด Lifeline, Full Body Harness)
- Isolation & Warning controls (การตัดระบบท่อ, ปิดวาล์ว, ติดป้ายเตือนอันตราย, ล็อกเบรกเกอร์)
- Personal Protective Equipment (PPE) specific to tasks.

#### Step 4: Workers, Confined Space 4 Roles & LOTO Register (ผู้ปฏิบัติงานและตัดแยกพลังงาน)
- **Worker Roster**: Table of worker names, IDs, and safety induction status.
- **Confined Space 4 Roles Registration** (ตามกฎกระทรวงฯ ๒๕๖๒):
  1. *ผู้อนุญาต (Authorizer)*: Name + Training Certificate No.
  2. *ผู้ควบคุมงาน (Supervisor)*: Name + Training Certificate No.
  3. *ผู้ช่วยเหลือ (Attendant / Standby Person)*: Name + Training Certificate No.
  4. *ผู้ปฏิบัติงาน (Entrants)*: List of entrant names + Training Certificate Nos.
- **LOTO Isolation Register** (ตามกฎกระทรวงฯ ๒๕๕๘):
  - Isolation Point Description (e.g. Main Breaker Panel MCC-01)
  - Padlock Tag No. (e.g. LOTO-E-042)
  - Energy Source Type (Electrical, Hydraulic, Pneumatic, Chemical, Thermal)
  - Zero Energy Verification Method (Multimeter test, pressure gauge release, try-to-start test)
  - Verified By (Name & Timestamp)

#### Step 5: Emergency Response & Rescue Plan (แผนฉุกเฉินและการกู้ภัย)
- Confined space rescue equipment checklist: Tripod winch, Full body harness, SCBA / Air-line respirator, Retrieval lifeline.
- Emergency Coordinator Name & Immediate Contact Phone (24-hr).
- Designated Evacuation Assembly Point.
- Nearest Hospital Name & Ambulance Direct Line.

#### Step 6: 4-Party Digital Signatures & Submission (ลงนามดิจิทัล 4 ฝ่าย)
Interactive Digital Signature Pads for:
1. **ผู้ขอใบอนุญาต (Applicant / Contractor Supervisor)**: ยืนยันข้อมูลและความพร้อมของคนงาน
2. **ผู้ตรวจสอบความปลอดภัย (Safety Officer / จป.วิชาชีพ)**: ตรวจสอบ JSA, มาตรการควบคุม, และความถูกต้องตามกฎหมาย
3. **ผู้อนุญาตตามกฎหมาย (Authorizer / Facility Manager)**: อนุมัติเปิดงานและกำหนดช่วงเวลา
4. **ผู้ปิดงาน / ส่งมอบพื้นที่ (Closure Sign-off)**: ตรวจสอบความปลอดภัยหลังเลิกงานและปิดใบอนุญาตสมบูรณ์

---

### 4.3 Tab 3: Live Site Safety Controls (`PtwLiveSafetyTab`)

Designed specifically for on-site Safety Officers, Supervisors, and Fire Watchers:

#### A. Active Permit Selector & Live Banner
- Dropdown selector of currently `ACTIVE` permits.
- Prominent countdown badge showing remaining validity hours:minutes.
- Quick status badge: "Safe to Work" vs. "Hazard Alert".

#### B. Real-time Gas Test Logger (ที่อับอากาศ)
- **Live Gas Evaluation Engine**:
  * $\text{O}_2$ (Oxygen): **19.5% - 23.5%** (Alert if $< 19.5\%$ or $> 23.5\%$)
  * $\text{LEL}$ (Flammable Gas): **$< 10\%$** (Alert if $\ge 10\%$)
  * $\text{CO}$ (Carbon Monoxide): **$< 25\text{ ppm}$** (Alert if $\ge 25\text{ ppm}$)
  * $\text{H}_2\text{S}$ (Hydrogen Sulfide): **$< 10\text{ ppm}$** (Alert if $\ge 10\text{ ppm}$)
- **Measurement Log Form**:
  - Test Type: Pre-entry (ก่อนเข้าทำงาน) vs. Continuous Monitoring (ตรวจวัดต่อเนื่องทุก 1-2 ชม.)
  - Timestamp, Tester Name, Equipment Model & Calibration Date.
  - Automatic Pass/Fail banner with immediate acoustic/visual hazard alert if out of range.
- **Gas Test History Table & Trend Graph**: Real-time multi-point history display.

#### C. 30-Minute Fire Watch Countdown Timer (งาน Hot Work)
- Conforming to กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อกำหนดเฝ้าระวังอัคคีภัยหลังเลิกงานไม่น้อยกว่า ๓๐ นาที.
- **Interactive Timer**: Start, Pause, Reset, Complete buttons.
- Real-time animated circular progress indicator counting down 30:00 -> 00:00.
- Post-work Inspection Checklist:
  - ฉีดพรมน้ำดับเศษเถ้าถ่าน / ดับสะเก็ดไฟ
  - ตรวจสอบอุณหภูมิผิวโลหะและรอยต่อโครงสร้าง
  - ยืนยันไม่มีควันหรือความร้อนสะสม
- Fire Watcher digital sign-off upon completion of 30 minutes.

#### D. LOTO Zero-Energy Verification Tracker
- Live checklist of all active padlock tags on site.
- One-click confirmation of zero energy before starting maintenance.

#### E. Shift Handover & Extension Sign-off
- Log for transferring permit control to incoming shift supervisor.
- Overtime extension request with updated hazard verification.

---

### 4.4 Tab 4: Legal Reference Library (`PtwLegalLibraryTab`)

A searchable repository for Thai Occupational Safety & Health laws:
1. **พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔**: มาตรา ๘ (หน้าที่นายจ้าง), ๑๔ (แจ้งอันตราย), ๑๖ (ฝึกอบรม), ๒๒ (PPE), ๒๓ (ผู้รับเหมา), ๓๒ (แผนควบคุมอันตราย).
2. **กฎกระทรวงที่อับอากาศ ๒๕๖๒**: ข้อ ๔-๖ (หนังสืออนุญาตและปิดประกาศ), ข้อ ๗ (เกณฑ์บรรยากาศอันตราย), ข้อ ๙-๑๒ (หน้าที่ ๔ ฝ่าย), ข้อ ๑๗-๑๘ (แผนกู้ภัย).
3. **กฎกระทรวงป้องกันและระงับอัคคีภัย ๒๕๕๕**: การทำงานประกายไฟ (Hot Work), เครื่องดับเพลิง, ผู้เฝ้าระวังไฟ, และการตรวจหลังเลิกงาน ๓๐ นาที.
4. **กฎกระทรวงไฟฟ้า ๒๕๕๘**: การตัดแยกระบบไฟฟ้า (LOTO), การตรวจไฟตกค้าง, ป้ายเตือน.
5. **กฎกระทรวงงานบนที่สูงและงานดินขุด ๒๕๖๔**: การทำงานสูงเกิน ๒ เมตร, สายรัด Full Body Harness & Lifeline, งานขุดดินลึกเกิน ๑.๕ เมตร.
6. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน**: แบบหนังสืออนุญาตให้ลูกจ้างทำงานในที่อับอากาศฉบับมาตรฐาน.

**Interactive Features**:
- Full-text search by statutory keyword or article number.
- Threshold quick reference cheat-sheet (Gas, Height, Fire Watch, Shoring).
- Integrated PDF Viewer with download and print capabilities.

---

## 5. Export Pipelines (PDF, Excel, QR Code)

### 5.1 Official Statutory PDF Exporter (`PtwPdfExporter`)
- **Document Layout**: A4 Portrait official Permit to Work document matching Department of Labour Protection and Welfare (DLPW) standards.
- **Typography**: Authentic Google Sarabun (`PdfGoogleFonts.sarabunRegular()`, `sarabunBold()`, `sarabunItalic()`).
- **Embedded Document Sections**:
  1. **Header Banner**: Official emblem / Title, Permit No, Validity Period, Status.
  2. **Workplace & Contractor Details**: Company, plant area, job title, emergency contact.
  3. **High-Risk Classification & Safety Checklist**: 5 risk types, PPE requirements, safety controls.
  4. **Confined Space 4-Role Roster & LOTO Tags**: Statutory names, training numbers, padlock tag numbers.
  5. **Atmospheric Gas Testing Record**: Pre-entry & continuous test logs (O2, LEL, CO, H2S).
  6. **Fire Watch & Post-Work Monitoring**: 30-min monitoring confirmation.
  7. **QR Code Verification Stamp**: `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: ptwPayload, width: 75, height: 75)`.
  8. **4-Party Digital Signatures**: High-resolution embedded signature images for Requester, Safety Officer, Authorizer, and Closure.

### 5.2 Multi-Sheet Excel Exporter (`PtwExcelExporter`)
Generates comprehensive `.xlsx` workbooks with 5 structured sheets:
- **Sheet 1: สรุปภาพรวมและทะเบียน (Summary & Register)**: Executive KPI counts (Total, Active, Pending, Overdue, Closed) + master permit table.
- **Sheet 2: รายละเอียดใบอนุญาต (Permit Details)**: Deep data attributes for all 5 risk types, contractors, and work schedules.
- **Sheet 3: บันทึกผลตรวจวัดก๊าซ (Gas Testing Logs)**: Full timestamped readings of O2, LEL, CO, H2S with automated pass/fail evaluations.
- **Sheet 4: ผู้มีหน้าที่ 4 ฝ่ายและ LOTO (4 Roles & LOTO)**: Confined space role certs and padlock tag registers.
- **Sheet 5: เกณฑ์มาตรฐานกฎหมาย (Statutory Standards)**: Reference legal thresholds and ministerial articles.

---

## 6. Testing Infrastructure & Verification Strategy

### 6.1 Test Suite Organization
Located under `test/features/ptw/`:
1. `ptw_gas_evaluator_test.dart`: Unit tests for gas testing thresholds (O2 19.5-23.5%, LEL < 10%, CO < 25 ppm, H2S < 10 ppm) with boundary values (19.4%, 19.5%, 23.5%, 23.6%, 9.9%, 10.0%, 24.9 ppm, 25.0 ppm, 9.9 ppm, 10.0 ppm).
2. `ptw_workflow_state_machine_test.dart`: State transition tests (Draft -> Pending -> Active -> Extended -> Closed / Cancelled) with validation checks.
3. `ptw_loto_and_roles_test.dart`: Validation of 4 distinct confined space roles, certificate formats, and zero-energy checks.
4. `ptw_kpi_summary_test.dart`: Metric aggregation and overdue permit detection.
5. `ptw_exporters_test.dart`: PDF and Excel byte generation verification.
6. `ptw_page_widget_test.dart`: Complete widget tests for 4 tabs, dialogs, timers, and signature pads.
7. `ptw_adversarial_stress_test.dart`: Boundary values, null fields, corrupted timestamps, and high concurrency load.

---

## 7. Recommended Implementation Plan for Worker Agents

| Component | Responsibility | Priority |
|-----------|----------------|----------|
| `PtwModel`, `GasTestLogModel`, `LotoIsolationModel`, `ConfinedRoleModel`, `PtwChecklistModel` | Domain Models & JSON serialization | High |
| `PtwEvaluator`, `PtwStateMachine`, `PtwKpiCalculator` | Core calculation and state engine | High |
| `PtwRepository` & `DatabaseHelper` (v7 -> v8 migration) | SQLite persistence | High |
| `PtwProviders` (Riverpod StateNotifiers) | Presentation state management | High |
| `SignaturePadWidget` & `QrCodeWidget` | Reusable UI components | Medium |
| `PtwDashboardTab`, `PtwWizardTab`, `PtwLiveSafetyTab`, `PtwLegalLibraryTab` | 4 statutory tabs in `PtwPage` | High |
| `PtwPdfExporter` & `PtwExcelExporter` | Official DLPW export services | High |
| Unit, Widget, and Adversarial Test Suites | 100% test coverage | High |
