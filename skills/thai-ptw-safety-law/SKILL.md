---
name: thai-ptw-safety-law
description: >-
  Validate High-Risk Permit to Work (PTW) workflows, evaluate Confined Space gas testing (O2, LEL, CO, H2S), verify 4-role duty holders (Authorizer, Supervisor, Attendant, Entrant), audit Hot Work 30-min fire watch, inspect LOTO zero energy isolation, retrieve statutory safety checklists, and query Thai safety laws (พ.ร.บ. ๒๕๕๔, กฎกระทรวงอับอากาศ ๒๕๖๒, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, นั่งร้าน/งานบนที่สูง/ดินขุด ๒๕๖๔).
---

# Thai PTW Safety Law & High-Risk Permit Verification (ระบบตรวจสอบใบอนุญาตทำงานความเสี่ยงสูงตามกฎหมายไทย)

Agent Skill สำหรับการตรวจสอบความถูกต้องของระบบใบอนุญาตทำงานความเสี่ยงสูง (Permit to Work - PTW) ประเมินผลการตรวจวัดก๊าซในสถานที่อับอากาศ (Gas Testing) ตรวจสอบคุณสมบัติและบทบาทหน้าที่ ๔ ฝ่ายในที่อับอากาศ การเฝ้าระวังอัคคีภัยหลังงาน Hot Work ๓๐ นาที การตัดแยกพลังงาน Lockout/Tagout (LOTO) และการดึงข้อกำหนดกฎหมายจากประกาศราชกิจจานุเบกษาแห่งราชอาณาจักรไทย ๕ ฉบับหลัก

---

## ๕ กฎหมายความปลอดภัยราชกิจจานุเบกษาหลัก (5 Core Royal Gazette Regulations)

1. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔** (เล่ม ๑๒๘ ตอนที่ ๔ ก)
2. **กฎกระทรวง กำหนดมาตรฐานฯ ในสถานที่อับอากาศ พ.ศ. ๒๕๖๒** (เล่ม ๑๓๖ ตอนที่ ๖๓ ก)
   - เกณฑ์บรรยากาศอันตราย: $O_2$ (19.5% - 23.5%), $\text{LEL} < 10\%$, $CO < 25\text{ ppm}$, $H_2S < 10\text{ ppm}$
   - ผู้มีหน้าที่ ๔ ฝ่าย: ผู้อนุญาต, ผู้ควบคุมงาน, ผู้ช่วยเหลือ, ผู้ปฏิบัติงาน
3. **กฎกระทรวง กำหนดมาตรฐานฯ การป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕** (เล่ม ๑๒๙ ตอนที่ ๑๓๐ ก)
   - งาน Hot Work: เคลียร์พื้นที่รัศมี ๑๑ เมตร, เครื่องดับเพลิงพร้อมใช้ ๒ เครื่อง, ผู้เฝ้าระวังไฟ (Fire Watcher), เฝ้าระวังต่อเนื่องหลังเสร็จงาน $\ge 30\text{ นาที}$
4. **กฎกระทรวง กำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘** (เล่ม ๑๓๒ ตอนที่ ๑๑ ก)
   - การตัดแยกพลังงาน Lockout / Tagout (LOTO) และการตรวจสอบสภาพไร้พลังงาน (Zero Energy Verification)
5. **กฎกระทรวง กำหนดมาตรฐานฯ นั่งร้าน งานบนที่สูง และงานดินขุด พ.ศ. ๒๕๖๔** (เล่ม ๑๓๘ ตอนที่ ๕๓ ก)
   - งานบนที่สูง $\ge 2.0\text{ ม.}$ ต้องใช้ Full Body Harness & จุดยึด $\ge 22.2\text{ kN}$
   - งานดินขุดลึก $\ge 1.5\text{ ม.}$ ต้องมีระบบค้ำยัน (Shoring) และสำรวจสาธารณูปโภคใต้ดิน

---

## Prerequisites

- **Python**: `>=3.10`
- **Dependencies**: Pure Python Standard Library (Offline-first Standalone JSON Datasets in `scripts/data/`)

---

## Quick Start & CLI Subcommands

สามารถเรียกใช้งานผ่าน `uv run` หรือ `python scripts/thai_ptw_cli.py <subcommand>`:

### 1. ประเมินผลตรวจวัดก๊าซในที่อับอากาศ (Evaluate Gas Testing)
ประเมินค่า $O_2, \text{LEL}, CO, H_2S$ ตามกฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗:

```bash
python scripts/thai_ptw_cli.py eval-gas --o2 20.9 --lel 0.0 --co 2.0 --h2s 0.0
# หรือแบบแสดงตารางสรุป
python scripts/thai_ptw_cli.py eval-gas --o2 18.0 --lel 12.0 --co 30.0 --h2s 15.0 --format table
```

**ตัวอย่าง JSON Output:**
```json
{
  "status": "success",
  "overall_status": "SAFE_TO_ENTER",
  "is_safe": true,
  "statutory_reference": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒ ข้อ ๗",
  "readings": {
    "oxygen": {
      "value": 20.9,
      "unit": "%",
      "standard_range": "19.5 - 23.5%",
      "status": "PASS",
      "code": "OXYGEN_NORMAL",
      "alarm_level": "NONE",
      "detail": "ค่าออกซิเจน 20.9% อยู่ในเกณฑ์ปกติและปลอดภัย (19.5% - 23.5%)"
    },
    "combustible_gas": {
      "value": 0.0,
      "unit": "% LEL",
      "standard_limit": "< 10.0% LEL",
      "status": "PASS",
      "code": "LEL_SAFE",
      "alarm_level": "NONE",
      "detail": "ค่าก๊าซไวไฟ 0.0% LEL ปลอดภัย (< 10.0% LEL)"
    },
    "carbon_monoxide": {
      "value": 2.0,
      "unit": "ppm",
      "standard_limit": "< 25.0 ppm",
      "status": "PASS",
      "code": "CO_SAFE",
      "alarm_level": "NONE",
      "detail": "ค่าคาร์บอนมอนอกไซด์ 2.0 ppm อยู่ในเกณฑ์ปลอดภัย (< 25.0 ppm)"
    },
    "hydrogen_sulfide": {
      "value": 0.0,
      "unit": "ppm",
      "standard_limit": "< 10.0 ppm",
      "status": "PASS",
      "code": "H2S_SAFE",
      "alarm_level": "NONE",
      "detail": "ค่าก๊าซไข่เน่า (H2S) 0.0 ppm อยู่ในเกณฑ์ปลอดภัย (< 10.0 ppm)"
    }
  },
  "findings": [],
  "actions": [
    "อนุญาตให้เข้าปฏิบัติงานได้ตามขั้นตอนความปลอดภัย",
    "ต้องเปิดพัดลมระบายอากาศแบบกลไก (Forced Mechanical Ventilation) ต่อเนื่องตลอดเวลาการทำงาน",
    "จัดให้มีการตรวจวัดซ้ำทุก ๑-๒ ชั่วโมง หรือติดตั้งเครื่องตรวจวัดแบบพกพาชนิดต่อเนื่อง"
  ]
}
```

---

### 2. ตรวจสอบผู้มีหน้าที่ ๔ ฝ่ายในที่อับอากาศ (Verify Confined Roles)
ตรวจสอบความครบถ้วนและข้อห้ามการซ้อนทับหน้าที่ (ผู้ช่วยเหลือห้ามเป็นผู้ปฏิบัติงาน):

```bash
python scripts/thai_ptw_cli.py verify-confined-roles \
  --authorizer "นายทรงศักดิ์ มั่นคง:AUTH-001" \
  --supervisor "นายกานต์ สุภาพ:SUP-002" \
  --attendant "นายสมบัติ พร้อมช่วย:ATT-003" \
  --entrants "นายอนุชา ว่องไว:ENT-004,นายณัฐพล ช่างฝีมือ:ENT-005"
```

---

### 3. ตรวจสอบความถูกต้องของใบอนุญาตทำงาน PTW ฉบับเต็ม (Validate PTW)
ตรวจสอบตามประเภทงานความเสี่ยงสูง (Hot Work, Confined Space, Working at Height, Electrical LOTO, Excavation):

```bash
python scripts/thai_ptw_cli.py validate-ptw -f scripts/data/sample_ptws.json -t confined_space
```

---

### 4. ดึงรายการ Safety Checklist มาตรฐาน (Get Checklist)
ดึงข้อกำหนดตรวจความปลอดภัยตามประเภทงาน:

```bash
python scripts/thai_ptw_cli.py get-checklist -t hot_work
python scripts/thai_ptw_cli.py get-checklist -t confined_space
python scripts/thai_ptw_cli.py get-checklist -t all
```

---

### 5. ค้นหาข้อกฎหมายและประกาศราชกิจจานุเบกษา (Get PTW Law & Search)
สืบค้นข้อกำหนดและบทกำหนดโทษ:

```bash
python scripts/thai_ptw_cli.py get-ptw-law -q "บรรยากาศอันตราย"
python scripts/thai_ptw_cli.py get-ptw-law -t confined_2562 -s "ข้อ ๗"
```

---

## Programmatic Usage in Python & Multi-Agent Systems

```python
from thai_ptw_helper import ThaiPtwHelper

helper = ThaiPtwHelper()

# 1. ตรวจวัดก๊าซในที่อับอากาศ
gas_res = helper.eval_gas(o2=20.9, lel=0.0, co=2.0, h2s=0.0)

# 2. ตรวจสอบผู้มีหน้าที่ 4 ฝ่าย
roles_res = helper.verify_confined_roles(
    authorizer={"name": "นายสมศักดิ์", "cert_no": "AUTH-101"},
    supervisor={"name": "นายวิชัย", "cert_no": "SUP-102"},
    attendant={"name": "นายธงชัย", "cert_no": "ATT-103"},
    entrants=[{"name": "นายดำรง", "cert_no": "ENT-104"}]
)

# 3. ตรวจสอบการเฝ้าระวังไฟ Hot Work 30 นาที
hw_res = helper.check_hotwork_firewatch(
    monitoring_minutes=35.0,
    fire_watcher_name="นายเอกชัย ตาไว",
    extinguisher_ready=True,
    area_cleared_11m=True
)

# 4. ตรวจสอบใบอนุญาต PTW ฉบับเต็ม
val_res = helper.validate_ptw("path/to/ptw.json")
```
