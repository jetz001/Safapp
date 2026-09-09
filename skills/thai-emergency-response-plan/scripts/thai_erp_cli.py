import sys
import os
import json
import argparse
from typing import Optional

# Add parent directory to sys.path
sys.path.insert(0, os.path.dirname(__file__))
from thai_erp_engine import ThaiErpEngine

def write_output(data: dict or list, output_path: Optional[str] = None):
    output_str = json.dumps(data, indent=2, ensure_ascii=False)
    if output_path:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(output_str)
        print(f"Success! Output written to: {output_path}")
    else:
        print(output_str)

def main():
    parser = argparse.ArgumentParser(
        description="Thai Multi-Hazard Emergency Response Plan (ERP) & Fire Drill CLI Validator"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # 1. validate-plan
    p_validate = subparsers.add_parser("validate-plan", help="Validate 6 statutory sub-plans of an ERP")
    p_validate.add_argument("--input-json", required=True, help="Path to ERP JSON file")
    p_validate.add_argument("--hazard-type", default="FIRE", choices=["FIRE", "CHEMICAL", "FLOOD", "EARTHQUAKE", "CUSTOM"], help="Type of hazard")
    p_validate.add_argument("--output", help="Optional output file path")

    # 2. audit-drill
    p_drill = subparsers.add_parser("audit-drill", help="Audit fire drill compliance & 30-day Form Spr.4 deadline")
    p_drill.add_argument("--drill-json", required=True, help="Path to Drill Session JSON file")
    p_drill.add_argument("--current-date", help="Simulated current date YYYY-MM-DD")
    p_drill.add_argument("--output", help="Optional output file path")

    # 3. calc-training-quota
    p_quota = subparsers.add_parser("calc-training-quota", help="Calculate 40% basic fire training quota (Clause 27)")
    p_quota.add_argument("--total-employees", type=int, required=True, help="Total employee headcount")
    p_quota.add_argument("--currently-trained", type=int, default=0, help="Number of trained employees")
    p_quota.add_argument("--output", help="Optional output file path")

    # 4. calc-extinguishers
    p_ext = subparsers.add_parser("calc-extinguishers", help="Calculate fire extinguishers and spacing (Clause 11)")
    p_ext.add_argument("--area-sqm", type=float, required=True, help="Floor area in square meters")
    p_ext.add_argument("--hazard-level", default="MEDIUM", choices=["LIGHT", "MEDIUM", "HIGH"], help="Fire hazard severity")
    p_ext.add_argument("--output", help="Optional output file path")

    # 5. get-emergency-law
    p_law = subparsers.add_parser("get-emergency-law", help="Query Thai emergency & fire protection laws")
    p_law.add_argument("--query", required=True, help="Keyword query (e.g., 'ข้อ ๔', 'สปร. ๔', 'ดับเพลิงขั้นต้น')")
    p_law.add_argument("--output", help="Optional output file path")

    # 6. list-presets
    p_pre = subparsers.add_parser("list-presets", help="List smart preset templates for emergency response")
    p_pre.add_argument("--hazard-type", default="ALL", help="Filter by hazard (FIRE, CHEMICAL_SPILL, FLOOD, EARTHQUAKE, ELECTRICAL, ALL)")
    p_pre.add_argument("--output", help="Optional output file path")

    # 7. audit-electrical
    p_elec = subparsers.add_parser("audit-electrical", help="Audit annual electrical inspection & Form 56289 compliance (Clause 12)")
    p_elec.add_argument("--inspection-json", required=True, help="Path to Electrical Inspection JSON file")
    p_elec.add_argument("--current-date", help="Simulated current date YYYY-MM-DD")
    p_elec.add_argument("--output", help="Optional output file path")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    engine = ThaiErpEngine()

    try:
        if args.command == "validate-plan":
            with open(args.input_json, 'r', encoding='utf-8') as f:
                plan_data = json.load(f)
            res = engine.validate_plan(plan_data, hazard_type=args.hazard_type)
            write_output(res, args.output)

        elif args.command == "audit-drill":
            with open(args.drill_json, 'r', encoding='utf-8') as f:
                drill_data = json.load(f)
            res = engine.audit_drill(drill_data, current_date=args.current_date)
            write_output(res, args.output)

        elif args.command == "calc-training-quota":
            res = engine.calc_training_quota(
                total_employees=args.total_employees,
                currently_trained=args.currently_trained,
            )
            write_output(res, args.output)

        elif args.command == "calc-extinguishers":
            res = engine.calc_extinguishers(
                area_sqm=args.area_sqm,
                hazard_level=args.hazard_level,
            )
            write_output(res, args.output)

        elif args.command == "get-emergency-law":
            res = engine.get_emergency_law(query=args.query)
            write_output(res, args.output)

        elif args.command == "list-presets":
            res = engine.list_presets(hazard_type=args.hazard_type)
            write_output(res, args.output)

        elif args.command == "audit-electrical":
            with open(args.inspection_json, 'r', encoding='utf-8') as f:
                elec_data = json.load(f)
            res = engine.audit_electrical_inspection(elec_data, current_date=args.current_date)
            write_output(res, args.output)

    except Exception as e:
        sys.stderr.write(f"Error executing command {args.command}: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
