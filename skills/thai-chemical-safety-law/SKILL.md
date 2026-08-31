---
name: thai-chemical-safety-law
description: >-
  Query Thai hazardous chemical safety regulations (กฎกระทรวงฯ ๒๕๕๖), search 1,516 regulated chemicals, lookup 324 TLV standards (TWA/STEL/Ceiling), retrieve Sor.Or. 1 (สอ.๑) SDS 16 sections, Sor.Or. 3 (สอ.๓ ๒๕๖๕) measurement guidelines, and verify SDS compliance.
---

# Thai Chemical Safety Law (กฎหมายความปลอดภัยสารเคมีอันตรายและค่ามาตรฐาน TLV)

Agent Skill สำหรับการค้นคว้า สืบค้นข้อกำหนดกฎหมายความปลอดภัยสารเคมีอันตรายตามประกาศราชกิจจานุเบกษาแห่งราชอาณาจักรไทย ตรวจสอบค่าขีดจำกัดความเข้มข้นสารเคมีในบรรยากาศสถานที่ทำงาน (324 รายการ TLV), แบบ สอ.๑ (SDS 16 หัวข้อ GHS), แบบ สอ.๓ (รายงานผลการตรวจวัด พ.ศ. ๒๕๖๕) และการประเมินความสอดคล้องทางกฎหมาย

## Prerequisites

1. **Python / `uv`**: Python >= 3.10 พร้อม `uv` หรือ standard library (`argparse`, `json`, `os`, `re`, `sys`).
2. **Offline Data**: ฐานข้อมูลสารเคมี ๑,๕๑๖ รายการ และค่า TLV ๓๒๔ รายการ ติดตั้งอยู่ภายในเครื่องแบบ Standalone ไม่ต้องเชื่อมต่อเครือข่ายภายนอก

---

## Quick Start & CLI Commands

สคริปต์หลักเขียนตามมาตรฐาน PEP 723 สามารถเรียกใช้งานผ่าน `uv run` หรือ `python`:

### 1. ค้นหาข้อมูลสารเคมีอันตราย (Search Chemical)
ค้นหาด้วยชื่อภาษาไทย, ภาษาอังกฤษ, CAS Number, UN Number หรือเลขลำดับ:

```bash
uv run scripts/thai_chem_cli.py search -q "Toluene" --limit 5
# หรือค้นหาด้วย CAS Number
uv run scripts/thai_chem_cli.py search -q "7647-01-0"
# หรือค้นหาด้วยชื่อภาษาไทย
uv run scripts/thai_chem_cli.py search -q "กรดกำมะถัน"
```

**ตัวอย่าง JSON Output:**
```json
{
  "status": "success",
  "query": "Toluene",
  "total_found": 1,
  "results": [
    {
      "id": 1,
      "seq_no": 1,
      "name_th": "โทลูอีน (เมทิลเบนซีน)",
      "name_en": "Toluene",
      "cas_no": "108-88-3",
      "formula": "C7H8",
      "molecular_weight": 92.14,
      "un_no": "1294",
      "is_regulated_1516": true,
      "has_tlv_324": true,
      "tlv": {
        "item_no": 1,
        "twa_ppm": 200.0,
        "twa_mg_m3": 753.0,
        "stel_ppm": 300.0,
        "stel_mg_m3": 1130.0,
        "ceiling_ppm": 500.0,
        "ceiling_mg_m3": 1883.0,
        "notation": "Skin",
        "remarks": "ตัวทำละลายอินทรีย์ ดูดซึมผ่านผิวหนัง"
      },
      "sds_required": true,
      "sor_or_1_applicable": true,
      "sor_or_3_testing_required": true
    }
  ]
}
```

---

### 2. ตรวจสอบค่าขีดจำกัดความเข้มข้น TLV และประเมินผลตรวจวัด (Get TLV & Evaluate)
ค้นหาค่ามาตรฐาน TWA 8-hr, STEL 15-min หรือ Ceiling พร้อมประเมินผลค่าตรวจวัดจริงเทียบกับกฎหมาย:

```bash
# ตรวจสอบค่ามาตรฐานโทลูอีน
uv run scripts/thai_chem_cli.py get-tlv -q "108-88-3"

# ประเมินผลค่าตรวจวัด 225.5 ppm เทียบกับ TWA (มาตรฐาน 200 ppm)
uv run scripts/thai_chem_cli.py get-tlv -q "108-88-3" --eval-val 225.5 --eval-type twa --eval-unit ppm
```

**ตัวอย่าง JSON Output (การประเมินผล):**
```json
{
  "status": "success",
  "substance": {
    "name_th": "โทลูอีน (เมทิลเบนซีน)",
    "name_en": "Toluene",
    "cas_no": "108-88-3",
    "standard_limits": {
      "twa_ppm": 200.0,
      "twa_mg_m3": 753.0,
      "stel_ppm": 300.0,
      "stel_mg_m3": 1130.0,
      "ceiling_ppm": 500.0,
      "ceiling_mg_m3": 1883.0,
      "notation": "Skin"
    }
  },
  "evaluation": {
    "measured_value": 225.5,
    "unit": "ppm",
    "metric": "TWA (8-hour Time-Weighted Average)",
    "legal_limit": 200.0,
    "ratio_to_standard": 1.1275,
    "percent_of_standard": 112.75,
    "status": "EXCEEDED",
    "is_compliant": false,
    "color_code": "RED",
    "action_required": "เกินค่าขีดจำกัดความเข้มข้นตามกฎหมาย (112.8% ของมาตรฐาน)! นายจ้างต้องปรับปรุงระบบระบายอากาศ/ระบบวิศวกรรมทันที และส่งรายงานแบบ สอ.๓ ภายใน ๑๕ วัน"
  }
}
```

---

### 3. ดึงข้อกำหนดกฎหมายและแนวทางปฏิบัติ (Get Law & Guidelines)

```bash
# ดึงข้อกำหนดการตรวจวัดและรายงาน สอ.๓ พ.ศ. ๒๕๖๕
uv run scripts/thai_chem_cli.py get-law -t sor_or_3_2565

# ดึงโครงสร้างแบบฟอร์ม สอ.๑ (SDS 16 หัวข้อ)
uv run scripts/thai_chem_cli.py get-law -t sor_or_1

# ดึงข้อกำหนดผู้ตรวจวัดขึ้นทะเบียน ม.๙ และ ม.๑๑
uv run scripts/thai_chem_cli.py get-law -t registered_testers
```

---

### 4. ตรวจสอบความถูกต้องสมบูรณ์ของเอกสาร SDS (Verify SDS 16 Sections)

```bash
uv run scripts/thai_chem_cli.py verify-sds -f scripts/data/sample_sds.json
```

**ตัวอย่าง JSON Output:**
```json
{
  "status": "success",
  "compliant": true,
  "compliance_rate_percent": 100.0,
  "total_sections": 16,
  "valid_sections": 16,
  "missing_sections": [],
  "validation_report": [
    {
      "section": 1,
      "title": "ข้อมูลเกี่ยวกับสารเคมีอันตรายและบริษัทผู้ผลิตและหรือนำเข้า",
      "status": "PASS",
      "details": "Found complete content."
    }
  ],
  "recommendations": [
    "สารเคมีนี้อยู่ในบัญชี TLV ๓๒๔ รายการ (TWA: 200.0 ppm / 753.0 mg/m3) ต้องระบุค่ามาตรฐานไทยนี้ในหมวดที่ 8"
  ]
}
```

---

### 5. ประเมินผลกระทบสารเคมีผสม (Chemical Mixture Exposure Index $E_m$)

```bash
uv run scripts/thai_chem_cli.py eval-mixture -c '[{"chemical": "Toluene", "measured_value": 100.0, "unit": "ppm"}, {"chemical": "Xylene", "measured_value": 60.0, "unit": "ppm"}]'
```

$$E_m = \frac{100}{200} + \frac{60}{100} = 0.50 + 0.60 = 1.10 \quad (> 1.0 \rightarrow \text{EXCEEDED})$$

---

### 6. แปลงหน่วยความเข้มข้น (Unit Conversion ppm $\leftrightarrow$ mg/m³)

```bash
uv run scripts/thai_chem_cli.py convert-unit -v 50.0 --from-unit ppm --to-unit mg_m3 --mw 92.14
```

---

## AgentResearch Integration (`D:\DEV\AgentResearch`)

สคริปต์ในระบบ Multi-Agent Research สามารถเรียกใช้งานผ่านโมดูล `ThaiChemLawHelper`:

```python
from Scripts.thai_chem_helper import ThaiChemLawHelper

helper = ThaiChemLawHelper()
result = helper.search_chemical("Benzene")
tlv_eval = helper.get_tlv("Benzene", eval_val=0.6, eval_type="twa")
print(tlv_eval["evaluation"]["status"])  # "EXCEEDED"
```
