# DISPATCH

## 2026-08-31T13:41:51Z
You are the Thai Chemical Law Spec Miner for the Chemical & SDS Management module and Skill.
Your working directory is: d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\
The project root is: d:\DEV\SAFAPP\
Read the original request at: d:\DEV\SAFAPP\.agents\ORIGINAL_REQUEST.md

Your task is to exhaustively extract, verify, and document the Thai Royal Gazette legal specifications, datasets, and business logic:
1. ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง บัญชีรายชื่อสารเคมีอันตราย (1,516 รายการ: Thai Name, English Name, CAS Number, Sequence No.): Verify master dataset structure, search indexing requirements (Thai, English, CAS No.), autocomplete behavior.
2. ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง ขีดจำกัดความเข้มข้นของสารเคมีอันตราย (324 รายการ TLV: TWA 8-hr, STEL, Ceiling, units ppm / mg/m3): Map TLV calculation and automatic pass/fail evaluation rules.
3. แบบ สอ.๑ (SDS 16 หัวข้อตามมาตรฐาน GHS): Detail all 16 sections, GHS pictograms, signal words, hazard/precautionary statements, NFPA 704 diamond, export/print layout.
4. แบบ สอ.๓ (ฉบับแก้ไข พ.ศ. ๒๕๖๕): Atmospheric measurement report layout, Section 9 (นิติบุคคลที่ขึ้นทะเบียนตรวจวัด) and Section 11 (ผู้ขึ้นทะเบียนตรวจวัด) registration fields, calculation comparison with 324 TLVs, pass/fail status determination.
5. SDS Expiry & Tracking rules: Expiry calculation, status (Normal, Near Expiry within 30/60/90 days, Expired), review cycles (3-5 years).
6. Legal Reference Library: List of full legal documents with titles, gazette publication dates, descriptions, links / PDF preview structures.

Write your exhaustive specification report to:
d:\DEV\SAFAPP\.agents\specminer_thai_chemical_law\handoff.md
Update progress.md in your directory as you work.
When done, message your parent with your handoff summary.
