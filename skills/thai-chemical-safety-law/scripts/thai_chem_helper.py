"""
Thai Chemical Safety Law Helper for AgentResearch Multi-Agent System (thai_chem_helper.py)
Provides programmatic and CLI access to chemical regulations & TLVs for:
  - Research Agent (SK-RES-09)
  - Writer Agent
  - Advisor Agent
  - QA Agent
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional

# Locate skill directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(SCRIPT_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPT_DIR, "thai_chem_cli.py")

# Ensure script directory is in sys.path for direct imports
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

try:
    from thai_chem_law import ThaiChemLawEngine
    from sds_validator import SDSValidator
    _HAS_DIRECT_IMPORTS = True
except ImportError:
    _HAS_DIRECT_IMPORTS = False


class ThaiChemLawHelper:
    """Helper class for AgentResearch system to query Thai chemical laws and standards."""
    def __init__(self, skill_dir: str = SKILL_DIR, prefer_direct: bool = True):
        self.skill_dir = skill_dir
        self.cli_script = os.path.join(skill_dir, "scripts", "thai_chem_cli.py")
        self.prefer_direct = prefer_direct
        self._engine: Optional[ThaiChemLawEngine] = None
        self._validator: Optional[SDSValidator] = None

        if self.prefer_direct and _HAS_DIRECT_IMPORTS:
            try:
                self._engine = ThaiChemLawEngine(data_dir=DATA_DIR)
                self._validator = SDSValidator(self._engine)
            except Exception:
                self._engine = None
                self._validator = None

    def _run_cli(self, args: List[str]) -> Dict[str, Any]:
        """Execute CLI command via subprocess."""
        if os.path.exists(self.cli_script):
            cmd = [sys.executable, self.cli_script] + args
            try:
                res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", check=True)
                return json.loads(res.stdout)
            except Exception as e:
                return {"status": "error", "message": f"CLI execution failed: {str(e)}"}
        return {"status": "error", "message": f"CLI script not found at {self.cli_script}"}

    def search_chemical(self, query: str, limit: int = 10) -> Dict[str, Any]:
        """Search chemical by Thai name, English name, or CAS No."""
        if self._engine:
            return self._engine.search_chemical(query, limit=limit)
        return self._run_cli(["search", "-q", query, "-l", str(limit)])

    def get_tlv(
        self,
        query: str,
        eval_val: Optional[float] = None,
        eval_type: str = "twa",
        eval_unit: str = "ppm"
    ) -> Dict[str, Any]:
        """Query TLV standard and optionally evaluate measurement against law."""
        if self._engine:
            return self._engine.get_tlv(query, eval_val=eval_val, eval_type=eval_type, eval_unit=eval_unit)
        args = ["get-tlv", "-q", query]
        if eval_val is not None:
            args += ["--eval-val", str(eval_val), "--eval-type", eval_type, "--eval-unit", eval_unit]
        return self._run_cli(args)

    def get_law(self, topic: str = "all", section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve legal provisions (regulation_2556, sor_or_1, sor_or_3_2565)."""
        if self._engine:
            return self._engine.get_law(topic=topic, section=section)
        args = ["get-law", "-t", topic]
        if section:
            args += ["-s", section]
        return self._run_cli(args)

    def verify_sds(self, file_path: str) -> Dict[str, Any]:
        """Verify SDS compliance with 16 GHS sections."""
        if self._validator:
            return self._validator.verify_sds_file(file_path)
        return self._run_cli(["verify-sds", "-f", file_path])

    def calculate_mixture_index(self, components: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Evaluate additive exposure index (Em) for multiple chemicals."""
        if self._engine:
            return self._engine.calculate_mixture_index(components)
        return self._run_cli(["eval-mixture", "-c", json.dumps(components)])

    def convert_units(
        self,
        value: float,
        from_unit: str,
        to_unit: str,
        mw: float,
        temp_c: float = 25.0,
        pressure_atm: float = 1.0
    ) -> Dict[str, Any]:
        """Convert ppm <-> mg/m3."""
        if self._engine:
            return self._engine.convert_units(value, from_unit, to_unit, mw, temp_c, pressure_atm)
        return self._run_cli([
            "convert-unit",
            "-v", str(value),
            "--from-unit", from_unit,
            "--to-unit", to_unit,
            "--mw", str(mw),
            "--temp", str(temp_c),
            "--pressure", str(pressure_atm)
        ])
