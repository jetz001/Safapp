"""
Test runner for thai-chemical-safety-law skill test suite.
Executes test_thai_chem_skill.py and test_thai_chem_stress.py and dumps execution results.
"""

import os
import sys
import unittest
import json
import time

TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(TEST_DIR)
SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)
if TEST_DIR not in sys.path:
    sys.path.insert(0, TEST_DIR)

from test_thai_chem_skill import TestThaiChemicalSafetyLaw
from test_thai_chem_stress import TestThaiChemicalStress

def run_tests():
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    suite.addTests(loader.loadTestsFromTestCase(TestThaiChemicalSafetyLaw))
    suite.addTests(loader.loadTestsFromTestCase(TestThaiChemicalStress))

    start_time = time.time()
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    duration = time.time() - start_time

    summary = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "total_tests": result.testsRun,
        "failures_count": len(result.failures),
        "errors_count": len(result.errors),
        "was_successful": result.wasSuccessful(),
        "duration_seconds": round(duration, 4),
        "failures": [str(f) for f in result.failures],
        "errors": [str(e) for e in result.errors]
    }
    return summary

if __name__ == "__main__":
    summary = run_tests()
    print("\n--- SUMMARY JSON ---")
    print(json.dumps(summary, indent=2))
