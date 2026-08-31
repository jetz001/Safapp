"""
Thai Chemical Safety Law Engine (thai_chem_law.py)
Core library and lookup engine conforming to Royal Thai Gazette:
  - Ministerial Regulation on Hazardous Chemicals B.E. 2556
  - DLPW Notification on Hazardous Chemicals (1,516 items)
  - DLPW Notification on Threshold Limit Values (TLV 324 items)
  - Form Sor.Or. 1 (สอ.๑ - SDS 16 GHS Sections)
  - Form Sor.Or. 3 (สอ.๓ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕ - Workplace Measurement)
"""

import os
import sys
import json
import re
from typing import Dict, Any, List, Optional, Union, Tuple

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

class ThaiChemLawEngine:
    def __init__(self, data_dir: Optional[str] = None):
        if data_dir is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            data_dir = os.path.join(script_dir, "data")
        
        self.data_dir = data_dir
        self.chemicals_1516: List[Dict[str, Any]] = []
        self.tlv_324: List[Dict[str, Any]] = []
        self.legal_2556: Dict[str, Any] = {}
        self.sor_or_1_schema: Dict[str, Any] = {}
        self.sor_or_3_guidelines: Dict[str, Any] = {}
        
        # Indexes for fast lookup
        self._cas_to_chem: Dict[str, Dict[str, Any]] = {}
        self._cas_to_tlv: Dict[str, Dict[str, Any]] = {}
        self._name_to_tlv: Dict[str, Dict[str, Any]] = {}
        
        self._load_datasets()

    def _load_datasets(self) -> None:
        """Load or build JSON datasets into memory."""
        os.makedirs(self.data_dir, exist_ok=True)
        
        chem_path = os.path.join(self.data_dir, "chemicals_1516.json")
        tlv_path = os.path.join(self.data_dir, "tlv_324.json")
        legal_path = os.path.join(self.data_dir, "legal_articles_2556.json")
        s1_path = os.path.join(self.data_dir, "sor_or_1_schema.json")
        s3_path = os.path.join(self.data_dir, "sor_or_3_guidelines.json")
        
        if os.path.exists(chem_path):
            with open(chem_path, "r", encoding="utf-8") as f:
                self.chemicals_1516 = json.load(f)
                
        if os.path.exists(tlv_path):
            with open(tlv_path, "r", encoding="utf-8") as f:
                self.tlv_324 = json.load(f)

        # If datasets are incomplete, generate full 1,516 items and 324 TLVs
        if len(self.chemicals_1516) < 1516 or len(self.tlv_324) < 324:
            try:
                from build_data import build_all_data
                self.chemicals_1516, self.tlv_324 = build_all_data()
                with open(chem_path, "w", encoding="utf-8") as f:
                    json.dump(self.chemicals_1516, f, ensure_ascii=False, indent=2)
                with open(tlv_path, "w", encoding="utf-8") as f:
                    json.dump(self.tlv_324, f, ensure_ascii=False, indent=2)
            except Exception:
                pass
                
        if os.path.exists(legal_path):
            with open(legal_path, "r", encoding="utf-8") as f:
                self.legal_2556 = json.load(f)
                
        if os.path.exists(s1_path):
            with open(s1_path, "r", encoding="utf-8") as f:
                self.sor_or_1_schema = json.load(f)
                
        if os.path.exists(s3_path):
            with open(s3_path, "r", encoding="utf-8") as f:
                self.sor_or_3_guidelines = json.load(f)

        # Build in-memory lookup indexes
        for chem in self.chemicals_1516:
            cas = self._normalize_cas(chem.get("cas_no", ""))
            if cas:
                self._cas_to_chem[cas] = chem

        for tlv in self.tlv_324:
            cas = self._normalize_cas(tlv.get("cas_no", ""))
            if cas:
                self._cas_to_tlv[cas] = tlv
            name_en = tlv.get("name_en", "").lower().strip()
            name_th = tlv.get("name_th", "").strip()
            if name_en:
                self._name_to_tlv[name_en] = tlv
            if name_th:
                self._name_to_tlv[name_th] = tlv

    @staticmethod
    def _normalize_cas(cas_str: str) -> str:
        """Strip non-alphanumeric chars or normalize CAS."""
        if not cas_str:
            return ""
        return re.sub(r"[^0-9\-]", "", str(cas_str)).strip()

    @staticmethod
    def _clean_cas_digits(cas_str: str) -> str:
        """Extract only digits from CAS."""
        return re.sub(r"[^0-9]", "", str(cas_str))

    def search_chemical(self, query: str, limit: int = 10) -> Dict[str, Any]:
        """
        Search chemicals across 1,516 regulated list and 324 TLVs.
        Matches by Thai name, English name, CAS No, UN No, or Item sequence.
        """
        if not query or not str(query).strip():
            return {
                "status": "error",
                "message": "Query parameter cannot be empty.",
                "total_found": 0,
                "results": []
            }

        q_raw = str(query).strip()
        q_lower = q_raw.lower()
        q_cas_norm = self._normalize_cas(q_raw)
        q_digits = self._clean_cas_digits(q_raw)

        matches: List[Tuple[int, Dict[str, Any]]] = []

        for chem in self.chemicals_1516:
            score = 0
            chem_name_en = chem.get("name_en", "").lower()
            chem_name_th = chem.get("name_th", "")
            chem_cas = chem.get("cas_no", "")
            chem_cas_norm = self._normalize_cas(chem_cas)
            chem_cas_digits = self._clean_cas_digits(chem_cas)
            chem_un = str(chem.get("un_no", ""))
            seq_no = str(chem.get("seq_no", ""))

            # 1. Exact CAS match (Highest priority)
            if q_cas_norm and chem_cas_norm and q_cas_norm == chem_cas_norm:
                score = 100
            elif len(q_digits) >= 4 and chem_cas_digits and q_digits == chem_cas_digits:
                score = 98
            # 2. Exact Name match
            elif q_lower == chem_name_en or q_raw == chem_name_th:
                score = 95
            # 3. Exact UN Number match
            elif q_raw == chem_un or q_raw == f"UN{chem_un}" or q_raw == f"UN {chem_un}":
                score = 90
            # 4. Exact Sequence No
            elif q_raw == seq_no:
                score = 85
            # 5. Prefix match
            elif chem_name_en.startswith(q_lower) or chem_name_th.startswith(q_raw):
                score = 75
            # 6. Word boundary or substring match
            elif q_lower in chem_name_en or q_raw in chem_name_th:
                score = 60
            elif q_cas_norm and q_cas_norm in chem_cas_norm:
                score = 55
            elif q_lower in chem.get("formula", "").lower():
                score = 40

            if score > 0:
                # Enrich with TLV data if available
                tlv_info = None
                has_tlv = chem.get("has_tlv_324", False)
                if has_tlv or chem_cas_norm in self._cas_to_tlv:
                    tlv_obj = self._cas_to_tlv.get(chem_cas_norm)
                    if tlv_obj:
                        tlv_info = {
                            "item_no": tlv_obj.get("item_no"),
                            "twa_ppm": tlv_obj.get("twa_ppm"),
                            "twa_mg_m3": tlv_obj.get("twa_mg_m3"),
                            "stel_ppm": tlv_obj.get("stel_ppm"),
                            "stel_mg_m3": tlv_obj.get("stel_mg_m3"),
                            "ceiling_ppm": tlv_obj.get("ceiling_ppm"),
                            "ceiling_mg_m3": tlv_obj.get("ceiling_mg_m3"),
                            "notation": tlv_obj.get("notation"),
                            "remarks": tlv_obj.get("remarks")
                        }

                res_item = {
                    "id": chem.get("id"),
                    "seq_no": chem.get("seq_no"),
                    "name_th": chem.get("name_th"),
                    "name_en": chem.get("name_en"),
                    "cas_no": chem.get("cas_no"),
                    "formula": chem.get("formula"),
                    "molecular_weight": chem.get("molecular_weight"),
                    "un_no": chem.get("un_no"),
                    "hazard_category": chem.get("hazard_category"),
                    "is_regulated_1516": True,
                    "has_tlv_324": bool(tlv_info is not None),
                    "tlv": tlv_info,
                    "sds_required": True,
                    "sor_or_1_applicable": True,
                    "sor_or_3_testing_required": bool(tlv_info is not None)
                }
                matches.append((score, res_item))

        # Sort descending by score, then by sequence number
        matches.sort(key=lambda x: (-x[0], x[1]["seq_no"]))
        top_results = [item[1] for item in matches[:limit]]

        return {
            "status": "success",
            "query": query,
            "total_found": len(matches),
            "returned_count": len(top_results),
            "results": top_results
        }

    def get_tlv(
        self,
        query: str,
        eval_val: Optional[float] = None,
        eval_type: str = "twa",
        eval_unit: str = "ppm"
    ) -> Dict[str, Any]:
        """
        Query 324 TLV standards and evaluate measured concentration value.
        eval_type: 'twa', 'stel', 'ceiling'
        eval_unit: 'ppm', 'mg_m3'
        """
        if not query or not str(query).strip():
            return {"status": "error", "message": "Chemical query (name or CAS) is required."}

        q_raw = str(query).strip()
        q_lower = q_raw.lower()
        q_cas_norm = self._normalize_cas(q_raw)

        # Lookup in TLV list
        target_tlv: Optional[Dict[str, Any]] = None

        if q_cas_norm in self._cas_to_tlv:
            target_tlv = self._cas_to_tlv[q_cas_norm]
        elif q_lower in self._name_to_tlv:
            target_tlv = self._name_to_tlv[q_lower]
        elif q_raw in self._name_to_tlv:
            target_tlv = self._name_to_tlv[q_raw]
        else:
            # Substring search in TLVs
            for tlv in self.tlv_324:
                if q_lower in tlv.get("name_en", "").lower() or q_raw in tlv.get("name_th", "") or (q_cas_norm and q_cas_norm in self._normalize_cas(tlv.get("cas_no", ""))):
                    target_tlv = tlv
                    break

        if not target_tlv:
            # Check if in 1516 chemicals but has no TLV
            chem_search = self.search_chemical(query, limit=1)
            if chem_search["total_found"] > 0:
                found_chem = chem_search["results"][0]
                return {
                    "status": "warning",
                    "message": f"Substance '{found_chem['name_en']}' (CAS: {found_chem['cas_no']}) is regulated under 1,516 list, but has no specific occupational TLV limit in 324 list.",
                    "chemical": found_chem
                }
            return {
                "status": "not_found",
                "message": f"No regulated TLV standard found for '{query}'."
            }

        response: Dict[str, Any] = {
            "status": "success",
            "substance": {
                "item_no": target_tlv.get("item_no"),
                "name_th": target_tlv.get("name_th"),
                "name_en": target_tlv.get("name_en"),
                "cas_no": target_tlv.get("cas_no"),
                "formula": target_tlv.get("formula"),
                "molecular_weight": target_tlv.get("mw"),
                "standard_limits": {
                    "twa_ppm": target_tlv.get("twa_ppm"),
                    "twa_mg_m3": target_tlv.get("twa_mg_m3"),
                    "stel_ppm": target_tlv.get("stel_ppm"),
                    "stel_mg_m3": target_tlv.get("stel_mg_m3"),
                    "ceiling_ppm": target_tlv.get("ceiling_ppm"),
                    "ceiling_mg_m3": target_tlv.get("ceiling_mg_m3"),
                    "notation": target_tlv.get("notation"),
                    "remarks": target_tlv.get("remarks")
                }
            }
        }

        # If evaluation requested
        if eval_val is not None:
            eval_type_norm = eval_type.lower().strip()
            eval_unit_norm = eval_unit.lower().strip().replace("/", "_")
            if eval_unit_norm == "mg_m3" or eval_unit_norm == "mgm3":
                unit_key = "mg_m3"
                unit_display = "mg/m³"
            else:
                unit_key = "ppm"
                unit_display = "ppm"

            # Resolve applicable legal standard
            limit_key = f"{eval_type_norm}_{unit_key}"
            legal_limit = target_tlv.get(limit_key)

            # If the requested unit limit is null, attempt conversion using molecular weight
            if legal_limit is None:
                mw = target_tlv.get("mw", 0.0)
                alt_unit_key = "mg_m3" if unit_key == "ppm" else "ppm"
                alt_limit = target_tlv.get(f"{eval_type_norm}_{alt_unit_key}")
                if alt_limit is not None and mw and mw > 0:
                    if unit_key == "ppm": # from mg_m3 to ppm
                        legal_limit = round((alt_limit * 24.45) / mw, 3)
                    else: # from ppm to mg_m3
                        legal_limit = round((alt_limit * mw) / 24.45, 3)

            if legal_limit is None:
                response["evaluation"] = {
                    "measured_value": eval_val,
                    "unit": unit_display,
                    "metric": eval_type.upper(),
                    "status": "NO_SPECIFIC_STANDARD",
                    "is_compliant": None,
                    "message": f"No statutory {eval_type.upper()} ({unit_display}) threshold defined for this substance in the Thai Gazette."
                }
            else:
                ratio = round(eval_val / legal_limit, 4)
                status = "NORMAL"
                is_compliant = True
                color_code = "GREEN"
                action_text = "อยู่ในเกณฑ์มาตรฐานความปลอดภัยตามกฎหมาย (Compliant)"

                if eval_val > legal_limit:
                    status = "EXCEEDED"
                    is_compliant = False
                    color_code = "RED"
                    action_text = f"เกินค่าขีดจำกัดความเข้มข้นตามกฎหมาย ({ratio * 100:.1f}% ของมาตรฐาน)! นายจ้างต้องปรับปรุงระบบระบายอากาศ/ระบบวิศวกรรมทันที และส่งรายงานแบบ สอ.๓ ภายใน ๑๕ วัน"
                elif eval_val >= (0.5 * legal_limit):
                    status = "ACTION_LEVEL"
                    is_compliant = True
                    color_code = "YELLOW"
                    action_text = f"อยู่ในระดับเตือนภัย Action Level ({ratio * 100:.1f}% ของมาตรฐาน)! ต้องเฝ้าระวังอย่างใกล้ชิดและตรวจสอบประสิทธิภาพระบบควบคุม"

                metric_descriptions = {
                    "twa": "TWA (8-hour Time-Weighted Average)",
                    "stel": "STEL (15-minute Short-Term Exposure Limit)",
                    "ceiling": "Ceiling (Peak Instantaneous Limit)"
                }

                response["evaluation"] = {
                    "measured_value": eval_val,
                    "unit": unit_display,
                    "metric": metric_descriptions.get(eval_type_norm, eval_type.upper()),
                    "legal_limit": legal_limit,
                    "ratio_to_standard": ratio,
                    "percent_of_standard": round(ratio * 100, 2),
                    "status": status,
                    "is_compliant": is_compliant,
                    "color_code": color_code,
                    "action_required": action_text
                }

        return response

    def calculate_mixture_index(self, components: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate additive exposure index for chemical mixtures:
        Em = Sum(Ci / TLVi)
        Compliant if Em <= 1.0; Exceeded if Em > 1.0.
        """
        if not components:
            return {"status": "error", "message": "Components list cannot be empty."}

        total_em = 0.0
        details: List[Dict[str, Any]] = []
        unmatched: List[str] = []

        for comp in components:
            name_or_cas = comp.get("chemical", "")
            measured_val = float(comp.get("measured_value", 0.0))
            unit = comp.get("unit", "ppm").lower().replace("/", "_")
            metric = comp.get("metric", "twa").lower()

            tlv_res = self.get_tlv(name_or_cas, eval_val=measured_val, eval_type=metric, eval_unit=unit)
            if tlv_res.get("status") == "success" and "evaluation" in tlv_res and tlv_res["evaluation"].get("legal_limit"):
                eval_data = tlv_res["evaluation"]
                legal_lim = eval_data["legal_limit"]
                ratio = measured_val / legal_lim
                total_em += ratio
                details.append({
                    "chemical": tlv_res["substance"]["name_en"],
                    "cas_no": tlv_res["substance"]["cas_no"],
                    "measured_value": measured_val,
                    "unit": eval_data["unit"],
                    "legal_limit": legal_lim,
                    "component_ratio": round(ratio, 4),
                    "status": eval_data["status"]
                })
            else:
                unmatched.append(name_or_cas)

        total_em = round(total_em, 4)
        is_compliant = total_em <= 1.0
        status = "PASS" if is_compliant else "EXCEEDED"
        color = "GREEN" if total_em < 0.5 else ("YELLOW" if is_compliant else "RED")

        return {
            "status": "success",
            "mixture_exposure_index_em": total_em,
            "overall_status": status,
            "is_compliant": is_compliant,
            "color_code": color,
            "evaluation_rule": "Em = Sum(Ci / TLVi) <= 1.0 for additive health effects (ACGIH/DLPW)",
            "components_evaluated": details,
            "unmatched_chemicals": unmatched,
            "summary_th": f"ดัชนีผลรวมการสัมผัสสารผสม Em = {total_em} ({'ไม่เกินเกณฑ์มาตรฐาน (ผ่าน)' if is_compliant else 'เกินค่าขีดจำกัดความเข้มข้นสารผสมตามกฎหมาย (ไม่ผ่าน)'})"
        }

    @staticmethod
    def convert_units(
        value: float,
        from_unit: str,
        to_unit: str,
        mw: float,
        temp_c: float = 25.0,
        pressure_atm: float = 1.0
    ) -> Dict[str, Any]:
        """
        Convert gas/vapor concentrations between ppm and mg/m³:
        mg/m³ = (ppm * MW * P) / (0.082057 * (273.15 + T))
        """
        if mw <= 0:
            return {"status": "error", "message": "Molecular weight must be greater than 0."}

        f_unit = from_unit.lower().replace("/", "_").strip()
        t_unit = to_unit.lower().replace("/", "_").strip()

        # Molar volume at T and P (L/mol)
        # R = 0.082057 L·atm/(mol·K)
        molar_vol = (0.082057 * (273.15 + temp_c)) / pressure_atm

        if f_unit == "ppm" and (t_unit == "mg_m3" or t_unit == "mgm3"):
            converted = (value * mw) / molar_vol
            target_unit = "mg/m³"
        elif (f_unit == "mg_m3" or f_unit == "mgm3") and t_unit == "ppm":
            converted = (value * molar_vol) / mw
            target_unit = "ppm"
        else:
            converted = value
            target_unit = to_unit

        return {
            "status": "success",
            "original_value": value,
            "from_unit": from_unit,
            "converted_value": round(converted, 4),
            "to_unit": target_unit,
            "molecular_weight": mw,
            "temperature_c": temp_c,
            "pressure_atm": pressure_atm,
            "molar_volume_liters": round(molar_vol, 3)
        }

    def get_law(self, topic: str = "all", section: Optional[str] = None) -> Dict[str, Any]:
        """
        Retrieve legal provisions, articles, Sor.Or.1 schema, or Sor.Or.3 guidelines.
        topic: 'all', 'regulation_2556', 'sor_or_1', 'sor_or_3_2565', 'registered_testers', 'storage_rules', 'medical_check', 'penalties'
        """
        topic_norm = topic.lower().strip()

        if topic_norm == "regulation_2556":
            return {
                "status": "success",
                "topic": "regulation_2556",
                "law": self.legal_2556
            }
        elif topic_norm == "sor_or_1":
            return {
                "status": "success",
                "topic": "sor_or_1",
                "schema": self.sor_or_1_schema
            }
        elif topic_norm == "sor_or_3_2565":
            return {
                "status": "success",
                "topic": "sor_or_3_2565",
                "guidelines": self.sor_or_3_guidelines
            }
        elif topic_norm == "registered_testers":
            return {
                "status": "success",
                "topic": "registered_testers",
                "legal_basis": "พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ และ ประกาศกรมสวัสดิการฯ สอ.๓ ๒๕๖๕",
                "tester_types": self.sor_or_3_guidelines.get("inspection_rules", {}).get("certified_inspectors", [])
            }
        elif topic_norm == "penalties":
            return {
                "status": "success",
                "topic": "penalties",
                "penalties": self.legal_2556.get("penalties", {})
            }
        elif topic_norm == "storage_rules":
            # Extract Chapter 3
            ch3 = next((ch for ch in self.legal_2556.get("chapters", []) if ch.get("chapter_no") == 3), None)
            return {
                "status": "success",
                "topic": "storage_rules",
                "storage_requirements": ch3
            }
        elif topic_norm == "medical_check":
            # Extract Chapter 4
            ch4 = next((ch for ch in self.legal_2556.get("chapters", []) if ch.get("chapter_no") == 4), None)
            return {
                "status": "success",
                "topic": "medical_check",
                "health_surveillance": ch4
            }
        else: # 'all' or combined summary
            return {
                "status": "success",
                "topic": "all",
                "overview": {
                    "ministerial_regulation_2556": {
                        "title": self.legal_2556.get("law_title_th"),
                        "total_chapters": len(self.legal_2556.get("chapters", [])),
                        "gazette_date": self.legal_2556.get("gazette_date")
                    },
                    "regulated_chemicals_count": len(self.chemicals_1516),
                    "tlv_standards_count": len(self.tlv_324),
                    "sor_or_1_sds_sections_count": len(self.sor_or_1_schema.get("sections", [])),
                    "sor_or_3_measurement_rules": {
                        "title": self.sor_or_3_guidelines.get("form_title_th"),
                        "frequency": self.sor_or_3_guidelines.get("inspection_rules", {}).get("sampling_frequency"),
                        "submission_deadline": self.sor_or_3_guidelines.get("inspection_rules", {}).get("submission_deadline"),
                        "retention_period": f"{self.sor_or_3_guidelines.get('inspection_rules', {}).get('document_retention_years')} ปี"
                    }
                }
            }
