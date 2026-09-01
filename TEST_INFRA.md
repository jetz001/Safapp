# E2E Test Infra: SAFAPP Environmental Monitoring & Thai Environmental Safety Law

## Test Philosophy
- Opaque-box, requirement-driven, and white-box mathematical verification.
- Methodology: Category-Partition + Boundary Value Analysis (BVA) + Pairwise + Workload Testing + Forensic Integrity Audit.

## Feature Inventory & Test Mapping
| # | Feature | Source (Requirement) | Tier 1 (Feature) | Tier 2 (BVA/Corner) | Tier 3 (Cross-Feature) | Tier 4 (Workload) |
|---|---------|----------------------|:----------------:|:-------------------:|:----------------------:|:-----------------:|
| 1 | Master Standards Catalog | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 2 | Data Models & DB v7 | ORIGINAL_REQUEST §R1, R2 | 5 | 5 | ✓ | ✓ |
| 3 | Sessions & Subcontractor | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 4 | Point Auto-Evaluation Engine | ORIGINAL_REQUEST §R3 | 10 | 10 | ✓ | ✓ |
| 5 | CAPA & Hearing Conservation | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ | ✓ |
| 6 | UI EnvironmentPage (4 Tabs) | ORIGINAL_REQUEST §R2, R3, R4 | 5 | 5 | ✓ | ✓ |
| 7 | PDF/Excel Exporters | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ | ✓ |
| 8 | Agent Skill & CLI Helper | ORIGINAL_REQUEST §R6 | 6 | 6 | ✓ | ✓ |

## Test Architecture
- **Flutter Test Suite** (`test/features/environment/`):
  - Unit tests for WBGT calculation (indoor vs outdoor formulas, workload thresholds 34/32/30°C).
  - Unit tests for lighting evaluation (category matching, lux thresholds, pass/fail edge cases).
  - Unit tests for noise evaluation (TWA calculation, 85 dBA Action Level, 86 dBA standard limit, 115 dBA continuous, 140 dB peak, HCP trigger).
  - Repository & DB migration tests (CRUD for sessions, points, CAPAs, standard master queries).
  - Exporter tests (PDF document structure & Excel multi-sheet data population).
  - Widget tests (EnvironmentPage tab switching, KPI rendering, modal form submissions).
- **Python Agent Skill Test Suite** (`tests/test_thai_env_skill.py`):
  - 12 comprehensive unit tests for `thai_env_engine.py`, `thai_env_cli.py`, and `thai_env_helper.py`.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Full Annual Factory Survey (30 points: 10 light, 10 noise, 10 heat) with Mixed Subcontractor (Sec 11) | F1, F2, F3, F4, F5, F7 | High |
| 2 | High Noise Area (>85 dBA and >86 dBA) triggering mandatory Hearing Conservation Program & Auto-CAPA | F1, F4, F5, F6 | Medium |
| 3 | Boiler / Foundry Outdoor Heat Stress WBGT calculation with solar load exceeding 30°C limit | F1, F4, F5 | Medium |
| 4 | Agent Skill CLI batch evaluation of session JSON generating compliance index & recommendations | F8 | Medium |

## Coverage Thresholds
- Tier 1: >= 5 per feature
- Tier 2: >= 5 per feature (where boundaries exist)
- Tier 3: pairwise coverage of major feature interactions
- Tier 4: >= 4 realistic application scenarios
- Tier 5: White-box adversarial hardening by Challenger agent
