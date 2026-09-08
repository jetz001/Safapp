## 2026-09-01T14:40:10Z

<USER_REQUEST>
You are Worker M5: Agent Skill 'thai-ptw-safety-law' & Python Tooling Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\worker_m5\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md and d:\DEV\SAFAPP\PROJECT.md.
2. Review d:\DEV\SAFAPP\.agents\explorer_skill_survey\analysis.md for exact specifications.
3. Build the Agent Skill in `C:\Users\jetsa\.gemini\config\skills\thai-ptw-safety-law\` and mirror in `d:\DEV\SAFAPP\skills\thai-ptw-safety-law\`:
   - `SKILL.md`: Complete metadata, YAML frontmatter, command descriptions, examples, references to Royal Gazette.
   - `pyproject.toml`: PEP 621 metadata.
   - `scripts/thai_ptw_engine.py`: Statutory rule engine implementing `evaluate_gas()`, `verify_confined_roles()`, `evaluate_fire_watch()`, `verify_loto()`, `validate_ptw()`, `get_checklist()`, `get_ptw_law()`.
   - `scripts/thai_ptw_cli.py`: CLI with subcommands `validate-ptw`, `eval-gas`, `verify-confined-roles`, `get-checklist`, `get-ptw-law` with UTF-8 stdout, robust JSON output, error handling.
   - `scripts/thai_ptw_helper.py`: Local helper class.
   - `tests/test_thai_ptw_skill.py`: 15+ automated unit tests covering all subcommands and edge cases.
4. Implement `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py`:
   - Dual-mode helper for multi-agent workflows in AgentResearch. Mode 1 in-memory engine, Mode 2 CLI fallback. Exposing `validate_ptw()`, `eval_gas()`, `verify_confined_roles()`, `check_hotwork_firewatch()`, `verify_loto()`, `get_checklist()`, `get_ptw_law()`.
5. Run the test suite: `python -m unittest discover -s skills/thai-ptw-safety-law/tests -p "test_*.py"` or `pytest` and ensure all tests pass 100%.
6. Write your handoff report to d:\DEV\SAFAPP\.agents\worker_m5\handoff.md following the Handoff Protocol.
7. Send completion message to parent.
</USER_REQUEST>
