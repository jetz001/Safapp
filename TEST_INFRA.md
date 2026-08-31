# E2E Test Infra: Safety Legal Register & Compliance Evaluation

## Test Philosophy
- Opaque-box, requirement-driven, based strictly on `ORIGINAL_REQUEST.md` and statutory Thai safety compliance standards.
- Verification Methodology:
  1. Category-Partitioning (8 statutory domains)
  2. Boundary Value Analysis (employee count thresholds: 19/20, 49/50, 99/100, etc., kVA thresholds, decibel limits, hazardous chemical quantities)
  3. Pairwise Combinatorial Testing (Law Category × Assessment Status × CAPA Status × Filter State)
  4. Real-World Application Workload Scenarios (Factory A with 250 workers + chemicals + cranes, Warehouse B with 15 workers, Hospital C with risk factors)

## Feature Inventory
| # | Feature | Source (Requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Master Safety Legal Catalog (8 laws) | ORIGINAL_REQUEST §R1 | 8 | 5 | ✓ |
| 2 | Data Models & DB Schema | ORIGINAL_REQUEST §R1, R2 | 5 | 5 | ✓ |
| 3 | Repository & Riverpod State | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 4 | Legal Register & Assessment Tab | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 5 | Royal Gazette Repository Tab | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 6 | CAPA Action Plan Tab & Alerts | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 7 | KPI Dashboard & Filtering | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 8 | PDF Statutory Report Export | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 9 | Excel Multi-Sheet Export | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 10 | Agent Skill `thai-safety-legal-register` | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ |
| 11 | AgentResearch Helper Script | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ |
| 12 | Comprehensive Unit & Integration Tests | ORIGINAL_REQUEST §A4 | 5 | 5 | ✓ |

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Heavy Manufacturing Plant (250 workers, boilers, cranes, hazardous chemicals, high noise) | F1, F2, F3, F4, F6, F7, F8, F9, F10 | High |
| 2 | Logistics & Warehousing Hub (30 workers, forklifts, fire safety, health checks) | F1, F2, F4, F6, F7, F8 | Medium |
| 3 | Automated CAPA Lifecycle Transition (Non-compliant -> CAPA -> In-progress -> Evidence Attached -> Compliant) | F3, F4, F6, F7, F8 | High |
| 4 | Agent Research Multi-Agent Legal Evaluation CLI workflow | F10, F11 | Medium |
| 5 | Export Verification (PDF Sarabun font & 3-sheet Excel with Thai characters) | F8, F9 | High |

## Test Runners
- Flutter Unit & Widget Tests: `flutter test test/legal_register_test.dart`
- Adversarial & Challenge Tests: `flutter test test/legal_register_adversarial_challenge_test.dart`
- Python Skill Unit Tests: `python -m unittest discover -s skills/thai-safety-legal-register/tests`

## Coverage Thresholds
- Tier 1: ≥60 tests
- Tier 2: ≥60 boundary tests
- Tier 3: Pairwise coverage across all 8 categories × 4 assessment statuses
- Tier 4: ≥5 full-scale application workload scenarios
