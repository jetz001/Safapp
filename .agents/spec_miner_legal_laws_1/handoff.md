# 5-Component Handoff Report: Thai Safety Legal Specification Miner

**Date**: 2026-08-31T15:20:00Z  
**Agent**: `spec_miner_legal_laws_1` (Thai Safety Legal Spec Miner)  
**Parent Agent**: `bedb8118-4836-4c4c-a9fb-ce9e5b6459df`  
**Working Directory**: `d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1`  
**Deliverable Files**:
- `d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\legal_spec.md`
- `d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\safety_legal_catalog.json`

---

## ๑. Observation (สิ่งตรวจพบและหลักฐานเชิงประจักษ์)

1. **User Requirements & Scope (`ORIGINAL_REQUEST.md`)**:
   - `ORIGINAL_REQUEST.md` (lines 10-18): กำหนดกฎหมายราชกิจจานุเบกษาหลัก ๘ ฉบับที่ต้องครอบคลุมในระบบ Legal Register ของ SAFAPP:
     1. พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔
     2. กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕ (จป./คปอ.)
     3. กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖
     4. กฎกระทรวงป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕
     5. กฎกระทรวงไฟฟ้า พ.ศ. ๒๕๕๘
     6. กฎกระทรวงเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔
     7. กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙
     8. กฎกระทรวงตรวจสุขภาพตามปัจจัยเสี่ยง พ.ศ. ๒๕๖๓
   - `ORIGINAL_REQUEST.md` (lines 24-55): ระบุความต้องการ R1 (Master Safety Legal Catalog), R2 (Legal Register & Compliance Assessment Form & % KPI Calculation), R3 (CAPA Action Plan for Legal Compliance), R4 (Reference Repository, Attachments, Export PDF/Excel), และ R5 (Agent Skill `thai-safety-legal-register` & helper in `D:\DEV\AgentResearch\Scripts\thai_safety_legal_helper.py`).

2. **Existing Domain Skill Reference (`thai-chemical-safety-law`)**:
   - ตรวจพบไฟล์ `C:\Users\jetsa\.gemini\config\skills\thai-chemical-safety-law\SKILL.md` และ `references\laws_summary.md` ซึ่งระบุข้อกำหนดกฎหมายสารเคมี ๒๕๕๖ (แบบ สอ.๑ ภายใน ๗ วัน, สอ.๓ ตรวจวัดประจำปี เทียบค่า TLV ๓๒๔ รายการ, Eye Wash/Shower ภายใน ๑๐ วินาที, Bunding ๑๑๐%, และการขึ้นทะเบียน ม.๙/ม.๑๑).

3. **Existing SAFAPP Architecture (`lib/features/legal_register`)**:
   - ตรวจพบหน้า `lib\features\legal_register\presentation\pages\legal_page.dart` ในสถานะโครงร่างเริ่มต้น (Placeholder) พร้อมสำหรับการเชื่อมโยงกับ Clean Architecture Domain Models, Repository, Bloc/State Management, และ Presentation UI Tabs.

4. **AgentResearch Scripts Environment (`d:\DEV\AgentResearch\Scripts`)**:
   - ตรวจพบสคริปต์ `thai_chem_helper.py` ซึ่งเป็นรูปแบบตัวอย่าง (Standard Pattern) สำหรับการพัฒนา `thai_safety_legal_helper.py` เพื่อให้ Multi-Agent System สามารถเรียกใช้ฟังก์ชัน `search`, `get-law`, `evaluate`, และ `capa-summary` ได้อย่างมีประสิทธิภาพ.

---

## ๒. Logic Chain (ลำดับเหตุผลและการวิเคราะห์เชิงตรรกะ)

1. **การสกัดข้อกำหนดและโครงสร้างข้อมูลจากราชกิจจานุเบกษา (Statutory Mapping)**:
   - กฎหมายทั้ง ๘ ฉบับมีลำดับชั้นทางกฎหมายและหน่วยงานบังคับใช้เดียวกันคือ กรมสวัสดิการและคุ้มครองแรงงาน (DLPW) กระทรวงแรงงาน
   - กฎหมายแต่ละฉบับมีข้อกำหนดเชิงเทคนิคและเอกสารราชการที่ต้องใช้เป็นหลักฐาน (เช่น แบบ สปร. ๕, จป.ท. ๑, สอ.๑, สอ.๓, ปจ.๑/๒, บร.๑/๒, จปภ.๑, จปภ.๓) ซึ่งต้องถูกนำมาเป็น Metadata สำคัญในโมเดล `LegalItem` เพื่อให้ผู้ตรวจประเมินรู้ว่าต้องแนบไฟล์ประเภทใด.

2. **การออกแบบความสัมพันธ์ของเอนทิตี (Entity Relationships)**:
   - `LegalItem` (1) $\longleftrightarrow$ `LegalComplianceAssessment` (0..*) $\longleftrightarrow$ `LegalCapa` (0..1)
   - การประเมินสถานะ (`COMPLIANT`, `NON_COMPLIANT`, `IN_PROGRESS`, `NOT_APPLICABLE`) ต้องสามารถคำนวณสถิติภาพรวม % Compliance Index ได้ทันที ทั้งแบบพื้นฐาน (Basic Index) และแบบถ่วงน้ำหนักตามระดับความเสี่ยง (Weighted Risk Index).
   - เมื่อสถานะการประเมินเป็น `NON_COMPLIANT` หรือ `IN_PROGRESS` ระบบจะสามารถสร้างและเชื่อมโยง CAPA Record เพื่อกำหนดผู้รับผิดชอบ (PIC), สาเหตุรากเหง้า (Root Cause), และวันกำหนดเสร็จ (Target Date) ได้ทันที.

3. **การจัดเตรียม Master Seed Catalog**:
   - เพื่อให้โมดูลใน Flutter SAFAPP และ Agent Skill สามารถทำงานแบบ Offline Standalone ได้ทันที จึงได้จัดทำ `safety_legal_catalog.json` ที่บรรจุข้อมูลครบทั้ง ๘ กฎหมาย พร้อม ๓๒ รายการประเมินย่อยที่มีข้อความภาษาไทย/อังกฤษ เกณฑ์การบังคับใช้ เกณฑ์ความสอดคล้อง บทกำหนดโทษ และหลักฐานที่ต้องตรวจสอบอย่างครบถ้วน.

---

## ๓. Caveats (ข้อจำกัดและข้อควรระวัง)

1. **การอัปเดตระเบียบและประกาศกรมฯ เพิ่มเติมในอนาคต**:
   - กฎกระทรวงหลักทั้ง ๘ ฉบับมีผลบังคับใช้แล้ว แต่ในอนาคตอาจมีประกาศกรมสวัสดิการและคุ้มครองแรงงานเพิ่มเติม (เช่น การขยายรายการสารเคมีหรือการปรับปรุงแบบฟอร์มอิเล็กทรอนิกส์) สถาปัตยกรรมระบบจึงต้องรองรับการ Import/Update JSON Seed Catalog ผ่าน Local Storage หรือ API ได้.
2. **ขอบเขตกฎหมายเฉพาะของกระทรวงอื่น**:
   - การประเมินนี้เน้นกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ และกฎกระทรวงของกระทรวงแรงงานเป็นหลัก สำหรับกฎหมายโรงงาน (กระทรวงอุตสาหกรรม - DIW) หรือกฎหมายควบคุมอาคาร (มหาดไทย - DOPA) ถือเป็นกฎหมายเฉพาะที่สามารถเพิ่มเป็นส่วนขยาย (Extension Category) ในอนาคตได้.

---

## ๔. Conclusion (ข้อสรุปและผลการดำเนินงาน)

1. การขุดค้นและจัดทำข้อกำหนดกฎหมายราชกิจจานุเบกษา ๘ ฉบับเสร็จสมบูรณ์ 100% ครอบคลุม:
   - พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ (LAW-OSH-2554)
   - กฎกระทรวง จป./คปอ. ๒๕๖๕ (LAW-JPO-2565)
   - กฎกระทรวงสารเคมีอันตราย ๒๕๕๖ (LAW-CHEM-2556)
   - กฎกระทรวงป้องกันและระงับอัคคีภัย ๒๕๕๕ (LAW-FIRE-2555)
   - กฎกระทรวงไฟฟ้า ๒๕๕๘ (LAW-ELEC-2558)
   - กฎกระทรวงเครื่องจักร ปั้นจั่น หม้อน้ำ ๒๕๖๔ (LAW-MCH-2564)
   - กฎกระทรวงความร้อน แสงสว่าง เสียง ๒๕๕๙ (LAW-ENV-2559)
   - กฎกระทรวงตรวจสุขภาพตามปัจจัยเสี่ยง ๒๕๖๓ (LAW-HLT-2563)
2. โครงสร้างโมเดลข้อมูล `LegalItem`, `LegalComplianceAssessment`, `LegalCapa` และมาตรวัด % Compliance KPI Formula ได้รับการระบุไว้อย่างชัดเจนใน `legal_spec.md`.
3. ชุดข้อมูล Master JSON Seed Dataset บรรจุใน `safety_legal_catalog.json` พร้อมส่งมอบให้ทีมพัฒนา Flutter (Worker M1-M2, Worker M3-M4) และ Agent Skill Creator (Worker M5 Skill) นำไปใช้งานได้ทันที.

---

## ๕. Verification Method (วิธีการตรวจสอบความถูกต้อง)

1. **ตรวจสอบความถูกต้องของไฟล์ข้อกำหนดและโครงสร้าง JSON**:
   - ตรวจสอบไฟล์ `d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\legal_spec.md`
   - ตรวจสอบความสมบูรณ์ของ JSON syntax ใน `d:\DEV\SAFAPP\.agents\spec_miner_legal_laws_1\safety_legal_catalog.json` (มีกฎหมายครบ 8 ฉบับ และมีรายการประเมิน 32 รายการ).
2. **เงื่อนไขการ Invalidation**:
   - หากราชกิจจานุเบกษาประกาศแก้ไขกฎกระทรวงฉบับใหม่ ให้ปรับปรุง Law ID, Version, และข้อกำหนดใน Catalog ตามประกาศใหม่.
