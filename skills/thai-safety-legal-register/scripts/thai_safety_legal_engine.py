"""
==============================================================================
 Thai Safety Legal Register Engine (thai_safety_legal_engine.py)
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
import json
import re
import datetime
from typing import Dict, Any, List, Optional, Union, Tuple


class ThaiSafetyLegalEngine:
    """Core domain engine for Thai occupational safety legal register & compliance evaluation."""

    def __init__(self, data_dir: Optional[str] = None):
        if data_dir is None:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            data_dir = os.path.join(script_dir, "data")
        
        self.data_dir = data_dir
        self.catalog_path = os.path.join(data_dir, "safety_laws_catalog.json")
        self.criteria_path = os.path.join(data_dir, "compliance_criteria.json")
        self.capa_path = os.path.join(data_dir, "capa_templates.json")

        self.laws: List[Dict[str, Any]] = []
        self.law_by_id: Dict[str, Dict[str, Any]] = {}
        self.req_by_id: Dict[str, Tuple[Dict[str, Any], Dict[str, Any]]] = {}
        self.criteria: Dict[str, Any] = {}
        self.capa_templates: Dict[str, Any] = {}

        self._load_data()

    def _load_data(self) -> None:
        """Load all offline JSON catalogs and build in-memory indexes."""
        if not os.path.exists(self.catalog_path):
            raise FileNotFoundError(f"Catalog file not found: {self.catalog_path}")

        with open(self.catalog_path, "r", encoding="utf-8") as f:
            catalog_data = json.load(f)
            self.laws = catalog_data.get("laws", [])

        if os.path.exists(self.criteria_path):
            with open(self.criteria_path, "r", encoding="utf-8") as f:
                self.criteria = json.load(f)

        if os.path.exists(self.capa_path):
            with open(self.capa_path, "r", encoding="utf-8") as f:
                self.capa_templates = json.load(f).get("templates", {})

        # Build fast lookup indexes
        for law in self.laws:
            law_id = law.get("law_id", "")
            law_code = law.get("law_code", "")
            category = law.get("category", "")

            # Index law by various keys
            for key in [law_id, law_code, category]:
                if key:
                    self.law_by_id[key.lower()] = law
            
            for alias in law.get("aliases", []):
                self.law_by_id[alias.lower()] = law

            # Index requirements
            for req in law.get("items", []):
                req_id = req.get("req_id", "")
                item_id = req.get("item_id", "")
                article_no = req.get("article_no", "")

                for rk in [req_id, item_id]:
                    if rk:
                        self.req_by_id[rk.lower()] = (law, req)
                
                for alias in req.get("aliases", []):
                    self.req_by_id[alias.lower()] = (law, req)

    def _normalize_text(self, text: str) -> str:
        """Clean and normalize Thai/English text for comparison."""
        if not text:
            return ""
        # Lowercase, strip punctuation and extra whitespace
        text = text.lower().strip()
        # Normalize Thai numerals to Arabic numerals
        thai_to_arabic = {
            '๐': '0', '๑': '1', '๒': '2', '๓': '3', '๔': '4',
            '๕': '5', '๖': '6', '๗': '7', '๘': '8', '๙': '9'
        }
        for th, ar in thai_to_arabic.items():
            text = text.replace(th, ar)
        return text

    def search_laws(
        self,
        query: str,
        category: str = "all",
        limit: int = 10
    ) -> Dict[str, Any]:
        """
        Search statutory provisions, articles, and requirements across 8 safety regulations.
        """
        if not query or not query.strip():
            return {
                "status": "error",
                "message": "Query parameter cannot be empty.",
                "query": query,
                "category": category,
                "total_found": 0,
                "results": []
            }

        norm_query = self._normalize_text(query)
        norm_cat = self._normalize_text(category)

        # Mapping for category aliases
        cat_map = {
            "all": "all",
            "act_2554": "act_2554",
            "osh_act": "act_2554",
            "osh": "act_2554",
            "jpor_cpo_2565": "jpor_cpo_2565",
            "safety_officer": "jpor_cpo_2565",
            "jpor": "jpor_cpo_2565",
            "chemical_2556": "chemical_2556",
            "chemical_safety": "chemical_2556",
            "chemical": "chemical_2556",
            "fire_2555": "fire_2555",
            "fire_safety": "fire_2555",
            "fire": "fire_2555",
            "electrical_2558": "electrical_2558",
            "electrical_safety": "electrical_2558",
            "electrical": "electrical_2558",
            "machinery_crane_boiler_2564": "machinery_crane_boiler_2564",
            "machinery_boiler": "machinery_crane_boiler_2564",
            "machinery": "machinery_crane_boiler_2564",
            "crane": "machinery_crane_boiler_2564",
            "boiler": "machinery_crane_boiler_2564",
            "environment_2559": "environment_2559",
            "environment_physical": "environment_2559",
            "environment": "environment_2559",
            "env": "environment_2559",
            "health_check_2563": "health_check_2563",
            "health_surveillance": "health_check_2563",
            "health": "health_check_2563",
        }
        target_cat = cat_map.get(norm_cat, norm_cat)

        scored_results: List[Tuple[float, Dict[str, Any]]] = []

        for law in self.laws:
            law_cat = law.get("category", "")
            if target_cat != "all" and law_cat != target_cat:
                continue

            law_name_th = law.get("law_name_th", "")
            law_name_en = law.get("law_name_en", "")
            law_code = law.get("law_code", "")
            law_id = law.get("law_id", "")
            gazette = law.get("gazette_reference", {})

            for req in law.get("items", []):
                req_id = req.get("req_id", "")
                item_id = req.get("item_id", "")
                article_no = req.get("article_no", "")
                title = req.get("title", "")
                description = req.get("description", "")
                applicability = req.get("applicability_criteria", "")
                compliance = req.get("compliance_criteria", "")
                penalty = req.get("penalty_clause", "")
                form_name = req.get("official_form_name", "") or ""
                aliases = req.get("aliases", [])

                # Text corpus for matching
                search_corpus = [
                    req_id, item_id, article_no, title, description,
                    applicability, compliance, penalty, form_name,
                    law_name_th, law_name_en, law_code, law_id
                ] + aliases

                norm_corpus = [self._normalize_text(s) for s in search_corpus]
                full_text = " ".join(norm_corpus)

                score = 0.0

                # 1. Exact ID or Alias Match
                if norm_query == self._normalize_text(req_id) or norm_query == self._normalize_text(item_id):
                    score += 150.0
                elif any(norm_query == self._normalize_text(a) for a in aliases):
                    score += 120.0
                # 2. Exact Title / Article Match
                elif norm_query in self._normalize_text(title):
                    score += 100.0
                elif norm_query in self._normalize_text(article_no):
                    score += 90.0
                # 3. Form Name match
                elif form_name and norm_query in self._normalize_text(form_name):
                    score += 85.0
                # 4. Keyword in description / penalty / full text
                elif norm_query in full_text:
                    score += 60.0
                else:
                    # Token matching
                    query_tokens = [t for t in norm_query.split() if len(t) > 1]
                    if query_tokens:
                        token_matches = sum(1 for t in query_tokens if t in full_text)
                        if token_matches > 0:
                            score += (token_matches / len(query_tokens)) * 50.0

                if score > 0:
                    result_item = {
                        "law_id": law_id,
                        "law_code": law_code,
                        "title_th": law_name_th,
                        "category": law_cat,
                        "req_id": req_id,
                        "item_id": item_id,
                        "article_no": article_no,
                        "requirement_title": title,
                        "requirement_summary": description,
                        "applicability_criteria": applicability,
                        "compliance_criteria": compliance,
                        "risk_level": req.get("risk_level", "MEDIUM"),
                        "official_form_name": form_name,
                        "gazette_reference": {
                            "volume": gazette.get("volume", ""),
                            "issue": gazette.get("issue", gazette.get("part", "")),
                            "page": gazette.get("page", ""),
                            "publication_date_th": gazette.get("publication_date_th", gazette.get("published_date", "")),
                            "effective_date_th": gazette.get("effective_date_th", gazette.get("effective_date", "")),
                            "gazette_url": gazette.get("gazette_url", "")
                        },
                        "penalty_clause": penalty,
                        "score": round(score, 1)
                    }
                    scored_results.append((score, result_item))

        # Sort descending by score
        scored_results.sort(key=lambda x: x[0], reverse=True)
        final_results = [item for _, item in scored_results[:limit]]

        return {
            "status": "success",
            "query": query,
            "category": category,
            "total_found": len(scored_results),
            "results": final_results
        }

    def get_law(self, law_id: str, section: Optional[str] = None) -> Dict[str, Any]:
        """
        Retrieve full text, gazette metadata, and statutory details for a specific law or section.
        """
        if not law_id or not law_id.strip():
            return {
                "status": "error",
                "message": "Law ID cannot be empty."
            }

        norm_id = law_id.strip().lower()
        norm_id_clean = self._normalize_text(norm_id)

        target_law: Optional[Dict[str, Any]] = None

        # Check direct index or normalized index
        if norm_id in self.law_by_id:
            target_law = self.law_by_id[norm_id]
        elif norm_id_clean in self.law_by_id:
            target_law = self.law_by_id[norm_id_clean]
        else:
            # Try fuzzy match across laws
            for law in self.laws:
                aliases = [self._normalize_text(a) for a in law.get("aliases", [])]
                if (norm_id_clean in self._normalize_text(law.get("law_id", "")) or
                    norm_id_clean in self._normalize_text(law.get("law_code", "")) or
                    norm_id_clean in aliases):
                    target_law = law
                    break

        if not target_law:
            return {
                "status": "error",
                "message": f"Law with ID or alias '{law_id}' not found in catalog.",
                "available_laws": [l.get("law_id") for l in self.laws]
            }

        gazette = target_law.get("gazette_reference", {})
        response_law: Dict[str, Any] = {
            "law_id": target_law.get("law_id", ""),
            "law_code": target_law.get("law_code", ""),
            "title_th": target_law.get("law_name_th", ""),
            "title_en": target_law.get("law_name_en", ""),
            "category": target_law.get("category", ""),
            "gazette": {
                "volume": gazette.get("volume", ""),
                "issue": gazette.get("issue", gazette.get("part", "")),
                "page": gazette.get("page", ""),
                "date_th": gazette.get("publication_date_th", gazette.get("published_date", "")),
                "effective_date_th": gazette.get("effective_date_th", gazette.get("effective_date", "")),
                "gazette_url": gazette.get("gazette_url", "")
            },
            "regulator": target_law.get("governing_authority", "กรมสวัสดิการและคุ้มครองแรงงาน (DLPW)"),
            "summary": target_law.get("summary", ""),
            "total_items": len(target_law.get("items", []))
        }

        # If a specific section is requested
        if section and section.strip():
            norm_sec = self._normalize_text(section)
            target_req: Optional[Dict[str, Any]] = None

            for req in target_law.get("items", []):
                req_corpus = [
                    req.get("req_id", ""),
                    req.get("item_id", ""),
                    req.get("article_no", ""),
                    req.get("title", ""),
                    req.get("official_form_name", "") or ""
                ] + req.get("aliases", [])

                norm_req_corpus = [self._normalize_text(s) for s in req_corpus]
                if any(norm_sec in c or c in norm_sec for c in norm_req_corpus if c):
                    target_req = req
                    break

            if target_req:
                response_law["target_section"] = {
                    "req_id": target_req.get("req_id", ""),
                    "item_id": target_req.get("item_id", ""),
                    "article_no": target_req.get("article_no", ""),
                    "title": target_req.get("title", ""),
                    "description": target_req.get("description", ""),
                    "criteria": target_req.get("applicability_criteria", ""),
                    "compliance_criteria": target_req.get("compliance_criteria", ""),
                    "risk_level": target_req.get("risk_level", ""),
                    "evidence_needed": target_req.get("required_evidence_type", ""),
                    "official_form_name": target_req.get("official_form_name", ""),
                    "penalty": target_req.get("penalty_clause", "")
                }
            else:
                response_law["target_section"] = None
                response_law["section_warning"] = f"Section '{section}' not found in law '{law_id}'."
        else:
            response_law["requirements"] = target_law.get("items", [])

        return {
            "status": "success",
            "law": response_law
        }

    def evaluate_compliance(self, workplace_profile: Union[Dict[str, Any], str]) -> Dict[str, Any]:
        """
        Evaluate legal compliance of a workplace profile against all 8 safety regulations.
        """
        # Parse profile if given as JSON string or file path
        if isinstance(workplace_profile, str):
            if os.path.exists(workplace_profile):
                with open(workplace_profile, "r", encoding="utf-8") as f:
                    profile: Dict[str, Any] = json.load(f)
            else:
                try:
                    profile = json.loads(workplace_profile)
                except Exception as e:
                    return {"status": "error", "message": f"Malformed JSON profile: {str(e)}"}
        elif isinstance(workplace_profile, dict):
            profile = workplace_profile
        else:
            return {"status": "error", "message": "Invalid workplace profile type. Must be dict or JSON string."}

        company_name = profile.get("company_name", "Unknown Workplace")
        industry_type = profile.get("industry_type", "General Industry")
        annex = int(profile.get("business_category_annex", 2))
        employees = int(profile.get("employee_count", 0))

        has_chem = bool(profile.get("has_hazardous_chemicals", False) or profile.get("hazardous_chemicals_list", []))
        has_cranes = bool(profile.get("has_cranes", False) or profile.get("crane_count", 0) > 0)
        has_boilers = bool(profile.get("has_boilers", False) or profile.get("boiler_count", 0) > 0)
        has_high_voltage = bool(profile.get("has_high_voltage_electrical", False) or profile.get("electrical_transformer_kva", 0) > 0)
        has_noise = bool(profile.get("has_noise_exceed_85dba", False))
        has_heat = bool(profile.get("has_heat_wbgt_risk", False))
        has_health_risks = bool(
            profile.get("has_occupational_health_risks", False) or
            profile.get("risk_factor_types", []) or
            has_chem or has_noise or has_heat
        )

        practices: Dict[str, Any] = profile.get("current_practices", {})

        detailed_evaluations: List[Dict[str, Any]] = []
        applicable_laws_set = set()

        total_reqs = 0
        compliant_count = 0
        non_compliant_count = 0
        in_progress_count = 0
        not_applicable_count = 0
        critical_gaps = 0

        risk_weights = {
            "CRITICAL": 4.0,
            "HIGH": 3.0,
            "MEDIUM": 2.0,
            "LOW": 1.0
        }

        weighted_numerator = 0.0
        weighted_denominator = 0.0

        for law in self.laws:
            law_id = law.get("law_id", "")
            law_code = law.get("law_code", "")
            law_name_th = law.get("law_name_th", "")

            for req in law.get("items", []):
                total_reqs += 1
                req_id = req.get("req_id", "")
                title = req.get("title", "")
                article_no = req.get("article_no", "")
                risk_level = req.get("risk_level", "MEDIUM")
                penalty = req.get("penalty_clause", "")
                rule_meta = self.criteria.get("rules", {}).get(req_id, {})

                # 1. Applicability Check
                is_applicable = False
                applicability_reason = ""

                if law_id == "LAW-01":
                    # OSH Act is applicable to all workplaces with >= 1 employee
                    is_applicable = True
                    applicability_reason = f"พ.ร.บ. ความปลอดภัยฯ บังคับใช้กับสถานประกอบกิจการทุกแห่ง (ลูกจ้าง {employees} คน)"

                elif law_id == "LAW-02":
                    # Safety Officers & Committee B.E. 2565
                    if req_id == "LAW-02-REQ-01": # จป.หัวหน้างาน / จป.บริหาร
                        if annex in [1, 2] and employees >= 2:
                            is_applicable = True
                            applicability_reason = f"บัญชี {annex} ลูกจ้างตั้งแต่ ๒ คนขึ้นไป บังคับมี จป.หัวหน้างาน และ จป.บริหาร"
                        elif annex == 3 and employees >= 20:
                            is_applicable = True
                            applicability_reason = f"บัญชี ๓ ลูกจ้างตั้งแต่ ๒๐ คนขึ้นไป บังคับมี จป.หัวหน้างาน"
                    elif req_id == "LAW-02-REQ-02": # จป.เทคนิค
                        if annex == 2 and (20 <= employees <= 49):
                            is_applicable = True
                            applicability_reason = f"บัญชี ๒ ลูกจ้าง ๒๐-๔๙ คน บังคับมี จป.เทคนิค"
                        elif annex == 3 and (100 <= employees <= 199):
                            is_applicable = True
                            applicability_reason = f"บัญชี ๓ ลูกจ้าง ๑๐๐-๑๙๙ คน บังคับมี จป.เทคนิค"
                    elif req_id == "LAW-02-REQ-03": # จป.เทคนิคขั้นสูง
                        if annex == 2 and (50 <= employees <= 99):
                            is_applicable = True
                            applicability_reason = f"บัญชี ๒ ลูกจ้าง ๕๐-๙๙ คน บังคับมี จป.เทคนิคขั้นสูง หรือ จป.วิชาชีพ"
                    elif req_id == "LAW-02-REQ-04": # จป.วิชาชีพ
                        if annex == 1 and employees >= 2:
                            is_applicable = True
                            applicability_reason = f"บัญชี ๑ ลูกจ้างตั้งแต่ ๒ คนขึ้นไป บังคับมี จป.วิชาชีพ เต็มเวลา"
                        elif annex == 2 and employees >= 64:
                            is_applicable = True
                            applicability_reason = f"บัญชี ๒ ลูกจ้างตั้งแต่ ๖๔ คนขึ้นไป (ปัจจุบัน {employees} คน) บังคับมี จป.วิชาชีพ เต็มเวลา"
                        elif annex == 3 and employees >= 200:
                            is_applicable = True
                            applicability_reason = f"บัญชี ๓ ลูกจ้างตั้งแต่ ๒๐๐ คนขึ้นไป บังคับมี จป.วิชาชีพ เต็มเวลา"
                    elif req_id == "LAW-02-REQ-05": # คปอ.
                        if employees >= 50:
                            is_applicable = True
                            applicability_reason = f"สถานประกอบกิจการมีลูกจ้าง {employees} คน (>= ๕๐ คน) บังคับจัดตั้ง คปอ."
                    elif req_id == "LAW-02-REQ-06": # หน่วยงานความปลอดภัย
                        if (annex == 1 and employees >= 2) or (annex == 2 and employees >= 200):
                            is_applicable = True
                            applicability_reason = f"บัญชี {annex} ลูกจ้าง {employees} คน บังคับจัดตั้งหน่วยงานความปลอดภัย"
                    elif req_id == "LAW-02-REQ-07": # จป.ท. ๑
                        if (annex == 1 and employees >= 2) or (annex == 2 and employees >= 50) or (annex == 3 and employees >= 200):
                            is_applicable = True
                            applicability_reason = f"สถานประกอบกิจการมี จป.วิชาชีพ หรือ จป.เทคนิคขั้นสูง ต้องส่งแบบ จป.ท. ๑"

                elif law_id == "LAW-03":
                    # Hazardous Chemicals B.E. 2556
                    if has_chem:
                        is_applicable = True
                        chem_count = len(profile.get("hazardous_chemicals_list", []))
                        applicability_reason = f"มีการครอบครองและใช้งานสารเคมีอันตราย ({chem_count} รายการ)"

                elif law_id == "LAW-04":
                    # Fire Safety B.E. 2555
                    is_applicable = True
                    applicability_reason = f"กฎกระทรวงอัคคีภัย บังคับใช้กับสถานประกอบกิจการทุกแห่ง"

                elif law_id == "LAW-05":
                    # Electrical Safety B.E. 2558
                    is_applicable = True
                    applicability_reason = f"มีการใช้ระบบไฟฟ้าในสถานประกอบการ" + (f" (หม้อแปลง {profile.get('electrical_transformer_kva', 0)} kVA)" if has_high_voltage else "")

                elif law_id == "LAW-06":
                    # Machinery, Cranes & Boilers B.E. 2564
                    if req_id == "LAW-06-REQ-01":
                        # Machine guarding
                        is_applicable = True
                        applicability_reason = "มีการใช้งานเครื่องจักรในสถานประกอบการ"
                    elif req_id in ["LAW-06-REQ-02", "LAW-06-REQ-03"]:
                        # Cranes
                        if has_cranes:
                            is_applicable = True
                            applicability_reason = f"มีการใช้งานปั้นจั่น ({profile.get('crane_count', 0)} เครื่อง)"
                    elif req_id == "LAW-06-REQ-04":
                        # Boilers
                        if has_boilers:
                            is_applicable = True
                            applicability_reason = f"มีการใช้งานหม้อน้ำ/ภาชนะรับแรงดัน ({profile.get('boiler_count', 0)} ลูก)"

                elif law_id == "LAW-07":
                    # Environment (Heat, Light, Noise) B.E. 2559
                    if req_id in ["LAW-07-REQ-01", "LAW-07-REQ-02"]:
                        # General physical environment
                        if annex in [1, 2] or has_noise or has_heat or employees >= 20:
                            is_applicable = True
                            applicability_reason = "สถานประกอบกิจการมีสภาพแวดล้อมการทำงานด้านแสง เสียง หรือความร้อน"
                    elif req_id == "LAW-07-REQ-03":
                        # Hearing Conservation
                        if has_noise:
                            is_applicable = True
                            applicability_reason = "พื้นที่ทำงานมีระดับเสียงเฉลี่ย ๘ ชม. เท่ากับหรือเกิน ๘๕ dBA"

                elif law_id == "LAW-08":
                    # Health Examination B.E. 2563
                    if has_health_risks:
                        is_applicable = True
                        risks_str = ", ".join(profile.get("risk_factor_types", ["เคมี", "เสียง"]))
                        applicability_reason = f"มีลูกจ้างปฏิบัติงานเกี่ยวกับปัจจัยเสี่ยง ({risks_str})"

                # 2. Compliance Evaluation
                if not is_applicable:
                    status = "NOT_APPLICABLE"
                    not_applicable_count += 1
                    current_practice_desc = "ไม่เข้าเกณฑ์ข้อกำหนดนี้"
                    gap_desc = None
                    req_action = None
                else:
                    applicable_laws_set.add(law_code)
                    weight = risk_weights.get(risk_level, 2.0)
                    weighted_denominator += weight

                    # Evaluate practice keys
                    is_compliant = True
                    is_in_progress = False

                    # Threshold check (e.g. fire training %)
                    if req_id == "LAW-04-REQ-04":
                        fire_percent = float(practices.get("basic_fire_trained_percent", 0.0))
                        if fire_percent >= 40.0:
                            is_compliant = True
                        elif 0.0 < fire_percent < 40.0:
                            is_compliant = False
                            is_in_progress = True
                        else:
                            is_compliant = False
                    else:
                        check_keys = rule_meta.get("check_keys")
                        if check_keys:
                            vals = [practices.get(k, None) for k in check_keys]
                            # If all true -> compliant, if some true -> in_progress, if all false/None -> non_compliant
                            if all(v is True for v in vals):
                                is_compliant = True
                            elif any(v is True for v in vals):
                                is_compliant = False
                                is_in_progress = True
                            else:
                                is_compliant = False
                        else:
                            practice_key = rule_meta.get("practice_key", "")
                            default_val = rule_meta.get("default_value", False)
                            val = practices.get(practice_key, default_val)

                            if isinstance(val, bool):
                                is_compliant = val
                            elif isinstance(val, str):
                                if val.upper() in ["COMPLIANT", "PASS", "YES", "TRUE"]:
                                    is_compliant = True
                                elif val.upper() in ["IN_PROGRESS", "PARTIAL", "PENDING"]:
                                    is_compliant = False
                                    is_in_progress = True
                                else:
                                    is_compliant = False
                            else:
                                is_compliant = bool(val)

                    if is_compliant:
                        status = "COMPLIANT"
                        compliant_count += 1
                        weighted_numerator += (weight * 1.0)
                        current_practice_desc = "ดำเนินการสอดคล้องตามข้อกำหนดกฎหมายแล้ว"
                        gap_desc = None
                        req_action = None
                    elif is_in_progress:
                        status = "IN_PROGRESS"
                        in_progress_count += 1
                        weighted_numerator += (weight * 0.5)
                        current_practice_desc = "อยู่ระหว่างการดำเนินการปรับปรุงแก้ไข"
                        gap_desc = rule_meta.get("gap_description", "อยู่ระหว่างดำเนินการให้ครบถ้วนตามเกณฑ์")
                        req_action = rule_meta.get("required_action", "เร่งรัดการดำเนินงานให้แล้วเสร็จตามแผน")
                    else:
                        status = "NON_COMPLIANT"
                        non_compliant_count += 1
                        current_practice_desc = "ยังไม่ได้ดำเนินการหรือยังไม่ครบถ้วนตามเกณฑ์กฎหมาย"
                        gap_desc = rule_meta.get("gap_description", "ยังไม่มีการปฏิบัติตามข้อกำหนดนี้")
                        req_action = rule_meta.get("required_action", "ดำเนินการตามข้อกำหนดกฎหมายทันที")
                        if risk_level == "CRITICAL":
                            critical_gaps += 1

                eval_entry = {
                    "req_id": req_id,
                    "law_code": law_code,
                    "law_name": law_name_th,
                    "requirement_title": title,
                    "legal_article": article_no,
                    "applicability": f"{'APPLICABLE' if is_applicable else 'NOT_APPLICABLE'} ({applicability_reason})",
                    "status": status,
                    "risk_level": risk_level,
                    "current_practice": current_practice_desc,
                    "gap_description": gap_desc,
                    "penalty_risk": penalty if status != "COMPLIANT" and is_applicable else None,
                    "required_action": req_action
                }
                detailed_evaluations.append(eval_entry)

        # Calculate Compliance KPI
        applicable_count = total_reqs - not_applicable_count
        if applicable_count > 0:
            compliance_percentage = round(((compliant_count + (0.5 * in_progress_count)) / applicable_count) * 100.0, 2)
        else:
            compliance_percentage = 100.0

        if weighted_denominator > 0:
            risk_weighted_score = round((weighted_numerator / weighted_denominator) * 100.0, 2)
        else:
            risk_weighted_score = 100.0

        # Determine Compliance Grade
        if compliance_percentage >= 95.0 and critical_gaps == 0:
            grade = "A - EXCELLENT"
        elif compliance_percentage >= 85.0 and critical_gaps == 0:
            grade = "B - GOOD"
        elif (compliance_percentage >= 70.0 and critical_gaps <= 2) or (compliance_percentage >= 85.0 and critical_gaps <= 2):
            grade = "C - NEEDS_IMPROVEMENT"
        else:
            grade = "D - CRITICAL_NON_COMPLIANCE"

        return {
            "status": "success",
            "evaluation_timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "company_name": company_name,
            "workplace_summary": {
                "industry_type": f"{industry_type} (Annex {annex})",
                "employee_count": employees,
                "applicable_laws_count": len(applicable_laws_set),
                "total_applicable_requirements": applicable_count
            },
            "compliance_summary": {
                "total_requirements": total_reqs,
                "compliant_count": compliant_count,
                "non_compliant_count": non_compliant_count,
                "in_progress_count": in_progress_count,
                "not_applicable_count": not_applicable_count,
                "compliance_percentage": compliance_percentage,
                "risk_weighted_score": risk_weighted_score,
                "compliance_grade": grade,
                "critical_gaps_count": critical_gaps
            },
            "detailed_evaluations": detailed_evaluations
        }

    def generate_capa(
        self,
        eval_data: Optional[Dict[str, Any]] = None,
        item_ids: Optional[Union[List[str], str]] = None
    ) -> Dict[str, Any]:
        """
        Generate prioritized Corrective & Preventive Action (CAPA) plans with root causes,
        counter-measures, designated PICs, target duration days, and verification criteria.
        """
        target_req_ids: List[str] = []

        if isinstance(item_ids, str):
            target_req_ids = [s.strip() for s in item_ids.split(",") if s.strip()]
        elif isinstance(item_ids, list):
            target_req_ids = [str(s).strip() for s in item_ids if str(s).strip()]

        # Extract from evaluation data if provided
        if eval_data and "detailed_evaluations" in eval_data:
            for item in eval_data["detailed_evaluations"]:
                st = item.get("status", "")
                rid = item.get("req_id", "")
                if st in ["NON_COMPLIANT", "IN_PROGRESS"] and rid:
                    if rid not in target_req_ids:
                        target_req_ids.append(rid)

        if not target_req_ids:
            return {
                "status": "success",
                "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                "capa_summary": {
                    "total_capa_items": 0,
                    "critical_priority_count": 0,
                    "high_priority_count": 0,
                    "medium_priority_count": 0,
                    "estimated_total_remediation_days": 0
                },
                "capa_plans": []
            }

        capa_plans: List[Dict[str, Any]] = []
        now_date = datetime.date.today()

        critical_count = 0
        high_count = 0
        medium_count = 0
        total_duration = 0

        for idx, rid in enumerate(target_req_ids, 1):
            # Resolve requirement and template
            lookup = self.req_by_id.get(rid.lower())
            law_dict: Dict[str, Any] = {}
            req_dict: Dict[str, Any] = {}

            if lookup:
                law_dict, req_dict = lookup
            
            # Find matching CAPA template
            tmpl = self.capa_templates.get(rid)
            if not tmpl:
                # Try finding by req_id in req_dict
                canonical_rid = req_dict.get("req_id", rid)
                tmpl = self.capa_templates.get(canonical_rid, {})

            priority = tmpl.get("priority", req_dict.get("risk_level", "HIGH"))
            if priority == "CRITICAL":
                critical_count += 1
            elif priority == "HIGH":
                high_count += 1
            elif priority == "MEDIUM":
                medium_count += 1

            duration_days = int(tmpl.get("target_duration_days", 30))
            total_duration = max(total_duration, duration_days)
            target_deadline = (now_date + datetime.timedelta(days=duration_days)).isoformat()

            capa_id = f"CAPA-{now_date.year}-{idx:03d}"

            capa_item = {
                "capa_id": capa_id,
                "req_id": req_dict.get("req_id", rid),
                "item_id": req_dict.get("item_id", ""),
                "priority": priority,
                "law_code": law_dict.get("law_code", ""),
                "law_name": law_dict.get("law_name_th", ""),
                "requirement": req_dict.get("title", f"ข้อกำหนด {rid}"),
                "legal_article": req_dict.get("article_no", ""),
                "finding": tmpl.get("finding", f"พบข้อบกพร่องตามข้อกำหนด {rid} ยังไม่สอดคล้องตามเกณฑ์กฎหมาย"),
                "root_cause": tmpl.get("root_cause", "ขาดระบบการติดตามและควบคุมการปฏิบัติตามกฎหมายอย่างต่อเนื่อง"),
                "corrective_action": tmpl.get("corrective_action", "ดำเนินการแก้ไขปรับปรุงหน้างานให้เป็นไปตามเกณฑ์มาตรฐานกฎหมาย"),
                "preventive_action": tmpl.get("preventive_action", "จัดทำ SOP และบรรจุลงในระบบตรวจสอบความปลอดภัยประจำงวด"),
                "person_in_charge": tmpl.get("person_in_charge", "จป.วิชาชีพ / ผู้จัดการแผนกที่เกี่ยวข้อง"),
                "target_duration_days": duration_days,
                "target_deadline": target_deadline,
                "verification_method": tmpl.get("verification_method", "ตรวจสอบเอกสารหลักฐานและลงพื้นที่ตรวจสภาพจริง"),
                "evidence_needed": tmpl.get("evidence_needed", "เอกสารหลักฐานผลการปรับปรุงแก้ไข"),
                "status": "OPEN"
            }
            capa_plans.append(capa_item)

        # Sort plans by priority (CRITICAL -> HIGH -> MEDIUM -> LOW)
        priority_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
        capa_plans.sort(key=lambda x: priority_order.get(x["priority"], 99))

        return {
            "status": "success",
            "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "capa_summary": {
                "total_capa_items": len(capa_plans),
                "critical_priority_count": critical_count,
                "high_priority_count": high_count,
                "medium_priority_count": medium_count,
                "estimated_total_remediation_days": total_duration
            },
            "capa_plans": capa_plans
        }
