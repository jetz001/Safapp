"""
==============================================================================
 Milestone 5 Adversarial Challenge & Stress Test Suite
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

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(TESTS_DIR)
SCRIPTS_DIR = os.path.join(SKILL_ROOT, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_ptw_engine import ThaiPtwEngine
from thai_ptw_helper import ThaiPtwHelper


class TestMilestone5AdversarialChallenge(unittest.TestCase):
    """Adversarial stress-testing suite for M5 Python Engine, CLI, and Helper."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiPtwEngine(data_dir=DATA_DIR)
        cls.helper = ThaiPtwHelper(skill_dir=SKILL_ROOT, prefer_direct=True)

    # -------------------------------------------------------------------------
    # 1. Gas Evaluation Exact Boundary Limits
    # -------------------------------------------------------------------------
    def test_gas_boundary_o2_exact_limits(self):
        """O2 boundaries: 19.4% (FAIL), 19.5% (PASS), 23.5% (PASS), 23.6% (FAIL)"""
        # 19.4% -> Sub-oxygen deficient -> FAIL
        r194 = self.engine.evaluate_gas(o2=19.4, lel=0.0, co=0.0, h2s=0.0)
        self.assertFalse(r194["is_safe"])
        self.assertEqual(r194["readings"]["oxygen"]["status"], "FAIL")
        self.assertEqual(r194["readings"]["oxygen"]["code"], "OXYGEN_DEFICIENT")
        self.assertEqual(r194["overall_status"], "UNSAFE_PROHIBITED")

        # 19.5% -> Lower Statutory Threshold -> PASS
        r195 = self.engine.evaluate_gas(o2=19.5, lel=0.0, co=0.0, h2s=0.0)
        self.assertTrue(r195["is_safe"])
        self.assertEqual(r195["readings"]["oxygen"]["status"], "PASS")
        self.assertEqual(r195["overall_status"], "SAFE_TO_ENTER")

        # 23.5% -> Upper Statutory Threshold -> PASS
        r235 = self.engine.evaluate_gas(o2=23.5, lel=0.0, co=0.0, h2s=0.0)
        self.assertTrue(r235["is_safe"])
        self.assertEqual(r235["readings"]["oxygen"]["status"], "PASS")
        self.assertEqual(r235["overall_status"], "SAFE_TO_ENTER")

        # 23.6% -> Oxygen Enriched Flammable Hazard -> FAIL
        r236 = self.engine.evaluate_gas(o2=23.6, lel=0.0, co=0.0, h2s=0.0)
        self.assertFalse(r236["is_safe"])
        self.assertEqual(r236["readings"]["oxygen"]["status"], "FAIL")
        self.assertEqual(r236["readings"]["oxygen"]["code"], "OXYGEN_ENRICHED")
        self.assertEqual(r236["overall_status"], "UNSAFE_PROHIBITED")

    def test_gas_boundary_lel_exact_limits(self):
        """LEL boundaries: 9.9% (PASS), 10.0% (FAIL), 10.1% (FAIL)"""
        # 9.9% LEL -> Below 10% statutory limit -> PASS
        r99 = self.engine.evaluate_gas(o2=20.9, lel=9.9, co=0.0, h2s=0.0)
        self.assertTrue(r99["is_safe"])
        self.assertEqual(r99["readings"]["combustible_gas"]["status"], "PASS")

        # 10.0% LEL -> Exact Explosive Threshold -> FAIL
        r100 = self.engine.evaluate_gas(o2=20.9, lel=10.0, co=0.0, h2s=0.0)
        self.assertFalse(r100["is_safe"])
        self.assertEqual(r100["readings"]["combustible_gas"]["status"], "FAIL")
        self.assertEqual(r100["readings"]["combustible_gas"]["code"], "EXPLOSIVE_HAZARD")

        # 10.1% LEL -> Exceeded Explosive Threshold -> FAIL
        r101 = self.engine.evaluate_gas(o2=20.9, lel=10.1, co=0.0, h2s=0.0)
        self.assertFalse(r101["is_safe"])
        self.assertEqual(r101["readings"]["combustible_gas"]["status"], "FAIL")

    def test_gas_boundary_co_exact_limits(self):
        """CO boundaries: 24.9 ppm (PASS), 25.0 ppm (FAIL), 25.1 ppm (FAIL)"""
        # 24.9 ppm -> Below 25 ppm statutory limit -> PASS
        r249 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=24.9, h2s=0.0)
        self.assertTrue(r249["is_safe"])
        self.assertEqual(r249["readings"]["carbon_monoxide"]["status"], "PASS")

        # 25.0 ppm -> Exact Toxic Ceiling -> FAIL
        r250 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=25.0, h2s=0.0)
        self.assertFalse(r250["is_safe"])
        self.assertEqual(r250["readings"]["carbon_monoxide"]["status"], "FAIL")
        self.assertEqual(r250["readings"]["carbon_monoxide"]["code"], "TOXIC_CO_EXCEEDED")

        # 25.1 ppm -> Exceeded Toxic Ceiling -> FAIL
        r251 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=25.1, h2s=0.0)
        self.assertFalse(r251["is_safe"])
        self.assertEqual(r251["readings"]["carbon_monoxide"]["status"], "FAIL")

    def test_gas_boundary_h2s_exact_limits(self):
        """H2S boundaries: 9.9 ppm (PASS), 10.0 ppm (FAIL), 10.1 ppm (FAIL)"""
        # 9.9 ppm -> Below 10 ppm statutory limit -> PASS
        r99 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=0.0, h2s=9.9)
        self.assertTrue(r99["is_safe"])
        self.assertEqual(r99["readings"]["hydrogen_sulfide"]["status"], "PASS")

        # 10.0 ppm -> Exact Deadly Toxic Ceiling -> FAIL
        r100 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=0.0, h2s=10.0)
        self.assertFalse(r100["is_safe"])
        self.assertEqual(r100["readings"]["hydrogen_sulfide"]["status"], "FAIL")
        self.assertEqual(r100["readings"]["hydrogen_sulfide"]["code"], "TOXIC_H2S_EXCEEDED")

        # 10.1 ppm -> Deadly H2S Atmosphere -> FAIL
        r101 = self.engine.evaluate_gas(o2=20.9, lel=0.0, co=0.0, h2s=10.1)
        self.assertFalse(r101["is_safe"])
        self.assertEqual(r101["readings"]["hydrogen_sulfide"]["status"], "FAIL")

    # -------------------------------------------------------------------------
    # 2. Confined Space 4-Role Validation & Collision Prevention
    # -------------------------------------------------------------------------
    def test_confined_roles_4_distinct_compliant(self):
        """Complete 4-role registration with certificate numbers passes."""
        roles = {
            "authorizer": {"name": "นายสมศักดิ์ ผู้อนุญาต", "cert_no": "AUTH-001"},
            "supervisor": {"name": "นายวิชัย ผู้ควบคุมงาน", "cert_no": "SUP-002"},
            "attendant": {"name": "นายธงชัย ผู้ช่วยเหลือ", "cert_no": "ATT-003"},
            "entrants": [
                {"name": "นายดำรง ช่างเชื่อม", "cert_no": "ENT-004"},
                {"name": "นายอนุชา ช่างกล", "cert_no": "ENT-005"},
            ]
        }
        res = self.engine.verify_confined_roles(roles_payload=roles)
        self.assertTrue(res["is_valid"])
        self.assertEqual(res["verdict"], "COMPLETE_AND_COMPLIANT")
        self.assertEqual(len(res["missing_roles"]), 0)
        self.assertEqual(len(res["conflict_issues"]), 0)

    def test_confined_roles_missing_each_statutory_role(self):
        """Missing any of the 4 statutory roles (ข้อ ๙-๑๒) MUST FAIL."""
        # 1. Missing Authorizer
        res_no_auth = self.engine.verify_confined_roles(
            supervisor={"name": "นายวิชัย", "cert_no": "S-1"},
            attendant={"name": "นายธงชัย", "cert_no": "A-1"},
            entrants=[{"name": "นายดำรง", "cert_no": "E-1"}]
        )
        self.assertFalse(res_no_auth["is_valid"])
        self.assertTrue(any("Authorizer" in m for m in res_no_auth["missing_roles"]))

        # 2. Missing Supervisor
        res_no_sup = self.engine.verify_confined_roles(
            authorizer={"name": "นายสมศักดิ์", "cert_no": "A-1"},
            attendant={"name": "นายธงชัย", "cert_no": "A-2"},
            entrants=[{"name": "นายดำรง", "cert_no": "E-1"}]
        )
        self.assertFalse(res_no_sup["is_valid"])
        self.assertTrue(any("Supervisor" in m for m in res_no_sup["missing_roles"]))

        # 3. Missing Attendant
        res_no_att = self.engine.verify_confined_roles(
            authorizer={"name": "นายสมศักดิ์", "cert_no": "A-1"},
            supervisor={"name": "นายวิชัย", "cert_no": "S-1"},
            entrants=[{"name": "นายดำรง", "cert_no": "E-1"}]
        )
        self.assertFalse(res_no_att["is_valid"])
        self.assertTrue(any("Attendant" in m for m in res_no_att["missing_roles"]))

        # 4. Missing Entrants (empty list)
        res_no_ent = self.engine.verify_confined_roles(
            authorizer={"name": "นายสมศักดิ์", "cert_no": "A-1"},
            supervisor={"name": "นายวิชัย", "cert_no": "S-1"},
            attendant={"name": "นายธงชัย", "cert_no": "A-2"},
            entrants=[]
        )
        self.assertFalse(res_no_ent["is_valid"])
        self.assertTrue(any("Entrant" in m for m in res_no_ent["missing_roles"]))

    def test_confined_roles_attendant_entrant_collision(self):
        """Attendant assigned as Entrant triggers statutory conflict violation."""
        # Exact name collision
        res_collision = self.engine.verify_confined_roles(
            authorizer={"name": "นายประสิทธิ์", "cert_no": "AUTH-1"},
            supervisor={"name": "นายวิชัย", "cert_no": "SUP-1"},
            attendant={"name": "นายสมชาย ยืนเฝ้า", "cert_no": "ATT-1"},
            entrants=[
                {"name": "นายสมชาย ยืนเฝ้า", "cert_no": "ENT-1"},
                {"name": "นายดำรง", "cert_no": "ENT-2"},
            ]
        )
        self.assertFalse(res_collision["is_valid"])
        self.assertTrue(len(res_collision["conflict_issues"]) > 0)
        self.assertIn("ผู้ช่วยเหลือ", res_collision["conflict_issues"][0])

        # Case-insensitive / whitespace trimmed collision
        res_whitespace_collision = self.engine.verify_confined_roles(
            authorizer={"name": "นายประสิทธิ์", "cert_no": "AUTH-1"},
            supervisor={"name": "นายวิชัย", "cert_no": "SUP-1"},
            attendant={"name": "Somchai Helper ", "cert_no": "ATT-1"},
            entrants=[{"name": " somchai helper", "cert_no": "ENT-1"}]
        )
        self.assertFalse(res_whitespace_collision["is_valid"])
        self.assertTrue(len(res_whitespace_collision["conflict_issues"]) > 0)

    # -------------------------------------------------------------------------
    # 3. Hot Work Fire Watch 30-min Duration & Extinguisher Verification
    # -------------------------------------------------------------------------
    def test_firewatch_duration_boundaries(self):
        """Fire watch duration: 29.0m (FAIL), 29.99m (FAIL), 30.0m (PASS), 35.0m (PASS)"""
        # 29.0 minutes -> FAIL
        r29 = self.engine.evaluate_fire_watch(
            monitoring_minutes=29.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertFalse(r29["is_valid"])
        self.assertEqual(r29["verdict"], "FIRE_WATCH_NON_COMPLIANT")
        self.assertTrue(any(f["code"] == "POST_WORK_WATCH_INSUFFICIENT" for f in r29["findings"]))

        # 29.99 minutes -> FAIL
        r2999 = self.engine.evaluate_fire_watch(
            monitoring_minutes=29.99,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertFalse(r2999["is_valid"])

        # 30.0 minutes -> Exact Statutory Threshold -> PASS
        r30 = self.engine.evaluate_fire_watch(
            monitoring_minutes=30.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertTrue(r30["is_valid"])
        self.assertEqual(r30["verdict"], "FIRE_WATCH_COMPLIANT")

        # 35.0 minutes -> PASS
        r35 = self.engine.evaluate_fire_watch(
            monitoring_minutes=35.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertTrue(r35["is_valid"])

    def test_firewatch_missing_extinguisher_or_watcher(self):
        """Extinguisher absent or missing watcher name MUST FAIL."""
        # Extinguisher absent
        r_no_ext = self.engine.evaluate_fire_watch(
            monitoring_minutes=30.0,
            fire_watcher_name="นายเอกชัย ตาไว",
            extinguisher_ready=False,
            area_cleared_11m=True
        )
        self.assertFalse(r_no_ext["is_valid"])
        self.assertTrue(any(f["code"] == "NO_FIRE_EXTINGUISHER" for f in r_no_ext["findings"]))

        # Missing watcher name
        r_no_watcher = self.engine.evaluate_fire_watch(
            monitoring_minutes=30.0,
            fire_watcher_name="",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertFalse(r_no_watcher["is_valid"])
        self.assertTrue(any(f["code"] == "MISSING_FIRE_WATCHER" for f in r_no_watcher["findings"]))

    # -------------------------------------------------------------------------
    # 4. LOTO Zero Energy Verification
    # -------------------------------------------------------------------------
    def test_loto_zero_energy_verification(self):
        """LOTO zero energy: unverified (FAIL) vs verified (PASS)"""
        iso_points = [
            {"point_id": "MCC-01", "padlock_no": "LOCK-1", "tag_no": "TAG-1"},
            {"point_id": "VALVE-02", "padlock_no": "LOCK-2", "tag_no": "TAG-2"}
        ]

        # Zero energy unverified -> FAIL
        r_unverified = self.engine.verify_loto(
            isolation_points=iso_points,
            zero_energy_verified=False
        )
        self.assertFalse(r_unverified["is_valid"])
        self.assertEqual(r_unverified["verdict"], "LOTO_ISOLATION_INCOMPLETE")
        self.assertTrue(any(f["code"] == "ZERO_ENERGY_NOT_VERIFIED" for f in r_unverified["findings"]))

        # Zero energy verified -> PASS
        r_verified = self.engine.verify_loto(
            isolation_points=iso_points,
            zero_energy_verified=True
        )
        self.assertTrue(r_verified["is_valid"])
        self.assertEqual(r_verified["verdict"], "LOTO_ISOLATION_VALID")

        # Empty isolation points -> FAIL
        r_empty = self.engine.verify_loto(
            isolation_points=[],
            zero_energy_verified=True
        )
        self.assertFalse(r_empty["is_valid"])
        self.assertTrue(any(f["code"] == "NO_ISOLATION_POINTS" for f in r_empty["findings"]))

    # -------------------------------------------------------------------------
    # 5. Dual-Mode Helper Verification
    # -------------------------------------------------------------------------
    def test_helper_direct_and_cli_modes(self):
        """Verify ThaiPtwHelper executes correctly via direct Python imports."""
        # Eval gas via helper
        gas_res = self.helper.eval_gas(o2=20.9, lel=0.0, co=2.0, h2s=0.0)
        self.assertTrue(gas_res["is_safe"])

        # Check hot work via helper
        hw_res = self.helper.check_hotwork_firewatch(
            monitoring_minutes=35.0,
            fire_watcher_name="นายเอกชัย",
            extinguisher_ready=True,
            area_cleared_11m=True
        )
        self.assertTrue(hw_res["is_valid"])

        # Query law via helper
        law_res = self.helper.get_ptw_law(query="บรรยากาศอันตราย")
        self.assertEqual(law_res["status"], "success")
        self.assertTrue(len(law_res.get("results", [])) > 0)


if __name__ == "__main__":
    unittest.main()
