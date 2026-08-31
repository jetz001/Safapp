import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/chemicals/data/datasources/chemical_1516_master_data.dart';
import 'package:safety_superapp/features/chemicals/data/datasources/chemical_324_tlv_data.dart';
import 'package:safety_superapp/features/chemicals/data/datasources/chemical_laws_data.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_inventory_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_master_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_tlv_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_sds_sor1_model.dart';
import 'package:safety_superapp/features/chemicals/domain/models/chemical_measurement_sor3_model.dart';
import 'package:safety_superapp/features/chemicals/presentation/widgets/ghs_pictogram_selector.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_sor1_pdf_service.dart';
import 'package:safety_superapp/features/chemicals/services/chemical_sor3_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Master Data 1,516 Chemicals Tests', () {
    test('Master dataset contains exactly 1,516 regulated items', () {
      expect(Chemical1516MasterData.chemicals.length, 1516);
    });

    test('Exact CAS lookup finds Toluene (108-88-3)', () {
      final toluene = Chemical1516MasterData.findByCas('108-88-3');
      expect(toluene, isNotNull);
      expect(toluene!.englishName.toLowerCase(), contains('toluene'));
      expect(toluene.casNumber, '108-88-3');
    });

    test('CAS lookup normalizes dashes (7664939 matches Sulfuric Acid 7664-93-9)', () {
      final sulfuric = Chemical1516MasterData.findByCas('7664939');
      expect(sulfuric, isNotNull);
      expect(sulfuric!.sequenceNo, 2);
      expect(sulfuric.thaiName, contains('กำมะถัน'));
    });

    test('Autocomplete search returns relevant results within top matches', () {
      final results = Chemical1516MasterData.search('benzene', limit: 10);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.englishName.toLowerCase(), contains('benzene'));
    });

    test('Sequence lookup finds correct chemical', () {
      final item1 = Chemical1516MasterData.findBySequence(1);
      expect(item1, isNotNull);
      expect(item1!.thaiName, contains('กรดเกลือ'));
      expect(item1.casNumber, '7647-01-0');
    });
  });

  group('2. TLV Evaluation Engine & 324 Standards Tests', () {
    test('TLV dataset contains 324 occupational exposure standards', () {
      expect(Chemical324TlvData.tlvList.length, 324);
    });

    test('Single chemical evaluation: Measured <= 50% TLV -> PASS', () {
      final result = TlvEvaluationEngine.evaluate(
        measuredValue: 20.0,
        standardLimit: 50.0, // 40% of TLV
        unit: 'ppm',
      );
      expect(result.status, TlvEvalStatus.pass);
      expect(result.isPass, isTrue);
      expect(result.ratio, 0.4);
    });

    test('Single chemical evaluation: 50% < Measured <= 100% TLV -> ACTION_LEVEL', () {
      final result = TlvEvaluationEngine.evaluate(
        measuredValue: 40.0,
        standardLimit: 50.0, // 80% of TLV
        unit: 'ppm',
      );
      expect(result.status, TlvEvalStatus.actionLevel);
      expect(result.isActionLevel, isTrue);
      expect(result.ratio, 0.8);
    });

    test('Single chemical evaluation: Measured > TLV -> EXCEEDED', () {
      final result = TlvEvaluationEngine.evaluate(
        measuredValue: 65.0,
        standardLimit: 50.0, // 130% of TLV
        unit: 'ppm',
      );
      expect(result.status, TlvEvalStatus.exceeded);
      expect(result.isExceeded, isTrue);
      expect(result.ratio, 1.3);
    });

    test('PPM to MG/M3 conversion formula verification (Benzene MW=78.11)', () {
      // mg/m3 = (ppm * MW) / 24.45
      final mgM3 = TlvEvaluationEngine.ppmToMgM3(1.0, 78.11);
      expect((mgM3 * 100).round() / 100, 3.19);
    });

    test('MG/M3 to PPM conversion formula verification (Acetone MW=58.08)', () {
      // ppm = (mg/m3 * 24.45) / MW
      final ppm = TlvEvaluationEngine.mgM3ToPpm(1188.0, 58.08);
      expect(ppm.round(), 500);
    });

    test('Mixture Additive Exposure Index (Em <= 1.0 -> Compliant)', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 10.0, tlv: 50.0), // 0.2
          (measured: 20.0, tlv: 100.0), // 0.2
          (measured: 100.0, tlv: 500.0), // 0.2
        ],
      );
      expect(res.index, 0.6);
      expect(res.isExceeded, isFalse);
    });

    test('Mixture Additive Exposure Index (Em > 1.0 -> Exceeded)', () {
      final res = TlvEvaluationEngine.evaluateMixture(
        components: [
          (measured: 30.0, tlv: 50.0), // 0.6
          (measured: 60.0, tlv: 100.0), // 0.6
        ],
      );
      expect(res.index, 1.2);
      expect(res.isExceeded, isTrue);
    });
  });

  group('3. SDS Lifecycle & Expiry Engine Tests', () {
    final now = DateTime.now();

    test('SDS issued recently (1 year ago, 3-year validity) -> NORMAL', () {
      final issueDate = DateTime(now.year - 1, now.month, now.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.normal);
    });

    test('SDS expiring in 75 days -> NEAR_90', () {
      final expiryTarget = now.add(const Duration(days: 75));
      final issueDate = DateTime(expiryTarget.year - 3, expiryTarget.month, expiryTarget.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near90);
    });

    test('SDS expiring in 45 days -> NEAR_60', () {
      final expiryTarget = now.add(const Duration(days: 45));
      final issueDate = DateTime(expiryTarget.year - 3, expiryTarget.month, expiryTarget.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near60);
    });

    test('SDS expiring in 15 days -> NEAR_30', () {
      final expiryTarget = now.add(const Duration(days: 15));
      final issueDate = DateTime(expiryTarget.year - 3, expiryTarget.month, expiryTarget.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.near30);
    });

    test('SDS issued 4 years ago (3-year validity) -> EXPIRED', () {
      final issueDate = DateTime(now.year - 4, now.month, now.day);
      final status = SdsExpiryCalculation.calculateStatus(issueDate, validityYears: 3);
      expect(status, SdsExpiryStatus.expired);
    });

    test('SDS with null issue date -> NO_SDS', () {
      final status = SdsExpiryCalculation.calculateStatus(null);
      expect(status, SdsExpiryStatus.noSds);
    });
  });

  group('4. Chemical Inventory Model & Serialization Tests', () {
    test('toMap and fromMap serialize properly with all fields', () {
      const item = ChemicalInventoryItem(
        id: 1,
        tradeName: 'Toluene Industrial Grade',
        chemicalNameTh: 'โทลูอีน',
        chemicalNameEn: 'Toluene',
        casNumber: '108-88-3',
        unNumber: 'UN 1294',
        storageLocation: 'คลังสารไวไฟ อาคาร B',
        physicalState: 'LIQUID',
        quantity: 400.0,
        unit: 'L',
        maxCapacity: 1000.0,
        containerType: 'ถังเหล็ก 200 ลิตร (Drums)',
        manufacturerSupplier: 'PTT Global Chemical',
        hazardClass: 'ของเหลวไวไฟ ประเภท ๒',
        ghsPictograms: ['GHS02', 'GHS07', 'GHS08'],
        registerDate: '2026-01-15',
        sdsIssueDate: '2025-06-01',
        sdsExpiryYears: 3,
        nfpaHealth: 2,
        nfpaFlammability: 3,
        nfpaInstability: 0,
        nfpaSpecial: '',
        notes: 'จัดเก็บในห้องควบคุมอุณหภูมิ มีสายต่อลงดินป้องกันไฟฟ้าสถิต',
        status: 'ACTIVE',
      );

      final map = item.toMap();
      expect(map['trade_name'], 'Toluene Industrial Grade');
      expect(map['cas_number'], '108-88-3');
      expect(map['quantity'], 400.0);

      final reconstructed = ChemicalInventoryItem.fromMap(map);
      expect(reconstructed.tradeName, item.tradeName);
      expect(reconstructed.chemicalNameTh, item.chemicalNameTh);
      expect(reconstructed.casNumber, item.casNumber);
      expect(reconstructed.ghsPictograms, contains('GHS02'));
      expect(reconstructed.nfpaFlammability, 3);
      expect(reconstructed.capacityUtilization, 0.4);
    });
  });

  group('5. GHS Pictograms & Legal Reference Library Tests', () {
    test('GHS Pictograms catalog contains 9 official pictograms', () {
      expect(GhsPictograms.all.length, 9);
      expect(GhsPictograms.getByCode('GHS02')!.nameEn, 'Flame');
      expect(GhsPictograms.getByCode('GHS06')!.nameEn, 'Skull and Crossbones');
      expect(GhsPictograms.getByCode('GHS08')!.nameEn, 'Health Hazard');
    });

    test('Legal Reference Library contains 7 Gazette documents', () {
      expect(ChemicalLawsData.laws.length, 7);
      final law1 = ChemicalLawsData.getById('LAW-001');
      expect(law1, isNotNull);
      expect(law1!.gazetteVolume, '๑๓๐');
      expect(law1.titleTh, contains('กฎกระทรวง'));
    });
  });

  group('6. Form สอ.๑ (SDS 16 Sections) Model Serialization & Integrity', () {
    test('ChemicalSdsSor1Model preserves all 16 GHS headings across toMap and fromMap', () {
      const sor1 = ChemicalSdsSor1Model(
        id: 10,
        inventoryId: 1,
        tradeName: 'Toluene Commercial Pure',
        chemicalFormula: 'C7H8',
        casNumber: '108-88-3',
        unNumber: 'UN 1294',
        manufacturerImporterInfo: 'บริษัท สารเคมีไทยพัฒนา จำกัด (โทร 02-123-4567)',
        emergencyPhone: '02-123-4568 (24 ชั่วโมง)',
        recommendedUse: 'ตัวทำละลายในอุตสาหกรรมสีและสารเคลือบ',
        ghsClassification: 'Flammable Liquid Cat. 2, Skin Irrit. Cat. 2, Repr. Cat. 2',
        ghsPictograms: ['GHS02', 'GHS07', 'GHS08'],
        signalWord: 'DANGER',
        hazardStatements: ['H225: ของเหลวและไอระเหยไวไฟสูง', 'H315: ระคายเคืองต่อผิวหนังมาก', 'H361d: สงสัยว่าอาจเกิดอันตรายต่อทารกในครรภ์'],
        precautionaryStatements: ['P210: เก็บให้ห่างจากความร้อน ประกายไฟ', 'P280: สวมถุงมือและแว่นตานิรภัย'],
        nfpaHealth: 2,
        nfpaFlammability: 3,
        nfpaInstability: 0,
        nfpaSpecial: '',
        ingredients: [
          SdsIngredientItem(chemicalName: 'Toluene', casNumber: '108-88-3', percentage: 99.5, hazardClassification: 'Flam. Liq. 2'),
          SdsIngredientItem(chemicalName: 'Benzene (Trace)', casNumber: '71-43-2', percentage: 0.05, hazardClassification: 'Carc. 1A'),
        ],
        inhalationFirstAid: 'ย้ายผู้ป่วยไปยังที่อากาศบริสุทธิ์ ให้ออกซิเจนหากหายใจลำบาก',
        skinContactFirstAid: 'ล้างผิวหนังด้วยน้ำสะอาดและสบู่ปริมาณมากอย่างน้อย 15 นาที',
        eyeContactFirstAid: 'ล้างตาทันทีด้วยน้ำสะอาดปริมาณมากอย่างน้อย 15 นาที',
        ingestionFirstAid: 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาดและนำส่งแพทย์ทันที',
        suitableExtinguishingMedia: 'ผงเคมีแห้ง (Dry Chemical), โฟมทนแอลกอฮอล์, CO2',
        unsuitableExtinguishingMedia: 'ห้ามใช้น้ำฉีดเป็นลำตรง',
        personalPrecautions: 'อพยพผู้ไม่เกี่ยวข้อง สวมอุปกรณ์ PPE กำจัดประกายไฟ',
        handlingPrecautions: 'ใช้งานในพื้นที่ระบายอากาศดี ต่อสายดินป้องกันไฟฟ้าสถิต',
        storageConditions: 'เก็บในที่แห้ง เย็น อากาศถ่ายเท ปิดภาชนะให้แน่น',
        exposureLimits: 'TWA: 50 ppm (188 mg/m3), STEL: 100 ppm',
        engineeringControls: 'ระบบระบายอากาศเฉพาะที่ (Local Exhaust Ventilation)',
        respiratoryProtection: 'หน้ากากไส้กรองไอระเหยสารอินทรีย์ (Organic Vapor)',
        appearance: 'ของเหลวใส ไม่มีสี',
        odor: 'กลิ่นหอมเฉพาะตัวคล้ายน้ำมันเบนซิน',
        phValue: 'N/A',
        boilingPoint: '110.6 °C',
        flashPoint: '4.4 °C (Closed Cup)',
        relativeDensity: '0.867',
        solubility: 'ไม่ละลายน้ำ (0.52 g/L ที่ 20°C)',
        reactivity: 'ไม่มีปฏิกิริยาอันตรายภายใต้สภาวะปกติ',
        chemicalStability: 'เสถียรภายใต้สภาวะการจัดเก็บและการใช้งานปกติ',
        acuteToxicity: 'LD50 ทางปาก (หนู) = 5,580 mg/kg',
        carcinogenicity: 'IARC Group 3 (ไม่จัดเป็นสารก่อมะเร็งในมนุษย์)',
        ecotoxicity: 'LC50 ปลา (96 ชม.) = 5.5 mg/L',
        wasteTreatmentMethods: 'เผาทำลายในเตาเผาขยะอันตรายที่ได้รับอนุญาต',
        unProperShippingName: 'TOLUENE',
        transportHazardClass: '3',
        packingGroup: 'II',
        safetyHealthRegulations: 'กฎกระทรวงสารเคมีอันตราย ๒๕๕๖, ประกาศกรมสวัสดิการฯ ๑,๕๑๖ สารเคมี',
        revisionDate: '2026-08-01',
        versionNo: '2.0',
        preparedBy: 'นายวิชาญ ปลอดภัย (จป.วิชาชีพ เลขที่ ๑๒๓๔๕)',
        referencesList: 'DLPW 2556, ACGIH 2024, NIOSH Pocket Guide',
        status: 'COMPLETED',
      );

      final map = sor1.toMap();
      expect(map['trade_name'], 'Toluene Commercial Pure');
      expect(map['cas_number'], '108-88-3');
      expect(map['signal_word'], 'DANGER');
      expect(map['nfpa_flammability'], 3);

      final reconstructed = ChemicalSdsSor1Model.fromMap(map);
      expect(reconstructed.tradeName, sor1.tradeName);
      expect(reconstructed.chemicalFormula, 'C7H8');
      expect(reconstructed.casNumber, sor1.casNumber);
      expect(reconstructed.ghsPictograms, contains('GHS02'));
      expect(reconstructed.ingredients.length, 2);
      expect(reconstructed.ingredients.first.chemicalName, 'Toluene');
      expect(reconstructed.ingredients.first.percentage, 99.5);
      expect(reconstructed.inhalationFirstAid, contains('ย้ายผู้ป่วย'));
      expect(reconstructed.flashPoint, contains('4.4'));
      expect(reconstructed.versionNo, '2.0');
    });
  });

  group('7. Form สอ.๓ ๒๕๖๕ (Atmospheric Measurement) Model & Sampling Points', () {
    test('ChemicalMeasurementSor3Model and Sor3SamplingPointItem serialization', () {
      final sor3 = ChemicalMeasurementSor3Model(
        id: 1,
        documentNo: 'SOR3-2569-001',
        assessmentDate: '2026-08-15',
        workplaceArea: 'แผนกผสมสารเคลือบผิวและตัวทำละลาย อาคาร 2',
        chemicalName: 'โทลูอีน (Toluene)',
        casNumber: '108-88-3',
        samplingType: 'TWA_8HR',
        samplingDurationMinutes: 480,
        samplingMethod: 'NIOSH Method 1501 / GC-FID',
        measuredValue: 24.5,
        unit: 'ppm',
        tlvStandardValue: 50.0,
        evaluationResult: 'PASS',
        serviceProviderName: 'บริษัท ไทยเอ็นไวรอนเมนทอลแล็บ จำกัด',
        surveyorType: 'SECTION_9',
        serviceProviderM9RegNo: 'นบ. 018-2563',
        samplingOfficerName: 'นายประสิทธิ์ ตรวจวัด',
        analystName: 'น.ส.วิไลลักษณ์ นักเคมี',
        analysisLaboratory: 'Thai Environmental Central Laboratory (ISO/IEC 17025)',
        weatherCondition: 'อากาศแจ่มใส มีลมพัดผ่านเบาๆ',
        temperatureCelsius: 29.2,
        relativeHumidity: 65.0,
        correctiveAction: 'ผลการตรวจวัดอยู่ในเกณฑ์มาตรฐานความปลอดภัย แนะนำให้บำรุงรักษาระบบดูดอากาศเฉพาะที่ตามแผนงาน',
        samplingPoints: const [
          Sor3SamplingPointItem(
            pointCode: 'SP-01',
            workAreaName: 'จุดเทสารเคมีลงถังผสมที่ 1',
            processDescription: 'งานตวงและเทสารทำละลาย',
            exposedWorkersCount: 2,
            ppeUsed: 'หน้ากาก 3M ไส้กรอง Organic Vapor, ถุงมือ Nitrile',
            chemicalName: 'Toluene',
            casNumber: '108-88-3',
            samplingType: 'TWA_8HR',
            samplingDurationMinutes: 480,
            measuredValue: 22.0,
            unit: 'ppm',
            tlvStandardValue: 50.0,
            evaluationResult: 'PASS',
          ),
          Sor3SamplingPointItem(
            pointCode: 'SP-02',
            workAreaName: 'จุดบรรจุผลิตภัณฑ์ลงถัง 200 ลิตร',
            processDescription: 'งานบรรจุและปิดฝาถัง',
            exposedWorkersCount: 1,
            ppeUsed: 'หน้ากาก Organic Vapor, แว่นครอบตา',
            chemicalName: 'Toluene',
            casNumber: '108-88-3',
            samplingType: 'TWA_8HR',
            samplingDurationMinutes: 480,
            measuredValue: 27.0,
            unit: 'ppm',
            tlvStandardValue: 50.0,
            evaluationResult: 'PASS',
          ),
        ],
        status: 'APPROVED',
      );

      final map = sor3.toMap();
      expect(map['document_no'], 'SOR3-2569-001');
      expect(map['measured_value'], 24.5);
      expect(map['service_provider_m9_reg_no'], 'นบ. 018-2563');

      final reconstructed = ChemicalMeasurementSor3Model.fromMap(map);
      expect(reconstructed.documentNo, sor3.documentNo);
      expect(reconstructed.chemicalName, sor3.chemicalName);
      expect(reconstructed.samplingPoints.length, 2);
      expect(reconstructed.samplingPoints.first.pointCode, 'SP-01');
      expect(reconstructed.samplingPoints.first.isPass, isTrue);
      expect(reconstructed.ratioPercentage, 49.0);
      expect(reconstructed.isPass, isTrue);
    });

    test('Section 11 Individual Surveyor is correctly identified', () {
      const sor3Sec11 = ChemicalMeasurementSor3Model(
        documentNo: 'SOR3-SEC11-002',
        assessmentDate: '2026-08-20',
        workplaceArea: 'ห้องปฏิบัติการเคมี',
        chemicalName: 'Hexane',
        casNumber: '110-54-3',
        measuredValue: 45.0,
        unit: 'ppm',
        tlvStandardValue: 50.0,
        evaluationResult: 'ACTION_LEVEL',
        serviceProviderName: 'นายสุขุม สุขศาสตร์',
        surveyorType: 'SECTION_11',
        serviceProviderM11CertNo: 'บ. 042-2564',
        surveyorQualification: 'วศ.ม. สุขศาสตร์อุตสาหกรรมและความปลอดภัย',
      );

      expect(sor3Sec11.isActionLevel, isTrue);
      expect(sor3Sec11.ratioPercentage, 90.0);
      expect(sor3Sec11.surveyorType, 'SECTION_11');
      expect(sor3Sec11.serviceProviderM11CertNo, 'บ. 042-2564');
    });
  });

  group('8. Statutory Form สอ.๑ PDF Service Generation Tests', () {
    test('generatePdf produces valid non-empty PDF byte stream', () async {
      const sor1 = ChemicalSdsSor1Model(
        id: 1,
        tradeName: 'Acetone Industrial Grade',
        chemicalFormula: 'C3H6O',
        casNumber: '67-64-1',
        unNumber: 'UN 1090',
        manufacturerImporterInfo: 'บริษัท เคมีอุตสาหกรรมสยาม จำกัด',
        emergencyPhone: '02-999-8888',
        ghsClassification: 'Flammable Liquid Cat. 2, Eye Irrit. Cat. 2',
        ghsPictograms: ['GHS02', 'GHS07'],
        signalWord: 'DANGER',
        hazardStatements: ['H225: ของเหลวและไอระเหยไวไฟสูง', 'H319: ระคายเคืองต่อดวงตาอย่างรุนแรง'],
        precautionaryStatements: ['P210: เก็บให้ห่างจากเปลวไฟ', 'P280: สวมใส่อุปกรณ์ป้องกันดวงตา'],
        nfpaHealth: 1,
        nfpaFlammability: 3,
        nfpaInstability: 0,
        appearance: 'ของเหลวใส ไม่มีสี',
        boilingPoint: '56.1 °C',
        flashPoint: '-20.0 °C',
        revisionDate: '2026-08-01',
        preparedBy: 'จป.วิชาชีพ โรงงาน',
      );

      final pdfBytes = await ChemicalSor1PdfService.generatePdf(
        sor1,
        companyName: 'บริษัท ทดสอบความปลอดภัยอุตสาหกรรม จำกัด',
        companyAddress: '123 นิคมอุตสาหกรรมบางปู จ.สมุทรปราการ',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF headers start with '%PDF'
      final header = String.fromCharCodes(pdfBytes.sublist(0, 4));
      expect(header, '%PDF');
    });
  });

  group('9. Statutory Form สอ.๓ ๒๕๖๕ PDF Service Generation Tests', () {
    test('generatePdf produces valid non-empty Form สอ.๓ PDF document', () async {
      final sor3 = ChemicalMeasurementSor3Model(
        id: 1,
        documentNo: 'SOR3-TEST-001',
        assessmentDate: '2026-08-25',
        workplaceArea: 'สายการผลิตยานยนต์ โซน B',
        chemicalName: 'ไซลีน (Xylene)',
        casNumber: '1330-20-7',
        samplingType: 'TWA_8HR',
        samplingDurationMinutes: 480,
        samplingMethod: 'NIOSH 1501',
        measuredValue: 35.0,
        unit: 'ppm',
        tlvStandardValue: 100.0,
        evaluationResult: 'PASS',
        serviceProviderName: 'บริษัท ตรวจวัดสิ่งแวดล้อมสากล จำกัด',
        surveyorType: 'SECTION_9',
        serviceProviderM9RegNo: 'นบ. 005-2563',
        samplingPoints: const [
          Sor3SamplingPointItem(
            pointCode: 'SP-01',
            workAreaName: 'สถานีพ่นสีตัวถัง',
            chemicalName: 'Xylene',
            casNumber: '1330-20-7',
            measuredValue: 35.0,
            tlvStandardValue: 100.0,
            evaluationResult: 'PASS',
          ),
        ],
      );

      final pdfBytes = await ChemicalSor3PdfService.generatePdf(
        sor3,
        companyName: 'บริษัท ออโตโมทีฟ แมนูแฟคเจอริ่ง จำกัด',
        companyAddress: '456 นิคมอุตสาหกรรมอีสเทิร์นซีบอร์ด ระยอง',
        companyTaxId: '0105555123456',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.sublist(0, 4));
      expect(header, '%PDF');
    });
  });
}
