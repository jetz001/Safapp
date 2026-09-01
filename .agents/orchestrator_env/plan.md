# Implementation Plan: SAFAPP Environmental Monitoring & Agent Skill

## Objectives
Deliver complete Environmental Monitoring module (Lighting, Noise, Heat WBGT) conforming to Thai Royal Gazette standards (2559, 2561, 2563) on SAFAPP, along with 'thai-environmental-safety-law' agent skill and AgentResearch helper script.

## Phase Breakdown

### Phase 0: Survey & Specification Extraction
- Spawn 3 parallel explorers/spec miners:
  - Explorer 1: Inspect existing SAFAPP architecture, existing models, database/storage layer (SQLite / Isar / Hive / State management), services, routing, theme, and previous Legal Register module implementation.
  - Spec Miner 1: Map the exact Thai legal requirements, formulas (WBGT indoor: 0.7 NWB + 0.3 GT, outdoor: 0.7 NWB + 0.2 GT + 0.1 DB; light standards by area category; noise 8-hr TWA limit 86 dBA, Action level 85 dBA, 115 dBA continuous, 140 dB peak; subcontractor Section 9 / 11; official reporting forms).
  - Explorer 2: Inspect Agent Skills directory (`.gemini/config/skills/thai-safety-legal-register`, `thai-chemical-safety-law`) and `D:\DEV\AgentResearch\Scripts` patterns to prepare for `thai-environmental-safety-law` and `thai_env_helper.py`.

### Phase 1: Architectural Design & PROJECT.md
- Merge survey findings into `PROJECT.md` with Feature Inventory, Milestones, Interface Contracts, and Code Layout.
- Setup `TEST_INFRA.md`.

### Phase 2: Execution Milestones (Iteration Loops)
- Milestone 1: Master Environmental Standards & Data Models (Models, JSON Serialization, Database/Repository)
- Milestone 2: Environmental Evaluation Engine & Business Logic (Calculators, Validators, KPI Aggregators)
- Milestone 3: SAFAPP UI EnvironmentPage & 4 Tabs (Dashboard/Subcontractor, Point Measurement, CAPA/Hearing Conservation, Gazette Library)
- Milestone 4: Multi-category Document Attachments & Official PDF/Excel Exporters
- Milestone 5: Agent Skill (`thai-environmental-safety-law`) & AgentResearch Helper
- Milestone 6: E2E Integration, Full Test Suite Pass & Adversarial Hardening (Challenger + Forensic Audit)
- Milestone 7: Final Delivery & Sentinel Handoff
