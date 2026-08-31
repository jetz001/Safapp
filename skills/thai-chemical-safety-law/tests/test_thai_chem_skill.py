"""
Comprehensive Unit Test Suite for thai-chemical-safety-law Skill
Verifies search, TLV lookup & evaluation, mixture additivity, unit conversion,
SDS 16-section validation, legal article retrieval, and ThaiChemLawHelper.
"""

import os
import sys
import unittest
import json

# Setup import path
TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(TEST_DIR)
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_chem_law import ThaiChemLawEngine
from sds_validator import SDSValidator
from thai_chem_helper import ThaiChemLawHelper


class TestThaiChemicalSafetyLaw(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiChemLawEngine(data_dir=DATA_DIR)
        cls.validator = SDSValidator(cls.engine)
        cls.helper = ThaiChemLawHelper(skill_dir=SKILL_DIR)

    def test_01_database_sizes(self):
        """Verify that 1,516 chemical database and 324 TLV standards are loaded."""
        self.assertGreaterEqual(len(self.engine.chemicals_1516), 1516, "Must have at least 1,516 regulated chemicals")
        self.assertGreaterEqual(len(self.engine.tlv_324), 324, "Must have at least 324 TLV standards")
        self.assertIn("chapters", self.engine.legal_2556, "Legal articles 2556 must contain chapters")
        self.assertEqual(len(self.engine.sor_or_1_schema.get("sections", [])), 16, "Sor.Or.1 must have 16 sections")

    def test_02_search_by_exact_cas(self):
        """Test searching chemicals by CAS Number with and without hyphens."""
        # Exact CAS with hyphens
        res = self.engine.search_chemical("108-88-3")
        self.assertEqual(res["status"], "success")
        self.assertGreaterEqual(res["total_found"], 1)
        top = res["results"][0]
        self.assertEqual(top["cas_no"], "108-88-3")
        self.assertIn("Toluene", top["name_en"])
        self.assertTrue(top["has_tlv_324"])
        self.assertEqual(top["tlv"]["twa_ppm"], 200.0)

        # CAS without hyphens: 7647010 -> 7647-01-0 (Hydrochloric acid)
        res_hcl = self.engine.search_chemical("7647010")
        self.assertEqual(res_hcl["status"], "success")
        self.assertGreaterEqual(res_hcl["total_found"], 1)
        top_hcl = res_hcl["results"][0]
        self.assertEqual(top_hcl["cas_no"], "7647-01-0")

    def test_03_search_by_thai_and_english_name(self):
        """Test searching chemicals by Thai and English names."""
        res_benzene = self.engine.search_chemical("Benzene")
        self.assertEqual(res_benzene["status"], "success")
        top_b = res_benzene["results"][0]
        self.assertEqual(top_b["cas_no"], "71-43-2")
        self.assertEqual(top_b["tlv"]["twa_ppm"], 0.5)

        res_sulfuric = self.engine.search_chemical("กรดกำมะถัน")
        self.assertEqual(res_sulfuric["status"], "success")
        top_s = res_sulfuric["results"][0]
        self.assertEqual(top_s["cas_no"], "7664-93-9")

        res_nh3 = self.engine.search_chemical("แอมโมเนีย")
        self.assertEqual(res_nh3["status"], "success")
        top_nh3 = res_nh3["results"][0]
        self.assertEqual(top_nh3["cas_no"], "7664-41-7")

    def test_04_get_tlv_lookup(self):
        """Test querying 324 TLV standards."""
        # Toluene
        res = self.engine.get_tlv("Toluene")
        self.assertEqual(res["status"], "success")
        limits = res["substance"]["standard_limits"]
        self.assertEqual(limits["twa_ppm"], 200.0)
        self.assertEqual(limits["twa_mg_m3"], 753.0)
        self.assertEqual(limits["stel_ppm"], 300.0)
        self.assertEqual(limits["stel_mg_m3"], 1130.0)
        self.assertEqual(limits["ceiling_ppm"], 500.0)
        self.assertEqual(limits["ceiling_mg_m3"], 1883.0)
        self.assertEqual(limits["notation"], "Skin")

        # Hydrogen chloride (Ceiling only)
        res_hcl = self.engine.get_tlv("7647-01-0")
        self.assertEqual(res_hcl["status"], "success")
        limits_hcl = res_hcl["substance"]["standard_limits"]
        self.assertEqual(limits_hcl["ceiling_ppm"], 2.0)
        self.assertEqual(limits_hcl["ceiling_mg_m3"], 2.98)

    def test_05_tlv_evaluation_engine(self):
        """Test compliance evaluation against legal thresholds (NORMAL, ACTION_LEVEL, EXCEEDED)."""
        # 1. NORMAL (50 ppm < 0.5 * 200 ppm)
        eval_normal = self.engine.get_tlv("Toluene", eval_val=50.0, eval_type="twa", eval_unit="ppm")
        self.assertEqual(eval_normal["evaluation"]["status"], "NORMAL")
        self.assertTrue(eval_normal["evaluation"]["is_compliant"])
        self.assertEqual(eval_normal["evaluation"]["color_code"], "GREEN")

        # 2. ACTION LEVEL (120 ppm: 0.5 * 200 <= 120 <= 200)
        eval_action = self.engine.get_tlv("Toluene", eval_val=120.0, eval_type="twa", eval_unit="ppm")
        self.assertEqual(eval_action["evaluation"]["status"], "ACTION_LEVEL")
        self.assertTrue(eval_action["evaluation"]["is_compliant"])
        self.assertEqual(eval_action["evaluation"]["color_code"], "YELLOW")

        # 3. EXCEEDED (240 ppm > 200 ppm)
        eval_exceeded = self.engine.get_tlv("Toluene", eval_val=240.0, eval_type="twa", eval_unit="ppm")
        self.assertEqual(eval_exceeded["evaluation"]["status"], "EXCEEDED")
        self.assertFalse(eval_exceeded["evaluation"]["is_compliant"])
        self.assertEqual(eval_exceeded["evaluation"]["color_code"], "RED")
        self.assertIn("เกินค่าขีดจำกัดความเข้มข้นตามกฎหมาย", eval_exceeded["evaluation"]["action_required"])

    def test_06_chemical_mixture_additivity_index(self):
        """Test additive mixture exposure index Em = Sum(Ci / TLVi)."""
        # Compliant Mixture: Toluene 80 ppm (TLV 200 -> 0.4) + Xylene 40 ppm (TLV 100 -> 0.4) = 0.8 <= 1.0 (PASS)
        mix_pass = self.engine.calculate_mixture_index([
            {"chemical": "Toluene", "measured_value": 80.0, "unit": "ppm"},
            {"chemical": "Xylene (all isomers)", "measured_value": 40.0, "unit": "ppm"}
        ])
        self.assertEqual(mix_pass["status"], "success")
        self.assertEqual(mix_pass["overall_status"], "PASS")
        self.assertTrue(mix_pass["is_compliant"])
        self.assertAlmostEqual(mix_pass["mixture_exposure_index_em"], 0.8, places=2)

        # Exceeded Mixture: Toluene 150 ppm (TLV 200 -> 0.75) + Xylene 60 ppm (TLV 100 -> 0.60) = 1.35 > 1.0 (EXCEEDED)
        mix_fail = self.engine.calculate_mixture_index([
            {"chemical": "Toluene", "measured_value": 150.0, "unit": "ppm"},
            {"chemical": "Xylene (all isomers)", "measured_value": 60.0, "unit": "ppm"}
        ])
        self.assertEqual(mix_fail["overall_status"], "EXCEEDED")
        self.assertFalse(mix_fail["is_compliant"])
        self.assertEqual(mix_fail["color_code"], "RED")
        self.assertAlmostEqual(mix_fail["mixture_exposure_index_em"], 1.35, places=2)

    def test_07_unit_conversion(self):
        """Test physical chemistry ppm <-> mg/m3 conversion at 25C, 1 atm."""
        # Toluene MW=92.14: 200 ppm -> mg/m3: (200 * 92.14) / 24.453 = ~753.6
        conv_res = self.engine.convert_units(200.0, "ppm", "mg_m3", mw=92.14)
        self.assertEqual(conv_res["status"], "success")
        self.assertAlmostEqual(conv_res["converted_value"], 753.6, delta=1.0)

        # Reverse conversion mg/m3 -> ppm
        rev_res = self.engine.convert_units(753.6, "mg_m3", "ppm", mw=92.14)
        self.assertAlmostEqual(rev_res["converted_value"], 200.0, delta=1.0)

    def test_08_sds_validation_complete(self):
        """Test SDS validation on sample_sds.json (100% compliant)."""
        sample_path = os.path.join(DATA_DIR, "sample_sds.json")
        res = self.validator.verify_sds_file(sample_path)
        self.assertEqual(res["status"], "success")
        self.assertTrue(res["compliant"])
        self.assertEqual(res["compliance_rate_percent"], 100.0)
        self.assertEqual(res["valid_sections"], 16)
        self.assertEqual(len(res["missing_sections"]), 0)
        self.assertIn("Toluene", res["cross_reference_check"]["matched_substance"])

    def test_09_sds_validation_incomplete(self):
        """Test SDS validation on incomplete SDS dictionary."""
        incomplete_sds = {
            "section_1_identification": {"chemical_name": "Incomplete Substance", "cas_no": "108-88-3"},
            "section_2_hazard": {"ghs_classification": ["Flammable"]},
            "section_3_composition": {"ingredients": [{"name": "Chem A"}]}
        }
        res = self.validator.verify_sds_data(incomplete_sds)
        self.assertEqual(res["status"], "success")
        self.assertFalse(res["compliant"])
        self.assertEqual(res["valid_sections"], 3)
        self.assertEqual(len(res["missing_sections"]), 13)
        self.assertAlmostEqual(res["compliance_rate_percent"], 18.8, delta=0.5)

    def test_10_get_law_topics(self):
        """Test legal article retrieval topics."""
        law_2556 = self.engine.get_law(topic="regulation_2556")
        self.assertEqual(law_2556["status"], "success")
        self.assertIn("law_title_th", law_2556["law"])

        sor_or_3 = self.engine.get_law(topic="sor_or_3_2565")
        self.assertEqual(sor_or_3["status"], "success")
        self.assertIn("inspection_rules", sor_or_3["guidelines"])

        testers = self.engine.get_law(topic="registered_testers")
        self.assertEqual(testers["status"], "success")
        self.assertEqual(len(testers["tester_types"]), 2)

    def test_11_thai_chem_helper(self):
        """Test ThaiChemLawHelper facade class."""
        search_res = self.helper.search_chemical("Acetone")
        self.assertEqual(search_res["status"], "success")
        self.assertGreaterEqual(search_res["total_found"], 1)

        tlv_res = self.helper.get_tlv("Acetone", eval_val=200.0, eval_type="twa")
        self.assertEqual(tlv_res["status"], "success")
        self.assertEqual(tlv_res["evaluation"]["status"], "NORMAL")

        law_res = self.helper.get_law("sor_or_1")
        self.assertEqual(law_res["status"], "success")


if __name__ == "__main__":
    unittest.main(verbosity=2)
