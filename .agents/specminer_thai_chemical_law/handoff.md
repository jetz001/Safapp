# Thai Chemical Safety Law Specification Mining Report
**Module**: Chemical & SDS Management (การจัดการสารเคมีอันตรายและเอกสารความปลอดภัย) & Agent Skill `thai-chemical-safety-law`  
**Author**: Thai Chemical Law Spec Miner  
**Target File**: `d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\handoff.md`  
**Date**: 2026-08-31  

---

## 1. Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Master Data | Hazardous Chemical Master List (1,516 items) | Comprehensive master database of 1,516 regulated hazardous substances under DLPW notification | Search query string (Thai, English, CAS No., Seq No.) | List of matching chemical records with Thai Name, English Name, CAS No., Sequence ID | Returns empty list if no match found; handles punctuation/dash stripping gracefully | ราชกิจจานุเบกษา เล่ม ๑๓๐ ตอนพิเศษ ๑๘๕ ง (๒๕๕๖) |
| 2 | Master Data | Autocomplete & Search Indexing Engine | High-performance sub-50ms search index prioritizing CAS No. exact match, Prefix match, Substring match | User typed input in search bar | Ranked suggestions list (Top 10-20 items) with highlighted match | Falls back to fuzzy/trigram match if strict prefix yields 0 results | UI/UX & SQLite FTS5 / In-Memory indexing specs |
| 3 | TLV & Evaluation | Occupational Exposure Limits (324 items) | Master dataset of 324 chemical occupational exposure thresholds (TWA 8-hr, STEL 15-min, Ceiling in ppm and mg/m³) | Chemical CAS / Seq No. | Legal threshold values (`twa_ppm`, `twa_mg_m3`, `stel_ppm`, `stel_mg_m3`, `ceiling_ppm`, `ceiling_mg_m3`, `skin_notation`) | Returns null or "No specific TLV" warning if chemical not in 324 list | ราชกิจจานุเบกษา เล่ม ๑๓๔ ตอนพิเศษ ๑๙๘ ง (๒๕๖๐) |
| 4 | TLV & Evaluation | Single Chemical Pass/Fail Evaluation | Compares measured airborne concentration against legal TLV thresholds | Measured value, unit (ppm or mg/m³), measurement type (TWA / STEL / Ceiling) | Evaluation Status: `PASS` (<= TLV), `ACTION_LEVEL` (50%-100% TLV), `EXCEEDED` (> TLV), ratio % | Throws validation error if measured value < 0 or invalid unit | ประกาศ กพร. เรื่อง ขีดจำกัดความเข้มข้นฯ |
| 5 | TLV & Evaluation | Chemical Mixture Exposure Index (Additivity) | Evaluates combined exposure for multiple chemicals with additive health effects: $E_m = \sum (C_i / \text{TLV}_i)$ | List of measured pairs $(C_i, \text{TLV}_i)$ | Combined index $E_m$, Pass status ($E_m \le 1.0$ = Pass, $E_m > 1.0$ = Exceeded) | Flags warning if components lack comparable TLVs or units mismatch | ACGIH / NIOSH Industrial Hygiene Standard |
| 6 | TLV & Evaluation | PPM to MG/M³ Unit Conversion | Converts gas/vapor concentrations between ppm and mg/m³ at $25^\circ\text{C}, 1\text{ atm}$ using Molecular Weight | Value, source unit, Molecular Weight (g/mol), optional Temperature & Pressure | Converted value in target unit | Returns error if Molecular Weight <= 0 or missing | Standard Physical Chemistry / NIOSH Formula |
| 7 | Form Sor.Or.1 | SDS 16 Sections Data Model | Data structure and entry form covering all 16 mandatory GHS safety data sheet sections | Complete form input across 16 categories | Validated SDS object ready for database storage and rendering | Highlights missing mandatory fields (trade name, CAS, GHS classification) | กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ (แบบ สอ.๑) |
| 8 | Form Sor.Or.1 | GHS Pictograms & Hazard Identification | Selection and visual rendering of 9 standard GHS pictograms, Signal Words (Danger/Warning), Hazard & Precautionary codes | Selected pictogram IDs, Signal Word, H-statements, P-statements | GHS Hazard Label Preview & Badge components | Rejects invalid H/P codes, ensures at least one classification if hazardous | GHS Rev.8 / ประกาศกระทรวงอุตสาหกรรม ๒๕๕๕ |
| 9 | Form Sor.Or.1 | NFPA 704 Diamond Component | Interactive/visual 4-quadrant diamond for Health (Blue), Flammability (Red), Instability (Yellow), Special (White) | Scores 0-4 for H, F, I; Special symbol (e.g. W, OX, SA) | Rendered 2D canvas/widget NFPA 704 Diamond graphic | Enforces integer range 0..4; validates standard special hazard symbols | NFPA 704 Standard System |
| 10 | Form Sor.Or.1 | Sor.Or.1 PDF/Print Export | Generates official PDF document matching the statutory Form Sor.Or.1 layout | Form Sor.Or.1 record & company profile | Standard PDF document (A4, Thai Sarabun font, official DLPW header) | Gracefully handles long text wrapping across multi-page tables | แบบท้ายประกาศกรมสวัสดิการฯ (แบบ สอ.๑) |
| 11 | Form Sor.Or.3 | Sor.Or.3 Measurement Report Model (2022) | Structure for recording atmospheric measurement surveys per Revised Notification B.E. 2565 | Company info, sampling date, locations, methods, sampled points, lab analysis results | Structured Sor.Or.3 survey record with auto-calculated compliance status | Rejects records with missing sampling points or uncertified surveyor | ราชกิจจานุเบกษา เล่ม ๑๓๙ ตอนพิเศษ ๗๓ ง (๒๕๖๕) |
| 12 | Form Sor.Or.3 | Section 9 & 11 Registration Management | Captures legal certification for registered inspecting entities (Section 9) and registered individuals (Section 11) | License No., Entity/Person Name, Validity Dates, Signatory info | Verification badge, expiration check of surveyor license | Displays warning if surveyor license is expired or invalid format | พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ ม.๙ และ ม.๑๑ |
| 13 | Form Sor.Or.3 | Sor.Or.3 Official PDF Export (2022 Format) | Generates statutory Form Sor.Or.3 PDF report complete with Sections 1-6 and formal signatures | Complete Sor.Or.3 survey record & company profile | Official DLPW Form Sor.Or.3 PDF document (A4 landscape/portrait) | Validates table alignment and signature placeholders | แบบท้ายประกาศกรมสวัสดิการฯ สอ.๓ (ฉบับที่ ๒) ๒๕๖๕ |
| 14 | SDS Lifecycle | Expiry Calculation & Status Engine | Computes SDS expiry based on issue date and review cycle (3-5 years) with dynamic status categories | SDS issue date, review cycle policy (years) | Expiry Date, Days Remaining ($\Delta_{\text{days}}$), Status Enum (`NORMAL`, `NEAR_30`, `NEAR_60`, `NEAR_90`, `EXPIRED`) | Flags warning if issue date is in the future | Industrial Best Practice & DLPW Regulations |
| 15 | SDS Lifecycle | Chemical Possession & Location Inventory | Tracks workplace chemical inventory: quantity, storage location, container type, max allowed threshold | Quantity, unit (kg, L, ton), warehouse/room ID, container type | Inventory balance, hazard aggregation per storage location | Rejects negative quantities; alerts when location capacity exceeded | กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ หมวด ๒ |
| 16 | Legal Library | Gazette Repository & PDF Preview | Digital library of full Thai Royal Gazette chemical laws with metadata, tags, and in-app PDF preview | Legal document ID / filter query | Filtered list of laws, embedded PDF viewer, external web links | Displays friendly fallback if PDF asset is loading or missing | กรมสวัสดิการและคุ้มครองแรงงาน / ราชกิจจานุเบกษา |
| 17 | Legal Library | Cross-Module Contextual Deep Links | Direct navigational links from forms (Sor.Or.1, Sor.Or.3, Inventory) to relevant legal gazette articles | Context tag (e.g. `TLV_TABLE`, `SOR_OR_1_SPEC`, `MINISTERIAL_2556`) | Opens modal or navigates to specific legal document page | Falls back to general legal library overview if tag not found | SAFAPP Architecture Integration |
| 18 | Agent Skill | `thai-chemical-safety-law` CLI Tool | CLI tool interface for AI agents supporting search, get-tlv, get-law, and verify-sds | CLI arguments (`search --query`, `get-tlv --cas`, `get-law --id`, `verify-sds --file`) | JSON formatted output with exit code 0 on success | Outputs structured JSON error message with non-zero exit code | Multi-Agent System Skill Standard |

---

## 2. Edge Cases

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Autocomplete Search | User types CAS number without dashes: `7664939` vs `7664-93-9` | Search normalizer automatically strips non-alphanumeric chars or injects standard dash pattern to match CAS `7664-93-9` (Sulfuric acid). |
| 2 | Autocomplete Search | Mixed Thai and English spelling (e.g., `โทลูอีน` vs `Toluene` vs `108-88-3`) | Multi-index search matches across Thai name, English name, and CAS simultaneously, ranking exact match first. |
| 3 | Autocomplete Search | Chemical with multiple CAS numbers or isomer mixtures (e.g. Xylene `1330-20-7`, o-xylene `95-47-6`, m-xylene `108-38-3`, p-xylene `106-42-3`) | System displays parent entry and specific isomers with sequence numbers and CAS identifiers clearly separated. |
| 4 | TLV Evaluation | Chemical has both TWA (ppm) and TWA (mg/m³) in gazette | System allows input in either ppm or mg/m³ and performs automatic equivalence check using molecular weight. |
| 5 | TLV Evaluation | Measured value exactly equals TLV ($C = \text{TLV}$) | Evaluates to `PASS` (Normal / ไม่เกินมาตรฐาน) per legal boundary condition ($\le$). |
| 6 | TLV Evaluation | Measured value at Action Level ($0.5 \times \text{TLV} \le C \le \text{TLV}$) | Evaluates to `PASS_ACTION_LEVEL` (ผ่านเกณฑ์แต่ต้องเฝ้าระวัง/มีสีเตือนเหลือง) to alert Safety Officer. |
| 7 | TLV Evaluation | Chemical has Ceiling limit only (no TWA) | Evaluates peak instantaneous reading directly against Ceiling; any exceedance immediately triggers `FAIL`. |
| 8 | TLV Mixture Index | One of the mixture components has 0 concentration or is not in 324 TLV list | Calculation skips 0-concentration components; displays warning badge for unlisted components while calculating $E_m$ for listed ones. |
| 9 | Sor.Or.1 Form | Mixture has > 20 individual chemical components | Section 3 provides dynamic scrollable table with sorting by percentage and automatic sum validation ($\sum \% \le 100\%$). |
| 10 | Sor.Or.1 Form | Chemical with no NFPA 704 rating assigned by manufacturer | NFPA diamond defaults to standard 0/0/0/None with visual indicator "ข้อมูลไม่ระบุ" rather than crashing. |
| 11 | Sor.Or.3 Form | Survey performed across multiple days/shifts (TWA calculation) | Calculates time-weighted average using exact duration of each shift segment: $C_{\text{TWA}} = \frac{\sum (C_i \times T_i)}{\sum T_i}$. |
| 12 | Sor.Or.3 Form | Surveyor license under Section 9 expired before sampling date | Form validation highlights license status in red and flags warning on PDF report that surveyor was not actively certified on test date. |
| 13 | SDS Expiry | SDS Issue Date is exactly 3 years ago today | Days remaining = 0 $\rightarrow$ Status transitions to `EXPIRED` at 00:00:00. |
| 14 | SDS Expiry | User customizes review cycle from 3 years to 5 years | System immediately recalculates expiry dates and re-categorizes status badges across all registered chemicals. |
| 15 | PDF Generation | Chemical name or location text is extremely long (> 100 characters in Thai) | PDF table generator utilizes automated text wrapping, dynamic cell height, and Thai word-break hyphenation without clipping text. |

---

## 3. 5-Component Handoff Report

### 1. Observation
- **Codebase & Architecture Inspection**:
  - `lib/features/chemicals/presentation/pages/chemicals_page.dart` is currently a placeholder (32 lines) with basic Scaffold and AppBar.
  - `lib/core/database/database_helper.dart` (705 lines) provides SQLite infrastructure (`sqflite_common_ffi`, database path in `Documents/SafetySuperapp/safety_superapp_v1.db`).
  - Architecture standards established in `lib/features/risk_assessment/` and `lib/features/health_hygiene/` follow clear Clean Architecture: `data/repositories/`, `domain/models/`, `presentation/pages/`, `presentation/providers/`, `presentation/widgets/`, and `services/` (PDF and Excel generation using `pdf`, `printing`, `excel`, and `syncfusion_flutter_pdfviewer`).
- **Thai Royal Gazette Specifications**:
  1. *Ministerial Regulation on Hazardous Chemicals B.E. 2556* (กฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับสารเคมีอันตราย พ.ศ. ๒๕๕๖): Published 29 Nov 2556, Vol. 130, Part 113 A.
  2. *DLPW Notification on Hazardous Chemicals List* (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง บัญชีรายชื่อสารเคมีอันตราย): Published 20 Dec 2556, Vol. 130, Special Part 185 D. Regulates **1,516 chemical substances** with Sequence No., Thai Name, English Name, and CAS Number.
  3. *DLPW Notification on Threshold Limit Values of Hazardous Chemicals* (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง ขีดจำกัดความเข้มข้นของสารเคมีอันตราย): Published 3 Aug 2560, Vol. 134, Special Part 198 D. Regulates **324 chemical exposure limits** (TWA 8-hr, STEL 15-min, Ceiling in ppm and mg/m³).
  4. *DLPW Notification on Form Sor.Or.1* (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย (แบบ สอ.๑)): Published 20 Dec 2556, Vol. 130, Special Part 185 D. Defines **16 standard GHS sections**.
  5. *DLPW Notification on Atmospheric Measurement Rules & Form Sor.Or.3 (No.2) B.E. 2565* (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการตรวจวัด และการวิเคราะห์ผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตราย (ฉบับที่ ๒) พ.ศ. ๒๕๖๕): Published 29 Mar 2565, Vol. 139, Special Part 73 D. Defines revised **Form Sor.Or.3 (แบบ สอ.๓)**, requiring registration under **Section 9** (Juridical Entities) and **Section 11** (Certified Individuals) of OSH Act B.E. 2554.

---

### 2. Logic Chain
1. **Master Data Structure (1,516 & 324 Items)**:
   - To guarantee compliance, the system must embed a seed dataset of all 1,516 hazardous substances and 324 TLVs.
   - Indexing on `cas_number`, `english_name`, `thai_name`, and `sequence_no` allows instant local autocomplete queries with zero network latency.
   - For substances present in both lists, a direct foreign reference (`chemical_master_id` $\leftrightarrow$ `tlv_master_id`) ensures automatic TLV retrieval during atmospheric measurement entry.

2. **TLV Evaluation Logic**:
   - For measured concentration $C$:
     - If $C \le 0.5 \times \text{TLV} \rightarrow$ `STATUS_NORMAL` (Green).
     - If $0.5 \times \text{TLV} < C \le \text{TLV} \rightarrow$ `STATUS_ACTION_LEVEL` (Orange/Yellow - caution, continuous monitoring recommended).
     - If $C > \text{TLV} \rightarrow$ `STATUS_EXCEEDED` (Red - non-compliant, requires immediate engineering/PPE intervention).
   - For mixtures with additive toxicological targets:
     - $E_m = \sum_{i=1}^n \frac{C_i}{\text{TLV}_i}$. If $E_m > 1.0 \rightarrow$ `STATUS_EXCEEDED`.

3. **SDS 16-Section Structure (แบบ สอ.๑)**:
   - Must mirror the statutory 16 GHS headings precisely so exported PDFs match DLPW official inspection standards.
   - Integrated with GHS Pictograms (9 standard types) and NFPA 704 Diamond (Health, Flammability, Reactivity, Special).

4. **Atmospheric Measurement Report Structure (แบบ สอ.๓ พ.ศ. ๒๕๖๕)**:
   - Revised 2565 form strictly mandates recording whether the inspection was performed by:
     - **Section 9 Entity**: Legal entity name, DLPW registration certificate no. (เลขทะเบียนใบสำคัญ), validity dates, signatory.
     - **Section 11 Individual**: Individual name, registration no., certified qualification, validity dates.
   - Automated comparison between measured sampling points and the 324 TLV table determines overall report compliance.

5. **SDS Lifecycle & Expiry Tracking**:
   - Expiry Date = $\text{Issue Date} + \text{Validity Years (default 3 or 5)}$.
   - Real-time status badges: `EXPIRED` ($\Delta_{\text{days}} < 0$), `NEAR_30` ($0 \le \Delta \le 30$), `NEAR_60` ($31 \le \Delta \le 60$), `NEAR_90` ($61 \le \Delta \le 90$), `NORMAL` ($\Delta > 90$).

6. **Legal Reference Library**:
   - Stores authoritative metadata and bundled PDF assets for all 7 key legal documents, enabling in-app preview and contextual navigation from forms.

---

### 3. Caveats
- **Local vs. Remote Master Dataset**: Master data for 1,516 substances and 324 TLVs should be bundled locally as JSON/SQLite asset seeds so the desktop application functions 100% offline without external network dependencies.
- **Molecular Weight for Unit Conversion**: Not all 1,516 chemicals have simple constant molecular weights (some are petroleum fractions or polymers). For substances with variable composition, conversion should prompt the user for specific MW if not in standard table.
- **Section 9 / Section 11 Surveyor Validation**: The system validates license format and expiration date locally based on user input.

---

### 4. Conclusion & Technical Specifications

#### A. Database Schema Blueprint
```sql
-- 1. Master Hazardous Chemicals (1,516 items)
CREATE TABLE IF NOT EXISTS chemical_master_1516 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sequence_no INTEGER NOT NULL UNIQUE,
  cas_number TEXT NOT NULL,
  thai_name TEXT NOT NULL,
  english_name TEXT NOT NULL,
  chemical_formula TEXT,
  un_number TEXT,
  hazard_category TEXT,
  molecular_weight REAL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_chem_master_cas ON chemical_master_1516(cas_number);
CREATE INDEX IF NOT EXISTS idx_chem_master_en ON chemical_master_1516(english_name);
CREATE INDEX IF NOT EXISTS idx_chem_master_th ON chemical_master_1516(thai_name);

-- 2. Master Occupational Exposure Limits (324 TLVs)
CREATE TABLE IF NOT EXISTS chemical_tlv_324 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sequence_no INTEGER NOT NULL UNIQUE,
  cas_number TEXT,
  thai_name TEXT NOT NULL,
  english_name TEXT NOT NULL,
  twa_ppm REAL,
  twa_mg_m3 REAL,
  stel_ppm REAL,
  stel_mg_m3 REAL,
  ceiling_ppm REAL,
  ceiling_mg_m3 REAL,
  skin_notation INTEGER DEFAULT 0,
  carcinogen_category TEXT,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_chem_tlv_cas ON chemical_tlv_324(cas_number);

-- 3. Workplace Chemical Possession & SDS Register (R1 & R2)
CREATE TABLE IF NOT EXISTS workplace_chemicals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chemical_master_id INTEGER,
  trade_name TEXT NOT NULL,
  chemical_name TEXT NOT NULL,
  cas_number TEXT,
  un_number TEXT,
  manufacturer_supplier TEXT,
  supplier_contact TEXT,
  emergency_phone TEXT,
  current_quantity REAL DEFAULT 0.0,
  quantity_unit TEXT DEFAULT 'KG',
  storage_location TEXT NOT NULL,
  container_type TEXT,
  max_capacity REAL,
  sds_issue_date TEXT,
  sds_validity_years INTEGER DEFAULT 3,
  sds_file_path TEXT,
  ghs_pictograms TEXT, -- JSON array e.g. ["flame", "corrosion"]
  signal_word TEXT, -- 'DANGER', 'WARNING', 'NONE'
  hazard_statements TEXT, -- JSON array of H-codes
  precautionary_statements TEXT, -- JSON array of P-codes
  nfpa_health INTEGER DEFAULT 0,
  nfpa_flammability INTEGER DEFAULT 0,
  nfpa_instability INTEGER DEFAULT 0,
  nfpa_special TEXT,
  notes TEXT,
  status TEXT DEFAULT 'ACTIVE',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chemical_master_id) REFERENCES chemical_master_1516(id) ON DELETE SET NULL
);

-- 4. Form Sor.Or.1 Detailed 16-Section Records
CREATE TABLE IF NOT EXISTS sds_form_sor_or_1 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  workplace_chemical_id INTEGER NOT NULL,
  sec1_chemical_product_identity TEXT,
  sec2_hazard_identification TEXT,
  sec3_composition_ingredients TEXT, -- JSON list of components
  sec4_first_aid_measures TEXT,
  sec5_fire_fighting_measures TEXT,
  sec6_accidental_release_measures TEXT,
  sec7_handling_storage TEXT,
  sec8_exposure_controls_ppe TEXT,
  sec9_physical_chemical_properties TEXT,
  sec10_stability_reactivity TEXT,
  sec11_toxicological_information TEXT,
  sec12_ecological_information TEXT,
  sec13_disposal_considerations TEXT,
  sec14_transport_information TEXT,
  sec15_regulatory_information TEXT,
  sec16_other_information TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (workplace_chemical_id) REFERENCES workplace_chemicals(id) ON DELETE CASCADE
);

-- 5. Form Sor.Or.3 Atmospheric Measurement Survey (2022 Revision)
CREATE TABLE IF NOT EXISTS atmospheric_surveys_sor_or_3 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  report_number TEXT NOT NULL UNIQUE,
  survey_title TEXT NOT NULL,
  company_id INTEGER,
  measurement_date_start TEXT NOT NULL,
  measurement_date_end TEXT NOT NULL,
  surveyor_type TEXT NOT NULL, -- 'SECTION_9' (Juridical) or 'SECTION_11' (Individual)
  section9_entity_name TEXT,
  section9_registration_no TEXT,
  section9_valid_from TEXT,
  section9_valid_to TEXT,
  section9_inspector_name TEXT,
  section9_certifier_name TEXT,
  section11_person_name TEXT,
  section11_registration_no TEXT,
  section11_qualification TEXT,
  section11_valid_to TEXT,
  ambient_temperature REAL,
  ambient_pressure REAL,
  ambient_humidity REAL,
  overall_pass_status TEXT DEFAULT 'PASS', -- 'PASS', 'ACTION_REQUIRED', 'FAIL'
  summary_notes TEXT,
  recommendations TEXT,
  pdf_report_path TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 6. Form Sor.Or.3 Measured Sampling Points
CREATE TABLE IF NOT EXISTS atmospheric_sampling_points (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_id INTEGER NOT NULL,
  point_code TEXT NOT NULL,
  work_area_name TEXT NOT NULL,
  process_description TEXT,
  exposed_workers_count INTEGER DEFAULT 1,
  ppe_used TEXT,
  chemical_tlv_id INTEGER,
  chemical_name TEXT NOT NULL,
  cas_number TEXT,
  sampling_type TEXT DEFAULT 'PERSONAL', -- 'PERSONAL' or 'AREA'
  sampling_duration_minutes REAL NOT NULL,
  air_volume_liters REAL,
  sampling_method TEXT, -- e.g. 'NIOSH 1501'
  analytical_method TEXT, -- e.g. 'GC-FID'
  measured_value REAL NOT NULL,
  measured_unit TEXT NOT NULL DEFAULT 'PPM', -- 'PPM' or 'MG_M3'
  twa_value REAL,
  legal_tlv_twa REAL,
  legal_tlv_stel REAL,
  legal_tlv_ceiling REAL,
  evaluation_status TEXT NOT NULL, -- 'PASS', 'ACTION_LEVEL', 'FAIL'
  exceed_percentage REAL DEFAULT 0.0,
  notes TEXT,
  FOREIGN KEY (survey_id) REFERENCES atmospheric_surveys_sor_or_3(id) ON DELETE CASCADE,
  FOREIGN KEY (chemical_tlv_id) REFERENCES chemical_tlv_324(id) ON DELETE SET NULL
);

-- 7. Legal Gazette Reference Library
CREATE TABLE IF NOT EXISTS chemical_legal_references (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_code TEXT NOT NULL UNIQUE,
  title_th TEXT NOT NULL,
  title_en TEXT,
  issuing_authority TEXT NOT NULL,
  gazette_date TEXT NOT NULL,
  gazette_volume TEXT,
  gazette_part TEXT,
  category TEXT NOT NULL,
  summary TEXT NOT NULL,
  key_provisions TEXT,
  pdf_asset_path TEXT,
  external_url TEXT,
  sort_order INTEGER DEFAULT 0
);
```

#### B. Complete 16 GHS Sections Specification (สอ.๑)
1. **Section 1: Identification** (ชื่อผลิตภัณฑ์, CAS, ผู้ผลิต/นำเข้า, เบอร์ฉุกเฉิน 24 ชม.)
2. **Section 2: Hazard Identification** (การจำแนก GHS, 9 Pictograms, Signal Word, H-statements, P-statements)
3. **Section 3: Composition / Information on Ingredients** (สารเดี่ยว/สารผสม, CAS No., % by weight)
4. **Section 4: First-Aid Measures** (สูดดม, ผิวหนัง, ดวงตา, กลืนกิน, อาการเฉียบพลัน/เรื้อรัง)
5. **Section 5: Fire-Fighting Measures** (สารดับเพลิงที่เหมาะสม/ห้ามใช้, ความเสี่ยงเฉพาะ, อุปกรณ์ SCBA)
6. **Section 6: Accidental Release Measures** (ข้อควรระวังส่วนบุคคล, วิธีดูดซับ/กักเก็บ, สิ่งแวดล้อม)
7. **Section 7: Handling and Storage** (การขนถ่ายปลอดภัย, สภาพจัดเก็บ, สารที่เข้ากันไม่ได้)
8. **Section 8: Exposure Controls / Personal Protection** (TLV/PEL, วิศวกรรมระบายอากาศ, PPE: Mask, Glove, Goggles, Body)
9. **Section 9: Physical and Chemical Properties** (สถานะ, จุดเดือด, จุดวาบไฟ, ความดันไอ, ค่า pH, ความถ่วงจำเพาะ, ความสามารถในการละลาย)
10. **Section 10: Stability and Reactivity** (ความคงตัว, สารที่เข้ากันไม่ได้, สภาวะที่ต้องหลีกเลี่ยง, สารสลายตัวอันตราย)
11. **Section 11: Toxicological Information** (LD50/LC50, การระคายเคือง, การแพ้, สารก่อมะเร็ง IARC)
12. **Section 12: Ecological Information** (ความเป็นพิษต่อสิ่งแวดล้อมทางน้ำ, การย่อยสลาย, การสะสมทางชีวภาพ)
13. **Section 13: Disposal Considerations** (วิธีกำจัดของเสีย, รหัสกากของเสียอันตราย กรอ.)
14. **Section 14: Transport Information** (UN Number, Proper Shipping Name, Class 1-9, Packing Group I/II/III)
15. **Section 15: Regulatory Information** (พ.ร.บ. วัตถุอันตราย, กฎกระทรวงสารเคมี ๒๕๕๖, พ.ร.บ. โรงงาน)
16. **Section 16: Other Information** (NFPA 704 Diamond, วันจัดทำ/ทบทวน, แหล่งอ้างอิง)

#### C. Sor.Or.3 (พ.ศ. ๒๕๖๕) Measurement Report Layout Specification
- **Header**: Official Emblem / DLPW Header (แบบ สอ.๓ ท้ายประกาศกรมสวัสดิการและคุ้มครองแรงงาน พ.ศ. ๒๕๖๕)
- **Part 1**: Company Details & Workplace Address
- **Part 2**: Process, Department, Sampling Point, Number of Exposed Employees, PPE Used
- **Part 3**: Chemical Name (Thai/EN/CAS), Sampling Method (NIOSH/OSHA), Lab Technique (GC/HPLC/AAS)
- **Part 4**: Sampling Duration, Measured Value, TWA Conversion, Legal Standard Comparison, Pass/Fail Status
- **Part 5**: Certifier Identity:
  - Checkbox: นิติบุคคลตามมาตรา ๙ (Company Name, Reg No. นบ., Signatory)
  - Checkbox: บุคคลธรรมดาตามมาตรา ๑๑ (Individual Name, Reg No. บ., Qualification)
- **Part 6**: Summary, Corrective Action Plan & Professional Recommendations

#### D. SDS Expiry Status Transition Matrix
| Status Code | Display Name (Thai) | Condition | Badge Color | Action Required |
|-------------|---------------------|-----------|-------------|-----------------|
| `NORMAL` | ปกติ | $\Delta_{\text{days}} > 90$ | Green (`#10B981`) | เอกสารสมบูรณ์ ใช้งานได้ตามปกติ |
| `NEAR_90` | ใกล้หมดอายุ (90 วัน) | $60 < \Delta_{\text{days}} \le 90$ | Yellow (`#F59E0B`) | เตรียมประสานผู้ผลิตขอ SDS ฉบับทบทวน |
| `NEAR_60` | ใกล้หมดอายุ (60 วัน) | $30 < \Delta_{\text{days}} \le 60$ | Orange (`#FB923C`) | ติดตามเอกสาร SDS ฉบับใหม่ |
| `NEAR_30` | ใกล้หมดอายุเร่งด่วน (30 วัน) | $0 \le \Delta_{\text{days}} \le 30$ | Red-Orange (`#F97316`) | ต้องได้รับ SDS ฉบับใหม่โดยด่วน |
| `EXPIRED` | หมดอายุแล้ว | $\Delta_{\text{days}} < 0$ | Red (`#EF4444`) | ห้ามใช้เอกสารเดิม ต้องปรับปรุงทันที |
| `NO_SDS` | ยังไม่มี SDS | SDS Date is NULL | Gray (`#6B7280`) | ขึ้นทะเบียนและแนบไฟล์ SDS ด่วน |

#### E. Legal Reference Library Repository List
1. **กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖** (ราชกิจจานุเบกษา ๒๙ พ.ย. ๒๕๕๖, เล่ม ๑๓๐ ตอน ๑๑๓ ก)
2. **ประกาศกรมสวัสดิการฯ เรื่อง บัญชีรายชื่อสารเคมีอันตราย ๑,๕๑๖ รายการ** (ราชกิจจานุเบกษา ๒๐ ธ.ค. ๒๕๕๖, เล่ม ๑๓๐ ตอนพิเศษ ๑๘๕ ง)
3. **ประกาศกรมสวัสดิการฯ เรื่อง ขีดจำกัดความเข้มข้นของสารเคมีอันตราย ๓๒๔ รายการ** (ราชกิจจานุเบกษา ๓ ส.ค. ๒๕๖๐, เล่ม ๑๓๔ ตอนพิเศษ ๑๙๘ ง)
4. **ประกาศกรมสวัสดิการฯ เรื่อง แบบ สอ.๑ (SDS 16 หัวข้อ)** (ราชกิจจานุเบกษา ๒๐ ธ.ค. ๒๕๕๖, เล่ม ๑๓๐ ตอนพิเศษ ๑๘๕ ง)
5. **ประกาศกรมสวัสดิการฯ เรื่อง การตรวจวัดและรายงานผล แบบ สอ.๓ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕** (ราชกิจจานุเบกษา ๒๙ มี.ค. ๒๕๖๕, เล่ม ๑๓๙ ตอนพิเศษ ๗๓ ง)
6. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔** (ราชกิจจานุเบกษา ๑๗ ม.ค. ๒๕๕๔, เล่ม ๑๒๘ ตอน ๔ ก)
7. **ประกาศกระทรวงอุตสาหกรรม เรื่อง ระบบ GHS พ.ศ. ๒๕๕๕** (ราชกิจจานุเบกษา ๑๒ มี.ค. ๒๕๕๕, เล่ม ๑๒๙ ตอนพิเศษ ๕๐ ง)

---

### 5. Verification Method
1. **Unit Test Suite**:
   - `test/chemicals_tlv_test.dart`: Test Single chemical pass/fail evaluation against 324 TLVs, STEL, Ceiling, and mixture exposure additivity index.
   - `test/sds_expiry_test.dart`: Test expiry date calculation and status transitions (`NORMAL`, `NEAR_90`, `NEAR_60`, `NEAR_30`, `EXPIRED`).
   - `test/unit_conversion_test.dart`: Test ppm $\leftrightarrow$ mg/m³ conversion using molecular weights (e.g. Benzene MW=78.11, Acetone MW=58.08).
2. **Database Integrity & Search Benchmark**:
   - Verify SQLite seeds insert 1,516 hazardous substances and 324 TLVs cleanly.
   - Run query benchmark for autocomplete search across 1,516 rows; verify execution time $< 50\text{ms}$.
3. **PDF Generation Visual Layout Verification**:
   - Verify generated PDF for Form Sor.Or.1 contains all 16 sections, GHS pictograms, NFPA diamond, and Thai Sarabun font.
   - Verify generated PDF for Form Sor.Or.3 contains Sections 1-6, Section 9 / 11 surveyor information, and sampling evaluation table.
