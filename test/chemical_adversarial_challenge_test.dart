import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/chemicals/data/datasources/chemical_1516_master_data.dart';
import 'package:safety_superapp/features/chemicals/data/datasources/chemical_324_tlv_data.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_inventory_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_master_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_tlv_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // DOMAIN 1: TLV Evaluation Logic & Boundary Stress Tests
  // ==========================================================================
  group('Adversarial Challenge 1: TLV Evaluation Logic & Boundaries', () {
    const double standardLimit = 50.0;

    test('Boundary C = 0.0 -> PASS (0% TLV)', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 0.0,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.pass);
      expect(res.isPass, isTrue);
      expect(res.isActionLevel, isFalse);
      expect(res.isExceeded, isFalse);
      expect(res.ratio, 0.0);
    });

    test('Boundary C = 0.5 * TLV (Exact Action Level Boundary 25.0) -> PASS', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 25.0,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.pass);
      expect(res.isPass, isTrue);
      expect(res.ratio, 0.5);
    });

    test('Boundary C = 0.5 * TLV + 0.001 (25.001) -> ACTION_LEVEL', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 25.001,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.actionLevel);
      expect(res.isActionLevel, isTrue);
      expect(res.ratio, greaterThan(0.5));
    });

    test('Boundary C = TLV - 0.001 (49.999) -> ACTION_LEVEL', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 49.999,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.actionLevel);
      expect(res.isActionLevel, isTrue);
      expect(res.ratio, closeTo(0.99998, 0.0001));
    });

    test('Boundary C = TLV (Exact 100% 50.0) -> ACTION_LEVEL (Compliant at limit)', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 50.0,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.actionLevel);
      expect(res.isActionLevel, isTrue);
      expect(res.isExceeded, isFalse);
      expect(res.ratio, 1.0);
    });

    test('Boundary C = TLV + 0.001 (50.001) -> EXCEEDED', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 50.001,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.exceeded);
      expect(res.isExceeded, isTrue);
      expect(res.ratio, greaterThan(1.0));
    });

    test('Extreme high concentration (C = 1,000,000 ppm) -> EXCEEDED without crash', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 1000000.0,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.exceeded);
      expect(res.ratio, 20000.0);
      expect(res.messageTh, contains('เกินขีดจำกัด'));
    });

    test('Unregulated substance (standardLimit = null) -> PASS with null ratio', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 120.0,
        standardLimit: null,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.pass);
      expect(res.ratio, isNull);
      expect(res.messageTh, contains('ไม่มีค่าขีดจำกัด'));
    });

    test('Substance with zero standardLimit -> PASS with null ratio (division by zero defense)', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: 10.0,
        standardLimit: 0.0,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.pass);
      expect(res.ratio, isNull);
    });

    test('Negative concentration from sensor baseline drift (C = -2.0 ppm) -> PASS', () {
      final res = TlvEvaluationEngine.evaluate(
        measuredValue: -2.0,
        standardLimit: standardLimit,
        unit: 'ppm',
      );
      expect(res.status, TlvEvalStatus.pass);
      expect(res.ratio, -0.04);
    });

    test('Substances with Ceiling limit only (Hydrogen chloride: Seq 1)', () {
      final hcl = Chemical324TlvData.findBySequence(1)!;
      expect(hcl.ceilingPpm, 5.0);
      expect(hcl.twaPpm, isNull);

      final evalCeilingPass = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: hcl,
        samplingType: 'CEILING',
        unit: 'ppm',
        measuredValue: 2.0,
      );
      expect(evalCeilingPass.status, TlvEvalStatus.pass);

      final evalCeilingExceed = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: hcl,
        samplingType: 'CEILING',
        unit: 'ppm',
        measuredValue: 5.5,
      );
      expect(evalCeilingExceed.status, TlvEvalStatus.exceeded);
    });

    test('Substances with TWA only in mg/m3 (Sulfuric acid: Seq 2)', () {
      final sulfuric = Chemical324TlvData.findBySequence(2)!;
      expect(sulfuric.twaMgM3, 1.0);
      expect(sulfuric.twaPpm, isNull);

      final evalMgM3 = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: sulfuric,
        samplingType: 'TWA_8HR',
        unit: 'mg/m3',
        measuredValue: 0.4,
      );
      expect(evalMgM3.status, TlvEvalStatus.pass);
      expect(evalMgM3.ratio, 0.4);
    });

    test('Substances with STEL and Skin notation (Hydrogen fluoride: Seq 5)', () {
      final hf = Chemical324TlvData.findBySequence(5)!;
      expect(hf.skinNotation, isTrue);
      expect(hf.ceilingPpm, 2.0);
      expect(hf.summaryLabel, contains('Skin Notation'));
    });

    test('Unit fallback safety: getStandardLimit does not cross units without MW conversion', () {
      final sulfuric = Chemical324TlvData.findBySequence(2)!; // twaMgM3 = 1.0, twaPpm = null
      
      // Requesting PPM without MW must return null (not fall back to 1.0 mg/m3)
      final limitPpmNoMw = sulfuric.getStandardLimit(type: 'TWA_8HR', unit: 'ppm');
      expect(limitPpmNoMw, isNull);

      // Requesting PPM with MW = 98.08 g/mol dynamically converts 1.0 mg/m3 to ~0.249 ppm
      final limitPpmWithMw = sulfuric.getStandardLimit(type: 'TWA_8HR', unit: 'ppm', molecularWeight: 98.08);
      expect(limitPpmWithMw, isNotNull);
      expect(limitPpmWithMw!, closeTo(0.249286, 0.0001));

      // Measured 0.8 ppm without MW evaluates as unthresholded PASS
      final evalNoMw = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: sulfuric,
        samplingType: 'TWA_8HR',
        unit: 'ppm',
        measuredValue: 0.8,
      );
      expect(evalNoMw.status, TlvEvalStatus.pass);
      expect(evalNoMw.ratio, isNull);

      // Measured 0.8 ppm with MW accurately detects EXCEEDED (0.8 ppm > 0.249 ppm limit)
      final evalWithMw = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: sulfuric,
        samplingType: 'TWA_8HR',
        unit: 'ppm',
        measuredValue: 0.8,
        molecularWeight: 98.08,
      );
      expect(evalWithMw.status, TlvEvalStatus.exceeded);
      expect(evalWithMw.isExceeded, isTrue);
      expect(evalWithMw.ratio, greaterThan(3.0));
    });
  });

  // ==========================================================================
  // DOMAIN 2: Unit Conversions Across Extreme Molecular Weights
  // ==========================================================================
  group('Adversarial Challenge 2: Unit Conversions (PPM <-> MG/M3)', () {
    test('Ultra-light Gas: Hydrogen H2 (MW = 2.016 g/mol)', () {
      // 100 ppm of H2
      final mgM3 = TlvEvaluationEngine.ppmToMgM3(100.0, 2.016);
      final expectedMgM3 = (100.0 * 2.016) / 24.45; // 8.2453987
      expect(mgM3, closeTo(expectedMgM3, 0.0001));

      // Invert back to PPM
      final ppmBack = TlvEvaluationEngine.mgM3ToPpm(mgM3, 2.016);
      expect(ppmBack, closeTo(100.0, 0.0001));
    });

    test('Molar volume parity compound (MW = 24.45 g/mol): 1 ppm == 1 mg/m3', () {
      final mgM3 = TlvEvaluationEngine.ppmToMgM3(42.0, 24.45);
      expect(mgM3, closeTo(42.0, 0.0001));

      final ppm = TlvEvaluationEngine.mgM3ToPpm(42.0, 24.45);
      expect(ppm, closeTo(42.0, 0.0001));
    });

    test('Heavy Organic Compound: Bis(2-ethylhexyl) phthalate (MW = 390.56 g/mol)', () {
      final mgM3 = TlvEvaluationEngine.ppmToMgM3(5.0, 390.56);
      final expected = (5.0 * 390.56) / 24.45; // 79.8691
      expect(mgM3, closeTo(expected, 0.001));

      final ppmBack = TlvEvaluationEngine.mgM3ToPpm(mgM3, 390.56);
      expect(ppmBack, closeTo(5.0, 0.0001));
    });

    test('Super-heavy polymer monomer / organometallic (MW = 1000.0 g/mol)', () {
      final mgM3 = TlvEvaluationEngine.ppmToMgM3(1.0, 1000.0);
      expect(mgM3, closeTo(40.8998, 0.001));

      final ppmBack = TlvEvaluationEngine.mgM3ToPpm(mgM3, 1000.0);
      expect(ppmBack, closeTo(1.0, 0.0001));
    });

    test('Zero or negative molecular weight handles gracefully without division by zero', () {
      expect(TlvEvaluationEngine.ppmToMgM3(50.0, 0.0), 50.0);
      expect(TlvEvaluationEngine.ppmToMgM3(50.0, -10.0), 50.0);
      expect(TlvEvaluationEngine.mgM3ToPpm(50.0, 0.0), 50.0);
      expect(TlvEvaluationEngine.mgM3ToPpm(50.0, -10.0), 50.0);
    });

    test('Zero concentration returns 0.0', () {
      expect(TlvEvaluationEngine.ppmToMgM3(0.0, 92.14), 0.0);
      expect(TlvEvaluationEngine.mgM3ToPpm(0.0, 92.14), 0.0);
    });
  });

  // ==========================================================================
  // DOMAIN 3: Mixture Exposure Additivity Index (Em = Sum(Ci / TLVi))
  // ==========================================================================
  group('Adversarial Challenge 3: Mixture Exposure Additivity Index', () {
    test('Empty components list returns index 0.0 and isExceeded = false', () {
      final res = TlvEvaluationEngine.evaluateMixture(components: []);
      expect(res.index, 0.0);
      expect(res.isExceeded, isFalse);
      expect(res.message, contains('ไม่มีข้อมูล'));
    });

    test('Single chemical component at 50% TLV', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [(measured: 25.0, tlv: 50.0)],
      );
      expect(res.index, 0.5);
      expect(res.isExceeded, isFalse);
    });

    test('Multiple chemicals with individual Ci < TLVi, but cumulative Em > 1.0 -> EXCEEDED', () {
      // 3 solvents: 40% + 40% + 30% = 110% of additive capacity
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 40.0, tlv: 100.0), // 0.40
          (measured: 80.0, tlv: 200.0), // 0.40
          (measured: 15.0, tlv: 50.0),  // 0.30
        ],
      );
      expect(res.index, closeTo(1.10, 0.001));
      expect(res.isExceeded, isTrue);
      expect(res.message, contains('เกินเกณฑ์มาตรฐานรวม'));
    });

    test('Boundary Em = 1.0 exactly -> COMPLIANT (isExceeded = false)', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 25.0, tlv: 50.0),  // 0.50
          (measured: 50.0, tlv: 100.0), // 0.50
        ],
      );
      expect(res.index, 1.0);
      expect(res.isExceeded, isFalse);
    });

    test('Boundary Em = 1.0001 -> EXCEEDED (isExceeded = true)', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 50.005, tlv: 50.0), // 1.0001
        ],
      );
      expect(res.index, greaterThan(1.0));
      expect(res.isExceeded, isTrue);
    });

    test('Zero concentrations in mixture contribute 0.0 to index', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 0.0, tlv: 50.0),
          (measured: 0.0, tlv: 100.0),
          (measured: 20.0, tlv: 100.0), // 0.20
        ],
      );
      expect(res.index, 0.20);
      expect(res.isExceeded, isFalse);
    });

    test('Component with zero or negative TLV is ignored safely (no division by zero)', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 10.0, tlv: 0.0),
          (measured: 10.0, tlv: -5.0),
          (measured: 25.0, tlv: 50.0), // 0.50
        ],
      );
      expect(res.index, 0.50);
      expect(res.isExceeded, isFalse);
    });
  });

  // ==========================================================================
  // DOMAIN 4: SDS Expiry Engine & Date Boundary Stress Tests
  // ==========================================================================
  group('Adversarial Challenge 4: SDS Expiry Engine & Leap Years', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('Null issue date -> SdsExpiryStatus.noSds', () {
      expect(SdsExpiryCalculation.calculateStatus(null), SdsExpiryStatus.noSds);
      expect(SdsExpiryCalculation.getDaysRemaining(null), -99999);
      expect(SdsExpiryCalculation.getExpiryDate(null), isNull);
    });

    test('Leap year issue date (2024-02-29) + 3 years rollover (2027-03-01)', () {
      final leapIssueDate = DateTime(2024, 2, 29);
      final expiryDate = SdsExpiryCalculation.getExpiryDate(leapIssueDate, validityYears: 3);
      expect(expiryDate, isNotNull);
      // In Dart, DateTime(2027, 2, 29) rolls over cleanly to 2027-03-01
      expect(expiryDate!.year, 2027);
      expect(expiryDate.month, 3);
      expect(expiryDate.day, 1);
    });

    test('Leap year issue date (2024-02-29) + 4 years lands on leap year (2028-02-29)', () {
      final leapIssueDate = DateTime(2024, 2, 29);
      final expiryDate = SdsExpiryCalculation.getExpiryDate(leapIssueDate, validityYears: 4);
      expect(expiryDate, isNotNull);
      expect(expiryDate!.year, 2028);
      expect(expiryDate.month, 2);
      expect(expiryDate.day, 29);
    });

    test('Exact day boundary: 0 days remaining (Expires today) -> NEAR_30 (Urgent)', () {
      // Create issue date exactly 3 years prior to today
      final issueDate = DateTime(today.year - 3, today.month, today.day);
      final days = SdsExpiryCalculation.getDaysRemaining(issueDate, validityYears: 3);
      expect(days, 0);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near30);
    });

    test('Exact day boundary: -1 days remaining (Expired yesterday) -> EXPIRED', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final issueDate = DateTime(yesterday.year - 3, yesterday.month, yesterday.day);
      final days = SdsExpiryCalculation.getDaysRemaining(issueDate, validityYears: 3);
      expect(days, -1);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.expired);
    });

    test('Brackets test: 30 days remaining -> NEAR_30', () {
      final target = today.add(const Duration(days: 30));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near30);
    });

    test('Brackets test: 31 days remaining -> NEAR_60', () {
      final target = today.add(const Duration(days: 31));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near60);
    });

    test('Brackets test: 60 days remaining -> NEAR_60', () {
      final target = today.add(const Duration(days: 60));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near60);
    });

    test('Brackets test: 61 days remaining -> NEAR_90', () {
      final target = today.add(const Duration(days: 61));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near90);
    });

    test('Brackets test: 90 days remaining -> NEAR_90', () {
      final target = today.add(const Duration(days: 90));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near90);
    });

    test('Brackets test: 91 days remaining -> NORMAL', () {
      final target = today.add(const Duration(days: 91));
      final issueDate = DateTime(target.year - 3, target.month, target.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.normal);
    });
  });

  // ==========================================================================
  // DOMAIN 5: Search & Autocomplete Stress Tests
  // ==========================================================================
  group('Adversarial Challenge 5: Search & Autocomplete Resilience', () {
    test('Exact CAS with dashes ("108-88-3") matches Toluene with score 100', () {
      final results = Chemical1516MasterData.search('108-88-3');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.casNumber, '108-88-3');
    });

    test('CAS without dashes ("108883") matches Toluene correctly', () {
      final results = Chemical1516MasterData.search('108883');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.casNumber, '108-88-3');
    });

    test('CAS with spaces ("  7664-93-9  ") matches Sulfuric acid', () {
      final res = Chemical1516MasterData.findByCas('  7664-93-9  ');
      expect(res, isNotNull);
      expect(res!.sequenceNo, 2);
    });

    test('Thai name prefix search ("กรด") returns statutory acid group', () {
      final results = Chemical1516MasterData.search('กรด', limit: 10);
      expect(results.isNotEmpty, isTrue);
      for (final r in results) {
        expect(r.thaiName.contains('กรด') || r.englishName.toLowerCase().contains('acid'), isTrue);
      }
    });

    test('Thai substring with tone marks ("แอมโมเนีย") matches Ammonia', () {
      final results = Chemical1516MasterData.search('แอมโมเนีย');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.casNumber, '7664-41-7');
    });

    test('English case insensitive search ("tOlUeNe") matches Toluene', () {
      final results = Chemical1516MasterData.search('tOlUeNe');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.englishName.toLowerCase(), contains('toluene'));
    });

    test('Statutory sequence number lookup ("#1" and "#1516")', () {
      final item1 = Chemical1516MasterData.search('#1');
      expect(item1.isNotEmpty, isTrue);
      expect(item1.first.sequenceNo, 1);

      final item1516 = Chemical1516MasterData.findBySequence(1516);
      expect(item1516, isNotNull);
      expect(item1516!.sequenceNo, 1516);
    });

    test('Empty string query returns default top items without crashing', () {
      final results = Chemical1516MasterData.search('', limit: 15);
      expect(results.length, 15);
    });

    test('Gibberish query returns empty list gracefully', () {
      final results = Chemical1516MasterData.search('xyz999nonsensechemical');
      expect(results.isEmpty, isTrue);
    });
  });
}
