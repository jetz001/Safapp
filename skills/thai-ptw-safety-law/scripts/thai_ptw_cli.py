#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
==============================================================================
 Thai PTW Safety Law CLI (thai_ptw_cli.py)
 Conforming to Thai Royal Gazette PTW Safety Regulations.
 Supports subcommands:
   - validate-ptw
   - eval-gas
   - verify-confined-roles
   - get-checklist
   - get-ptw-law
==============================================================================
"""

import io
import os
import sys
import json
import argparse
from typing import Dict, Any

# Ensure UTF-8 output on Windows console
if sys.stdout.encoding != "utf-8":
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass

if sys.stderr.encoding != "utf-8":
    try:
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass

# Ensure scripts dir in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from thai_ptw_engine import ThaiPtwEngine


def format_table_output(data: Dict[str, Any], subcommand: str) -> str:
    """Format structured dictionary into human-readable summary text table."""
    lines = []
    lines.append("=" * 70)
    lines.append(f" THAI PTW SAFETY LAW EVALUATION REPORT [{subcommand.upper()}]")
    lines.append("=" * 70)

    if subcommand == "eval-gas":
        lines.append(f"Overall Verdict: {data.get('overall_status')} (Safe: {data.get('is_safe')})")
        lines.append(f"Statutory Basis: {data.get('statutory_reference')}")
        lines.append("-" * 70)
        readings = data.get("readings", {})
        lines.append(f"{'GAS PARAMETER':<20} | {'VALUE':<10} | {'STANDARD':<18} | {'STATUS'}")
        lines.append("-" * 70)
        for k, v in readings.items():
            lines.append(f"{k.upper():<20} | {v.get('value')} {v.get('unit'):<6} | {v.get('standard_range', v.get('standard_limit', '')):<18} | {v.get('status')}")
        if data.get("actions"):
            lines.append("-" * 70)
            lines.append("Mandatory Safety Actions:")
            for act in data["actions"]:
                lines.append(f"  • {act}")

    elif subcommand == "verify-confined-roles":
        lines.append(f"Verdict: {data.get('verdict')} (Valid: {data.get('is_valid')})")
        lines.append(f"Statutory Basis: {data.get('statutory_reference')}")
        lines.append("-" * 70)
        roles = data.get("roles", {})
        lines.append(f"1. ผู้อนุญาต (Authorizer): {roles.get('authorizer', {}).get('name', 'N/A')} (Cert: {roles.get('authorizer', {}).get('cert_no', 'N/A')})")
        lines.append(f"2. ผู้ควบคุมงาน (Supervisor): {roles.get('supervisor', {}).get('name', 'N/A')} (Cert: {roles.get('supervisor', {}).get('cert_no', 'N/A')})")
        lines.append(f"3. ผู้ช่วยเหลือ (Attendant): {roles.get('attendant', {}).get('name', 'N/A')} (Cert: {roles.get('attendant', {}).get('cert_no', 'N/A')})")
        lines.append(f"4. ผู้ปฏิบัติงาน (Entrants): {len(roles.get('entrants', []))} persons")
        for ent in roles.get("entrants", []):
            lines.append(f"     - {ent.get('name')} (Cert: {ent.get('cert_no')})")
        if data.get("conflict_issues"):
            lines.append("-" * 70)
            lines.append("CRITICAL CONFLICTS:")
            for conf in data["conflict_issues"]:
                lines.append(f"  [X] {conf}")

    elif subcommand == "validate-ptw":
        lines.append(f"PTW Number: {data.get('ptw_number')} | Type: {data.get('work_type')}")
        lines.append(f"Status Badge: {data.get('status_badge')} | Compliant: {data.get('is_compliant')}")
        lines.append(f"Validation Score: {data.get('validation_score')}%")
        lines.append("-" * 70)
        if data.get("findings"):
            lines.append(f"Findings ({len(data['findings'])} issues):")
            for f in data["findings"]:
                lines.append(f"  [{f.get('severity')}] {f.get('message')}")
        else:
            lines.append("All statutory safety checks PASSED with 0 non-compliances.")

    elif subcommand == "get-checklist":
        lines.append(f"Work Type: {data.get('work_type')} (Total Items: {data.get('total_items')})")
        lines.append("-" * 70)
        for it in data.get("items", []):
            m_tag = "[MANDATORY]" if it.get("is_mandatory") else "[OPTIONAL]"
            lines.append(f"{it.get('item_id')} {m_tag} {it.get('title_th')}")
            lines.append(f"    {it.get('description_th')}")

    elif subcommand == "get-ptw-law":
        if "laws" in data:
            lines.append(f"Topic: {data.get('topic')} (Found {data.get('total_found')} laws)")
            lines.append("-" * 70)
            for l in data.get("laws", []):
                lines.append(f"[{l.get('law_id')}] {l.get('title_th')}")
                for art in l.get("articles", []):
                    lines.append(f"  - {art.get('article_no')}: {art.get('title')}")
                    lines.append(f"    {art.get('enforcement_summary')}")
        elif "results" in data:
            lines.append(f"Search Query: '{data.get('query')}' (Found {data.get('total_found')} results)")
            lines.append("-" * 70)
            for res in data.get("results", []):
                lines.append(f"[{res.get('law_id')} - {res.get('article_no')}] {res.get('title')}")
                lines.append(f"  {res.get('enforcement_summary')}")
                lines.append(f"  Penalty: {res.get('penalty_clause')}")

    lines.append("=" * 70)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Thai PTW Safety Law CLI — Statutory validation and legal reference tool.",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # Subcommand: validate-ptw
    p_val = subparsers.add_parser("validate-ptw", help="Validate complete PTW payload against Thai safety laws")
    p_val.add_argument("-f", "--file", help="Path to PTW JSON file")
    p_val.add_argument("-d", "--data", help="Raw JSON string of PTW payload")
    p_val.add_argument("-t", "--type", help="PTW type filter (hot_work, confined_space, working_at_height, electrical_loto, excavation_lifting)")
    p_val.add_argument("--format", choices=["json", "table"], default="json", help="Output format (default: json)")
    p_val.add_argument("-o", "--output", help="Optional output file path")

    # Subcommand: eval-gas
    p_gas = subparsers.add_parser("eval-gas", help="Evaluate atmospheric gas testing values (O2, LEL, CO, H2S)")
    p_gas.add_argument("--o2", type=float, required=True, help="Oxygen volume percentage (e.g. 20.9)")
    p_gas.add_argument("--lel", type=float, required=True, help="Combustible gas % LEL (e.g. 0.0)")
    p_gas.add_argument("--co", type=float, required=True, help="Carbon monoxide ppm (e.g. 0.0)")
    p_gas.add_argument("--h2s", type=float, required=True, help="Hydrogen sulfide ppm (e.g. 0.0)")
    p_gas.add_argument("--type", default="pre_entry", choices=["pre_entry", "continuous"], help="Measurement type")
    p_gas.add_argument("--interval", type=float, help="Continuous interval in hours")
    p_gas.add_argument("--format", choices=["json", "table"], default="json", help="Output format (default: json)")
    p_gas.add_argument("-o", "--output", help="Optional output file path")

    # Subcommand: verify-confined-roles
    p_roles = subparsers.add_parser("verify-confined-roles", help="Verify 4 Confined Space statutory duty holders")
    p_roles.add_argument("-f", "--file", help="Path to roles JSON file")
    p_roles.add_argument("-d", "--data", help="Raw JSON string of roles")
    p_roles.add_argument("--authorizer", help="Authorizer name:cert_no")
    p_roles.add_argument("--supervisor", help="Supervisor name:cert_no")
    p_roles.add_argument("--attendant", help="Attendant name:cert_no")
    p_roles.add_argument("--entrants", help="Comma-separated entrant name:cert_no list")
    p_roles.add_argument("--format", choices=["json", "table"], default="json", help="Output format (default: json)")
    p_roles.add_argument("-o", "--output", help="Optional output file path")

    # Subcommand: get-checklist
    p_chk = subparsers.add_parser("get-checklist", help="Retrieve statutory safety checklist items by PTW type")
    p_chk.add_argument("-t", "--type", default="all", choices=["all", "hot_work", "confined_space", "working_at_height", "electrical_loto", "excavation_lifting"], help="Work type")
    p_chk.add_argument("-s", "--sub-category", help="Sub-category filter (e.g. clearance, gas, harness)")
    p_chk.add_argument("--format", choices=["json", "table"], default="json", help="Output format (default: json)")
    p_chk.add_argument("-o", "--output", help="Optional output file path")

    # Subcommand: get-ptw-law
    p_law = subparsers.add_parser("get-ptw-law", help="Retrieve Thai safety laws and Gazette citations")
    p_law.add_argument("-t", "--topic", default="all", help="Law topic filter (osh_2554, confined_2562, fire_2555, electrical_2558, height_2564, all)")
    p_law.add_argument("-s", "--section", help="Section / article search (e.g. ข้อ ๗, มาตรา ๘)")
    p_law.add_argument("-q", "--query", help="Keyword search across statutory articles")
    p_law.add_argument("--format", choices=["json", "table"], default="json", help="Output format (default: json)")
    p_law.add_argument("-o", "--output", help="Optional output file path")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    engine = ThaiPtwEngine()
    result: Dict[str, Any] = {}

    try:
        if args.command == "validate-ptw":
            payload = args.data or args.file
            if not payload:
                print(json.dumps({"status": "error", "message": "Missing PTW data. Provide -f/--file or -d/--data"}, ensure_ascii=False))
                sys.exit(1)
            result = engine.validate_ptw(ptw_payload=payload, work_type=args.type)

        elif args.command == "eval-gas":
            result = engine.evaluate_gas(
                o2=args.o2,
                lel=args.lel,
                co=args.co,
                h2s=args.h2s,
                measurement_type=args.type,
                continuous_interval_hours=args.interval
            )

        elif args.command == "verify-confined-roles":
            if args.data or args.file:
                payload = args.data or args.file
                data = {}
                if isinstance(payload, str) and os.path.exists(payload):
                    with open(payload, "r", encoding="utf-8") as f:
                        data = json.load(f)
                elif isinstance(payload, str):
                    data = json.loads(payload)
                result = engine.verify_confined_roles(roles_payload=data)
            else:
                result = engine.verify_confined_roles(
                    authorizer=args.authorizer,
                    supervisor=args.supervisor,
                    attendant=args.attendant,
                    entrants=args.entrants
                )

        elif args.command == "get-checklist":
            result = engine.get_checklist(ptw_type=args.type, sub_category=args.sub_category)

        elif args.command == "get-ptw-law":
            result = engine.get_ptw_law(topic=args.topic, section=args.section, query=args.query)

        # Output formatting
        if args.format == "table":
            output_str = format_table_output(result, args.command)
        else:
            output_str = json.dumps(result, ensure_ascii=False, indent=2)

        if args.output:
            with open(args.output, "w", encoding="utf-8") as out_f:
                out_f.write(output_str)
        else:
            print(output_str)

        # Exit code evaluation
        if result.get("status") == "error":
            sys.exit(1)
        if args.command == "eval-gas" and not result.get("is_safe", True):
            sys.exit(0) # Standard exit for evaluation result
        sys.exit(0)

    except Exception as ex:
        err_res = {"status": "error", "message": f"CLI execution error: {str(ex)}"}
        print(json.dumps(err_res, ensure_ascii=False, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
