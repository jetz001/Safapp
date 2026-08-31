"""
==============================================================================
 Adversarial Stress Testing Suite for thai-safety-legal-register Agent Skill
 File: skills/thai-safety-legal-register/tests/test_thai_safety_legal_stress.py
==============================================================================
"""

import unittest
import os
import sys
import json
import time
import subprocess
import io

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(TESTS_DIR)
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_safety_legal_cli.py")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from thai_safety_legal_engine import ThaiSafetyLegalEngine
from thai_safety_legal_helper import ThaiSafetyLegalHelper


class TestThaiSafetyLegalStress(unittest.TestCase):
    """Adversarial stress and robustness test suite."""

    @classmethod
    def setUpClass(cls):
        cls.engine = ThaiSafetyLegalEngine(data_dir=DATA_DIR)
        cls.helper = ThaiSafetyLegalHelper(skill_dir=SKILL_DIR, prefer_direct=True)
        cls.helper_cli = ThaiSafetyLegalHelper(skill_dir=SKILL_DIR, prefer_direct=False)

    # -------------------------------------------------------------------------
    # 1. THAI NUMERAL QUERY PARSING & NORMALIZATION
    # -------------------------------------------------------------------------
    def test_01_thai_numeral_parsing(self):
        """Verify queries with Thai numerals (๐-๙) correctly match legal articles & laws."""
        test_cases = [
            ("มาตรา ๓๒", "LAW-01"),
            ("มาตรา ๑๖", "LAW-01"),
            ("ข้อ ๑๖", "LAW-02"),
            ("๒๕๕๔", "LAW-01"),
            ("๒๕๖๕", "LAW-02"),
            ("๒๕๕๖", "LAW-03"),
            ("๒๕๕๕", "LAW-04"),
            ("๒๕๕๘", "LAW-05"),
            ("๒๕๖๔", "LAW-06"),
            ("๒๕๕๙", "LAW-07"),
            ("๒๕๖๓", "LAW-08"),
            ("สอ.๑", "LAW-03"),
            ("สปร.๕", "LAW-08"),
            ("จป.วิชาชีพ ๖๔", "LAW-02"),
        ]

        for query, expected_law in test_cases:
            res = self.engine.search_laws(query)
            self.assertEqual(res.get("status"), "success", f"Failed for query: {query}")
            self.assertGreater(
                res.get("total_found", 0), 0,
                f"Query with Thai numerals '{query}' returned 0 results."
            )
            found_laws = [item["law_id"] for item in res["results"]]
            self.assertIn(
                expected_law, found_laws,
                f"Query '{query}' expected to find {expected_law}, found {found_laws}"
            )

    def test_02_mixed_thai_and_arabic_numerals(self):
        """Verify mixed Thai and Arabic numeral equivalents produce identical results."""
        pairs = [
            ("มาตรา ๑๖", "มาตรา 16"),
            ("ข้อ ๑๖", "ข้อ 16"),
            ("พ.ร.บ. ๒๕๕๔", "พ.ร.บ. 2554"),
            ("กฎกระทรวง ๒๕๖๕", "กฎกระทรวง 2565"),
        ]

        for thai_q, arab_q in pairs:
            res_th = self.engine.search_laws(thai_q)
            res_ar = self.engine.search_laws(arab_q)
            self.assertEqual(res_th.get("status"), "success")
            self.assertEqual(res_ar.get("status"), "success")
            self.assertGreater(res_th.get("total_found", 0), 0)
            self.assertGreater(res_ar.get("total_found", 0), 0)
            # Scores and top match should be identical
            self.assertEqual(
                res_th["results"][0]["req_id"],
                res_ar["results"][0]["req_id"],
                f"Top result mismatch between '{thai_q}' and '{arab_q}'"
            )

    # -------------------------------------------------------------------------
    # 2. MALFORMED JSON & EVALUATION BOUNDARY CONDITIONS
    # -------------------------------------------------------------------------
    def test_03_malformed_json_inputs(self):
        """Test engine handles malformed, truncated, or syntactically invalid JSON strings."""
        malformed_inputs = [
            "",
            "   ",
            "{",
            "{ company_name: invalid }",
            "{\"employee_count\": 50, }",  # trailing comma
            "[1, 2, 3]",
            "null",
            "None",
            "{\"company_name\": \"Test\", \"employee_count\": }",
        ]

        for bad_input in malformed_inputs:
            res = self.engine.evaluate_compliance(bad_input)
            self.assertEqual(
                res.get("status"), "error",
                f"Expected error for malformed input '{bad_input}', got: {res.get('status')}"
            )

    def test_04_out_of_range_employee_counts(self):
        """Test compliance evaluation across boundary and out-of-range employee counts."""
        test_employee_counts = [
            -1000, -1, 0, 1, 2, 19, 20, 49, 50, 63, 64, 99, 100, 199, 200, 1000000
        ]

        for emp in test_employee_counts:
            profile = {
                "company_name": f"Factory with {emp} employees",
                "business_category_annex": 2,
                "employee_count": emp,
                "current_practices": {}
            }
            res = self.engine.evaluate_compliance(profile)
            self.assertEqual(res.get("status"), "success", f"Failed for employee count: {emp}")
            summary = res.get("compliance_summary", {})
            self.assertIn("compliance_percentage", summary)
            self.assertIn("compliance_grade", summary)
            self.assertGreaterEqual(summary["compliance_percentage"], 0.0)
            self.assertLessEqual(summary["compliance_percentage"], 100.0)

    def test_05_invalid_and_out_of_range_annex(self):
        """Test non-existent annex categories (e.g. -1, 0, 4, 99, 9999)."""
        bad_annexes = [-1, 0, 4, 10, 99]

        for ann in bad_annexes:
            profile = {
                "company_name": f"Test Annex {ann}",
                "business_category_annex": ann,
                "employee_count": 100,
                "current_practices": {}
            }
            res = self.engine.evaluate_compliance(profile)
            self.assertEqual(res.get("status"), "success", f"Failed for annex: {ann}")
            summary = res.get("compliance_summary", {})
            self.assertIsInstance(summary["compliance_percentage"], float)

    # -------------------------------------------------------------------------
    # 3. SEARCH & GET-LAW ADVERSARIAL CASES
    # -------------------------------------------------------------------------
    def test_06_non_existent_and_fuzzed_law_ids(self):
        """Test get_law with invalid, fuzzed, or SQL-like law IDs."""
        fuzzed_ids = [
            "LAW-999",
            "UNKNOWN_LAW_ID",
            "LAW-01'; DROP TABLE laws; --",
            "<script>alert(1)</script>",
            "   ",
            "$$$###@@@",
            "LAW-00",
            "LAW-09",
        ]

        for fid in fuzzed_ids:
            res = self.engine.get_law(fid)
            if not fid.strip():
                self.assertEqual(res.get("status"), "error")
            else:
                self.assertEqual(res.get("status"), "error")
                self.assertIn("not found", res.get("message", "").lower())
                self.assertIn("available_laws", res)

    def test_07_non_existent_categories_in_search(self):
        """Test search with non-existent categories returns empty results gracefully."""
        bad_categories = [
            "nuclear_safety",
            "aviation_law_2550",
            "fake_category_xyz",
            "12345",
            "all_invalid",
        ]

        for cat in bad_categories:
            res = self.engine.search_laws("ความปลอดภัย", category=cat)
            self.assertEqual(res.get("status"), "success")
            self.assertEqual(res.get("total_found"), 0)
            self.assertEqual(len(res.get("results", [])), 0)

    def test_08_special_character_and_injection_resilience(self):
        """Test search queries containing regex metacharacters, punctuation, and injection payloads."""
        payloads = [
            "จป.*+?^${}()|[]\\",
            "ดับเพลิง' OR 1=1 --",
            "<xml><law id='LAW-01'/></xml>",
            "\x00\x01\x02",
            "Emoji: 🛡️🔥⚡🏗️",
            "Whitespace: \t\r\n\v\f",
            "Very long query: " + "ความปลอดภัย " * 100,
        ]

        for p in payloads:
            res = self.engine.search_laws(p)
            self.assertIn(res.get("status"), ["success", "error"])
            self.assertIsInstance(res.get("results", []), list)

    def test_09_search_limits_boundary(self):
        """Test limit parameter boundaries (0, 1, 1000, negative)."""
        res_0 = self.engine.search_laws("ความปลอดภัย", limit=0)
        self.assertEqual(len(res_0.get("results", [])), 0)

        res_1 = self.engine.search_laws("ความปลอดภัย", limit=1)
        self.assertLessEqual(len(res_1.get("results", [])), 1)

        res_1000 = self.engine.search_laws("ความปลอดภัย", limit=1000)
        self.assertEqual(res_1000.get("status"), "success")
        self.assertGreater(len(res_1000.get("results", [])), 0)

    # -------------------------------------------------------------------------
    # 4. CAPA FUZZING & ERROR HANDLING
    # -------------------------------------------------------------------------
    def test_10_capa_generation_fuzzing(self):
        """Test generate_capa with invalid IDs, empty data, or non-existent items."""
        # Non-existent requirement IDs
        res = self.engine.generate_capa(item_ids="UNKNOWN-REQ-999,FAKE-REQ-123")
        self.assertEqual(res.get("status"), "success")
        self.assertEqual(len(res.get("capa_plans", [])), 2)
        for plan in res["capa_plans"]:
            self.assertIn("capa_id", plan)
            self.assertIn("root_cause", plan)
            self.assertEqual(plan.get("status"), "OPEN")

        # Corrupted evaluation data dict
        corrupted_eval = {
            "detailed_evaluations": [
                {"status": "NON_COMPLIANT"},  # missing req_id
                {"status": "IN_PROGRESS", "req_id": "LAW-03-REQ-01"},
                {"status": "COMPLIANT", "req_id": "LAW-01-REQ-01"},
                {"invalid_structure": True},
            ]
        }
        res_corrupted = self.engine.generate_capa(eval_data=corrupted_eval)
        self.assertEqual(res_corrupted.get("status"), "success")
        self.assertEqual(len(res_corrupted.get("capa_plans", [])), 1)
        self.assertEqual(res_corrupted["capa_plans"][0]["req_id"], "LAW-03-REQ-01")

    # -------------------------------------------------------------------------
    # 5. CLI EXECUTION & PERFORMANCE BENCHMARKING
    # -------------------------------------------------------------------------
    def test_11_cli_subcommands_and_utf8_output(self):
        """Stress-test CLI across all 4 subcommands with Thai arguments and UTF-8 verification."""
        commands = [
            [sys.executable, CLI_SCRIPT, "search", "-q", "จป.วิชาชีพ ๒๕๖๕", "-l", "5"],
            [sys.executable, CLI_SCRIPT, "get-law", "-i", "LAW-02", "-s", "ข้อ ๑๖"],
            [sys.executable, CLI_SCRIPT, "evaluate", "-d", '{"company_name":"โรงงานตัวอย่าง","employee_count":100,"business_category_annex":2}'],
            [sys.executable, CLI_SCRIPT, "capa-summary", "-i", "LAW-02-REQ-04,LAW-05-REQ-01"],
        ]

        for cmd in commands:
            start_time = time.perf_counter()
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace"
            )
            elapsed_ms = (time.perf_counter() - start_time) * 1000

            self.assertEqual(proc.returncode, 0, f"CLI command failed: {' '.join(cmd)}\nStderr: {proc.stderr}")
            parsed = json.loads(proc.stdout)
            self.assertEqual(parsed.get("status"), "success")
            # Execution should be sub-second
            self.assertLess(elapsed_ms, 2000.0, f"CLI latency too high: {elapsed_ms:.1f}ms")

    def test_12_cli_missing_mandatory_flags(self):
        """Verify CLI returns exit code != 0 and clean JSON error on missing mandatory flags."""
        bad_cli_calls = [
            [sys.executable, CLI_SCRIPT, "search"],  # missing -q
            [sys.executable, CLI_SCRIPT, "get-law"],  # missing -i
            [sys.executable, CLI_SCRIPT, "evaluate"],  # missing -p and -d
            [sys.executable, CLI_SCRIPT, "capa-summary"],  # missing -e and -i
        ]

        for cmd in bad_cli_calls:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace"
            )
            self.assertNotEqual(proc.returncode, 0, f"Expected non-zero exit code for: {' '.join(cmd)}")


if __name__ == "__main__":
    unittest.main(verbosity=2)
