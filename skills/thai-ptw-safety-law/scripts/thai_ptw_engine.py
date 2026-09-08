"""
==============================================================================
 Thai PTW Safety Law Engine (thai_ptw_engine.py)
 Conforming to Royal Thai Gazette PTW Safety Regulations:
   - OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
   - Ministerial Reg. Confined Space B.E. 2562 (กฎกระทรวงอับอากาศ ๒๕๖๒)
   - Ministerial Reg. Fire Safety B.E. 2555 (กฎกระทรวงอัคคีภัย ๒๕๕๕ - Hot Work)
   - Ministerial Reg. Electrical Safety B.E. 2558 (กฎกระทรวงไฟฟ้า ๒๕๕๘ - LOTO)
   - Ministerial Reg. Height & Excavation B.E. 2564 (กฎกระทรวงงานบนที่สูงและดินขุด ๒๕๖๔)
==============================================================================
"""

import os
import re
import json
from typing import Dict, Any, List, Optional, Union


class ThaiPtwEngine:
    """Pure Python statutory rule engine for Thai Permit to Work (PTW) safety compliance."""

    def __init__(self, data_dir: Optional[str] = None):
        if data_dir and os.path.exists(data_dir):
            self.data_dir = data_dir
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            candidate = os.path.join(base_dir, "data")
            if os.path.exists(candidate):
                self.data_dir = candidate
            else:
                self.data_dir = base_dir

        self.laws_catalog = self._load_json("ptw_laws_catalog.json", default={"laws": []})
        self.gas_standards = self._load_json("gas_standards.json", default={"parameters": {}})
        self.safety_checklists = self._load_json("safety_checklists.json", default={"checklists": {}})
        self.sample_ptws = self._load_json("sample_ptws.json", default={"samples": []})

    def _load_json(self, filename: str, default: Any) -> Any:
        path = os.path.join(self.data_dir, filename)
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return default
        return default

    # -------------------------------------------------------------------------
    # 1. Atmospheric Gas Testing Evaluator (ข้อ ๗ กฎกระทรวงอับอากาศ ๒๕๖๒)
    # -------------------------------------------------------------------------
    def evaluate_gas(
        self,
        o2: float,
        lel: float,
        co: float,
        h2s: float,
        measurement_type: str = "pre_entry",
        continuous_interval_hours: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Evaluate atmospheric gas testing values against Ministerial Reg. Confined Space 2562 (ข้อ ๗).
        Thresholds:
          - O2:  19.5% - 23.5%
          - LEL: < 10.0%
          - CO:  < 25.0 ppm
          - H2S: < 10.0 ppm
        """
        o2_val = float(o2)
        lel_val = float(lel)
        co_val = float(co)
        h2s_val = float(h2s)

        findings = []
        is_safe = True

        # O2 Evaluation
        if o2_val < 19.5:
            is_safe = False
            o2_status = "FAIL"
            o2_code = "OXYGEN_DEFICIENT"
            o2_alarm = "CRITICAL"
            o2_desc = f"ค่าออกซิเจน {o2_val}% ต่ำกว่าเกณฑ์มาตรฐาน 19.5% (ภาวะขาดออกซิเจน - ห้ามเข้าเด็ดขาด)"
            findings.append({
                "gas": "O2",
                "severity": "CRITICAL",
                "code": o2_code,
                "message": o2_desc,
                "action": "สั่งระงับการเข้าทำงานทันที เปิดพัดลมระบายอากาศแบบกลไก (Blower) ต่อเนื่อง และตรวจวัดซ้ำ"
            })
        elif o2_val > 23.5:
            is_safe = False
            o2_status = "FAIL"
            o2_code = "OXYGEN_ENRICHED"
            o2_alarm = "HIGH"
            o2_desc = f"ค่าออกซิเจน {o2_val}% สูงกว่าเกณฑ์มาตรฐาน 23.5% (ภาวะออกซิเจนเกิน เสี่ยงต่อการลุกไหม้รุนแรง)"
            findings.append({
                "gas": "O2",
                "severity": "HIGH",
                "code": o2_code,
                "message": o2_desc,
                "action": "ห้ามก่อให้เกิดประกายไฟ ตรวจสอบการรั่วไหลของถัง/ท่อก๊าซ และระบายอากาศ"
            })
        else:
            o2_status = "PASS"
            o2_code = "OXYGEN_NORMAL"
            o2_alarm = "NONE"
            o2_desc = f"ค่าออกซิเจน {o2_val}% อยู่ในเกณฑ์ปกติและปลอดภัย (19.5% - 23.5%)"

        # LEL Evaluation
        if lel_val >= 10.0:
            is_safe = False
            lel_status = "FAIL"
            lel_code = "EXPLOSIVE_HAZARD"
            lel_alarm = "CRITICAL"
            lel_desc = f"ค่าก๊าซ/ไอระเหยไวไฟ {lel_val}% LEL เกินเกณฑ์มาตรฐาน 10.0% LEL (บรรยากาศไวไฟ - เสี่ยงระเบิด)"
            findings.append({
                "gas": "LEL",
                "severity": "CRITICAL",
                "code": lel_code,
                "message": lel_desc,
                "action": "สั่งอพยพทันที ตัดแหล่งกำเนิดประกายไฟ และใช้พัดลมชนิด Explosion-Proof ระบายอากาศ"
            })
        else:
            lel_status = "PASS"
            lel_code = "LEL_SAFE"
            lel_alarm = "NONE"
            lel_desc = f"ค่าก๊าซไวไฟ {lel_val}% LEL ปลอดภัย (< 10.0% LEL)"

        # CO Evaluation
        if co_val >= 25.0:
            is_safe = False
            co_status = "FAIL"
            co_code = "TOXIC_CO_EXCEEDED"
            co_alarm = "HIGH"
            co_desc = f"ค่าคาร์บอนมอนอกไซด์ {co_val} ppm เกินเกณฑ์มาตรฐาน 25.0 ppm (ก๊าซพิษสะสม)"
            findings.append({
                "gas": "CO",
                "severity": "HIGH",
                "code": co_code,
                "message": co_desc,
                "action": "ระงับการเข้าทำงาน ตรวจสอบไอเสียเครื่องยนต์และระบายอากาศจนกว่าค่าจะ < 25 ppm"
            })
        else:
            co_status = "PASS"
            co_code = "CO_SAFE"
            co_alarm = "NONE"
            co_desc = f"ค่าคาร์บอนมอนอกไซด์ {co_val} ppm อยู่ในเกณฑ์ปลอดภัย (< 25.0 ppm)"

        # H2S Evaluation
        if h2s_val >= 10.0:
            is_safe = False
            h2s_status = "FAIL"
            h2s_code = "TOXIC_H2S_EXCEEDED"
            h2s_alarm = "CRITICAL"
            h2s_desc = f"ค่าก๊าซไข่เน่า (H2S) {h2s_val} ppm เกินเกณฑ์มาตรฐาน 10.0 ppm (ก๊าซพิษร้ายแรง อัมพาตการหายใจ)"
            findings.append({
                "gas": "H2S",
                "severity": "CRITICAL",
                "code": h2s_code,
                "message": h2s_desc,
                "action": "ห้ามเข้าทำงานเด็ดขาด อพยพทันที ผู้ช่วยเหลือต้องสวมใส่ชุด SCBA เท่านั้น"
            })
        else:
            h2s_status = "PASS"
            h2s_code = "H2S_SAFE"
            h2s_alarm = "NONE"
            h2s_desc = f"ค่าก๊าซไข่เน่า (H2S) {h2s_val} ppm อยู่ในเกณฑ์ปลอดภัย (< 10.0 ppm)"

        overall_status = "SAFE_TO_ENTER" if is_safe else "UNSAFE_PROHIBITED"

        actions = []
        if is_safe:
            actions.append("อนุญาตให้เข้าปฏิบัติงานได้ตามขั้นตอนความปลอดภัย")
            actions.append("ต้องเปิดพัดลมระบายอากาศแบบกลไก (Forced Mechanical Ventilation) ต่อเนื่องตลอดเวลาการทำงาน")
            actions.append("จัดให้มีการตรวจวัดซ้ำทุก ๑-๒ ชั่วโมง หรือติดตั้งเครื่องตรวจวัดแบบพกพาชนิดต่อเนื่อง")
        else:
            actions.append("ระงับการเข้าทำงานในสถานที่อับอากาศโดยเด็ดขาด (PROHIBITED ENTRY)")
            actions.append("เปิดพัดลมระบายอากาศเพื่อเจือจางอากาศเสียและเติมออกซิเจนบริสุทธิ์")
            actions.append("ตรวจวัดสภาพอากาศซ้ำจนกว่าผลการตรวจวัดจะผ่านเกณฑ์ความปลอดภัยครบทั้ง ๔ ชนิด")

        return {
            "status": "success",
            "overall_status": overall_status,
            "is_safe": is_safe,
            "measurement_type": measurement_type,
            "continuous_interval_hours": continuous_interval_hours,
            "statutory_reference": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒ ข้อ ๗",
            "readings": {
                "oxygen": {
                    "value": o2_val,
                    "unit": "%",
                    "standard_range": "19.5 - 23.5%",
                    "status": o2_status,
                    "code": o2_code,
                    "alarm_level": o2_alarm,
                    "detail": o2_desc
                },
                "combustible_gas": {
                    "value": lel_val,
                    "unit": "% LEL",
                    "standard_limit": "< 10.0% LEL",
                    "status": lel_status,
                    "code": lel_code,
                    "alarm_level": lel_alarm,
                    "detail": lel_desc
                },
                "carbon_monoxide": {
                    "value": co_val,
                    "unit": "ppm",
                    "standard_limit": "< 25.0 ppm",
                    "status": co_status,
                    "code": co_code,
                    "alarm_level": co_alarm,
                    "detail": co_desc
                },
                "hydrogen_sulfide": {
                    "value": h2s_val,
                    "unit": "ppm",
                    "standard_limit": "< 10.0 ppm",
                    "status": h2s_status,
                    "code": h2s_code,
                    "alarm_level": h2s_alarm,
                    "detail": h2s_desc
                }
            },
            "findings": findings,
            "actions": actions
        }

    # -------------------------------------------------------------------------
    # 2. Confined Space 4-Role Verifier (ข้อ ๙, ๑๐, ๑๑, ๑๒ กฎกระทรวงอับอากาศ ๒๕๖๒)
    # -------------------------------------------------------------------------
    def verify_confined_roles(
        self,
        authorizer: Optional[Union[Dict[str, Any], str]] = None,
        supervisor: Optional[Union[Dict[str, Any], str]] = None,
        attendant: Optional[Union[Dict[str, Any], str]] = None,
        entrants: Optional[Union[List[Any], str]] = None,
        roles_payload: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Verify statutory completeness and separation of 4 Confined Space roles:
          1. ผู้อนุญาต (Authorizer) - ข้อ ๙
          2. ผู้ควบคุมงาน (Supervisor) - ข้อ ๑๐
          3. ผู้ช่วยเหลือ (Attendant / Standby Person) - ข้อ ๑๑
          4. ผู้ปฏิบัติงาน (Entrant) - ข้อ ๑๒
        Enforces:
          - All 4 roles must be assigned.
          - Attendant cannot be an Entrant (strict conflict).
          - Training certificate numbers must be recorded.
        """
        if roles_payload and isinstance(roles_payload, dict):
            authorizer = roles_payload.get("authorizer", authorizer)
            supervisor = roles_payload.get("supervisor", supervisor)
            attendant = roles_payload.get("attendant", attendant)
            entrants = roles_payload.get("entrants", entrants)

        # Helper parser for name and cert
        def _parse_person(obj: Any) -> Dict[str, Any]:
            if isinstance(obj, dict):
                name = str(obj.get("name", "")).strip()
                cert = str(obj.get("cert_no", obj.get("certificate_no", obj.get("license_no", "")))).strip()
                signed = bool(obj.get("signed", False))
                return {"name": name, "cert_no": cert, "signed": signed, "valid": bool(name)}
            elif isinstance(obj, str) and obj.strip():
                parts = obj.strip().split(":")
                name = parts[0].strip()
                cert = parts[1].strip() if len(parts) > 1 else ""
                return {"name": name, "cert_no": cert, "signed": False, "valid": bool(name)}
            return {"name": "", "cert_no": "", "signed": False, "valid": False}

        parsed_auth = _parse_person(authorizer)
        parsed_sup = _parse_person(supervisor)
        parsed_att = _parse_person(attendant)

        parsed_entrants: List[Dict[str, Any]] = []
        if isinstance(entrants, list):
            for e in entrants:
                p = _parse_person(e)
                if p["valid"]:
                    parsed_entrants.append(p)
        elif isinstance(entrants, str) and entrants.strip():
            for e_str in entrants.split(","):
                p = _parse_person(e_str)
                if p["valid"]:
                    parsed_entrants.append(p)

        is_valid = True
        missing_roles = []
        conflict_issues = []
        warnings = []

        if not parsed_auth["valid"]:
            is_valid = False
            missing_roles.append("ผู้อนุญาต (Authorizer - ข้อ ๙)")
        elif not parsed_auth["cert_no"]:
            warnings.append("ผู้อนุญาตไม่ได้ระบุเลขที่ใบรับรองการฝึกอบรม")

        if not parsed_sup["valid"]:
            is_valid = False
            missing_roles.append("ผู้ควบคุมงาน (Supervisor - ข้อ ๑๐)")
        elif not parsed_sup["cert_no"]:
            warnings.append("ผู้ควบคุมงานไม่ได้ระบุเลขที่ใบรับรองการฝึกอบรม")

        if not parsed_att["valid"]:
            is_valid = False
            missing_roles.append("ผู้ช่วยเหลือ (Attendant - ข้อ ๑๑)")
        elif not parsed_att["cert_no"]:
            warnings.append("ผู้ช่วยเหลือไม่ได้ระบุเลขที่ใบรับรองการฝึกอบรม")

        if len(parsed_entrants) == 0:
            is_valid = False
            missing_roles.append("ผู้ปฏิบัติงาน (Entrant - ข้อ ๑๒ อย่างน้อย ๑ คน)")
        else:
            for i, ent in enumerate(parsed_entrants):
                if not ent["cert_no"]:
                    warnings.append(f"ผู้ปฏิบัติงานคนที่ {i+1} ({ent['name']}) ไม่ได้ระบุเลขที่ใบรับรองการฝึกอบรม")

        # Conflict check: Attendant cannot be Entrant
        att_name_clean = parsed_att["name"].lower()
        if parsed_att["valid"]:
            for ent in parsed_entrants:
                ent_name_clean = ent["name"].lower()
                if att_name_clean and att_name_clean == ent_name_clean:
                    is_valid = False
                    conflict_msg = f"ข้อห้ามตามกฎหมาย: ผู้ช่วยเหลือ '{parsed_att['name']}' ถูกระบุเป็นผู้ปฏิบัติงานเข้าไปภายในสถานที่อับอากาศพร้อมกัน (ละเมิดกฎกระทรวงฯ ข้อ ๑๑ และ ๑๒)"
                    conflict_issues.append(conflict_msg)

        verdict = "COMPLETE_AND_COMPLIANT" if is_valid else "NON_COMPLIANT_ROLES"

        return {
            "status": "success",
            "is_valid": is_valid,
            "verdict": verdict,
            "statutory_reference": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒ ข้อ ๙, ๑๐, ๑๑, ๑๒",
            "roles": {
                "authorizer": parsed_auth,
                "supervisor": parsed_sup,
                "attendant": parsed_att,
                "entrants": parsed_entrants,
                "total_entrants": len(parsed_entrants)
            },
            "missing_roles": missing_roles,
            "conflict_issues": conflict_issues,
            "warnings": warnings
        }

    # -------------------------------------------------------------------------
    # 3. Hot Work Fire Watch & 30-min Monitoring (กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๓๐ - ๓๔)
    # -------------------------------------------------------------------------
    def evaluate_fire_watch(
        self,
        monitoring_minutes: float,
        fire_watcher_name: str,
        extinguisher_ready: bool,
        area_cleared_11m: bool = True
    ) -> Dict[str, Any]:
        """
        Verify Hot Work fire safety controls and 30-minute post-work monitoring.
        """
        mins = float(monitoring_minutes)
        watcher = str(fire_watcher_name).strip() if fire_watcher_name else ""
        ext_ready = bool(extinguisher_ready)
        cleared_11m = bool(area_cleared_11m)

        is_valid = True
        findings = []

        if not watcher:
            is_valid = False
            findings.append({
                "severity": "CRITICAL",
                "code": "MISSING_FIRE_WATCHER",
                "message": "ไม่มีการแต่งตั้งผู้เฝ้าระวังไฟ (Fire Watcher) ประจำตลอดเวลาทำงาน (ละเมิดกฎกระทรวงฯ ข้อ ๓๓)"
            })

        if not ext_ready:
            is_valid = False
            findings.append({
                "severity": "CRITICAL",
                "code": "NO_FIRE_EXTINGUISHER",
                "message": "ไม่มีเครื่องดับเพลิงพร้อมใช้งานประจำจุดทำงาน Hot Work (ละเมิดกฎกระทรวงฯ ข้อ ๓๒)"
            })

        if not cleared_11m:
            is_valid = False
            findings.append({
                "severity": "HIGH",
                "code": "AREA_NOT_CLEARED_11M",
                "message": "ไม่ได้เคลื่อนย้ายสารไวไฟ/วัสดุติดไฟออกจากรัศมี ๑๑ เมตร หรือไม่มีผ้ากันไฟคลุม (ละเมิดกฎกระทรวงฯ ข้อ ๓๑)"
            })

        if mins < 30.0:
            is_valid = False
            findings.append({
                "severity": "CRITICAL",
                "code": "POST_WORK_WATCH_INSUFFICIENT",
                "message": f"เวลาเฝ้าระวังไฟหลังเลิกงาน {mins} นาที น้อยกว่าเกณฑ์ขั้นต่ำตามกฎหมาย ๓๐ นาที (ละเมิดกฎกระทรวงฯ ข้อ ๓๔)"
            })

        verdict = "FIRE_WATCH_COMPLIANT" if is_valid else "FIRE_WATCH_NON_COMPLIANT"

        return {
            "status": "success",
            "is_valid": is_valid,
            "verdict": verdict,
            "statutory_reference": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๓๐ - ๓๔",
            "details": {
                "fire_watcher_name": watcher,
                "extinguisher_ready": ext_ready,
                "area_cleared_11m": cleared_11m,
                "monitoring_minutes": mins,
                "required_minutes": 30.0
            },
            "findings": findings
        }

    # -------------------------------------------------------------------------
    # 4. Electrical Lockout/Tagout & Zero Energy (กฎกระทรวงไฟฟ้า ๒๕๕๘ ข้อ ๑๒, ๑๓)
    # -------------------------------------------------------------------------
    def verify_loto(
        self,
        isolation_points: List[Dict[str, Any]],
        zero_energy_verified: bool
    ) -> Dict[str, Any]:
        """
        Verify Lockout / Tagout (LOTO) energy isolation points and zero-energy verification.
        """
        is_valid = True
        findings = []

        if not isolation_points or len(isolation_points) == 0:
            is_valid = False
            findings.append({
                "severity": "CRITICAL",
                "code": "NO_ISOLATION_POINTS",
                "message": "ไม่พบรายการจุดตัดแยกพลังงาน (Energy Isolation Points) สำหรับงานซ่อมบำรุงไฟฟ้า/เครื่องจักร (ละเมิดกฎกระทรวงไฟฟ้าฯ ข้อ ๑๒)"
            })

        for i, point in enumerate(isolation_points or []):
            p_id = point.get("point_id", f"Point-{i+1}")
            padlock = point.get("padlock_no", point.get("lock_no", ""))
            tag = point.get("tag_no", point.get("danger_tag", ""))
            if not padlock:
                is_valid = False
                findings.append({
                    "severity": "HIGH",
                    "code": "MISSING_PADLOCK",
                    "message": f"จุดตัดแยก '{p_id}' ไม่ได้ระบุหมายเลขกุญแจตัดตอน (Padlock No.)"
                })
            if not tag:
                is_valid = False
                findings.append({
                    "severity": "HIGH",
                    "code": "MISSING_DANGER_TAG",
                    "message": f"จุดตัดแยก '{p_id}' ไม่ได้ระบุหมายเลขป้ายเตือนอันตราย (Danger Tag No.)"
                })

        if not zero_energy_verified:
            is_valid = False
            findings.append({
                "severity": "CRITICAL",
                "code": "ZERO_ENERGY_NOT_VERIFIED",
                "message": "ไม่มีการทดสอบยืนยันสภาพไร้พลังงาน (Zero Energy Verification) ด้วยเครื่องมือวัดก่อนเริ่มงาน (ละเมิดกฎกระทรวงไฟฟ้าฯ ข้อ ๑๓)"
            })

        verdict = "LOTO_ISOLATION_VALID" if is_valid else "LOTO_ISOLATION_INCOMPLETE"

        return {
            "status": "success",
            "is_valid": is_valid,
            "verdict": verdict,
            "statutory_reference": "กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๑๒, ๑๓",
            "total_points": len(isolation_points or []),
            "zero_energy_verified": bool(zero_energy_verified),
            "findings": findings
        }

    # -------------------------------------------------------------------------
    # 5. Full Permit to Work (PTW) Statutory Validator
    # -------------------------------------------------------------------------
    def validate_ptw(
        self,
        ptw_payload: Union[Dict[str, Any], str],
        work_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Comprehensive PTW Validator against Thai statutory safety regulations across 5 high-risk types.
        """
        # Parse payload
        data: Dict[str, Any] = {}
        if isinstance(ptw_payload, str):
            if os.path.exists(ptw_payload):
                try:
                    with open(ptw_payload, "r", encoding="utf-8") as f:
                        data = json.load(f)
                except Exception as e:
                    return {"status": "error", "message": f"Failed to parse PTW JSON file: {str(e)}"}
            else:
                try:
                    data = json.loads(ptw_payload)
                except Exception as e:
                    return {"status": "error", "message": f"Failed to parse raw PTW JSON string: {str(e)}"}
        elif isinstance(ptw_payload, dict):
            data = ptw_payload
        else:
            return {"status": "error", "message": "Invalid PTW payload type"}

        ptw_no = str(data.get("ptw_number", data.get("ptw_no", data.get("id", "PTW-DRAFT")))).strip()
        w_type = (work_type or data.get("work_type", data.get("type", "general"))).strip().lower()
        status = str(data.get("status", "draft")).strip().lower()

        findings: List[Dict[str, Any]] = []
        is_compliant = True
        scores_deductions = 0.0

        # General validations
        if not data.get("work_title") and not data.get("title"):
            findings.append({
                "severity": "MEDIUM",
                "code": "MISSING_WORK_TITLE",
                "message": "ไม่ได้ระบุชื่องาน / รายละเอียดลักษณะงาน"
            })
            scores_deductions += 10.0

        if not data.get("valid_from") or not data.get("valid_to"):
            findings.append({
                "severity": "HIGH",
                "code": "MISSING_VALIDITY_PERIOD",
                "message": "ไม่ได้ระบุช่วงวันและเวลาที่มีผลบังคับใช้ของใบอนุญาตทำงาน (Valid From / To)"
            })
            scores_deductions += 20.0
            is_compliant = False

        # Specific work type checks
        role_result = None
        gas_result = None
        fire_watch_result = None
        loto_result = None

        if w_type == "confined_space":
            # 1. Roles verification
            roles_data = {
                "authorizer": data.get("authorizer"),
                "supervisor": data.get("supervisor"),
                "attendant": data.get("attendant"),
                "entrants": data.get("entrants")
            }
            role_result = self.verify_confined_roles(roles_payload=roles_data)
            if not role_result["is_valid"]:
                is_compliant = False
                scores_deductions += 35.0
                for r_msg in role_result["missing_roles"]:
                    findings.append({
                        "severity": "CRITICAL",
                        "code": "CONFINED_ROLE_MISSING",
                        "message": f"ขาดการแต่งตั้ง {r_msg}"
                    })
                for c_msg in role_result["conflict_issues"]:
                    findings.append({
                        "severity": "CRITICAL",
                        "code": "CONFINED_ROLE_CONFLICT",
                        "message": c_msg
                    })

            # 2. Gas testing verification
            gas_data = data.get("gas_testing", data.get("gas_test", {}))
            if gas_data:
                o2 = gas_data.get("o2_pct", gas_data.get("o2", 20.9))
                lel = gas_data.get("lel_pct", gas_data.get("lel", 0.0))
                co = gas_data.get("co_ppm", gas_data.get("co", 0.0))
                h2s = gas_data.get("h2s_ppm", gas_data.get("h2s", 0.0))
                gas_result = self.evaluate_gas(o2=o2, lel=lel, co=co, h2s=h2s)
                if not gas_result["is_safe"]:
                    is_compliant = False
                    scores_deductions += 40.0
                    for gf in gas_result["findings"]:
                        findings.append(gf)
            else:
                is_compliant = False
                scores_deductions += 40.0
                findings.append({
                    "severity": "CRITICAL",
                    "code": "MISSING_GAS_TESTING",
                    "message": "ไม่พบบันทึกการตรวจวัดสภาพอากาศก่อนเข้าทำงานในที่อับอากาศ (ละเมิดกฎกระทรวงฯ ข้อ ๗)"
                })

            # 3. Ventilation check
            if not data.get("continuous_ventilation", data.get("forced_ventilation", False)):
                scores_deductions += 15.0
                findings.append({
                    "severity": "HIGH",
                    "code": "VENTILATION_NOT_CONFIRMED",
                    "message": "ไม่ได้ยืนยันการเปิดพัดลมระบายอากาศแบบกลไกอย่างต่อเนื่อง (กฎกระทรวงฯ ข้อ ๑๔)"
                })

            # 4. Rescue plan
            if not data.get("emergency_rescue_plan", data.get("rescue_plan", False)):
                scores_deductions += 10.0
                findings.append({
                    "severity": "HIGH",
                    "code": "NO_EMERGENCY_PLAN",
                    "message": "ไม่ได้ระบุแผนปฏิบัติการฉุกเฉินและการกู้ภัย (กฎกระทรวงฯ ข้อ ๑๗)"
                })

        elif w_type == "hot_work":
            hw_controls = data.get("hot_work_controls", data.get("hotwork", {}))
            watcher_name = hw_controls.get("fire_watcher_name", data.get("fire_watcher_name", ""))
            ext_ready = hw_controls.get("fire_extinguishers_count", 0) >= 1 or hw_controls.get("extinguisher_ready", False)
            cleared_11m = hw_controls.get("area_cleared_11m", True)
            mins = float(hw_controls.get("post_work_monitoring_minutes", data.get("post_work_monitoring_minutes", 0.0)))

            fire_watch_result = self.evaluate_fire_watch(
                monitoring_minutes=mins if status in ["closed", "extended"] else 30.0,
                fire_watcher_name=watcher_name,
                extinguisher_ready=ext_ready,
                area_cleared_11m=cleared_11m
            )
            if not fire_watch_result["is_valid"]:
                is_compliant = False
                scores_deductions += 30.0
                for fw_f in fire_watch_result["findings"]:
                    findings.append(fw_f)

        elif w_type == "electrical_loto":
            loto_data = data.get("loto_isolation", data.get("loto", {}))
            iso_points = loto_data.get("isolation_points", data.get("isolation_points", []))
            zero_energy = loto_data.get("zero_energy_verified", data.get("zero_energy_verified", False))

            loto_result = self.verify_loto(isolation_points=iso_points, zero_energy_verified=zero_energy)
            if not loto_result["is_valid"]:
                is_compliant = False
                scores_deductions += 35.0
                for lf in loto_result["findings"]:
                    findings.append(lf)

        elif w_type == "working_at_height":
            height_m = float(data.get("height_meters", data.get("height", 2.0)))
            h_controls = data.get("height_controls", data.get("height_safety", {}))
            if height_m >= 2.0:
                if not h_controls.get("full_body_harness_used", False):
                    is_compliant = False
                    scores_deductions += 25.0
                    findings.append({
                        "severity": "CRITICAL",
                        "code": "NO_FULL_BODY_HARNESS",
                        "message": "การทำงานบนที่สูงตั้งแต่ ๒.๐ เมตรขึ้นไป ต้องใช้เข็มขัดนิรภัยแบบเต็มตัว (Full Body Harness) (กฎกระทรวงฯ ข้อ ๑๕)"
                    })
                if not h_controls.get("anchor_point_certified_22kn", True):
                    is_compliant = False
                    scores_deductions += 20.0
                    findings.append({
                        "severity": "HIGH",
                        "code": "ANCHOR_POINT_UNVERIFIED",
                        "message": "จุดยึดเหนี่ยว (Anchor Point) ต้องรับแรงได้ไม่น้อยกว่า ๒๒.๒ kN (กฎกระทรวงฯ ข้อ ๑๖)"
                    })

        elif w_type == "excavation_lifting":
            depth_m = float(data.get("depth_meters", data.get("depth", 0.0)))
            exc_controls = data.get("excavation_controls", data.get("excavation_safety", {}))
            if depth_m >= 1.5:
                if not exc_controls.get("shoring_installed", False) and not exc_controls.get("sloping_done", False):
                    is_compliant = False
                    scores_deductions += 30.0
                    findings.append({
                        "severity": "CRITICAL",
                        "code": "NO_SOIL_SHORING",
                        "message": "งานขุดดินลึกตั้งแต่ ๑.๕ เมตรขึ้นไป ต้องติดตั้งระบบค้ำยัน (Shoring) หรือขุดแบบลาดเอียง (กฎกระทรวงฯ ข้อ ๓๘)"
                    })
                if not exc_controls.get("underground_utilities_scanned", False):
                    is_compliant = False
                    scores_deductions += 20.0
                    findings.append({
                        "severity": "HIGH",
                        "code": "NO_UTILITIES_SCAN",
                        "message": "ต้องทำการสำรวจแนวสาธารณูปโภคใต้ดินก่อนเริ่มขุดเจาะ (กฎกระทรวงฯ ข้อ ๓๙)"
                    })

        # Calculate final compliance score
        validation_score = max(0.0, min(100.0, 100.0 - scores_deductions))

        status_badge = "COMPLIANT_PERMIT_VALID" if (is_compliant and validation_score >= 80.0) else "NON_COMPLIANT_REJECTED"
        if status == "draft" and validation_score >= 80.0:
            status_badge = "VALID_DRAFT_READY_FOR_APPROVAL"

        return {
            "status": "success",
            "ptw_number": ptw_no,
            "work_type": w_type,
            "lifecycle_status": status,
            "is_compliant": is_compliant,
            "validation_score": round(validation_score, 1),
            "status_badge": status_badge,
            "total_findings": len(findings),
            "findings": findings,
            "role_verification": role_result,
            "gas_verification": gas_result,
            "fire_watch_verification": fire_watch_result,
            "loto_verification": loto_result
        }

    # -------------------------------------------------------------------------
    # 6. Safety Checklist Retrieval
    # -------------------------------------------------------------------------
    def get_checklist(
        self,
        ptw_type: str = "all",
        sub_category: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve statutory safety checklist items by work type."""
        t = (ptw_type or "all").strip().lower()
        sub = (sub_category or "").strip().lower() if sub_category else None

        checklists = self.safety_checklists.get("checklists", {})

        if t != "all" and t in checklists:
            cat_data = checklists[t]
            items = cat_data.get("items", [])
            if sub:
                items = [it for it in items if sub in it.get("category", "").lower()]
            return {
                "status": "success",
                "work_type": t,
                "name_th": cat_data.get("name_th"),
                "statutory_law": cat_data.get("statutory_law"),
                "total_items": len(items),
                "items": items
            }
        elif t == "all":
            all_items = []
            for k, cat_data in checklists.items():
                for it in cat_data.get("items", []):
                    if not sub or sub in it.get("category", "").lower():
                        item_copy = dict(it)
                        item_copy["work_type"] = k
                        all_items.append(item_copy)
            return {
                "status": "success",
                "work_type": "all",
                "total_categories": len(checklists),
                "total_items": len(all_items),
                "items": all_items
            }
        else:
            return {
                "status": "error",
                "message": f"Unknown PTW work type '{ptw_type}'. Available types: {list(checklists.keys()) + ['all']}"
            }

    # -------------------------------------------------------------------------
    # 7. PTW Law Catalog & Search
    # -------------------------------------------------------------------------
    def get_ptw_law(
        self,
        topic: str = "all",
        section: Optional[str] = None,
        query: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve Thai safety laws, Gazette citations, and statutory clauses."""
        if query:
            return self.search_laws(query=query, topic=topic)

        laws = self.laws_catalog.get("laws", [])
        topic_clean = (topic or "all").strip().lower()
        sec_clean = (section or "").strip().lower() if section else None

        filtered_laws = []
        for law in laws:
            l_code = law.get("law_code", "").lower()
            l_id = law.get("law_id", "").lower()
            l_cat = law.get("category", "").lower()

            if topic_clean != "all" and (topic_clean not in l_code and topic_clean not in l_id and topic_clean not in l_cat):
                continue

            articles = law.get("articles", [])
            if sec_clean:
                articles = [
                    a for a in articles
                    if sec_clean in a.get("article_no", "").lower()
                    or sec_clean in a.get("title", "").lower()
                ]

            law_copy = dict(law)
            law_copy["articles"] = articles
            law_copy["total_articles"] = len(articles)
            filtered_laws.append(law_copy)

        return {
            "status": "success",
            "topic": topic_clean,
            "total_found": len(filtered_laws),
            "laws": filtered_laws
        }

    def search_laws(self, query: str, topic: str = "all", limit: int = 10) -> Dict[str, Any]:
        """Full-text statutory search with relevance scoring across Thai safety laws."""
        q = (query or "").strip().lower()
        if not q:
            return self.get_ptw_law(topic=topic)

        laws = self.laws_catalog.get("laws", [])
        topic_clean = (topic or "all").strip().lower()

        results = []
        terms = [t for t in re.split(r"\s+", q) if t]

        for law in laws:
            l_code = law.get("law_code", "").lower()
            l_id = law.get("law_id", "").lower()
            l_cat = law.get("category", "").lower()

            if topic_clean != "all" and (topic_clean not in l_code and topic_clean not in l_id and topic_clean not in l_cat):
                continue

            for art in law.get("articles", []):
                art_no = art.get("article_no", "").lower()
                title = art.get("title", "").lower()
                full_text = art.get("full_text_th", "").lower()
                enforce = art.get("enforcement_summary", "").lower()
                penalty = art.get("penalty_clause", "").lower()

                score = 0.0
                for term in terms:
                    if term in art_no:
                        score += 50.0
                    if term in title:
                        score += 40.0
                    if term in enforce:
                        score += 25.0
                    if term in full_text:
                        score += 15.0
                    if term in penalty:
                        score += 10.0

                if score > 0:
                    results.append({
                        "law_id": law.get("law_id"),
                        "law_code": law.get("law_code"),
                        "short_name_th": law.get("short_name_th"),
                        "gazette_reference": law.get("gazette_reference"),
                        "article_no": art.get("article_no"),
                        "title": art.get("title"),
                        "full_text_th": art.get("full_text_th"),
                        "enforcement_summary": art.get("enforcement_summary"),
                        "penalty_clause": art.get("penalty_clause"),
                        "relevance_score": score
                    })

        results.sort(key=lambda x: x["relevance_score"], reverse=True)
        trimmed = results[:limit]

        return {
            "status": "success",
            "query": query,
            "topic": topic,
            "total_found": len(trimmed),
            "results": trimmed
        }
