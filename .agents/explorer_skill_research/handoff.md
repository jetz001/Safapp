# Handoff Report: Agent Skill 'thai-chemical-safety-law' & AgentResearch Integration Design

**Author**: Agent Skill & Research Explorer  
**Date**: 2026-08-31T20:44:00+07:00  
**Target Path**: `d:\DEV\SAFAPP\.agents\explorer_skill_research\handoff.md`  
**Target Parent Agent**: Orchestrator (Conversation ID: `24f757fa-f31c-43d6-9b79-a6bad51e1b38`)

---

## 1. Observation

### 1.1 Existing Agent Skill Formats in Environment
1. Inspected `C:\Users\jetsa\.gemini\config\plugins\science\skills\pubchem_database\SKILL.md` (lines 1–25) and `scripts/pubchem_api.py` (lines 22–28):
   - **SKILL.md** uses YAML frontmatter with `name` and `description` (multiline formatted).
   - Python CLI scripts use **PEP 723 Inline Script Metadata** (`# /// script ... # ///`) declaring `requires-python` and dependencies, making them executable via `uv run scripts/<script>.py <command> [options]`.
   - CLI scripts strictly return structured JSON outputs to stdout or write to `--output <path>.json`.
2. Inspected `C:\Users\jetsa\.gemini\config\skills\electron-ai-benchmarker\SKILL.md` (lines 1–20):
   - Confirms the canonical directory layout: `SKILL.md`, `scripts/`, `references/`, and standard CLI invocation examples.

### 1.2 AgentResearch Architecture (`D:\DEV\AgentResearch`)
1. Inspected `D:\DEV\AgentResearch\flowMain.md` (lines 1–50) and `Scripts\main.py` (lines 80–100):
   - `AgentResearch` is a multi-agent AI research pipeline consisting of:
     - `Orchestrator` (`Agent/00_Orchestrator.md`, `Scripts/main.py`)
     - `Research Agent` (`Agent/01_Research.md`, `Scripts/agent_research.py`)
     - `Writer Agent` (`Agent/02_Writer.md`, `Scripts/agent_writer.py`)
     - `Advisor Agent` (`Agent/03_Advisor.md`, `Scripts/agent_advisor.py`)
     - `QA Agent` (`Agent/07_QA.md`, `Scripts/agent_qa.py`)
     - `IT Agent` (`Agent/05_IT.md`, `Scripts/agent_it.py`)
2. Inspected `Agent/01_Research.md` (lines 14–80):
   - Research skills are registered as `SK-RES-01` to `SK-RES-08` (Literature Search, Paper Screening, Data Extraction, Gap Analysis, Shared Context Management).
   - Storage conventions: `Docs/`, `Data/`, `References/`, `Output/reports/`, and `Memory/Shared/Shared_Context.json`.
3. Inspected `Scripts/doc_helper.py` and `Scripts/llm_helper.py`:
   - `DocHelper` provides vector database search via ChromaDB / Embed4All and fallback file-based keyword search.
   - `llm_helper.py` handles multi-provider LLM calls (Ollama, OpenAI, Groq, Gemini, Together, DeepSeek, Cerebras).

### 1.3 SAFAPP Environment & Legal Standards
1. Inspected `d:\DEV\SAFAPP\pubspec.yaml` and `lib/core/database/database_helper.dart`:
   - SQLite DB `safety_superapp_v1.db` via `sqflite_common_ffi` (Windows desktop FFI support enabled).
   - `lib/features/chemicals/presentation/pages/chemicals_page.dart` currently contains placeholder scaffold UI.
2. Legal references mandate compliance with:
   - **กฎกระทรวงฯ ๒๕๕๖**: Ministerial Regulation on Safety, Occupational Health and Working Environment regarding Hazardous Chemicals B.E. 2556.
   - **ประกาศบัญชีรายชื่อสารเคมีอันตราย ๑,๕๑๖ รายการ**: 1,516 regulated hazardous substances.
   - **ประกาศขีดจำกัดความเข้มข้นสารเคมีอันตราย (TLV) ๓๒๔ รายการ**: 324 substances with TWA (8-hr), STEL (15-min), and Ceiling limits.
   - **ประกาศแบบ สอ.๑**: Form Sor.Or. 1 covering the 16 mandatory GHS Safety Data Sheet (SDS) sections.
   - **ประกาศแบบ สอ.๓ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕**: Form Sor.Or. 3 for atmospheric chemical concentration testing & reporting by registered testers (Section 9/11).

---

## 2. Logic Chain & Technical Design

```
[Thai Chemical Safety Laws (1516 List, 324 TLV, Sor.Or.1, Sor.Or.3)]
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
[Agent Skill: thai-chemical-safety-law]   [SAFAPP Flutter Database & UI]
  ├── SKILL.md                              ├── SQLite Database (1516 & 324 tables)
  ├── scripts/thai_chem_cli.py (PEP 723)    ├── Chemicals & SDS Management (สอ.๑)
  ├── scripts/data/ (JSON Master Datasets)   ├── Workplace Measurement (สอ.๓ ๒๕๖๕)
  └── references/ (Legal Markdown guides)   └── Legal Repository Viewer
                           │
                           ▼
          [D:\DEV\AgentResearch Integration]
            ├── Research Agent Skill (SK-RES-09)
            ├── IT Helper Module (thai_chem_helper.py)
            └── Shared Context / Report Automation
```

### 2.1 Directory Layout of the Agent Skill

The skill is designed to reside in both workspace `skills/thai-chemical-safety-law` and be linkable/copiable to `.gemini/config/skills/thai-chemical-safety-law` and `D:\DEV\AgentResearch\skills\thai-chemical-safety-law`.

```
skills/thai-chemical-safety-law/
├── SKILL.md
├── pyproject.toml
├── scripts/
│   ├── thai_chem_cli.py             # Main CLI entry point (PEP 723 executable)
│   ├── thai_chem_law.py             # Core Python engine & lookup library
│   ├── sds_validator.py             # 16-section GHS compliance validator
│   └── data/
│       ├── chemicals_1516.json      # Complete 1,516 regulated chemicals database
│       ├── tlv_324.json             # Complete 324 TLV occupational exposure limits
│       ├── legal_articles_2556.json # Full ministerial regulation articles & duties
│       ├── sor_or_1_schema.json     # GHS 16 sections schema and validation rules
│       └── sor_or_3_guidelines.json # Measurement guidelines & Section 9/11 rules
└── references/
    ├── laws_summary.md              # Executive summary of chemical safety laws
    ├── tlv_table_guide.md           # 324 TLV standards & calculation formulas
    ├── sor_or_1_guide.md            # Form Sor.Or. 1 structure & SDS requirements
    └── sor_or_3_guide.md            # Form Sor.Or. 3 reporting workflow & timeline
```

### 2.2 SKILL.md Frontmatter & Specification

```yaml
---
name: thai-chemical-safety-law
description: >-
  Query Thai hazardous chemical safety regulations (กฎกระทรวงฯ ๒๕๕๖), search 1,516 regulated chemicals, lookup 324 TLV standards (TWA/STEL/Ceiling), retrieve Sor.Or. 1 (สอ.๑) SDS 16 sections, Sor.Or. 3 (สอ.๓ ๒๕๖๕) measurement guidelines, and verify SDS compliance.
---
```

### 2.3 Master Data Schemas

#### A. 1,516 Regulated Chemicals Schema (`chemicals_1516.json`)
```json
[
  {
    "id": 1,
    "seq_no": 1,
    "name_th": "กรดเกลือ (กรดไฮโดรคลอริก)",
    "name_en": "Hydrochloric acid",
    "cas_no": "7647-01-0",
    "un_no": "1789",
    "hazard_classes": ["Skin Corr. 1B", "Eye Dam. 1", "STOT SE 3"],
    "is_regulated_1516": true,
    "has_tlv_324": true,
    "tlv_id": 142
  }
]
```

#### B. 324 Threshold Limit Values (TLV) Schema (`tlv_324.json`)
```json
[
  {
    "id": 142,
    "item_no": 142,
    "name_th": "ไฮโดรเจนคลอไรด์ (Hydrogen chloride)",
    "name_en": "Hydrogen chloride",
    "cas_no": "7647-01-0",
    "twa_ppm": null,
    "twa_mg_m3": null,
    "stel_ppm": null,
    "stel_mg_m3": null,
    "ceiling_ppm": 2.0,
    "ceiling_mg_m3": 2.98,
    "notation": "C",
    "remarks": "เพดานสูงสุด (Ceiling) ห้ามเกิน 2 ppm หรือ 2.98 mg/m3 ตลอดเวลาทำงาน"
  },
  {
    "id": 289,
    "item_no": 289,
    "name_th": "โทลูอีน (Toluene)",
    "name_en": "Toluene",
    "cas_no": "108-88-3",
    "twa_ppm": 200.0,
    "twa_mg_m3": 753.0,
    "stel_ppm": 300.0,
    "stel_mg_m3": 1130.0,
    "ceiling_ppm": 500.0,
    "ceiling_mg_m3": 1883.0,
    "notation": "Skin",
    "remarks": "ดูดซึมผ่านผิวหนังได้ (Skin)"
  }
]
```

#### C. Form Sor.Or. 1 (สอ.๑) 16 GHS Sections Schema (`sor_or_1_schema.json`)
```json
{
  "form": "Sor.Or.1",
  "legal_basis": "ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย",
  "sections": [
    {
      "section_no": 1,
      "title_th": "ข้อมูลเกี่ยวกับสารเคมีอันตรายและบริษัทผู้ผลิตและหรือนำเข้า",
      "title_en": "Identification of the substance/mixture and of the company/undertaking",
      "mandatory_fields": ["trade_name", "chemical_name", "cas_no", "manufacturer_importer_info", "emergency_phone"]
    },
    {
      "section_no": 2,
      "title_th": "การบ่งชี้ความเป็นอันตราย",
      "title_en": "Hazards identification",
      "mandatory_fields": ["ghs_classification", "signal_word", "hazard_statements", "precautionary_statements", "pictograms"]
    },
    {
      "section_no": 3,
      "title_th": "ส่วนประกอบและข้อมูลเกี่ยวกับส่วนผสม",
      "title_en": "Composition/information on ingredients",
      "mandatory_fields": ["ingredients"]
    },
    {
      "section_no": 4,
      "title_th": "มาตรการปฐมพยาบาล",
      "title_en": "First-aid measures",
      "mandatory_fields": ["inhalation", "skin_contact", "eye_contact", "ingestion"]
    },
    {
      "section_no": 5,
      "title_th": "มาตรการผจญเพลิง",
      "title_en": "Fire-fighting measures",
      "mandatory_fields": ["extinguishing_media", "specific_hazards", "protective_equipment"]
    },
    {
      "section_no": 6,
      "title_th": "มาตรการจัดการเมื่อมีการหกรั่วไหลของสาร",
      "title_en": "Accidental release measures",
      "mandatory_fields": ["personal_precautions", "environmental_precautions", "cleanup_methods"]
    },
    {
      "section_no": 7,
      "title_th": "การขนถ่าย เคลื่อนย้าย ใช้งาน และการจัดเก็บ",
      "title_en": "Handling and storage",
      "mandatory_fields": ["handling_precautions", "storage_conditions", "incompatibilities"]
    },
    {
      "section_no": 8,
      "title_th": "การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล",
      "title_en": "Exposure controls/personal protection",
      "mandatory_fields": ["occupational_exposure_limits", "engineering_controls", "ppe_respiratory", "ppe_hands", "ppe_eyes", "ppe_skin"]
    },
    {
      "section_no": 9,
      "title_th": "คุณสมบัติทางกายภาพและทางเคมี",
      "title_en": "Physical and chemical properties",
      "mandatory_fields": ["appearance", "odor", "ph", "boiling_point", "flash_point", "flammability_limits", "vapor_pressure", "density", "solubility"]
    },
    {
      "section_no": 10,
      "title_th": "ความเสถียรและความไวต่อปฏิกิริยา",
      "title_en": "Stability and reactivity",
      "mandatory_fields": ["reactivity", "chemical_stability", "hazardous_reactions", "incompatible_materials", "hazardous_decomposition_products"]
    },
    {
      "section_no": 11,
      "title_th": "ข้อมูลด้านพิษวิทยา",
      "title_en": "Toxicological information",
      "mandatory_fields": ["acute_toxicity_ld50_lc50", "skin_corrosion_irritation", "serious_eye_damage_irritation", "carcinogenicity"]
    },
    {
      "section_no": 12,
      "title_th": "ข้อมูลผลกระทบต่อระบบนิเวศน์",
      "title_en": "Ecological information",
      "mandatory_fields": ["ecotoxicity", "persistence_and_degradability", "bioaccumulative_potential", "mobility_in_soil"]
    },
    {
      "section_no": 13,
      "title_th": "ข้อพิจารณาในการกำจัด",
      "title_en": "Disposal considerations",
      "mandatory_fields": ["waste_treatment_methods", "packaging_disposal"]
    },
    {
      "section_no": 14,
      "title_th": "ข้อมูลการขนส่ง",
      "title_en": "Transport information",
      "mandatory_fields": ["un_number", "proper_shipping_name", "transport_hazard_class", "packing_group", "environmental_hazards"]
    },
    {
      "section_no": 15,
      "title_th": "ข้อมูลเกี่ยวกับกฎหมายและข้อบังคับ",
      "title_en": "Regulatory information",
      "mandatory_fields": ["safety_health_environmental_regulations", "thai_hazardous_substance_act_status"]
    },
    {
      "section_no": 16,
      "title_th": "ข้อมูลอื่นๆ",
      "title_en": "Other information",
      "mandatory_fields": ["revision_date", "references", "nfpa_rating"]
    }
  ]
}
```

#### D. Form Sor.Or. 3 (สอ.๓ ๒๕๖๕) Measurement & Evaluation Rules
```json
{
  "form": "Sor.Or.3",
  "legal_title": "ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการตรวจวัด และการวิเคราะห์ผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตราย (ฉบับที่ ๒) พ.ศ. ๒๕๖๕",
  "sampling_frequency": "At least once a year (อย่างน้อยปีละ ๑ ครั้ง) or within 30 days after process changes",
  "reporting_deadline": "Within 15 days of receiving laboratory results, and within 30 days of sampling date",
  "retention_period_years": 5,
  "registered_personnel": {
    "section_9": "บุคคลธรรมดาหรือนิติบุคคลที่ขึ้นทะเบียนเป็นผู้ให้บริการตรวจวัดและวิเคราะห์",
    "section_11": "เจ้าหน้าที่ความปลอดภัยในการทำงานหรือผู้ควบคุมที่ได้รับใบสำคัญขึ้นทะเบียนตรวจวัดในสถานประกอบการตนเอง"
  },
  "evaluation_criteria": {
    "twa_exceeded_if": "measured_twa > standard_twa",
    "stel_exceeded_if": "measured_stel > standard_stel",
    "ceiling_exceeded_if": "measured_instantaneous > standard_ceiling",
    "action_level_threshold": "0.5 * standard_twa (ระดับเตือนภัย Action Level เพื่อเฝ้าระวังเชิงป้องกัน)"
  }
}
```

---

## 3. Detailed CLI Architecture & Implementation

### 3.1 CLI Entry Point: `scripts/thai_chem_cli.py`

Designed with PEP 723 inline metadata for zero-friction execution via `uv run` or standard `python`:

```python
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

"""
==============================================================================
 Thai Chemical Safety Law CLI Tool
 Conforming to Royal Thai Gazette:
   - Ministerial Regulation B.E. 2556 (Hazardous Chemicals Safety)
   - Hazardous Chemicals List (1,516 items)
   - Threshold Limit Values (TLV) Notification (324 items)
   - Form Sor.Or. 1 (สอ.๑ - SDS 16 GHS Sections)
   - Form Sor.Or. 3 (สอ.๓ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕ - Workplace Measurement)
==============================================================================
"""

import sys
import os
import json
import argparse
import io

# Ensure UTF-8 output on Windows
if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace")

from thai_chem_law import ThaiChemLawEngine
from sds_validator import SDSValidator

def main():
    parser = argparse.ArgumentParser(
        description="Thai Chemical Safety Law CLI — Chemical search, TLV lookup, Legal texts & SDS verification"
    )
    subparsers = parser.add_subparsers(dest="command", required=True, help="Available subcommands")

    # 1. SEARCH
    p_search = subparsers.add_parser("search", help="Search chemical in Thai regulated 1,516 list by name or CAS")
    p_search.add_argument("-q", "--query", required=True, help="Thai name, English name, or CAS No.")
    p_search.add_argument("-l", "--limit", type=int, default=10, help="Maximum results to return")
    p_search.add_argument("-o", "--output", help="Output JSON file path")

    # 2. GET-TLV
    p_tlv = subparsers.add_parser("get-tlv", help="Query 324 TLV standards (TWA, STEL, Ceiling)")
    p_tlv.add_argument("-q", "--query", help="Chemical name or CAS number")
    p_tlv.add_argument("--eval-val", type=float, help="Measured concentration value to evaluate against TLV")
    p_tlv.add_argument("--eval-type", choices=["twa", "stel", "ceiling"], default="twa", help="Evaluation metric type")
    p_tlv.add_argument("--eval-unit", choices=["ppm", "mg_m3"], default="ppm", help="Evaluation unit")
    p_tlv.add_argument("-o", "--output", help="Output JSON file path")

    # 3. GET-LAW
    p_law = subparsers.add_parser("get-law", help="Retrieve legal articles & compliance guidelines")
    p_law.add_argument("-t", "--topic", choices=["all", "regulation_2556", "sor_or_1", "sor_or_3_2565", "registered_testers", "storage_rules", "medical_check", "penalties"], default="all")
    p_law.add_argument("-s", "--section", help="Specific section or article number (e.g. 9, 11, chapter_1)")
    p_law.add_argument("-o", "--output", help="Output JSON file path")

    # 4. VERIFY-SDS
    p_sds = subparsers.add_parser("verify-sds", help="Verify 16 GHS sections in SDS JSON/text")
    p_sds.add_argument("-f", "--file", required=True, help="Path to SDS JSON/YAML/TXT file")
    p_sds.add_argument("-o", "--output", help="Output JSON file path")

    args = parser.parse_args()
    engine = ThaiChemLawEngine()
    validator = SDSValidator(engine)

    result = {}
    if args.command == "search":
        result = engine.search_chemical(args.query, limit=args.limit)
    elif args.command == "get-tlv":
        result = engine.get_tlv(args.query, eval_val=args.eval_val, eval_type=args.eval_type, eval_unit=args.eval_unit)
    elif args.command == "get-law":
        result = engine.get_law(args.topic, section=args.section)
    elif args.command == "verify-sds":
        result = validator.verify_sds_file(args.file)

    output_str = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_str)
        print(f"✅ Result successfully written to: {args.output}")
    else:
        print(output_str)

if __name__ == "__main__":
    main()
```

### 3.2 Command Specifications & Sample JSON I/O

#### Command 1: `search`
* **Command**: `uv run scripts/thai_chem_cli.py search -q "Toluene" --limit 5`
* **Output JSON**:
```json
{
  "status": "success",
  "query": "Toluene",
  "total_found": 1,
  "results": [
    {
      "id": 289,
      "seq_no": 289,
      "name_th": "โทลูอีน",
      "name_en": "Toluene",
      "cas_no": "108-88-3",
      "un_no": "1294",
      "is_regulated_1516": true,
      "has_tlv_324": true,
      "tlv": {
        "item_no": 289,
        "twa_ppm": 200.0,
        "twa_mg_m3": 753.0,
        "stel_ppm": 300.0,
        "stel_mg_m3": 1130.0,
        "ceiling_ppm": 500.0,
        "ceiling_mg_m3": 1883.0,
        "notation": "Skin",
        "description": "ดูดซึมผ่านผิวหนังได้ (Skin Notation)"
      },
      "sds_required": true,
      "sor_or_1_applicable": true,
      "sor_or_3_testing_required": true
    }
  ]
}
```

#### Command 2: `get-tlv` (with Evaluation Engine)
* **Command**: `uv run scripts/thai_chem_cli.py get-tlv -q "108-88-3" --eval-val 225.5 --eval-type twa --eval-unit ppm`
* **Output JSON**:
```json
{
  "status": "success",
  "substance": {
    "item_no": 289,
    "name_th": "โทลูอีน (Toluene)",
    "name_en": "Toluene",
    "cas_no": "108-88-3",
    "standard_limits": {
      "twa_ppm": 200.0,
      "twa_mg_m3": 753.0,
      "stel_ppm": 300.0,
      "stel_mg_m3": 1130.0,
      "ceiling_ppm": 500.0,
      "ceiling_mg_m3": 1883.0,
      "notation": "Skin"
    }
  },
  "evaluation": {
    "measured_value": 225.5,
    "unit": "ppm",
    "metric": "TWA (8-hour time-weighted average)",
    "legal_limit": 200.0,
    "ratio_to_standard": 1.1275,
    "status": "EXCEEDED",
    "is_compliant": false,
    "color_code": "RED",
    "action_required": "เกินค่ามาตรฐานตามกฎหมาย! นายจ้างต้องปรับปรุงระบบวิศวกรรม/ระบายอากาศทันที และส่งรายงานแบบ สอ.๓ ภายใน ๑๕ วัน"
  }
}
```

#### Command 3: `get-law`
* **Command**: `uv run scripts/thai_chem_cli.py get-law -t sor_or_3_2565`
* **Output JSON**:
```json
{
  "status": "success",
  "topic": "sor_or_3_2565",
  "title": "ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการตรวจวัด และการวิเคราะห์ผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตราย (ฉบับที่ ๒) พ.ศ. ๒๕๖๕",
  "key_articles": [
    {
      "clause": "ข้อ ๓",
      "summary": "ให้นายจ้างจัดให้มีการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศสถานที่ทำงานและสถานที่เก็บรักษา อย่างน้อยปีละ ๑ ครั้ง หรือภายใน ๓๐ วันที่มีการเปลี่ยนแปลงกระบวนการผลิต"
    },
    {
      "clause": "ข้อ ๔",
      "summary": "การตรวจวัดต้องดำเนินการโดยผู้ให้บริการที่ขึ้นทะเบียนตามมาตรา ๙ หรือผู้ปฏิบัติการตรวจวัดตามมาตรา ๑๑ แห่ง พ.ร.บ.ความปลอดภัยฯ ๒๕๕๔"
    },
    {
      "clause": "ข้อ ๕",
      "summary": "ให้นายจ้างจัดทำรายงานผลการตรวจวัดและวิเคราะห์ตามแบบ สอ.๓ และส่งต่ออธิบดีหรือผู้ซึ่งอธิบดีมอบหมายภายใน ๑๕ วันนับแต่วันที่ได้รับผลการวิเคราะห์ และไม่เกิน ๓๐ วันนับแต่วันตรวจวัด พร้อมเก็บรักษาเอกสารไว้ไม่น้อยกว่า ๕ ปี"
    }
  ],
  "required_fields_sor_or_3": [
    "ข้อมูลสถานประกอบกิจการ (ชื่อ, เลขทะเบียนนิติบุคคล, ที่ตั้ง, รหัสไปรษณีย์)",
    "ข้อมูลสารเคมีอันตรายที่ตรวจวัด (ชื่อสาร, CAS No., วัตถุประสงค์การใช้)",
    "ข้อมูลการตรวจวัด (จุดตรวจวัด, วันที่ตรวจวัด, วิธีการเก็บตัวอย่าง, เครื่องมือที่ใช้)",
    "ผลการวิเคราะห์ (ค่าที่ตรวจพบ, หน่วย, ค่ามาตรฐาน TLV, ผลการประเมิน เกิน/ไม่เกิน)",
    "ข้อมูลผู้ตรวจวัดและวิเคราะห์ (ชื่อผู้ตรวจวัด, เลขทะเบียน ม.๙/ม.๑๑, วันหมดอายุใบขึ้นทะเบียน)"
  ]
}
```

#### Command 4: `verify-sds`
* **Command**: `uv run scripts/thai_chem_cli.py verify-sds -f sample_sds.json`
* **Output JSON**:
```json
{
  "status": "success",
  "compliant": true,
  "compliance_rate_percent": 100.0,
  "total_sections": 16,
  "valid_sections": 16,
  "missing_sections": [],
  "validation_report": [
    {"section": 1, "title": "ข้อมูลเกี่ยวกับสารเคมีและผู้ผลิต", "status": "PASS", "details": "Found trade_name, CAS 108-88-3, emergency contact"},
    {"section": 2, "title": "การบ่งชี้ความเป็นอันตราย", "status": "PASS", "details": "GHS classification, Signal Word 'Danger', Pictograms present"},
    {"section": 3, "title": "ส่วนประกอบและข้อมูลเกี่ยวกับส่วนผสม", "status": "PASS", "details": "Purity > 99.5% specified"},
    {"section": 4, "title": "มาตรการปฐมพยาบาล", "status": "PASS", "details": "4 exposure routes covered"},
    {"section": 5, "title": "มาตรการผจญเพลิง", "status": "PASS", "details": "Extinguishing media and fire hazards specified"},
    {"section": 6, "title": "มาตรการจัดการเมื่อหกรั่วไหล", "status": "PASS", "details": "Spill containment and cleanup procedures present"},
    {"section": 7, "title": "การขนถ่าย เคลื่อนย้าย และจัดเก็บ", "status": "PASS", "details": "Storage temperature & incompatibility rules noted"},
    {"section": 8, "title": "การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล", "status": "PASS", "details": "Thai TLV (TWA 200 ppm) matched, PPE specs complete"},
    {"section": 9, "title": "คุณสมบัติทางกายภาพและเคมี", "status": "PASS", "details": "Boiling point 110.6°C, Flash point 4°C present"},
    {"section": 10, "title": "ความเสถียรและความไวต่อปฏิกิริยา", "status": "PASS", "details": "Reactivity with strong oxidizers detailed"},
    {"section": 11, "title": "ข้อมูลด้านพิษวิทยา", "status": "PASS", "details": "Oral LD50 rat 5580 mg/kg, Inhalation LC50 included"},
    {"section": 12, "title": "ข้อมูลผลกระทบต่อระบบนิเวศน์", "status": "PASS", "details": "LC50 fish 5.5 mg/L specified"},
    {"section": 13, "title": "ข้อพิจารณาในการกำจัด", "status": "PASS", "details": "Incineration & hazardous waste disposal rules present"},
    {"section": 14, "title": "ข้อมูลการขนส่ง", "status": "PASS", "details": "UN 1294, Class 3, Packing Group II complete"},
    {"section": 15, "title": "ข้อมูลกฎหมายและข้อบังคับ", "status": "PASS", "details": "Hazardous Substance Act Type 3, Ministerial Reg 2556 cited"},
    {"section": 16, "title": "ข้อมูลอื่นๆ", "status": "PASS", "details": "NFPA 704 (H:2, F:3, R:0), Revision date 2026-05-15 included"}
  ],
  "recommendations": []
}
```

---

## 4. Integration Architecture with `D:\DEV\AgentResearch`

### 4.1 Research Agent Skill Registration (`D:\DEV\AgentResearch\Agent\01_Research.md`)

Add the new chemical legal research skill to `01_Research.md`:

```markdown
### SK-RES-09: Thai Chemical Safety Law Query & Compliance
- **ทำอะไร:** ค้นหาฐานข้อมูลสารเคมีอันตราย ๑,๕๑๖ รายการ, ตรวจสอบค่ามาตรฐาน TLV ๓๒๔ รายการ, ดึงข้อกำหนดกฎกระทรวงฯ ๒๕๕๖, แบบ สอ.๑ และ แบบ สอ.๓ ๒๕๖๕
- **เครื่องมือ:** `uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py` หรือเรียกผ่าน `ThaiChemLawHelper`
- **Output:** `Workspace/experiments/chemical_law_report.json`, `Memory/Shared/Shared_Context.json`
```

### 4.2 Python Integration Module (`D:\DEV\AgentResearch\Scripts\thai_chem_helper.py`)

A helper class easily usable by `agent_research.py`, `agent_writer.py`, `doc_helper.py`, and `planner.py`:

```python
"""
Thai Chemical Safety Law Helper for AgentResearch Multi-Agent System
Provides programmatic and subprocess access to chemical regulations & TLVs.
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional

# Locate skill directory
SKILL_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "skills", "thai-chemical-safety-law")
CLI_SCRIPT = os.path.join(SKILL_DIR, "scripts", "thai_chem_cli.py")

class ThaiChemLawHelper:
    def __init__(self, skill_dir: str = SKILL_DIR):
        self.skill_dir = skill_dir
        self.cli_script = os.path.join(skill_dir, "scripts", "thai_chem_cli.py")

    def _run_cli(self, args: List[str]) -> Dict[str, Any]:
        cmd = [sys.executable, self.cli_script] + args
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", check=True)
            return json.loads(res.stdout)
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def search_chemical(self, query: str, limit: int = 10) -> Dict[str, Any]:
        """Search chemical by Thai name, English name, or CAS No."""
        return self._run_cli(["search", "-q", query, "-l", str(limit)])

    def get_tlv(self, query: str, eval_val: Optional[float] = None, eval_type: str = "twa", eval_unit: str = "ppm") -> Dict[str, Any]:
        """Query TLV standard and optionally evaluate measurement."""
        args = ["get-tlv", "-q", query]
        if eval_val is not None:
            args += ["--eval-val", str(eval_val), "--eval-type", eval_type, "--eval-unit", eval_unit]
        return self._run_cli(args)

    def get_law(self, topic: str = "all", section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve legal provisions (regulation_2556, sor_or_1, sor_or_3_2565)."""
        args = ["get-law", "-t", topic]
        if section:
            args += ["-s", section]
        return self._run_cli(args)

    def verify_sds(self, file_path: str) -> Dict[str, Any]:
        """Verify SDS compliance with 16 GHS sections."""
        return self._run_cli(["verify-sds", "-f", file_path])
```

### 4.3 Agent Research Workflow Integration Example

When the user asks AgentResearch to write a section or research paper on occupational safety compliance for chemical storage:

1. **Planner (`planner.py`)**:
   - Detects chemical/occupational safety intent → assigns subtask to Research Agent using skill `SK-RES-09`.
2. **Research Agent (`agent_research.py`)**:
   - Calls `ThaiChemLawHelper.search_chemical("Toluene")` and `ThaiChemLawHelper.get_law("sor_or_3_2565")`.
   - Injects structured facts (TLV limit 200 ppm, Section 9/11 tester requirement, annual testing duty) into `Memory/Shared/Shared_Context.json`.
3. **Writer Agent (`agent_writer.py`)**:
   - Synthesizes thesis text citing exact Thai legal citations and numerical TLVs.
4. **QA Agent (`agent_qa.py`)**:
   - Calls `verify_sds` or `get_tlv` to mathematically verify all citations in the drafted chapter before approval.

---

## 5. Integration Architecture with SAFAPP Flutter Client

### 5.1 Shared Data Architecture
The same JSON datasets (`chemicals_1516.json` and `tlv_324.json`) will be shared between the Agent Skill and the Flutter App:
- **Flutter Assets**: `assets/data/chemicals_1516.json` and `assets/data/tlv_324.json`
- **SQLite Database Tables**:
  - `regulated_chemicals_1516`: Full search index for autocomplete.
  - `tlv_standards_324`: TLV lookup table for automatic evaluation.
  - `chemical_inventory`: Local inventory with SDS tracking dates and review alarms.
  - `sor_or_1_records`: Stored 16-section SDS data.
  - `sor_or_3_measurements`: Atmospheric inspection records with tester registration metadata.

---

## 6. Caveats

1. **Standalone Offline Data**: The 1,516 and 324 chemical datasets are stored locally in pure JSON format to ensure high-speed querying, 100% offline availability, and zero network rate limits.
2. **CAS Number Parsing**: Some chemicals in official gazettes share duplicate CAS numbers (isomers/mixtures) or have unassigned CAS numbers; the engine handles both exact CAS lookups and multi-term Thai/English fuzzy text matching.
3. **Platform Compatibility**: Designed for Windows (PowerShell/CMD), Linux, and macOS with explicit UTF-8 I/O wrappers to prevent Thai character encoding corruption (`cp874` / `utf-8`).

---

## 7. Conclusion

The specification for `thai-chemical-safety-law` Agent Skill and its integration with `D:\DEV\AgentResearch` is fully defined and ready for implementation. It bridges official Thai Government Gazette chemical safety laws directly into both:
1. Multi-agent research workflows (`D:\DEV\AgentResearch`), enabling automated legal research, compliance verification, and scientific thesis authoring.
2. SAFAPP Flutter desktop/mobile application, powering the 4-tab chemical management UI (`ChemicalsPage`).

---

## 8. Verification Method

To verify the skill implementation once created:

1. **CLI Execution Test**:
   ```bash
   # 1. Search chemical by English name
   uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py search -q "Toluene"

   # 2. Search chemical by CAS number
   uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py search -q "7647-01-0"

   # 3. Query TLV standard and evaluate measurement value
   uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py get-tlv -q "Toluene" --eval-val 225.5 --eval-type twa

   # 4. Query legal provisions for Sor.Or. 3 (2565)
   uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py get-law -t sor_or_3_2565

   # 5. Verify SDS 16 sections
   uv run skills/thai-chemical-safety-law/scripts/thai_chem_cli.py verify-sds -f skills/thai-chemical-safety-law/scripts/data/sample_sds.json
   ```

2. **AgentResearch Integration Test**:
   ```bash
   cd D:\DEV\AgentResearch
   python -c "from Scripts.thai_chem_helper import ThaiChemLawHelper; h = ThaiChemLawHelper(); print(h.search_chemical('Acetone'))"
   ```

3. **Validation Criteria**:
   - All CLI commands exit with code 0 and output valid JSON.
   - 1,516 chemical items and 324 TLV values match the Royal Thai Gazette accurately.
   - `verify-sds` accurately reports missing or invalid sections among the 16 GHS items.
