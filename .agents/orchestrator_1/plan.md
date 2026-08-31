# Plan — Safety Legal Register & Compliance Evaluation Module

## Objectives
Deliver a comprehensive, robust, and law-compliant Safety Legal Register & Compliance Evaluation module for SAFAPP, conforming to the 8 Thai Royal Gazette laws, Flutter application design, export capabilities, unit tests, and multi-agent skill integration.

## Phase 0: Survey & Architecture Discovery
1. **Explorer 1 (Codebase & Flutter Architecture)**: Map existing SAFAPP structure, models, providers/state management, UI themes, routes, asset management, and export libraries (pdf, excel, file_picker, etc.).
2. **Spec Miner / Explorer 2 (Thai Royal Gazette Laws & Master Legal Catalog)**: Analyze the 8 required Thai Royal Gazette laws, sections, mandatory compliance criteria, penalty/enforcement authorities, and extract structured JSON/Dart seed catalog.
3. **Explorer 3 (Agent Skill & Tooling Integration)**: Inspect Agent Skill environment in `C:\Users\jetsa\.gemini\config\skills\`, `thai-chemical-safety-law` reference skill, and `D:\DEV\AgentResearch\Scripts\` helper integration.

## Phase 1: Decomposition & Specification
- Synthesize survey findings into `PROJECT.md`.
- Define Data Models, Interface Contracts, Milestones, and E2E Test Strategy.

## Phase 2: Dual Track Execution
- **Track A (E2E Testing)**: Test infra, mock datasets, category-partition/boundary/pairwise test cases (Tiers 1-4).
- **Track B (Implementation)**:
  - M1: Data Models & Master Catalog (8 Royal Gazette Laws)
  - M2: Business Logic, Compliance Statistics, CAPA Workflow & PDF/Excel Exporter
  - M3: Flutter UI (LegalPage with 3 tabs, KPI Dashboard, Assessment Dialogs, PDF Preview)
  - M4: Agent Skill `thai-safety-legal-register` (SKILL.md, CLI tool, helper script)

## Phase 3: Verification, Gating & Hardening
- Run Reviewers, Challengers, and Forensic Auditor across all milestones.
- Execute E2E tests to 100% pass rate.
- Adversarial coverage hardening.

## Phase 4: Final Synthesis & Delivery Report
- Aggregate verification artifacts, build logs, test reports, and report completion to parent.
