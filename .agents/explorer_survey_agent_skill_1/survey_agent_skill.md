# Survey & Architectural Design Report: `thai-safety-legal-register` Agent Skill & Tooling Integration

**Document Version:** 1.0.0  
**Author:** Agent Skill & Tooling Integration Explorer  
**Date:** 2026-08-31  
**Working Directory:** `d:\DEV\SAFAPP\.agents\explorer_survey_agent_skill_1`  
**Target Skill Location:** `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register`  
**Target Helper Location:** `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`  

---

## 1. Executive Summary

This report establishes the comprehensive architectural design, JSON data schemas, command-line interface (CLI) specifications, evaluation rule matrices, automated CAPA generation logic, and multi-agent helper integration for the new **`thai-safety-legal-register`** Agent Skill.

The skill is built upon 8 foundational Thai Royal Gazette occupational safety, health, and environment regulations:
1. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔** (OSH Act B.E. 2554)
2. **กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕** (Safety Officers & Committee B.E. 2565)
3. **กฎกระทรวง กำหนดมาตรฐานฯ สารเคมีอันตราย พ.ศ. ๒๕๕๖** (Hazardous Chemicals B.E. 2556)
4. **กฎกระทรวง กำหนดมาตรฐานฯ การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕** (Fire Safety B.E. 2555)
5. **กฎกระทรวง กำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘** (Electrical Safety B.E. 2558)
6. **กฎกระทรวง กำหนดมาตรฐานฯ เครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔** (Machinery, Cranes & Boilers B.E. 2564)
7. **กฎกระทรวง กำหนดมาตรฐานฯ ความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙** (Heat, Light & Noise B.E. 2559)
8. **กฎกระทรวง กำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓** (Occupational Health Examination B.E. 2563)

The skill enables autonomous AI agents (in Gemini and in `D:\DEV\AgentResearch`) as well as backend services in SAFAPP to:
- Fast-search statutory provisions, penalty clauses, and gazette metadata.
- Retrieve full legal requirements and applicability thresholds.
- Automatically evaluate workplace compliance against operational profiles (employee count, industry category, machinery, chemicals, electrical load, physical environmental conditions, and health risk factors).
- Generate prioritized Corrective & Preventive Action (CAPA) plans with root causes, designated Persons-in-Charge (PICs), target timelines, and compliance index calculations.

---

## 2. Analysis of Existing Skill Architecture (`thai-chemical-safety-law`)

An in-depth survey of `C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law` revealed key structural and implementation conventions:

### 2.1 File & Directory Organization
```
thai-chemical-safety-law/
├── SKILL.md                  # Frontmatter metadata (YAML) + Comprehensive Markdown manual
├── pyproject.toml            # PEP 621 packaging metadata
├── references/               # Deep-dive legal markdown documentation
│   ├── laws_summary.md
│   ├── sor_or_1_guide.md
│   ├── sor_or_3_guide.md
│   └── tlv_table_guide.md
├── scripts/                  # Executable Python scripts and offline datasets
│   ├── thai_chem_cli.py      # Main CLI tool with PEP 723 metadata & argparse
│   ├── thai_chem_law.py      # Core engine for indexing, fast search, and scoring
│   ├── thai_chem_helper.py   # Dual-mode helper module for agent research
│   ├── sds_validator.py      # Specific domain validator
│   └── data/                 # Standalone offline JSON databases
│       ├── chemicals_1516.json
│       ├── tlv_324.json
│       ├── legal_articles_2556.json
│       ├── sor_or_1_schema.json
│       └── sor_or_3_guidelines.json
└── tests/                    # Unittest test suites
    ├── run_all_tests.py
    ├── test_thai_chem_skill.py
    └── test_thai_chem_stress.py
```

### 2.2 SKILL.md Frontmatter & Structure
- **YAML Frontmatter:**
  ```yaml
  ---
  name: thai-chemical-safety-law
  description: >-
    Query Thai hazardous chemical safety regulations (กฎกระทรวงฯ ๒๕๕๖), search 1,516 regulated chemicals, lookup 324 TLV standards (TWA/STEL/Ceiling), retrieve Sor.Or. 1 (สอ.๑) SDS 16 sections, Sor.Or. 3 (สอ.๓ ๒๕๖๕) measurement guidelines, and verify SDS compliance.
  ---
  ```
- **Markdown Documentation:**
  - Executive introduction with Royal Gazette references.
  - Prerequisites (`Python >= 3.10`, `uv`, standard library).
  - Quick Start guide detailing each CLI subcommand with example input commands and exact formatted JSON outputs.
  - Mathematical formulas and evaluation decision logic.
  - Integration guide for multi-agent systems (`AgentResearch`).

### 2.3 CLI Tooling & PEP 723 Standards
- Header includes PEP 723 inline script metadata:
  ```python
  # /// script
  # requires-python = ">=3.10"
  # dependencies = []
  # ///
  ```
- Cross-platform UTF-8 stream wrapping (`sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")`) to prevent Windows `cp874` / `cp1252` encoding crashes.
- Subcommand architecture using `argparse.ArgumentParser` with `add_subparsers(dest="command", required=True)`.
- Support for CLI execution via `uv run scripts/<cli_file>.py <command> [args]` or directly via `python`.
- Standardized JSON stdout / file output via `-o / --output`.

### 2.4 Data Packaging & In-Memory Indexing
- Offline JSON files located in `scripts/data/` for zero-latency, network-independent lookup.
- In-memory dictionary hash indexing (`_cas_to_chem`, `_name_to_tlv`) to achieve sub-millisecond search and query resolution.
- Normalization helpers (`_normalize_cas`, `_clean_cas_digits`, lowercase normalization) for fuzzy and partial matching.

---

## 3. Analysis of Multi-Agent System & AgentResearch Integration

Investigation of `D:\DEV\AgentResearch` and `D:\DEV\AgentResearch\Scripts\` revealed the operational patterns for AI agent tooling:

### 3.1 Dual-Mode Invocation Pattern in Helper Modules
The helper module (`thai_chem_helper.py`) implements a resilient **Dual-Mode pattern**:
1. **Direct In-Process Import Mode:** If the skill scripts are in `sys.path` and can be imported, it instantiates the engine directly (`ThaiChemLawEngine`), executing in-memory calls with zero subprocess overhead.
2. **Subprocess CLI Fallback Mode:** If direct imports fail or paths differ, it falls back to spawning `python <cli_script_path>` with JSON argument passing and captures stdout JSON.

### 3.2 Agent Roles & Skill Consumption in AgentResearch
- **Research Agent (`01_Research.md`, `agent_research.py`):** Queries legal catalogs and compliance standards to extract regulatory requirements and generate literature/compliance matrices.
- **Writer Agent (`02_Writer.md`):** Uses structured compliance and CAPA outputs to draft audit reports, executive summaries, and legal registers.
- **QA & Advisor Agents (`03_Advisor.md`, `07_QA.md`):** Validates legal citations against official Royal Gazette issue/volume/page references.
- **Shared Memory:** Results are formatted as clean JSON and markdown tables for ingestion into `Memory/Shared/Shared_Context.json` and `Workspace/Decision/`.

---

## 4. Master Legal Catalog Architecture (8 Royal Gazette Laws)

The master legal catalog `safety_laws_catalog.json` contains full structured records for the 8 core Thai safety regulations:

| Law ID | Short Code | Official Thai Name | Royal Gazette Citation | Supervising Authority | Core Mandatory Requirements |
|---|---|---|---|---|---|
| **LAW-01** | `OSH-ACT-2554` | พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ | เล่ม ๑๒๘ ตอนที่ ๔ ก, ๑๗ ม.ค. ๒๕๕๔ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | ม.๘ บริหารจัดการความปลอดภัย, ม.๑๓ แต่งตั้ง จป., ม.๑๔ แจ้งอันตราย, ม.๑๖ ฝึกอบรมพนักงานใหม่, ม.๓๒ แผนฉุกเฉินและประเมินความเสี่ยง, ม.๓๔ รายงานอุบัติเหตุร้ายแรง |
| **LAW-02** | `MIN-JPOR-2565` | กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕ | เล่ม ๑๓๙ ตอนที่ ๔๐ ก, ๒๐ มิ.ย. ๒๕๖๕ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | แต่งตั้ง จป.หัวหน้างาน, จป.บริหาร, จป.เทคนิค, จป.เทคนิคขั้นสูง, จป.วิชาชีพ ตามบัญชี ๑-๓, แต่งตั้ง คปอ. (ลูกจ้าง $\ge 50$ คน), จัดตั้งหน่วยงานความปลอดภัย (ลูกจ้าง $\ge 200$ คน บัญชี ๒), แจ้งชื่อภายใน ๓๐ วัน |
| **LAW-03** | `MIN-CHEM-2556` | กฎกระทรวง กำหนดมาตรฐานฯ สารเคมีอันตราย พ.ศ. ๒๕๕๖ | เล่ม ๑๓๐ ตอนที่ ๙๗ ก, ๒๙ พ.ย. ๒๕๕๖ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | บัญชีสารเคมีอันตรายและ SDS สอ.๑ ครบ ๑๖ หัวข้อ, แจ้ง สอ.๑ ภายใน ๗ วัน, ตรวจวัดสารเคมีในบรรยากาศปีละ ๑ ครั้ง และส่ง สอ.๓ ภายใน ๑๕ วัน, ซ้อมแผนฉุกเฉินสารเคมีปีละ ๑ ครั้ง, ตรวจสุขภาพตามปัจจัยเสี่ยง |
| **LAW-04** | `MIN-FIRE-2555` | กฎกระทรวง กำหนดมาตรฐานฯ การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ | เล่ม ๑๒๙ ตอนที่ ๑๑ ก, ๙ ก.พ. ๒๕๕๕ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | แผนป้องกันและระงับอัคคีภัย ๕ แผน, ตรวจสอบถังดับเพลิงเดือนละ ๑ ครั้ง, ฝึกอบรมดับเพลิงขั้นต้น $\ge 40\%$ ต่อแผนก, ฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟปีละ ๑ ครั้ง, ระบบสัญญาณเตือนและไฟฉุกเฉิน |
| **LAW-05** | `MIN-ELEC-2558` | กฎกระทรวง กำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ | เล่ม ๑๓๒ ตอนที่ ๑๑ ก, ๑๙ ก.พ. ๒๕๕๘ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | ตรวจสอบและรับรองความปลอดภัยระบบไฟฟ้าประจำปีโดยวิศวกร, ต่อลงดิน (Grounding) และเครื่องตัดไฟรั่ว (RCD), แผนผังวงจรไฟฟ้า (Single Line Diagram), ป้ายเตือนอันตราย, อบรมลูกจ้างผู้ปฏิบัติงานเกี่ยวกับไฟฟ้า |
| **LAW-06** | `MIN-MACH-2564` | กฎกระทรวง กำหนดมาตรฐานฯ เครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔ | เล่ม ๑๓๘ ตอนที่ ๔๙ ก, ๒๗ ก.ค. ๒๕๖๔ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | ฝาครอบป้องกันอันตรายเครื่องจักร (Guarding) และ Safety Stop, ตรวจสอบและทดสอบปั้นจั่นประจำงวด (ปจ.๑/ปจ.๒ โดยวิศวกรเครื่องกล), อบรมผู้ปฏิบัติงาน ๔ ผู้ (ผู้บังคับ/ผู้ให้สัญญาณ/ผู้ยึดเกาะ/ผู้ควบคุม), ตรวจรับรองหม้อน้ำประจำปี (หม.๑/หม.๒) |
| **LAW-07** | `MIN-ENV-2559` | กฎกระทรวง กำหนดมาตรฐานฯ ความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ | เล่ม ๑๓๓ ตอนที่ ๙๑ ก, ๑๗ ต.ค. ๒๕๕๙ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | ตรวจวัดสภาพแวดล้อมปีละ ๑ ครั้ง (ความร้อน WBGT ไม่เกิน 30-34°C, ความส่องสว่าง Lux ตามพื้นที่, เสียงเฉลี่ย 8 ชม. ไม่เกิน 85 dBA, เสียงสูงสุด $\le 140$ dBC), รายงานผลตรวจวัด, โครงการอนุรักษ์การได้ยินเมื่อเสียง $\ge 85$ dBA |
| **LAW-08** | `MIN-HLTH-2563` | กฎกระทรวง กำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓ | เล่ม ๑๓๗ ตอนที่ ๗๙ ก, ๕ ต.ค. ๒๕๖๓ | กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) | ตรวจสุขภาพลูกจ้างปัจจัยเสี่ยงก่อนเริ่มงานภายใน ๓๐ วัน, ตรวจสุขภาพประจำปีอย่างน้อยปีละ ๑ ครั้ง โดยแพทย์อาชีวเวชศาสตร์, บันทึกสมุดสุขภาพประจำตัว, ส่งรายงานผลการตรวจสุขภาพ (แบบ จผ.๑) ภายใน ๓๐ วัน |

---

## 5. Architectural Design of `thai-safety-legal-register` Agent Skill

### 5.1 Directory Layout
```
C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\
├── SKILL.md                         # Main skill documentation & CLI manual
├── pyproject.toml                   # Project metadata
├── references/                      # Deep-dive legal references
│   ├── legal_catalog_guide.md       # Full 8 Royal Gazette laws breakdown & citations
│   ├── compliance_evaluation_guide.md # Evaluation matrices, scoring & risk weights
│   └── capa_action_plan_guide.md    # CAPA lifecycle, root causes & timelines
├── scripts/                         # Python scripts & data
│   ├── thai_safety_legal_cli.py     # PEP 723 CLI Tool (search, get-law, evaluate, capa-summary)
│   ├── thai_safety_legal_engine.py  # Core indexing, evaluation engine & CAPA generator
│   ├── thai_safety_legal_helper.py  # Helper module (dual-mode in-process/subprocess)
│   └── data/                        # Offline standalone JSON data files
│       ├── safety_laws_catalog.json # Full catalog of 8 laws & requirements
│       ├── compliance_criteria.json # Workplace evaluation logic rules
│       ├── capa_templates.json      # CAPA templates & corrective actions
│       └── sample_workplace_profile.json # Sample profile for instant testing
└── tests/                           # Unit tests
    ├── run_all_tests.py             # Test suite runner
    └── test_thai_safety_legal_skill.py # Comprehensive unit tests
```

### 5.2 `SKILL.md` Frontmatter Specification
```yaml
---
name: thai-safety-legal-register
description: >-
  Search Thai occupational safety and health laws (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวง จป./คปอ. ๒๕๖๕, สารเคมี ๒๕๕๖, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, เครื่องจักร/ปั้นจั่น/หม้อน้ำ ๒๕๖๔, สิ่งแวดล้อม แสง/เสียง/ความร้อน ๒๕๕๙, ตรวจสุขภาพ ๒๕๖๓), retrieve Royal Gazette statutory articles, evaluate workplace legal compliance, and generate automated CAPA action plans.
---
```

### 5.3 CLI Interface Specification (`thai_safety_legal_cli.py`)

The CLI script implements 4 commands with strict arguments and rich JSON responses:

#### Subcommand 1: `search`
Searches laws, articles, and requirements by keyword, category, or Royal Gazette citation.
- **CLI Arguments:**
  - `-q`, `--query` (string, required): Search query (e.g. `"จป.วิชาชีพ"`, `"ดับเพลิง"`, `"หม้อน้ำ"`, `"85 dBA"`, `"สอ.๑"`, `"LAW-02"`).
  - `-c`, `--category` (string, optional, default: `"all"`): Filter by category (`all`, `act_2554`, `jpor_cpo_2565`, `chemical_2556`, `fire_2555`, `electrical_2558`, `machinery_crane_boiler_2564`, `environment_2559`, `health_check_2563`).
  - `-l`, `--limit` (int, optional, default: `10`): Maximum results to return.
  - `-o`, `--output` (string, optional): Output JSON file path.

**Example Invocation:**
```bash
uv run scripts/thai_safety_legal_cli.py search -q "ตรวจรับรองไฟฟ้าประจำปี" --limit 5
```

**JSON Output Schema:**
```json
{
  "status": "success",
  "query": "ตรวจรับรองไฟฟ้าประจำปี",
  "category": "all",
  "total_found": 1,
  "results": [
    {
      "law_id": "LAW-05",
      "law_code": "MIN-ELEC-2558",
      "title_th": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘",
      "category": "electrical",
      "req_id": "LAW-05-REQ-03",
      "article_no": "ข้อ ๑๒",
      "requirement_title": "การตรวจสอบและรับรองความปลอดภัยระบบไฟฟ้าประจำปี",
      "requirement_summary": "นายจ้างต้องจัดให้มีการตรวจสอบและรับรองความปลอดภัยของระบบไฟฟ้าและบริภัณฑ์ไฟฟ้าในสถานประกอบกิจการอย่างน้อยปีละหนึ่งครั้ง โดยวิศวกรไฟฟ้าที่มีใบประกอบวิชาชีพและบันทึกผลการตรวจสอบเก็บไว้พร้อมให้พนักงานตรวจความปลอดภัยตรวจสอบ",
      "gazette_reference": {
        "volume": "๑๓๒",
        "issue": "๑๑ ก",
        "page": "๑-๑๐",
        "publication_date_th": "๑๙ กุมภาพันธ์ ๒๕๕๘",
        "gazette_url": "http://www.ratchakitcha.soc.go.th/DATA/PDF/2558/A/011/1.PDF"
      },
      "penalty_clause": "จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (พ.ร.บ. ความปลอดภัยฯ ม.๕๓)",
      "score": 98
    }
  ]
}
```

---

#### Subcommand 2: `get-law`
Retrieves the comprehensive text, statutory provisions, applicability thresholds, penalties, and required evidence for a specific law or requirement.
- **CLI Arguments:**
  - `-i`, `--id` (string, required): Law ID (e.g. `LAW-01` .. `LAW-08` or shortcode `jpor_2565`, `fire_2555`, `chem_2556`).
  - `-s`, `--section` (string, optional): Specific article or requirement ID (e.g. `"ข้อ ๑๒"`, `"ม.๑๓"`, `"LAW-02-REQ-05"`).
  - `-o`, `--output` (string, optional): Output JSON file path.

**Example Invocation:**
```bash
uv run scripts/thai_safety_legal_cli.py get-law -i LAW-02 -s "ข้อ ๑๖"
```

**JSON Output Schema:**
```json
{
  "status": "success",
  "law": {
    "law_id": "LAW-02",
    "law_code": "MIN-JPOR-2565",
    "title_th": "กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลเพื่อดำเนินการด้านความปลอดภัยในสถานประกอบกิจการ พ.ศ. ๒๕๖๕",
    "title_en": "Ministerial Regulation on Safety Officers, Personnel, Department or Committee in Workplace B.E. 2565",
    "gazette": {
      "volume": "๑๓๙",
      "issue": "๔๐ ก",
      "page": "๑-๒๔",
      "date_th": "๒๐ มิถุนายน ๒๕๖๕",
      "effective_date_th": "๒๒ มิถุนายน ๒๕๖๕"
    },
    "regulator": "กรมสวัสดิการและคุ้มครองแรงงาน (DLPW)",
    "target_section": {
      "req_id": "LAW-02-REQ-05",
      "article_no": "ข้อ ๑๖",
      "title": "การแต่งตั้งเจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ)",
      "criteria": "สถานประกอบกิจการตามบัญชี ๑ ทุกจำนวนลูกจ้าง, บัญชี ๒ ลูกจ้างตั้งแต่ ๖๔ คนขึ้นไป, หรือบัญชี ๓ ลูกจ้างตั้งแต่ ๒๐๐ คนขึ้นไป",
      "full_text": "ให้นายจ้างจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพประจำสถานประกอบกิจการเต็มเวลา เพื่อปฏิบัติหน้าที่ด้านความปลอดภัย...",
      "mandate": "แต่งตั้ง จป.วิชาชีพ ทำงานเต็มเวลา และแจ้งชื่อต่ออธิบดีภายใน ๓๐ วัน",
      "evidence_needed": "สำเนาคำสั่งแต่งตั้ง จป.วิชาชีพ, เอกสารแสดงคุณวุฒิ/ใบรับรอง, แบบแจ้งการแต่งตั้ง จป. (แบบ จป.ว)",
      "penalty": "จำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (พ.ร.บ. ม.๖๖)"
    }
  }
}
```

---

#### Subcommand 3: `evaluate`
Performs an automated, rule-based legal compliance assessment matching a workplace operational profile against the 8 safety regulations.
- **CLI Arguments:**
  - `-p`, `--profile` (string, optional): File path to workplace profile JSON.
  - `-d`, `--data` (string, optional): Direct JSON string containing workplace profile.
  - `-o`, `--output` (string, optional): Output JSON file path.

**Workplace Profile Input Schema:**
```json
{
  "company_name": "Apex Manufacturing Co., Ltd.",
  "industry_type": "Automotive Parts Manufacturing",
  "business_category_annex": 2,
  "employee_count": 85,
  "has_hazardous_chemicals": true,
  "hazardous_chemicals_list": ["Toluene", "Trichloroethylene", "Sulfuric Acid"],
  "has_cranes": true,
  "crane_count": 3,
  "has_boilers": false,
  "boiler_count": 0,
  "has_high_voltage_electrical": true,
  "electrical_transformer_kva": 500,
  "has_noise_exceed_85dba": true,
  "has_heat_wbgt_risk": false,
  "has_occupational_health_risks": true,
  "risk_factor_types": ["Chemical", "Noise"],
  "current_practices": {
    "has_jpor_supervisory": true,
    "has_jpor_executive": true,
    "has_jpor_professional": false,
    "has_safety_committee": true,
    "fire_drill_conducted_last_12m": true,
    "basic_fire_trained_percent": 45.0,
    "electrical_inspection_conducted_last_12m": false,
    "crane_pj2_inspected_last_interval": false,
    "chem_measurement_sor_or_3_conducted_last_12m": true,
    "env_noise_measurement_conducted_last_12m": true,
    "health_check_conducted_last_12m": true,
    "health_check_report_submitted_jphor1": false
  }
}
```

**JSON Output Schema (Evaluation Assessment):**
```json
{
  "status": "success",
  "evaluation_timestamp": "2026-08-31T22:15:10Z",
  "company_name": "Apex Manufacturing Co., Ltd.",
  "workplace_summary": {
    "industry_type": "Automotive Parts Manufacturing (Annex 2)",
    "employee_count": 85,
    "applicable_laws_count": 7,
    "total_applicable_requirements": 24
  },
  "compliance_summary": {
    "total_requirements": 24,
    "compliant_count": 18,
    "non_compliant_count": 4,
    "in_progress_count": 2,
    "not_applicable_count": 6,
    "compliance_percentage": 75.0,
    "risk_weighted_score": 71.5,
    "compliance_grade": "C - NEEDS_IMPROVEMENT",
    "critical_gaps_count": 2
  },
  "detailed_evaluations": [
    {
      "req_id": "LAW-02-REQ-05",
      "law_code": "MIN-JPOR-2565",
      "law_name": "กฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕",
      "requirement_title": "การแต่งตั้งเจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ)",
      "legal_article": "ข้อ ๑๖",
      "applicability": "APPLICABLE (Annex 2 with 85 employees >= 64)",
      "status": "NON_COMPLIANT",
      "current_practice": "ยังไม่มีการแต่งตั้ง จป.วิชาชีพ ประจำสถานประกอบการ",
      "gap_description": "สถานประกอบการจัดอยู่ในบัญชี ๒ มีลูกจ้าง ๘๕ คน (เกิน ๖๔ คน) กฎหมายบังคับให้ต้องมี จป.วิชาชีพ เต็มเวลาอย่างน้อย ๑ คน",
      "risk_level": "CRITICAL",
      "penalty_risk": "จำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท (พ.ร.บ. ม.๖๖)",
      "required_action": "สรรหาและแต่งตั้ง จป.วิชาชีพ เต็มเวลา พร้อมแจ้งชื่อต่อ สสค. ภายใน ๓๐ วัน"
    },
    {
      "req_id": "LAW-05-REQ-03",
      "law_code": "MIN-ELEC-2558",
      "law_name": "กฎกระทรวง ไฟฟ้า พ.ศ. ๒๕๕๘",
      "requirement_title": "การตรวจสอบและรับรองความปลอดภัยระบบไฟฟ้าประจำปี",
      "legal_article": "ข้อ ๑๒",
      "applicability": "APPLICABLE (High voltage 500 kVA system present)",
      "status": "NON_COMPLIANT",
      "current_practice": "ยังไม่ได้ทำการตรวจสอบระบบไฟฟ้าในรอบ ๑๒ เดือนที่ผ่านมา",
      "gap_description": "ระบบไฟฟ้า 500 kVA ยังไม่ได้รับการตรวจสอบและรับรองความปลอดภัยประจำปีโดยวิศวกรไฟฟ้าที่มีใบประกอบวิชาชีพ",
      "risk_level": "CRITICAL",
      "penalty_risk": "จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท (พ.ร.บ. ม.๕๓)",
      "required_action": "ว่าจ้างวิศวกรไฟฟ้าเข้าตรวจสอบ รับรองความปลอดภัย และจัดทำรายงานผลการตรวจสอบ"
    },
    {
      "req_id": "LAW-06-REQ-04",
      "law_code": "MIN-MACH-2564",
      "law_name": "กฎกระทรวง เครื่องจักร ปั้นจั่น หม้อน้ำ พ.ศ. ๒๕๖๔",
      "requirement_title": "การตรวจสอบและทดสอบปั้นจั่นตามระยะเวลา (แบบ ปจ.๑ / ปจ.๒)",
      "legal_article": "ข้อ ๖๙",
      "applicability": "APPLICABLE (3 cranes in operation)",
      "status": "NON_COMPLIANT",
      "current_practice": "ปั้นจั่น 3 ตัวยังไม่ได้รับการทดสอบน้ำหนักและรับรองโดยวิศวกรเครื่องกลตามกำหนด",
      "gap_description": "ปั้นจั่นเกินกำหนดรอบการทดสอบประจำงวดโดยวิศวกรเครื่องกล",
      "risk_level": "HIGH",
      "penalty_risk": "จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท (พ.ร.บ. ม.๕๓)",
      "required_action": "จัดให้วิศวกรเครื่องกลทดสอบการรับน้ำหนัก (Load Test) และออกเอกสารรับรองแบบ ปจ.๑/ปจ.๒"
    },
    {
      "req_id": "LAW-08-REQ-05",
      "law_code": "MIN-HLTH-2563",
      "law_name": "กฎกระทรวง ตรวจสุขภาพตามปัจจัยเสี่ยง พ.ศ. ๒๕๖๓",
      "requirement_title": "การส่งรายงานผลการตรวจสุขภาพลูกจ้าง (แบบ จผ.๑)",
      "legal_article": "ข้อ ๑๐",
      "applicability": "APPLICABLE (Employees exposed to chemicals and noise)",
      "status": "NON_COMPLIANT",
      "current_practice": "ตรวจสุขภาพแล้วแต่ยังไม่ได้ส่งแบบ จผ.๑ แก่เจ้าหน้าที่",
      "gap_description": "ตรวจสุขภาพลูกจ้างเสร็จสิ้นแล้วแต่ยังไม่ได้จัดส่งแบบ จผ.๑ ต่อพนักงานตรวจความปลอดภัยภายใน ๓๐ วัน",
      "risk_level": "MEDIUM",
      "penalty_risk": "ปรับไม่เกิน ๒๐,๐๐๐ บาท (พ.ร.บ. ม.๖๘)",
      "required_action": "รวบรวมสรุปผลจากแพทย์อาชีวเวชศาสตร์ กรอกแบบ จผ.๑ และยื่นต่อสำนักงานสวัสดิการและคุ้มครองแรงงาน"
    }
  ]
}
```

---

#### Subcommand 4: `capa-summary`
Aggregates non-compliant and in-progress items from an evaluation result or raw requirement list and outputs prioritized, actionable Corrective & Preventive Action (CAPA) plans with root causes, standardized counter-measures, designated PICs, target duration days, and verification criteria.
- **CLI Arguments:**
  - `-e`, `--eval-file` (string, optional): Path to evaluation result JSON file.
  - `-i`, `--items` (string, optional): Comma-separated list of non-compliant requirement IDs (e.g. `"LAW-02-REQ-05,LAW-05-REQ-03,LAW-06-REQ-04"`).
  - `-o`, `--output` (string, optional): Output JSON file path.

**Example Invocation:**
```bash
uv run scripts/thai_safety_legal_cli.py capa-summary -i "LAW-02-REQ-05,LAW-05-REQ-03,LAW-06-REQ-04,LAW-08-REQ-05"
```

**JSON Output Schema (CAPA Action Plan):**
```json
{
  "status": "success",
  "generated_at": "2026-08-31T22:15:10Z",
  "capa_summary": {
    "total_capa_items": 4,
    "critical_priority_count": 2,
    "high_priority_count": 1,
    "medium_priority_count": 1,
    "estimated_total_remediation_days": 45
  },
  "capa_plans": [
    {
      "capa_id": "CAPA-2026-001",
      "req_id": "LAW-02-REQ-05",
      "priority": "CRITICAL",
      "law_code": "MIN-JPOR-2565",
      "law_name": "กฎกระทรวง จป./คปอ. ๒๕๖๕",
      "requirement": "การแต่งตั้ง จป.วิชาชีพ ประจำสถานประกอบกิจการเต็มเวลา",
      "legal_article": "ข้อ ๑๖",
      "finding": "สถานประกอบกิจการบัญชี ๒ มีลูกจ้าง ๘๕ คน ยังไม่มีการแต่งตั้ง จป.วิชาชีพ",
      "root_cause": "ขาดการติดตามการเปลี่ยนแปลงจำนวนลูกจ้างที่เพิ่มขึ้นเกินเกณฑ์ ๖๔ คน และไม่มีแผนอัตรากำลัง จป.วิชาชีพ",
      "corrective_action": "เปิดรับสมัคร/จัดจ้าง จป.วิชาชีพ เต็มเวลา หรือส่งเจ้าหน้าที่เข้าอบรมหลักสูตรเทียบคุณวุฒิ และออกคำสั่งแต่งตั้งอย่างเป็นทางการ",
      "preventive_action": "กำหนดขั้นตอนทบทวนจำนวนลูกจ้างทุกไตรมาสร่วมกับฝ่ายบุคคล (HR) เพื่อรองรับการปฏิบัติตามเกณฑ์กฎหมาย จป.",
      "person_in_charge": "ผู้จัดการฝ่ายทรัพยากรบุคคล (HR Manager) / กรรมการผู้จัดการ",
      "target_duration_days": 30,
      "target_deadline": "2026-09-30",
      "verification_method": "ตรวจสอบคำสั่งแต่งตั้ง จป.วิชาชีพ และใบเสร็จ/หลักฐานการยื่นแบบ จป.ว ต่อกรมสวัสดิการและคุ้มครองแรงงาน",
      "evidence_needed": "แบบ จป.ว ที่ประทับตรารับเรื่องจาก สสค., สำเนาวุฒิการศึกษา/ใบรับรอง จป.วิชาชีพ",
      "status": "OPEN"
    },
    {
      "capa_id": "CAPA-2026-002",
      "req_id": "LAW-05-REQ-03",
      "priority": "CRITICAL",
      "law_code": "MIN-ELEC-2558",
      "law_name": "กฎกระทรวง ไฟฟ้า ๒๕๕๘",
      "requirement": "การตรวจสอบและรับรองความปลอดภัยระบบไฟฟ้าประจำปี",
      "legal_article": "ข้อ ๑๒",
      "finding": "ระบบไฟฟ้าหม้อแปลง 500 kVA ขาดการตรวจสอบและรับรองประจำปีในรอบ ๑๒ เดือน",
      "root_cause": "ไม่มีระบบปฏิทินแจ้งเตือนกำหนดรอบการตรวจสอบทางวิศวกรรมประจำปี (Annual PM Schedule)",
      "corrective_action": "ประสานงานว่าจ้างวิศวกรไฟฟ้าที่มีใบ กว. ดำเนินการตรวจสอบระบบไฟฟ้า หม้อแปลง ตู้ MDB การต่อลงดิน และออกเอกสารรับรอง",
      "preventive_action": "ขึ้นทะเบียนระบบไฟฟ้าลงในระบบ Preventive Maintenance (PM) และตั้งเตือนล่วงหน้า ๖๐ วันก่อนครบกำหนดรอบปี",
      "person_in_charge": "ผู้จัดการฝ่ายวิศวกรรมและซ่อมบำรุง (Engineering Manager) / จป.วิชาชีพ",
      "target_duration_days": 15,
      "target_deadline": "2026-09-15",
      "verification_method": "ตรวจสอบเล่มรายงานผลการตรวจสอบระบบไฟฟ้าและใบ กว. ของวิศวกรผู้รับรอง",
      "evidence_needed": "รายงานการตรวจรับรองความปลอดภัยระบบไฟฟ้าประจำปี พร้อมลงนามโดยวิศวกรไฟฟ้าสามัญ/วุฒิ",
      "status": "OPEN"
    },
    {
      "capa_id": "CAPA-2026-003",
      "req_id": "LAW-06-REQ-04",
      "priority": "HIGH",
      "law_code": "MIN-MACH-2564",
      "law_name": "กฎกระทรวง เครื่องจักร ปั้นจั่น หม้อน้ำ ๒๕๖๔",
      "requirement": "การตรวจสอบและทดสอบปั้นจั่นตามระยะเวลา (แบบ ปจ.๑ / ปจ.๒)",
      "legal_article": "ข้อ ๖๙",
      "finding": "ปั้นจั่น 3 ตัวยังไม่ได้รับการทดสอบพิกัดยกและรับรองความปลอดภัยประจำงวด",
      "root_cause": "ขาดการจัดทำทะเบียนเครื่องจักรและปั้นจั่นเพื่อควบคุมรอบการทดสอบตามพิกัดน้ำหนัก",
      "corrective_action": "จัดให้วิศวกรเครื่องกลเข้าทดสอบ Load Test และออกเอกสารรับรองความปลอดภัยแบบ ปจ.๑ หรือ ปจ.๒ ตามขนาดพิกัดยก",
      "preventive_action": "จัดทำป้ายแสดงสถานะการตรวจรับรอง (Inspection Tag) ติดที่ตัวปั้นจั่น และนำเข้าระบบ Safety Inspection Calendar",
      "person_in_charge": "หัวหน้าแผนกซ่อมบำรุง (Maintenance Supervisor) / วิศวกรเครื่องกล",
      "target_duration_days": 20,
      "target_deadline": "2026-09-20",
      "verification_method": "ตรวจสอบแบบ ปจ.๑ / ปจ.๒ ที่ลงนามโดยวิศวกรเครื่องกลและติด Tag วันหมดอายุบนปั้นจั่น",
      "evidence_needed": "เอกสารรายงานการทดสอบปั้นจั่น (แบบ ปจ.๑/ปจ.๒) ฉบับสมบูรณ์",
      "status": "OPEN"
    },
    {
      "capa_id": "CAPA-2026-004",
      "req_id": "LAW-08-REQ-05",
      "priority": "MEDIUM",
      "law_code": "MIN-HLTH-2563",
      "law_name": "กฎกระทรวง ตรวจสุขภาพตามปัจจัยเสี่ยง ๒๕๖๓",
      "requirement": "การส่งรายงานผลการตรวจสุขภาพลูกจ้างตามปัจจัยเสี่ยง (แบบ จผ.๑)",
      "legal_article": "ข้อ ๑๐",
      "finding": "ตรวจสุขภาพลูกจ้างแล้วเสร็จแต่ยังไม่ได้ยื่นแบบ จผ.๑ ภายใน ๓๐ วัน",
      "root_cause": "เจ้าหน้าที่เข้าใจผิดว่าเก็บเล่มรายงานไว้ที่สถานประกอบการเพียงอย่างเดียวโดยไม่ต้องส่งราชการ",
      "corrective_action": "จัดทำแบบรายงานสรุปผลการตรวจสุขภาพลูกจ้าง (แบบ จผ.๑) แนบสำเนาใบรับรองแพทย์ และยื่นต่อ สสค. พื้นที่",
      "preventive_action": "จัดทำ Standard Operating Procedure (SOP) งานตรวจสุขภาพตามปัจจัยเสี่ยง ระบุ Timeline ส่ง จผ.๑ ชัดเจน",
      "person_in_charge": "พยาบาลประจำห้องพยาบาล / จป.วิชาชีพ",
      "target_duration_days": 10,
      "target_deadline": "2026-09-10",
      "verification_method": "ตรวจสอบหลักฐานการยื่นแบบ จผ.๑ หรือหนังสือตอบรับจากสำนักงานสวัสดิการและคุ้มครองแรงงาน",
      "evidence_needed": "แบบ จผ.๑ ประทับตรารับเรื่อง หรือใบรับเอกสารทางระบบ e-Service ของกรมฯ",
      "status": "OPEN"
    }
  ]
}
```

---

## 6. Architecture & Implementation of `ThaiSafetyLegalHelper` for AgentResearch

The helper script at `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py` provides high-level programmatic and CLI wrapper access tailored for research, writer, advisor, and QA agents:

```python
"""
==============================================================================
 Thai Safety Legal Register Helper for AgentResearch Multi-Agent System
 Module: D:\\DEV\\AgentResearch\\Scripts\\thai_safety_legal_helper.py
 Connects to Agent Skill: thai-safety-legal-register
 Conforming to 8 Thai Royal Gazette Safety Regulations
==============================================================================
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional, Union

# Skill directory determination
SKILL_DIR = os.path.expanduser(r"~\.gemini\config\skills\thai-safety-legal-register")
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_safety_legal_cli.py")

# Ensure script dir in sys.path
if SCRIPTS_DIR not in sys.path and os.path.exists(SCRIPTS_DIR):
    sys.path.insert(0, SCRIPTS_DIR)

try:
    from thai_safety_legal_engine import ThaiSafetyLegalEngine
    _HAS_DIRECT_ENGINE = True
except ImportError:
    _HAS_DIRECT_ENGINE = False


class ThaiSafetyLegalHelper:
    """Helper class for AgentResearch system to query Thai safety laws and evaluate compliance."""

    def __init__(self, skill_dir: str = SKILL_DIR, prefer_direct: bool = True):
        self.skill_dir = skill_dir
        self.cli_script = os.path.join(skill_dir, "scripts", "thai_safety_legal_cli.py")
        self.data_dir = os.path.join(skill_dir, "scripts", "data")
        self.prefer_direct = prefer_direct
        self._engine: Optional[Any] = None

        if self.prefer_direct and _HAS_DIRECT_ENGINE:
            try:
                self._engine = ThaiSafetyLegalEngine(data_dir=self.data_dir)
            except Exception:
                self._engine = None

    def _run_cli(self, args: List[str]) -> Dict[str, Any]:
        """Execute CLI command via subprocess with UTF-8 encoding."""
        if os.path.exists(self.cli_script):
            cmd = [sys.executable, self.cli_script] + args
            try:
                res = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    check=True
                )
                return json.loads(res.stdout)
            except Exception as e:
                return {
                    "status": "error",
                    "message": f"CLI execution failed: {str(e)}",
                    "cmd": cmd
                }
        return {"status": "error", "message": f"CLI script not found at {self.cli_script}"}

    def search_law(self, query: str, category: str = "all", limit: int = 10) -> Dict[str, Any]:
        """Search legal provisions across 8 safety regulations."""
        if self._engine:
            return self._engine.search_laws(query=query, category=category, limit=limit)
        return self._run_cli(["search", "-q", query, "-c", category, "-l", str(limit)])

    def get_law(self, law_id: str, section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve full text, gazette citations and statutory details for a law."""
        if self._engine:
            return self._engine.get_law(law_id=law_id, section=section)
        args = ["get-law", "-i", law_id]
        if section:
            args += ["-s", section]
        return self._run_cli(args)

    def evaluate_workplace(self, workplace_profile: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """Evaluate workplace safety compliance status based on profile data."""
        if isinstance(workplace_profile, str) and os.path.exists(workplace_profile):
            with open(workplace_profile, "r", encoding="utf-8") as f:
                profile_dict = json.load(f)
        elif isinstance(workplace_profile, str):
            profile_dict = json.loads(workplace_profile)
        else:
            profile_dict = workplace_profile

        if self._engine:
            return self._engine.evaluate_compliance(profile_dict)
        return self._run_cli(["evaluate", "-d", json.dumps(profile_dict, ensure_ascii=False)])

    def generate_capa_summary(
        self,
        eval_result_or_file: Optional[Union[Dict[str, Any], str]] = None,
        non_compliant_item_ids: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Generate prioritized CAPA action plans for non-compliant requirements."""
        if self._engine:
            return self._engine.generate_capa(
                eval_data=eval_result_or_file if isinstance(eval_result_or_file, dict) else None,
                item_ids=non_compliant_item_ids
            )

        if isinstance(eval_result_or_file, str) and os.path.exists(eval_result_or_file):
            return self._run_cli(["capa-summary", "-e", eval_result_or_file])
        elif non_compliant_item_ids:
            return self._run_cli(["capa-summary", "-i", ",".join(non_compliant_item_ids)])
        elif isinstance(eval_result_or_file, dict):
            return self._engine.generate_capa(eval_data=eval_result_or_file) if self._engine else {
                "status": "error", "message": "Engine required for raw dict evaluation CAPA"
            }
        return {"status": "error", "message": "Missing evaluation data or item IDs"}
```

---

## 7. Compliance Evaluation Rules & Mathematical Scoring Matrix

### 7.1 Compliance Index Calculation
The overall compliance index $C_{\text{index}}$ is calculated using both simple percentage and risk-weighted score:

$$C_{\text{index}} = \left( \frac{N_{\text{compliant}} + (0.5 \times N_{\text{in\_progress}})}{N_{\text{applicable}}} \right) \times 100\%$$

Where:
- $N_{\text{applicable}} = N_{\text{total}} - N_{\text{not\_applicable}}$
- $N_{\text{compliant}}$: Number of fully compliant items (Score 1.0)
- $N_{\text{in\_progress}}$: Number of items with initiated remediation (Score 0.5)
- $N_{\text{non\_compliant}}$: Number of non-compliant items (Score 0.0)

### 7.2 Risk-Weighted Compliance Score
To reflect critical statutory liability (imprisonment / severe fines):

$$S_{\text{weighted}} = \left( \frac{\sum_{i=1}^{n} w_i \times s_i}{\sum_{i=1}^{n} w_i} \right) \times 100\%$$

| Risk Level | Weight ($w_i$) | Statutory Impact Criteria |
|---|---|---|
| **CRITICAL** | 4.0 | Penalty includes imprisonment $\ge 6$ months, imminent danger to life, direct shutdown order. |
| **HIGH** | 3.0 | Penalty fine $\ge 200,000$ THB, major equipment safety (cranes, boilers, high voltage). |
| **MEDIUM** | 2.0 | Statutory reporting deadlines (จผ.๑, สอ.๓), documentation, periodic drills. |
| **LOW** | 1.0 | Minor recordkeeping, warning signs, internal communication. |

### 7.3 Compliance Grading Scale
- **Grade A (Excellent):** $C_{\text{index}} \ge 95\%$ and 0 Critical Gaps
- **Grade B (Good):** $85\% \le C_{\text{index}} < 95\%$ and 0 Critical Gaps
- **Grade C (Needs Improvement):** $70\% \le C_{\text{index}} < 85\%$ or $\le 2$ Critical Gaps
- **Grade D (Critical Non-Compliance):** $C_{\text{index}} < 70\%$ or $> 2$ Critical Gaps

---

## 8. Test Plan & Quality Assurance Strategy

The test suite in `tests/test_thai_safety_legal_skill.py` verifies all functional requirements and edge cases:

```
Test Cases (12 Automated Tests):
  [x] test_01_catalog_integrity: Verify all 8 laws exist with Gazette metadata and >= 40 total requirements.
  [x] test_02_search_by_keyword: Search Thai/English terms ('จป.วิชาชีพ', 'ดับเพลิง', 'ปั้นจั่น', 'หม้อน้ำ', 'WBGT').
  [x] test_03_search_by_category: Test category filtering for electrical, chemical, fire, and environment.
  [x] test_04_get_law_by_id: Retrieve LAW-01 through LAW-08 with valid section details.
  [x] test_05_evaluate_small_enterprise: Profile with 15 employees in Annex 3 (verify minimal applicable requirements).
  [x] test_06_evaluate_large_chemical_manufacturing: Profile with 250 employees, chemical storage, cranes, boilers (verify all 8 laws applicable).
  [x] test_07_evaluate_scoring_accuracy: Verify 100% compliant profile produces Grade A; mixed profile computes exact formula.
  [x] test_08_capa_generation_from_eval: Test automated CAPA creation from evaluation output.
  [x] test_09_capa_generation_from_ids: Test CAPA generation with comma-separated IDs.
  [x] test_10_helper_dual_mode: Verify ThaiSafetyLegalHelper functions under both direct and CLI fallback modes.
  [x] test_11_invalid_inputs_handling: Ensure graceful error messages on empty queries, malformed JSON, or non-existent IDs.
  [x] test_12_utf8_thai_encoding: Stress test Thai characters across Windows console streams.
```

---

## 9. Deliverables Matrix for Next Phases

| Component | Target Location | Implementation Responsible |
|---|---|---|
| **Skill Metadata & Doc** | `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\SKILL.md` | Skill Builder Agent |
| **Skill pyproject.toml** | `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\pyproject.toml` | Skill Builder Agent |
| **Master Legal Catalog** | `...\thai-safety-legal-register\scripts\data\safety_laws_catalog.json` | Skill Builder Agent |
| **Evaluation Rules** | `...\thai-safety-legal-register\scripts\data\compliance_criteria.json` | Skill Builder Agent |
| **CAPA Templates** | `...\thai-safety-legal-register\scripts\data\capa_templates.json` | Skill Builder Agent |
| **Core Engine Script** | `...\thai-safety-legal-register\scripts\thai_safety_legal_engine.py` | Skill Builder Agent |
| **CLI Script (PEP 723)** | `...\thai-safety-legal-register\scripts\thai_safety_legal_cli.py` | Skill Builder Agent |
| **Skill Helper Script** | `...\thai-safety-legal-register\scripts\thai_safety_legal_helper.py` | Skill Builder Agent |
| **AgentResearch Helper**| `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py` | Integration Agent |
| **Skill Unit Tests** | `...\thai-safety-legal-register\tests\test_thai_safety_legal_skill.py` | Skill Builder Agent |
| **SAFAPP Models & UI** | `d:\DEV\SAFAPP\lib\features\legal\...` | SAFAPP Developer Agent |

---

## 10. Conclusion & Recommendations

1. **Self-Contained Data Packaging:** Embedding the full 8 Royal Gazette safety catalog and evaluation matrices directly within `scripts/data/` guarantees 100% offline reliability, sub-millisecond query latency, and zero runtime dependencies.
2. **Unified Data Schema:** The JSON structure designed here directly mirrors SAFAPP's Dart models (`LegalItemModel`, `LegalComplianceAssessmentModel`, `LegalCapaModel`), enabling effortless data synchronization between the AI agent layer and the mobile/desktop app.
3. **Cross-Platform Compatibility:** With PEP 723 metadata, standard library dependencies, and strict UTF-8 text wrappers, the skill executes reliably across Windows, Linux, and macOS environments via `uv run` or standard `python`.
