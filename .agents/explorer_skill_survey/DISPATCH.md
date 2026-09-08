## 2026-09-01T14:35:36Z

<USER_REQUEST>
You are Explorer 3: Agent Skill & Python Tooling Specialist.
Your working directory is: d:\DEV\SAFAPP\.agents\explorer_skill_survey\
Original request path: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Instructions:
1. Read d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md thoroughly.
2. Investigate existing Thai safety skills in C:\Users\jetsa\.gemini\config\skills\ (e.g. thai-chemical-safety-law, thai-environmental-safety-law, thai-safety-legal-register):
   - Directory structure, SKILL.md format and metadata, CLI scripts (argument parsing, JSON output, error handling), reference legal texts or datasets.
   - Check if uv / python is used and how tests are written for these skills.
3. Investigate D:\DEV\AgentResearch\Scripts\ and determine how thai_ptw_helper.py should be designed to interface with the skill and provide programmatic API for multi-agent workflows in AgentResearch.
4. Design the complete specification for 'thai-ptw-safety-law' skill:
   - CLI commands: validate-ptw, eval-gas, verify-confined-roles, get-checklist, get-ptw-law.
   - Legal rule engine for Thai PTW regulations (พ.ร.บ. ๒๕๕๔, กฎกระทรวงอับอากาศ ๒๕๖๒, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, งานบนที่สูง/ดินขุด ๒๕๖๔).
   - Test suite design for the Python skill.
5. Write your detailed analysis to d:\DEV\SAFAPP\.agents\explorer_skill_survey\analysis.md.
6. Write your self-contained handoff to d:\DEV\SAFAPP\.agents\explorer_skill_survey\handoff.md following the Handoff Protocol.
7. Send a completion message back to parent.
</USER_REQUEST>
