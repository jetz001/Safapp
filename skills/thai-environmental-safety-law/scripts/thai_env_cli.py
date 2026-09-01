# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Thai Environmental Safety Law CLI (Command-Line Interface)
Conforming to Royal Thai Gazette Enactments:
  - OSH Act B.E. 2554 (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)
  - Ministerial Reg. Heat, Light, Noise B.E. 2559 (กฎกระทรวงฯ ๒๕๕๙)
  - DLPW Notification Lighting Standards B.E. 2561 (ประกาศกรมฯ แสงสว่าง ๒๕๖๑)
  - DLPW Notification Noise Exposure Standards B.E. 2561 (ประกาศกรมฯ เสียง ๒๕๖๑)
  - DLPW Notification WBGT Calculation & Evaluation B.E. 2563 (ประกาศกรมฯ ความร้อน ๒๕๖๓)
  - DLPW Notification Environmental Reporting Form B.E. 2559 (แบบรายงานผลตรวจวัด สสค. / อธ.๑)
"""

import os
import sys
import io
import json
import argparse
from typing import Dict, Any, List, Optional

# UTF-8 stream setup for cross-platform / Windows PowerShell terminal support
if sys.stdout.encoding != "utf-8":
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
        sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass

# Ensure scripts directory is in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from thai_env_engine import ThaiEnvEngine


def format_table_output(data: Dict[str, Any], command: str) -> str:
    """Format JSON result dictionary into readable text / ASCII table output."""
    lines: List[str] = []
    separator = "=" * 78
    sub_sep = "-" * 78

    lines.append(separator)
    lines.append(f" THAI ENVIRONMENTAL SAFETY LAW EVALUATION REPORT: {command.upper()}")
    lines.append(separator)

    if command == "search-light":
        results = data.get("results", [])
        lines.append(f"Query: '{data.get('query', '')}' | Category: '{data.get('category', 'all')}' | Found: {len(results)}")
        lines.append(sub_sep)
        for i, item in enumerate(results, 1):
            lines.append(f"[{i}] ID: {item.get('id')} | Category: {item.get('category_name_th', item.get('category'))}")
            lines.append(f"    Workplace: {item.get('workplace_type_th')}")
            lines.append(f"    Standard Min: {item.get('standard_lux_min')} Lux | Recommended: {item.get('recommended_lux_range')}")
            if "evaluation" in item:
                ev = item["evaluation"]
                status = "PASS (สอดคล้อง)" if ev.get("is_compliant") else "FAIL (ไม่ผ่านเกณฑ์)"
                lines.append(f"    >>> Evaluation: Measured {ev.get('measured_lux')} Lux -> {status} (Variance: {ev.get('variance_lux'):+g} Lux)")
                lines.append(f"    >>> Recommendation: {ev.get('corrective_recommendation')}")
            lines.append(sub_sep)

    elif command == "eval-noise":
        lines.append(f"Measured Sound Level : {data.get('measured_dba')} dBA (Duration: {data.get('duration_hours')} hrs)")
        if data.get("peak_db") is not None:
            lines.append(f"Peak Sound Level     : {data.get('peak_db')} dB (Statutory Max: 140.0 dB)")
        lines.append(f"8-Hr TWA Limit       : {data.get('statutory_limit_8hr_dba')} dBA | Action Level: {data.get('action_level_dba')} dBA")
        lines.append(f"Calculated 8-Hr TWA  : {data.get('calculated_twa_8hr_dba')} dBA | Noise Dose: {data.get('noise_dose_pct')}%")
        lines.append(f"Max Permissible Time : {data.get('permissible_duration_formatted')}")
        status_text = "PASS (สอดคล้อง)" if data.get("is_compliant") else "FAIL (เกินเกณฑ์มาตรฐาน)"
        lines.append(f"Compliance Status    : {status_text} [{data.get('compliance_status')}]")
        hcp_status = "YES (ต้องจัดทำโครงการ)" if data.get("hearing_conservation_required") else "NO"
        lines.append(f"Hearing Conservation : {hcp_status} -> {data.get('hearing_conservation_reason')}")
        lines.append(f"PPE Recommendation   : {data.get('ppe_recommendation')}")
        lines.append(sub_sep)
        lines.append("Recommended Controls:")
        for ctrl in data.get("recommended_controls", []):
            lines.append(f"  - {ctrl}")

    elif command == "calc-wbgt":
        inputs = data.get("inputs", {})
        lines.append(f"Environment Mode     : {data.get('environment_mode')}")
        lines.append(f"Sensors              : NWB = {inputs.get('nwb_c')}°C, GT = {inputs.get('gt_c')}°C, DB = {inputs.get('db_c')}°C")
        lines.append(f"Formula Used         : {data.get('formula_used')}")
        lines.append(f"Calculated WBGT      : {data.get('calculated_wbgt_c')} °C WBGT")
        lines.append(f"Workload Level       : {data.get('workload_description')}")
        lines.append(f"Statutory Max Limit  : <= {data.get('statutory_limit_wbgt_c')} °C WBGT")
        lines.append(f"Safety Margin        : {data.get('safety_margin_c'):+g} °C")
        status_text = "PASS (อยู่ในเกณฑ์ปลอดภัย)" if data.get("is_compliant") else "FAIL (เกินมาตรฐานเสี่ยงต่อ Heat Stress)"
        lines.append(f"Compliance Status    : {status_text} [{data.get('compliance_status')}]")
        lines.append(sub_sep)
        lines.append("Heat Control Measures:")
        for rec in data.get("recommendations", []):
            lines.append(f"  - {rec}")

    elif command == "eval-session":
        summary = data.get("session_summary", {})
        kpi = summary.get("kpi_metrics", {})
        lines.append(f"Session ID           : {summary.get('session_id')} | Workplace: {summary.get('workplace_name')}")
        lines.append(f"Survey Date / Year   : {summary.get('survey_date')} (พ.ศ. {summary.get('survey_year')})")
        lines.append(sub_sep)
        lines.append("KPI SUMMARY:")
        lines.append(f"  Total Sampling Points : {kpi.get('total_points')}")
        lines.append(f"  Compliant (Pass)      : {kpi.get('compliant_points')}")
        lines.append(f"  Action Level (Watch)  : {kpi.get('action_level_points')}")
        lines.append(f"  Non-Compliant (Fail)  : {kpi.get('non_compliant_points')}")
        lines.append(f"  Compliance Index %    : {kpi.get('compliance_index_pct')}%")
        lines.append(f"  Overall Grade         : {kpi.get('overall_grade')}")
        lines.append(sub_sep)
        capas = data.get("capa_action_plans", [])
        lines.append(f"CAPA ACTION PLANS ({len(capas)} items):")
        for capa in capas:
            lines.append(f"  [{capa.get('capa_id')}] Factor: {capa.get('factor')} | Severity: {capa.get('severity')}")
            lines.append(f"    Location: {capa.get('location_name')} ({capa.get('department')})")
            lines.append(f"    Measured: {capa.get('measured_value')} vs Std: {capa.get('standard_threshold')}")
            lines.append(f"    Action  : {capa.get('corrective_action')}")
            lines.append(f"    PIC     : {capa.get('pic')} | Deadline: {capa.get('target_deadline')}")
        lines.append(sub_sep)
        notices = data.get("statutory_deadlines_notice", {})
        lines.append("OFFICIAL STATUTORY NOTICES:")
        lines.append(f"  - Posting: {notices.get('posting_at_workplace')}")
        lines.append(f"  - DLPW Submission: {notices.get('submission_to_dlpw')}")
        lines.append(f"  - Document Retention: {notices.get('document_retention')}")

    elif command == "verify-subcontractor":
        lines.append(f"Provider Type        : {data.get('license_type_title_th')}")
        lines.append(f"License Number       : {data.get('license_no')}")
        lines.append(f"Format Valid         : {'YES (ถูกต้อง)' if data.get('is_format_valid') else 'NO (ผิดรูปแบบ)'}")
        lines.append(f"Expiry Status        : {data.get('expiry_status')}")
        lines.append(f"Overall Valid        : {'YES (ใช้งานได้)' if data.get('is_valid') else 'NO (ไม่สามารถใช้งานได้)'}")
        lines.append(f"ISO/IEC 17025 Mandate: {data.get('calibration_mandate')}")
        lines.append(f"Penalty Clause       : {data.get('penalty_clause')}")

    elif command == "get-env-law":
        laws = data.get("laws", [])
        lines.append(f"Found {len(laws)} Legal Reference Regulations:")
        for law in laws:
            lines.append(f"  [{law.get('law_id')}] {law.get('title_th')}")
            lines.append(f"    Gazette: {law.get('gazette_volume')} ({law.get('gazette_date')})")
            for art in law.get("enforcement_articles", []):
                lines.append(f"    - {art.get('article')}: {art.get('title')}")
                lines.append(f"      Summary: {art.get('summary')}")
                lines.append(f"      Penalty: {art.get('penalty')}")
            lines.append(sub_sep)

    lines.append(separator)
    return "\n".join(lines)


def output_result(data: Dict[str, Any], command: str, fmt: str = "json", out_file: Optional[str] = None) -> None:
    """Output JSON or Table formatted result to stdout or file."""
    if fmt == "table":
        output_str = format_table_output(data, command)
    else:
        output_str = json.dumps(data, ensure_ascii=False, indent=2)

    if out_file:
        try:
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(output_str)
        except Exception as e:
            sys.stderr.write(f"Error writing output file {out_file}: {e}\n")

    print(output_str)


def build_parser() -> argparse.ArgumentParser:
    """Construct CLI argument parser with all subcommands."""
    parser = argparse.ArgumentParser(
        prog="thai_env_cli",
        description="Thai Environmental Safety Law & Workplace Monitoring CLI (แสงสว่าง, เสียง, ความร้อน WBGT, Subcontractor ม.๙/ม.๑๑)"
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="Subcommand to execute")

    # 1. search-light
    p_light = subparsers.add_parser("search-light", help="Search lighting standards (Lux) and evaluate compliance")
    p_light.add_argument("-q", "--query", type=str, default="", help="Workplace, task, or area keyword")
    p_light.add_argument("-c", "--category", type=str, default="all", help="Category filter (general_area, office_administration, manufacturing_rough, manufacturing_medium, manufacturing_fine, manufacturing_extra_fine, inspection_high_contrast, inspection_low_contrast, specialized_medical)")
    p_light.add_argument("-v", "--measured-val", type=float, default=None, help="Measured Lux value at workstation")
    p_light.add_argument("-s", "--surrounding-val", type=float, default=None, help="Measured surrounding Lux value (0.5m radius)")
    p_light.add_argument("-l", "--limit", type=int, default=10, help="Max results (default: 10)")
    p_light.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_light.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    # 2. eval-noise
    p_noise = subparsers.add_parser("eval-noise", help="Evaluate 8-hr TWA noise exposure, Action Level, and HCP mandate")
    p_noise.add_argument("-v", "--measured-dba", type=float, required=True, help="Measured sound level in dBA")
    p_noise.add_argument("-t", "--duration-hours", type=float, default=8.0, help="Exposure duration in hours (default: 8.0)")
    p_noise.add_argument("--peak-db", type=float, default=None, help="Peak / impact noise level in dB")
    p_noise.add_argument("--type", type=str, choices=["continuous", "intermittent", "impact"], default="continuous", help="Noise character")
    p_noise.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_noise.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    # 3. calc-wbgt
    p_wbgt = subparsers.add_parser("calc-wbgt", help="Calculate Indoor/Outdoor WBGT and evaluate workload heat stress")
    p_wbgt.add_argument("--nwb", type=float, required=True, help="Natural Wet Bulb temperature in °C")
    p_wbgt.add_argument("--gt", type=float, required=True, help="Globe temperature in °C")
    p_wbgt.add_argument("--db", type=float, default=None, help="Dry Bulb air temperature in °C (required for outdoor)")
    p_wbgt.add_argument("--outdoor", action="store_true", help="Set if work environment has direct solar load")
    p_wbgt.add_argument("-w", "--workload", type=str, choices=["light", "moderate", "heavy"], default="moderate", help="Metabolic workload category")
    p_wbgt.add_argument("-m", "--metabolic-rate", type=float, default=None, help="Exact metabolic rate in kcal/hr")
    p_wbgt.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_wbgt.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    # 4. eval-session
    p_sess = subparsers.add_parser("eval-session", help="Batch evaluate entire workplace monitoring session & generate CAPA")
    p_sess.add_argument("-f", "--file", type=str, default=None, help="Session JSON file path")
    p_sess.add_argument("-d", "--data", type=str, default=None, help="Raw session JSON string")
    p_sess.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_sess.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    # 5. verify-subcontractor
    p_sub = subparsers.add_parser("verify-subcontractor", help="Validate Section 9 (นบ.) or Section 11 (บ.) credentials")
    p_sub.add_argument("-t", "--type", type=str, default="section_11_juristic", help="section_9_individual or section_11_juristic")
    p_sub.add_argument("-n", "--license-no", type=str, required=True, help="Registration or License number (e.g. 'นบ. 0123/2565', 'บ. 0045/2560')")
    p_sub.add_argument("-e", "--expiry-date", type=str, default=None, help="Expiry date (YYYY-MM-DD)")
    p_sub.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_sub.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    # 6. get-env-law
    p_law = subparsers.add_parser("get-env-law", help="Retrieve statutory provisions and legal articles")
    p_law.add_argument("-t", "--topic", type=str, default="all", help="Topic or law code (e.g. OSH-ACT-2554, MIN-REG-ENV-2559)")
    p_law.add_argument("-s", "--section", type=str, default=None, help="Specific section or article (e.g. 'ข้อ ๒', 'มาตรา ๑๕')")
    p_law.add_argument("-o", "--output", type=str, default=None, help="Output file path")
    p_law.add_argument("--format", type=str, choices=["json", "table"], default="json", help="Output format")

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if not args.subcommand:
        parser.print_help()
        sys.exit(1)

    engine = ThaiEnvEngine()

    try:
        if args.subcommand == "search-light":
            res = engine.search_lighting(
                query=args.query,
                category=args.category,
                measured_lux=args.measured_val,
                surrounding_lux=args.surrounding_val,
                limit=args.limit
            )
            output_result(res, "search-light", args.format, args.output)

        elif args.subcommand == "eval-noise":
            res = engine.evaluate_noise(
                measured_dba=args.measured_dba,
                duration_hours=args.duration_hours,
                peak_db=args.peak_db,
                noise_type=args.type
            )
            output_result(res, "eval-noise", args.format, args.output)

        elif args.subcommand == "calc-wbgt":
            res = engine.calculate_wbgt(
                nwb=args.nwb,
                gt=args.gt,
                db=args.db,
                is_outdoor=args.outdoor,
                workload_category=args.workload,
                metabolic_rate=args.metabolic_rate
            )
            output_result(res, "calc-wbgt", args.format, args.output)

        elif args.subcommand == "eval-session":
            if not args.file and not args.data:
                # Use embedded sample session if none provided
                sample = engine.standards_data.get("sample_session")
                if not sample:
                    sys.stderr.write("Error: Either --file or --data must be provided for eval-session.\n")
                    sys.exit(1)
                session_payload = sample
            elif args.file:
                session_payload = args.file
            else:
                session_payload = args.data

            res = engine.evaluate_session(session_payload)
            output_result(res, "eval-session", args.format, args.output)

        elif args.subcommand == "verify-subcontractor":
            res = engine.verify_subcontractor(
                license_type=args.type,
                license_no=args.license_no,
                expiry_date=args.expiry_date
            )
            output_result(res, "verify-subcontractor", args.format, args.output)

        elif args.subcommand == "get-env-law":
            res = engine.get_law(
                topic=args.topic,
                section=args.section
            )
            output_result(res, "get-env-law", args.format, args.output)

    except Exception as e:
        err_res = {"status": "error", "message": str(e), "subcommand": args.subcommand}
        output_result(err_res, args.subcommand, "json", args.output)
        sys.exit(1)


if __name__ == "__main__":
    main()
