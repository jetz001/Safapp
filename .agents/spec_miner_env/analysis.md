# Environmental Safety Law & Standards Technical Specification Mining Report
**Authority**: Royal Thai Government Gazette (ราชกิจจานุเบกษา) & Department of Labour Protection and Welfare (DLPW / กรมสวัสดิการและคุ้มครองแรงงาน)  
**Target Module**: SAFAPP Environmental Monitoring & `thai-environmental-safety-law` Agent Skill  
**Author**: Environmental Safety Law & Standards Spec Miner  
**Timestamp**: 2026-09-01T13:30:00Z  

---

## 1. Executive Summary & Legal Framework Hierarchy

The environmental safety monitoring regime in Thailand is governed by a strict hierarchy of legislation under the **Occupational Safety, Health and Environment Act B.E. 2554 (2011)** and secondary legislation issued by the Ministry of Labour and the Department of Labour Protection and Welfare (DLPW).

```
┌────────────────────────────────────────────────────────────────────────────┐
│         Occupational Safety, Health and Environment Act B.E. 2554           │
│   (Sections 8 [Standard Mandate], 9 [Individual Reg.], 11 [Juristic Org.], │
│       15 [Posting & Submitting], 32 [Safety Order], 53, 55, 56 [Penalties]) │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                      │
                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│      Ministerial Regulation on Heat, Light, and Noise B.E. 2559 (2016)      │
│   (Heat: Cl. 2-3, Light: Cl. 4-6, Noise: Cl. 7-11, PPE: Cl. 12-13,          │
│       Annual Measurement: Cl. 14, Reporting: Cl. 15)                       │
└──────────────┬──────────────────────┬──────────────────────┬───────────────┘
               │                      │                      │
               ▼                      ▼                      ▼
┌────────────────────────┐ ┌────────────────────────┐ ┌───────────────────────┐
│   DLPW Lighting Std    │ │     DLPW Noise Std     │ │   DLPW Heat & WBGT    │
│     B.E. 2561 (2018)   │ │    B.E. 2561 (2018)    │ │   B.E. 2563 (2020)    │
│ - General Areas (20-100│ │ - 8-hr TWA <= 86 dBA   │ │ - WBGT formulas       │
│ - Specific Tasks (100- │ │ - Action Level = 85 dBA│ │ - Metabolic rate work │
│   1200 Lux)            │ │ - Peak <= 140 dB       │ │   classes (34/32/30°C)│
│ - Surrounding Area (1/3│ │ - Cont. <= 115 dBA     │ │ - Indoor vs Outdoor   │
│   and 1/5 ratio)       │ │ - 3 dB Exchange Rate   │ │   solar radiation     │
└────────────────────────┘ └────────────────────────┘ └───────────────────────┘
```

---

## 2. Statutory Legal Requirements Matrix

### 2.1 Thai Labor Safety Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)

| Section (มาตรา) | Title & Legal Scope | Statutory Requirement & Enforceable Obligation | Penalties / Legal Impact |
|---|---|---|---|
| **Section 8** (ม.๘) | Employer's Duty of Safety Standard Compliance | นายจ้างต้องบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน ให้เป็นไปตามมาตรฐานที่กำหนดในกฎกระทรวง | Section 53: จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ |
| **Section 9** (ม.๙) | Individual Registered Service Provider (บุคคลธรรมดาผู้ขึ้นทะเบียน) | การให้บริการตรวจวัด ทดสอบ รับรอง ประเมินความเสี่ยง ฝึกอบรม หรือให้คำปรึกษา ต้องดำเนินการโดยผู้ขึ้นทะเบียนตามมาตรา ๙ (มีเลขทะเบียนขึ้นต้นด้วย **นบ.** เช่น นบ. ๑๒๓-๔๕/๒๕๖x) | Section 56: จำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (ทั้งผู้จ้างและผู้รับจ้าง) |
| **Section 11** (ม.๑๑) | Authorized Juristic Service Provider (นิติบุคคลผู้ได้รับใบอนุญาต) | นิติบุคคลที่ประสงค์จะให้บริการตรวจวัด ทดสอบ รับรอง หรือประเมินด้านสภาพแวดล้อม ต้องได้รับใบอนุญาตจากอธิบดีกรมสวัสดิการฯ (มีเลขที่ใบอนุญาตขึ้นต้นด้วย **บ.** เช่น บ. ๑๒๓-๔๕/๒๕๖x) | Section 56: จำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ |
| **Section 15** (ม.๑๕) | Result Posting & Agency Submission Deadlines | นายจ้างต้องปิดประกาศผลการตรวจวัด หรือผลการตรวจสอบ ณ สถานประกอบกิจการในที่เปิดเผยให้ลูกจ้างทราบ **ภายใน ๑๕ วัน** นับแต่วันที่ได้รับรายงาน และส่งสำเนารายงานให้อธิบดี/พนักงานตรวจความปลอดภัย **ภายใน ๓๐ วัน** นับแต่วันตรวจวัด | Section 55: ปรับไม่เกิน ๕๐,๐๐๐ บาท |
| **Section 32** (ม.๓๒) | Corrective Safety Plan & Remedial Action | พนักงานตรวจความปลอดภัยมีอำนาจสั่งให้นายจ้างจัดทำแผนการปรับปรุงสภาพแวดล้อมในการทำงาน (CAPA) และรายงานความคืบหน้าตามกรอบเวลาที่กำหนด | Section 53 / 71: ปรับรายวันจนกว่าจะปฏิบัติถูกต้อง |

---

### 2.2 Ministerial Regulation on Heat, Light, and Noise B.E. 2559 (กฎกระทรวงความร้อน แสงสว่าง และเสียง ๒๕๕๙)

| Clause (ข้อ) | Factor | Statutory Standard / Requirement | Implementation Details |
|---|---|---|---|
| **ข้อ ๒-๓** | **ความร้อน (Heat)** | ควบคุมระดับความร้อนในสถานประกอบกิจการมิให้เกินมาตรฐาน WBGT ตามลักษณะงาน (เบา <= 34°C, ปานกลาง <= 32°C, หนัก <= 30°C) | หากเกิน ต้องปรับปรุงวิศวกรรม/บริหารจัดการ และจัดหาชุด PPE ทนความร้อน |
| **ข้อ ๔-๖** | **แสงสว่าง (Light)** | ควบคุมความเข้มของแสงสว่างในสถานประกอบกิจการไม่ให้ต่ำกว่ามาตรฐานที่อธิบดีประกาศกำหนด | วัด ณ จุดทำงานจริง (Task Area) และบริเวณรอบข้าง ป้องกันแสงจ้าและเงาสะท้อน |
| **ข้อ ๗-๘** | **เสียง (Noise)** | ควบคุมระดับเสียงเฉลี่ยตลอดการทำงาน 8 ชั่วโมง ไม่เกิน 86 dBA, เสียงต่อเนื่องสูงสุดไม่เกิน 115 dBA, เสียงกระทบ/กระแทกไม่เกิน 140 dB | หากระดับเสียงเปลี่ยนแปลง ให้คำนวณ Leq / TWA 8-hr เทียบเท่า |
| **ข้อ ๑๐** | **ป้ายเตือน PPE** | ในบริเวณที่มีระดับเสียงเกินมาตรฐาน ต้องติดป้ายเตือนให้สวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลอย่างชัดเจน | ป้ายสัญลักษณ์สีน้ำเงิน (Mandatory Sign) บังคับสวมที่อุดหูหรือครอบหู |
| **ข้อ ๑๑** | **โครงการอนุรักษ์การได้ยิน (HCP)** | สถานประกอบกิจการที่มีระดับเสียงเฉลี่ย 8 ชม. **ตั้งแต่ 85 dBA ขึ้นไป (Action Level)** ต้องจัดทำโครงการอนุรักษ์การได้ยินเป็นลายลักษณ์อักษร | รวม 6 องค์ประกอบหลัก: นโยบาย, แผนที่เสียง, ตรวจการได้ยิน, PPE, อบรม, ประเมินผล |
| **ข้อ ๑๒-๑๓** | **อุปกรณ์ PPE** | นายจ้างต้องจัดหาอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (Earplugs/Earmuffs, แว่นตา/กระบังหน้า, เสื้อผ้าทนความร้อน) โดยไม่คิดมูลค่า | ได้รับมาตรฐาน มอก. หรือมาตรฐานสากล (ANSI, EN, CE, ISO) |
| **ข้อ ๑๔** | **รอบการตรวจวัดประจำปี** | นายจ้างต้องจัดให้มีการตรวจวัดและประเมินสภาวะการทำงาน **อย่างน้อยปีละ ๑ ครั้ง** | ดำเนินการโดย จป.วิชาชีพ ของสถานประกอบการ หรือผู้ขึ้นทะเบียน ม.๙ / ผู้รับใบอนุญาต ม.๑๑ |
| **ข้อ ๑๕** | **การจัดทำและส่งรายงาน** | นายจ้างต้องจัดทำรายงานผลการตรวจวัดตามแบบที่อธิบดีกำหนด และส่งรายงานต่อกรมฯ **ภายใน ๓๐ วัน** นับแต่วันตรวจวัด และเก็บรักษาไว้ **ไม่น้อยกว่า ๕ ปี** | แบบรายงาน สสค. ครบทั้ง 3 ปัจจัย พร้อมเอกสารรับรองเครื่องมือวัด (Calibration Certificate) |

---

## 3. DLPW Lighting Standards Specification (ประกาศกรมฯ เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑)

Published in Government Gazette Vol. 135, Special Part 43 Ngor, dated 27 February 2018.

### 3.1 Category 1: บริเวณพื้นที่ทั่วไปและทางสัญจร (General Areas & Circulation Paths)

| Code | Subcategory / Area Description (ภาษาไทย) | English Description | Standard Minimum (Lux) | Evaluation Rule |
|---|---|---|---|---|
| `LIGHT-CAT1-01` | ทางเดินภายนอกอาคาร, ลานจอดรถ, บริเวณถ่ายเทสินค้าภายนอก | Outdoor walkways, parking lots, outdoor loading bays | **20** | Measured >= 20 Lux |
| `LIGHT-CAT1-02` | ทางเดินภายในอาคาร, ทางหนีไฟ, บันได, ลิฟต์ | Indoor corridors, fire escape routes, stairs, elevators | **50** | Measured >= 50 Lux |
| `LIGHT-CAT1-03` | ทางสัญจรในพื้นที่ปฏิบัติงาน, ทางเดินในโรงงาน | Walkways in production/operational areas | **100** | Measured >= 100 Lux |
| `LIGHT-CAT1-04` | ห้องน้ำ, ห้องสุขา, ห้องแต่งตัว, ห้องรับประทานอาหาร, ห้องพักผ่อน | Restrooms, toilets, locker rooms, canteens, rest areas | **100** | Measured >= 100 Lux |
| `LIGHT-CAT1-05` | คลังสินค้าทั่วไป, พื้นที่จัดเก็บสินค้าขนาดใหญ่, โกดังสินค้าแบบเทกอง | Bulk storage, general warehousing, inactive storage | **100** | Measured >= 100 Lux |
| `LIGHT-CAT1-06` | คลังสินค้าที่มีการอ่านฉลากหรือเบิกจ่ายสินค้า, ช่องทางเดินระหว่างชั้นวาง | Active warehouse racking aisles, picking and reading areas | **200** | Measured >= 200 Lux |

---

### 3.2 Category 2: บริเวณที่ลูกจ้างทำงานโดยใช้สายตามองเฉพาะจุด (Specific Visual Task Workstations)

| Code | Task Type & Complexity (ลักษณะงานและความละเอียด) | Typical Industrial Examples | Standard Minimum (Lux) | Recommended Working Range (Lux) |
|---|---|---|---|---|
| `LIGHT-CAT2-01` | **งานที่ใช้สายตาน้อยมาก / งานหยาบมาก** (Very Rough Tasks) | งานคัดแยกวัตถุขนาดใหญ่, งานผสมคอนกรีต, งานโหลดวัสดุหยาบ, งานตีเหล็กเบื้องต้น | **100** | 100 – 150 |
| `LIGHT-CAT2-02` | **งานที่ใช้สายตาหยาบ** (Rough Tasks) | งานปั๊มชิ้นงานขนาดใหญ่, งานเลื่อยไม้, งานโรงรีดเหล็ก, งานล้างภาชนะอุตสาหกรรม | **200** | 200 – 250 |
| `LIGHT-CAT2-03` | **งานที่ใช้สายตาปานกลาง** (Medium / General Tasks) | งานกลึง ไส กัด เจาะ, งานประกอบชิ้นส่วนยานยนต์, งานบรรจุภัณฑ์, งานทอผ้า, งานเชื่อมโลหะ | **300** | 300 – 400 |
| `LIGHT-CAT2-04` | **งานสำนักงานและธุรการทั่วไป** (General Office & Administration) | งานพิมพ์เอกสาร, บันทึกข้อมูลคอมพิวเตอร์, ห้องประชุม, โต๊ะทำงานทั่วไป, ห้องเรียน | **300** | 400 – 500 |
| `LIGHT-CAT2-05` | **งานที่ใช้สายตาละเอียด** (Fine / Detailed Tasks) | งานเย็บผ้า, งานประกอบชิ้นส่วนอิเล็กทรอนิกส์, งานพิมพ์ละเอียด, งานเขียนแบบ (Drafting), งานกลึงละเอียด | **400** | 400 – 600 |
| `LIGHT-CAT2-06` | **งานที่ใช้สายตาละเอียดสูง / ตรวจสอบคุณภาพ** (Very Fine / QC Inspection) | งานตรวจข้อบกพร่องของสี, งานตรวจสอบชิ้นงานแม่นยำ (QC/QA), งานห้องปฏิบัติการวิเคราะห์ | **600** | 600 – 800 |
| `LIGHT-CAT2-07` | **งานที่ใช้สายตาละเอียดเป็นพิเศษ** (Minute / Extra Fine Tasks) | งานทำอัญมณี/เพชรพลอย, งานประกอบนาฬิกา, งานผ่าตัด/ทันตกรรม, งานผลิตไมโครชิป | **1,000** | 1,000 – 1,500 |

---

### 3.3 Category 3: บริเวณรอบๆ จุดทำงาน (Surrounding & Background Areas)

1. **รัศมี ๐.๕ เมตรโดยรอบจุดทำงาน (Surrounding Area within 0.5 m)**:
   - ความเข้มแสงสว่างต้องไม่น้อยกว่า **๑ ใน ๓ ($\ge 1/3$)** ของความเข้มแสงสว่าง ณ จุดทำงาน
   - หากจุดทำงานต้องการ $\ge 300 \text{ Lux}$ บริเวณรอบข้างต้องไม่น้อยกว่า **$200 \text{ Lux}$**
2. **บริเวณถัดออกไป (Adjacent / Background Area)**:
   - ความเข้มแสงสว่างต้องไม่น้อยกว่า **๑ ใน ๕ ($\ge 1/5$)** ของจุดทำงาน หรือไม่ต่ำกว่า **$100 \text{ Lux}$**
3. **เกณฑ์การประเมินความสม่ำเสมอของแสง (Uniformity Ratio $U_0$)**:
   $$U_0 = \frac{E_{\min}}{E_{\text{avg}}} \ge 0.5 \quad \text{(สำหรับพื้นที่ทำงานทั่วไป)}, \quad \ge 0.7 \quad \text{(สำหรับงานละเอียด)}$$

---

## 4. DLPW Noise Standards Specification (ประกาศกรมฯ เรื่อง มาตรฐานระดับเสียง พ.ศ. ๒๕๖๑)

Published in Government Gazette Vol. 135, Special Part 27 Ngor, dated 6 February 2018.

### 4.1 Fundamental Threshold Limits

| Noise Parameter | Standard Legal Threshold | Legal & Technical Description | Action Required on Exceedance |
|---|---|---|---|
| **8-Hour TWA Limit** ($L_{\text{TWA,8h}}$) | **$\le 86.0 \text{ dBA}$** | ระดับเสียงเฉลี่ยตลอดระยะเวลาการทำงาน ๘ ชั่วโมงต่อวัน | ต้องมีมาตรการลดเสียงทางวิศวกรรม/บริหารจัดการ และสวมใส่ PPE |
| **Action Level** ($L_{\text{action}}$) | **$\ge 85.0 \text{ dBA}$** | ระดับเสียงเฉลี่ย 8 ชม. ที่ต้องเริ่มดำเนิน **"โครงการอนุรักษ์การได้ยิน" (Hearing Conservation Program)** | บังคับจัดทำเอกสารโครงการ HCP, ตรวจการได้ยินประจำปี, แจก PPE |
| **Continuous Ceiling Limit** ($L_{\text{max,cont}}$) | **$< 115.0 \text{ dBA}$** | ระดับเสียงดังต่อเนื่องสูงสุด ห้ามลูกจ้างได้รับเสียงเกินระดับนี้ในทุกกรณี ไม่ว่าเวลาใด | หยุดการปฏิบัติงานทันที หรือกั้นห้องแยกลูกจ้างออกจากแหล่งกำเนิดเสียง |
| **Impact / Peak Noise Limit** ($L_{\text{peak}}$) | **$\le 140.0 \text{ dB}$** | ระดับเสียงกระทบหรือเสียงกระแทก (Peak Sound Pressure Level, C-Weighted หรือ Linear Peak) | ห้ามมีระดับเสียงกระแทกเกิน 140 dB, ต้องปรับปรุงกระบวนการกลไก |

---

### 4.2 Mathematical Formulas for Noise Assessment

#### 1. Exchange Rate ($Q = 3 \text{ dB}$) Permissible Exposure Duration Formula:
$$T_i = \frac{8}{2^{\frac{L_i - 86}{3}}} = 8 \times 2^{\frac{86 - L_i}{3}} \quad [\text{hours}]$$
where $L_i$ is the measured A-weighted continuous sound level in dBA.

#### Exposure Duration Reference Table (DLPW B.E. 2561):
| Sound Level ($L_i$, dBA) | Permissible Duration ($T_i$) | Exact Calculation ($8 \times 2^{(86-L)/3}$) |
|---|---|---|
| 80 dBA | 32 hours | 32.0 hrs |
| 83 dBA | 16 hours | 16.0 hrs |
| **85 dBA (Action Level)** | **10.08 hours** (605 mins) | $8 \times 2^{1/3} \approx 10.079$ hrs |
| **86 dBA (Standard Limit)** | **8 hours** (480 mins) | 8.0 hrs |
| 89 dBA | 4 hours (240 mins) | 4.0 hrs |
| 92 dBA | 2 hours (120 mins) | 2.0 hrs |
| 95 dBA | 1 hour (60 mins) | 1.0 hr |
| 98 dBA | 30 minutes | 0.5 hr |
| 101 dBA | 15 minutes | 0.25 hr |
| 104 dBA | 7.5 minutes | 0.125 hr |
| 107 dBA | 3.75 minutes | 0.0625 hr |
| 110 dBA | 1.875 minutes | 0.03125 hr |
| 113 dBA | 56.25 seconds | 0.015625 hr |
| **115 dBA** | **28.125 seconds** | **Absolute Ceiling** |

#### 2. Cumulative Noise Dose ($D$):
$$D = \left( \sum_{i=1}^n \frac{C_i}{T_i} \right) \times 100\%$$
where:
- $C_i$ = Actual exposure duration at level $L_i$ (hours).
- $T_i$ = Permissible exposure duration at level $L_i$ (hours).
- **Compliance Status**:
  - $D \le 79.37\%$ ($\text{TWA} < 85 \text{ dBA}$): **COMPLIANT_NORMAL** (ผ่านเกณฑ์ปกติ)
  - $79.37\% \le D \le 100.0\%$ ($85 \text{ dBA} \le \text{TWA} \le 86 \text{ dBA}$): **ACTION_LEVEL_HCP** (เข้าเกณฑ์เฝ้าระวัง / บังคับโครงการอนุรักษ์การได้ยิน)
  - $D > 100.0\%$ ($\text{TWA} > 86 \text{ dBA}$): **NON_COMPLIANT_EXCEEDED** (เกินเกณฑ์มาตรฐานกฎหมาย)

#### 3. 8-Hour Time-Weighted Average ($\text{TWA}_{8\text{h}}$):
$$\text{TWA}_{8\text{h}} = 86 + \frac{3}{\log_{10}(2)} \times \log_{10}\left(\frac{D}{100}\right) = 86 + 9.965784 \times \log_{10}\left(\frac{D}{100}\right) \quad [\text{dBA}]$$

#### 4. Equivalent Continuous Sound Level ($L_{\text{eq}, T}$):
$$L_{\text{eq}, T} = 10 \times \log_{10} \left( \frac{1}{T} \sum_{i=1}^n t_i \times 10^{\frac{L_i}{10}} \right) \quad [\text{dBA}]$$

---

### 4.3 Hearing Conservation Program (HCP) Mandatory Elements (ข้อ ๑๑)

When any workplace area or occupational group exhibits $\text{TWA}_{8\text{h}} \ge 85.0 \text{ dBA}$ or Noise Dose $\ge 79.4\%$, the employer MUST establish a written Hearing Conservation Program consisting of:
1. **Written HCP Policy & Organization**: นโยบายและโครงสร้างผู้รับผิดชอบโครงการ
2. **Noise Monitoring & Noise Mapping**: แผนผังแสดงระดับเสียงในแต่ละโซน (Noise Contour Map) อัปเดตทุกปี
3. **Audiometric Testing (การตรวจสมรรถภาพการได้ยิน)**:
   - Baseline Audiogram ภายใน 30 วันแรกหลังเริ่มงานในพื้นที่เสี่ยง
   - Annual Audiogram ติดตามผลทุกปี เพื่อตรวจจับ Standard Threshold Shift (STS: การสูญเสียการได้ยินเฉลี่ย $\ge 10 \text{ dB}$ ที่ความถี่ 2000, 3000, 4000 Hz)
4. **Engineering & Administrative Noise Controls**: ติดตั้ง Acoustic Enclosures, Silencers, Rubber Dampers, หรือสลับผลัดหมุนเวียนงาน
5. **Hearing Protection Devices (HPD / PPE)**: แจกจ่าย Earplugs หรือ Earmuffs ที่มีค่า NRR (Noise Reduction Rating) หรือ SNR เพียงพอ โดยคำนวณ Protected Noise Level:
   $$L_{\text{protected}} = L_{\text{measured}} - \frac{\text{NRR} - 7}{2} \le 85 \text{ dBA}$$
6. **Training & Employee Motivation**: อบรมความรู้เรื่องอันตรายจากเสียงและการใส่ PPE อย่างถูกต้อง
7. **Annual Program Evaluation**: ประเมินประสิทธิผลของโครงการทุกปี

---

## 5. DLPW Heat & WBGT Specification (ประกาศกรมฯ เรื่อง หลักเกณฑ์และวิธีการตรวจวัดและคำนวณระดับความร้อน พ.ศ. ๒๕๖๓)

Published in Government Gazette Vol. 137, Special Part 238 Ngor, dated 9 October 2020.

### 5.1 Temperature Sensor Definitions

- **Natural Wet-Bulb Temperature ($NWB$ / อุณหภูมิกระเปาะเปียกธรรมชาติ)**: Sensor with a clean wetted cotton wick exposed to natural ambient air movement (without forced ventilation).
- **Globe Temperature ($GT$ / อุณหภูมิโกลบ)**: Temperature measured inside a matte black copper sphere with a standard diameter of $150 \text{ mm}$ (15 cm or 6 inches) to measure radiant heat.
- **Dry-Bulb Temperature ($DB$ / อุณหภูมิกระเปาะแห้ง)**: Ambient air temperature measured with sensor shielded from direct radiant heat sources.

---

### 5.2 Mathematical WBGT Calculation Formulas

#### Formula 1: In-doors or Out-doors without direct solar load (ในร่ม หรือไม่มีแสงแดด):
$$\text{WBGT}_{\text{indoor}} = 0.7 \times NWB + 0.3 \times GT$$

#### Formula 2: Out-doors with direct solar load (กลางแจ้ง หรือมีแสงแดดส่องถึง):
$$\text{WBGT}_{\text{outdoor}} = 0.7 \times NWB + 0.2 \times GT + 0.1 \times DB$$

---

### 5.3 Workload Classification & Threshold Standards (การจำแนกลักษณะงานตามอัตราการเผาผลาญพลังงาน)

| Workload Category (ลักษณะงาน) | Metabolic Rate Range ($M$) | Statutory Limit (Max Allowable WBGT) | Typical Job Examples (ตัวอย่างงานตามประกาศกรมฯ) |
|---|---|---|---|
| **งานเบา** (Light Work) | **$\le 200 \text{ kcal/hr}$** | **$\le 34.0^\circ\text{C WBGT}$** | งานนั่งเขียนหนังสือ, งานพิมพ์ดีด/คอมพิวเตอร์, งานนั่งประกอบชิ้นงานขนาดเล็ก, งานขับขี่รถยนต์/โฟล์คลิฟต์, งานยืนควบคุมปุ่มกดเครื่องจักรอัตโนมัติ |
| **งานปานกลาง** (Moderate Work) | **$200 < M \le 350 \text{ kcal/hr}$** | **$\le 32.0^\circ\text{C WBGT}$** | งานเดินตรวจงานสม่ำเสมอ, งานยกของหนักปานกลาง (5-15 kg), งานไสไม้ งานกลึง, งานก่ออิฐฉาบปูน, งานกวาดพื้น/ขัดพื้น, งานประกอบรถยนต์ |
| **งานหนัก** (Heavy Work) | **$M > 350 \text{ kcal/hr}$** | **$\le 30.0^\circ\text{C WBGT}$** | งานแบกหามของหนัก (> 15 kg), งานขุดดิน/ขุดเจาะถนน, งานใช้ค้อนปอนด์ตีเหล็ก, งานโกยถ่านหิน, งานตัดไม้ด้วยเลื่อยมือ, งานดับเพลิง, งานเทโลหะหลอมเหลว |

---

### 5.4 Time-Weighted WBGT & Metabolic Rate for Variable Tasks (การคำนวณเฉลี่ยถ่วงน้ำหนักตามเวลา)

When an employee performs duties across multiple heat zones or alternates between heavy work and rest in a cool area:

$$\text{WBGT}_{\text{TWA}} = \frac{\sum_{i=1}^k (\text{WBGT}_i \times t_i)}{\sum_{i=1}^k t_i} = \frac{\text{WBGT}_1 t_1 + \text{WBGT}_2 t_2 + \dots + \text{WBGT}_k t_k}{t_1 + t_2 + \dots + t_k}$$

$$\text{Metabolic Rate}_{\text{TWA}} = \frac{\sum_{i=1}^k (M_i \times t_i)}{\sum_{i=1}^k t_i} = \frac{M_1 t_1 + M_2 t_2 + \dots + M_k t_k}{t_1 + t_2 + \dots + t_k}$$

Where:
- $t_i$ = Duration of time spent in task/location $i$ (minutes or hours).
- Total cycle time must typically be evaluated over a continuous **60-minute window** during peak heat hours (10:00 - 15:00).

---

## 6. Subcontractor & Registration Architecture (Section 9 vs Section 11)

Under Section 9 and Section 11 of the OSH Act B.E. 2554, only certified persons or licensed legal entities are legally authorized to perform environmental safety measurement and issue compliance certifications:

### 6.1 Service Provider Classification Matrix

| Criteria | Section 9: Individual Registered Person (บุคคลธรรมดาผู้ขึ้นทะเบียน) | Section 11: Authorized Juristic Person (นิติบุคคลผู้ได้รับใบอนุญาต) |
|---|---|---|
| **Legal Entity Type** | Natural Person (บุคคลธรรมดา) | Registered Corporation / Company Limited (นิติบุคคล เช่น บจก., บมจ.) |
| **Registration Code Format** | **เลขทะเบียน นบ.** เช่น `นบ. 0123-45/2566` (NB-xxxx-yy/yyyy) | **เลขที่ใบอนุญาต บ.** เช่น `บ. 0045-12/2565` (B-xxxx-yy/yyyy) |
| **Qualifications** | - จป.วิชาชีพ หรือสำเร็จการศึกษาด้านอาชีวอนามัย / วิศวกรรม / วิทยาศาสตร์<br>- ผ่านการอบรมและขึ้นทะเบียนกับกรมสวัสดิการฯ | - ทุนจดทะเบียนและหลักทรัพย์ค้ำประกันตามเกณฑ์<br>- มีเจ้าหน้าที่ผู้ควบคุมที่มีคุณสมบัติตามกฎหมายประจำเต็มเวลา |
| **Certification Authority** | เซ็นรับรองรายงานในนามบุคคลผู้ขึ้นทะเบียน | เซ็นรับรองรายงานในนามนิติบุคคล โดยผู้มีอำนาจลงนามและผู้ควบคุม |
| **Calibration Requirements** | เครื่องมือวัดต้องมีใบรับรองการสอบเทียบ (Calibration Certificate) จากสถาบันที่ได้รับการรับรอง **ISO/IEC 17025** มีอายุไม่เกิน ๑ ปี | เครื่องมือวัดทุกชิ้นต้องมีใบรับรองการสอบเทียบ ISO/IEC 17025 มีอายุไม่เกิน ๑ ปี พร้อมแผนบำรุงรักษา |

---

## 7. Official DLPW Reporting Form Specifications & Workflow Deadlines

### 7.1 Statutory Form Sections (แบบรายงาน สสค.)

The official DLPW Environmental Measurement & Analysis Report consists of 6 mandatory sections:
1. **General Workplace Profile (ข้อมูลสถานประกอบกิจการ)**:
   - Workplace Name (ชื่อสถานประกอบการ), Tax ID (เลขทะเบียนนิติบุคคล 13 หลัก), TSIC Industry Code (รหัสประเภทกิจการ), Location/Address, Total Employees (Male/Female), Safety Committee (คปอ.) & Safety Officer (จป.วิชาชีพ) contact info.
2. **Measurement Service Provider Information (ข้อมูลผู้ตรวจวัดและรับรอง)**:
   - Name of Section 9 Individual or Section 11 Juristic Entity, Registration/License No. (`นบ.` or `บ.`), Date of Expiration.
3. **Apparatus & Calibration Log (เครื่องมือวัดและการสอบเทียบ)**:
   - Instrument Category (Sound Level Meter Type 1/2, Lux Meter Class A/B, WBGT Heat Stress Monitor), Brand, Model, Serial Number, Calibration Institute (ISO/IEC 17025 accredited), Calibration Certificate Number, Calibration Date and Valid Until Date.
4. **Point-by-Point Environmental Sampling Tables (ตารางผลการตรวจวัดรายจุด)**:
   - **Heat Table**: Sampling Point, Location, Indoor/Outdoor, NWB (°C), GT (°C), DB (°C), Calculated WBGT (°C), Metabolic Workload (kcal/hr), Statutory Limit (°C), Status (Pass/Fail).
   - **Light Table**: Sampling Point, Department/Workstation, Visual Task Category, Measured Lux, Statutory Minimum Lux, Surrounding Area Lux, Status (Pass/Fail).
   - **Noise Table**: Sampling Point/Machine, Department, Measurement Type (8-hr Leq, Area Noise, Peak), Measured Level (dBA / dB), Dose (%), Statutory Limit (86 dBA / 115 dBA / 140 dB), Action Level HCP Flag, Status (Normal/Action Level/Exceeded).
5. **Evaluation Summary & Corrective Action Plan (สรุปผลและแผน CAPA)**:
   - Overall Compliance Percentage, Summary of Exceeded Points, Root Causes, Hierarchy of Controls (Engineering, Administrative, PPE), PIC, Target Completion Date.
6. **Signatures & Legal Endorsements (ลายมือชื่อรับรองตามกฎหมาย)**:
   - Signature of Measurer & Certified Assessor (Section 9/11 with stamp/reg no.).
   - Signature of Employer / Authorized Director (นายจ้าง / กรรมการผู้จัดการ) acknowledging results.

---

### 7.2 Strict Statutory Deadlines Timeline

```
Day 0: Measurement Conducted on Site
  │
  ├─── Within 15 Days (Day 0 to Day 15) ─────────────────────────────┐
  │    Mandatory Posting at Workplace (พ.ร.บ. ม.๑๕)                   │
  │    - Post results in prominent locations accessible to all       │
  │    - Penalty for failure: Fine up to 50,000 THB (ม.๕๕)           │
  │                                                                  │
  ├─── Within 30 Days (Day 0 to Day 30) ─────────────────────────────┤
  │    Mandatory Official Submission to DLPW (ม.๑๕ & กฎกระทรวง ข้อ ๑๕)│
  │    - Submit full certified report to Provincial/Area Labour      │
  │      Protection and Welfare Office (สสค.จังหวัด/พื้นที่)          │
  │    - Penalty for failure: Fine up to 50,000 THB (ม.๕๕)           │
  │                                                                  │
  └─── 5-Year Document Retention Period (กฎกระทรวง ข้อ ๑๕) ──────────┘
       - Employer must maintain physical/digital copy on site for >= 5 years.
```

---

## 8. Comprehensive Data Schemas (JSON Specification)

### 8.1 Environmental Monitoring Session Model Schema (`EnvironmentSessionModel`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EnvironmentSessionModel",
  "type": "object",
  "required": [
    "session_id",
    "year_be",
    "measurement_date",
    "workplace_name",
    "subcontractor_type",
    "subcontractor_id",
    "assessor_name",
    "registration_no",
    "status"
  ],
  "properties": {
    "session_id": { "type": "string", "example": "ENV-SESS-2026-001" },
    "year_be": { "type": "integer", "example": 2569 },
    "measurement_date": { "type": "string", "format": "date", "example": "2026-09-01" },
    "report_received_date": { "type": "string", "format": "date", "example": "2026-09-05" },
    "posting_deadline": { "type": "string", "format": "date", "example": "2026-09-16" },
    "submission_deadline": { "type": "string", "format": "date", "example": "2026-10-01" },
    "workplace_name": { "type": "string", "example": "สยาม แอดวานซ์ แมนูแฟคเจอริ่ง จำกัด" },
    "workplace_address": { "type": "string", "example": "นิคมอุตสาหกรรมบางปู จ.สมุทรปราการ" },
    "subcontractor_type": { "type": "string", "enum": ["SECTION_9_INDIVIDUAL", "SECTION_11_JURISTIC", "INTERNAL_JPO"] },
    "subcontractor_id": { "type": "string", "example": "SUBCON-ENV-001" },
    "subcontractor_company_name": { "type": "string", "example": "บริษัท ไทยเซฟตี้ เอ็นไวรอนเมนทอล คอนซัลแตนท์ จำกัด" },
    "assessor_name": { "type": "string", "example": "นายสมชาย ปลอดภัยดี" },
    "registration_no": { "type": "string", "example": "บ. 0089-01/2565" },
    "status": { "type": "string", "enum": ["PLANNED", "MEASURED", "REPORT_POSTED", "SUBMITTED_TO_DLPW", "CLOSED"] },
    "attachment_summary": {
      "type": "object",
      "properties": {
        "pdf_report_path": { "type": "string" },
        "calibration_cert_paths": { "type": "array", "items": { "type": "string" } },
        "subcontractor_license_path": { "type": "string" },
        "site_photo_paths": { "type": "array", "items": { "type": "string" } }
      }
    },
    "kpi_summary": {
      "type": "object",
      "properties": {
        "total_points": { "type": "integer", "example": 25 },
        "light_points": { "type": "integer", "example": 12 },
        "noise_points": { "type": "integer", "example": 8 },
        "heat_points": { "type": "integer", "example": 5 },
        "passed_points": { "type": "integer", "example": 21 },
        "action_level_points": { "type": "integer", "example": 2 },
        "failed_points": { "type": "integer", "example": 2 },
        "compliance_percentage": { "type": "number", "example": 84.0 }
      }
    }
  }
}
```

---

### 8.2 Environmental Sampling Point Model Schema (`EnvironmentPointModel`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EnvironmentPointModel",
  "type": "object",
  "required": [
    "point_id",
    "session_id",
    "factor_type",
    "department",
    "location_name",
    "evaluation_status"
  ],
  "properties": {
    "point_id": { "type": "string", "example": "PT-ENV-LIGHT-001" },
    "session_id": { "type": "string", "example": "ENV-SESS-2026-001" },
    "factor_type": { "type": "string", "enum": ["LIGHT", "NOISE", "HEAT_WBGT"] },
    "department": { "type": "string", "example": "แผนกประกอบแผงวงจร (SMT Line)" },
    "location_name": { "type": "string", "example": "โต๊ะตรวจงาน QC Line 1" },
    
    "light_data": {
      "type": "object",
      "properties": {
        "category_code": { "type": "string", "example": "LIGHT-CAT2-06" },
        "task_description": { "type": "string", "example": "งานตรวจสอบคุณภาพ (QC Inspection)" },
        "measured_lux": { "type": "number", "example": 650.0 },
        "standard_min_lux": { "type": "number", "example": 600.0 },
        "surrounding_lux": { "type": "number", "example": 280.0 },
        "is_compliant": { "type": "boolean", "example": true }
      }
    },

    "noise_data": {
      "type": "object",
      "properties": {
        "measurement_type": { "type": "string", "enum": ["LEQ_8HR_TWA", "AREA_NOISE", "PEAK_SOUND_LEVEL"] },
        "measured_dba": { "type": "number", "example": 85.6 },
        "peak_db": { "type": "number", "example": 128.0 },
        "exposure_duration_hours": { "type": "number", "example": 8.0 },
        "noise_dose_percent": { "type": "number", "example": 91.2 },
        "standard_twa_limit": { "type": "number", "default": 86.0 },
        "action_level_threshold": { "type": "number", "default": 85.0 },
        "continuous_ceiling_limit": { "type": "number", "default": 115.0 },
        "peak_limit": { "type": "number", "default": 140.0 },
        "is_hcp_required": { "type": "boolean", "example": true },
        "evaluation_tier": { "type": "string", "enum": ["NORMAL", "ACTION_LEVEL_HCP", "EXCEEDED_STANDARD"] }
      }
    },

    "heat_data": {
      "type": "object",
      "properties": {
        "solar_exposure": { "type": "string", "enum": ["INDOOR_NO_SOLAR", "OUTDOOR_WITH_SOLAR"] },
        "nwb_celsius": { "type": "number", "example": 28.5 },
        "gt_celsius": { "type": "number", "example": 38.0 },
        "db_celsius": { "type": "number", "example": 34.0 },
        "calculated_wbgt": { "type": "number", "example": 31.35 },
        "workload_type": { "type": "string", "enum": ["LIGHT", "MODERATE", "HEAVY"] },
        "metabolic_rate_kcal_hr": { "type": "number", "example": 250.0 },
        "standard_limit_wbgt": { "type": "number", "example": 32.0 },
        "is_compliant": { "type": "boolean", "example": true }
      }
    },

    "evaluation_status": { "type": "string", "enum": ["PASS", "ACTION_LEVEL", "FAIL"] },
    "capa_id": { "type": "string", "nullable": true, "example": "CAPA-ENV-2026-004" }
  }
}
```

---

## 9. Discovered Features & Verification Table

### Features Discovered Matrix

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|---|---|---|---|---|---|---|
| 1 | **Heat WBGT** | `calculate_wbgt_indoor` | คำนวณ WBGT ในร่ม/ไม่มีแดด: $0.7 NWB + 0.3 GT$ | $NWB, GT \in [0, 60]^\circ\text{C}$ | WBGT (°C, 2 decimals) | Raise `ValueError` on negative or unrealistic range | DLPW Notification 2563 |
| 2 | **Heat WBGT** | `calculate_wbgt_outdoor` | คำนวณ WBGT กลางแจ้ง/มีแดด: $0.7 NWB + 0.2 GT + 0.1 DB$ | $NWB, GT, DB \in [0, 60]^\circ\text{C}$ | WBGT (°C, 2 decimals) | Raise `ValueError` if any sensor temperature missing | DLPW Notification 2563 |
| 3 | **Heat WBGT** | `evaluate_heat_compliance` | ประเมินผลความร้อนเทียบกับภาระงาน (เบา $\le 34$, ปานกลาง $\le 32$, หนัก $\le 30$) | Calculated WBGT, Workload enum or kcal/hr | Compliance Result (PASS / FAIL, Margin °C) | Raise `KeyError` if workload category invalid | Ministerial Reg. 2559 Cl. 2 |
| 4 | **Heat WBGT** | `calculate_twa_wbgt` | คำนวณ WBGT ถ่วงน้ำหนักเวลาหลายจุดงาน | List of $(\text{WBGT}_i, t_i, M_i)$ | $\text{WBGT}_{\text{avg}}, M_{\text{avg}}$, Pass/Fail | Error if total time $\le 0$ | DLPW Notification 2563 |
| 5 | **Lighting** | `search_lighting_standard` | ค้นหาเกณฑ์ความเข้มแสง Lux ตามหมวดหมู่งานหรือคีย์เวิร์ด | Keyword / Category code | List of matched lighting standards with min Lux | Return empty list if no match found | DLPW Notification 2561 |
| 6 | **Lighting** | `evaluate_light_compliance` | ประเมินความเข้มแสงจุดทำงานจริงและบริเวณรอบข้าง ($\ge 1/3, \ge 1/5$) | Measured Lux, Standard Min Lux, Surrounding Lux | Compliance Result (PASS / FAIL, Deficit Lux) | Warning flag if surrounding ratio $< 1/3$ | DLPW Notification 2561 |
| 7 | **Noise** | `calculate_permissible_noise_duration` | คำนวณเวลาที่ยอมให้สัมผัสเสียง: $T = 8 / 2^{(L-86)/3}$ | Continuous Noise Level $L$ (dBA) | Permissible Duration (hours/minutes) | Cap at 115 dBA (max 28.1s); Error if $> 115$ dBA | DLPW Notification 2561 |
| 8 | **Noise** | `calculate_noise_dose_and_twa` | คำนวณ Noise Dose (%) และ 8-hr TWA (dBA) | List of $(L_i, C_i)$ | Dose (%), $\text{TWA}_{8\text{h}}$ (dBA), Status tier | Error if $C_i < 0$ or $L_i < 0$ | DLPW Notification 2561 |
| 9 | **Noise** | `evaluate_noise_compliance` | ประเมินเสียง 8-hr TWA (86 dBA), Action Level (85 dBA), Ceiling (115 dBA), Peak (140 dB) | $\text{TWA}_{8\text{h}}$, Max Cont dBA, Peak dB | Tier (`NORMAL`, `ACTION_LEVEL_HCP`, `EXCEEDED`), HCP Flag | Immediate violation if Peak $> 140$ or Cont $\ge 115$ | Ministerial Reg. 2559 Cl. 7, 8, 11 |
| 10 | **Subcontractor** | `validate_subcontractor_credentials` | ตรวจสอบรูปแบบและวันหมดอายุของเลขทะเบียน ม.๙ (`นบ.`) และ ม.๑๑ (`บ.`) | Reg Code, Provider Type, Expire Date | Validation Status (`VALID`, `EXPIRED`, `INVALID_FORMAT`) | Return format error if prefix mismatch | OSH Act 2554 Sec 9 & 11 |
| 11 | **Compliance** | `calculate_deadline_schedule` | คำนวณวันกำหนดปิดประกาศ (15 วัน) และวันส่งกรมฯ (30 วัน) | Measurement Date | `posting_deadline`, `submission_deadline` | Error if invalid date string | OSH Act 2554 Sec 15 |
| 12 | **Reporting** | `generate_official_dlpw_export_data` | รวมรวมข้อมูลตามโครงสร้างแบบรายงาน สสค. ครบทั้ง 6 ส่วน | Session ID, Points, Subcon, Signatures | Structured Export Object (for PDF/Excel) | Error if required signature or point data missing | DLPW Reporting Notification |

---

## 10. Edge Cases & Boundary Conditions

| # | Feature | Input Scenario | Expected / Observed Behavior | Technical Rationale |
|---|---|---|---|---|
| E1 | `evaluate_noise_compliance` | Continuous noise measured at exactly $85.0 \text{ dBA}$ for 8 hours | Result: `ACTION_LEVEL_HCP` (Pass standard limit 86 dBA, but triggers Mandatory Hearing Conservation Program) | Section 11 of Ministerial Reg 2559 explicitly mandates HCP at $\ge 85 \text{ dBA}$. |
| E2 | `evaluate_noise_compliance` | Short impulse noise measured at $140.1 \text{ dB}$ Peak | Result: `NON_COMPLIANT_EXCEEDED` (Critical Violation) even if 8-hr TWA is only 75 dBA | Peak noise limit of 140 dB is an absolute ceiling that cannot be averaged out. |
| E3 | `evaluate_noise_compliance` | Continuous noise of $116 \text{ dBA}$ for 10 seconds | Result: `NON_COMPLIANT_EXCEEDED` (Immediate Ceiling Violation) | Continuous noise $\ge 115 \text{ dBA}$ is prohibited under any exposure duration. |
| E4 | `calculate_wbgt_indoor` | $NWB = 29.0^\circ\text{C}, GT = 45.0^\circ\text{C}$ in Moderate work | Calculated $\text{WBGT} = 0.7(29.0) + 0.3(45.0) = 33.8^\circ\text{C}$. Result: `FAIL` (Exceeds $32.0^\circ\text{C}$ limit by $+1.8^\circ\text{C}$) | Formula $0.7 NWB + 0.3 GT$ applies strictly for indoor environments. |
| E5 | `evaluate_light_compliance` | Task Workstation = $450 \text{ Lux}$ (Passed standard 400 Lux), but Surrounding Area = $120 \text{ Lux}$ | Result: `WARNING_SURROUNDING_DEFICIT` (Task passed, but surrounding $< 1/3$ ratio of $150 \text{ Lux}$) | Category 3 requires surrounding area within 0.5m to be $\ge 1/3$ of task illumination. |
| E6 | `validate_subcontractor_credentials` | Subcontractor claims Section 11 Juristic Person, but provides code `นบ. 0123/2566` | Result: `INVALID_PREFIX_MISMATCH` (Error: `นบ.` is for Section 9 Individuals; Section 11 must be `บ.`) | Statutory numbering distinction under OSH Act 2554. |
| E7 | `calculate_deadline_schedule` | Measurement Date = `2026-09-01` | `posting_deadline` = `2026-09-16` (15 days), `submission_deadline` = `2026-10-01` (30 days) | Calendar day calculations strictly matching Section 15. |
