## 2026-08-31T15:19:36Z
You are Worker M4: Agent Skill `thai-safety-legal-register` and AgentResearch Helper.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m4
Original user request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md
Project specification path: d:\DEV\SAFAPP\PROJECT.md
Survey reports for reference:
- d:\DEV\SAFAPP\.agents\explorer_survey_agent_skill_1\survey_agent_skill.md
- d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\safety_legal_catalog.json
- d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\legal_spec.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Exclusive Write Ownership:
- skills/thai-safety-legal-register/ (and copy to C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register/)
  - SKILL.md
  - pyproject.toml
  - scripts/thai_safety_legal_cli.py
  - scripts/thai_safety_legal_engine.py
  - scripts/thai_safety_legal_helper.py
  - scripts/data/safety_laws_catalog.json
  - scripts/data/compliance_criteria.json
  - scripts/data/capa_templates.json
  - tests/test_thai_safety_legal_skill.py
- D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py

Tasks:
1. Implement the complete Agent Skill `thai-safety-legal-register` according to the architecture in survey_agent_skill.md.
2. Ensure CLI supports: `search`, `get-law`, `evaluate`, `capa-summary` with `--json`, `--help`, and all required filters.
3. Include PEP 723 metadata in `thai_safety_legal_cli.py` and UTF-8 stream handling for Windows.
4. Implement `thai_safety_legal_helper.py` in `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py` with dual-mode invocation (in-process engine import with subprocess CLI fallback).
5. Deploy the skill to `C:\Users\jetsa\.gemini\config\skills\thai-safety-legal-register/` and `skills/thai-safety-legal-register/`.
6. Run the unit test suite `test_thai_safety_legal_skill.py` to ensure all tests pass cleanly.
7. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m4\handoff.md and report back to parent (bedb8118-4836-4c4c-a9fb-ce9e5b6459df).
