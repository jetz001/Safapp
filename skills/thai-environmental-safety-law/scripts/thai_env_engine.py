"""
Thai Environmental Safety Law Evaluation Engine (Pure Python Standard Library)
Conforming to Royal Thai Gazette Enactments:
  1. OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ - ม.๘, ม.๙, ม.๑๑, ม.๑๕, ม.๓๒, ม.๕๓, ม.๕๕, ม.๕๖)
  2. Ministerial Reg. Heat, Light, Noise B.E. 2559 (กฎกระทรวงฯ ๒๕๕๙)
  3. DLPW Notification Lighting Standards B.E. 2561 (ประกาศกรมฯ แสงสว่าง ๒๕๖๑)
  4. DLPW Notification Noise Exposure Standards B.E. 2561 (ประกาศกรมฯ เสียง ๒๕๖๑)
  5. DLPW Notification WBGT Calculation & Evaluation B.E. 2563 (ประกาศกรมฯ ความร้อน ๒๕๖๓)
  6. DLPW Notification Official Environmental Reporting Form (แบบรายงาน สสค. / อธ.๑)
"""

import os
import sys
import json
import math
import re
from datetime import datetime, date
from typing import Dict, Any, List, Optional, Union, Tuple


class ThaiEnvEngine:
    """Pure Python calculation & statutory evaluation engine for workplace environmental safety."""

    def __init__(self, data_dir: Optional[str] = None):
        self.data_dir = data_dir or os.path.join(os.path.dirname(__file__), "data")
        self.standards_file = os.path.join(self.data_dir, "standards.json")
        self.standards_data: Dict[str, Any] = {}
        self._load_standards()

    def _load_standards(self) -> None:
        """Load statutory standards and reference catalog from JSON or fallback default."""
        if os.path.exists(self.standards_file):
            try:
                with open(self.standards_file, "r", encoding="utf-8") as f:
                    self.standards_data = json.load(f)
                return
            except Exception as e:
                pass
        self.standards_data = self._get_fallback_standards()

    def _get_fallback_standards(self) -> Dict[str, Any]:
        """Provide minimal fallback standards when JSON file is absent."""
        return {
            "metadata": {"title": "Thai Environmental Safety Standards Fallback", "version": "1.0.0"},
            "lighting_standards": [
                {
                    "id": "LIGHT-GEN-001",
                    "category": "general_area",
                    "workplace_type_th": "ทางเดินภายนอกอาคาร ลานจอดรถ",
                    "workplace_type_en": "Outdoor walkways, parking lots",
                    "standard_lux_min": 20.0,
                    "recommended_lux_range": "20 - 50 Lux",
                    "category_name_th": "พื้นที่ทั่วไปและทางสัญจร",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                },
                {
                    "id": "LIGHT-GEN-002",
                    "category": "general_area",
                    "workplace_type_th": "ทางเดินภายในอาคาร ทางหนีไฟ บันได",
                    "workplace_type_en": "Indoor corridors, emergency routes",
                    "standard_lux_min": 50.0,
                    "recommended_lux_range": "50 - 100 Lux",
                    "category_name_th": "พื้นที่ทั่วไปและทางสัญจร",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                },
                {
                    "id": "LIGHT-OFF-001",
                    "category": "office_administration",
                    "workplace_type_th": "งานสำนักงานทั่วไป โต๊ะทำงาน การอ่าน การเขียน บันทึกข้อมูลคอมพิวเตอร์",
                    "workplace_type_en": "General office work, reading, writing, computer data entry",
                    "standard_lux_min": 300.0,
                    "recommended_lux_range": "400 - 500 Lux",
                    "category_name_th": "งานสำนักงานและธุรการ",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                },
                {
                    "id": "LIGHT-MFG-M01",
                    "category": "manufacturing_medium",
                    "workplace_type_th": "งานกลึง ไส กัด เจาะโลหะ งานเครื่องจักรกล",
                    "workplace_type_en": "General machining, lathe, milling",
                    "standard_lux_min": 300.0,
                    "recommended_lux_range": "300 - 400 Lux",
                    "category_name_th": "งานอุตสาหกรรมปานกลาง",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                },
                {
                    "id": "LIGHT-MFG-F01",
                    "category": "manufacturing_fine",
                    "workplace_type_th": "งานประกอบชิ้นส่วนอิเล็กทรอนิกส์ งานเย็บผ้า งานพิมพ์ละเอียด",
                    "workplace_type_en": "Electronic PCB assembly, sewing, fine printing",
                    "standard_lux_min": 400.0,
                    "recommended_lux_range": "400 - 600 Lux",
                    "category_name_th": "งานอุตสาหกรรมละเอียด",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                },
                {
                    "id": "LIGHT-MFG-X01",
                    "category": "manufacturing_extra_fine",
                    "workplace_type_th": "งานประกอบนาฬิกา งานเจียระไนเพชรพลอย งานไมโครชิป",
                    "workplace_type_en": "Watchmaking, diamond cutting, microchip fabrication",
                    "standard_lux_min": 1000.0,
                    "recommended_lux_range": "1000 - 1500 Lux",
                    "category_name_th": "งานละเอียดเป็นพิเศษ",
                    "legal_reference": "ประกาศกรมสวัสดิการฯ แสงสว่าง ๒๕๖๑"
                }
            ],
            "noise_standards": {
                "statutory_limit_8hr_twa_dba": 86.0,
                "action_level_dba": 85.0,
                "continuous_ceiling_max_dba": 115.0,
                "peak_impact_max_db": 140.0,
                "exchange_rate_q_db": 3.0,
                "criterion_level_lc_dba": 86.0
            },
            "heat_wbgt_standards": {
                "formulas": {
                    "indoor": {"formula_expression": "WBGT = 0.7 * NWB + 0.3 * GT"},
                    "outdoor": {"formula_expression": "WBGT = 0.7 * NWB + 0.2 * GT + 0.1 * DB"}
                },
                "workload_limits": [
                    {"category": "light", "standard_wbgt_limit_c": 34.0, "metabolic_rate_max": 200.0},
                    {"category": "moderate", "standard_wbgt_limit_c": 32.0, "metabolic_rate_max": 350.0},
                    {"category": "heavy", "standard_wbgt_limit_c": 30.0, "metabolic_rate_min": 350.0}
                ]
            },
            "subcontractor_standards": {
                "section_9_individual": {"prefix": "นบ."},
                "section_11_juristic": {"prefix": "บ."}
            },
            "laws_catalog": []
        }

    # =========================================================================
    # 1. LIGHTING SEARCH & COMPLIANCE EVALUATION (ประกาศกรมฯ แสงสว่าง ๒๕๖๑)
    # =========================================================================

    def search_lighting(
        self,
        query: Optional[str] = None,
        category: str = "all",
        measured_lux: Optional[float] = None,
        surrounding_lux: Optional[float] = None,
        limit: int = 10
    ) -> Dict[str, Any]:
        """
        Search statutory lighting intensity standards and evaluate measured lux.
        """
        standards_list: List[Dict[str, Any]] = self.standards_data.get("lighting_standards", [])
        matched: List[Dict[str, Any]] = []

        query_str = (query or "").strip().lower()
        cat_filter = (category or "all").strip().lower()

        for item in standards_list:
            # Category filter
            if cat_filter != "all" and item.get("category", "").lower() != cat_filter:
                continue

            # Query keyword filter
            if query_str:
                combined_text = (
                    f"{item.get('id', '')} "
                    f"{item.get('workplace_type_th', '')} "
                    f"{item.get('workplace_type_en', '')} "
                    f"{item.get('category_name_th', '')} "
                    f"{item.get('category', '')}"
                ).lower()
                if query_str not in combined_text:
                    # Token-level matching
                    tokens = query_str.split()
                    if not any(token in combined_text for token in tokens):
                        continue

            matched_item = dict(item)

            # Perform compliance evaluation if measured_lux is provided
            if measured_lux is not None:
                evaluation = self.evaluate_lighting_item(
                    item=item,
                    measured_lux=measured_lux,
                    surrounding_lux=surrounding_lux
                )
                matched_item["evaluation"] = evaluation

            matched.append(matched_item)
            if len(matched) >= limit:
                break

        return {
            "status": "success",
            "query": query or "",
            "category": category,
            "total_found": len(matched),
            "results": matched
        }

    def evaluate_lighting_item(
        self,
        item: Dict[str, Any],
        measured_lux: float,
        surrounding_lux: Optional[float] = None
    ) -> Dict[str, Any]:
        """Evaluate a measured lux value against a specific lighting standard record."""
        std_min = float(item.get("standard_lux_min", 300.0))
        is_compliant = float(measured_lux) >= std_min
        variance = round(float(measured_lux) - std_min, 2)
        ratio_pct = round((float(measured_lux) / std_min) * 100.0, 2) if std_min > 0 else 100.0

        eval_result: Dict[str, Any] = {
            "measured_lux": float(measured_lux),
            "standard_min_lux": std_min,
            "is_compliant": is_compliant,
            "variance_lux": variance,
            "compliance_ratio_pct": ratio_pct,
            "status_badge": "COMPLIANT_ADEQUATE" if is_compliant else "NON_COMPLIANT_DEFICIENT"
        }

        if not is_compliant:
            eval_result["deficiency_lux"] = abs(variance)
            eval_result["corrective_recommendation"] = (
                f"ความเข้มของแสงสว่างต่ำกว่ามาตรฐานขั้นต่ำ {std_min} Lux (ขาดอยู่ {abs(variance)} Lux) "
                f"ต้องดำเนินการปรับปรุงระบบแสงสว่าง เช่น เปลี่ยนหลอดไฟ LED ที่มีค่า Lumen สูงขึ้น, "
                f"ทำความสะอาดโคมไฟ, หรือติดตั้งโคมไฟส่องสว่างเฉพาะจุด (Task Lighting)"
            )
        else:
            eval_result["corrective_recommendation"] = "ระดับความเข้มของแสงสว่างเป็นไปตามมาตรฐานกฎหมาย"

        # Surrounding lighting assessment (รัศมี 0.5 เมตร ต้องไม่น้อยกว่า 1/3 ของจุดทำงาน)
        if surrounding_lux is not None:
            surr_float = float(surrounding_lux)
            min_surr_ratio = std_min / 3.0
            surr_pass = surr_float >= min_surr_ratio
            eval_result["surrounding_evaluation"] = {
                "surrounding_lux": surr_float,
                "minimum_required_surrounding_lux": round(min_surr_ratio, 2),
                "is_surrounding_compliant": surr_pass,
                "surrounding_ratio": round(surr_float / float(measured_lux), 2) if float(measured_lux) > 0 else 0.0,
                "note": "ความเข้มแสงสว่างบริเวณรอบๆ จุดทำงานในรัศมี ๐.๕ เมตร ต้องไม่น้อยกว่า ๑ ใน ๓ ของความเข้มแสงสว่าง ณ จุดทำงาน"
            }
            if not surr_pass:
                eval_result["surrounding_recommendation"] = (
                    f"ความเข้มแสงสว่างบริเวณโดยรอบ ({surr_float} Lux) ต่ำกว่าเกณฑ์ ๑/๓ ({round(min_surr_ratio, 2)} Lux) "
                    f"อาจทำให้สายตาเกิดความเมื่อยล้าจากความเปรียบต่างสูง (Glare/Contrast Fatigue) ควรเพิ่มแสงสว่างบริเวณรอบข้าง"
                )

        return eval_result

    # =========================================================================
    # 2. NOISE EVALUATION & TWA 8-HR CALCULATION (ประกาศกรมฯ เสียง ๒๕๖๑)
    # =========================================================================

    def calculate_permissible_noise_duration(self, measured_dba: float) -> float:
        """
        Calculate statutory permissible exposure duration in hours:
        T = 8 / 2^((L - 86) / 3) = 8 * 2^((86 - L) / 3)
        """
        L = float(measured_dba)
        if L <= 0:
            return 999.0
        if L > 115.0:
            return 0.0  # Continuous noise > 115 dBA is strictly forbidden without protection
        # Exchange rate Q = 3 dB, Criterion Lc = 86 dBA
        exponent = (86.0 - L) / 3.0
        return 8.0 * math.pow(2.0, exponent)

    def calculate_noise_dose(self, measured_dba: float, duration_hours: float = 8.0) -> float:
        """Calculate Noise Dose percentage: Dose = (C / T) * 100%"""
        T = self.calculate_permissible_noise_duration(measured_dba)
        if T <= 0:
            return 9999.0
        return round((float(duration_hours) / T) * 100.0, 2)

    def calculate_twa_8hr(self, noise_dose_pct: float) -> float:
        """
        Calculate 8-Hour Time-Weighted Average from Noise Dose:
        TWA_8h = 86 + (3 / log10(2)) * log10(Dose / 100) = 86 + 9.965784 * log10(Dose / 100)
        """
        dose = float(noise_dose_pct)
        if dose <= 0:
            return 0.0
        return round(86.0 + 9.965784 * math.log10(dose / 100.0), 2)

    def format_duration(self, hours: float) -> str:
        """Format duration hours into human-readable Thai text."""
        if hours <= 0:
            return "๐ วินาที (ห้ามสัมผัสโดยไม่มีอุปกรณ์ป้องกัน)"
        if hours >= 24.0:
            return f"{hours:.1f} ชั่วโมง"
        total_seconds = int(round(hours * 3600))
        h = total_seconds // 3600
        m = (total_seconds % 3600) // 60
        s = total_seconds % 60
        parts = []
        if h > 0:
            parts.append(f"{h} ชั่วโมง")
        if m > 0:
            parts.append(f"{m} นาที")
        if s > 0 and h == 0:
            parts.append(f"{s} วินาที")
        return " ".join(parts) if parts else "๐ นาที"

    def evaluate_noise(
        self,
        measured_dba: float,
        duration_hours: float = 8.0,
        peak_db: Optional[float] = None,
        noise_type: str = "continuous"
    ) -> Dict[str, Any]:
        """
        Comprehensive statutory evaluation for noise exposure under Ministerial Reg. 2559 & DLPW Notification 2561.
        """
        L = float(measured_dba)
        dur = float(duration_hours)
        peak = float(peak_db) if peak_db is not None else None

        statutory_limit_8hr = 86.0
        action_level = 85.0
        continuous_ceiling = 115.0
        peak_limit = 140.0

        permissible_hours = self.calculate_permissible_noise_duration(L)
        dose_pct = self.calculate_noise_dose(L, dur)
        twa_8h = self.calculate_twa_8hr(dose_pct) if dur != 8.0 else L

        # Critical ceiling checks
        is_continuous_exceeded = L > continuous_ceiling
        is_peak_exceeded = (peak is not None) and (peak > peak_limit)

        # Standard 8-hr compliance check
        is_compliant = (dose_pct <= 100.0) and (not is_continuous_exceeded) and (not is_peak_exceeded)

        # Action Level & Hearing Conservation Program Mandate
        # HCP is required if 8-hr TWA >= 85.0 dBA or Dose >= 79.37% (ข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙)
        is_hcp_required = (twa_8h >= action_level) or (dose_pct >= 79.37) or (L >= action_level and dur >= 8.0)

        # Status badge determination
        if is_peak_exceeded:
            compliance_status = "CRITICAL_PEAK_LIMIT_VIOLATION"
            status_badge = "FAIL_CRITICAL"
        elif is_continuous_exceeded:
            compliance_status = "CRITICAL_CONTINUOUS_CEILING_VIOLATION"
            status_badge = "FAIL_CRITICAL"
        elif not is_compliant:
            compliance_status = "EXCEEDED_STANDARD"
            status_badge = "FAIL"
        elif is_hcp_required:
            compliance_status = "ACTION_LEVEL_HCP_MANDATORY"
            status_badge = "ACTION_LEVEL"
        else:
            compliance_status = "COMPLIANT_NORMAL"
            status_badge = "PASS"

        # PPE Attenuation NRR Calculation
        # Protected Level = Measured - (NRR - 7) / 2 <= 80 dBA
        target_attenuation = max(0.0, L - 80.0)
        recommended_nrr = math.ceil(target_attenuation * 2.0 + 7.0) if target_attenuation > 0 else 0

        ppe_recommendation = (
            f"อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลลดเสียง (Hearing Protection Device): "
            f"แนะนำ Earplugs หรือ Earmuffs ที่มีค่า NRR >= {recommended_nrr} dB (มาตรฐาน มอก. หรือ ANSI S3.19)"
            if recommended_nrr > 0 else "ไม่จำเป็นต้องใช้อุปกรณ์ลดเสียงเป็นพิเศษในสภาวะปกติ"
        )

        recommended_controls = []
        if is_hcp_required:
            recommended_controls.append("จัดทำโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program) เป็นลายลักษณ์อักษร (ข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙)")
            recommended_controls.append("ตรวจสมรรถภาพการได้ยิน (Audiometric Testing) แก่ลูกจ้างแรกเข้าและประจำปีทุก ๑๒ เดือน")
            recommended_controls.append("จัดทำแผนผังแสดงระดับเสียง (Noise Contour Map) และติดป้ายเตือนบังคับสวมใส่อุปกรณ์ลดเสียง")
        if not is_compliant:
            recommended_controls.append("มาตรการทางวิศวกรรม: ติดตั้งโครงสร้างซับเสียง (Acoustic Enclosure), แผ่นยางกันสะเทือน หรือ Silencer")
            recommended_controls.append("มาตรการบริหารจัดการ: สลับผลัดหมุนเวียนลูกจ้างเพื่อจำกัดเวลาการสัมผัสเสียงไม่ให้เกินเวลาที่กำหนด")
            recommended_controls.append(f"บังคับสวมใส่อุปกรณ์ลดเสียง: {ppe_recommendation}")

        return {
            "status": "success",
            "measured_dba": L,
            "duration_hours": dur,
            "peak_db": peak,
            "noise_type": noise_type,
            "statutory_limit_8hr_dba": statutory_limit_8hr,
            "action_level_dba": action_level,
            "continuous_ceiling_dba": continuous_ceiling,
            "peak_max_db": peak_limit,
            "is_compliant": is_compliant,
            "compliance_status": compliance_status,
            "status_badge": status_badge,
            "calculated_twa_8hr_dba": twa_8h,
            "noise_dose_pct": dose_pct,
            "permissible_duration_hours": round(permissible_hours, 2),
            "permissible_duration_formatted": self.format_duration(permissible_hours),
            "hearing_conservation_required": is_hcp_required,
            "hearing_conservation_reason": (
                "ระดับเสียงเฉลี่ยตลอดการทำงาน ๘ ชั่วโมง เท่ากับหรือเกิน ๘๕ dBA (ข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙)"
                if is_hcp_required else "ระดับเสียงไม่ถึงเกณฑ์เฝ้าระวัง ๘๕ dBA"
            ),
            "required_ppe_nrr": recommended_nrr,
            "ppe_recommendation": ppe_recommendation,
            "recommended_controls": recommended_controls,
            "legal_reference": "กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ (ข้อ ๗, ๘, ๑๐, ๑๑) และประกาศกรมฯ มาตรฐานระดับเสียง พ.ศ. ๒๕๖๑"
        }

    # =========================================================================
    # 3. HEAT WBGT CALCULATION & EVALUATION (ประกาศกรมฯ ความร้อน ๒๕๖๓)
    # =========================================================================

    def calculate_wbgt(
        self,
        nwb: float,
        gt: float,
        db: Optional[float] = None,
        is_outdoor: bool = False,
        workload_category: str = "moderate",
        metabolic_rate: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Calculate Indoor/Outdoor Wet Bulb Globe Temperature (WBGT) and evaluate against metabolic workload limits.
        Formulas:
          - Indoor / No Solar: WBGT = 0.7 * NWB + 0.3 * GT
          - Outdoor / Solar:    WBGT = 0.7 * NWB + 0.2 * GT + 0.1 * DB
        """
        t_nwb = float(nwb)
        t_gt = float(gt)
        t_db = float(db) if db is not None else None

        if is_outdoor:
            if t_db is None:
                raise ValueError("Dry bulb temperature (db) is required for outdoor WBGT calculation with solar radiation.")
            calculated_wbgt = 0.7 * t_nwb + 0.2 * t_gt + 0.1 * t_db
            formula_used = "WBGT = 0.7 * NWB + 0.2 * GT + 0.1 * DB (กลางแจ้ง/มีแสงแดด)"
            env_mode = "outdoor_with_solar"
        else:
            calculated_wbgt = 0.7 * t_nwb + 0.3 * t_gt
            formula_used = "WBGT = 0.7 * NWB + 0.3 * GT (ในร่ม/ไม่มีแสงแดด)"
            env_mode = "indoor_no_solar"

        calculated_wbgt = round(calculated_wbgt, 2)

        # Determine workload category and statutory limit
        workload_key = (workload_category or "moderate").strip().lower()

        if metabolic_rate is not None:
            m_rate = float(metabolic_rate)
            if m_rate <= 200.0:
                workload_key = "light"
            elif m_rate <= 350.0:
                workload_key = "moderate"
            else:
                workload_key = "heavy"

        limits_map = {
            "light": {"limit": 34.0, "name_th": "งานเบา (การใช้พลังงาน <= 200 kcal/hr)", "desc": "งานนั่งเขียนหนังสือ พิมพ์ดีด ขับขี่รถยก ประกอบชิ้นงานขนาดเล็ก"},
            "moderate": {"limit": 32.0, "name_th": "งานปานกลาง (การใช้พลังงาน 200 - 350 kcal/hr)", "desc": "งานกลึง ไส เจาะ ก่ออิฐฉาบปูน ประกอบรถยนต์ ยกของ 5-15 กก."},
            "heavy": {"limit": 30.0, "name_th": "งานหนัก (การใช้พลังงาน > 350 kcal/hr)", "desc": "งานแบกหามของหนัก (> 15 กก.) งานขุดดิน ใช้ค้อนปอนด์ เทโลหะหลอมเหลว"}
        }

        limit_info = limits_map.get(workload_key, limits_map["moderate"])
        statutory_limit = limit_info["limit"]

        is_compliant = calculated_wbgt <= statutory_limit
        safety_margin = round(statutory_limit - calculated_wbgt, 2)

        recommendations = []
        if not is_compliant:
            recommendations.append(f"ระดับความร้อน ({calculated_wbgt}°C WBGT) เกินเกณฑ์มาตรฐาน {statutory_limit}°C WBGT")
            recommendations.append("จัดให้มีจุดพักผ่อนที่มีอากาศถ่ายเทสะดวกหรือห้องปรับอากาศ (Cooling Area)")
            recommendations.append("จัดบริการน้ำดื่มสะอาดและเกลือแร่ (Electrolyte) ประจำจุดทำงานอย่างเพียงพอ")
            recommendations.append("ปรับตารางการทำงานและการพัก (Work-Rest Cycles) เช่น ทำงาน 45 นาที พัก 15 นาที ต่อชั่วโมง")
            recommendations.append("จัดหาอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลทนความร้อน (Heat PPE) เช่น เสื้อสะท้อนความร้อน กระบังหน้าทนความร้อน")
        else:
            recommendations.append("ระดับความร้อนอยู่ในเกณฑ์มาตรฐานความปลอดภัยตามกฎหมาย")
            recommendations.append("จัดให้น้ำดื่มสะอาดเพียงพอ และเฝ้าระวังอาการเจ็บป่วยจากความร้อนในช่วงฤดูร้อน")

        return {
            "status": "success",
            "environment_mode": env_mode,
            "inputs": {
                "nwb_c": t_nwb,
                "gt_c": t_gt,
                "db_c": t_db
            },
            "formula_used": formula_used,
            "calculated_wbgt_c": calculated_wbgt,
            "workload_category": workload_key,
            "workload_description": limit_info["name_th"],
            "workload_examples": limit_info["desc"],
            "statutory_limit_wbgt_c": statutory_limit,
            "is_compliant": is_compliant,
            "safety_margin_c": safety_margin,
            "compliance_status": "COMPLIANT_WITHIN_LIMIT" if is_compliant else "NON_COMPLIANT_HEAT_STRESS",
            "status_badge": "PASS" if is_compliant else "FAIL",
            "recommendations": recommendations,
            "legal_reference": "กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ (ข้อ ๒) และประกาศกรมฯ การคำนวณและประเมินระดับความร้อน พ.ศ. ๒๕๖๓"
        }

    def calculate_time_weighted_wbgt(self, time_records: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate Time-Weighted Average WBGT and Metabolic Rate across multiple workstations/rest cycles:
        WBGT_twa = sum(WBGT_i * t_i) / sum(t_i)
        Metabolic_twa = sum(M_i * t_i) / sum(t_i)
        """
        if not time_records:
            raise ValueError("No time records provided for time-weighted WBGT calculation.")

        total_time = 0.0
        weighted_wbgt_sum = 0.0
        weighted_metabolic_sum = 0.0

        for r in time_records:
            t = float(r.get("duration_minutes", 0.0))
            w = float(r.get("wbgt", 0.0))
            m = float(r.get("metabolic_rate", 200.0))
            if t <= 0:
                continue
            total_time += t
            weighted_wbgt_sum += w * t
            weighted_metabolic_sum += m * t

        if total_time <= 0:
            raise ValueError("Total duration across all records must be greater than zero.")

        avg_wbgt = round(weighted_wbgt_sum / total_time, 2)
        avg_metabolic = round(weighted_metabolic_sum / total_time, 2)

        # Evaluate against average metabolic rate
        wbgt_eval = self.calculate_wbgt(
            nwb=avg_wbgt,
            gt=avg_wbgt,
            metabolic_rate=avg_metabolic
        )

        return {
            "status": "success",
            "total_duration_minutes": total_time,
            "time_weighted_wbgt_c": avg_wbgt,
            "time_weighted_metabolic_rate_kcal_hr": avg_metabolic,
            "evaluation": wbgt_eval
        }

    # =========================================================================
    # 4. SUBCONTRACTOR REGISTRATION AUDIT (มาตรา ๙ & มาตรา ๑๑)
    # =========================================================================

    def verify_subcontractor(
        self,
        license_type: str,
        license_no: str,
        expiry_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Verify qualifications and registration number format for Section 9 Individual or Section 11 Juristic Entity.
        """
        raw_type = (license_type or "").strip().lower()
        lic_str = (license_no or "").strip()

        is_section_9 = "9" in raw_type or "individual" in raw_type or "บุคคล" in raw_type or "นบ" in raw_type
        is_section_11 = "11" in raw_type or "juristic" in raw_type or "นิติบุคคล" in raw_type or "บ." in raw_type or raw_type.startswith("บ")

        if not is_section_9 and not is_section_11:
            # Try to auto-detect from prefix
            if lic_str.startswith("นบ") or lic_str.startswith("NB"):
                is_section_9 = True
            elif lic_str.startswith("บ") or lic_str.startswith("B"):
                is_section_11 = True
            else:
                is_section_11 = True  # Default to Juristic

        if is_section_9:
            target_type = "SECTION_9_INDIVIDUAL"
            type_title_th = "บุคคลธรรมดาผู้ขึ้นทะเบียนตามมาตรา ๙ (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)"
            expected_prefix = "นบ."
            pattern = r"^(?:นบ\.?\s*|NB-?)?\d{1,5}(?:[-/]\d{1,4})*(?:/\d{2,4})?$"
            penalty_ref = "หากฝ่าฝืนให้บริการโดยไม่ขึ้นทะเบียน ระวางโทษจำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (มาตรา ๕๖)"
        else:
            target_type = "SECTION_11_JURISTIC"
            type_title_th = "นิติบุคคลผู้ได้รับใบอนุญาตตามมาตรา ๑๑ (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)"
            expected_prefix = "บ."
            pattern = r"^(?:บ\.?\s*|B-?)?\d{1,5}(?:[-/]\d{1,4})*(?:/\d{2,4})?$"
            penalty_ref = "หากฝ่าฝืนให้บริการโดยไม่ได้รับใบอนุญาต ระวางโทษจำคุกไม่เกิน ๖ เดือน หรือปรับไม่เกิน ๒๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (มาตรา ๕๖)"

        # Check regex format
        format_valid = bool(re.match(pattern, lic_str, re.IGNORECASE)) if lic_str else False

        # Check expiration date
        is_expired = False
        expiry_status = "NOT_SPECIFIED"
        days_remaining = None

        if expiry_date:
            try:
                exp_dt = datetime.strptime(expiry_date.strip(), "%Y-%m-%d").date()
                today_dt = date(2026, 9, 1)  # Reference system date
                days_remaining = (exp_dt - today_dt).days
                if days_remaining < 0:
                    is_expired = True
                    expiry_status = f"EXPIRED (หมดอายุเมื่อ {expiry_date})"
                elif days_remaining <= 60:
                    expiry_status = f"EXPIRING_SOON (เหลือ {days_remaining} วัน)"
                else:
                    expiry_status = f"ACTIVE (มีผลบังคับใช้ถึง {expiry_date})"
            except Exception:
                expiry_status = "INVALID_DATE_FORMAT (ต้องเป็น YYYY-MM-DD)"

        is_overall_valid = format_valid and (not is_expired)

        return {
            "status": "success",
            "license_type": target_type,
            "license_type_title_th": type_title_th,
            "license_no": lic_str,
            "expected_prefix": expected_prefix,
            "is_format_valid": format_valid,
            "expiry_date": expiry_date,
            "expiry_status": expiry_status,
            "is_expired": is_expired,
            "is_valid": is_overall_valid,
            "calibration_mandate": "เครื่องมือวัดทุกชิ้นต้องมีใบรับรองการสอบเทียบ (Calibration Certificate) จากห้องปฏิบัติการ ISO/IEC 17025 มีอายุไม่เกิน ๑ ปี",
            "penalty_clause": penalty_ref,
            "legal_reference": "พ.ร.บ. ความปลอดภัยฯ พ.ศ. ๒๕๕๔ มาตรา ๙, มาตรา ๑๑, มาตรา ๕๖ และกฎกระทรวงฯ ๒๕๕๙ ข้อ ๑๔"
        }

    # =========================================================================
    # 5. BATCH ENVIRONMENTAL SESSION EVALUATION & AUTO CAPA GENERATION
    # =========================================================================

    def evaluate_session(self, session_data_or_file: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """
        Batch evaluate an entire workplace environmental monitoring session:
          - Validates all light, noise, and heat points
          - Verifies subcontractor accreditation
          - Calculates overall Compliance Index % and assign grade
          - Automatically synthesizes prioritized CAPA Action Plans
          - Summarizes official DLPW reporting timelines (15-day posting, 30-day submission)
        """
        if isinstance(session_data_or_file, str):
            if os.path.exists(session_data_or_file):
                with open(session_data_or_file, "r", encoding="utf-8") as f:
                    session = json.load(f)
            else:
                session = json.loads(session_data_or_file)
        else:
            session = session_data_or_file

        session_id = session.get("session_id", "ENV-SESSION-001")
        workplace_name = session.get("workplace_name", "สถานประกอบกิจการ")
        survey_year = session.get("survey_year", 2569)
        survey_date = session.get("survey_date", "2026-09-01")

        # Verify subcontractor
        subcontractor_info = session.get("subcontractor", {})
        subcon_eval = None
        if subcontractor_info:
            subcon_eval = self.verify_subcontractor(
                license_type=subcontractor_info.get("license_type", "SECTION_11_JURISTIC"),
                license_no=subcontractor_info.get("license_no", "") or subcontractor_info.get("assessor_reg_no", ""),
                expiry_date=subcontractor_info.get("expiry_date")
            )

        points = session.get("points", [])
        evaluated_points: List[Dict[str, Any]] = []
        capa_plans: List[Dict[str, Any]] = []

        total_points = len(points)
        compliant_points = 0
        action_level_points = 0
        non_compliant_points = 0

        light_stats = {"total": 0, "pass": 0, "fail": 0}
        noise_stats = {"total": 0, "pass": 0, "action_level": 0, "fail": 0, "hcp_required_count": 0}
        heat_stats = {"total": 0, "pass": 0, "fail": 0}

        capa_counter = 1

        for pt in points:
            pt_id = pt.get("point_id", f"PT-{len(evaluated_points)+1}")
            factor = pt.get("factor_type", "").upper()
            dept = pt.get("department", "พื้นที่ปฏิบัติงาน")
            loc = pt.get("location_name", "จุดตรวจวัด")

            eval_pt: Dict[str, Any] = {
                "point_id": pt_id,
                "factor_type": factor,
                "department": dept,
                "location_name": loc
            }

            # -------------------------------------------------------------
            # Factor A: LIGHT
            # -------------------------------------------------------------
            if "LIGHT" in factor:
                light_stats["total"] += 1
                measured_lux = float(pt.get("measured_lux", 300.0))
                surrounding_lux = pt.get("surrounding_lux")
                std_id = pt.get("standard_id")
                std_min = float(pt.get("standard_min_lux", 0.0))

                # Find standard item if id provided
                matched_std = None
                if std_id:
                    for s in self.standards_data.get("lighting_standards", []):
                        if s.get("id") == std_id:
                            matched_std = s
                            break

                if matched_std:
                    light_eval = self.evaluate_lighting_item(
                        item=matched_std,
                        measured_lux=measured_lux,
                        surrounding_lux=surrounding_lux
                    )
                else:
                    if std_min <= 0:
                        std_min = 300.0
                    dummy_std = {"id": "CUSTOM", "standard_lux_min": std_min, "workplace_type_th": loc}
                    light_eval = self.evaluate_lighting_item(
                        item=dummy_std,
                        measured_lux=measured_lux,
                        surrounding_lux=surrounding_lux
                    )

                eval_pt["evaluation"] = light_eval
                is_pass = light_eval["is_compliant"]

                if is_pass:
                    light_stats["pass"] += 1
                    compliant_points += 1
                    eval_pt["status_badge"] = "PASS"
                else:
                    light_stats["fail"] += 1
                    non_compliant_points += 1
                    eval_pt["status_badge"] = "FAIL"

                    # Generate CAPA
                    capa_id = f"CAPA-ENV-{survey_year}-{capa_counter:03d}"
                    capa_counter += 1
                    eval_pt["capa_id"] = capa_id
                    capa_plans.append({
                        "capa_id": capa_id,
                        "point_id": pt_id,
                        "factor": "LIGHTING",
                        "department": dept,
                        "location_name": loc,
                        "measured_value": f"{measured_lux} Lux",
                        "standard_threshold": f">= {light_eval['standard_min_lux']} Lux",
                        "severity": "MEDIUM",
                        "root_cause": "ความเข้มแสงสว่างไม่เพียงพอเนื่องจากหลอดไฟเสื่อมสภาพ ตำแหน่งการติดตั้งโคมไฟสูงเกินไป หรือไม่มีโคมไฟเฉพาะจุด",
                        "corrective_action": "เปลี่ยนหลอดประหยัดไฟ LED กำลังส่องสว่างสูงขึ้น หรือติดตั้งโคมไฟเฉพาะจุด (Task Lighting)",
                        "preventive_action": "จัดทำตารางทำความสะอาดและตรวจสอบประสิทธิภาพโคมไฟส่องสว่างทุก ๖ เดือน",
                        "hierarchy_control": "Engineering Control",
                        "pic": "หัวหน้าแผนกซ่อมบำรุง / จป.วิชาชีพ",
                        "target_deadline": "30 วัน",
                        "status": "OPEN"
                    })

            # -------------------------------------------------------------
            # Factor B: NOISE
            # -------------------------------------------------------------
            elif "NOISE" in factor:
                noise_stats["total"] += 1
                measured_dba = float(pt.get("measured_dba", 80.0))
                dur = float(pt.get("duration_hours", 8.0))
                peak = pt.get("peak_db")
                noise_type = pt.get("noise_type", "continuous")

                noise_eval = self.evaluate_noise(
                    measured_dba=measured_dba,
                    duration_hours=dur,
                    peak_db=peak,
                    noise_type=noise_type
                )
                eval_pt["evaluation"] = noise_eval
                status_badge = noise_eval["status_badge"]
                eval_pt["status_badge"] = status_badge

                if noise_eval["hearing_conservation_required"]:
                    noise_stats["hcp_required_count"] += 1

                if status_badge == "PASS":
                    noise_stats["pass"] += 1
                    compliant_points += 1
                elif status_badge == "ACTION_LEVEL":
                    noise_stats["action_level"] += 1
                    action_level_points += 1
                    compliant_points += 1  # Action level is compliant but requires monitoring

                    # Generate Action Level CAPA
                    capa_id = f"CAPA-ENV-{survey_year}-{capa_counter:03d}"
                    capa_counter += 1
                    eval_pt["capa_id"] = capa_id
                    capa_plans.append({
                        "capa_id": capa_id,
                        "point_id": pt_id,
                        "factor": "NOISE_ACTION_LEVEL",
                        "department": dept,
                        "location_name": loc,
                        "measured_value": f"{measured_dba} dBA ({dur} ชม.)",
                        "standard_threshold": "85.0 - 86.0 dBA (Action Level)",
                        "severity": "HIGH",
                        "root_cause": "ระดับเสียงเฉลี่ยเข้าสู่เกณฑ์เฝ้าระวัง Action Level ตามกฎหมาย (ข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙)",
                        "corrective_action": "บรรจุพื้นที่เข้าสู่ 'โครงการอนุรักษ์การได้ยิน' (Hearing Conservation Program), ตรวจ Audiogram ประจำปี, แจก Earplugs",
                        "preventive_action": "ตรวจวัดระดับเสียงติดตามผลทุก ๖ เดือน และติดป้ายเตือนระดับเสียง",
                        "hierarchy_control": "Administrative & PPE Control",
                        "pic": "จป.วิชาชีพ / คณะกรรมการ คปอ.",
                        "target_deadline": "30 วัน",
                        "status": "OPEN"
                    })
                else:
                    noise_stats["fail"] += 1
                    non_compliant_points += 1

                    # Generate High Severity Failure CAPA
                    capa_id = f"CAPA-ENV-{survey_year}-{capa_counter:03d}"
                    capa_counter += 1
                    eval_pt["capa_id"] = capa_id
                    capa_plans.append({
                        "capa_id": capa_id,
                        "point_id": pt_id,
                        "factor": "NOISE_EXCEEDED",
                        "department": dept,
                        "location_name": loc,
                        "measured_value": f"{measured_dba} dBA (Dose {noise_eval['noise_dose_pct']}%)",
                        "standard_threshold": "<= 86.0 dBA (8 ชม.) / Continuous <= 115 dBA",
                        "severity": "CRITICAL",
                        "root_cause": "การทำงานของเครื่องจักรกลหนักไม่มีฉนวนซับเสียง หรือไม่มีการสลับผลัดลดระยะเวลารับสัมผัส",
                        "corrective_action": f"ติดตั้งฉนวนซับเสียงรอบเครื่องจักร (Acoustic Enclosure), บังคับสวมใส่ {noise_eval['ppe_recommendation']}, สลับผลัดทำงาน",
                        "preventive_action": "จัดทำโครงการอนุรักษ์การได้ยินเต็มรูปแบบ และปรับปรุงแผนบำรุงรักษาเครื่องจักร",
                        "hierarchy_control": "Engineering, Administrative & PPE",
                        "pic": "ผู้จัดการฝ่ายผลิต / จป.วิชาชีพ",
                        "target_deadline": "15 วัน",
                        "status": "OPEN"
                    })

            # -------------------------------------------------------------
            # Factor C: HEAT WBGT
            # -------------------------------------------------------------
            elif "HEAT" in factor or "WBGT" in factor:
                heat_stats["total"] += 1
                nwb = float(pt.get("nwb", 28.0))
                gt = float(pt.get("gt", 35.0))
                db = pt.get("db")
                is_outdoor = bool(pt.get("is_outdoor", False))
                workload = pt.get("workload", "moderate")
                metabolic = pt.get("metabolic_rate")

                heat_eval = self.calculate_wbgt(
                    nwb=nwb,
                    gt=gt,
                    db=db,
                    is_outdoor=is_outdoor,
                    workload_category=workload,
                    metabolic_rate=metabolic
                )
                eval_pt["evaluation"] = heat_eval
                is_pass = heat_eval["is_compliant"]

                if is_pass:
                    heat_stats["pass"] += 1
                    compliant_points += 1
                    eval_pt["status_badge"] = "PASS"
                else:
                    heat_stats["fail"] += 1
                    non_compliant_points += 1
                    eval_pt["status_badge"] = "FAIL"

                    # Generate Heat CAPA
                    capa_id = f"CAPA-ENV-{survey_year}-{capa_counter:03d}"
                    capa_counter += 1
                    eval_pt["capa_id"] = capa_id
                    capa_plans.append({
                        "capa_id": capa_id,
                        "point_id": pt_id,
                        "factor": "HEAT_WBGT_EXCEEDED",
                        "department": dept,
                        "location_name": loc,
                        "measured_value": f"{heat_eval['calculated_wbgt_c']}°C WBGT",
                        "standard_threshold": f"<= {heat_eval['statutory_limit_wbgt_c']}°C WBGT ({heat_eval['workload_description']})",
                        "severity": "HIGH",
                        "root_cause": "การสะสมความร้อนจากเตาหลอม/กระบวนการผลิต และการระบายอากาศในพื้นที่ไม่เพียงพอ",
                        "corrective_action": "ติดตั้งพัดลมระบายอากาศอุตสาหกรรม (Ventilation Fans), จัดบริการน้ำดื่มผสมเกลือแร่, จัดตารางพักในห้องปรับอากาศ",
                        "preventive_action": "ตรวจเช็กระบบดูดระบายความร้อนและเฝ้าระวังโรคลมแดด (Heat Stroke)",
                        "hierarchy_control": "Engineering & Administrative",
                        "pic": "ฝ่ายวิศวกรรมโรงงาน / จป.วิชาชีพ",
                        "target_deadline": "30 วัน",
                        "status": "OPEN"
                    })

            evaluated_points.append(eval_pt)

        # Calculate Overall Compliance Index Percentage
        if total_points > 0:
            compliance_index_pct = round((compliant_points / float(total_points)) * 100.0, 2)
        else:
            compliance_index_pct = 100.0

        if compliance_index_pct >= 90.0:
            grade = "A - EXCELLENT"
        elif compliance_index_pct >= 80.0:
            grade = "B - GOOD"
        elif compliance_index_pct >= 70.0:
            grade = "C - NEEDS_IMPROVEMENT"
        else:
            grade = "D - CRITICAL_NON_COMPLIANT"

        return {
            "status": "success",
            "session_summary": {
                "session_id": session_id,
                "workplace_name": workplace_name,
                "survey_year": survey_year,
                "survey_date": survey_date,
                "subcontractor_audit": subcon_eval,
                "kpi_metrics": {
                    "total_points": total_points,
                    "compliant_points": compliant_points,
                    "action_level_points": action_level_points,
                    "non_compliant_points": non_compliant_points,
                    "compliance_index_pct": compliance_index_pct,
                    "overall_grade": grade
                },
                "factor_breakdown": {
                    "lighting": light_stats,
                    "noise": noise_stats,
                    "heat_wbgt": heat_stats
                }
            },
            "evaluated_points": evaluated_points,
            "capa_action_plans": capa_plans,
            "statutory_deadlines_notice": {
                "posting_at_workplace": "นายจ้างต้องปิดประกาศผลการตรวจวัดในที่เปิดเผยให้ลูกจ้างทราบ ภายใน ๑๕ วัน นับแต่วันที่ได้รับรายงาน (พ.ร.บ. ม.๑๕)",
                "submission_to_dlpw": "นายจ้างต้องส่งรายงานผลการตรวจวัด (แบบ อธ.๑) ต่ออธิบดีหรือผู้ตรวจความปลอดภัย ภายใน ๓๐ วัน นับแต่วันตรวจวัด (พ.ร.บ. ม.๑๕ และ กฎกระทรวงฯ ข้อ ๑๕)",
                "document_retention": "นายจ้างต้องเก็บรักษาเอกสารรายงานผลการตรวจวัดไว้ ณ สถานประกอบกิจการ ไม่น้อยกว่า ๕ ปี (กฎกระทรวงฯ ข้อ ๑๕)"
            }
        }

    # =========================================================================
    # 6. STATUTORY LAW PROVISIONS RETRIEVAL
    # =========================================================================

    def get_law(self, topic: str = "all", section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve statutory articles and provisions from laws catalog."""
        catalog = self.standards_data.get("laws_catalog", [])
        topic_str = (topic or "all").strip().lower()
        sec_str = (section or "").strip().lower()

        matched_laws: List[Dict[str, Any]] = []

        for law in catalog:
            if topic_str != "all":
                law_text = f"{law.get('law_id', '')} {law.get('law_code', '')} {law.get('title_th', '')}".lower()
                if topic_str not in law_text:
                    continue

            law_copy = dict(law)
            if sec_str:
                filtered_articles = []
                for art in law.get("enforcement_articles", []):
                    art_text = f"{art.get('article', '')} {art.get('title', '')} {art.get('summary', '')}".lower()
                    if sec_str in art_text:
                        filtered_articles.append(art)
                law_copy["enforcement_articles"] = filtered_articles

            matched_laws.append(law_copy)

        return {
            "status": "success",
            "topic": topic,
            "section": section,
            "total_laws": len(matched_laws),
            "laws": matched_laws
        }
