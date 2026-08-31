# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

"""
==============================================================================
 Thai Chemical Safety Law CLI Tool (thai_chem_cli.py)
 Conforming to Royal Thai Gazette:
   - Ministerial Regulation B.E. 2556 (Hazardous Chemicals Safety)
   - Hazardous Chemicals List (1,516 items)
   - Threshold Limit Values (TLV) Notification (324 items)
   - Form Sor.Or. 1 (สอ.๑ - SDS 16 GHS Sections)
   - Form Sor.Or. 3 (สอ.๓ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕ - Workplace Measurement)
==============================================================================
"""

import sys
import os
import json
import argparse
import io
from typing import Dict, Any, List, Optional

# Ensure UTF-8 I/O across platforms (Windows / Linux / macOS)
if sys.stdout.encoding != "utf-8":
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass

# Ensure local script directory is in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from thai_chem_law import ThaiChemLawEngine
from sds_validator import SDSValidator

def main():
    parser = argparse.ArgumentParser(
        prog="thai_chem_cli.py",
        description="Thai Chemical Safety Law CLI — Search 1,516 chemicals, evaluate 324 TLVs, retrieve legal articles & verify SDS 16 sections"
    )
    subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommands")

    # 1. SEARCH
    p_search = subparsers.add_parser("search", help="Search 1,516 Thai regulated chemicals by Thai/English name or CAS No.")
    p_search.add_argument("-q", "--query", required=True, help="Thai name, English name, CAS No, or UN No.")
    p_search.add_argument("-l", "--limit", type=int, default=10, help="Maximum results to return (default: 10)")
    p_search.add_argument("-o", "--output", help="Output JSON file path")

    # 2. GET-TLV
    p_tlv = subparsers.add_parser("get-tlv", help="Lookup 324 TLV standards (TWA/STEL/Ceiling) and evaluate measured concentration")
    p_tlv.add_argument("-q", "--query", required=True, help="Chemical name or CAS number")
    p_tlv.add_argument("--eval-val", type=float, help="Measured concentration value to evaluate")
    p_tlv.add_argument("--eval-type", choices=["twa", "stel", "ceiling"], default="twa", help="Measurement type (default: twa)")
    p_tlv.add_argument("--eval-unit", choices=["ppm", "mg_m3", "mg/m3"], default="ppm", help="Concentration unit (default: ppm)")
    p_tlv.add_argument("-o", "--output", help="Output JSON file path")

    # 3. GET-LAW
    p_law = subparsers.add_parser("get-law", help="Retrieve statutory provisions, Sor.Or.1 schema, and Sor.Or.3 guidelines")
    p_law.add_argument(
        "-t", "--topic",
        choices=["all", "regulation_2556", "sor_or_1", "sor_or_3_2565", "registered_testers", "storage_rules", "medical_check", "penalties"],
        default="all",
        help="Legal topic to retrieve (default: all)"
    )
    p_law.add_argument("-s", "--section", help="Specific article or section")
    p_law.add_argument("-o", "--output", help="Output JSON file path")

    # 4. VERIFY-SDS
    p_sds = subparsers.add_parser("verify-sds", help="Validate 16 GHS sections in SDS JSON document")
    p_sds.add_argument("-f", "--file", required=True, help="Path to SDS JSON file")
    p_sds.add_argument("-o", "--output", help="Output JSON file path")

    # 5. EVAL-MIXTURE
    p_mix = subparsers.add_parser("eval-mixture", help="Evaluate additive exposure index (Em) for chemical mixtures")
    p_mix.add_argument("-f", "--file", help="Path to JSON file containing list of component measurements")
    p_mix.add_argument("-c", "--components", help="Raw JSON string containing list of component measurements")
    p_mix.add_argument("-o", "--output", help="Output JSON file path")

    # 6. CONVERT-UNIT
    p_conv = subparsers.add_parser("convert-unit", help="Convert gas/vapor concentrations between ppm and mg/m3")
    p_conv.add_argument("-v", "--value", type=float, required=True, help="Value to convert")
    p_conv.add_argument("--from-unit", choices=["ppm", "mg_m3", "mg/m3"], required=True, help="Source unit")
    p_conv.add_argument("--to-unit", choices=["ppm", "mg_m3", "mg/m3"], required=True, help="Target unit")
    p_conv.add_argument("--mw", type=float, required=True, help="Molecular weight (g/mol)")
    p_conv.add_argument("--temp", type=float, default=25.0, help="Temperature in Celsius (default: 25.0)")
    p_conv.add_argument("--pressure", type=float, default=1.0, help="Atmospheric pressure in atm (default: 1.0)")
    p_conv.add_argument("-o", "--output", help="Output JSON file path")

    args = parser.parse_args()

    engine = ThaiChemLawEngine()
    validator = SDSValidator(engine)

    result: Dict[str, Any] = {}

    try:
        if args.command == "search":
            result = engine.search_chemical(args.query, limit=args.limit)
        elif args.command == "get-tlv":
            result = engine.get_tlv(
                query=args.query,
                eval_val=args.eval_val,
                eval_type=args.eval_type,
                eval_unit=args.eval_unit
            )
        elif args.command == "get-law":
            result = engine.get_law(topic=args.topic, section=args.section)
        elif args.command == "verify-sds":
            result = validator.verify_sds_file(args.file)
        elif args.command == "eval-mixture":
            components = []
            if args.file:
                with open(args.file, "r", encoding="utf-8") as f:
                    components = json.load(f)
            elif args.components:
                components = json.loads(args.components)
            result = engine.calculate_mixture_index(components)
        elif args.command == "convert-unit":
            result = engine.convert_units(
                value=args.value,
                from_unit=args.from_unit,
                to_unit=args.to_unit,
                mw=args.mw,
                temp_c=args.temp,
                pressure_atm=args.pressure
            )
    except Exception as e:
        result = {
            "status": "error",
            "message": str(e)
        }

    output_json = json.dumps(result, ensure_ascii=False, indent=2)

    if getattr(args, "output", None):
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_json)
        print(f"Result successfully saved to: {args.output}")
    else:
        print(output_json)

if __name__ == "__main__":
    main()
