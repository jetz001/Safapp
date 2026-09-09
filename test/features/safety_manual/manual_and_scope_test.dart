import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/safety_manual/data/models/factory_scope_model.dart';
import 'package:safety_superapp/features/safety_manual/data/repositories/manual_repository.dart';
import 'package:safety_superapp/features/safety_manual/services/safety_manual_pdf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FactoryScopeModel Tests', () {
    test('Default FactoryScopeModel enables all 8 hazard domains', () {
      const scope = FactoryScopeModel();
      expect(scope.hasBoiler, isTrue);
      expect(scope.hasCrane, isTrue);
      expect(scope.hasChemical, isTrue);
      expect(scope.hasConfinedSpace, isTrue);
      expect(scope.hasWorkingAtHeight, isTrue);
      expect(scope.hasElectricalLoto, isTrue);
      expect(scope.hasEmergencyFire, isTrue);
      expect(scope.hasPpe, isTrue);
      expect(scope.activeCount, 8);
    });

    test('FactoryScopeModel toMap and fromMap serialization roundtrip', () {
      const scope = FactoryScopeModel(
        hasBoiler: false,
        hasCrane: true,
        hasChemical: false,
        hasConfinedSpace: true,
        hasWorkingAtHeight: false,
        hasElectricalLoto: true,
        hasEmergencyFire: true,
        hasPpe: true,
      );

      final map = scope.toMap();
      expect(map['has_boiler'], 0);
      expect(map['has_crane'], 1);
      expect(map['has_chemical'], 0);
      expect(map['has_confined_space'], 1);
      expect(map['has_working_at_height'], 0);
      expect(map['has_electrical_loto'], 1);
      expect(map['has_emergency_fire'], 1);
      expect(map['has_ppe'], 1);

      final restored = FactoryScopeModel.fromMap(map);
      expect(restored.hasBoiler, isFalse);
      expect(restored.hasCrane, isTrue);
      expect(restored.hasChemical, isFalse);
      expect(restored.hasConfinedSpace, isTrue);
      expect(restored.hasWorkingAtHeight, isFalse);
      expect(restored.activeCount, 5);
    });

    test('copyWith updates specific field correctly', () {
      const initial = FactoryScopeModel();
      final updated = initial.copyWith(hasBoiler: false);
      expect(updated.hasBoiler, isFalse);
      expect(updated.hasCrane, isTrue);
      expect(updated.activeCount, 7);
    });
  });

  group('Dynamic Safety Manual Synthesis Tests', () {
    late ManualRepository repo;

    setUp(() {
      repo = ManualRepository();
    });

    test('Tier 1 Master Manual includes Boiler chapter when hasBoiler is true', () {
      const fullScope = FactoryScopeModel(hasBoiler: true);
      final chapters = repo.buildMasterChapters(fullScope, companyName: 'บริษัท ทดสอบไทย จำกัด');

      final boilerChapters = chapters.where((c) => c.categoryKey == 'BOILER' || c.titleTh.contains('หม้อน้ำ'));
      expect(boilerChapters.isNotEmpty, isTrue);
      expect(chapters.length, greaterThanOrEqualTo(10));
    });

    test('Tier 1 Master Manual completely omits Boiler chapter when hasBoiler is false', () {
      const scopeNoBoiler = FactoryScopeModel(hasBoiler: false);
      final chapters = repo.buildMasterChapters(scopeNoBoiler, companyName: 'โรงงานไม่มีหม้อน้ำ');

      final boilerChapters = chapters.where((c) => c.categoryKey == 'BOILER' || c.titleTh.contains('หม้อน้ำ'));
      expect(boilerChapters.isEmpty, isTrue);

      // Verify sequential chapter numbers remain contiguous (1, 2, 3...)
      for (int i = 0; i < chapters.length; i++) {
        expect(chapters[i].chapterNumber, i + 1);
      }
    });

    test('Tier 1 Master Manual omits multiple excluded domains cleanly', () {
      const compactScope = FactoryScopeModel(
        hasBoiler: false,
        hasCrane: false,
        hasChemical: false,
        hasConfinedSpace: false,
      );
      final chapters = repo.buildMasterChapters(compactScope);

      expect(chapters.any((c) => c.categoryKey == 'BOILER'), isFalse);
      expect(chapters.any((c) => c.categoryKey == 'CRANE'), isFalse);
      expect(chapters.any((c) => c.categoryKey == 'CHEMICAL'), isFalse);
      expect(chapters.any((c) => c.categoryKey == 'CONFINED_SPACE'), isFalse);

      // Core chapters must always remain present
      expect(chapters.any((c) => c.titleTh.contains('นโยบายความปลอดภัย')), isTrue);
      expect(chapters.any((c) => c.titleTh.contains('บทบาทหน้าที่')), isTrue);
      expect(chapters.any((c) => c.titleTh.contains('กฎระเบียบความปลอดภัยทั่วไป')), isTrue);
    });

    test('Tier 2 Employee Handbook dynamically adapts Golden Rules based on factory scope', () {
      const fullScope = FactoryScopeModel(hasBoiler: true, hasCrane: true);
      final fullHandbook = repo.buildEmployeeHandbookChapters(fullScope);
      final goldenRulesCh = fullHandbook.firstWhere((c) => c.categoryKey == 'GOLDEN_RULES');

      expect(goldenRulesCh.keyRules.any((r) => r.contains('หม้อน้ำ')), isTrue);
      expect(goldenRulesCh.keyRules.any((r) => r.contains('ปั้นจั่น')), isTrue);

      const noBoilerScope = FactoryScopeModel(hasBoiler: false, hasCrane: true);
      final noBoilerHandbook = repo.buildEmployeeHandbookChapters(noBoilerScope);
      final noBoilerGoldenRules = noBoilerHandbook.firstWhere((c) => c.categoryKey == 'GOLDEN_RULES');

      expect(noBoilerGoldenRules.keyRules.any((r) => r.contains('หม้อน้ำ')), isFalse);
      expect(noBoilerGoldenRules.keyRules.any((r) => r.contains('ปั้นจั่น')), isTrue);
    });

    test('Tier 3 1-Page Induction Card dynamically adapts Donts list and contains Tear-off slip info', () {
      const scopeWithCrane = FactoryScopeModel(hasCrane: true);
      final inductionWithCrane = repo.buildSafetyInductionLeaflet(scopeWithCrane);
      expect(inductionWithCrane.keyRules.any((r) => r.contains('ปั้นจั่น')), isTrue);

      const scopeNoCrane = FactoryScopeModel(hasCrane: false);
      final inductionNoCrane = repo.buildSafetyInductionLeaflet(scopeNoCrane);
      expect(inductionNoCrane.keyRules.any((r) => r.contains('ปั้นจั่น')), isFalse);
      expect(inductionNoCrane.titleTh, contains('ใบสรุปกฎระเบียบความปลอดภัย'));
    });
  });

  group('Safety Manual PDF Exporter Tests', () {
    test('generateMasterManualBytes creates valid non-empty PDF binary', () async {
      final repo = ManualRepository();
      final chapters = repo.buildMasterChapters(const FactoryScopeModel(), companyName: 'เทสต์ แฟคตอรี่ จำกัด');
      final pdfBytes = await SafetyManualPdfExporter.generateMasterManualBytes(
        chapters: chapters,
        companyName: 'เทสต์ แฟคตอรี่ จำกัด',
      );
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateEmployeeHandbookBytes creates valid non-empty PDF binary', () async {
      final repo = ManualRepository();
      final chapters = repo.buildEmployeeHandbookChapters(const FactoryScopeModel(), companyName: 'เทสต์ แฟคตอรี่ จำกัด');
      final pdfBytes = await SafetyManualPdfExporter.generateEmployeeHandbookBytes(
        chapters: chapters,
        companyName: 'เทสต์ แฟคตอรี่ จำกัด',
      );
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(500));
    });

    test('generateInductionLeafletBytes creates valid non-empty 1-Page PDF binary', () async {
      final repo = ManualRepository();
      final leaflet = repo.buildSafetyInductionLeaflet(const FactoryScopeModel(), companyName: 'เทสต์ แฟคตอรี่ จำกัด');
      final pdfBytes = await SafetyManualPdfExporter.generateInductionLeafletBytes(
        leaflet: leaflet,
        companyName: 'เทสต์ แฟคตอรี่ จำกัด',
      );
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(500));
    });
  });
}
