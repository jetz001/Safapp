# Master Project Plan: Permit to Work (PTW) Module & 'thai-ptw-safety-law' Agent Skill

## 1. Objectives & Scope
Implement the full Thai Legal-compliant High-Risk Permit to Work (PTW) system for SAFAPP (Flutter desktop/web/mobile) and the companion Agent Skill `thai-ptw-safety-law` with CLI and Python helpers for multi-agent workflows.

## 2. Execution Phases

### Phase 0: Survey & Codebase Investigation (3 Explorers)
- **Explorer 1**: SAFAPP Core Architecture, Existing Models, Enums, Database/Storage patterns, Legal Standards representation.
- **Explorer 2**: SAFAPP UI Layout, Design Tokens, Routing, Signature Pad, PDF/Excel generation libraries, Live State Management.
- **Explorer 3**: Agent Skills framework (`thai-chemical-safety-law`, `thai-safety-legal-register`, etc.), Python helper architecture in `D:\DEV\AgentResearch\Scripts\`.

### Phase 1: Global Specification & Architecture Synthesis
- Author `PROJECT.md` with complete architecture, feature inventory, milestones, and interface contracts.
- Author `TEST_INFRA.md` with 4-tier E2E testing framework.

### Phase 2: Dual Track Execution
- **Track A: Implementation Track**
  - Milestone 1: High-Risk PTW Models, Enums, Gas Safety Evaluation, and LOTO Logic.
  - Milestone 2: 5-State Workflow State Machine, Approval Logic, Digital Signature Integration.
  - Milestone 3: Specialized Live Controls (Gas Testing Continuous Tracker, 4-Role Confined Space Registry, 30-min Fire Watch Counter, LOTO Isolation Log).
  - Milestone 4: PtwPage UI (4 Tabs: Dashboard & Register, Create Wizard, Live Site Controls, Legal Library).
  - Milestone 5: Official Government PDF Generation with QR Code & Excel Export.
  - Milestone 6: Agent Skill `thai-ptw-safety-law` (SKILL.md, CLI script, test suite) and `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py`.
- **Track B: E2E Testing Track**
  - Milestone T1: E2E Test Runner & Harness, Tier 1-4 Test Suites (Feature, Boundary, Combinatorial, Real-World).
  - Publish `TEST_READY.md`.

### Phase 3: Final Integration, E2E Verification & Adversarial Coverage Hardening
- Phase 1: 100% Pass of E2E Test Suite (Tiers 1-4) across all Flutter and Python components.
- Phase 2: Adversarial Hardening (Tier 5) with Challengers and Forensic Auditor.

### Phase 4: Final Handover & Reporting
- Generate comprehensive report for user with test results, architecture overview, and usage instructions.
