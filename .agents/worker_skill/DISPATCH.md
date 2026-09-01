## 2026-09-01T13:32:11Z

You are a specialized Agent Skill & Python Integration Worker for `thai-environmental-safety-law`.

Working Directory: d:\DEV\SAFAPP\.agents\worker_skill

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Scope & Tasks:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md and d:\DEV\SAFAPP\PROJECT.md.
2. Read analysis from d:\DEV\SAFAPP\.agents\explorer_skills\analysis.md and d:\DEV\SAFAPP\.agents\spec_miner_env\analysis.md.
3. Build the Agent Skill in `C:\Users\jetsa\.gemini\config\skills\thai-environmental-safety-law\`:
   - `SKILL.md` (complete instructions, YAML frontmatter, CLI usage examples, workflow rules)
   - `pyproject.toml` (PEP 621 package metadata)
   - `scripts/data/standards.json` (Light Lux catalog 2561, Noise limits 2561, Heat WBGT limits 2563, Royal Gazette catalog)
   - `scripts/thai_env_engine.py` (Pure Python standard library engine for WBGT calculations, Light lookup, Noise TWA & HCP eval, session batch eval, Subcontractor validation)
   - `scripts/thai_env_cli.py` (PEP 723 header, CLI subcommands: `search-light`, `eval-noise`, `calc-wbgt`, `eval-session`, `verify-subcontractor`, `get-env-law`, JSON & tabular outputs, UTF-8 wrapper for Windows)
   - `scripts/thai_env_helper.py` (Dual-mode helper module)
   - `tests/test_thai_env_skill.py` (12+ comprehensive unit tests covering all subcommands, edge cases, formulas, CLI outputs)
4. Implement Helper in `D:\DEV\AgentResearch\Scripts\thai_env_helper.py`:
   - Duplicate/deploy the dual-mode helper class `ThaiEnvHelper` so that AgentResearch agents can import and use it immediately.
5. Run the test suite:
   - Run `python C:\Users\jetsa\.gemini\config\skills\thai-environmental-safety-law\tests\test_thai_env_skill.py`
   - Run manual CLI test calls for `calc-wbgt`, `eval-noise`, `search-light`, `eval-session`.
   - Verify that all tests pass 100%.
6. Write detailed completion report to `d:\DEV\SAFAPP\.agents\worker_skill\handoff.md` with test commands and outputs. Send completion message to parent.
