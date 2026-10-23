import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_inventory_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_measurement_sor3_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_sds_sor1_model.dart';
import 'package:safety_superapp/features/chemicals/presentation/widgets/ghs_diamond_widget.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_signboard_pdf_service.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_sor1_pdf_service.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_sor3_pdf_service.dart';

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

  test('ChemicalSor1PdfService generates authentic 4-page statutory Form สอ.๑ PDF', () async {
    const sor1Model = ChemicalSdsSor1Model(
      id: 1,
      inventoryId: 1,
      tradeName: 'อะซิโตน (Acetone High Purity 99.5%)',
      casNumber: '67-64-1',
      unNumber: 'UN 1090',
      chemicalFormula: 'C3H6O',
      manufacturerImporterInfo: 'บริษัท เซฟแอพ โกลบอล เคมีคอล จำกัด\nเลขที่ 123 นิคมอุตสาหกรรมอมตะซิตี้ ระยอง',
      emergencyPhone: '038-999-999',
      recommendedUse: 'ตัวทำละลายสำหรับงานอุตสาหกรรมและห้องปฏิบัติการ',
      ghsClassification: 'Flammable Liquids Cat 2, Eye Irritation Cat 2A, STOT SE 3',
      ghsPictograms: ['GHS02', 'GHS07'],
      signalWord: 'DANGER',
      hazardStatements: [
        'H225: ของเหลวและไอระเหยไวไฟสูง',
        'H319: ระคายเคืองต่อดวงตาอย่างรุนแรง',
        'H336: อาจทำให้ง่วงซึมหรือมึนงง',
      ],
      precautionaryStatements: [
        'P210: เก็บให้ห่างจากความร้อน ประกายไฟ เปลวไฟ และพื้นผิวที่ร้อน',
        'P280: สวมถุงมือป้องกัน แว่นตานิรภัย หน้ากากป้องกันสารเคมี',
      ],
      nfpaHealth: 1,
      nfpaFlammability: 3,
      nfpaInstability: 0,
      ingredients: [
        SdsIngredientItem(
          chemicalName: 'Acetone',
          casNumber: '67-64-1',
          percentage: 99.5,
          hazardClassification: 'Flam. Liq. 2, Eye Irrit. 2',
          tlvPel: '500 ppm',
        ),
      ],
      compositionSummary: 'อะซิโตนบริสุทธิ์ 99.5% โดยน้ำหนัก',
      inhalationFirstAid: 'ย้ายผู้ป่วยไปยังที่ที่มีอากาศบริสุทธิ์',
      skinContactFirstAid: 'ล้างออกด้วยน้ำสะอาดปริมาณมากและสบู่',
      eyeContactFirstAid: 'ล้างตาด้วยน้ำสะอาดไหลผ่านทันทีอย่างน้อย 15 นาที',
      ingestionFirstAid: 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาดและรีบนำส่งแพทย์',
      suitableExtinguishingMedia: 'ผงเคมีแห้ง, โฟมทนแอลกอฮอล์, คาร์บอนไดออกไซด์',
      personalPrecautions: 'สวมอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่เหมาะสม',
      handlingPrecautions: 'ใช้ในบริเวณที่มีการระบายอากาศที่ดี ต่อสายดินภาชนะ',
      storageConditions: 'เก็บในที่แห้ง เย็น และมีการระบายอากาศเพียงพอ',
      exposureLimits: 'OSHA PEL: 1,000 ppm, ACGIH TLV: 250 ppm (TWA)',
      appearance: 'ของเหลวใส ไม่มีสี กลิ่นฉุนเฉพาะตัว',
      phValue: '7.0',
      boilingPoint: '56.1 °C',
      flashPoint: '-20.0 °C',
      vaporPressure: '24.0 kPa (@ 20°C)',
      relativeDensity: '0.79 g/cm³',
      solubility: 'ละลายได้สมบูรณ์ในน้ำ',
      reactivity: 'ไม่มีปฏิกิริยาอันตรายภายใต้สภาวะปกติ',
      chemicalStability: 'มีความเสถียรภายใต้สภาวะปกติ',
      acuteToxicity: 'LD50 ทางปาก (หนู): 5,800 mg/kg, LC50 ทางการหายใจ (หนู): 76 mg/L (4 ชม.)',
      ecotoxicity: 'LC50 ปลาเรนโบว์เทราต์: 5,540 mg/L (96 ชม.)',
      wasteTreatmentMethods: 'กำจัดตามพระราชบัญญัติโรงงานและกฎหมายสิ่งแวดล้อม',
      unProperShippingName: 'ACETONE',
      transportHazardClass: '3',
      packingGroup: 'II',
      safetyHealthRegulations: 'พรบ. วัตถุอันตราย พ.ศ. 2535 วัตถุอันตรายชนิดที่ 3',
      revisionDate: '23 ตุลาคม 2569',
      versionNo: '4.0',
      preparedBy: 'ฝ่ายความปลอดภัยและอาชีวอนามัย บจก. เซฟแอพ โกลบอล',
      referencesList: 'DLPW Notification, ACGIH 2024, ECHA REACH dossier',
      status: 'APPROVED',
    );

    final bytes = await ChemicalSor1PdfService.generatePdf(
      sor1Model,
      companyName: 'บริษัท เซฟแอพ โกลบอล เคมีคอล จำกัด',
      companyAddress: 'เลขที่ 123 นิคมอุตสาหกรรมอมตะซิตี้ อ.ปลวกแดง จ.ระยอง 21140',
      companyPhone: '038-999-999',
      companyEmail: 'ehs@safapp-chemical.com',
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(2000));
  });

  test('ChemicalSor3PdfService generates authentic A4 landscape statutory Form สอ.๓ PDF', () async {
    const sor3Model = ChemicalMeasurementSor3Model(
      id: 1,
      documentNo: 'SOR3-2026-0042',
      assessmentDate: '23/10/2569',
      workplaceArea: 'อาคารผลิตสารทำความสะอาด แผนกผสมเคมี A',
      samplingPointDescription: 'จุดตวงเทตัวทำละลายถังผสม Blend Tank-01',
      chemicalName: 'โทลูอีน (Toluene)',
      casNumber: '108-88-3',
      samplingType: 'TWA_8HR',
      samplingDurationMinutes: 480,
      samplingMethod: 'NIOSH Method 1501 (Solid Sorbent Tube)',
      measuredValue: 18.5,
      unit: 'ppm',
      tlvStandardValue: 50.0,
      evaluationResult: 'PASS',
      serviceProviderName: 'บริษัท ศูนย์วิเคราะห์สิ่งแวดล้อมและอาชีวอนามัยไทย จำกัด',
      surveyorType: 'SECTION_11',
      serviceProviderM11CertNo: 'ว-245-จ-789/2565',
      surveyorValidTo: '31/12/2571',
      surveyorQualification: 'ผู้ควบคุมระบบบำบัดมลพิษ / ผู้ขึ้นทะเบียนตรวจวัดสิ่งแวดล้อม',
      samplingOfficerName: 'นายพิเชษฐ์ วิศวการ EHS',
      analystName: 'ดร.สมชาย เคมีวิเคราะห์',
      analysisLaboratory: 'ห้องปฏิบัติการเอกชนที่ได้รับการรับรอง ISO/IEC 17025',
      weatherCondition: 'อากาศแจ่มใส มีระบบระบายอากาศ Local Exhaust',
      temperatureCelsius: 28.5,
      relativeHumidity: 62.0,
      correctiveAction: 'ระดับความเข้มข้นไม่เกินค่ามาตรฐาน 50 ppm ให้บำรุงรักษาระบบ LEV ทุก 3 เดือน',
      status: 'APPROVED',
      samplingPoints: [
        Sor3SamplingPointItem(
          pointCode: 'SP-01',
          workAreaName: 'จุดเทตวงสารเคมี Tank-01',
          processDescription: 'ตวงเท Toluene เข้าถังทำปฏิกิริยา',
          exposedWorkersCount: 4,
          ppeUsed: 'หน้ากากครึ่งหน้าไส้กรองไอระเหยอินทรีย์, ถุงมือไนไตรล์หนา 15 mil',
          chemicalName: 'โทลูอีน (Toluene)',
          casNumber: '108-88-3',
          samplingType: 'TWA_8HR',
          samplingDurationMinutes: 480,
          airVolumeLiters: 96.0,
          samplingMethod: 'NIOSH 1501',
          analyticalMethod: 'GC-FID (FID Detector)',
          measuredValue: 18.5,
          unit: 'ppm',
          tlvStandardValue: 50.0,
          evaluationResult: 'PASS',
        ),
        Sor3SamplingPointItem(
          pointCode: 'SP-02',
          workAreaName: 'จุดบรรจุแกลลอน 20 ลิตร',
          processDescription: 'บรรจุสารละลายเคมีลงบรรจุภัณฑ์',
          exposedWorkersCount: 3,
          ppeUsed: 'หน้ากากครึ่งหน้าไส้กรองไอระเหยอินทรีย์, แว่นครอบตากันสารเคมี',
          chemicalName: 'โทลูอีน (Toluene)',
          casNumber: '108-88-3',
          samplingType: 'TWA_8HR',
          samplingDurationMinutes: 480,
          airVolumeLiters: 96.0,
          samplingMethod: 'NIOSH 1501',
          analyticalMethod: 'GC-FID (FID Detector)',
          measuredValue: 24.2,
          unit: 'ppm',
          tlvStandardValue: 50.0,
          evaluationResult: 'PASS',
        ),
      ],
    );

    final bytes = await ChemicalSor3PdfService.generatePdf(
      sor3Model,
      companyName: 'บริษัท สยามแมนูแฟคเจอริ่ง แอนด์ เคมีคอล จำกัด',
      companyAddress: 'เลขที่ 88 หมู่ 4 นิคมอุตสาหกรรมมาบตาพุด ต.มาบตาพุด อ.เมือง จ.ระยอง 21150',
      companyTaxId: '0105559012345',
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(2000));
  });
}
