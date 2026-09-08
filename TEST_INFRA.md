# E2E Test Infra: Permit to Work (PTW) & Thai Safety Law

## Test Philosophy
- Opaque-box and requirement-driven derived strictly from `ORIGINAL_REQUEST.md` and Thai Safety Regulations.
- Methodology: Category-Partition + Boundary Value Analysis (BVA) + Pairwise Combinatorial + Real-World Workload + Adversarial Penetration.
- Zero reliance on internal mocking for domain rules: all legal boundaries are evaluated with mathematical fidelity.

## Feature Inventory
| # | Feature | Source (Requirement) | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---------|----------------------|:------:|:------:|:------:|:------:|
| 1 | High-Risk PTW Models & Enums | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 2 | Statutory Gas Testing Evaluator | ORIGINAL_REQUEST §R3, กฎฯ อับอากาศ ๒๕๖๒ | 5 | 5 | ✓ | ✓ |
| 3 | Confined Space 4-Role Registry | ORIGINAL_REQUEST §R3, กฎฯ อับอากาศ ๒๕๖๒ | 5 | 5 | ✓ | ✓ |
| 4 | Hot Work 30-min Fire Watch Log | ORIGINAL_REQUEST §R3, กฎฯ อัคคีภัย ๒๕๕๕ | 5 | 5 | ✓ | ✓ |
| 5 | Electrical LOTO Zero-Energy Verification | ORIGINAL_REQUEST §R3, กฎฯ ไฟฟ้า ๒๕๕๘ | 5 | 5 | ✓ | ✓ |
| 6 | 5-State Workflow State Machine & Guards | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 7 | Digital Signature Canvas & Capture | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 8 | SQLite v8 Relational Repository | Explorer 1 Survey | 5 | 5 | ✓ | ✓ |
| 9 | Riverpod 3 State Management & Filters | Explorer 1 & 2 Survey | 5 | 5 | ✓ | ✓ |
| 10 | PtwPage 4-Tab Interactive UI & KPI | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ | ✓ |
| 11 | Official DLPW A4 PDF Generator & QR | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ | ✓ |
| 12 | 5-Sheet Excel Exporter | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ | ✓ |
| 13 | Agent Skill `thai-ptw-safety-law` CLI | ORIGINAL_REQUEST §R6 | 5 | 5 | ✓ | ✓ |
| 14 | AgentResearch Python Helper | ORIGINAL_REQUEST §R6 | 5 | 5 | ✓ | ✓ |

## Test Architecture
- **Flutter Test Runner**: `flutter test test/features/ptw/`
- **Python Skill Test Runner**: `python -m unittest discover -s skills/thai-ptw-safety-law/tests -p "test_*.py"`
- **Pass/Fail Criteria**:
  * 100% of test assertions must pass with exit code 0.
  * Zero uncaught exceptions, zero type casting failures, zero layout overflows in widget tests.
  * Exact Thai legal standard enforcement: 0% tolerance for hazardous atmosphere or missing mandatory roles.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Silo Welding & Grinding in Confined Space | Hot Work + Confined Space + Continuous Gas + Fire Watch 30m + 4-Party Signatures | High |
| 2 | High-Voltage Substation Transformer Maintenance | Electrical LOTO (3 breaker locks) + Working at Height (Scaffolding > 2m) + Zero Energy | High |
| 3 | Chemical Underground Pipeline Excavation & Repair | Excavation (>1.5m Shoring) + Confined Space + Gas Pre-entry + Emergency Plan | High |
| 4 | Multi-Day Structural Roof Repair Shift Handover | Working at Height + Overdue Detection + Extension & Shift Handover Sign-off | Medium |
| 5 | Emergency Gas Leakage Incident & Permit Immediate Cancellation | Live Gas Alert Trigger (>25 ppm CO, >10 ppm H2S) -> Auto-Revocation -> Closure | High |

## Coverage Thresholds
- Tier 1 (Feature Coverage): $\ge 70$ tests across Flutter & Python components.
- Tier 2 (Boundary & Corner Cases): $\ge 70$ tests at exact statutory limits.
- Tier 3 (Cross-Feature Combinations): $\ge 15$ interaction tests.
- Tier 4 (Real-World Workloads): $\ge 5$ end-to-end multi-risk scenarios.
- Tier 5 (Adversarial Coverage Hardening): Stress tests + Forensic audit verification.
