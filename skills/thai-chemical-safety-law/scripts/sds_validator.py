"""
16-Section GHS Safety Data Sheet (SDS / แบบ สอ.๑) Validator
Validates chemical safety data sheets against Thai Ministerial Regulation B.E. 2556 & Form Sor.Or. 1.
"""

import os
import json
import re
from typing import Dict, Any, List, Optional, Union
from thai_chem_law import ThaiChemLawEngine

class SDSValidator:
    def __init__(self, engine: Optional[ThaiChemLawEngine] = None):
        self.engine = engine or ThaiChemLawEngine()
        self.schema = self.engine.sor_or_1_schema.get("sections", [])
        
        # Build section mapping for flexible key matching
        self._section_key_patterns = {
            1: ["section_1", "sec1", "sec_1", "identification", "ข้อมูลสารเคมี", "1"],
            2: ["section_2", "sec2", "sec_2", "hazard", "hazards", "การบ่งชี้อันตราย", "2"],
            3: ["section_3", "sec3", "sec_3", "composition", "ingredients", "ส่วนประกอบ", "3"],
            4: ["section_4", "sec4", "sec_4", "first_aid", "firstaid", "ปฐมพยาบาล", "4"],
            5: ["section_5", "sec5", "sec_5", "fire_fighting", "firefighting", "ดับเพลิง", "ผจญเพลิง", "5"],
            6: ["section_6", "sec6", "sec_6", "accidental_release", "spill", "หกรั่วไหล", "6"],
            7: ["section_7", "sec7", "sec_7", "handling_storage", "storage", "การจัดเก็บ", "7"],
            8: ["section_8", "sec8", "sec_8", "exposure_controls", "ppe", "การควบคุมการรับสัมผัส", "8"],
            9: ["section_9", "sec9", "sec_9", "physical_chemical", "properties", "คุณสมบัติทางกายภาพ", "9"],
            10: ["section_10", "sec10", "sec_10", "stability_reactivity", "reactivity", "ความเสถียร", "10"],
            11: ["section_11", "sec11", "sec_11", "toxicological", "toxicity", "พิษวิทยา", "11"],
            12: ["section_12", "sec12", "sec_12", "ecological", "ecotoxicity", "ระบบนิเวศน์", "12"],
            13: ["section_13", "sec13", "sec_13", "disposal", "การกำจัด", "13"],
            14: ["section_14", "sec14", "sec_14", "transport", "transportation", "การขนส่ง", "14"],
            15: ["section_15", "sec15", "sec_15", "regulatory", "regulations", "กฎหมาย", "15"],
            16: ["section_16", "sec16", "sec_16", "other", "other_information", "ข้อมูลอื่นๆ", "16"]
        }

    def _find_section_data(self, sds_data: Dict[str, Any], sec_no: int) -> Optional[Any]:
        """Find data for a specific section using known patterns or numbers."""
        patterns = self._section_key_patterns.get(sec_no, [])
        for k, v in sds_data.items():
            k_lower = k.lower().replace("-", "_").replace(" ", "_")
            for pat in patterns:
                if pat in k_lower:
                    return v
        return None

    def verify_sds_data(self, sds_data: Dict[str, Any]) -> Dict[str, Any]:
        """Verify SDS dictionary covering all 16 GHS sections."""
        validation_report: List[Dict[str, Any]] = []
        missing_sections: List[Dict[str, Any]] = []
        valid_sections_count = 0
        recommendations: List[str] = []

        extracted_cas: Optional[str] = None
        extracted_name: Optional[str] = None

        for sec in self.schema:
            sec_no = sec.get("section_no")
            name_th = sec.get("name_th")
            name_en = sec.get("name_en")
            mandatory_fields = sec.get("mandatory_fields", [])

            sec_content = self._find_section_data(sds_data, sec_no)

            if sec_content is None or (isinstance(sec_content, str) and not sec_content.strip()):
                missing_sections.append({
                    "section_no": sec_no,
                    "name_th": name_th,
                    "name_en": name_en
                })
                validation_report.append({
                    "section": sec_no,
                    "title": name_th,
                    "title_en": name_en,
                    "status": "FAIL",
                    "details": "Section missing or empty in SDS document."
                })
                recommendations.append(f"หมวดที่ {sec_no} ({name_th}): ต้องระบุข้อมูลตามแบบ สอ.๑ ให้ครบถ้วน")
            else:
                valid_sections_count += 1
                # Inspect sub-fields if content is a dict
                missing_subfields = []
                if isinstance(sec_content, dict):
                    # Check CAS in Sec 1
                    if sec_no == 1:
                        extracted_cas = sec_content.get("cas_no") or sec_content.get("cas_number") or sec_content.get("cas")
                        extracted_name = sec_content.get("chemical_name") or sec_content.get("trade_name")

                    for req_f in mandatory_fields:
                        found_f = any(req_f.lower() in k.lower() for k in sec_content.keys())
                        if not found_f and req_f not in ["recommended_use", "address", "telephone"]:
                            missing_subfields.append(req_f)

                status_str = "PASS" if not missing_subfields else "WARN"
                detail_str = f"Found complete content ({len(str(sec_content))} chars)." if not missing_subfields else f"Present, but missing recommended fields: {', '.join(missing_subfields)}"
                
                validation_report.append({
                    "section": sec_no,
                    "title": name_th,
                    "title_en": name_en,
                    "status": status_str,
                    "details": detail_str
                })

        total_sections = 16
        compliance_pct = round((valid_sections_count / total_sections) * 100.0, 1)
        is_compliant = (valid_sections_count == total_sections)

        # Cross reference with Thai legal master list
        cross_ref_info = {}
        if extracted_cas or extracted_name:
            query = extracted_cas or extracted_name
            search_res = self.engine.search_chemical(query, limit=1)
            if search_res.get("total_found", 0) > 0:
                match_chem = search_res["results"][0]
                cross_ref_info = {
                    "matched_substance": match_chem["name_en"],
                    "matched_thai_name": match_chem["name_th"],
                    "cas_no": match_chem["cas_no"],
                    "is_regulated_1516": match_chem["is_regulated_1516"],
                    "has_tlv_324": match_chem["has_tlv_324"],
                    "official_tlv": match_chem.get("tlv")
                }
                if match_chem["has_tlv_324"]:
                    tlv_data = match_chem["tlv"]
                    recommendations.append(f"สารเคมีนี้อยู่ในบัญชี TLV ๓๒๔ รายการ (TWA: {tlv_data.get('twa_ppm')} ppm / {tlv_data.get('twa_mg_m3')} mg/m3) ต้องระบุค่ามาตรฐานไทยนี้ในหมวดที่ 8")

        return {
            "status": "success",
            "compliant": is_compliant,
            "compliance_rate_percent": compliance_pct,
            "total_sections": total_sections,
            "valid_sections": valid_sections_count,
            "missing_sections": missing_sections,
            "validation_report": validation_report,
            "cross_reference_check": cross_ref_info,
            "recommendations": recommendations
        }

    def verify_sds_file(self, file_path: str) -> Dict[str, Any]:
        """Verify SDS from file path (JSON)."""
        if not os.path.exists(file_path):
            return {
                "status": "error",
                "message": f"SDS file not found: {file_path}"
            }
        
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                sds_data = json.load(f)
            return self.verify_sds_data(sds_data)
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to parse SDS file as JSON: {str(e)}"
            }
