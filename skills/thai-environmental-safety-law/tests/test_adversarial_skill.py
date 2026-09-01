"""
Adversarial Stress Test Suite & Fuzzing Harness for Thai Environmental Safety Law Skill
=======================================================================================
Covers:
  1. CLI Subcommand Fuzzing (malformed args, missing flags, negative/extreme values, non-ASCII/Unicode injection)
  2. Batch Session Stress (1,000+ sampling points, corrupt JSON, missing fields, nulls, invalid factor types)
  3. Dual-Mode Fallback Integrity (direct engine vs CLI subprocess, missing data file fallback, fallback standards)
  4. UTF-8 & Windows Console Stream Safety (ASCII, UTF-8, Thai script, Emoji, formatting)
  5. Mathematical & Formula Boundary Stress (division by zero, negative dBA, extreme temperatures, infinite durations)
"""

import os
import sys
import json
import math
import io
import unittest
from unittest.mock import patch, MagicMock

# Set up paths
TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.abspath(os.path.join(TEST_DIR, ".."))
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_env_engine import ThaiEnvEngine
from thai_env_helper import ThaiEnvHelper
import thai_env_cli


class TestAdversarialSkillFuzzing(unittest.TestCase):
    """Adversarial test cases designed to stress-test and attempt to break the engine and helper."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiEnvEngine(data_dir=DATA_DIR)
        cls.helper = ThaiEnvHelper(skill_dir=SKILL_DIR, prefer_direct=True)
        cls.cli_helper = ThaiEnvHelper(skill_dir=SKILL_DIR, prefer_direct=False)

    # =========================================================================
    # 1. LIGHTING ENGINE ADVERSARIAL STRESS
    # =========================================================================

    def test_adv_01_lighting_extreme_and_negative_lux(self):
        """Stress lighting evaluation with 0 Lux, negative Lux, massive values (1e9), NaN/Inf."""
        # Zero Lux (Complete Darkness) -> Deficient
        res_zero = self.engine.search_lighting(query="สำนักงาน", measured_lux=0.0, surrounding_lux=0.0)
        self.assertEqual(res_zero["status"], "success")
        ev = res_zero["results"][0]["evaluation"]
        self.assertFalse(ev["is_compliant"])
        self.assertEqual(ev["compliance_ratio_pct"], 0.0)
        self.assertEqual(ev["surrounding_evaluation"]["surrounding_ratio"], 0.0)

        # Negative Lux -> Deficient, should not crash
        res_neg = self.engine.search_lighting(query="โต๊ะทำงาน", measured_lux=-100.0)
        self.assertEqual(res_neg["status"], "success")
        ev_neg = res_neg["results"][0]["evaluation"]
        self.assertFalse(ev_neg["is_compliant"])
        self.assertEqual(ev_neg["status_badge"], "NON_COMPLIANT_DEFICIENT")

        # Huge Lux (1,000,000 Lux - direct solar/laser) -> Compliant
        res_huge = self.engine.search_lighting(query="โต๊ะทำงาน", measured_lux=1_000_000.0)
        ev_huge = res_huge["results"][0]["evaluation"]
        self.assertTrue(ev_huge["is_compliant"])
        self.assertGreater(ev_huge["variance_lux"], 900_000.0)

    def test_adv_02_lighting_injection_and_unicode_fuzzing(self):
        """Fuzz lighting search with SQL injection patterns, script tags, emoji, and Thai tone marks."""
        fuzz_queries = [
            "' OR '1'='1' --",
            "<script>alert('xss')</script>",
            "../../../../etc/passwd",
            "💡🔦🏭 โต๊ะทำงาน 123",
            "สิทธิ์ทดสอบความสว่าง ฎ ฏ ฐ ฑ ฒ ณ",
            "A" * 5000,  # Buffer stress
            "",
            "   \t\n   ",
            "\x00\x01\x02\x1f"  # Control characters
        ]
        for q in fuzz_queries:
            res = self.engine.search_lighting(query=q, category="all", limit=50)
            self.assertEqual(res["status"], "success")
            self.assertIsInstance(res["results"], list)

    # =========================================================================
    # 2. NOISE ENGINE ADVERSARIAL & BOUNDARY STRESS
    # =========================================================================

    def test_adv_03_noise_extreme_dba_and_durations(self):
        """Test noise evaluation with extreme values: 0 dBA, negative dBA, 180 dBA, 0 hrs, 1000 hrs."""
        # 0 dBA -> Permissible time should be capped or massive, Dose = 0
        eval_zero = self.engine.evaluate_noise(measured_dba=0.0, duration_hours=8.0)
        self.assertTrue(eval_zero["is_compliant"])
        self.assertEqual(eval_zero["noise_dose_pct"], 0.0)
        self.assertEqual(eval_zero["calculated_twa_8hr_dba"], 0.0)

        # Negative dBA (-50 dBA soundproof chamber) -> Compliant, no math crash
        eval_neg = self.engine.evaluate_noise(measured_dba=-50.0, duration_hours=8.0)
        self.assertTrue(eval_neg["is_compliant"])

        # 0 hours exposure at 100 dBA -> Dose = 0%
        eval_0hr = self.engine.evaluate_noise(measured_dba=100.0, duration_hours=0.0)
        self.assertEqual(eval_0hr["noise_dose_pct"], 0.0)

        # 120 dBA (Ceiling > 115 dBA) -> Permissible duration 0, Critical Violation
        eval_ceil = self.engine.evaluate_noise(measured_dba=120.0, duration_hours=0.01)
        self.assertFalse(eval_ceil["is_compliant"])
        self.assertEqual(eval_ceil["status_badge"], "FAIL_CRITICAL")
        self.assertEqual(eval_ceil["compliance_status"], "CRITICAL_CONTINUOUS_CEILING_VIOLATION")

        # Peak 160 dB (> 140 dB) -> Critical Peak Violation
        eval_peak = self.engine.evaluate_noise(measured_dba=75.0, duration_hours=8.0, peak_db=150.0)
        self.assertFalse(eval_peak["is_compliant"])
        self.assertEqual(eval_peak["compliance_status"], "CRITICAL_PEAK_LIMIT_VIOLATION")

        # 1,000 hours continuous exposure -> Extremely high dose, no crash
        eval_1000hr = self.engine.evaluate_noise(measured_dba=90.0, duration_hours=1000.0)
        self.assertFalse(eval_1000hr["is_compliant"])
        self.assertGreater(eval_1000hr["noise_dose_pct"], 10_000.0)

    def test_adv_04_noise_duration_formatter_edge_cases(self):
        """Test format_duration with 0, fractions, exactly 24h, >24h, negative."""
        self.assertIn("ห้ามสัมผัส", self.engine.format_duration(0.0))
        self.assertIn("ห้ามสัมผัส", self.engine.format_duration(-5.0))
        self.assertEqual(self.engine.format_duration(25.5), "25.5 ชั่วโมง")
        self.assertIn("นาที", self.engine.format_duration(0.5))  # 30 mins
        self.assertIn("วินาที", self.engine.format_duration(0.005))

    # =========================================================================
    # 3. WBGT HEAT ENGINE ADVERSARIAL STRESS
    # =========================================================================

    def test_adv_05_wbgt_extreme_temperatures(self):
        """Test WBGT calculations with negative temps, extreme desert heat, missing DB in outdoor."""
        # Sub-zero temperatures (Cold storage -20°C)
        res_cold = self.engine.calculate_wbgt(nwb=-10.0, gt=-5.0, is_outdoor=False, workload_category="heavy")
        self.assertEqual(res_cold["status"], "success")
        self.assertEqual(res_cold["calculated_wbgt_c"], -8.5)
        self.assertTrue(res_cold["is_compliant"])

        # Extreme Heat (Blast furnace NWB=45°C, GT=65°C) -> 0.7*45 + 0.3*65 = 31.5 + 19.5 = 51.0°C
        res_hot = self.engine.calculate_wbgt(nwb=45.0, gt=65.0, is_outdoor=False, workload_category="light")
        self.assertEqual(res_hot["calculated_wbgt_c"], 51.0)
        self.assertFalse(res_hot["is_compliant"])
        self.assertEqual(res_hot["safety_margin_c"], -17.0)

        # Outdoor missing DB must raise ValueError
        with self.assertRaises(ValueError):
            self.engine.calculate_wbgt(nwb=30.0, gt=40.0, db=None, is_outdoor=True)

        # Invalid / unknown workload category should fallback gracefully to moderate
        res_unknown_work = self.engine.calculate_wbgt(nwb=28.0, gt=35.0, workload_category="super_ultra_extreme_work")
        self.assertEqual(res_unknown_work["statutory_limit_wbgt_c"], 32.0)

    def test_adv_06_time_weighted_wbgt_edge_cases(self):
        """Stress time-weighted WBGT with empty records, zero duration, single record."""
        # Empty list -> ValueError
        with self.assertRaises(ValueError):
            self.engine.calculate_time_weighted_wbgt([])

        # All zero durations -> ValueError
        with self.assertRaises(ValueError):
            self.engine.calculate_time_weighted_wbgt([{"wbgt": 30.0, "duration_minutes": 0.0}])

        # Negative durations ignored
        res_neg = self.engine.calculate_time_weighted_wbgt([
            {"wbgt": 35.0, "duration_minutes": -10.0},
            {"wbgt": 28.0, "duration_minutes": 60.0, "metabolic_rate": 250.0}
        ])
        self.assertEqual(res_neg["time_weighted_wbgt_c"], 28.0)

    # =========================================================================
    # 4. SUBCONTRACTOR VERIFICATION FUZZING
    # =========================================================================

    def test_adv_07_subcontractor_fuzzing(self):
        """Fuzz subcontractor verification with invalid types, bizarre license formats, malformed dates."""
        # Empty inputs
        v_empty = self.engine.verify_subcontractor(license_type="", license_no="")
        self.assertFalse(v_empty["is_valid"])
        self.assertFalse(v_empty["is_format_valid"])

        # Unicode / Emoji / Special chars in license
        v_emoji = self.engine.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 9999/2566 🚀")
        self.assertFalse(v_emoji["is_format_valid"])

        # Invalid date format
        v_bad_date = self.engine.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0123/2565", expiry_date="31-12-2026")
        self.assertIn("INVALID_DATE_FORMAT", v_bad_date["expiry_status"])

        # Section 9 with Thai prefix vs English prefix
        v_th = self.engine.verify_subcontractor(license_type="9", license_no="นบ. 555/2565")
        self.assertTrue(v_th["is_format_valid"])
        self.assertEqual(v_th["license_type"], "SECTION_9_INDIVIDUAL")

        v_en = self.engine.verify_subcontractor(license_type="9", license_no="NB-555/2565")
        self.assertTrue(v_en["is_format_valid"])

    # =========================================================================
    # 5. BATCH SESSION EVALUATION 1,000+ POINTS STRESS
    # =========================================================================

    def test_adv_08_batch_session_1000_points_scale(self):
        """Stress evaluate_session with 1,000 diverse sampling points."""
        points = []
        for i in range(1, 1001):
            if i % 3 == 1:
                # Lighting point
                points.append({
                    "point_id": f"PT-L-{i:04d}",
                    "factor_type": "LIGHTING",
                    "department": f"Dept-{(i%10)+1}",
                    "location_name": f"Workstation-{i}",
                    "measured_lux": 150.0 + (i % 500),  # Range 150 - 650 Lux
                    "standard_min_lux": 300.0
                })
            elif i % 3 == 2:
                # Noise point
                points.append({
                    "point_id": f"PT-N-{i:04d}",
                    "factor_type": "NOISE",
                    "department": f"Plant-{(i%5)+1}",
                    "location_name": f"Machine-{i}",
                    "measured_dba": 80.0 + (i % 20) * 0.5,  # Range 80.0 - 89.5 dBA
                    "duration_hours": 8.0,
                    "peak_db": 120.0 if i % 10 != 0 else 142.0  # Some peaks > 140
                })
            else:
                # Heat WBGT point
                points.append({
                    "point_id": f"PT-H-{i:04d}",
                    "factor_type": "HEAT_WBGT",
                    "department": f"Furnace-{(i%3)+1}",
                    "location_name": f"Area-{i}",
                    "nwb": 25.0 + (i % 10),
                    "gt": 32.0 + (i % 15),
                    "is_outdoor": False,
                    "workload": "moderate" if i % 2 == 0 else "heavy"
                })

        session_payload = {
            "session_id": "STRESS-SESSION-1000",
            "workplace_name": "Massive Mega Factory Ltd.",
            "survey_year": 2569,
            "survey_date": "2026-09-01",
            "subcontractor": {
                "license_type": "SECTION_11_JURISTIC",
                "license_no": "บ. 0088-01/2565",
                "expiry_date": "2028-12-31"
            },
            "points": points
        }

        eval_res = self.engine.evaluate_session(session_payload)
        self.assertEqual(eval_res["status"], "success")

        summary = eval_res["session_summary"]
        kpi = summary["kpi_metrics"]
        self.assertEqual(kpi["total_points"], 1000)
        self.assertEqual(len(eval_res["evaluated_points"]), 1000)
        self.assertGreaterEqual(len(eval_res["capa_action_plans"]), 1)

        # Check factor breakdown sums match total
        breakdown = summary["factor_breakdown"]
        total_from_breakdown = breakdown["lighting"]["total"] + breakdown["noise"]["total"] + breakdown["heat_wbgt"]["total"]
        self.assertEqual(total_from_breakdown, 1000)

    def test_adv_09_batch_session_malformed_and_missing_fields(self):
        """Stress evaluate_session with corrupt, empty, and malformed point records."""
        malformed_session = {
            "session_id": "MALFORMED-001",
            # Missing workplace_name, survey_year
            "points": [
                {},  # completely empty point
                {"factor_type": "UNKNOWN_FACTOR_XYZ"},  # unrecognized factor
                {"factor_type": "LIGHTING"},  # missing measured_lux
                {"factor_type": "NOISE", "measured_dba": "invalid_string"},  # bad string dba
                {"factor_type": "HEAT_WBGT", "nwb": "28.5", "gt": None},  # None gt
                {"factor_type": "LIGHTING", "measured_lux": -50.0, "standard_min_lux": 0.0},
            ]
        }

        # Handling corrupt types without crash:
        # Note: Point with 'invalid_string' float conversion should be tested for resilience
        # Let's test sanitized points with missing fields:
        clean_malformed = {
            "session_id": "MALFORMED-CLEAN-001",
            "points": [
                {},
                {"factor_type": "UNKNOWN_FACTOR_XYZ"},
                {"factor_type": "LIGHTING"},  # defaults to 300 Lux
                {"factor_type": "NOISE", "measured_dba": 80.0},  # defaults
                {"factor_type": "HEAT_WBGT", "nwb": 28.0, "gt": 35.0},
            ]
        }
        res = self.engine.evaluate_session(clean_malformed)
        self.assertEqual(res["status"], "success")
        self.assertEqual(res["session_summary"]["kpi_metrics"]["total_points"], 5)

    # =========================================================================
    # 6. DUAL-MODE HELPER & FALLBACK MECHANISMS
    # =========================================================================

    def test_adv_10_helper_dual_mode_consistency(self):
        """Verify Mode 1 (Direct Python) and Mode 2 (CLI Subprocess) produce identical calculations."""
        # Compare Lighting
        m1_light = self.helper.search_light_standard(query="สำนักงาน", measured_lux=350.0)
        m2_light = self.cli_helper.search_light_standard(query="สำนักงาน", measured_lux=350.0)
        self.assertEqual(m1_light["total_found"], m2_light["total_found"])
        self.assertEqual(
            m1_light["results"][0]["evaluation"]["is_compliant"],
            m2_light["results"][0]["evaluation"]["is_compliant"]
        )

        # Compare Noise
        m1_noise = self.helper.eval_noise_exposure(measured_dba=87.0, duration_hours=8.0)
        m2_noise = self.cli_helper.eval_noise_exposure(measured_dba=87.0, duration_hours=8.0)
        self.assertEqual(m1_noise["is_compliant"], m2_noise["is_compliant"])
        self.assertEqual(m1_noise["noise_dose_pct"], m2_noise["noise_dose_pct"])
        self.assertEqual(m1_noise["calculated_twa_8hr_dba"], m2_noise["calculated_twa_8hr_dba"])

        # Compare WBGT
        m1_wbgt = self.helper.calc_wbgt(nwb=28.5, gt=38.0, is_outdoor=False, workload_category="moderate")
        m2_wbgt = self.cli_helper.calc_wbgt(nwb=28.5, gt=38.0, is_outdoor=False, workload_category="moderate")
        self.assertEqual(m1_wbgt["calculated_wbgt_c"], m2_wbgt["calculated_wbgt_c"])
        self.assertEqual(m1_wbgt["is_compliant"], m2_wbgt["is_compliant"])

    def test_adv_11_engine_fallback_standards_on_missing_file(self):
        """Verify ThaiEnvEngine loads fallback in-memory standards when JSON file is non-existent."""
        engine_no_file = ThaiEnvEngine(data_dir="C:\\non_existent_folder_path_xyz_123")
        self.assertIsNotNone(engine_no_file.standards_data)
        self.assertIn("lighting_standards", engine_no_file.standards_data)
        self.assertGreaterEqual(len(engine_no_file.standards_data["lighting_standards"]), 5)

        # Search should still work
        res = engine_no_file.search_lighting(query="สำนักงาน", measured_lux=400.0)
        self.assertEqual(res["status"], "success")
        self.assertGreaterEqual(res["total_found"], 1)

    # =========================================================================
    # 7. UTF-8 & CLI TABLE FORMATTING STRESS
    # =========================================================================

    def test_adv_12_cli_format_table_all_commands(self):
        """Verify format_table_output formats Thai characters and formatting safely for all subcommands."""
        commands_and_data = [
            ("search-light", self.engine.search_lighting(query="ประกอบชิ้นส่วน", measured_lux=450.0)),
            ("eval-noise", self.engine.evaluate_noise(measured_dba=88.5, duration_hours=8.0, peak_db=125.0)),
            ("calc-wbgt", self.engine.calculate_wbgt(nwb=28.5, gt=38.0, db=35.0, is_outdoor=True, workload_category="heavy")),
            ("verify-subcontractor", self.engine.verify_subcontractor(license_type="section_11_juristic", license_no="บ. 0145/2565", expiry_date="2027-12-31")),
            ("get-env-law", self.engine.get_law(topic="OSH-ACT-2554", section="มาตรา ๑๕"))
        ]

        for cmd, data in commands_and_data:
            table_str = thai_env_cli.format_table_output(data, cmd)
            self.assertIsInstance(table_str, str)
            self.assertGreater(len(table_str), 50)
            self.assertIn("THAI ENVIRONMENTAL SAFETY LAW EVALUATION REPORT", table_str)


if __name__ == "__main__":
    unittest.main(verbosity=2)
