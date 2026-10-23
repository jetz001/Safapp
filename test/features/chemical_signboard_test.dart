import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_inventory_model.dart';
import 'package:safety_superapp/features/chemicals/presentation/widgets/ghs_diamond_widget.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_signboard_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GhsDiamondWidget renders to PNG bytes for all 9 UN GHS codes', () async {
    final codes = ['GHS01', 'GHS02', 'GHS03', 'GHS04', 'GHS05', 'GHS06', 'GHS07', 'GHS08', 'GHS09'];
    for (final code in codes) {
      final png = await GhsDiamondWidget.renderToPng(code, size: 120);
      expect(png, isNotNull);
      expect(png.length, greaterThan(100));
    }
  });

  test('ChemicalSignboardPdfService generates valid PDF in Landscape and Portrait', () async {
    const item = ChemicalInventoryItem(
      id: 1,
      tradeName: 'ไอโซโพรพิล แอลกอฮอล์ (IPA 99.9%)',
      chemicalNameTh: 'ไอโซโพรพานอล',
      chemicalNameEn: 'Isopropyl Alcohol (2-Propanol)',
      casNumber: '67-63-0',
      unNumber: 'UN 1219',
      storageLocation: 'คลังเก็บสารเคมีอันตราย โซน B (Flammable Cabinet A-02)',
      physicalState: 'LIQUID',
      quantity: 200,
      unit: 'L',
      maxCapacity: 1000,
      ghsPictograms: ['GHS02', 'GHS07'],
      nfpaHealth: 2,
      nfpaFlammability: 3,
      nfpaInstability: 0,
      registerDate: '2026-01-15',
      sdsIssueDate: '2026-01-15',
      sdsExpiryYears: 3,
      status: 'ACTIVE',
    );

    // Test Landscape
    final landscapeBytes = await ChemicalSignboardPdfService.generateSignboardPdf(item, isLandscape: true);
    expect(landscapeBytes, isNotNull);
    expect(landscapeBytes.length, greaterThan(1000));

    // Test Portrait
    final portraitBytes = await ChemicalSignboardPdfService.generateSignboardPdf(item, isLandscape: false);
    expect(portraitBytes, isNotNull);
    expect(portraitBytes.length, greaterThan(1000));
  });
}
