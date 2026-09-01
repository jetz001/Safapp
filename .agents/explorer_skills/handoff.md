# Handoff Report: Agent Skills & CLI Blueprint for Thai Environmental Safety Law

**Agent**: Explorer Skills  
**Target Recipient**: Parent Orchestrator / Implementer Agent  
**Date**: 2026-09-01  
**Artifacts**:
- `d:\DEV\SAFAPP\.agents\explorer_skills\analysis.md`
- `d:\DEV\SAFAPP\.agents\explorer_skills\handoff.md`
- `d:\DEV\SAFAPP\.agents\explorer_skills\BRIEFING.md`
- `d:\DEV\SAFAPP\.agents\explorer_skills\progress.md`

---

## 1. Observation

1. **Existing Skills Structure**:
   - Inspected `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register`, `thai-chemical-safety-law`, and `electron-ai-benchmarker`.
   - Each skill contains `SKILL.md` with standard YAML frontmatter (`name`, `description`), `pyproject.toml` (PEP 621), `scripts/` with PEP 723 metadata header (`# /// script ... # ///`), pure Python standard library implementation, offline JSON catalogs in `scripts/data/`, and a `tests/` directory with automated `unittest` suites.
   - Cross-platform UTF-8 stream handling (`io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")`) is required to prevent encoding errors on Windows PowerShell.

2. **AgentResearch Scripts Integration**:
   - Inspected `D:\DEV\AgentResearch\Scripts/` (`thai_safety_legal_helper.py`, `thai_chem_helper.py`, `agent_research.py`, `planner.py`).
   - The multi-agent thesis system dynamically resolves helper modules via dual-mode invocation:
     - *Direct mode*: loads the Python engine class in-process if available.
     - *CLI fallback mode*: executes `subprocess.run([sys.executable, cli_path, ...])` capturing stdout and parsing JSON.
   - Helper scripts are duplicated or synchronized between the skill's `scripts/` directory and `D:\DEV\AgentResearch\Scripts/` to allow research agents to import them directly.

3. **Statutory Legal Foundation for Environmental Safety**:
   - **พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔**: มาตรา ๘ (มาตรฐาน), ๙ (ขึ้นทะเบียนบุคคลธรรมดา นบ.), ๑๑ (ใบอนุญาตตรวจวัดนิติบุคคล บ.), ๑๕ (ปิดประกาศผลตรวจวัด), ๓๒ (แผนควบคุม), ๕๓/๕๕/๕๖ (บทกำหนดโทษ).
   - **กฎกระทรวงความร้อน แสงสว่าง เสียง ๒๕๕๙**:
     - ความร้อน (ข้อ ๒): งานเบา $\le 34^\circ\text{C}$, งานปานกลาง $\le 32^\circ\text{C}$, งานหนัก $\le 30^\circ\text{C}$.
     - แสงสว่าง (ข้อ ๔): ต้องไม่ต่ำกว่าเกณฑ์มาตรฐานความเข้มแสงสว่าง.
     - เสียง (ข้อ ๗, ๘, ๑๑): Peak $\le 140\text{ dB}$, Continuous $\le 115\text{ dBA}$, 8-hr TWA limit $\le 86\text{ dBA}$, Action Level $\ge 85\text{ dBA}$ triggering Hearing Conservation Program.
     - ผู้ให้บริการตรวจวัด (ข้อ ๑๔): ต้องขึ้นทะเบียน ม.๙ หรือได้รับใบอนุญาต ม.๑๑.
     - รายงานผล (ข้อ ๑๕): ส่งรายงานผลตรวจวัดภายใน ๓๐ วัน นับแต่วันที่ตรวจวัดเสร็จสิ้น.
   - **ประกาศกรมฯ เรื่อง มาตรฐานความเข้มของแสงสว่าง ๒๕๖๑**: กำหนด Lux แยกตามประเภทงานและพื้นที่ (50 - >1,000 Lux).
   - **ประกาศกรมฯ เรื่อง มาตรฐานระดับเสียง ๒๕๖๑**: สูตร $T = 8 / 2^{(L-86)/3}$ และตารางเวลาการรับสัมผัสเสียงเทียบเท่า.
   - **ประกาศกรมฯ เรื่อง การคำนวณและประเมินระดับความร้อน ๒๕๖๓**: สูตร $\text{WBGT}_{\text{indoor}} = 0.7 T_{\text{nwb}} + 0.3 T_{\text{gt}}$ และ $\text{WBGT}_{\text{outdoor}} = 0.7 T_{\text{nwb}} + 0.2 T_{\text{gt}} + 0.1 T_{\text{db}}$.

---

## 2. Logic Chain

1. **Architecture Consistency**: Because both `thai-safety-legal-register` and `thai-chemical-safety-law` demonstrate high reliability and zero runtime dependencies, `thai-environmental-safety-law` must follow the exact same architecture (`SKILL.md`, `thai_env_cli.py`, `thai_env_engine.py`, `thai_env_helper.py`, embedded JSON catalogs, and `test_thai_env_skill.py`).
2. **Subcommand Interface Design**:
   - `search-light` addresses lighting intensity queries and threshold verification.
   - `eval-noise` handles TWA calculations, exchange rate mathematics, Action Level HCP triggers, and peak safety limits.
   - `calc-wbgt` encapsulates indoor and outdoor formula calculation and metabolic workload comparison.
   - `eval-session` enables batch processing of an entire workplace monitoring campaign (multi-point sampling + subcontractor compliance + CAPA plan synthesis).
   - `verify-subcontractor` validates Section 9 (นบ.) and Section 11 (บ.) licensing credentials.
   - `get-env-law` retrieves authoritative statutory articles.
3. **Multi-Agent Research Helper Interoperability**: Creating `D:\DEV\AgentResearch\Scripts\thai_env_helper.py` with identical class signatures allows seamless invocation by Research, Writer, and QA Agents in `D:\DEV\AgentResearch`.
4. **Test-Driven Verification**: A 12-test suite ensures mathematical precision for WBGT, noise dose integration, lighting categorization, license validation, and dual-mode helper execution.

---

## 3. Caveats

- **No Third-Party Python Dependencies**: The skill and helper must strictly use Python standard library modules (`math`, `json`, `argparse`, `sys`, `os`, `re`, `subprocess`, `unittest`, `datetime`, `typing`, `io`) without requiring `numpy`, `scipy`, or `pandas`.
- **Statutory Precision**: In Thai law, the 8-hour noise limit is **86 dBA** (not 85 or 90 dBA), but the Action Level for Hearing Conservation is **85 dBA**. Both thresholds must be strictly evaluated in code.
- **Indoor vs Outdoor WBGT**: In outdoor settings with direct solar load, the dry bulb temperature ($T_{\text{db}}$) with weight $0.1$ is legally required by the Department Notification B.E. 2563.

---

## 4. Conclusion

The blueprint for `thai-environmental-safety-law` and `D:\DEV\AgentResearch\Scripts\thai_env_helper.py` is fully defined and ready for direct implementation. It provides:
1. Complete SKILL.md specification and frontmatter.
2. CLI subcommands with argument schemas, JSON output structures, and tabular formats.
3. Python engine and dual-mode helper class (`ThaiEnvHelper`) design.
4. Comprehensive 12-case test suite (`test_thai_env_skill.py`).
5. Complete alignment between SAFAPP Flutter app, Gemini agent skill ecosystem, and AgentResearch multi-agent thesis workflows.

---

## 5. Verification Method

To verify the blueprint:
1. **Inspect Blueprint Artifacts**:
   - View `d:\DEV\SAFAPP\.agents\explorer_skills\analysis.md`.
2. **Cross-Check Existing Skill Layouts**:
   - `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register\scripts\thai_safety_legal_cli.py`
   - `C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law\scripts\thai_chem_cli.py`
   - `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`
3. **Post-Implementation Verification (to be executed by builder)**:
   - Run unittest: `python C:\Users\jetsa\.gemini\config\skills\thai-environmental-safety-law\tests\test_thai_env_skill.py`
   - Test CLI: `python C:\Users\jetsa\.gemini\config\skills\thai-environmental-safety-law\scripts\thai_env_cli.py calc-wbgt --nwb 28 --gt 36 -w moderate`
   - Test Helper: `python -c "from thai_env_helper import ThaiEnvHelper; h=ThaiEnvHelper(); print(h.eval_noise_exposure(88.5))"`
