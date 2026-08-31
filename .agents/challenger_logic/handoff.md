# Empirical Challenge & Logic Verification Report: Chemical & SDS Management

**Target**: SAFAPP Chemical & SDS Management Logic (TLV Evaluation, Unit Conversions, Mixture Additivity, SDS Expiry Engine, Autocomplete Search)  
**Challenger**: Challenger 1 (Logic & Calculation Specialist)  
**Date**: 2026-08-31  
**Verdict**: **REQUEST_CHANGES** (1 compile error in `sds_sor3_measurement_dialog.dart:185`, 1 unit fallback flaw in `getStandardLimit`)

---

## 1. Observation

### 1.1 Compile Error in Form สอ.๓ Measurement Dialog
- **File**: `d:\DEV\SAFAPP\lib\features\chemicals\presentation\widgets\sds_sor3_measurement_dialog.dart`
- **Lines 181–187**:
```dart
    setState(() {
      _evaluationResult = TlvEvaluationEngine.evaluate(
        measuredValue: val,
        standardLimit: limit,
        unit: _unit,
        samplingType: _samplingType, // <-- Error: The named parameter 'samplingType' isn't defined
      );
    });
```
- **Definition in `chemical_tlv_model.dart` (lines 217–221)**:
```dart
  static TlvEvaluationResult evaluate({
    required double measuredValue,
    required double? standardLimit,
    required String unit,
  })
```
- **Observation**: `TlvEvaluationEngine.evaluate` does not accept `samplingType`. Passing `samplingType: _samplingType` causes a Dart static analysis / compile error. Note that line 194 in the same file calls `evaluate` correctly without `samplingType`: `TlvEvaluationEngine.evaluate(measuredValue: val, standardLimit: limit, unit: _unit);`.

### 1.2 Unit Mismatch Fallback in `ChemicalTlvItem.getStandardLimit`
- **File**: `d:\DEV\SAFAPP\lib\features\chemicals\domain\models\chemical_tlv_model.dart`
- **Lines 123–130**:
```dart
    if (t.contains('CEILING')) {
      return (u == 'PPM') ? (ceilingPpm ?? ceilingMgM3) : (ceilingMgM3 ?? ceilingPpm);
    } else if (t.contains('STEL')) {
      return (u == 'PPM') ? (stelPpm ?? stelMgM3) : (stelMgM3 ?? stelPpm);
    } else {
      // Default to TWA (8-hr)
      return (u == 'PPM') ? (twaPpm ?? twaMgM3) : (twaMgM3 ?? twaPpm);
    }
```
- **Observation**: If a substance only has limits in `mg/m³` (e.g. Sulfuric acid, Seq 2: `twaMgM3: 1.0`, `twaPpm: null`) and a measurement is made in `PPM`, `(twaPpm ?? twaMgM3)` returns `1.0`. The numeric value `1.0 mg/m³` is then directly compared against the PPM measured value without converting units via molecular weight. For Sulfuric acid (MW 98.08), 1.0 mg/m³ is actually 0.249 ppm. A measurement of 0.8 ppm (3.2 mg/m³ = 320% TLV) would be erroneously classified as 80% (Action Level).

### 1.3 Mathematical Correctness of Calculation Engines
- **TLV Evaluation Boundary Handling (`TlvEvaluationEngine.evaluate`)**:
  - $C = 0.0$: Evaluated as `TlvEvalStatus.pass` (0% TLV).
  - $C = 0.5 \times \text{TLV}$: Evaluated as `TlvEvalStatus.pass` (50.0% TLV, compliant).
  - $C = 0.5 \times \text{TLV} + 0.001$: Evaluated as `TlvEvalStatus.actionLevel` (Action Level triggered).
  - $C = 1.0 \times \text{TLV}$: Evaluated as `TlvEvalStatus.actionLevel` (Action Level, compliant at exact threshold).
  - $C = 1.0 \times \text{TLV} + 0.001$: Evaluated as `TlvEvalStatus.exceeded` (Statutory violation).
  - $C = 1,000,000$: Evaluated as `TlvEvalStatus.exceeded` without overflow.
  - $\text{standardLimit} = \text{null}$ or $0.0$: Returns `pass` with null ratio; division-by-zero defended.
  - $C < 0$ (sensor baseline drift): Evaluated as `pass` with negative ratio.

- **PPM $\leftrightarrow$ MG/M³ Conversion (`TlvEvaluationEngine.ppmToMgM3` & `mgM3ToPpm`)**:
  - Formulas: $\text{mg/m}^3 = \frac{\text{ppm} \times \text{MW}}{24.45}$, $\text{ppm} = \frac{\text{mg/m}^3 \times 24.45}{\text{MW}}$.
  - Ultra-light gas $H_2$ ($\text{MW} = 2.016 \text{ g/mol}$): $100\text{ ppm} = 8.2454\text{ mg/m}^3$; round-trip holds with $< 10^{-4}$ drift.
  - Parity $\text{MW} = 24.45$: $42.0\text{ ppm} = 42.0\text{ mg/m}^3$.
  - Heavy organics ($\text{MW} = 390.56$ to $\text{MW} = 1000.0$): conversions scale linearly and invert accurately.
  - $\text{MW} \le 0$: Returns input value safely without throwing `NaN` or `Infinity`.

- **Mixture Additivity Exposure Index ($E_m = \sum C_i / \text{TLV}_i$)**:
  - ACGIH / DLPW 2565 standard: $E_m \le 1.0 \implies \text{Compliant}$, $E_m > 1.0 \implies \text{Exceeded}$.
  - Multi-component additive evaluation (e.g. 3 solvents at 0.40 + 0.40 + 0.30 = 1.10) correctly detects cumulative exceedance even when every individual substance is below its statutory limit.
  - Boundary $E_m = 1.0 \implies \text{isExceeded} = \text{false}$.
  - Boundary $E_m = 1.0001 \implies \text{isExceeded} = \text{true}$.
  - Zero concentrations contribute $0.0$; non-positive TLVs are filtered to prevent division by zero.

- **SDS Expiry Engine (`SdsExpiryCalculation`)**:
  - Leap year Feb 29 rollover: `DateTime(2024, 2, 29)` + 3 years rolls over cleanly to `2027-03-01`; + 4 years lands on `2028-02-29`.
  - Exact day boundaries:
    - 0 days remaining $\implies$ `near30` (Urgent, expires today).
    - -1 days remaining $\implies$ `expired` (Overdue).
    - $1 \dots 30$ days $\implies$ `near30`.
    - $31 \dots 60$ days $\implies$ `near60`.
    - $61 \dots 90$ days $\implies$ `near90`.
    - $\ge 91$ days $\implies$ `normal`.
    - `null` issue date $\implies$ `noSds`.

- **Search & Autocomplete Engine (`Chemical1516MasterData.search`)**:
  - CAS with hyphens (`108-88-3`) and without hyphens (`108883`) return exact score 100.
  - Thai prefixes (`กรด`), full names (`กรดเกลือ`), tone marks (`แอมโมเนีย`) match correctly with scores 75–85.
  - English case-insensitive searches (`tOlUeNe`, `benzene`) match with score 85–100.
  - Statutory sequence queries (`#1`, `#1516`) return exact items.
  - Empty queries return top items safely; non-matching queries return empty list without crash.

---

## 2. Logic Chain

1. **Step 1 (Static and Code Analysis)**:
   - Inspection of `sds_sor3_measurement_dialog.dart:185` shows an undefined named argument `samplingType: _samplingType` in `TlvEvaluationEngine.evaluate(...)`.
   - Inspection of `chemical_tlv_model.dart:123-130` reveals that `getStandardLimit` falls back to `twaMgM3` when `twaPpm` is null without converting units via molecular weight.

2. **Step 2 (Empirical Test Harness)**:
   - Created `test/chemical_adversarial_challenge_test.dart` covering 26 distinct stress tests across all 5 requested domains.
   - All core calculation algorithms (TLV boundary logic, unit conversion math, mixture additivity summation, SDS expiry leap-year rollover, and autocomplete search indexing) proved mathematically sound, deterministic, and robust against boundary values.

3. **Step 3 (Synthesizing Findings)**:
   - While the underlying calculation algorithms in `TlvEvaluationEngine`, `SdsExpiryCalculation`, and `Chemical1516MasterData` are mathematically sound, the compile error in `sds_sor3_measurement_dialog.dart:185` and the unit fallback risk in `getStandardLimit` must be addressed to ensure clean builds and rigorous statutory hygiene compliance.

---

## 3. Caveats

- **No Caveats on Core Logic**: All math formulas for TLV ratio calculation, unit conversions, mixture additivity indices, and SDS lifecycle brackets were fully verified and stress-tested.
- **UI Compilation**: The named parameter mismatch in `sds_sor3_measurement_dialog.dart:185` prevents clean compilation of the measurement dialog until removed or supported.

---

## 4. Conclusion

- **Verdict**: **REQUEST_CHANGES**
- **Actionable Remediation Items**:
  1. In `d:\DEV\SAFAPP\lib\features\chemicals\presentation\widgets\sds_sor3_measurement_dialog.dart` line 185: Remove `samplingType: _samplingType,` from `TlvEvaluationEngine.evaluate(...)` (matching line 194).
  2. In `d:\DEV\SAFAPP\lib\features\chemicals\domain\models\chemical_tlv_model.dart` lines 123–130: In `getStandardLimit`, do not fall back across mismatched physical units (`PPM` vs `mg/m³`) without molecular weight conversion; return `null` if the standard limit in the requested unit is not published, or perform explicit unit conversion.

---

## 5. Verification Method

To verify these findings independently:
1. Inspect `d:\DEV\SAFAPP\lib\features\chemicals\presentation\widgets\sds_sor3_measurement_dialog.dart` at line 185 against `TlvEvaluationEngine.evaluate` parameter list in `d:\DEV\SAFAPP\lib\features\chemicals\domain\models\chemical_tlv_model.dart`.
2. Inspect `d:\DEV\SAFAPP\lib\features\chemicals\domain\models\chemical_tlv_model.dart` at lines 124, 126, 129 to observe the unit fallback across PPM and mg/m³.
3. Review the test suite `d:\DEV\SAFAPP\test\chemical_adversarial_challenge_test.dart` for all 26 stress test cases.
