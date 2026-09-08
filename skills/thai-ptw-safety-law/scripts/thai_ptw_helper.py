"""
==============================================================================
 Thai PTW Safety Law Helper for Multi-Agent Workflows
 Conforming to 5 Thai Royal Gazette Safety Regulations:
   1. OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
   2. Ministerial Reg. Confined Space B.E. 2562 (กฎกระทรวงอับอากาศ ๒๕๖๒)
   3. Ministerial Reg. Fire Safety B.E. 2555 (กฎกระทรวงอัคคีภัย ๒๕๕๕ - Hot Work)
   4. Ministerial Reg. Electrical Safety B.E. 2558 (กฎกระทรวงไฟฟ้า ๒๕๕๘ - LOTO)
   5. Ministerial Reg. Height & Excavation B.E. 2564 (กฎกระทรวงงานบนที่สูงและดินขุด ๒๕๖๔)
==============================================================================
"""

import os
import sys
import json
import subprocess
from typing import Dict, Any, List, Optional, Union

# Known default skill directories
_DEFAULT_CONFIG_DIR = os.path.expanduser(r"~\.gemini\config\skills\thai-ptw-safety-law")
_PROJECT_SKILL_DIR = r"d:\DEV\SAFAPP\skills\thai-ptw-safety-law"

if os.path.exists(_DEFAULT_CONFIG_DIR):
    SKILL_DIR = _DEFAULT_CONFIG_DIR
elif os.path.exists(_PROJECT_SKILL_DIR):
    SKILL_DIR = _PROJECT_SKILL_DIR
else:
    SKILL_DIR = _DEFAULT_CONFIG_DIR

SCRIPTS_DIR = os.path.join(SKILL_DIR, "scripts")
DATA_DIR = os.path.join(SCRIPTS_DIR, "data")
CLI_SCRIPT = os.path.join(SCRIPTS_DIR, "thai_ptw_cli.py")

# Ensure script dir in sys.path
if SCRIPTS_DIR not in sys.path and os.path.exists(SCRIPTS_DIR):
    sys.path.insert(0, SCRIPTS_DIR)


class ThaiPtwHelper:
    """Dual-mode Python Helper for querying Thai PTW safety laws and evaluating permit compliance."""

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

        self.cli_script = os.path.join(self.skill_dir, "scripts", "thai_ptw_cli.py")
        self.data_dir = os.path.join(self.skill_dir, "scripts", "data")
        self.prefer_direct = prefer_direct
        self._engine: Optional[Any] = None

        if self.prefer_direct:
            scripts_dir = os.path.join(self.skill_dir, "scripts")
            if scripts_dir not in sys.path and os.path.exists(scripts_dir):
                sys.path.insert(0, scripts_dir)
            try:
                from thai_ptw_engine import ThaiPtwEngine
                if os.path.exists(self.data_dir):
                    self._engine = ThaiPtwEngine(data_dir=self.data_dir)
                else:
                    self._engine = ThaiPtwEngine()
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
                    check=False
                )
                if res.stdout.strip():
                    return json.loads(res.stdout)
                else:
                    return {
                        "status": "error",
                        "message": f"CLI returned empty output (exit {res.returncode}): {res.stderr}",
                        "cmd": cmd
                    }
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

    def validate_ptw(
        self,
        ptw_payload_or_file: Union[Dict[str, Any], str],
        work_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Validate complete PTW request against statutory checklist, gas limits, roles, and safety controls."""
        if self._engine:
            return self._engine.validate_ptw(ptw_payload=ptw_payload_or_file, work_type=work_type)

        if isinstance(ptw_payload_or_file, str) and os.path.exists(ptw_payload_or_file):
            args = ["validate-ptw", "-f", ptw_payload_or_file]
        elif isinstance(ptw_payload_or_file, str):
            args = ["validate-ptw", "-d", ptw_payload_or_file]
        else:
            args = ["validate-ptw", "-d", json.dumps(ptw_payload_or_file, ensure_ascii=False)]

        if work_type:
            args += ["-t", work_type]

        return self._run_cli(args)

    def eval_gas(
        self,
        o2: float,
        lel: float,
        co: float,
        h2s: float,
        measurement_type: str = "pre_entry",
        continuous_interval_hours: Optional[float] = None
    ) -> Dict[str, Any]:
        """Evaluate atmospheric gas testing values against Ministerial Reg. Confined Space 2562 (ข้อ ๗)."""
        if self._engine:
            return self._engine.evaluate_gas(
                o2=o2,
                lel=lel,
                co=co,
                h2s=h2s,
                measurement_type=measurement_type,
                continuous_interval_hours=continuous_interval_hours
            )

        args = [
            "eval-gas",
            "--o2", str(o2),
            "--lel", str(lel),
            "--co", str(co),
            "--h2s", str(h2s),
            "--type", measurement_type
        ]
        if continuous_interval_hours is not None:
            args += ["--interval", str(continuous_interval_hours)]

        return self._run_cli(args)

    def evaluate_gas(
        self,
        o2: float,
        lel: float,
        co: float,
        h2s: float,
        measurement_type: str = "pre_entry",
        continuous_interval_hours: Optional[float] = None
    ) -> Dict[str, Any]:
        """Alias for eval_gas."""
        return self.eval_gas(o2, lel, co, h2s, measurement_type, continuous_interval_hours)

    def verify_confined_roles(
        self,
        roles_payload_or_file: Optional[Union[Dict[str, Any], str]] = None,
        authorizer: Optional[Union[Dict[str, Any], str]] = None,
        supervisor: Optional[Union[Dict[str, Any], str]] = None,
        attendant: Optional[Union[Dict[str, Any], str]] = None,
        entrants: Optional[Union[List[Any], str]] = None
    ) -> Dict[str, Any]:
        """Verify statutory completeness and separation of 4 Confined Space roles (ข้อ ๙, ๑๐, ๑๑, ๑๒)."""
        if self._engine:
            if roles_payload_or_file:
                if isinstance(roles_payload_or_file, str) and os.path.exists(roles_payload_or_file):
                    with open(roles_payload_or_file, "r", encoding="utf-8") as f:
                        payload = json.load(f)
                    return self._engine.verify_confined_roles(roles_payload=payload)
                elif isinstance(roles_payload_or_file, str):
                    payload = json.loads(roles_payload_or_file)
                    return self._engine.verify_confined_roles(roles_payload=payload)
                elif isinstance(roles_payload_or_file, dict):
                    return self._engine.verify_confined_roles(roles_payload=roles_payload_or_file)
            return self._engine.verify_confined_roles(
                authorizer=authorizer,
                supervisor=supervisor,
                attendant=attendant,
                entrants=entrants
            )

        if roles_payload_or_file:
            if isinstance(roles_payload_or_file, str) and os.path.exists(roles_payload_or_file):
                return self._run_cli(["verify-confined-roles", "-f", roles_payload_or_file])
            elif isinstance(roles_payload_or_file, str):
                return self._run_cli(["verify-confined-roles", "-d", roles_payload_or_file])
            else:
                return self._run_cli(["verify-confined-roles", "-d", json.dumps(roles_payload_or_file, ensure_ascii=False)])

        args = ["verify-confined-roles"]
        if authorizer:
            auth_str = authorizer if isinstance(authorizer, str) else f"{authorizer.get('name')}:{authorizer.get('cert_no', '')}"
            args += ["--authorizer", auth_str]
        if supervisor:
            sup_str = supervisor if isinstance(supervisor, str) else f"{supervisor.get('name')}:{supervisor.get('cert_no', '')}"
            args += ["--supervisor", sup_str]
        if attendant:
            att_str = attendant if isinstance(attendant, str) else f"{attendant.get('name')}:{attendant.get('cert_no', '')}"
            args += ["--attendant", att_str]
        if entrants:
            if isinstance(entrants, list):
                ent_list = []
                for e in entrants:
                    if isinstance(e, dict):
                        ent_list.append(f"{e.get('name')}:{e.get('cert_no', '')}")
                    else:
                        ent_list.append(str(e))
                args += ["--entrants", ",".join(ent_list)]
            else:
                args += ["--entrants", str(entrants)]

        return self._run_cli(args)

    def check_hotwork_firewatch(
        self,
        monitoring_minutes: float,
        fire_watcher_name: str,
        extinguisher_ready: bool,
        area_cleared_11m: bool = True
    ) -> Dict[str, Any]:
        """Verify Hot Work fire safety and 30-minute post-work monitoring requirement."""
        if self._engine:
            return self._engine.evaluate_fire_watch(
                monitoring_minutes=monitoring_minutes,
                fire_watcher_name=fire_watcher_name,
                extinguisher_ready=extinguisher_ready,
                area_cleared_11m=area_cleared_11m
            )
        # Direct evaluation if engine unavailable
        is_valid = bool(fire_watcher_name) and bool(extinguisher_ready) and bool(area_cleared_11m) and (monitoring_minutes >= 30.0)
        return {
            "status": "success",
            "is_valid": is_valid,
            "verdict": "FIRE_WATCH_COMPLIANT" if is_valid else "FIRE_WATCH_NON_COMPLIANT",
            "details": {
                "fire_watcher_name": fire_watcher_name,
                "extinguisher_ready": extinguisher_ready,
                "area_cleared_11m": area_cleared_11m,
                "monitoring_minutes": monitoring_minutes,
                "required_minutes": 30.0
            }
        }

    def verify_loto(
        self,
        isolation_points: List[Dict[str, Any]],
        zero_energy_verified: bool
    ) -> Dict[str, Any]:
        """Verify Lockout/Tagout energy isolation points and zero energy verification."""
        if self._engine:
            return self._engine.verify_loto(
                isolation_points=isolation_points,
                zero_energy_verified=zero_energy_verified
            )
        is_valid = bool(isolation_points) and len(isolation_points) > 0 and bool(zero_energy_verified)
        return {
            "status": "success",
            "is_valid": is_valid,
            "verdict": "LOTO_ISOLATION_VALID" if is_valid else "LOTO_ISOLATION_INCOMPLETE",
            "total_points": len(isolation_points or []),
            "zero_energy_verified": zero_energy_verified
        }

    def get_checklist(
        self,
        ptw_type: str = "all",
        sub_category: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve statutory safety checklist items by work type."""
        if self._engine:
            return self._engine.get_checklist(ptw_type=ptw_type, sub_category=sub_category)

        args = ["get-checklist", "-t", ptw_type]
        if sub_category:
            args += ["-s", sub_category]
        return self._run_cli(args)

    def get_ptw_law(
        self,
        topic: str = "all",
        section: Optional[str] = None,
        query: Optional[str] = None
    ) -> Dict[str, Any]:
        """Retrieve Thai safety laws, Gazette citations, and penalty clauses."""
        if self._engine:
            return self._engine.get_ptw_law(topic=topic, section=section, query=query)

        args = ["get-ptw-law", "-t", topic]
        if section:
            args += ["-s", section]
        if query:
            args += ["-q", query]
        return self._run_cli(args)

    def search_laws(self, query: str, topic: str = "all", limit: int = 10) -> Dict[str, Any]:
        """Search legal articles by keyword query."""
        if self._engine:
            return self._engine.search_laws(query=query, topic=topic, limit=limit)
        return self.get_ptw_law(topic=topic, query=query)
