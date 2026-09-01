## 2026-09-01T13:27:00Z
You are an Agent Skills & CLI Explorer.

Working Directory: d:\DEV\SAFAPP\.agents\explorer_skills
Your task is to analyze how existing agent skills and research helper scripts are implemented, structured, and tested, specifically:
1. Inspect `.gemini/config/skills/` (e.g. `thai-safety-legal-register`, `thai-chemical-safety-law`, `electron-ai-benchmarker`) to understand the standard SKILL.md structure, scripts/ CLI implementation, dependencies, and test conventions.
2. Inspect `D:\DEV\AgentResearch\Scripts` (e.g. `thai_safety_legal_helper.py`, `thai_chemical_helper.py` or similar) to understand how helper modules are structured, exported, and invoked by multi-agent research workflows.
3. Define the detailed blueprint for the new Agent Skill `thai-environmental-safety-law`:
   - SKILL.md definition and frontmatter
   - CLI commands (`search-light`, `eval-noise`, `calc-wbgt`, `eval-session`)
   - Argument parsing, output formats (JSON & human-readable markdown/tables)
   - Test suite for the skill scripts
   - Helper script `D:\DEV\AgentResearch\Scripts\thai_env_helper.py` interface and function signatures.

Inputs:
- Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md.
- Inspect `.gemini/config/skills/` and `D:\DEV\AgentResearch\Scripts`.

Outputs:
- Write your findings, CLI interface blueprint, and helper integration design to d:\DEV\SAFAPP\.agents\explorer_skills\analysis.md and d:\DEV\SAFAPP\.agents\explorer_skills\handoff.md.
- Send a completion message to parent.
