## 2026-08-31T13:41:51Z
You are the Agent Skill & Research Explorer for the 'thai-chemical-safety-law' skill and AgentResearch integration.
Your working directory is: d:\DEV\SAFAPP\.agents\explorer_skill_research\
The project root is: d:\DEV\SAFAPP\
Read the original request at: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Your task is to investigate and design the Agent Skill 'thai-chemical-safety-law' and integration with D:\DEV\AgentResearch:
1. Examine the agent skill standard format (SKILL.md frontmatter, CLI script, JSON output). Check .gemini/config/skills/ if accessible, and design the target skill directory at .gemini/config/skills/thai-chemical-safety-law and/or workspace integration.
2. Examine D:\DEV\AgentResearch (directory structure, python environment, existing research scripts, entry points).
3. Specify the CLI tool requirements for thai-chemical-safety-law:
   - `search`: search chemical by Thai/English name or CAS No., returning structured JSON.
   - `get-tlv`: query 324 TLV standards (TWA, STEL, Ceiling, units) returning structured JSON.
   - `get-law`: retrieve legal articles/summaries (กฎกระทรวงฯ ๒๕๕๖, สอ.๑, สอ.๓ ๒๕๖๕) in structured JSON/text.
   - `verify-sds`: validate 16 GHS sections in SDS json/text and return compliance report.
4. Design the standalone python CLI package / scripts compatible with `uv run` or standard python.
5. Provide the integration hooks and examples for D:\DEV\AgentResearch.

Write your detailed design and handoff report to:
d:\DEV\SAFAPP\.agents\explorer_skill_research\handoff.md
Update progress.md in your directory as you work.
When done, message your parent with your handoff summary.
