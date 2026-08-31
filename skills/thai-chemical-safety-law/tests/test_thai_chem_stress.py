"""
Empirical Stress and Adversarial Test Suite for Thai Chemical Safety Law Skill
Tests CLI robustness, Thai character encoding, JSON schema validity,
SDS 16-section validator edge cases, and mixture/unit conversion physics.
"""

import os
import sys
import json
import unittest
import io

TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(TEST_DIR)
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_chem_law import ThaiChemLawEngine
from sds_validator import SDSValidator
from thai_chem_helper import ThaiChemLawHelper


class TestThaiChemicalStress(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiChemLawEngine(data_dir=DATA_DIR)
        cls.validator = SDSValidator(cls.engine)
        cls.helper = ThaiChemLawHelper(skill_dir=SKILL_DIR)

    # -------------------------------------------------------------------------
    # 1. CLI COMMAND & SEARCH ROBUSTNESS
    # -------------------------------------------------------------------------
    def test_01_empty_and_whitespace_search(self):
        """Empty or whitespace-only search should return clean error JSON without crashing."""
        res_empty = self.engine.search_chemical("")
        self.assertEqual(res_empty["status"], "error")
        self.assertEqual(res_empty["total_found"], 0)
        self.assertIn("cannot be empty", res_empty["message"])

        res_spaces = self.engine.search_chemical("   \t\n  ")
        self.assertEqual(res_spaces["status"], "error")
        self.assertEqual(res_spaces["total_found"], 0)

    def test_02_unlisted_chemical_search(self):
        """Searching for non-existent chemical returns empty results with success status."""
        res = self.engine.search_chemical("Unobtainium_9999_Fake_Chemical")
        self.assertEqual(res["status"], "success")
        self.assertEqual(res["total_found"], 0)
        self.assertEqual(len(res["results"]), 0)

    def test_03_invalid_cas_numbers(self):
        """Invalid CAS formats and non-existent CAS numbers should not raise exceptions."""
        res_fake_cas = self.engine.search_chemical("9999999-99-9")
        self.assertEqual(res_fake_cas["status"], "success")
        self.assertEqual(res_fake_cas["total_found"], 0)

        res_malformed = self.engine.search_chemical("CAS-INVALID-FORMAT-###")
        self.assertEqual(res_malformed["status"], "success")
        self.assertEqual(res_malformed["total_found"], 0)

    def test_04_special_characters_and_injection_resilience(self):
        """Queries with special regex or SQL-like chars do not trigger exceptions."""
        special_queries = [
            "Toluene' OR '1'='1",
            "Benzene.*+?^${}()|[]\\",
            "Acid (HCl) [37%]",
            "<script>alert(1)</script>",
            "None",
            "null",
            "0"
        ]
        for q in special_queries:
            res = self.engine.search_chemical(q)
            self.assertIn("status", res)
            self.assertIn("total_found", res)
            self.assertIsInstance(res["results"], list)

    def test_05_search_limit_handling(self):
        """Search limit parameter enforces maximum number of returned items."""
        res_lim3 = self.engine.search_chemical("acid", limit=3)
        self.assertEqual(res_lim3["status"], "success")
        self.assertLessEqual(len(res_lim3["results"]), 3)
        self.assertLessEqual(res_lim3["returned_count"], 3)

        res_lim0 = self.engine.search_chemical("acid", limit=0)
        self.assertEqual(len(res_lim0["results"]), 0)

    # -------------------------------------------------------------------------
    # 2. CHARACTER ENCODING & THAI UNICODE ROBUSTNESS
    # -------------------------------------------------------------------------
    def test_06_thai_tone_marks_and_vowels(self):
        """Search chemicals with complex Thai tone marks and stacked vowels."""
        thai_terms = [
            ("กรดไฮโดรคลอริก", "7647-01-0"),
            ("เบนซีน", "71-43-2"),
            ("โทลูอีน", "108-88-3"),
            ("แอมโมเนีย", "7664-41-7"),
            ("กรดกำมะถัน", "7664-93-9"),
            ("ไดคลอโรมีเทน", "75-09-2"),
            ("เตตระไฮโดรฟิวแรน", "109-99-9"),
            ("ฟอร์มาลดีไฮด์", "50-00-0"),
            ("โซเดียมไฮดรอกไซด์", "1310-73-2"),
            ("ด่างทับทิม", "7722-64-7")
        ]

        for item in thai_terms:
            query = item[0]
            expected_cas = item[1]
            res = self.engine.search_chemical(query)
            self.assertEqual(res["status"], "success", f"Failed searching for Thai term: {query}")
            self.assertGreaterEqual(res["total_found"], 1, f"No match for Thai query: {query}")
            # Ensure Thai text is preserved without encoding corruptions
            top_name_th = res["results"][0]["name_th"]
            self.assertTrue(len(top_name_th) > 0)
            self.assertTrue(any('\u0e00' <= char <= '\u0e7f' for char in top_name_th), f"Expected Thai chars in: {top_name_th}")

    def test_07_mixed_thai_english_queries(self):
        """Search chemicals with mixed Thai and English names."""
        res_mixed1 = self.engine.search_chemical("Toluene (เมทิลเบนซีน)")
        self.assertEqual(res_mixed1["status"], "success")
        self.assertGreaterEqual(res_mixed1["total_found"], 1)
        self.assertEqual(res_mixed1["results"][0]["cas_no"], "108-88-3")

        res_mixed2 = self.engine.search_chemical("Acetone โพรพาโนน")
        self.assertEqual(res_mixed2["status"], "success")

    def test_08_json_serialization_utf8(self):
        """JSON serialization preserves Thai characters with ensure_ascii=False."""
        sample_data = self.engine.search_chemical("โทลูอีน", limit=1)
        json_str = json.dumps(sample_data, ensure_ascii=False)
        self.assertIn("โทลูอีน", json_str)
        self.assertNotIn("\\u0e42", json_str, "Thai characters must not be escaped when ensure_ascii=False")

        # Parsing back must be identical
        parsed = json.loads(json_str)
        self.assertEqual(parsed["results"][0]["name_th"], sample_data["results"][0]["name_th"])

    # -------------------------------------------------------------------------
    # 3. TLV THRESHOLD LIMIT VALUES & BOUNDARY CONDITIONS
    # -------------------------------------------------------------------------
    def test_09_tlv_boundaries_normal_action_exceeded(self):
        """Test exact boundary transitions for TLV evaluation."""
        # Toluene standard: TWA = 200.0 ppm
        # Normal < 100.0 ppm (50%)
        res_99 = self.engine.get_tlv("108-88-3", eval_val=99.9, eval_type="twa")
        self.assertEqual(res_99["evaluation"]["status"], "NORMAL")
        self.assertTrue(res_99["evaluation"]["is_compliant"])
        self.assertEqual(res_99["evaluation"]["color_code"], "GREEN")

        # Action level at exactly 50% (100.0 ppm)
        res_100 = self.engine.get_tlv("108-88-3", eval_val=100.0, eval_type="twa")
        self.assertEqual(res_100["evaluation"]["status"], "ACTION_LEVEL")
        self.assertTrue(res_100["evaluation"]["is_compliant"])
        self.assertEqual(res_100["evaluation"]["color_code"], "YELLOW")

        # Action level at exactly 100% (200.0 ppm)
        res_200 = self.engine.get_tlv("108-88-3", eval_val=200.0, eval_type="twa")
        self.assertEqual(res_200["evaluation"]["status"], "ACTION_LEVEL")
        self.assertTrue(res_200["evaluation"]["is_compliant"])

        # Exceeded at 200.01 ppm
        res_200_1 = self.engine.get_tlv("108-88-3", eval_val=200.01, eval_type="twa")
        self.assertEqual(res_200_1["evaluation"]["status"], "EXCEEDED")
        self.assertFalse(res_200_1["evaluation"]["is_compliant"])
        self.assertEqual(res_200_1["evaluation"]["color_code"], "RED")

    def test_10_tlv_metric_types(self):
        """Test evaluations against STEL and Ceiling limits."""
        # Toluene STEL = 300 ppm, Ceiling = 500 ppm
        res_stel = self.engine.get_tlv("108-88-3", eval_val=310.0, eval_type="stel")
        self.assertEqual(res_stel["evaluation"]["status"], "EXCEEDED")
        self.assertEqual(res_stel["evaluation"]["legal_limit"], 300.0)

        res_ceil = self.engine.get_tlv("108-88-3", eval_val=450.0, eval_type="ceiling")
        self.assertEqual(res_ceil["evaluation"]["status"], "ACTION_LEVEL")
        self.assertEqual(res_ceil["evaluation"]["legal_limit"], 500.0)

    def test_11_substance_with_no_tlv_warning(self):
        """Substance in 1,516 list without 324 TLV returns status: warning."""
        res = self.engine.get_tlv("Urea", eval_val=10.0)
        self.assertEqual(res["status"], "warning")
        self.assertIn("has no specific occupational TLV", res["message"])

    def test_12_nonexistent_substance_tlv(self):
        """Non-existent substance returns status: not_found."""
        res = self.engine.get_tlv("NonExistentChemicalXYZ")
        self.assertEqual(res["status"], "not_found")

    # -------------------------------------------------------------------------
    # 4. CHEMICAL MIXTURES & UNIT CONVERSIONS
    # -------------------------------------------------------------------------
    def test_13_mixture_additivity_edge_cases(self):
        """Test mixture additivity with empty list, single component, and unmatched items."""
        res_empty = self.engine.calculate_mixture_index([])
        self.assertEqual(res_empty["status"], "error")

        # Single component
        res_single = self.engine.calculate_mixture_index([
            {"chemical": "Toluene", "measured_value": 100.0, "unit": "ppm"}
        ])
        self.assertEqual(res_single["status"], "success")
        self.assertEqual(res_single["overall_status"], "PASS")
        self.assertAlmostEqual(res_single["mixture_exposure_index_em"], 0.5, places=2)

        # Mixed known and unknown substances
        res_partial = self.engine.calculate_mixture_index([
            {"chemical": "Toluene", "measured_value": 100.0, "unit": "ppm"},
            {"chemical": "UnknownSolvent99", "measured_value": 50.0, "unit": "ppm"}
        ])
        self.assertEqual(res_partial["status"], "success")
        self.assertIn("UnknownSolvent99", res_partial["unmatched_chemicals"])
        self.assertEqual(len(res_partial["components_evaluated"]), 1)

    def test_14_unit_conversion_physics(self):
        """Test unit conversions across various temperatures and pressures."""
        # Standard conditions (25C, 1 atm)
        res_25c = self.engine.convert_units(100.0, "ppm", "mg_m3", mw=92.14, temp_c=25.0, pressure_atm=1.0)
        self.assertEqual(res_25c["status"], "success")
        self.assertAlmostEqual(res_25c["converted_value"], 376.8, delta=1.0)

        # Freezing point (0C, 1 atm) -> molar vol = 22.414 L/mol
        res_0c = self.engine.convert_units(100.0, "ppm", "mg_m3", mw=92.14, temp_c=0.0, pressure_atm=1.0)
        self.assertEqual(res_0c["status"], "success")
        self.assertAlmostEqual(res_0c["molar_volume_liters"], 22.414, places=2)

        # Invalid molecular weight
        res_invalid_mw = self.engine.convert_units(100.0, "ppm", "mg_m3", mw=0.0)
        self.assertEqual(res_invalid_mw["status"], "error")

        res_neg_mw = self.engine.convert_units(100.0, "ppm", "mg_m3", mw=-10.0)
        self.assertEqual(res_neg_mw["status"], "error")

    # -------------------------------------------------------------------------
    # 5. SDS 16-SECTION VALIDATOR ROBUSTNESS
    # -------------------------------------------------------------------------
    def test_15_sds_empty_dict(self):
        """Empty SDS dict should report 0% compliance and 16 missing sections."""
        res = self.validator.verify_sds_data({})
        self.assertEqual(res["status"], "success")
        self.assertFalse(res["compliant"])
        self.assertEqual(res["compliance_rate_percent"], 0.0)
        self.assertEqual(res["valid_sections"], 0)
        self.assertEqual(len(res["missing_sections"]), 16)

    def test_16_sds_partial_sections(self):
        """Partial SDS with 4 sections should report 25.0% compliance and 12 missing sections."""
        partial_sds = {
            "section_1": {"trade_name": "TestChem", "cas_no": "108-88-3"},
            "section_2": {"ghs_classification": "Flammable"},
            "section_4": {"first_aid": "Wash with water"},
            "section_8": {"ppe": "Gloves, Goggles"}
        }
        res = self.validator.verify_sds_data(partial_sds)
        self.assertEqual(res["status"], "success")
        self.assertFalse(res["compliant"])
        self.assertEqual(res["valid_sections"], 4)
        self.assertEqual(len(res["missing_sections"]), 12)
        self.assertAlmostEqual(res["compliance_rate_percent"], 25.0, delta=0.1)

    def test_17_sds_nonexistent_file(self):
        """Non-existent SDS file path returns clean error JSON."""
        res = self.validator.verify_sds_file("non_existent_path/fake_sds.json")
        self.assertEqual(res["status"], "error")
        self.assertIn("not found", res["message"])

    def test_18_sds_thai_key_matching(self):
        """SDS using Thai section keys is properly matched and validated."""
        thai_sds = {
            "ข้อมูลสารเคมี": {"trade_name": "โทลูอีน", "cas_no": "108-88-3"},
            "การบ่งชี้อันตราย": {"ghs_classification": "Flammable Liquid"},
            "ส่วนประกอบ": {"ingredients": [{"name": "Toluene", "cas": "108-88-3"}]},
            "ปฐมพยาบาล": {"inhalation": "ให้ออกไปที่อากาศบริสุทธิ์"},
            "ผจญเพลิง": {"fire": "ใช้โฟมหรือผงเคมีแห้ง"},
            "หกรั่วไหล": {"spill": "กั้นบริเวณ ดูดซับด้วยทราย"},
            "การจัดเก็บ": {"storage": "เก็บในที่เย็นและแห้ง"},
            "การควบคุมการรับสัมผัส": {"ppe": "สวมถุงมือไนไตรล์"},
            "คุณสมบัติทางกายภาพ": {"properties": "ของเหลวใส ไม่มีสี"},
            "ความเสถียร": {"stability": "เสถียรภายใต้สภาวะปกติ"},
            "พิษวิทยา": {"toxicity": "LD50 ทางปาก > 5000 mg/kg"},
            "ระบบนิเวศน์": {"ecotoxicity": "เป็นพิษต่อสิ่งมีชีวิตในน้ำ"},
            "การกำจัด": {"disposal": "กำจัดตามกฎหมายโรงงาน"},
            "การขนส่ง": {"transport": "UN 1294, Class 3, PG II"},
            "กฎหมาย": {"regulatory": "พ.ร.บ. วัตถุอันตราย, กฎกระทรวงฯ ๒๕๕๖"},
            "ข้อมูลอื่นๆ": {"other": "NFPA 704: Health 2, Flammability 3, Instability 0"}
        }
        res = self.validator.verify_sds_data(thai_sds)
        self.assertEqual(res["status"], "success")
        self.assertTrue(res["compliant"])
        self.assertEqual(res["valid_sections"], 16)
        self.assertEqual(len(res["missing_sections"]), 0)
        self.assertEqual(res["compliance_rate_percent"], 100.0)

    # -------------------------------------------------------------------------
    # 6. LEGAL PROVISIONS RETRIEVAL
    # -------------------------------------------------------------------------
    def test_19_legal_articles_and_schemas(self):
        """Test retrieving Ministerial Regulation 2556, Sor.Or.1, Sor.Or.3, and penalties."""
        topics = ["regulation_2556", "sor_or_1", "sor_or_3_2565", "registered_testers", "penalties", "storage_rules", "medical_check", "all"]
        for t in topics:
            res = self.engine.get_law(topic=t)
            self.assertEqual(res["status"], "success", f"Failed retrieving legal topic: {t}")
            self.assertEqual(res["topic"], t)

    # -------------------------------------------------------------------------
    # 7. CLI MAIN ENTRY POINT EXECUTION & JSON STDOUT PARSING
    # -------------------------------------------------------------------------
    def _run_cli_main(self, args_list):
        from unittest.mock import patch
        import thai_chem_cli
        captured_stdout = io.StringIO()
        with patch.object(sys, "argv", args_list):
            with patch("sys.stdout", captured_stdout):
                thai_chem_cli.main()
        raw_output = captured_stdout.getvalue()
        return json.loads(raw_output), raw_output

    def test_20_cli_search_execution(self):
        """Execute CLI search command and verify JSON stdout."""
        data, raw = self._run_cli_main(["thai_chem_cli.py", "search", "-q", "Toluene", "-l", "2"])
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["returned_count"], min(2, data["total_found"]))
        self.assertIn("results", data)
        self.assertEqual(data["results"][0]["cas_no"], "108-88-3")

    def test_21_cli_get_tlv_execution(self):
        """Execute CLI get-tlv command with evaluation."""
        data, raw = self._run_cli_main(["thai_chem_cli.py", "get-tlv", "-q", "108-88-3", "--eval-val", "225.5", "--eval-type", "twa"])
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["evaluation"]["status"], "EXCEEDED")
        self.assertFalse(data["evaluation"]["is_compliant"])

    def test_22_cli_get_law_execution(self):
        """Execute CLI get-law command."""
        data, raw = self._run_cli_main(["thai_chem_cli.py", "get-law", "-t", "sor_or_3_2565"])
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["topic"], "sor_or_3_2565")
        self.assertIn("guidelines", data)

    def test_23_cli_verify_sds_execution(self):
        """Execute CLI verify-sds on sample_sds.json."""
        sample_file = os.path.join(DATA_DIR, "sample_sds.json")
        data, raw = self._run_cli_main(["thai_chem_cli.py", "verify-sds", "-f", sample_file])
        self.assertEqual(data["status"], "success")
        self.assertTrue(data["compliant"])
        self.assertEqual(data["compliance_rate_percent"], 100.0)

    def test_24_cli_eval_mixture_execution(self):
        """Execute CLI eval-mixture with components JSON."""
        mix_json = '[{"chemical": "Toluene", "measured_value": 80.0, "unit": "ppm"}, {"chemical": "Xylene (all isomers)", "measured_value": 40.0, "unit": "ppm"}]'
        data, raw = self._run_cli_main(["thai_chem_cli.py", "eval-mixture", "-c", mix_json])
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["overall_status"], "PASS")
        self.assertTrue(data["is_compliant"])

    def test_25_cli_convert_unit_execution(self):
        """Execute CLI convert-unit command."""
        data, raw = self._run_cli_main(["thai_chem_cli.py", "convert-unit", "-v", "200.0", "--from-unit", "ppm", "--to-unit", "mg_m3", "--mw", "92.14"])
        self.assertEqual(data["status"], "success")
        self.assertAlmostEqual(data["converted_value"], 753.6, delta=1.0)

    def test_26_cli_malformed_mixture_json(self):
        """Execute CLI eval-mixture with invalid JSON string and verify graceful error JSON output."""
        data, raw = self._run_cli_main(["thai_chem_cli.py", "eval-mixture", "-c", "{MALFORMED_JSON}"])
        self.assertEqual(data["status"], "error")
        self.assertIn("message", data)


if __name__ == "__main__":
    unittest.main(verbosity=2)

