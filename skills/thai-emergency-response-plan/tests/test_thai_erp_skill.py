import unittest
import os
import sys
import json

# Add scripts directory to path
current_dir = os.path.dirname(__file__)
scripts_dir = os.path.abspath(os.path.join(current_dir, '..', 'scripts'))
sys.path.insert(0, scripts_dir)

from thai_erp_engine import ThaiErpEngine

class TestThaiErpSkill(unittest.TestCase):
    def setUp(self):
        self.engine = ThaiErpEngine()

    def test_calc_training_quota(self):
        # 100 employees, 40% = 40 required
        res = self.engine.calc_training_quota(100, 40)
        self.assertEqual(res['required_quota'], 40)
        self.assertTrue(res['is_compliant'])
        self.assertEqual(res['shortfall'], 0)

        # 125 employees, 40 trained -> 50 required -> shortfall 10
        res2 = self.engine.calc_training_quota(125, 40)
        self.assertEqual(res2['required_quota'], 50)
        self.assertFalse(res2['is_compliant'])
        self.assertEqual(res2['shortfall'], 10)

    def test_calc_extinguishers(self):
        # Medium hazard 1000 sqm -> 10 units
        res_med = self.engine.calc_extinguishers(1000, 'MEDIUM')
        self.assertEqual(res_med['recommended_units'], 10)
        self.assertEqual(res_med['max_travel_distance_meters'], 20.0)
        self.assertEqual(res_med['max_installation_height_meters'], 1.50)

        # High hazard 1000 sqm -> ceil(1000/70) = 15 units
        res_high = self.engine.calc_extinguishers(1000, 'HIGH')
        self.assertEqual(res_high['recommended_units'], 15)
        self.assertEqual(res_high['max_travel_distance_meters'], 15.0)

    def test_audit_drill_compliant(self):
        drill = {
            "drill_title": "ซ้อมดับเพลิงประจำปี",
            "drill_date": "2025-11-01",
            "organizer_type": "CERTIFIED_BODY",
            "total_workers_on_site": 100,
            "participated_count": 98,
            "evacuation_time_sec": 180,
            "spr4_submission_status": "PENDING"
        }
        res = self.engine.audit_drill(drill, current_date="2025-11-15")
        self.assertTrue(res['is_compliant'])
        self.assertFalse(res['is_overdue'])
        self.assertGreaterEqual(res['days_remaining_to_submit'], 15)

    def test_audit_drill_overdue(self):
        drill = {
            "drill_title": "ซ้อมดับเพลิงที่ส่งรายงานล่าช้า",
            "drill_date": "2025-01-01",
            "organizer_type": "CERTIFIED_BODY",
            "total_workers_on_site": 100,
            "participated_count": 95,
            "evacuation_time_sec": 180,
            "spr4_submission_status": "PENDING"
        }
        res = self.engine.audit_drill(drill, current_date="2025-02-15") # 45 days later
        self.assertTrue(res['is_overdue'])
        self.assertFalse(res['is_compliant'])

    def test_validate_plan(self):
        complete_plan = {
            "plan_title": "แผนป้องกันระงับอัคคีภัย",
            "fire_commander_name": "นายสมศักดิ์ มั่นคง",
            "inspection_plan": {"items": [{"category": "ถังดับเพลิง"}]},
            "training_plan": {"courses": [{"courseName": "ดับเพลิงขั้นต้น"}]},
            "campaign_plan": {"activities": ["กิจกรรม 5ส"]},
            "suppression_plan": {"regular_shift_team": [{"roleTitle": "ทีมดับเพลิง"}]},
            "evacuation_plan": {"assembly_points": [{"pointName": "จุดรวมพล 1"}]},
            "relief_plan": {"government_contacts": [{"agencyName": "199"}]}
        }
        res = self.engine.validate_plan(complete_plan, 'FIRE')
        self.assertTrue(res['is_fully_compliant'])
        self.assertEqual(res['completeness_score'], 100)

    def test_get_emergency_law(self):
        laws = self.engine.get_emergency_law("ข้อ ๔")
        self.assertGreaterEqual(len(laws), 1)

    def test_list_presets(self):
        presets = self.engine.list_presets()
        self.assertIn("FIRE_FACTORY", presets)
        self.assertIn("CHEMICAL_HAZMAT", presets)
        self.assertIn("ELECTRICAL_SAFETY", presets)

    def test_audit_electrical_inspection(self):
        today = "2025-06-01"
        valid_inspection = {
            "inspection_date": "2025-05-15",
            "inspector_name": "นายวิศวะ ไฟฟ้า",
            "inspector_license_no": "กว. 12345",
            "grounding_resistance_ohm": 3.5,
            "vendor_report_pdf_path": "report.pdf",
            "thermoscan_report_path": "thermo.pdf"
        }
        res = self.engine.audit_electrical_inspection(valid_inspection, current_date=today)
        self.assertTrue(res['is_fully_compliant'])
        self.assertTrue(res['is_grounding_pass'])
        self.assertFalse(res['is_overdue'])
        self.assertEqual(res['sla_status'], 'COMPLIANT')

        # Overdue inspection
        overdue_inspection = {
            "inspection_date": "2023-01-01",
            "expiry_date": "2024-01-01",
            "inspector_name": "นายวิศวะ",
            "inspector_license_no": "123",
            "vendor_report_pdf_path": "old.pdf"
        }
        res_od = self.engine.audit_electrical_inspection(overdue_inspection, current_date=today)
        self.assertTrue(res_od['is_overdue'])
        self.assertEqual(res_od['sla_status'], 'OVERDUE')
        self.assertFalse(res_od['is_fully_compliant'])

        # Grounding failure (> 5 ohm)
        fail_grounding = {
            "inspection_date": "2025-05-15",
            "inspector_name": "นายวิศวะ",
            "inspector_license_no": "123",
            "grounding_resistance_ohm": 7.8,
            "vendor_report_pdf_path": "report.pdf"
        }
        res_g = self.engine.audit_electrical_inspection(fail_grounding, current_date=today)
        self.assertFalse(res_g['is_grounding_pass'])
        self.assertFalse(res_g['is_fully_compliant'])

    def test_electrical_law_lookup(self):
        laws = self.engine.get_emergency_law("แบบ ๕๖๒๘๙")
        self.assertGreaterEqual(len(laws), 1)
        self.assertEqual(laws[0]['id'], 'ELECTRICAL_REG_2558')

if __name__ == '__main__':
    unittest.main()
