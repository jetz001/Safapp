---
name: thai-safety-legal-register
description: >-
  Search Thai occupational safety and health laws (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวง จป./คปอ. ๒๕๖๕, สารเคมี ๒๕๕๖, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, เครื่องจักร/ปั้นจั่น/หม้อน้ำ ๒๕๖๔, สิ่งแวดล้อม แสง/เสียง/ความร้อน ๒๕๕๙, ตรวจสุขภาพ ๒๕๖๓), retrieve Royal Gazette statutory articles, evaluate workplace legal compliance, and generate automated CAPA action plans.
---

# Thai Safety Legal Register & Compliance Evaluation (ทะเบียนกฎหมายความปลอดภัยและการประเมินความสอดคล้อง)

Agent Skill สำหรับการสืบค้นข้อกำหนดกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานตามประกาศราชกิจจานุเบกษาแห่งราชอาณาจักรไทย ๘ ฉบับหลัก ประเมินความสอดคล้องของสถานประกอบกิจการ และจัดทำแผนปฏิบัติการแก้ไขและป้องกัน (CAPA) อัตโนมัติ

## ๘ กฎหมายความปลอดภัยราชกิจจานุเบกษาหลัก (8 Core Royal Gazette Regulations)

1. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔** (เล่ม ๑๒๘ ตอนที่ ๔ ก)
2. **กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕** (เล่ม ๑๓๙ ตอนที่ ๔๑ ก)
3. **กฎกระทรวง กำหนดมาตรฐานฯ สารเคมีอันตราย พ.ศ. ๒๕๕๖** (เล่ม ๑๓๐ ตอนที่ ๑๑๓ ก)
4. **กฎกระทรวง กำหนดมาตรฐานฯ การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕** (เล่ม ๑๒๙ ตอนที่ ๑๓๐ ก)
5. **กฎกระทรวง กำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘** (เล่ม ๑๓๒ ตอนที่ ๑๑ ก)
6. **กฎกระทรวง กำหนดมาตรฐานฯ เครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔** (เล่ม ๑๓๘ ตอนที่ ๕๓ ก)
7. **กฎกระทรวง กำหนดมาตรฐานฯ ความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙** (เล่ม ๑๓๓ ตอนที่ ๙๑ ก)
8. **กฎกระทรวง กำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓** (เล่ม ๑๓๗ ตอนที่ ๗๖ ก)

---

## Prerequisites

- **Python**: `>=3.10`
- **Package Manager**: `uv` หรือ standard library (`argparse`, `json`, `os`, `sys`, `re`, `datetime`)
- **Offline Catalogs**: บรรจุฐานข้อมูลกฎหมาย ๘ ฉบับ (๔๐ ข้อกำหนด), กฎการประเมิน และ CAPA Templates อยู่ในตัวแบบ Standalone ไม่ต้องเชื่อมต่ออินเทอร์เน็ต

---

## Quick Start & CLI Subcommands

สคริปต์หลักเขียนตามมาตรฐาน PEP 723 สามารถเรียกใช้งานผ่าน `uv run` หรือ `python`:

### 1. ค้นหาข้อกฎหมายและมาตรา (Search Laws)
ค้นหาด้วยคำสำคัญ เช่น `"จป.วิชาชีพ"`, `"ดับเพลิง"`, `"หม้อน้ำ"`, `"ปั้นจั่น"`, `"85 dBA"`, `"สอ.๑"`, `"สปร.๕"`:

```bash
uv run scripts/thai_safety_legal_cli.py search -q "จป.วิชาชีพ" --limit 5
# หรือกรองตามหมวดหมู่
uv run scripts/thai_safety_legal_cli.py search -q "ตรวจรับรองประจำปี" -c electrical_2558
```

**ตัวอย่าง JSON Output:**
```json
{
  "status": "success",
  "query": "จป.วิชาชีพ",
  "category": "all",
  "total_found": 1,
  "results": [
    {
      "law_id": "LAW-02",
      "law_code": "LAW-JPO-2565",
      "title_th": "กฎกระทรวง การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน บุคลากร หน่วยงาน หรือคณะบุคคลฯ พ.ศ. ๒๕๖๕",
      "category": "jpor_cpo_2565",
      "req_id": "LAW-02-REQ-04",
      "item_id": "ITEM-JPO-001D",
      "article_no": "ข้อ ๑๕-๒๐",
      "requirement_title": "การแต่งตั้งเจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ) ประจำเต็มเวลา",
      "requirement_summary": "สถานประกอบกิจการบัญชี ๑ (ลูกจ้าง >= ๒ คน), บัญชี ๒ (ลูกจ้าง >= ๖๔ คน), หรือบัญชี ๓ (ลูกจ้าง >= ๒๐๐ คน) ต้องจัดให้มี จป.วิชาชีพ ปฏิบัติงานเต็มเวลา",
      "risk_level": "CRITICAL",
      "penalty_clause": "ระวางโทษจำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (พ.ร.บ. ม.๖๖)",
      "score": 150.0
    }
  ]
}
```

---

### 2. ดึงรายละเอียดและข้อกำหนดกฎหมายฉบับเต็ม (Get Law)
ระบุรหัสกฎหมาย (`LAW-01` ถึง `LAW-08` หรือชื่อย่อ เช่น `jpor_2565`, `fire_2555`, `chem_2556`) และระบุมาตรา/ข้อกำหนด:

```bash
uv run scripts/thai_safety_legal_cli.py get-law -i LAW-02 -s "ข้อ ๑๖"
```

---

### 3. ประเมินความสอดคล้องตามกฎหมายของสถานประกอบการ (Evaluate Compliance)
ประเมิน Profile ของสถานประกอบการ (จำนวนลูกจ้าง, บัญชีประเภทกิจการ, เครื่องจักร, ปั้นจั่น, หม้อน้ำ, สารเคมี, สภาพแวดล้อม):

```bash
uv run scripts/thai_safety_legal_cli.py evaluate -p scripts/data/sample_workplace_profile.json
```

**ตัวอย่างสรุปผลการประเมิน (Compliance KPI):**
- **% Compliance Index**: $C_{\text{index}} = \left( \frac{N_{\text{compliant}} + 0.5 \times N_{\text{in\_progress}}}{N_{\text{applicable}}} \right) \times 100\%$
- **Risk-Weighted Score**: $S_{\text{weighted}} = \left( \frac{\sum w_i s_i}{\sum w_i} \right) \times 100\%$ (CRITICAL=4, HIGH=3, MEDIUM=2, LOW=1)
- **Compliance Grade**: A (Excellent), B (Good), C (Needs Improvement), D (Critical Non-Compliance)

---

### 4. สร้างแผนปฏิบัติการแก้ไข CAPA อัตโนมัติ (CAPA Summary)
สร้างแผน CAPA พร้อมระบุสาเหตุรากเหง้า (Root Cause), มาตรการแก้ไข, ผู้รับผิดชอบ (PIC), วันกำหนดเสร็จ และหลักฐานปิดงาน:

```bash
uv run scripts/thai_safety_legal_cli.py capa-summary -i "LAW-02-REQ-04,LAW-05-REQ-01,LAW-06-REQ-02"
```

---

## Programmatic Usage in Python & AgentResearch

```python
from thai_safety_legal_helper import ThaiSafetyLegalHelper

helper = ThaiSafetyLegalHelper()

# 1. ค้นหากฎหมาย
search_res = helper.search_law("หม้อน้ำ บร.๒")

# 2. ประเมินความสอดคล้อง
eval_res = helper.evaluate_workplace("path/to/profile.json")

# 3. จัดทำแผน CAPA
capa_res = helper.generate_capa_summary(eval_result_or_file=eval_res)
```
