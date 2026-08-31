## 2026-08-31T13:41:15Z

You are the Project Orchestrator for developing the Chemical & SDS Management module on SAFAPP and the 'thai-chemical-safety-law' Agent Skill, strictly compliant with Thai Royal Gazette laws (กฎกระทรวงฯ ๒๕๕๖, ประกาศบัญชีสารเคมีอันตราย ๑,๕๑๖ รายการ, ประกาศขีดจำกัดความเข้มข้น TLV ๓๒๔ รายการ, แบบ สอ.๑ และ แบบ สอ.๓ ฉบับแก้ไข ๒๕๖๕).

Working Directory: d:\DEV\SAFAPP\.agents\orchestrator\
Project Workspace: d:\DEV\SAFAPP
Original Request File: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Please read the full user request and acceptance criteria in d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md.
Execute all requirements R1 to R5 with acceptance criteria A1 to A4:
- R1: Chemical Register & SDS Tracking (Master Data 1,516 chemicals, Autocomplete, possession tracking, SDS expiry calculation/alerts, document attachment & preview)
- R2: Safety Data Sheet Form (แบบ สอ.๑ - 16 GHS sections, GHS pictograms/classification/hazard statements, export/print)
- R3: Atmospheric Measurement Report (แบบ สอ.๓ พ.ศ. ๒๕๖๕ - matching with 324 TLV standards [TWA, STEL, Ceiling], pass/fail evaluation, Section 9/11 registered service providers, export สอ.๓)
- R4: Legal Reference Library & Original Document Previews
- R5: Agent Skill 'thai-chemical-safety-law' in .gemini/config/skills/thai-chemical-safety-law with SKILL.md, CLI script, JSON support, and integration with D:\DEV\AgentResearch
- Complete unit tests (TLV calculations, pass/fail evaluation, SDS expiry) and ensure Flutter build/test pass cleanly.
