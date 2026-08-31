"""
==============================================================================
 Unit Test Suite for thai-safety-legal-register Agent Skill
 File: tests/test_thai_safety_legal_skill.py
 Covering 12 Automated Verification Tests
==============================================================================
"""

import unittest
import os
import sys
import json
import subprocess

# Ensure script paths
TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(TESTS_DIR)
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_safety_legal_cli.py")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_safety_legal_engine import ThaiSafetyLegalEngine
from thai_safety_legal_helper import ThaiSafetyLegalHelper


class TestThaiSafetyLegalSkill(unittest.TestCase):
    """Comprehensive test suite for Thai Safety Legal Register Agent Skill."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiSafetyLegalEngine(data_dir=DATA_DIR)
        cls.helper = ThaiSafetyLegalHelper(skill_dir=SKILL_DIR, prefer_direct=True)
        cls.helper_cli = ThaiSafetyLegalHelper(skill_dir=SKILL_DIR, prefer_direct=False)

    # 1. Catalog Integrity Test
    def test_01_catalog_integrity(self):
        """Verify all 8 laws exist with Gazette metadata and >= 30 total requirements."""
        self.assertEqual(len(self.engine.laws), 8, "Expected exactly 8 core safety regulations.")
        
        total_reqs = sum(len(law.get("items", [])) for law in self.engine.laws)
        self.assertGreaterEqual(total_reqs, 30, f"Expected at least 30 statutory requirements, got {total_reqs}.")

        expected_law_ids = ["LAW-01", "LAW-02", "LAW-03", "LAW-04", "LAW-05", "LAW-06", "LAW-07", "LAW-08"]
        for lid in expected_law_ids:
            law = self.engine.get_law(lid).get("law")
            self.assertIsNotNone(law, f"Law {lid} must be retrievable.")
            self.assertTrue(len(law.get("title_th", "")) > 0, f"Law {lid} must have Thai title.")
            gazette = law.get("gazette", {})
            self.assertTrue(len(gazette.get("volume", "")) > 0, f"Law {lid} must have Gazette volume.")
            self.assertTrue(len(gazette.get("issue", "")) > 0, f"Law {lid} must have Gazette issue/part.")

    # 2. Search by Keyword Test
    def test_02_search_by_keyword(self):
        """Search Thai and English keywords across requirements."""
        keywords = ["จป.วิชาชีพ", "ดับเพลิง", "ปั้นจั่น", "หม้อน้ำ", "WBGT", "สอ.๑", "สปร.๕", "Single Line Diagram"]
        for kw in keywords:
            res = self.engine.search_laws(kw)
            self.assertEqual(res.get("status"), "success")
            self.assertGreater(res.get("total_found", 0), 0, f"Keyword '{kw}' must return at least 1 match.")
            top_result = res["results"][0]
            self.assertIn("law_id", top_result)
            self.assertIn("req_id", top_result)
            self.assertIn("penalty_clause", top_result)

    # 3. Search by Category Test
    def test_03_search_by_category(self):
        """Test filtering by category."""
        categories = ["electrical_2558", "chemical_2556", "fire_2555", "environment_2559", "health_check_2563"]
        for cat in categories:
            res = self.engine.search_laws("การตรวจ", category=cat)
            self.assertEqual(res.get("status"), "success")
            for item in res.get("results", []):
                self.assertEqual(item.get("category"), cat)

    # 4. Get Law by ID and Section Test
    def test_04_get_law_by_id(self):
        """Retrieve laws by ID and specific sections."""
        # Retrieve LAW-02 section 'ข้อ ๑๖'
        res = self.engine.get_law("LAW-02", section="ข้อ ๑๖")
        self.assertEqual(res.get("status"), "success")
        law = res.get("law", {})
        self.assertEqual(law.get("law_id"), "LAW-02")
        self.assertIsNotNone(law.get("target_section"))
        self.assertIn("จป.วิชาชีพ", law["target_section"]["title"])

        # Retrieve by alias 'chem_2556'
        res_chem = self.engine.get_law("chem_2556")
        self.assertEqual(res_chem.get("status"), "success")
        self.assertEqual(res_chem["law"]["law_id"], "LAW-03")

    # 5. Evaluate Small Enterprise Profile Test
    def test_05_evaluate_small_enterprise(self):
        """Profile with 15 employees in Annex 3 (low hazard office/service)."""
        profile = {
            "company_name": "Small Office Co., Ltd.",
            "industry_type": "IT & Consulting",
            "business_category_annex": 3,
            "employee_count": 15,
            "has_hazardous_chemicals": False,
            "has_cranes": False,
            "has_boilers": False,
            "has_high_voltage_electrical": False,
            "has_noise_exceed_85dba": False,
            "has_occupational_health_risks": False,
            "current_practices": {
                "has_safety_policy": True,
                "new_employee_safety_trained": True,
                "safety_signs_and_rights_posted": True,
                "free_standard_ppe_provided": True,
                "accident_reporting_procedure_ready": True,
                "fire_exit_and_emergency_lights_compliant": True,
                "fire_extinguishers_checked_regularly": True,
                "basic_fire_trained_percent": 50.0,
                "fire_drill_conducted_last_12m": True,
                "single_line_diagram_updated": True,
                "electrical_inspection_conducted_last_12m": True,
                "grounding_and_rcd_tested_compliant": True
            }
        }
        res = self.engine.evaluate_compliance(profile)
        self.assertEqual(res.get("status"), "success")
        summary = res.get("compliance_summary", {})
        self.assertGreater(summary.get("not_applicable_count", 0), 10)
        self.assertEqual(summary.get("critical_gaps_count", 0), 0)
        self.assertIn("A", summary.get("compliance_grade", ""))

    # 6. Evaluate Large Chemical Manufacturing Profile Test
    def test_06_evaluate_large_chemical_manufacturing(self):
        """Profile with 250 employees in Annex 2 with chemicals, cranes, and boilers."""
        profile_path = os.path.join(DATA_DIR, "sample_workplace_profile.json")
        res = self.engine.evaluate_compliance(profile_path)
        self.assertEqual(res.get("status"), "success")
        summary = res.get("compliance_summary", {})
        
        # In sample profile: 85 employees in Annex 2, lacks JPor Prof, Elec check, Crane cert, Health report
        self.assertGreater(summary.get("non_compliant_count", 0), 0)
        self.assertGreater(summary.get("critical_gaps_count", 0), 0)
        self.assertIn("NEEDS_IMPROVEMENT", summary.get("compliance_grade", ""))

    # 7. Evaluate Scoring Accuracy Formula Test
    def test_07_evaluate_scoring_accuracy(self):
        """Verify 100% compliant profile produces Grade A and exact formula calculation."""
        # 100% compliant profile
        profile_perfect = {
            "company_name": "Perfect Safety Factory",
            "industry_type": "Manufacturing",
            "business_category_annex": 2,
            "employee_count": 80,
            "has_hazardous_chemicals": True,
            "has_cranes": True,
            "has_boilers": False,
            "has_high_voltage_electrical": True,
            "has_noise_exceed_85dba": True,
            "has_occupational_health_risks": True,
            "current_practices": {
                "has_safety_policy": True,
                "new_employee_safety_trained": True,
                "safety_signs_and_rights_posted": True,
                "free_standard_ppe_provided": True,
                "accident_reporting_procedure_ready": True,
                "has_jpor_supervisory": True,
                "has_jpor_executive": True,
                "has_jpor_technical_adv": True,
                "has_jpor_professional": True,
                "has_safety_committee": True,
                "safety_committee_meeting_monthly": True,
                "jpor_quarterly_report_submitted": True,
                "has_sds_16_sections_sor_or_1": True,
                "ghs_labeling_compliant": True,
                "chem_measurement_sor_or_3_conducted_last_12m": True,
                "bund_wall_containment_compliant": True,
                "eyewash_shower_checked_weekly": True,
                "chem_emergency_drill_conducted_last_12m": True,
                "fire_exit_and_emergency_lights_compliant": True,
                "fire_extinguishers_checked_regularly": True,
                "fire_alarm_and_pump_tested_last_12m": True,
                "basic_fire_trained_percent": 60.0,
                "fire_drill_conducted_last_12m": True,
                "single_line_diagram_updated": True,
                "electrical_inspection_conducted_last_12m": True,
                "grounding_and_rcd_tested_compliant": True,
                "lightning_protection_inspected": True,
                "electrical_safety_trained_and_loto": True,
                "machine_guarding_and_estop_compliant": True,
                "crane_pj2_inspected_last_interval": True,
                "crane_4_operators_trained": True,
                "env_standards_compliant": True,
                "env_measurement_conducted_last_12m": True,
                "has_hearing_conservation_program": True,
                "health_check_conducted_last_12m": True,
                "health_booklet_recorded": True,
                "health_check_report_submitted_jphor1": True
            }
        }
        res = self.engine.evaluate_compliance(profile_perfect)
        summary = res["compliance_summary"]
        self.assertEqual(summary["compliance_percentage"], 100.0)
        self.assertEqual(summary["risk_weighted_score"], 100.0)
        self.assertEqual(summary["critical_gaps_count"], 0)
        self.assertEqual(summary["non_compliant_count"], 0)
        self.assertIn("A - EXCELLENT", summary["compliance_grade"])

    # 8. CAPA Generation from Evaluation Output Test
    def test_08_capa_generation_from_eval(self):
        """Generate automated CAPA from evaluation assessment output."""
        sample_path = os.path.join(DATA_DIR, "sample_workplace_profile.json")
        eval_res = self.engine.evaluate_compliance(sample_path)
        
        capa_res = self.engine.generate_capa(eval_data=eval_res)
        self.assertEqual(capa_res.get("status"), "success")
        capa_plans = capa_res.get("capa_plans", [])
        self.assertGreater(len(capa_plans), 0)
        
        first_plan = capa_plans[0]
        self.assertIn("capa_id", first_plan)
        self.assertIn("root_cause", first_plan)
        self.assertIn("corrective_action", first_plan)
        self.assertIn("preventive_action", first_plan)
        self.assertIn("person_in_charge", first_plan)
        self.assertIn("target_deadline", first_plan)
        self.assertEqual(first_plan.get("status"), "OPEN")

    # 9. CAPA Generation from IDs Test
    def test_09_capa_generation_from_ids(self):
        """Generate CAPA from comma-separated list of requirement IDs."""
        item_ids = ["LAW-02-REQ-04", "LAW-05-REQ-01", "LAW-06-REQ-02"]
        capa_res = self.engine.generate_capa(item_ids=item_ids)
        self.assertEqual(capa_res.get("status"), "success")
        capa_plans = capa_res.get("capa_plans", [])
        self.assertEqual(len(capa_plans), 3)
        
        req_ids_in_plan = [p["req_id"] for p in capa_plans]
        for rid in item_ids:
            self.assertIn(rid, req_ids_in_plan)

    # 10. Helper Dual-Mode Invocation Test
    def test_10_helper_dual_mode(self):
        """Verify ThaiSafetyLegalHelper functions under both direct and CLI fallback modes."""
        # Direct mode
        res_direct = self.helper.search_law("จป.วิชาชีพ")
        self.assertEqual(res_direct.get("status"), "success")
        self.assertGreater(res_direct.get("total_found", 0), 0)

        # CLI fallback mode
        res_cli = self.helper_cli.search_law("จป.วิชาชีพ")
        self.assertEqual(res_cli.get("status"), "success")
        self.assertGreater(res_cli.get("total_found", 0), 0)

        # Helper evaluation
        eval_direct = self.helper.evaluate_workplace(os.path.join(DATA_DIR, "sample_workplace_profile.json"))
        self.assertEqual(eval_direct.get("status"), "success")

        # Helper CAPA
        capa_direct = self.helper.generate_capa_summary(non_compliant_item_ids=["LAW-02-REQ-04"])
        self.assertEqual(capa_direct.get("status"), "success")
        self.assertEqual(len(capa_direct.get("capa_plans", [])), 1)

    # 11. Invalid Inputs Handling Test
    def test_11_invalid_inputs_handling(self):
        """Ensure graceful error handling for empty queries, non-existent laws, or malformed JSON."""
        # Empty query
        res_empty = self.engine.search_laws("")
        self.assertEqual(res_empty.get("status"), "error")

        # Non-existent law
        res_invalid_law = self.engine.get_law("LAW-UNKNOWN-999")
        self.assertEqual(res_invalid_law.get("status"), "error")

        # Malformed profile string
        res_malformed = self.engine.evaluate_compliance("INVALID JSON STRING {")
        self.assertEqual(res_malformed.get("status"), "error")

    # 12. UTF-8 Thai Encoding Stress Test
    def test_12_utf8_thai_encoding(self):
        """Stress test Thai characters across CLI execution and engine queries."""
        thai_query = "การจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ และการตรวจวัดระดับความเข้มข้นสารเคมีอันตราย"
        res = self.engine.search_laws(thai_query)
        self.assertEqual(res.get("status"), "success")
        self.assertGreater(res.get("total_found", 0), 0)

        # Subprocess CLI execution with Thai argument
        cmd = [sys.executable, CLI_SCRIPT, "search", "-q", "ตรวจรับรองหม้อน้ำ บร.๒", "-l", "3"]
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(proc.returncode, 0, f"CLI stderr: {proc.stderr}")
        parsed = json.loads(proc.stdout)
        self.assertEqual(parsed.get("status"), "success")
        self.assertGreater(parsed.get("total_found", 0), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
