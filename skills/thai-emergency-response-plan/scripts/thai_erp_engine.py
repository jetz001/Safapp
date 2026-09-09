import math
import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

class ThaiErpEngine:
    def __init__(self, data_dir: Optional[str] = None):
        if data_dir is None:
            data_dir = os.path.join(os.path.dirname(__file__), 'data')
        self.data_dir = data_dir
        self.laws_data = self._load_json('emergency_laws.json')
        self.templates_data = self._load_json('erp_templates.json')

    def _load_json(self, filename: str) -> Dict[str, Any]:
        path = os.path.join(self.data_dir, filename)
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}

    def calc_training_quota(self, total_employees: int, currently_trained: int, statutory_percent: float = 40.0) -> Dict[str, Any]:
        """
        คำนวณโควตาการฝึกอบรมดับเพลิงขั้นต้นตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๒๗
        (นายจ้างต้องจัดให้ลูกจ้างไม่น้อยกว่าร้อยละ ๔๐ ของจำนวนลูกจ้างในแต่ละแผนกรับการฝึกอบรม)
        """
        if total_employees <= 0:
            return {
                "total_employees": 0,
                "statutory_percent": statutory_percent,
                "required_quota": 0,
                "currently_trained": currently_trained,
                "shortfall": 0,
                "current_percent": 0.0,
                "is_compliant": True,
                "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๒๗",
                "message": "ไม่มีจำนวนพนักงานให้คำนวณ"
            }

        required_quota = math.ceil(total_employees * (statutory_percent / 100.0))
        shortfall = max(0, required_quota - currently_trained)
        current_percent = (currently_trained / total_employees) * 100.0
        is_compliant = currently_trained >= required_quota

        return {
            "total_employees": total_employees,
            "statutory_percent": statutory_percent,
            "required_quota": required_quota,
            "currently_trained": currently_trained,
            "shortfall": shortfall,
            "current_percent": round(current_percent, 2),
            "is_compliant": is_compliant,
            "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๒๗ (ไม่น้อยกว่าร้อยละ ๔๐)",
            "message": "ผ่านเกณฑ์ตามกฎหมาย" if is_compliant else f"ต่ำกว่าเกณฑ์: ขาดอีก {shortfall} คน เพื่อให้ครบ {statutory_percent}% ({required_quota} คน)"
        }

    def calc_extinguishers(self, area_sqm: float, hazard_level: str = 'MEDIUM') -> Dict[str, Any]:
        """
        คำนวณจำนวนเครื่องดับเพลิงและระยะติดตั้งตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๑๑
        """
        level = hazard_level.upper()
        if level == 'LIGHT':
            sqm_per_unit = 150.0
            max_travel_dist = 20.0
            min_rating = '1-A / 5-B'
            desc = 'ความเสี่ยงต่ำ/อันตรายน้อย (อาคารสำนักงาน โรงแรม ที่พักอาศัย)'
        elif level == 'HIGH':
            sqm_per_unit = 70.0
            max_travel_dist = 15.0
            min_rating = '4-A / 40-B'
            desc = 'ความเสี่ยงสูง/อันตรายมาก (คลังสารเคมี โรงงานแปรรูปไม้ ปิโตรเลียม)'
        else: # MEDIUM
            sqm_per_unit = 100.0
            max_travel_dist = 20.0
            min_rating = '2-A / 10-B'
            desc = 'ความเสี่ยงปานกลาง/อันตรายปานกลาง (โรงงานอุตสาหกรรมทั่วไป คลังสินค้า)'

        units = max(1, math.ceil(area_sqm / sqm_per_unit))

        return {
            "area_sqm": area_sqm,
            "hazard_level": level,
            "hazard_description": desc,
            "recommended_units": units,
            "sqm_coverage_per_unit": sqm_per_unit,
            "max_travel_distance_meters": max_travel_dist,
            "max_installation_height_meters": 1.50,
            "min_fire_rating": min_rating,
            "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๑๑ & ประกาศกรมสวัสดิการฯ",
            "rule_summary": f"ติดตั้ง ๑ เครื่อง ต่อพื้นที่ไม่เกิน {sqm_per_unit} ตร.ม. ระยะเดินเข้าถึงไม่เกิน {max_travel_dist} ม. และส่วนบนสุดสูงจากพื้นไม่เกิน ๑.๕๐ ม."
        }

    def audit_drill(self, drill: Dict[str, Any], current_date: Optional[str] = None) -> Dict[str, Any]:
        """
        ตรวจสอบความถูกต้องของการฝึกซ้อมและกำหนดเวลายื่นแบบ สปร. ๔ (ตามข้อ ๓๐)
        """
        now = datetime.strptime(current_date, '%Y-%m-%d') if current_date else datetime.now()
        issues = []
        recommendations = []

        drill_date_str = drill.get('drill_date', '')
        try:
            drill_date = datetime.strptime(drill_date_str, '%Y-%m-%d')
            deadline = drill_date + timedelta(days=30)
            days_remaining = (deadline - datetime(now.year, now.month, now.day)).days
            is_overdue = days_remaining < 0 and drill.get('spr4_submission_status') != 'SUBMITTED'
        except Exception:
            deadline = None
            days_remaining = 0
            is_overdue = False
            issues.append('รูปแบบวันที่ฝึกซ้อมไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)')

        organizer_type = drill.get('organizer_type', 'SELF_APPROVED')
        approval_cert = drill.get('approval_cert_no', '').strip()
        if organizer_type == 'SELF_APPROVED' and not approval_cert:
            issues.append('กรณีนายจ้างจัดฝึกซ้อมเอง ต้องยื่นขอความเห็นชอบล่วงหน้าอย่างน้อย ๓๐ วัน และระบุเลขที่หนังสือเห็นชอบ (ข้อ ๓๐ วรรคสอง)')

        total_workers = drill.get('total_workers_on_site', 0)
        participated = drill.get('participated_count', 0)
        rate = (participated / total_workers * 100.0) if total_workers > 0 else 100.0

        if rate < 90.0:
            recommendations.append(f'อัตราการเข้าร่วมฝึกซ้อม {rate:.1f}% ต่ำกว่าเกณฑ์เป้าหมาย ๙๐% ควรจัดอบรมย่อยทบทวนสำหรับผู้ที่ขาดการซ้อม')

        evac_time_sec = drill.get('evacuation_time_sec', 0)
        if evac_time_sec > 300:
            recommendations.append(f'เวลาอพยพ {evac_time_sec} วินาที เกินกว่าเกณฑ์แนะนำ ๕ นาที (๓๐๐ วินาที)')

        if is_overdue:
            issues.append(f'เกินกำหนดเวลายื่นแบบ สปร. ๔ ต่อพนักงานตรวจความปลอดภัยมาแล้ว {abs(days_remaining)} วัน (กฎหมายกำหนดภายใน ๓๐ วัน)')

        return {
            "drill_title": drill.get('drill_title', ''),
            "drill_date": drill_date_str,
            "submission_deadline": deadline.strftime('%Y-%m-%d') if deadline else '',
            "days_remaining_to_submit": days_remaining,
            "is_overdue": is_overdue,
            "participation_rate_percent": round(rate, 2),
            "is_compliant": len(issues) == 0,
            "issues": issues,
            "recommendations": recommendations,
            "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๓๐ & แบบ สปร. ๔"
        }

    def validate_plan(self, plan: Dict[str, Any], hazard_type: str = 'FIRE') -> Dict[str, Any]:
        """
        ตรวจสอบความครบถ้วนของเล่มแผนฉุกเฉิน ๖ เสาหลัก (กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๔)
        """
        missing_pillars = []
        score = 0

        # Pillar 1: Inspection
        p1 = plan.get('inspection_plan', {})
        items = p1.get('items', [])
        if items and len(items) > 0:
            score += 15
        else:
            missing_pillars.append('แผนการตรวจตรา (๑. ตรวจตรา): ไม่มีรายการจุดตรวจตราหรือความถี่')

        # Pillar 2: Training
        p2 = plan.get('training_plan', {})
        courses = p2.get('courses', [])
        if courses and len(courses) > 0:
            score += 15
        else:
            missing_pillars.append('แผนการอบรม (๒. อบรม): ไม่มีหลักสูตรอบรมดับเพลิงขั้นต้น')

        # Pillar 3: Campaign
        p3 = plan.get('campaign_plan', {})
        acts = p3.get('activities', [])
        if acts and len(acts) > 0:
            score += 10
        else:
            missing_pillars.append('แผนการรณรงค์ (๓. รณรงค์): ไม่มีกิจกรรมส่งเสริมความปลอดภัยหรือ 5ส')

        # Pillar 4: Suppression
        p4 = plan.get('suppression_plan', {})
        team = p4.get('regular_shift_team', [])
        commander = plan.get('fire_commander_name', '').strip()
        if team and len(team) > 0 and commander:
            score += 25
        else:
            missing_pillars.append('แผนการดับเพลิง (๔. ดับเพลิง): ขาดโครงสร้างทีมระงับเหตุหรือผู้อำนวยการสั่งการ')

        # Pillar 5: Evacuation
        p5 = plan.get('evacuation_plan', {})
        points = p5.get('assembly_points', [])
        if points and len(points) > 0:
            score += 20
        else:
            missing_pillars.append('แผนอพยพหนีไฟ (๕. อพยพ): ยังไม่ได้กำหนดจุดรวมพล (Assembly Point)')

        # Pillar 6: Relief
        p6 = plan.get('relief_plan', {})
        contacts = p6.get('government_contacts', [])
        if contacts and len(contacts) > 0:
            score += 15
        else:
            missing_pillars.append('แผนบรรเทาทุกข์ (๖. บรรเทาทุกข์): ขาดรายชื่อและเบอร์โทรติดต่อ 199/รพ./ตำรวจ')

        is_compliant = (score >= 80) and (len(missing_pillars) == 0)

        return {
            "plan_title": plan.get('plan_title', ''),
            "hazard_type": hazard_type.upper(),
            "completeness_score": score,
            "is_fully_compliant": is_compliant,
            "missing_pillars": missing_pillars,
            "statutory_reference": "กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๔ (๖ แผนย่อย)",
            "summary": "แผนมีความสมบูรณ์ตามเกณฑ์กฎหมายครบทั้ง ๖ เสาหลัก" if is_compliant else f"ยังขาดองค์ประกอบสำคัญ {len(missing_pillars)} ด้าน (คะแนน {score}/100)"
        }

    def get_emergency_law(self, query: str) -> List[Dict[str, Any]]:
        """
        ค้นหากฎหมายและประกาศกระทรวงแรงงานเกี่ยวกับอัคคีภัยและภาวะฉุกเฉิน
        """
        q = query.lower().strip()
        results = []
        for law in self.laws_data.get('laws', []):
            matched_sections = []
            for sec in law.get('sections', []):
                if q in sec.get('clause', '').lower() or q in sec.get('summary', '').lower():
                    matched_sections.append(sec)

            if matched_sections or q in law.get('title', '').lower() or q in law.get('gazette', '').lower():
                results.append({
                    "id": law.get('id'),
                    "title": law.get('title'),
                    "gazette": law.get('gazette'),
                    "matched_sections": matched_sections if matched_sections else law.get('sections', [])
                })
        return results

    def list_presets(self, hazard_type: Optional[str] = None) -> Dict[str, Any]:
        """
        แสดงรายการพรีเซ็ตมาตรฐานสำหรับแผนฉุกเฉิน
        """
        presets = self.templates_data.get('presets', {})
        if hazard_type and hazard_type.upper() != 'ALL':
            filtered = {k: v for k, v in presets.items() if v.get('hazard_type') == hazard_type.upper()}
            return filtered
        return presets

    def audit_electrical_inspection(self, inspection: Dict[str, Any], current_date: Optional[str] = None) -> Dict[str, Any]:
        """
        ตรวจสอบความสอดคล้องของการตรวจและรับรองระบบไฟฟ้าประจำปีตามกฎกระทรวงไฟฟ้า ๒๕๕๘ ข้อ ๑๒
        และแบบ ๕๖๒๘๙
        """
        inspection_date_str = inspection.get('inspection_date', '')
        expiry_date_str = inspection.get('expiry_date', '')
        inspector_name = inspection.get('inspector_name', '').strip()
        license_no = inspection.get('inspector_license_no', '').strip()
        grounding_ohm = inspection.get('grounding_resistance_ohm')
        vendor_pdf = inspection.get('vendor_report_pdf_path', '')
        thermoscan_pdf = inspection.get('thermoscan_report_path', '')

        issues = []
        is_compliant = True

        if not inspection_date_str:
            return {"error": "กรุณาระบุ inspection_date"}

        try:
            insp_date = datetime.strptime(inspection_date_str[:10], '%Y-%m-%d').date()
        except ValueError:
            return {"error": "รูปแบบวันที่ inspection_date ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)"}

        if expiry_date_str:
            try:
                exp_date = datetime.strptime(expiry_date_str[:10], '%Y-%m-%d').date()
            except ValueError:
                exp_date = insp_date + timedelta(days=365)
        else:
            exp_date = insp_date + timedelta(days=365)

        if current_date:
            try:
                today = datetime.strptime(current_date[:10], '%Y-%m-%d').date()
            except ValueError:
                today = datetime.now().date()
        else:
            today = datetime.now().date()

        days_remaining = (exp_date - today).days
        is_overdue = days_remaining < 0

        if is_overdue:
            is_compliant = False
            issues.append(f"เกินกำหนดการตรวจสอบประจำปี ๑ ครั้งมาแล้ว {abs(days_remaining)} วัน (ผิดกฎกระทรวงไฟฟ้าฯ ข้อ ๑๒)")
        elif days_remaining <= 60:
            issues.append(f"ใกล้ครบกำหนดต่ออายุการตรวจสอบ (เหลืออีก {days_remaining} วัน)")

        if not inspector_name or not license_no:
            is_compliant = False
            issues.append("ต้องมีชื่อวิศวกรผู้รับรองและเลขที่ใบอนุญาต กว./ม.๑๑")

        grounding_pass = True
        if grounding_ohm is not None:
            try:
                ohm_val = float(grounding_ohm)
                if ohm_val > 5.0:
                    grounding_pass = False
                    issues.append(f"ค่าความต้านทานดิน {ohm_val} โอห์ม เกินเกณฑ์มาตรฐานกฎหมาย/วสท. (ต้องไม่เกิน ๕.๐ โอห์ม)")
            except (ValueError, TypeError):
                pass

        has_vendor_report = bool(vendor_pdf and vendor_pdf.strip())
        has_thermoscan = bool(thermoscan_pdf and thermoscan_pdf.strip())

        if not has_vendor_report:
            issues.append("ยังไม่ได้แนบไฟล์เล่มรายงานผลการตรวจสอบ (แบบ ๕๖๒๘๙ / รายงาน ผรม.)")

        return {
            "inspection_date": insp_date.strftime('%Y-%m-%d'),
            "expiry_date": exp_date.strftime('%Y-%m-%d'),
            "days_remaining": days_remaining,
            "is_overdue": is_overdue,
            "sla_status": "OVERDUE" if is_overdue else ("WARNING" if days_remaining <= 60 else "COMPLIANT"),
            "inspector_name": inspector_name,
            "inspector_license_no": license_no,
            "grounding_resistance_ohm": grounding_ohm,
            "is_grounding_pass": grounding_pass,
            "has_vendor_report_attachment": has_vendor_report,
            "has_thermoscan_attachment": has_thermoscan,
            "is_fully_compliant": is_compliant and grounding_pass and has_vendor_report,
            "issues": issues,
            "statutory_reference": "กฎกระทรวงกำหนดมาตรฐานฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๑๒ (ตรวจรับรองปีละ ๑ ครั้ง ตามแบบ ๕๖๒๘๙)",
            "message": "ผ่านเกณฑ์ตามกฎหมายครบถ้วน" if (is_compliant and grounding_pass and has_vendor_report) else f"พบประเด็นที่ต้องดำเนินการ {len(issues)} รายการ"
        }
