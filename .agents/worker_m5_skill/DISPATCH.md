## 2026-08-31T13:46:10Z

You are the Implementation Worker for Milestone 5 (Agent Skill 'thai-chemical-safety-law' & AgentResearch Integration).

Working Directory: d:\DEV\SAFAPP\.agents\worker_m5_skill\
Project Workspace: d:\DEV\SAFAPP\
Read the original request at: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Read the project specification at: d:\DEV\SAFAPP\PROJECT.md
Read the survey handoffs at:
- d:\DEV\SAFAPP\.agents\explorer_skill_research\handoff.md
- d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

File Ownership:
You exclusively own and will create/modify:
- skills/thai-chemical-safety-law/SKILL.md
- skills/thai-chemical-safety-law/pyproject.toml
- skills/thai-chemical-safety-law/scripts/thai_chem_cli.py (Standalone PEP 723 script)
- skills/thai-chemical-safety-law/scripts/thai_chem_law.py (Lookup & evaluation engine)
- skills/thai-chemical-safety-law/scripts/sds_validator.py (16-section GHS validator)
- skills/thai-chemical-safety-law/scripts/data/chemicals_1516.json (Complete 1,516 chemical database)
- skills/thai-chemical-safety-law/scripts/data/tlv_324.json (Complete 324 TLV database)
- skills/thai-chemical-safety-law/scripts/data/legal_articles_2556.json
- skills/thai-chemical-safety-law/scripts/data/sor_or_1_schema.json
- skills/thai-chemical-safety-law/scripts/data/sor_or_3_guidelines.json
- skills/thai-chemical-safety-law/references/ (Markdown legal reference guides)
- C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law\ (Ensure copied/installed)
- D:\DEV\AgentResearch\Scripts\thai_chem_helper.py (Integration helper)
- D:\DEV\AgentResearch\Agent\01_Research.md (Register SK-RES-09)

Requirements:
1. Implement full CLI with subcommands `search`, `get-tlv` (with evaluation engine for measured values vs standards), `get-law` (Ministerial 2556, Sor.Or.1, Sor.Or.3 2565), and `verify-sds` (validating 16 GHS sections).
2. Ensure CLI outputs clean, valid JSON to stdout or file.
3. Test all CLI commands via Python/`uv run` to ensure 100% working order.
4. Test `thai_chem_helper.py` in `D:\DEV\AgentResearch` to ensure smooth integration.

Write your handoff report to:
d:\DEV\SAFAPP\.agents\worker_m1_m5\handoff.md (or d:\DEV\SAFAPP\.agents\worker_m5_skill\handoff.md)
Update progress.md as you work.
When done, message your parent.
