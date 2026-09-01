"""
==============================================================================
 Thai Environmental Safety Law Helper for AgentResearch Multi-Agent System
 Conforming to Royal Thai Gazette Enactments:
   1. OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ - ม.๘, ม.๙, ม.๑๑, ม.๑๕, ม.๓๒, ม.๕๓, ม.๕๕, ม.๕๖)
   2. Ministerial Reg. Heat, Light, Noise B.E. 2559 (กฎกระทรวงฯ ๒๕๕๙)
   3. DLPW Notification Lighting Standards B.E. 2561 (ประกาศกรมฯ แสงสว่าง ๒๕๖๑)
   4. DLPW Notification Noise Exposure Standards B.E. 2561 (ประกาศกรมฯ เสียง ๒๕๖๑)
   5. DLPW Notification WBGT Calculation & Evaluation B.E. 2563 (ประกาศกรมฯ ความร้อน ๒๕๖๓)
   6. DLPW Notification Official Environmental Reporting Form (แบบรายงานผลตรวจวัด สสค. / อธ.๑)
==============================================================================
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional, Union

# Dynamic resolution of skill directory across environment locations
_DEFAULT_CONFIG_DIR = os.path.expanduser(r"~\.gemini\config\skills\thai-environmental-safety-law")
_PROJECT_SKILL_DIR = r"d:\DEV\SAFAPP\skills\thai-environmental-safety-law"

if os.path.exists(_DEFAULT_CONFIG_DIR):
    SKILL_DIR = _DEFAULT_CONFIG_DIR
elif os.path.exists(_PROJECT_SKILL_DIR):
    SKILL_DIR = _PROJECT_SKILL_DIR
else:
    SKILL_DIR = _PROJECT_SKILL_DIR

SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_env_cli.py")

# Ensure script dir is in sys.path
if SCRIPTS_DIR not in sys.path and os.path.exists(SCRIPTS_DIR):
    sys.path.insert(0, SCRIPTS_DIR)

try:
    from thai_env_engine import ThaiEnvEngine
    _HAS_DIRECT_ENGINE = True
except ImportError:
    _HAS_DIRECT_ENGINE = False


class ThaiEnvHelper:
    """
    Dual-mode Python helper for AgentResearch system:
      - Mode 1: Direct Python Engine instantiation (in-memory, high performance)
      - Mode 2: CLI Subprocess fallback with UTF-8 encoding
    """

    def __init__(self, skill_dir: Optional[str] = None, prefer_direct: bool = True):
        if skill_dir is None:
            if os.path.exists(_PROJECT_SKILL_DIR):
                self.skill_dir = _PROJECT_SKILL_DIR
            elif os.path.exists(_DEFAULT_CONFIG_DIR):
                self.skill_dir = _DEFAULT_CONFIG_DIR
            else:
                self.skill_dir = _PROJECT_SKILL_DIR
        else:
            self.skill_dir = skill_dir

        self.cli_script = os.path.join(self.skill_dir, "scripts", "thai_env_cli.py")
        self.data_dir = os.path.join(self.skill_dir, "scripts", "data")
        self.prefer_direct = prefer_direct
        self._engine: Optional[Any] = None

        if self.prefer_direct:
            scripts_dir = os.path.join(self.skill_dir, "scripts")
            if scripts_dir not in sys.path and os.path.exists(scripts_dir):
                sys.path.insert(0, scripts_dir)
            try:
                from thai_env_engine import ThaiEnvEngine
                if os.path.exists(self.data_dir):
                    self._engine = ThaiEnvEngine(data_dir=self.data_dir)
                else:
                    self._engine = ThaiEnvEngine()
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

    def search_light_standard(
        self,
        query: str = "",
        category: str = "all",
        measured_lux: Optional[float] = None,
        surrounding_lux: Optional[float] = None,
        limit: int = 10
    ) -> Dict[str, Any]:
        """Search lighting intensity standards and optionally evaluate measured lux."""
        if self._engine:
            return self._engine.search_lighting(
                query=query,
                category=category,
                measured_lux=measured_lux,
                surrounding_lux=surrounding_lux,
                limit=limit
            )
        args = ["search-light", "-q", query, "-c", category, "-l", str(limit)]
        if measured_lux is not None:
            args += ["-v", str(measured_lux)]
        if surrounding_lux is not None:
            args += ["-s", str(surrounding_lux)]
        return self._run_cli(args)

    def eval_noise_exposure(
        self,
        measured_dba: float,
        duration_hours: float = 8.0,
        peak_db: Optional[float] = None,
        noise_type: str = "continuous"
    ) -> Dict[str, Any]:
        """Evaluate 8-hr TWA noise exposure, Action Level, and Hearing Conservation requirements."""
        if self._engine:
            return self._engine.evaluate_noise(
                measured_dba=measured_dba,
                duration_hours=duration_hours,
                peak_db=peak_db,
                noise_type=noise_type
            )
        args = ["eval-noise", "-v", str(measured_dba), "-t", str(duration_hours), "--type", noise_type]
        if peak_db is not None:
            args += ["--peak-db", str(peak_db)]
        return self._run_cli(args)

    def calc_wbgt(
        self,
        nwb: float,
        gt: float,
        db: Optional[float] = None,
        is_outdoor: bool = False,
        workload_category: str = "moderate",
        metabolic_rate: Optional[float] = None
    ) -> Dict[str, Any]:
        """Calculate Indoor/Outdoor WBGT heat stress and evaluate against workload limits."""
        if self._engine:
            return self._engine.calculate_wbgt(
                nwb=nwb,
                gt=gt,
                db=db,
                is_outdoor=is_outdoor,
                workload_category=workload_category,
                metabolic_rate=metabolic_rate
            )
        args = ["calc-wbgt", "--nwb", str(nwb), "--gt", str(gt), "-w", workload_category]
        if is_outdoor:
            args.append("--outdoor")
            if db is not None:
                args += ["--db", str(db)]
        if metabolic_rate is not None:
            args += ["-m", str(metabolic_rate)]
        return self._run_cli(args)

    def evaluate_session(self, session_data_or_file: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """Batch evaluate workplace environmental monitoring session."""
        if self._engine:
            return self._engine.evaluate_session(session_data_or_file)
        if isinstance(session_data_or_file, str) and os.path.exists(session_data_or_file):
            return self._run_cli(["eval-session", "-f", session_data_or_file])
        else:
            payload_str = session_data_or_file if isinstance(session_data_or_file, str) else json.dumps(session_data_or_file, ensure_ascii=False)
            return self._run_cli(["eval-session", "-d", payload_str])

    def verify_subcontractor(
        self,
        license_type: str,
        license_no: str,
        expiry_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """Verify Section 9 or Section 11 subcontractor license credentials."""
        if self._engine:
            return self._engine.verify_subcontractor(
                license_type=license_type,
                license_no=license_no,
                expiry_date=expiry_date
            )
        args = ["verify-subcontractor", "-t", license_type, "-n", license_no]
        if expiry_date:
            args += ["-e", expiry_date]
        return self._run_cli(args)

    def get_env_law(self, topic: str = "all", section: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve statutory articles and provisions for heat, light, and noise."""
        if self._engine:
            return self._engine.get_law(topic=topic, section=section)
        args = ["get-env-law", "-t", topic]
        if section:
            args += ["-s", section]
        return self._run_cli(args)
