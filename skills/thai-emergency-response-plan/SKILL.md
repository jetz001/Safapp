---
name: thai-emergency-response-plan
description: >-
  Validate Multi-Hazard Emergency Response Plans (ERP) in Thailand, verify 6 statutory sub-plans (Inspection, Training, Campaign, Suppression, Evacuation, Relief per Ministerial Reg B.E. 2555 & 2556), audit annual fire & chemical drill compliance and Form สปร. ๔ deadlines, calculate 40% basic firefighting training quotas, compute fire extinguisher density & travel distances, and retrieve statutory emergency laws.
---

# Thai Multi-Hazard Emergency Response Plan & Statutory Drill Verification (ระบบจัดทำและตรวจสอบแผนฉุกเฉินตามกฎหมายไทย)

Agent Skill สำหรับการตรวจสอบและประเมินความสอดคล้องของแผนป้องกันและระงับอัคคีภัย ๖ เสาหลักตามกฎกระทรวงอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๔ รวมถึงแผนตอบโต้ภาวะฉุกเฉินสารเคมีรั่วไหล (HAZMAT) อุทกภัย (น้ำท่วม) และแผ่นดินไหว พร้อมระบบตรวจสอบการฝึกซ้อมอพยพหนีไฟประจำปีและการจัดส่งรายงานแบบ สปร. ๔ ภายใน ๓๐ วันตามกฎหมาย

---

## กฎหมายความปลอดภัยและมาตรฐานอ้างอิงหลัก

1. **กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕** (ราชกิจจานุเบกษา เล่ม ๑๓๐ ตอนที่ ๒ ก)
   - **ข้อ ๔**: สถานประกอบกิจการที่มีลูกจ้างตั้งแต่ ๑๐ คนขึ้นไป ต้องมีแผน ๖ เสาหลัก (ตรวจตรา, อบรม, รณรงค์, ดับเพลิง, อพยพหนีไฟ, บรรเทาทุกข์)
   - **ข้อ ๑๑**: เครื่องดับเพลิงแบบเคลื่อนย้ายได้ ระยะห่างไม่เกิน ๒๐ เมตร ส่วนบนสุดสูงจากพื้นไม่เกิน ๑.๕๐ เมตร
   - **ข้อ ๒๗**: ลูกจ้างไม่น้อยกว่าร้อยละ ๔๐ ในแต่ละแผนกต้องผ่านการฝึกอบรมการดับเพลิงขั้นต้น
   - **ข้อ ๓๐**: ฝึกซ้อมดับเพลิงและอพยพหนีไฟพร้อมกันอย่างน้อยปีละ ๑ ครั้ง และจัดส่งรายงาน สปร. ๔ ภายใน ๓๐ วัน
2. **ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง กำหนดแบบรายงานผลการฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟ** (แบบ สปร. ๔)
3. **กฎกระทรวง กำหนดมาตรฐานฯ สารเคมีอันตราย พ.ศ. ๒๕๕๖** (ข้อ ๒๙-๓๐ แผนฉุกเฉินสารเคมีและทีม ERT)
4. **พ.ร.บ. ป้องกันและบรรเทาสาธารณภัย พ.ศ. ๒๕๕๐** (แผนป้องกันอุทกภัยและแผ่นดินไหว)
5. **กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘**
   - **ข้อ ๑๒**: นายจ้างต้องจัดให้มีการตรวจสอบและรับรองระบบไฟฟ้าอย่างน้อยปีละ ๑ ครั้ง โดยบุคคลที่ขึ้นทะเบียนตาม ม.๙ หรือนิติบุคคล ม.๑๑ และจัดทำบันทึกตาม **แบบ ๕๖๒๘๙**
   - **ข้อ ๑๓**: จัดให้มี Single Line Diagram เป็นปัจจุบัน
   - **ข้อ ๑๖**: ค่าความต้านทานดิน (Grounding Resistance) ต้องไม่เกิน ๕ โอห์ม
   - **ข้อ ๒๔**: อบรมความปลอดภัยในการทำงานเกี่ยวกับไฟฟ้าและการปฐมพยาบาล CPR/AED ก่อนปฏิบัติงาน

---

## Dependencies

- **Python**: `>=3.10`
- **Libraries**: Pure Python Standard Library (Standalone, Zero External Dependencies)
- **Data**: Offline-first JSON datasets in `scripts/data/`

---

## Quick Start & CLI Subcommands

สามารถเรียกใช้งานผ่าน `python scripts/thai_erp_cli.py <subcommand>`:

### 1. คำนวณโควตาอบรมดับเพลิงขั้นต้น ๔๐% (ข้อ ๒๗)
```bash
python scripts/thai_erp_cli.py calc-training-quota --total-employees 120 --currently-trained 45
```
**ตัวอย่างผลลัพธ์ (JSON):**
```json
{
  "total_employees": 120,
  "statutory_percent": 40.0,
  "required_quota": 48,
  "currently_trained": 45,
  "shortfall": 3,
  "current_percent": 37.5,
  "is_compliant": false,
  "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๒๗ (ไม่น้อยกว่าร้อยละ ๔๐)",
  "message": "ต่ำกว่าเกณฑ์: ขาดอีก 3 คน เพื่อให้ครบ 40.0% (48 คน)"
}
```

### 2. คำนวณจำนวนเครื่องดับเพลิงและระยะติดตั้ง (ข้อ ๑๑)
```bash
python scripts/thai_erp_cli.py calc-extinguishers --area-sqm 1500 --hazard-level MEDIUM
```
**ตัวอย่างผลลัพธ์ (JSON):**
```json
{
  "area_sqm": 1500.0,
  "hazard_level": "MEDIUM",
  "recommended_units": 15,
  "max_travel_distance_meters": 20.0,
  "max_installation_height_meters": 1.50,
  "min_fire_rating": "2-A / 10-B",
  "rule_summary": "ติดตั้ง ๑ เครื่อง ต่อพื้นที่ไม่เกิน 100.0 ตร.ม. ระยะเดินเข้าถึงไม่เกิน 20.0 ม. และส่วนบนสุดสูงจากพื้นไม่เกิน ๑.๕๐ ม."
}
```

### 3. ตรวจสอบความถูกต้องของการฝึกซ้อมและกำหนดส่งแบบ สปร. ๔ (ข้อ ๓๐)
```bash
python scripts/thai_erp_cli.py audit-drill --drill-json path/to/drill.json
```

### 4. ตรวจสอบความครบถ้วนของเล่มแผนฉุกเฉิน ๖ เสาหลัก (ข้อ ๔)
```bash
python scripts/thai_erp_cli.py validate-plan --input-json path/to/plan.json --hazard-type FIRE
```

### 5. ค้นหากฎหมายและประกาศกระทรวงแรงงาน
```bash
python scripts/thai_erp_cli.py get-emergency-law --query "สปร. ๔"
```

### 6. แสดงรายการพรีเซ็ตมาตรฐานสำหรับแผนฉุกเฉิน
```bash
python scripts/thai_erp_cli.py list-presets --hazard-type ALL
```

### 7. ตรวจสอบความสอดคล้องของการตรวจรับรองระบบไฟฟ้าประจำปี (ข้อ ๑๒ / แบบ ๕๖๒๘๙)
```bash
python scripts/thai_erp_cli.py audit-electrical --inspection-json path/to/electrical_inspection.json
```
**ตัวอย่างผลลัพธ์ (JSON):**
```json
{
  "inspection_date": "2025-05-10",
  "expiry_date": "2026-05-10",
  "days_remaining": 243,
  "is_overdue": false,
  "sla_status": "COMPLIANT",
  "inspector_name": "นายวิศวะ ไฟฟ้าสยาม",
  "inspector_license_no": "ภฟก. 998877",
  "grounding_resistance_ohm": 3.2,
  "is_grounding_pass": true,
  "has_vendor_report_attachment": true,
  "has_thermoscan_attachment": true,
  "is_fully_compliant": true,
  "statutory_reference": "กฎกระทรวงกำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๑๒ (ตรวจรับรองปีละ ๑ ครั้ง ตามแบบ ๕๖๒๘๙)",
  "message": "ผ่านเกณฑ์ตามกฎหมายครบถ้วน"
}
```

---

## Common Mistakes & ข้อควรระวัง

1. **นับโควตาอบรม ๔๐% รวมทั้งโรงงานแทนที่จะนับแยกแผนก**: กฎหมายข้อ ๒๗ ระบุชัดเจนว่า *"ไม่น้อยกว่าร้อยละสี่สิบของจำนวนลูกจ้างในแต่ละแผนก"*
2. **ละเลยการขอความเห็นชอบกรณีซ้อมเอง**: กรณีนายจ้างไม่ได้จ้างหน่วยงานที่ขึ้นทะเบียนตามมาตรา ๑๑ ต้องยื่นขอความเห็นชอบต่ออธิบดี/พนักงานตรวจความปลอดภัยล่วงหน้าไม่น้อยกว่า ๓๐ วัน
3. **ส่งรายงาน สปร. ๔ เกิน ๓๐ วัน**: กฎหมายกำหนดให้ส่งรายงานภายใน ๓๐ วันนับแต่วันที่เสร็จสิ้นการฝึกซ้อม มิฉะนั้นถือว่ามีความผิดตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔
4. **จ้าง ผรม. ตรวจระบบไฟฟ้าแต่ไม่มีเล่มรายงานหรือไม่ได้แนบ แบบ ๕๖๒๘๙**: กฎกระทรวงไฟฟ้า ๒๕๕๘ ข้อ ๑๒ กำหนดให้ต้องมีบันทึกผลการตรวจสอบรับรองตามแบบที่อธิบดีกำหนด (แบบ ๕๖๒๘๙) และรายงาน Thermo-scan เก็บไว้พร้อมรับการตรวจ
