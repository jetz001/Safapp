# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

"""
==============================================================================
 Thai Safety Legal Register CLI Tool (thai_safety_legal_cli.py)
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

import sys
import os
import json
import argparse
import io
from typing import Dict, Any, Optional

# Ensure UTF-8 I/O across platforms (Windows / Linux / macOS)
if sys.stdout.encoding != "utf-8":
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
        sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass

# Ensure local script directory is in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from thai_safety_legal_engine import ThaiSafetyLegalEngine


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="thai_safety_legal_cli.py",
        description="Thai Safety Legal Register CLI — Search 8 Royal Gazette safety laws, retrieve articles, evaluate workplace compliance & generate CAPA action plans."
    )
    parser.add_argument("--json", action="store_true", help="Ensure JSON output mode (default)")
    subparsers = parser.add_subparsers(dest="command", required=True, help="Available subcommands")

    # 1. SEARCH
    p_search = subparsers.add_parser(
        "search",
        help="Search statutory provisions, articles, and requirements by keyword, category, or Royal Gazette citation"
    )
    p_search.add_argument("-q", "--query", required=True, help="Search query (e.g. 'จป.วิชาชีพ', 'ดับเพลิง', 'ปั้นจั่น', 'หม้อน้ำ', 'WBGT', 'สอ.๑')")
    p_search.add_argument(
        "-c", "--category",
        default="all",
        help="Filter by category (all, act_2554, jpor_cpo_2565, chemical_2556, fire_2555, electrical_2558, machinery_crane_boiler_2564, environment_2559, health_check_2563)"
    )
    p_search.add_argument("-l", "--limit", type=int, default=10, help="Maximum results to return (default: 10)")
    p_search.add_argument("-o", "--output", help="Output JSON file path")

    # 2. GET-LAW
    p_law = subparsers.add_parser(
        "get-law",
        help="Retrieve full text, statutory provisions, gazette citations and penalties for a specific law"
    )
    p_law.add_argument("-i", "--id", required=True, help="Law ID or alias (e.g. LAW-01..LAW-08, LAW-OSH-2554, jpor_2565, fire_2555, chem_2556)")
    p_law.add_argument("-s", "--section", help="Specific article number, requirement ID, or form name")
    p_law.add_argument("-o", "--output", help="Output JSON file path")

    # 3. EVALUATE
    p_eval = subparsers.add_parser(
        "evaluate",
        help="Evaluate workplace compliance against 8 safety regulations based on operational profile"
    )
    p_eval.add_argument("-p", "--profile", help="File path to workplace profile JSON")
    p_eval.add_argument("-d", "--data", help="Raw JSON string containing workplace profile")
    p_eval.add_argument("-o", "--output", help="Output JSON file path")

    # 4. CAPA-SUMMARY
    p_capa = subparsers.add_parser(
        "capa-summary",
        help="Generate prioritized Corrective & Preventive Action (CAPA) plans with root causes and timelines"
    )
    p_capa.add_argument("-e", "--eval-file", help="Path to evaluation result JSON file")
    p_capa.add_argument("-i", "--items", help="Comma-separated list of requirement IDs (e.g. 'LAW-02-REQ-04,LAW-05-REQ-01')")
    p_capa.add_argument("-o", "--output", help="Output JSON file path")

    args = parser.parse_args()

    engine = ThaiSafetyLegalEngine()
    result: Dict[str, Any] = {}

    if args.command == "search":
        result = engine.search_laws(
            query=args.query,
            category=args.category,
            limit=args.limit
        )

    elif args.command == "get-law":
        result = engine.get_law(
            law_id=args.id,
            section=args.section
        )

    elif args.command == "evaluate":
        if not args.profile and not args.data:
            result = {
                "status": "error",
                "message": "Either --profile (file path) or --data (raw JSON string) must be provided."
            }
        else:
            profile_input = args.profile if args.profile else args.data
            result = engine.evaluate_compliance(profile_input)

    elif args.command == "capa-summary":
        if not args.eval_file and not args.items:
            result = {
                "status": "error",
                "message": "Either --eval-file (path to evaluation JSON) or --items (comma-separated requirement IDs) must be provided."
            }
        else:
            eval_dict = None
            if args.eval_file and os.path.exists(args.eval_file):
                try:
                    with open(args.eval_file, "r", encoding="utf-8") as ef:
                        eval_dict = json.load(ef)
                except Exception as ex:
                    result = {"status": "error", "message": f"Failed to read eval file: {str(ex)}"}
                    print(json.dumps(result, ensure_ascii=False, indent=2))
                    return 1

            result = engine.generate_capa(
                eval_data=eval_dict,
                item_ids=args.items
            )

    else:
        result = {"status": "error", "message": f"Unknown command: {args.command}"}

    # Print formatted JSON to stdout
    json_output = json.dumps(result, ensure_ascii=False, indent=2)
    print(json_output)

    # If --output specified, write to file
    if getattr(args, "output", None):
        try:
            with open(args.output, "w", encoding="utf-8") as out_f:
                out_f.write(json_output)
        except Exception as e:
            sys.stderr.write(f"Warning: Failed to write output file: {str(e)}\n")

    return 0 if result.get("status") == "success" else 1


if __name__ == "__main__":
    sys.exit(main())
