"""
==============================================================================
 Thai Safety Legal Register Helper for AgentResearch Multi-Agent System
 Conforming to 8 Thai Royal Gazette Safety Regulations:
   1. OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
   2. Ministerial Reg. Safety Officers & Committee B.E. 2565 (จป. & คปอ.)
   3. Ministerial Reg. Hazardous Chemicals B.E. 2556 (สารเคมีอันตราย)
   4. Ministerial Reg. Fire Safety B.E. 2555 (การป้องกันและระงับอัคคีภัย)
   5. Ministerial Reg. Electrical Safety B.E. 2558 (ความปลอดภัยเกี่ยวกับไฟฟ้า)
   6. Ministerial Reg. Machinery, Cranes & Boilers B.E. 2564 (เครื่องจักร ปั้นจั่น หม้อน้ำ)
   7. Ministerial Reg. Heat, Light & Noise B.E. 2559 (ความร้อน แสงสว่าง เสียง)
   8. Ministerial Reg. Occupational Health Examination B.E. 2563 (ตรวจสุขภาพปัจจัยเสี่ยง)
==============================================================================
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional, Union

# Possible default skill directories
_DEFAULT_CONFIG_DIR = os.path.expanduser(r"~\.gemini\config\skills\thai-safety-legal-register")
_PROJECT_SKILL_DIR = r"d:\DEV\SAFAPP\skills\thai-safety-legal-register"

if os.path.exists(_DEFAULT_CONFIG_DIR):
    SKILL_DIR = _DEFAULT_CONFIG_DIR
elif os.path.exists(_PROJECT_SKILL_DIR):
    SKILL_DIR = _PROJECT_SKILL_DIR
else:
    SKILL_DIR = _DEFAULT_CONFIG_DIR

SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_safety_legal_cli.py")

# Ensure script dir in sys.path
if SCRIPTS_DIR not in sys.path and os.path.exists(SCRIPTS_DIR):
    sys.path.insert(0, SCRIPTS_DIR)

try:
    from thai_safety_legal_engine import ThaiSafetyLegalEngine
    _HAS_DIRECT_ENGINE = True
except ImportError:
    _HAS_DIRECT_ENGINE = False


class ThaiSafetyLegalHelper:
    """Helper class for AgentResearch system to query Thai safety laws and evaluate compliance."""

    def __init__(self, skill_dir: Optional[str] = None, prefer_direct: bool = True):
        if skill_dir is None:
            if os.path.exists(_DEFAULT_CONFIG_DIR):
                self.skill_dir = _DEFAULT_CONFIG_DIR
            elif os.path.exists(_PROJECT_SKILL_DIR):
                self.skill_dir = _PROJECT_SKILL_DIR
            else:
                self.skill_dir = _DEFAULT_CONFIG_DIR
        else:
            self.skill_dir = skill_dir

        self.cli_script = os.path.join(self.skill_dir, "scripts", "thai_safety_legal_cli.py")
        self.data_dir = os.path.join(self.skill_dir, "scripts", "data")
        self.prefer_direct = prefer_direct
        self._engine: Optional[Any] = None

        if self.prefer_direct:
            # Check if engine can be imported directly or added to sys.path
            scripts_dir = os.path.join(self.skill_dir, "scripts")
            if scripts_dir not in sys.path and os.path.exists(scripts_dir):
                sys.path.insert(0, scripts_dir)
            try:
                from thai_safety_legal_engine import ThaiSafetyLegalEngine
                if os.path.exists(self.data_dir):
                    self._engine = ThaiSafetyLegalEngine(data_dir=self.data_dir)
                else:
                    self._engine = ThaiSafetyLegalEngine()
            except Exception:
                self._engine = None

    def _run_cli(self, args: List[str]) -> Dict[str, Any]:
        """Execute CLI command via subprocess with UTF-8 encoding."""
        if os.path.exists(self.cli_script):
            cmd = [sys.executable, self.cli_script] + args
            try:
                res = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    check=True
                )
                return json.loads(res.stdout)
            except subprocess.CalledProcessError as cpe:
                try:
                    return json.loads(cpe.stdout)
                except Exception:
                    return {
                        "status": "error",
                        "message": f"CLI command failed with exit code {cpe.returncode}: {cpe.stderr or cpe.stdout}",
                        "cmd": cmd
                    }
            except Exception as e:
                return {
                    "status": "error",
                    "message": f"CLI execution failed: {str(e)}",
                    "cmd": cmd
                }
        return {"status": "error", "message": f"CLI script not found at {self.cli_script}"}

    def search_law(self, query: str, category: str = "all", limit: int = 10) -> Dict[str, Any]:
        """Search legal provisions across 8 safety regulations."""
        if self._engine:
            return self._engine.search_laws(query=query, category=category, limit=limit)
        return self._run_cli(["search", "-q", query, "-c", category, "-l", str(limit)])

    def search_laws(self, query: str, category: str = "all", limit: int = 10) -> Dict[str, Any]:
        """Alias for search_law."""
        return self.search_law(query=query, category=category, limit=limit)

    def get_law(self, law_id: str, section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve full text, gazette citations and statutory details for a law."""
        if self._engine:
            return self._engine.get_law(law_id=law_id, section=section)
        args = ["get-law", "-i", law_id]
        if section:
            args += ["-s", section]
        return self._run_cli(args)

    def evaluate_workplace(self, workplace_profile: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """Evaluate workplace safety compliance status based on profile data."""
        if self._engine:
            return self._engine.evaluate_compliance(workplace_profile)
        
        if isinstance(workplace_profile, str) and os.path.exists(workplace_profile):
            return self._run_cli(["evaluate", "-p", workplace_profile])
        elif isinstance(workplace_profile, str):
            return self._run_cli(["evaluate", "-d", workplace_profile])
        else:
            profile_json = json.dumps(workplace_profile, ensure_ascii=False)
            return self._run_cli(["evaluate", "-d", profile_json])

    def evaluate_compliance(self, workplace_profile: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """Alias for evaluate_workplace."""
        return self.evaluate_workplace(workplace_profile)

    def generate_capa_summary(
        self,
        eval_result_or_file: Optional[Union[Dict[str, Any], str]] = None,
        non_compliant_item_ids: Optional[Union[List[str], str]] = None
    ) -> Dict[str, Any]:
        """Generate prioritized CAPA action plans for non-compliant requirements."""
        if self._engine:
            eval_dict = None
            if isinstance(eval_result_or_file, dict):
                eval_dict = eval_result_or_file
            elif isinstance(eval_result_or_file, str) and os.path.exists(eval_result_or_file):
                with open(eval_result_or_file, "r", encoding="utf-8") as f:
                    eval_dict = json.load(f)
            
            return self._engine.generate_capa(
                eval_data=eval_dict,
                item_ids=non_compliant_item_ids
            )

        if isinstance(eval_result_or_file, str) and os.path.exists(eval_result_or_file):
            return self._run_cli(["capa-summary", "-e", eval_result_or_file])
        elif non_compliant_item_ids:
            items_str = non_compliant_item_ids if isinstance(non_compliant_item_ids, str) else ",".join(non_compliant_item_ids)
            return self._run_cli(["capa-summary", "-i", items_str])
        elif isinstance(eval_result_or_file, dict):
            # If we don't have engine and passed raw dict, write temporary evaluation JSON or pass items
            return self._engine.generate_capa(eval_data=eval_result_or_file) if self._engine else {
                "status": "error", "message": "Direct engine required for raw dict evaluation CAPA"
            }
        return {"status": "error", "message": "Missing evaluation data or item IDs"}

    def generate_capa(
        self,
        eval_result_or_file: Optional[Union[Dict[str, Any], str]] = None,
        non_compliant_item_ids: Optional[Union[List[str], str]] = None
    ) -> Dict[str, Any]:
        """Alias for generate_capa_summary."""
        return self.generate_capa_summary(eval_result_or_file, non_compliant_item_ids)
