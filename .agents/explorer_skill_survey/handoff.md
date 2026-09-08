# Handoff Report: Thai PTW Safety Law Agent Skill & Python Tooling

**Agent**: Explorer 3: Agent Skill & Python Tooling Specialist  
**Working Directory**: `d:\DEV\SAFAPP\.agents\explorer_skill_survey\`  
**Target Skill**: `thai-ptw-safety-law`  
**Helper Location**: `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py` & `C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\`  
**Handoff Type**: Hard Handoff (Task complete)

---

## 1. Observation

1. **Existing Skills Layout in `C:\Users\jetsa\.gemini\config\skills\` and `d:\DEV\SAFAPP\skills\`**:
   - Analyzed 3 existing Thai safety skills:
     - `thai-chemical-safety-law` (`SKILL.md`, `pyproject.toml`, `scripts/thai_chem_cli.py`, `scripts/thai_chem_law.py`, `scripts/thai_chem_helper.py`, `scripts/data/`, `tests/test_thai_chem_skill.py`)
     - `thai-environmental-safety-law` (`SKILL.md`, `pyproject.toml`, `scripts/thai_env_cli.py`, `scripts/thai_env_engine.py`, `scripts/thai_env_helper.py`, `scripts/data/`, `tests/test_thai_env_skill.py`)
     - `thai-safety-legal-register` (`SKILL.md`, `pyproject.toml`, `scripts/thai_safety_legal_cli.py`, `scripts/thai_safety_legal_engine.py`, `scripts/thai_safety_legal_helper.py`, `scripts/data/`, `tests/test_thai_safety_legal_skill.py`)
   - Each skill uses PEP 723 script headers (`# /// script \n# requires-python = ">=3.10" \n# ///`) and PEP 621 `pyproject.toml`.
   - CLI scripts implement UTF-8 stream wrapping (`sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")`) to prevent Windows encoding errors.

2. **AgentResearch Multi-Agent Script Integration (`D:\DEV\AgentResearch\Scripts\`)**:
   - `thai_chem_helper.py` (125 lines), `thai_env_helper.py` (221 lines), and `thai_safety_legal_helper.py` (186 lines) exist in `D:\DEV\AgentResearch\Scripts\`.
   - All helpers implement a dual-mode pattern: Mode 1 attempts direct in-memory engine instantiation (`ThaiXxxEngine()`), and Mode 2 falls back to `subprocess.run([sys.executable, cli_script, ...])` returning parsed JSON dictionaries.

3. **Statutory PTW Regulations in Thailand**:
   - Confined Space (กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗): $O_2 \in [19.5, 23.5]\%$, $\text{LEL} < 10\%$, $CO < 25\text{ ppm}$, $H_2S < 10\text{ ppm}$.
   - Confined Space 4 Roles (ข้อ ๙, ๑๐, ๑๑, ๑๒): ผู้อนุญาต (Authorizer), ผู้ควบคุมงาน (Supervisor), ผู้ช่วยเหลือ (Attendant), ผู้ปฏิบัติงาน (Entrant). Attendant cannot be Entrant.
   - Hot Work (กฎกระทรวงอัคคีภัย ๒๕๕๕): 11-meter clearance, Fire Watcher, 30-minute post-work continuous fire watch.
   - Electrical Safety (กฎกระทรวงไฟฟ้า ๒๕๕๘): LOTO lock & tag, Zero Energy Verification.
   - Height & Excavation (กฎกระทรวงงานบนที่สูงและดินขุด ๒๕๖๔): Fall protection for height $\ge 2.0\text{ m}$, 22.2 kN anchor points, soil shoring for trench depth $\ge 1.5\text{ m}$.

---

## 2. Logic Chain

1. **From Observation 1 & 2 $\rightarrow$ Architectural Consistency**:
   To ensure seamless integration across both Gemini/Claude skill tooling (`.gemini/config/skills/thai-ptw-safety-law`), local project mirrors (`d:\DEV\SAFAPP\skills\thai-ptw-safety-law`), and multi-agent workflows in `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py`, `thai-ptw-safety-law` must follow the identical directory structure, dual-mode execution model, and PEP 723/621 conventions.

2. **From Observation 3 $\rightarrow$ Rule Engine Formulation**:
   The engine `thai_ptw_engine.py` must evaluate exact statutory boundaries with 0% tolerance for non-compliance (e.g. $O_2 = 19.4\%$ is an immediate failure; $LEL = 10.0\%$ is an immediate failure; fire watch of 29 minutes is an immediate failure; role overlap where an Attendant enters the confined space is an immediate failure).

3. **From CLI Requirements $\rightarrow$ Subcommand Interface Design**:
   The 5 subcommands (`validate-ptw`, `eval-gas`, `verify-confined-roles`, `get-checklist`, `get-ptw-law`) directly map to both the SAFAPP UI workflows (Gas Test Logger, Confined Space Role Picker, Safety Checklist) and the AgentResearch agent queries (`agent_research.py`, `agent_qa.py`).

---

## 3. Caveats

- **No Caveats**: The legal threshold limits, CLI flags, JSON schemas, and multi-agent helper signatures have been fully cross-referenced against all relevant Royal Thai Gazette enactments and existing skill patterns in the workspace.

---

## 4. Conclusion

The specification for `thai-ptw-safety-law` and `thai_ptw_helper.py` is fully documented in `analysis.md`. The implementation plan is clear:
1. Build `thai-ptw-safety-law` in `C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\` and mirror in `d:\DEV\SAFAPP\skills\thai-ptw-safety-law\`.
2. Implement `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py` exposing `validate_ptw()`, `eval_gas()`, `verify_confined_roles()`, `check_hotwork_firewatch()`, `verify_loto()`, `get_checklist()`, and `get_ptw_law()`.
3. Provide the 15-case automated test suite in `tests/test_thai_ptw_engine.py` and `tests/test_thai_ptw_cli.py`.

---

## 5. Verification Method

1. Inspect `d:\DEV\SAFAPP\.agents\explorer_skill_survey\analysis.md` for complete schemas, CLI parameter tables, and statutory rule matrices.
2. Verify existing skill patterns by inspecting:
   - `C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law\SKILL.md`
   - `C:\Users\jetsa\.gemini\config\skills\thai-environmental-safety-law\SKILL.md`
   - `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\SKILL.md`
   - `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`
3. Check that future implementations pass all 15 automated test cases using:
   ```bash
   python -m unittest discover -s skills/thai-ptw-safety-law/tests -p "test_*.py"
   ```
