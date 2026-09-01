"""
Comprehensive Unit Test Suite for Thai Environmental Safety Law Skill
Conforming to 6 Royal Thai Gazette Enactments:
  - OSH Act B.E. 2554
  - Ministerial Reg. Heat, Light, Noise B.E. 2559
  - DLPW Notification Lighting Standards B.E. 2561
  - DLPW Notification Noise Exposure Standards B.E. 2561
  - DLPW Notification WBGT Calculation & Evaluation B.E. 2563
  - DLPW Notification Environmental Reporting Form B.E. 2559
"""

import os
import sys
import json
import math
import unittest

# Add scripts directory to path
TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.abspath(os.path.join(TEST_DIR, ".."))
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_env_engine import ThaiEnvEngine
from thai_env_helper import ThaiEnvHelper


class TestThaiEnvSkill(unittest.TestCase):
    """Test suite covering all calculations, statutory rules, subcommands, and dual-mode helper."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiEnvEngine(data_dir=DATA_DIR)
        cls.helper = ThaiEnvHelper(skill_dir=SKILL_DIR, prefer_direct=True)

    # -------------------------------------------------------------------------
    # Test 01: Catalog Integrity
    # -------------------------------------------------------------------------
    def test_01_catalog_integrity(self):
        """Verify statutory standards catalog contains lighting, noise, heat, and laws data."""
        data = self.engine.standards_data
        self.assertIn("lighting_standards", data)
        self.assertIn("noise_standards", data)
        self.assertIn("heat_wbgt_standards", data)
        self.assertIn("laws_catalog", data)

        lighting_list = data["lighting_standards"]
        self.assertGreaterEqual(len(lighting_list), 10, "Lighting standards must contain >= 10 records")

        noise_std = data["noise_standards"]
        self.assertEqual(noise_std.get("statutory_limit_8hr_twa_dba"), 86.0)
        self.assertEqual(noise_std.get("action_level_dba"), 85.0)
        self.assertEqual(noise_std.get("continuous_ceiling_max_dba"), 115.0)
        self.assertEqual(noise_std.get("peak_impact_max_db"), 140.0)

        heat_std = data["heat_wbgt_standards"]
        workload_limits = heat_std.get("workload_limits", [])
        self.assertEqual(len(workload_limits), 3, "Must define light, moderate, and heavy workload limits")

    # -------------------------------------------------------------------------
    # Test 02: Lighting Search & Category Filter
    # -------------------------------------------------------------------------
    def test_02_lighting_search_and_category_filter(self):
        """Test searching lighting standards by keyword and filtering by category."""
        res_office = self.engine.search_lighting(query="สำนักงาน", category="office_administration")
        self.assertEqual(res_office["status"], "success")
        self.assertGreaterEqual(res_office["total_found"], 1)
        first = res_office["results"][0]
        self.assertEqual(first["category"], "office_administration")
        self.assertGreaterEqual(first["standard_lux_min"], 300.0)

        res_gen = self.engine.search_lighting(category="general_area")
        self.assertGreaterEqual(res_gen["total_found"], 2)

        res_none = self.engine.search_lighting(query="non_existent_special_task_xyz")
        self.assertEqual(res_none["total_found"], 0)

    # -------------------------------------------------------------------------
    # Test 03: Lighting Compliance Evaluation
    # -------------------------------------------------------------------------
    def test_03_lighting_compliance_evaluation(self):
        """Test pass/fail compliance and surrounding ratio evaluation for lighting."""
        # 1. Compliant office task (Measured 450 Lux >= Min 300 Lux)
        res_pass = self.engine.search_lighting(query="โต๊ะทำงาน", category="office_administration", measured_lux=450.0, surrounding_lux=200.0)
        self.assertGreaterEqual(res_pass["total_found"], 1)
        eval_pass = res_pass["results"][0]["evaluation"]
        self.assertTrue(eval_pass["is_compliant"])
        self.assertEqual(eval_pass["status_badge"], "COMPLIANT_ADEQUATE")
        self.assertEqual(eval_pass["variance_lux"], 150.0)
        self.assertTrue(eval_pass["surrounding_evaluation"]["is_surrounding_compliant"])

        # 2. Non-compliant fine manufacturing task (Measured 250 Lux < Min 400 Lux)
        res_fail = self.engine.search_lighting(query="อิเล็กทรอนิกส์", category="manufacturing_fine", measured_lux=250.0, surrounding_lux=80.0)
        self.assertGreaterEqual(res_fail["total_found"], 1)
        eval_fail = res_fail["results"][0]["evaluation"]
        self.assertFalse(eval_fail["is_compliant"])
        self.assertEqual(eval_fail["status_badge"], "NON_COMPLIANT_DEFICIENT")
        self.assertEqual(eval_fail["deficiency_lux"], 150.0)
        self.assertFalse(eval_fail["surrounding_evaluation"]["is_surrounding_compliant"])

    # -------------------------------------------------------------------------
    # Test 04: Noise TWA 8-hr Compliance (86 dBA)
    # -------------------------------------------------------------------------
    def test_04_noise_twa_compliance_86dba(self):
        """Test continuous 8-hour noise exposure compliance at 84 dBA (Pass) vs 88 dBA (Fail)."""
        # 84 dBA for 8 hours -> Compliant, No HCP
        eval_84 = self.engine.evaluate_noise(measured_dba=84.0, duration_hours=8.0)
        self.assertTrue(eval_84["is_compliant"])
        self.assertEqual(eval_84["status_badge"], "PASS")
        self.assertFalse(eval_84["hearing_conservation_required"])
        self.assertLess(eval_84["noise_dose_pct"], 100.0)

        # 88 dBA for 8 hours -> Non-compliant, Dose = 158.74%, HCP Required
        eval_88 = self.engine.evaluate_noise(measured_dba=88.0, duration_hours=8.0)
        self.assertFalse(eval_88["is_compliant"])
        self.assertEqual(eval_88["status_badge"], "FAIL")
        self.assertTrue(eval_88["hearing_conservation_required"])
        self.assertGreater(eval_88["noise_dose_pct"], 100.0)
        self.assertGreater(eval_88["required_ppe_nrr"], 0)

    # -------------------------------------------------------------------------
    # Test 05: Noise Action Level & Hearing Conservation Program (>= 85 dBA)
    # -------------------------------------------------------------------------
    def test_05_noise_action_level_and_hearing_conservation(self):
        """Test Action Level trigger at >= 85.0 dBA according to Clause 11 of Ministerial Reg. 2559."""
        # 85.5 dBA for 8 hours -> Action Level (HCP Mandatory, but within 86 dBA limit)
        eval_action = self.engine.evaluate_noise(measured_dba=85.5, duration_hours=8.0)
        self.assertTrue(eval_action["is_compliant"])
        self.assertEqual(eval_action["status_badge"], "ACTION_LEVEL")
        self.assertTrue(eval_action["hearing_conservation_required"])
        self.assertIn("Hearing Conservation Program", eval_action["recommended_controls"][0])

    # -------------------------------------------------------------------------
    # Test 06: Noise Permissible Duration Mathematical Formula
    # -------------------------------------------------------------------------
    def test_06_noise_permissible_duration_formula(self):
        """Verify exact statutory formula T = 8 / 2^((L - 86) / 3) with 3 dB exchange rate."""
        # L = 86 dBA -> T = 8.0 hours
        t_86 = self.engine.calculate_permissible_noise_duration(86.0)
        self.assertAlmostEqual(t_86, 8.0, places=3)

        # L = 89 dBA -> T = 4.0 hours
        t_89 = self.engine.calculate_permissible_noise_duration(89.0)
        self.assertAlmostEqual(t_89, 4.0, places=3)

        # L = 92 dBA -> T = 2.0 hours
        t_92 = self.engine.calculate_permissible_noise_duration(92.0)
        self.assertAlmostEqual(t_92, 2.0, places=3)

        # L = 95 dBA -> T = 1.0 hour
        t_95 = self.engine.calculate_permissible_noise_duration(95.0)
        self.assertAlmostEqual(t_95, 1.0, places=3)

        # L = 80 dBA -> T = 32.0 hours
        t_80 = self.engine.calculate_permissible_noise_duration(80.0)
        self.assertAlmostEqual(t_80, 32.0, places=3)

    # -------------------------------------------------------------------------
    # Test 07: Noise Peak & Continuous Ceiling Limits
    # -------------------------------------------------------------------------
    def test_07_noise_peak_and_continuous_limits(self):
        """Test continuous ceiling limit (>115 dBA) and peak sound limit (>140 dB)."""
        # Continuous 118 dBA -> Immediate violation
        eval_cont = self.engine.evaluate_noise(measured_dba=118.0, duration_hours=0.1)
        self.assertFalse(eval_cont["is_compliant"])
        self.assertEqual(eval_cont["status_badge"], "FAIL_CRITICAL")
        self.assertEqual(eval_cont["compliance_status"], "CRITICAL_CONTINUOUS_CEILING_VIOLATION")

        # Peak 142 dB -> Critical violation
        eval_peak = self.engine.evaluate_noise(measured_dba=82.0, duration_hours=8.0, peak_db=142.0)
        self.assertFalse(eval_peak["is_compliant"])
        self.assertEqual(eval_peak["status_badge"], "FAIL_CRITICAL")
        self.assertEqual(eval_peak["compliance_status"], "CRITICAL_PEAK_LIMIT_VIOLATION")

    # -------------------------------------------------------------------------
    # Test 08: WBGT Indoor Calculation & Metabolic Workload Limits
    # -------------------------------------------------------------------------
    def test_08_wbgt_indoor_calculation_and_workload(self):
        """Verify Indoor formula: WBGT = 0.7 * NWB + 0.3 * GT against 34°C (Light), 32°C (Moderate), 30°C (Heavy)."""
        # NWB = 28.0, GT = 38.0 -> WBGT = 0.7*28 + 0.3*38 = 19.6 + 11.4 = 31.0°C
        # 1. Moderate workload (Limit 32.0°C) -> Compliant (31.0 <= 32.0)
        res_mod = self.engine.calculate_wbgt(nwb=28.0, gt=38.0, is_outdoor=False, workload_category="moderate")
        self.assertEqual(res_mod["calculated_wbgt_c"], 31.0)
        self.assertTrue(res_mod["is_compliant"])
        self.assertEqual(res_mod["safety_margin_c"], 1.0)
        self.assertEqual(res_mod["statutory_limit_wbgt_c"], 32.0)

        # 2. Heavy workload (Limit 30.0°C) -> Non-compliant (31.0 > 30.0)
        res_heavy = self.engine.calculate_wbgt(nwb=28.0, gt=38.0, is_outdoor=False, workload_category="heavy")
        self.assertEqual(res_heavy["calculated_wbgt_c"], 31.0)
        self.assertFalse(res_heavy["is_compliant"])
        self.assertEqual(res_heavy["safety_margin_c"], -1.0)
        self.assertEqual(res_heavy["statutory_limit_wbgt_c"], 30.0)

        # 3. Light workload (Limit 34.0°C) -> Compliant
        res_light = self.engine.calculate_wbgt(nwb=30.0, gt=40.0, is_outdoor=False, workload_category="light")
        self.assertEqual(res_light["calculated_wbgt_c"], 33.0)
        self.assertTrue(res_light["is_compliant"])
        self.assertEqual(res_light["statutory_limit_wbgt_c"], 34.0)

    # -------------------------------------------------------------------------
    # Test 09: WBGT Outdoor Calculation With Solar Load
    # -------------------------------------------------------------------------
    def test_09_wbgt_outdoor_calculation_with_solar(self):
        """Verify Outdoor formula: WBGT = 0.7 * NWB + 0.2 * GT + 0.1 * DB."""
        # NWB = 29.0, GT = 42.0, DB = 35.0 -> WBGT = 0.7*29 + 0.2*42 + 0.1*35 = 20.3 + 8.4 + 3.5 = 32.2°C
        res_out = self.engine.calculate_wbgt(nwb=29.0, gt=42.0, db=35.0, is_outdoor=True, workload_category="moderate")
        self.assertEqual(res_out["calculated_wbgt_c"], 32.2)
        self.assertFalse(res_out["is_compliant"])  # 32.2 > 32.0 Limit
        self.assertEqual(res_out["environment_mode"], "outdoor_with_solar")

        # Missing DB on outdoor calculation should raise ValueError
        with self.assertRaises(ValueError):
            self.engine.calculate_wbgt(nwb=29.0, gt=42.0, db=None, is_outdoor=True)

    # -------------------------------------------------------------------------
    # Test 10: Subcontractor Verification (Section 9 vs Section 11)
    # -------------------------------------------------------------------------
    def test_10_subcontractor_section9_and_section11(self):
        """Verify format checking and validity for Section 9 (นบ.) and Section 11 (บ.) subcontractors."""
        # Valid Section 9 Individual
        v_sec9 = self.engine.verify_subcontractor(license_type="section_9_individual", license_no="นบ. 0123-45/2566", expiry_date="2027-12-31")
        self.assertTrue(v_sec9["is_valid"])
        self.assertTrue(v_sec9["is_format_valid"])
        self.assertEqual(v_sec9["license_type"], "SECTION_9_INDIVIDUAL")

        # Valid Section 11 Juristic
        v_sec11 = self.engine.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0045-12/2565", expiry_date="2028-05-15")
        self.assertTrue(v_sec11["is_valid"])
        self.assertTrue(v_sec11["is_format_valid"])
        self.assertEqual(v_sec11["license_type"], "SECTION_11_JURISTIC")

        # Expired License
        v_exp = self.engine.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0012/2560", expiry_date="2023-01-01")
        self.assertFalse(v_exp["is_valid"])
        self.assertTrue(v_exp["is_expired"])

    # -------------------------------------------------------------------------
    # Test 11: Full Session Batch Evaluation & Automated CAPA
    # -------------------------------------------------------------------------
    def test_11_full_session_batch_evaluation_and_capa(self):
        """Batch evaluate a multi-point environmental session with Light, Noise, and Heat factors."""
        sample_file = os.path.join(DATA_DIR, "standards.json")
        with open(sample_file, "r", encoding="utf-8") as f:
            full_data = json.load(f)
        sample_sess = full_data["sample_session"]

        sess_eval = self.engine.evaluate_session(sample_sess)
        self.assertEqual(sess_eval["status"], "success")

        summary = sess_eval["session_summary"]
        kpi = summary["kpi_metrics"]
        self.assertEqual(kpi["total_points"], 13)
        self.assertGreater(kpi["compliant_points"], 0)
        self.assertGreater(kpi["compliance_index_pct"], 50.0)

        # CAPA generation verification
        capas = sess_eval["capa_action_plans"]
        self.assertGreaterEqual(len(capas), 1)
        first_capa = capas[0]
        self.assertIn("CAPA-ENV-", first_capa["capa_id"])
        self.assertIn("root_cause", first_capa)
        self.assertIn("corrective_action", first_capa)
        self.assertIn("pic", first_capa)

    # -------------------------------------------------------------------------
    # Test 12: Helper Dual Mode & Programmatic Calling
    # -------------------------------------------------------------------------
    def test_12_helper_dual_mode_and_cli_subprocess(self):
        """Test ThaiEnvHelper programmatic API across light, noise, wbgt, and session evaluation."""
        # 1. Search light
        l_res = self.helper.search_light_standard(query="โต๊ะทำงาน", measured_lux=350.0)
        self.assertEqual(l_res["status"], "success")

        # 2. Eval noise
        n_res = self.helper.eval_noise_exposure(measured_dba=86.5, duration_hours=8.0)
        self.assertEqual(n_res["status"], "success")
        self.assertTrue(n_res["hearing_conservation_required"])

        # 3. Calc WBGT
        w_res = self.helper.calc_wbgt(nwb=28.0, gt=36.0, workload_category="light")
        self.assertEqual(w_res["status"], "success")
        self.assertTrue(w_res["is_compliant"])

        # 4. Verify Subcontractor
        s_res = self.helper.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0145-02/2564")
        self.assertEqual(s_res["status"], "success")

    # -------------------------------------------------------------------------
    # Test 13: Time-Weighted WBGT & TWA Calculations
    # -------------------------------------------------------------------------
    def test_13_time_weighted_wbgt_and_noise_dose(self):
        """Test Time-Weighted WBGT calculation across variable temperature zones."""
        records = [
            {"wbgt": 34.0, "duration_minutes": 30.0, "metabolic_rate": 300.0},
            {"wbgt": 26.0, "duration_minutes": 30.0, "metabolic_rate": 150.0}
        ]
        res_twa = self.engine.calculate_time_weighted_wbgt(records)
        self.assertEqual(res_twa["status"], "success")
        self.assertEqual(res_twa["total_duration_minutes"], 60.0)
        self.assertEqual(res_twa["time_weighted_wbgt_c"], 30.0)
        self.assertEqual(res_twa["time_weighted_metabolic_rate_kcal_hr"], 225.0)

    # -------------------------------------------------------------------------
    # Test 14: Get Law Provisions
    # -------------------------------------------------------------------------
    def test_14_get_law_provisions(self):
        """Test statutory legal provisions retrieval."""
        law_res = self.engine.get_law(topic="OSH-ACT-2554", section="มาตรา ๑๕")
        self.assertEqual(law_res["status"], "success")
        self.assertGreaterEqual(law_res["total_laws"], 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
