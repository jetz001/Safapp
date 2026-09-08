"""
==============================================================================
 Comprehensive Unit & Integration Tests for thai-ptw-safety-law Agent Skill
 Conforming to 5 Thai Royal Gazette Safety Regulations:
   - OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
   - Ministerial Reg. Confined Space B.E. 2562 (กฎกระทรวงอับอากาศ ๒๕๖๒)
   - Ministerial Reg. Fire Safety B.E. 2555 (กฎกระทรวงอัคคีภัย ๒๕๕๕ - Hot Work)
   - Ministerial Reg. Electrical Safety B.E. 2558 (กฎกระทรวงไฟฟ้า ๒๕๕๘ - LOTO)
   - Ministerial Reg. Height & Excavation B.E. 2564 (กฎกระทรวงงานบนที่สูงและดินขุด ๒๕๖๔)
==============================================================================
"""

import os
import sys
import json
import unittest
import subprocess

# Setup path to import scripts
TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(TESTS_DIR)
SCRIPTS_DIR = os.path.join(SKILL_ROOT, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_ptw_engine import ThaiPtwEngine
from thai_ptw_helper import ThaiPtwHelper


class TestThaiPtwSafetyLawSkill(unittest.TestCase):
    """Test suite covering statutory engine, CLI commands, and dual-mode helper."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiPtwEngine(data_dir=DATA_DIR)
        cls.helper_direct = ThaiPtwHelper(skill_dir=SKILL_ROOT, prefer_direct=True)
        cls.helper_cli = ThaiPtwHelper(skill_dir=SKILL_ROOT, prefer_direct=False)

    # -------------------------------------------------------------------------
    # Test 1: Data Catalog Integrity
    # -------------------------------------------------------------------------
    def test_01_catalog_integrity(self):
        """Verify all 5 laws, gas standards, checklists, and sample PTWs are loaded properly."""
        self.assertEqual(len(self.engine.laws_catalog.get("laws", [])), 5)
        self.assertIn("oxygen", self.engine.gas_standards.get("parameters", {}))
        self.assertIn("combustible_gas", self.engine.gas_standards.get("parameters", {}))
        self.assertIn("carbon_monoxide", self.engine.gas_standards.get("parameters", {}))
        self.assertIn("hydrogen_sulfide", self.engine.gas_standards.get("parameters", {}))
        
        checklists = self.engine.safety_checklists.get("checklists", {})
        self.assertEqual(len(checklists), 5)
        self.assertIn("hot_work", checklists)
        self.assertIn("confined_space", checklists)
        self.assertIn("working_at_height", checklists)
        self.assertIn("electrical_loto", checklists)
        self.assertIn("excavation_lifting", checklists)

    # -------------------------------------------------------------------------
    # Test 2: Gas Evaluation - Normal Safe Atmospheric Readings
    # -------------------------------------------------------------------------
    def test_02_gas_evaluation_safe(self):
        """Verify normal atmospheric readings (O2=20.9%, LEL=0%, CO=2.0 ppm, H2S=0.0 ppm) pass."""
        res = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=2.0, h2s=0.0)
        self.assertTrue(res["is_safe"])
        self.assertEqual(res["overall_status"], "SAFE_TO_ENTER")
        self.assertEqual(res["readings"]["oxygen"]["status"], "PASS")
        self.assertEqual(res["readings"]["combustible_gas"]["status"], "PASS")
        self.assertEqual(res["readings"]["carbon_monoxide"]["status"], "PASS")
        self.assertEqual(res["readings"]["hydrogen_sulfide"]["status"], "PASS")
        self.assertEqual(len(res["findings"]), 0)

    # -------------------------------------------------------------------------
    # Test 3: Gas Evaluation - Oxygen Deficiency (< 19.5%)
    # -------------------------------------------------------------------------
    def test_03_gas_evaluation_oxygen_deficiency(self):
        """Verify O2 = 18.0% (< 19.5%) fails with OXYGEN_DEFICIENT critical alarm."""
        res = self.engine.evaluate_gas(o2=18.0, lel=0.0, co=0.0, h2s=0.0)
        self.assertFalse(res["is_safe"])
        self.assertEqual(res["overall_status"], "UNSAFE_PROHIBITED")
        self.assertEqual(res["readings"]["oxygen"]["status"], "FAIL")
        self.assertEqual(res["readings"]["oxygen"]["code"], "OXYGEN_DEFICIENT")
        self.assertEqual(res["readings"]["oxygen"]["alarm_level"], "CRITICAL")
        self.assertTrue(any(f["code"] == "OXYGEN_DEFICIENT" for f in res["findings"]))

    # -------------------------------------------------------------------------
    # Test 4: Gas Evaluation - Oxygen Enriched (> 23.5%)
    # -------------------------------------------------------------------------
    def test_04_gas_evaluation_oxygen_enriched(self):
        """Verify O2 = 24.5% (> 23.5%) fails with OXYGEN_ENRICHED high alarm."""
        res = self.engine.evaluate_gas(o2=24.5, lel=0.0, co=0.0, h2s=0.0)
        self.assertFalse(res["is_safe"])
        self.assertEqual(res["readings"]["oxygen"]["status"], "FAIL")
        self.assertEqual(res["readings"]["oxygen"]["code"], "OXYGEN_ENRICHED")

    # -------------------------------------------------------------------------
    # Test 5: Gas Evaluation - Explosive Flammable Gas (LEL >= 10%)
    # -------------------------------------------------------------------------
    def test_05_gas_evaluation_explosive_lel(self):
        """Verify LEL = 12.0% (>= 10.0%) fails with EXPLOSIVE_HAZARD critical alarm."""
        res = self.engine.evaluate_gas(o2=20.9, lel=12.0, co=0.0, h2s=0.0)
        self.assertFalse(res["is_safe"])
        self.assertEqual(res["readings"]["combustible_gas"]["status"], "FAIL")
        self.assertEqual(res["readings"]["combustible_gas"]["code"], "EXPLOSIVE_HAZARD")
        self.assertEqual(res["readings"]["combustible_gas"]["alarm_level"], "CRITICAL")

    # -------------------------------------------------------------------------
    # Test 6: Gas Evaluation - Toxic Gases (CO >= 25 ppm, H2S >= 10 ppm)
    # -------------------------------------------------------------------------
    def test_06_gas_evaluation_toxic_gases(self):
        """Verify CO = 30.0 ppm and H2S = 15.0 ppm fail with toxic gas alarms."""
        res = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=30.0, h2s=15.0)
        self.assertFalse(res["is_safe"])
        self.assertEqual(res["readings"]["carbon_monoxide"]["status"], "FAIL")
        self.assertEqual(res["readings"]["carbon_monoxide"]["code"], "TOXIC_CO_EXCEEDED")
        self.assertEqual(res["readings"]["hydrogen_sulfide"]["status"], "FAIL")
        self.assertEqual(res["readings"]["hydrogen_sulfide"]["code"], "TOXIC_H2S_EXCEEDED")

    # -------------------------------------------------------------------------
    # Test 7: Confined Space - 4 Valid Distinct Certified Roles
    # -------------------------------------------------------------------------
    def test_07_confined_roles_valid(self):
        """Verify complete 4-role registration with certificate numbers passes."""
        roles = {
            "authorizer": {"name": "นายสมศักดิ์ มั่นคง", "cert_no": "AUTH-001"},
            "supervisor": {"name": "นายวิชัย คุมงาน", "cert_no": "SUP-002"},
            "attendant": {"name": "นายธงชัย พร้อมช่วย", "cert_no": "ATT-003"},
            "entrants": [{"name": "นายดำรง ปฏิบัติงาน", "cert_no": "ENT-004"}]
        }
        res = self.engine.verify_confined_roles(roles_payload=roles)
        self.assertTrue(res["is_valid"])
        self.assertEqual(res["verdict"], "COMPLETE_AND_COMPLIANT")
        self.assertEqual(len(res["missing_roles"]), 0)
        self.assertEqual(len(res["conflict_issues"]), 0)

    # -------------------------------------------------------------------------
    # Test 8: Confined Space - Missing Supervisor or Authorizer
    # -------------------------------------------------------------------------
    def test_08_confined_roles_missing_authorizer_or_supervisor(self):
        """Verify missing supervisor fails with statutory non-compliance."""
        roles = {
            "authorizer": {"name": "นายสมศักดิ์ มั่นคง", "cert_no": "AUTH-001"},
            "attendant": {"name": "นายธงชัย พร้อมช่วย", "cert_no": "ATT-003"},
            "entrants": [{"name": "นายดำรง ปฏิบัติงาน", "cert_no": "ENT-004"}]
        }
        res = self.engine.verify_confined_roles(roles_payload=roles)
        self.assertFalse(res["is_valid"])
        self.assertEqual(res["verdict"], "NON_COMPLIANT_ROLES")
        self.assertTrue(any("Supervisor" in r for r in res["missing_roles"]))

    # -------------------------------------------------------------------------
    # Test 9: Confined Space - Attendant & Entrant Overlap Violation
    # -------------------------------------------------------------------------
    def test_09_confined_roles_attendant_entrant_conflict(self):
        """Verify assigning the same person as Attendant and Entrant triggers conflict error."""
        roles = {
            "authorizer": {"name": "นายสมศักดิ์ มั่นคง", "cert_no": "AUTH-001"},
            "supervisor": {"name": "นายวิชัย คุมงาน", "cert_no": "SUP-002"},
            "attendant": {"name": "นายสมชาย เข้าออก", "cert_no": "ATT-003"},
            "entrants": [
                {"name": "นายสมชาย เข้าออก", "cert_no": "ENT-004"},
                {"name": "นายดำรง ปฏิบัติงาน", "cert_no": "ENT-005"}
            ]
        }
        res = self.engine.verify_confined_roles(roles_payload=roles)
        self.assertFalse(res["is_valid"])
        self.assertTrue(len(res["conflict_issues"]) > 0)
        self.assertIn("ผู้ช่วยเหลือ", res["conflict_issues"][0])

    # -------------------------------------------------------------------------
    # Test 10: Hot Work Fire Watch - 30+ Minutes Compliant
    # -------------------------------------------------------------------------
    def test_10_hot_work_firewatch_compliant(self):
        """Verify 35-minute monitoring with watcher name and extinguisher passes."""
        res = self.engine.evaluate_fire_watch(
            monitoring_minutes=35.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertTrue(res["is_valid"])
        self.assertEqual(res["verdict"], "FIRE_WATCH_COMPLIANT")
        self.assertEqual(len(res["findings"]), 0)

    # -------------------------------------------------------------------------
    # Test 11: Hot Work Fire Watch - Insufficient Time (< 30 Minutes)
    # -------------------------------------------------------------------------
    def test_11_hot_work_firewatch_insufficient_time(self):
        """Verify 15-minute monitoring (< 30 min) fails with statutory violation."""
        res = self.engine.evaluate_fire_watch(
            monitoring_minutes=15.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertFalse(res["is_valid"])
        self.assertEqual(res["verdict"], "FIRE_WATCH_NON_COMPLIANT")
        self.assertTrue(any(f["code"] == "POST_WORK_WATCH_INSUFFICIENT" for f in res["findings"]))

    # -------------------------------------------------------------------------
    # Test 12: Hot Work Fire Watch - Missing Watcher or Extinguisher
    # -------------------------------------------------------------------------
    def test_12_hot_work_missing_watcher_or_extinguisher(self):
        """Verify missing watcher or extinguisher fails with critical findings."""
        res = self.engine.evaluate_fire_watch(
            monitoring_minutes=30.0,
            fire_watcher_name="",
            extinguisher_ready=False,
            area_cleared_11m=False
        )
        self.assertFalse(res["is_valid"])
        codes = [f["code"] for f in res["findings"]]
        self.assertIn("MISSING_FIRE_WATCHER", codes)
        self.assertIn("NO_FIRE_EXTINGUISHER", codes)
        self.assertIn("AREA_NOT_CLEARED_11M", codes)

    # -------------------------------------------------------------------------
    # Test 13: Electrical LOTO - Valid Isolation and Zero Energy Verification
    # -------------------------------------------------------------------------
    def test_13_electrical_loto_valid(self):
        """Verify valid isolation points with padlocks, tags, and zero energy verification pass."""
        points = [
            {"point_id": "MCC-BKR-01", "padlock_no": "PL-01", "tag_no": "TAG-01"},
            {"point_id": "VLV-ISO-02", "padlock_no": "PL-02", "tag_no": "TAG-02"}
        ]
        res = self.engine.verify_loto(isolation_points=points, zero_energy_verified=True)
        self.assertTrue(res["is_valid"])
        self.assertEqual(res["verdict"], "LOTO_ISOLATION_VALID")
        self.assertEqual(res["total_points"], 2)

    # -------------------------------------------------------------------------
    # Test 14: Electrical LOTO - Missing Zero Energy Verification
    # -------------------------------------------------------------------------
    def test_14_electrical_loto_missing_zero_energy(self):
        """Verify missing zero energy verification fails with critical violation."""
        points = [
            {"point_id": "MCC-BKR-01", "padlock_no": "PL-01", "tag_no": "TAG-01"}
        ]
        res = self.engine.verify_loto(isolation_points=points, zero_energy_verified=False)
        self.assertFalse(res["is_valid"])
        self.assertEqual(res["verdict"], "LOTO_ISOLATION_INCOMPLETE")
        self.assertTrue(any(f["code"] == "ZERO_ENERGY_NOT_VERIFIED" for f in res["findings"]))

    # -------------------------------------------------------------------------
    # Test 15: Working at Height - Fall Protection Validation
    # -------------------------------------------------------------------------
    def test_15_working_at_height_validation(self):
        """Verify height >= 2.0m enforces full body harness and anchor point verification."""
        ptw_good = {
            "ptw_number": "PTW-WAH-01",
            "work_title": "งานซ่อมหลังคาโรงงาน",
            "work_type": "working_at_height",
            "valid_from": "2026-09-02T08:00:00",
            "valid_to": "2026-09-02T16:00:00",
            "height_meters": 5.0,
            "height_controls": {
                "full_body_harness_used": True,
                "anchor_point_certified_22kn": True
            }
        }
        res_good = self.engine.validate_ptw(ptw_good)
        self.assertTrue(res_good["is_compliant"])
        self.assertGreaterEqual(res_good["validation_score"], 80.0)

        ptw_bad = {
            "ptw_number": "PTW-WAH-02",
            "work_title": "งานซ่อมหลังคาโรงงาน",
            "work_type": "working_at_height",
            "valid_from": "2026-09-02T08:00:00",
            "valid_to": "2026-09-02T16:00:00",
            "height_meters": 5.0,
            "height_controls": {
                "full_body_harness_used": False,
                "anchor_point_certified_22kn": False
            }
        }
        res_bad = self.engine.validate_ptw(ptw_bad)
        self.assertFalse(res_bad["is_compliant"])
        codes = [f["code"] for f in res_bad["findings"]]
        self.assertIn("NO_FULL_BODY_HARNESS", codes)

    # -------------------------------------------------------------------------
    # Test 16: Excavation - Depth Shoring and Underground Utility Scan
    # -------------------------------------------------------------------------
    def test_16_excavation_validation(self):
        """Verify excavation depth >= 1.5m enforces shoring and utility survey."""
        ptw_exc = {
            "ptw_number": "PTW-EXC-01",
            "work_title": "งานขุดวางท่อระบายน้ำ",
            "work_type": "excavation_lifting",
            "valid_from": "2026-09-02T08:00:00",
            "valid_to": "2026-09-02T16:00:00",
            "depth_meters": 2.0,
            "excavation_controls": {
                "shoring_installed": False,
                "sloping_done": False,
                "underground_utilities_scanned": False
            }
        }
        res = self.engine.validate_ptw(ptw_exc)
        self.assertFalse(res["is_compliant"])
        codes = [f["code"] for f in res["findings"]]
        self.assertIn("NO_SOIL_SHORING", codes)
        self.assertIn("NO_UTILITIES_SCAN", codes)

    # -------------------------------------------------------------------------
    # Test 17: Full PTW Validation on Sample Dataset
    # -------------------------------------------------------------------------
    def test_17_full_ptw_validation_samples(self):
        """Verify sample PTW benchmarks evaluate accurately."""
        samples = self.engine.sample_ptws.get("samples", [])
        self.assertGreaterEqual(len(samples), 5)
        
        # Check valid confined space
        s_cs_valid = next(s for s in samples if s["sample_id"] == "PTW-CONFINED-VALID")
        res_cs_valid = self.engine.validate_ptw(s_cs_valid["payload"])
        self.assertTrue(res_cs_valid["is_compliant"])
        self.assertEqual(res_cs_valid["status_badge"], "COMPLIANT_PERMIT_VALID")

        # Check bad gas confined space
        s_cs_bad = next(s for s in samples if s["sample_id"] == "PTW-CONFINED-BAD-GAS")
        res_cs_bad = self.engine.validate_ptw(s_cs_bad["payload"])
        self.assertFalse(res_cs_bad["is_compliant"])

    # -------------------------------------------------------------------------
    # Test 18: Safety Checklist Retrieval
    # -------------------------------------------------------------------------
    def test_18_get_checklist_by_type_and_subcategory(self):
        """Verify get_checklist returns structured items for work types."""
        chk_hw = self.engine.get_checklist(ptw_type="hot_work")
        self.assertEqual(chk_hw["status"], "success")
        self.assertEqual(chk_hw["work_type"], "hot_work")
        self.assertGreaterEqual(chk_hw["total_items"], 8)

        chk_all = self.engine.get_checklist(ptw_type="all")
        self.assertEqual(chk_all["status"], "success")
        self.assertGreaterEqual(chk_all["total_items"], 40)

    # -------------------------------------------------------------------------
    # Test 19: PTW Law Query & Search
    # -------------------------------------------------------------------------
    def test_19_ptw_law_query_and_search(self):
        """Verify law retrieval and keyword search return relevant statutory articles."""
        law_res = self.engine.get_ptw_law(topic="confined_space", section="ข้อ ๗")
        self.assertEqual(law_res["status"], "success")
        self.assertGreaterEqual(law_res["total_found"], 1)

        search_res = self.engine.search_laws(query="บรรยากาศอันตราย")
        self.assertEqual(search_res["status"], "success")
        self.assertGreaterEqual(search_res["total_found"], 1)
        self.assertIn("article_no", search_res["results"][0])

    # -------------------------------------------------------------------------
    # Test 20: Dual-Mode Helper (Direct In-Memory and CLI Subprocess)
    # -------------------------------------------------------------------------
    def test_20_dual_mode_helper_and_cli(self):
        """Verify ThaiPtwHelper runs seamlessly in both direct mode and CLI subprocess fallback mode."""
        # 1. Direct mode
        gas_dir = self.helper_direct.eval_gas(o2=20.9, lel=0.0, co=0.0, h2s=0.0)
        self.assertTrue(gas_dir["is_safe"])
        self.assertEqual(gas_dir["overall_status"], "SAFE_TO_ENTER")

        # 2. CLI subprocess mode
        gas_cli = self.helper_cli.eval_gas(o2=20.9, lel=0.0, co=0.0, h2s=0.0)
        self.assertTrue(gas_cli["is_safe"])
        self.assertEqual(gas_cli["overall_status"], "SAFE_TO_ENTER")

        # 3. Confined roles via helper
        roles_res = self.helper_direct.verify_confined_roles(
            authorizer="นายทรงศักดิ์:AUTH-01",
            supervisor="นายวิชัย:SUP-02",
            attendant="นายธงชัย:ATT-03",
            entrants="นายดำรง:ENT-04"
        )
        self.assertTrue(roles_res["is_valid"])

        # 4. Hot work fire watch via helper
        hw_res = self.helper_direct.check_hotwork_firewatch(
            monitoring_minutes=30.0,
            fire_watcher_name="นายเฝ้าไฟ",
            extinguisher_ready=True
        )
        self.assertTrue(hw_res["is_valid"])


if __name__ == "__main__":
    unittest.main()
