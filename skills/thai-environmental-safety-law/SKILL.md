---
name: thai-environmental-safety-law
description: >-
  Query Thai occupational environmental safety regulations (กฎกระทรวงความร้อน แสงสว่าง เสียง ๒๕๕๙), search lighting standards (ประกาศกรมฯ แสงสว่าง ๒๕๖๑), evaluate noise exposure & Hearing Conservation Program triggers (ประกาศกรมฯ เสียง ๒๕๖๑), calculate Indoor/Outdoor WBGT heat stress (ประกาศกรมฯ ความร้อน ๒๕๖๓), verify Subcontractor certifications (ม.๙ บุคคล & ม.๑๑ นิติบุคคล), and batch evaluate workplace environmental monitoring sessions with automated CAPA generation.
---

# Thai Environmental Safety Law & Workplace Monitoring (การตรวจวัดสภาพแวดล้อมในการทำงาน: แสงสว่าง เสียง ความร้อน WBGT)

Agent Skill สำหรับการสืบค้นมาตรฐานกฎหมายความปลอดภัยด้านสภาพแวดล้อมในการทำงานตามประกาศราชกิจจานุเบกษาแห่งราชอาณาจักรไทย คำนวณและประเมินผลความเข้มแสงสว่าง ระดับเสียงเฉลี่ย (8-hr TWA) ขนาดยินยอมเสียง (Noise Dose) โครงการอนุรักษ์การได้ยิน (Hearing Conservation Program) ดัชนีความร้อน WBGT ในร่มและกลางแจ้ง การตรวจสอบคุณสมบัติผู้ให้บริการตรวจวัด (Subcontractor ม.๙ บุคคลธรรมดา และ ม.๑๑ นิติบุคคล) และการประเมินผลรอบการตรวจวัดประจำปีพร้อมสร้างแผนปฏิบัติการแก้ไข (CAPA) อัตโนมัติ

## ๖ กฎหมายสภาพแวดล้อมราชกิจจานุเบกษาหลัก (6 Core Royal Gazette Enactments)

1. **พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔**
   - มาตรา ๘ (หน้าที่นายจ้างปฏิบัติตามมาตรฐาน), มาตรา ๙ (ขึ้นทะเบียนบุคคลธรรมดา นบ.), มาตรา ๑๑ (ใบอนุญาตตรวจวัดนิติบุคคล บ.), มาตรา ๑๕ (ปิดประกาศผล ๑๕ วัน & ส่งรายงานกรมฯ ๓๐ วัน), มาตรา ๓๒ (คำสั่งจัดทำแผนปรับปรุง CAPA)
2. **กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙**
   - ข้อ ๒ (ความร้อน WBGT), ข้อ ๔ (แสงสว่าง), ข้อ ๗-๘ (ระดับเสียง 86 dBA), ข้อ ๑๑ (โครงการอนุรักษ์การได้ยินเมื่อเสียง >= 85 dBA), ข้อ ๑๔ (ตรวจวัดประจำปี), ข้อ ๑๕ (จัดทำและเก็บรักษาแบบรายงาน ๕ ปี)
3. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑**
   - ตารางมาตรฐานความเข้มแสงสว่าง (Lux) ทุกหมวดหมู่งาน (ทางเดิน 20-100 Lux, สำนักงาน 300-400 Lux, งานละเอียด 400-600 Lux, ตรวจสอบคุณภาพ 600-1,000 Lux, งานละเอียดพิเศษ >1,000 Lux) และเกณฑ์แสงสว่างบริเวณรอบข้าง ($\ge 1/3$ และ $\ge 1/5$)
4. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานระดับเสียงที่ยอมให้ลูกจ้างได้รับเฉลี่ยตลอดระยะเวลาการทำงานในแต่ละวัน พ.ศ. ๒๕๖๑**
   - เกณฑ์ 8-hr TWA ($\le 86.0 \text{ dBA}$), เกณฑ์เฝ้าระวัง Action Level ($\ge 85.0 \text{ dBA}$), ขีดจำกัดเสียงต่อเนื่องสูงสุด ($< 115.0 \text{ dBA}$), เสียงกระทบกระแทก ($\le 140.0 \text{ dB}$), และสูตรคำนวณเวลาสูงสุด $T = 8 / 2^{(L-86)/3}$
5. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์และวิธีการตรวจวัดและคำนวณระดับความร้อน (WBGT) พ.ศ. ๒๕๖๓**
   - สูตรคำนวณในร่ม: $\text{WBGT} = 0.7 \times NWB + 0.3 \times GT$
   - สูตรคำนวณกลางแจ้ง: $\text{WBGT} = 0.7 \times NWB + 0.2 \times GT + 0.1 \times DB$
   - เกณฑ์ภาระงาน: งานเบา ($\le 34.0^\circ\text{C}$), งานปานกลาง ($\le 32.0^\circ\text{C}$), งานหนัก ($\le 30.0^\circ\text{C}$)
6. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงาน (แบบ อธ.๑)**

---

## Prerequisites

- **Python**: `>=3.10`
- **Dependencies**: Pure Python standard library (`math`, `json`, `argparse`, `os`, `sys`, `datetime`, `re`)
- **Catalogs**: Standalone JSON dataset (`scripts/data/standards.json`) บรรจุฐานข้อมูลความเข้มแสง ๕๐+ รายการ, ตารางเสียง, เกณฑ์ WBGT และข้อกฎหมาย

---

## Quick Start & CLI Subcommands

สคริปต์หลักเขียนตามมาตรฐาน PEP 723 สามารถเรียกใช้งานผ่าน `python` หรือ `uv run`:

### 1. ค้นหาและประเมินเกณฑ์ความเข้มแสงสว่าง (Search Lighting Standards)
```bash
python scripts/thai_env_cli.py search-light -q "ประกอบชิ้นส่วนอิเล็กทรอนิกส์" -v 350 -s 180
# หรือกรองตามหมวดหมู่
python scripts/thai_env_cli.py search-light -c office_administration --format table
```

### 2. ประเมินระดับเสียงและโครงการอนุรักษ์การได้ยิน (Evaluate Noise Exposure)
```bash
python scripts/thai_env_cli.py eval-noise -v 88.5 -t 8.0 --peak-db 125.0
```

### 3. คำนวณและประเมินความร้อน WBGT (Calculate WBGT Heat Stress)
```bash
# ในร่ม (Indoor)
python scripts/thai_env_cli.py calc-wbgt --nwb 28.5 --gt 38.0 -w moderate

# กลางแจ้ง (Outdoor with solar radiation)
python scripts/thai_env_cli.py calc-wbgt --nwb 29.0 --gt 42.0 --db 35.0 --outdoor -w heavy
```

### 4. ประเมินผลรอบการตรวจวัดประจำปีทั้งรอบ (Batch Session Evaluation & CAPA)
```bash
python scripts/thai_env_cli.py eval-session -f scripts/data/sample_env_session.json --format table
```

### 5. ตรวจสอบคุณสมบัติผู้ให้บริการตรวจวัด (Verify Subcontractor Certification)
```bash
python scripts/thai_env_cli.py verify-subcontractor -t section_11_juristic -n "บ. 0145-02/2564" -e "2027-12-31"
```

### 6. ดึงข้อกำหนดและมาตรากฎหมาย (Get Environmental Law Provisions)
```bash
python scripts/thai_env_cli.py get-env-law -t MIN-REG-ENV-2559 -s "ข้อ ๑๑"
```

---

## Multi-Agent Programmatic Integration (`AgentResearch`)

สำหรับนักวิจัยหรือเอเจนต์ในระบบ `D:\DEV\AgentResearch` สามารถเรียกใช้งานผ่าน `ThaiEnvHelper`:

```python
from thai_env_helper import ThaiEnvHelper

helper = ThaiEnvHelper()

# 1. Evaluate lighting
light_res = helper.search_light_standard(query="โต๊ะทำงาน", measured_lux=320.0)

# 2. Evaluate noise
noise_res = helper.eval_noise_exposure(measured_dba=89.0, duration_hours=8.0)

# 3. Calculate WBGT
heat_res = helper.calc_wbgt(nwb=28.5, gt=38.0, is_outdoor=False, workload_category="moderate")

# 4. Verify Subcontractor
subcon_res = helper.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0145-02/2564")
```
