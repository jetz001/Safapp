# Comprehensive Analysis & Specification: Thai PTW Safety Law Agent Skill & Python Tooling

**Agent**: Explorer 3: Agent Skill & Python Tooling Specialist  
**Date**: 2026-09-01  
**Target Skill**: `thai-ptw-safety-law`  
**Target Helper**: `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py` & `C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\`  
**Reference Workspaces**: `d:\DEV\SAFAPP`, `D:\DEV\AgentResearch`

---

## 1. Executive Summary & Problem Scope

This report establishes the technical architecture, legal rule engine, CLI specification, multi-agent programmatic helper, and automated test suite for the **`thai-ptw-safety-law`** Agent Skill and Python tooling.

The goal is to provide a unified, offline-first, dual-mode Python engine and CLI that enforces strict adherence to Thai occupational safety regulations (ราชกิจจานุเบกษา) for Permit to Work (PTW) across 5 high-risk work categories:
1. **Hot Work (งานประกายไฟ/ความร้อน)**: Fire safety, 11-meter hazard radius, 30-minute post-work monitoring.
2. **Confined Space (งานในสถานที่อับอากาศ)**: Gas limits (O2, LEL, CO, H2S), 4 statutory duty holders, forced mechanical ventilation.
3. **Working at Height (งานบนที่สูง)**: Fall protection >= 2.0m, Full Body Harness, 22.2 kN anchor points, scaffolding tags.
4. **Electrical & LOTO (งานไฟฟ้าและการตัดแยกพลังงาน)**: Lockout/Tagout, padlocks & tags, Zero Energy Verification.
5. **Excavation & Lifting (งานขุดเจาะและยกเคลื่อนย้าย)**: Shoring/benching >= 1.5m, underground utility checks, crane SWL & safety latches.

---

## 2. Survey of Existing Thai Safety Skill Ecosystem

An investigation of existing skills in `C:\Users\jetsa\.gemini\config\skills\` and `d:\DEV\SAFAPP\skills\` revealed an established architectural standard:

### 2.1 Existing Skills Analyzed
| Skill Name | Core Domain | Key Regulations | CLI Entrypoint | Helper Script |
|---|---|---|---|---|
| `thai-chemical-safety-law` | 1,516 regulated chemicals, 324 TLV standards, SDS 16 sections | กฎกระทรวงสารเคมีฯ ๒๕๕๖, ประกาศกรมฯ สอ.๑, สอ.๓ ๒๕๖๕ | `thai_chem_cli.py` | `thai_chem_helper.py` |
| `thai-environmental-safety-law` | Lighting (Lux), Noise (dBA/TWA), Heat (WBGT), Subcontractors (Sec 9/11) | กฎกระทรวงความร้อนฯ ๒๕๕๙, ประกาศกรมฯ แสง ๒๕๖๑, เสียง ๒๕๖๑, ความร้อน ๒๕๖๓ | `thai_env_cli.py` | `thai_env_helper.py` |
| `thai-safety-legal-register` | 8 core safety laws register, compliance scoring, automated CAPA generation | พ.ร.บ. ๒๕๕๔, กฎกระทรวง จป. ๒๕๖๕, สารเคมี ๒๕๕๖, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, เครื่องจักร ๒๕๖๔, สิ่งแวดล้อม ๒๕๕๙, ตรวจสุขภาพ ๒๕๖๓ | `thai_safety_legal_cli.py` | `thai_safety_legal_helper.py` |

### 2.2 Standard Architecture Patterns
1. **Standard Directory Layout**:
   ```
   thai-ptw-safety-law/
   ├── SKILL.md                 # YAML frontmatter + detailed Markdown documentation
   ├── pyproject.toml           # PEP 621 metadata (Python >= 3.10)
   ├── scripts/
   │   ├── thai_ptw_cli.py      # argparse CLI supporting JSON / Table output
   │   ├── thai_ptw_engine.py   # Pure Python domain logic & rule evaluator
   │   ├── thai_ptw_helper.py   # Dual-mode helper for AgentResearch & local use
   │   └── data/                # Offline JSON datasets (catalogs, standards, templates)
   │       ├── ptw_laws_catalog.json
   │       ├── gas_standards.json
   │       ├── safety_checklists.json
   │       └── sample_ptws.json
   ├── references/              # Legal markdown reference summaries (Royal Gazette)
   └── tests/                   # Automated unit & integration tests
       ├── __init__.py
       ├── test_thai_ptw_engine.py
       ├── test_thai_ptw_cli.py
       └── test_adversarial_ptw.py
   ```

2. **`SKILL.md` Specifications**:
   - YAML frontmatter at top:
     ```yaml
     ---
     name: thai-ptw-safety-law
     description: >-
       Validate High-Risk Permit to Work (PTW) workflows, evaluate Confined Space gas testing (O2, LEL, CO, H2S), verify 4-role duty holders (Authorizer, Supervisor, Attendant, Entrant), audit Hot Work 30-min fire watch, inspect LOTO zero energy isolation, retrieve statutory safety checklists, and query Thai safety laws (พ.ร.บ. ๒๕๕๔, กฎกระทรวงอับอากาศ ๒๕๖๒, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, นั่งร้าน/งานบนที่สูง/ดินขุด ๒๕๖๔).
     ---
     ```
   - Quick Start commands with `uv run scripts/thai_ptw_cli.py <subcommand>` and `python scripts/thai_ptw_cli.py <subcommand>`.
   - Clear sample JSON outputs for all CLI commands.
   - Integration instructions for `AgentResearch` multi-agent workflows.

3. **Dual-Mode Helper Pattern (`thai_ptw_helper.py`)**:
   - **Mode 1: In-Memory Engine Execution**: When `thai_ptw_engine.py` and `data/` are importable directly, instantiate `ThaiPtwEngine` for low-latency, in-process evaluation.
   - **Mode 2: Subprocess CLI Execution**: When running in an external agent process or across environments, invoke `sys.executable thai_ptw_cli.py <subcommand>` with `subprocess.run(capture_output=True, text=True, encoding="utf-8")`.

4. **CLI Encoding & Error Resilience**:
   - Explicit UTF-8 stream wrapping on Windows terminals:
     ```python
     if sys.stdout.encoding != "utf-8":
         sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
     ```
   - Standard exit codes: `0` for SUCCESS/PASS, `1` for CLI errors/validation failure.

---

## 3. Thai PTW Regulatory Legal Framework & Rule Logic

The rule engine must strictly embed statutory rules from the Royal Thai Gazette (ราชกิจจานุเบกษา):

### 3.1 Confined Space Regulations (กฎกระทรวงสถานที่อับอากาศ พ.ศ. ๒๕๖๒)
- **Official Title**: กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒
- **Legal Thresholds & Rules**:
  1. **Atmospheric Hazard Limits (ข้อ ๗)**:
     - **Oxygen ($O_2$)**: Must be between **19.5% and 23.5%** by volume.
       - $< 19.5\%$: Oxygen Deficiency (ภาวะขาดออกซิเจน - ห้ามเข้าเด็ดขาด)
       - $> 23.5\%$: Oxygen Enriched (ภาวะออกซิเจนเกิน เสี่ยงต่อการลุกไหม้รุนแรง)
     - **Flammable Gas / Vapor (LEL)**: Must be **$< 10\%$ LEL**.
       - $\ge 10\%$ LEL: Flammable / Explosive Hazard (บรรยากาศไวไฟ ห้ามเข้าเด็ดขาด)
     - **Carbon Monoxide ($CO$)**: Must be **$< 25\text{ ppm}$** (8-hr TWA standard; ceiling 200 ppm).
     - **Hydrogen Sulfide ($H_2S$)**: Must be **$< 10\text{ ppm}$** (8-hr TWA standard; ceiling 15 ppm).
  2. **4 Mandatory Duty Holders (ผู้มีหน้าที่ ๔ ฝ่าย - ข้อ ๙, ๑๐, ๑๑, ๑๒)**:
     - **ผู้อนุญาต (Authorizer / Permit Issuer)**: Must have certified training. Responsible for reviewing hazard assessment and issuing permit.
     - **ผู้ควบคุมงาน (Supervisor)**: Must have certified training. Responsible for supervising safety measures at the entrance.
     - **ผู้ช่วยเหลือ (Attendant / Standby Person / Rescuer)**: Must have certified training. Must remain stationed outside entrance at all times, maintain communication with entrants, monitor gas, and initiate rescue without entering without backup.
     - **ผู้ปฏิบัติงาน (Entrant)**: Must have certified training. Fit for confined space entry, equipped with PPE, harness, and lifeline.
     - **Role Separation Constraint**: The Attendant *cannot* be an Entrant at the same time. The Authorizer and Supervisor should generally be distinct, though in small operations Authorizer may assign certified Supervisor.
  3. **Operational Controls (ข้อ ๔, ๕, ๖, ๑๔, ๑๗, ๑๘)**:
     - Mandatory PTW posting at entrance.
     - Forced mechanical ventilation before and continuously during occupancy.
     - Rescue equipment: Tripod/Winch, SCBA/Air-line respirator, Emergency retrieval lifeline, Communication devices.

### 3.2 Hot Work & Fire Safety Regulations (กฎกระทรวงอัคคีภัย พ.ศ. ๒๕๕๕)
- **Official Title**: กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕
- **Legal Thresholds & Rules**:
  1. **Clearance Radius**: 10–11 meters (35 feet) cleared of all combustible materials or protected with fire blankets / non-combustible shields.
  2. **Fire Extinguisher Readiness**: At least 1-2 portable fire extinguishers (suitable type: 2A-10B or ABC) stationed within immediate reach.
  3. **Fire Watcher (ผู้เฝ้าระวังไฟ)**: Dedicated personnel trained in fire extinguisher operation stationed at the hot work area.
  4. **Post-Work Fire Monitoring**: Continuous fire watch for **not less than 30 minutes** after work completion to prevent smoldering fires.

### 3.3 Electrical & LOTO Regulations (กฎกระทรวงไฟฟ้า พ.ศ. ๒๕๕๘)
- **Official Title**: กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘
- **Legal Thresholds & Rules**:
  1. **Lockout / Tagout (LOTO)**: Circuit breakers, disconnect switches, and energy isolation valves must be mechanically locked with padlocks.
  2. **Danger Tags**: Attached to all isolation points with inspector name, contact, date/time, and warning "ห้ามสับสวิตช์/ห้ามเปิดวาล์ว".
  3. **Zero Energy Verification**: Voltage tester / multi-meter check, residual pressure bleeding, grounding test before work begins.

### 3.4 Working at Height & Excavation Regulations (กฎกระทรวงงานบนที่สูงและดินขุด พ.ศ. ๒๕๖๔)
- **Official Title**: กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับนั่งร้าน งานบนที่สูง และงานดินขุด พ.ศ. ๒๕๖๔
- **Legal Thresholds & Rules**:
  1. **Height Threshold**: Work at height $\ge 2.0\text{ meters}$ requires fall protection (Full Body Harness + Double Lanyard with Shock Absorber).
  2. **Anchor Point Strength**: Anchor must withstand $\ge 22.2\text{ kN}$ ($5,000\text{ lbs}$ or $2,270\text{ kg}$) per person.
  3. **Guardrails & Toe-boards**: Guardrail height $0.90 - 1.10\text{ m}$, toe-board $\ge 7.5 - 10\text{ cm}$.
  4. **Excavation Depth $\ge 1.5\text{ meters}$**: Requires soil shoring (ค้ำยัน) or sloping/benching, underground utility scanning, and access ladders every $7.5 - 15\text{ m}$.

---

## 4. Specification of `thai-ptw-safety-law` Skill

### 4.1 CLI Commands & Subparsers (`thai_ptw_cli.py`)

The CLI interface supports 5 core subcommands:

```
thai_ptw_cli.py
  ├── validate-ptw          # Validates complete PTW payload against Thai safety laws
  ├── eval-gas              # Evaluates single or continuous gas measurement readings
  ├── verify-confined-roles # Validates completeness and separation of 4 confined space roles
  ├── get-checklist         # Retrieves statutory safety checklist items by PTW type
  └── get-ptw-law           # Queries legal articles, Royal Gazette citations, and statutory clauses
```

#### Command 1: `validate-ptw`
- **Arguments**:
  - `-f, --file`: Path to PTW JSON file.
  - `-d, --data`: Raw JSON string of PTW payload.
  - `-t, --type`: PTW type filter (`hot_work`, `confined_space`, `working_at_height`, `electrical_loto`, `excavation_lifting`).
  - `--format`: `json` (default) or `table`.
  - `-o, --output`: Optional output file path.
- **Evaluation Logic**:
  - Validates general fields: `ptw_number`, `work_title`, `location`, `valid_from`, `valid_to`, `applicant_name`.
  - Validates work type specific legal mandates (e.g. If `confined_space` -> requires 4 roles, pre-entry gas test within valid limits, emergency plan, forced ventilation).
  - If `hot_work` -> requires Fire Watcher name, fire extinguisher verification, and 30-min post-work sign-off.
  - If `electrical_loto` -> requires isolation point list, lockout padlocks, and zero-energy verification.
  - If `working_at_height` -> requires fall protection type, harness inspection, anchor point verification.
  - If `excavation_lifting` -> requires shoring check, underground survey, crane inspection tag.
  - Validates signatures and approval workflow stage.
- **Sample JSON Output**:
  ```json
  {
    "status": "success",
    "ptw_number": "PTW-20260901-001",
    "work_type": "confined_space",
    "is_compliant": true,
    "validation_score": 100.0,
    "status_badge": "COMPLIANT_PERMIT_VALID",
    "findings": [],
    "role_verification": {
      "is_valid": true,
      "roles_present": ["authorizer", "supervisor", "attendant", "entrant"],
      "missing_roles": []
    },
    "gas_verification": {
      "is_safe": true,
      "o2_pct": 20.9,
      "lel_pct": 0.0,
      "co_ppm": 2.0,
      "h2s_ppm": 0.0
    },
    "mandatory_controls_summary": {
      "forced_ventilation": true,
      "emergency_rescue_plan": true,
      "digital_signatures_completed": true
    }
  }
  ```

#### Command 2: `eval-gas`
- **Arguments**:
  - `--o2`: Oxygen percentage (e.g. `20.9`).
  - `--lel`: LEL percentage (e.g. `0.0`).
  - `--co`: Carbon monoxide in ppm (e.g. `5.0`).
  - `--h2s`: Hydrogen sulfide in ppm (e.g. `1.0`).
  - `--type`: `pre_entry` (default) or `continuous`.
  - `--interval`: Measurement interval in hours (e.g. `1.0` or `2.0`).
  - `--format`: `json` or `table`.
  - `-o, --output`: Optional output file path.
- **Evaluation Logic**:
  - Checks $O_2 \in [19.5, 23.5]$. If $< 19.5 \rightarrow \text{OXYGEN\_DEFICIENT}$ (CRITICAL ALARM). If $> 23.5 \rightarrow \text{OXYGEN\_ENRICHED}$ (HIGH RISK).
  - Checks $\text{LEL} < 10.0\%$. If $\ge 10.0\% \rightarrow \text{EXPLOSIVE\_HAZARD}$ (CRITICAL ALARM).
  - Checks $CO < 25.0\text{ ppm}$. If $\ge 25.0\text{ ppm} \rightarrow \text{TOXIC\_CO\_EXCEEDED}$ (ALARM).
  - Checks $H_2S < 10.0\text{ ppm}$. If $\ge 10.0\text{ ppm} \rightarrow \text{TOXIC\_H2S\_EXCEEDED}$ (CRITICAL TOXIC ALARM).
  - Determines overall verdict: `SAFE_TO_ENTER`, `UNSAFE_PROHIBITED`, `CONTINUOUS_VENTILATION_REQUIRED`.
- **Sample JSON Output**:
  ```json
  {
    "status": "success",
    "overall_status": "SAFE_TO_ENTER",
    "is_safe": true,
    "statutory_reference": "กฎกระทรวงสถานที่อับอากาศ พ.ศ. ๒๕๖๒ ข้อ ๗",
    "readings": {
      "oxygen": {
        "value": 20.9,
        "unit": "%",
        "standard_range": "19.5 - 23.5%",
        "status": "PASS",
        "detail": "บรรยากาศปกติ ปริมาณออกซิเจนเพียงพอ"
      },
      "combustible_gas": {
        "value": 2.0,
        "unit": "% LEL",
        "standard_limit": "< 10.0% LEL",
        "status": "PASS",
        "detail": "ต่ำกว่า 10% LEL ไม่อยู่ในเกณฑ์ไวไฟ"
      },
      "carbon_monoxide": {
        "value": 3.0,
        "unit": "ppm",
        "standard_limit": "< 25.0 ppm",
        "status": "PASS",
        "detail": "ก๊าซคาร์บอนมอนอกไซด์อยู่ในเกณฑ์ปลอดภัย"
      },
      "hydrogen_sulfide": {
        "value": 0.0,
        "unit": "ppm",
        "standard_limit": "< 10.0 ppm",
        "status": "PASS",
        "detail": "ไม่พบก๊าซไข่เน่า (H2S)"
      }
    },
    "actions": [
      "อนุญาตให้เข้าปฏิบัติงานได้",
      "ต้องเปิดพัดลมระบายอากาศ (Forced Mechanical Ventilation) ต่อเนื่องตลอดเวลาการทำงาน",
      "ตรวจวัดซ้ำทุก 1-2 ชั่วโมง หรือติดตั้งเครื่องวัดแบบพกพาชนิดต่อเนื่อง"
    ]
  }
  ```

#### Command 3: `verify-confined-roles`
- **Arguments**:
  - `-f, --file` / `-d, --data`: JSON payload containing assigned roles and certificate numbers.
  - `--authorizer`: Authorizer name & cert ID.
  - `--supervisor`: Supervisor name & cert ID.
  - `--attendant`: Attendant / Standby person name & cert ID.
  - `--entrants`: Comma-separated list of entrant names & cert IDs.
  - `--format`: `json` or `table`.
- **Evaluation Logic**:
  - Ensures all 4 roles are populated: (1) ผู้อนุญาต, (2) ผู้ควบคุมงาน, (3) ผู้ช่วยเหลือ, (4) ผู้ปฏิบัติงาน.
  - Verifies role conflict rules:
    - `attendant` $\ne$ any member of `entrants` (Strict violation of Section 11 & 12).
    - Checks whether certification training numbers are provided.
    - Confirms at least 1 entrant is assigned.
- **Sample JSON Output**:
  ```json
  {
    "status": "success",
    "is_valid": true,
    "statutory_reference": "กฎกระทรวงสถานที่อับอากาศ พ.ศ. ๒๕๖๒ ข้อ ๙, ๑๐, ๑๑, ๑๒",
    "role_summary": {
      "authorizer": { "name": "นายสมศักดิ์ รักปลอดภัย", "cert_no": "AUTH-2565-089", "status": "VALID" },
      "supervisor": { "name": "นายวิชัย คุมงานดี", "cert_no": "SUP-2566-102", "status": "VALID" },
      "attendant": { "name": "นายธงชัย ช่วยเหลือไว", "cert_no": "ATT-2566-301", "status": "VALID" },
      "entrants": [
        { "name": "นายดำรง มั่นคง", "cert_no": "ENT-2567-005", "status": "VALID" },
        { "name": "นายประสิทธิ์ ว่องไว", "cert_no": "ENT-2567-006", "status": "VALID" }
      ]
    },
    "conflict_checks": {
      "attendant_entrant_overlap": false,
      "has_minimum_entrants": true
    },
    "verdict": "COMPLETE_AND_COMPLIANT"
  }
  ```

#### Command 4: `get-checklist`
- **Arguments**:
  - `-t, --type`: PTW type (`hot_work`, `confined_space`, `working_at_height`, `electrical_loto`, `excavation_lifting`, `all`).
  - `-s, --sub-category`: Subcategory filter (e.g. `welding`, `tank_entry`, `scaffolding`, `high_voltage`, `trenching`).
  - `--format`: `json` or `table`.
- **Sample JSON Output**:
  ```json
  {
    "status": "success",
    "work_type": "hot_work",
    "total_items": 8,
    "statutory_reference": "กฎกระทรวงป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕",
    "items": [
      {
        "item_id": "HW-CHK-01",
        "category": "combustible_clearance",
        "description_th": "เคลื่อนย้ายวัสดุติดไฟ สารไวไฟ หรือสารเคมี ออกจากรัศมี 11 เมตร (35 ฟุต) หรือคลุมด้วยผ้ากันไฟ (Fire Blanket) อย่างมิดชิด",
        "is_mandatory": true,
        "hazard_type": "Fire & Explosion"
      },
      {
        "item_id": "HW-CHK-02",
        "category": "fire_extinguisher",
        "description_th": "จัดเตรียมเครื่องดับเพลิงชนิดและขนาดเหมาะสม พร้อมใช้งานอย่างน้อย 2 ถัง ประจำจุดทำงาน",
        "is_mandatory": true,
        "hazard_type": "Fire"
      },
      {
        "item_id": "HW-CHK-03",
        "category": "fire_watch",
        "description_th": "แต่งตั้งผู้เฝ้าระวังไฟ (Fire Watcher) ประจำตลอดเวลาการปฏิบัติงานและเฝ้าระวังต่อเนื่องหลังเสร็จงานไม่น้อยกว่า 30 นาที",
        "is_mandatory": true,
        "hazard_type": "Smoldering Fire"
      }
    ]
  }
  ```

#### Command 5: `get-ptw-law`
- **Arguments**:
  - `-t, --topic`: `all`, `confined_2562`, `fire_2555`, `electrical_2558`, `height_excavation_2564`, `act_2554`.
  - `-s, --section`: Specific section/article search (e.g. `ข้อ ๗`, `ข้อ ๓๐`, `มาตรา ๑๔`).
  - `--format`: `json` or `table`.
- **Sample JSON Output**:
  ```json
  {
    "status": "success",
    "total_found": 1,
    "laws": [
      {
        "law_id": "PTW-LAW-CONFINED-2562",
        "title_th": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒",
        "gazette_reference": {
          "volume": "๑๓๖",
          "part": "๖๓ ก",
          "page": "๓๔",
          "date_th": "๑๓ พฤษภาคม ๒๕๖๒"
        },
        "target_article": {
          "article_no": "ข้อ ๗",
          "title": "เกณฑ์บรรยากาศอันตรายในสถานที่อับอากาศ",
          "full_text_th": "นายจ้างต้องจัดให้มีการประเมินสภาพอากาศในสถานที่อับอากาศก่อนให้ลูกจ้างเข้าไปทำงานและในระหว่างที่ลูกจ้างทำงาน โดยบรรยากาศที่ถือว่าปลอดภัยต้องมีออกซิเจนระหว่างร้อยละ 19.5 ถึง 23.5 โดยปริมาตร สารเคมีหรือก๊าซไวไฟต้องน้อยกว่าร้อยละ 10 ของขีดจำกัดล่างของช่วงการติดไฟ (LEL)...",
          "enforcement_summary": "ห้ามเข้าทำงานหากค่าก๊าซอยู่นอกเกณฑ์ความปลอดภัยเด็ดขาด และต้องระบายอากาศอย่างต่อเนื่อง",
          "penalty_clause": "พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๕๓ จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ"
        }
      }
    ]
  }
  ```

---

## 5. Multi-Agent Integration Architecture: `thai_ptw_helper.py`

In `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py`, the helper class `ThaiPtwHelper` provides high-level Python methods designed for direct integration with `AgentResearch` agents:
- `agent_research.py` (Regulatory researcher SK-RES-09)
- `agent_qa.py` (Compliance auditor)
- `agent_advisor.py` (Safety policy advisor)
- `agent_writer.py` (Report / Permit generator)

### 5.1 Helper Class Interface (`ThaiPtwHelper`)
```python
"""
Thai PTW Safety Law Helper for AgentResearch Multi-Agent System (thai_ptw_helper.py)
Conforming to Royal Thai Gazette PTW Safety Regulations:
  - OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
  - Ministerial Reg. Confined Space B.E. 2562 (กฎกระทรวงอับอากาศ ๒๕๖๒)
  - Ministerial Reg. Fire Safety B.E. 2555 (กฎกระทรวงอัคคีภัย ๒๕๕๕ - Hot Work)
  - Ministerial Reg. Electrical Safety B.E. 2558 (กฎกระทรวงไฟฟ้า ๒๕๕๘ - LOTO)
  - Ministerial Reg. Height & Excavation B.E. 2564 (กฎกระทรวงงานบนที่สูงและดินขุด ๒๕๖๔)
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional, Union

class ThaiPtwHelper:
    """Dual-mode Python Helper for querying Thai PTW safety laws and evaluating permit compliance."""

    def __init__(self, skill_dir: Optional[str] = None, prefer_direct: bool = True):
        # Auto-detect skill_dir in .gemini config or SAFAPP skills folder
        ...

    def validate_ptw(self, ptw_payload_or_file: Union[Dict[str, Any], str], work_type: Optional[str] = None) -> Dict[str, Any]:
        """Validate complete PTW request against statutory checklist, gas limits, roles, and safety controls."""
        ...

    def eval_gas(
        self,
        o2: float,
        lel: float,
        co: float,
        h2s: float,
        measurement_type: str = "pre_entry",
        continuous_interval_hours: Optional[float] = None
    ) -> Dict[str, Any]:
        """Evaluate atmospheric gas testing values against Ministerial Reg. Confined Space 2562 (ข้อ ๗)."""
        ...

    def verify_confined_roles(
        self,
        roles_payload_or_file: Union[Dict[str, Any], str]
    ) -> Dict[str, Any]:
        """Verify statutory completeness and separation of 4 Confined Space roles (ข้อ ๙, ๑๐, ๑๑, ๑๒)."""
        ...

    def check_hotwork_firewatch(
        self,
        monitoring_minutes: float,
        fire_watcher_name: str,
        extinguisher_ready: bool,
        area_cleared_11m: bool = True
    ) -> Dict[str, Any]:
        """Verify Hot Work fire safety and 30-minute post-work monitoring requirement."""
        ...

    def verify_loto(
        self,
        isolation_points: List[Dict[str, Any]],
        zero_energy_verified: bool
    ) -> Dict[str, Any]:
        """Verify Lockout/Tagout energy isolation points and zero energy verification."""
        ...

    def get_checklist(
        self,
        ptw_type: str = "all",
        sub_category: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve statutory safety checklist items by work type."""
        ...

    def get_ptw_law(
        self,
        topic: str = "all",
        section: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve Thai safety laws, Gazette citations, and penalty clauses."""
        ...
```

---

## 6. Offline Data Catalogs (`data/`) Specification

The engine relies on 4 self-contained JSON catalogs in `scripts/data/`:

1. **`ptw_laws_catalog.json`**:
   - Contains full metadata for the 5 key safety regulations (volume, part, page, gazette URL, publication date, effective date).
   - Key statutory articles indexed with Thai full text, requirement descriptions, applicability conditions, compliance rules, and legal penalties (มาตรา ๕๓, ๕๔, ๕๕, ๕๖ พ.ร.บ. ๒๕๕๔).

2. **`gas_standards.json`**:
   - Defined ranges for $O_2$ (19.5% - 23.5%), $\text{LEL} < 10\%$, $CO < 25\text{ ppm}$, $H_2S < 10\text{ ppm}$.
   - Severity badges: `SAFE`, `WARNING`, `DANGER_EXCEEDED`, `CRITICAL_PROHIBITED`.
   - Action recommendations: Forced mechanical ventilation rate, SCBA requirements, evacuation alerts.

3. **`safety_checklists.json`**:
   - Structured checklist items partitioned across the 5 high-risk types:
     - `hot_work`: 8 items (11m clearance, fire blanket, fire watcher, 2 extinguishers, 30-min watch, flammable vapor check).
     - `confined_space`: 10 items (pre-entry gas, 4 roles certs, forced blower, tripod & winch, SCBA/air-line, radio comms, entry log).
     - `working_at_height`: 8 items (full body harness, double lanyard shock absorber, 22.2 kN anchor point, scaffolding green tag, edge guardrails, weather check).
     - `electrical_loto`: 8 items (padlock lockout, danger tags, zero energy voltage check, residual discharge, PPE arc-flash).
     - `excavation_lifting`: 8 items (soil shoring > 1.5m, underground utility clearance, access ladder <= 7.5m, crane SWL, safety latches).

4. **`sample_ptws.json`**:
   - Realistic benchmark test cases:
     - Compliant Confined Space PTW (All 4 roles, safe gas, valid signatures)
     - Non-compliant Gas Confined Space PTW ($O_2 = 18.2\%$, $\text{LEL} = 15\%$)
     - Overlapping Attendant-Entrant violation PTW
     - Compliant Hot Work PTW with 30-minute fire watch
     - Compliant Electrical LOTO PTW with Zero Energy Verification

---

## 7. Test Suite Architecture

Following the existing skill test suite design (e.g. `test_thai_safety_legal_skill.py`), `thai-ptw-safety-law` will include a comprehensive `unittest` suite covering:

1. **`test_01_catalog_integrity`**: Checks that all 5 laws, gas standards, and 40+ checklist items load properly with Royal Gazette metadata.
2. **`test_02_gas_evaluation_safe`**: Verifies normal gas readings ($O_2 = 20.9\%$, $\text{LEL} = 0\%$, $CO = 2\text{ ppm}$, $H_2S = 0\text{ ppm}$) yield `is_safe: True` and `SAFE_TO_ENTER`.
3. **`test_03_gas_evaluation_oxygen_deficiency`**: Verifies $O_2 = 18.0\%$ triggers `OXYGEN_DEFICIENT` critical failure.
4. **`test_04_gas_evaluation_high_lel`**: Verifies $\text{LEL} = 12.0\%$ triggers `EXPLOSIVE_HAZARD` critical failure.
5. **`test_05_gas_evaluation_toxic_gases`**: Verifies $CO = 30\text{ ppm}$ and $H_2S = 15\text{ ppm}$ trigger toxic gas alarms.
6. **`test_06_confined_space_4_roles_valid`**: Verifies complete 4-role registration with certified IDs passes.
7. **`test_07_confined_space_role_conflict`**: Verifies that assigning the same person as Attendant and Entrant triggers a legal conflict violation.
8. **`test_08_confined_space_missing_roles`**: Verifies missing supervisor or authorizer fails validation.
9. **`test_09_hot_work_30min_firewatch_pass`**: Verifies 30+ minutes fire watch log with fire watcher name and extinguisher passes.
10. **`test_10_hot_work_firewatch_fail`**: Verifies $< 30\text{ minutes}$ (e.g. 15 minutes) or missing watcher fails.
11. **`test_11_electrical_loto_zero_energy`**: Verifies LOTO isolation points and zero-energy verification.
12. **`test_12_working_at_height_fall_protection`**: Verifies height $\ge 2.0\text{ m}$ enforces full body harness and anchor point verification.
13. **`test_13_excavation_depth_shoring`**: Verifies excavation $\ge 1.5\text{ m}$ enforces shoring/sloping.
14. **`test_14_ptw_lifecycle_workflow`**: Verifies state transitions (`draft` -> `pending_approval` -> `active` -> `extended` -> `closed`).
15. **`test_15_dual_mode_helper_and_cli`**: Verifies `ThaiPtwHelper` runs identically in in-memory mode and CLI subprocess fallback mode.

---

## 8. Summary of Integration with SAFAPP & Multi-Agent System

```
+-----------------------------------------------------------------------------------+
|                            SAFAPP PTW Flutter Module                              |
|   - PtwPage (4 Tabs: Dashboard, PTW Wizard, Live Site Controls, Legal Library)    |
|   - Models: PtwModel, GasTestLogModel, LotoIsolationModel, ConfinedRoleModel       |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|               thai-ptw-safety-law Agent Skill (Gemini / Claude / uv)              |
|   - Location: C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\           |
|   - Mirror:   d:\DEV\SAFAPP\skills\thai-ptw-safety-law\                           |
|   - CLI:      validate-ptw | eval-gas | verify-confined-roles | get-checklist     |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                 AgentResearch Multi-Agent System (D:\DEV\AgentResearch)           |
|   - Helper:   D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py                     |
|   - Agents:   agent_research.py (SK-RES-09), agent_qa.py, agent_advisor.py        |
+-----------------------------------------------------------------------------------+
```

This specification is complete, mathematically bounded by Thai statutory standards, and ready for immediate implementation by Builder agents.
