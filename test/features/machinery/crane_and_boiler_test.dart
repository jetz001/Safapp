import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/machinery/data/models/crane_inspection_model.dart';
import 'package:safety_superapp/features/machinery/data/models/boiler_inspection_model.dart';
import 'package:safety_superapp/features/machinery/data/models/machinery_asset_model.dart';

void main() {
  group('Machinery & Crane Inspection Model Tests', () {
    test('CraneInspectionModel toMap and fromMap serialization roundtrip', () {
      final crane = CraneInspectionModel(
        id: 1,
        craneName: 'ปั้นจั่นเหนือศีรษะ 5 ตัน อาคารผลิต 1',
        craneTag: 'CRANE-01-OH',
        craneType: 'OVERHEAD',
        inspectionForm: 'PJ1',
        locationBuilding: 'อาคารผลิต 1',
        locationArea: 'Bay 1',
        safeWorkingLoadTon: 5.0,
        testWeightTon: 6.25,
        loadTestPercent: 125.0,
        inspectionCycleMonths: 6,
        wireRopeStatus: 'PASS',
        hookLatchStatus: 'PASS',
        limitSwitchStatus: 'PASS',
        brakeSystemStatus: 'PASS',
        structureStatus: 'PASS',
        engineerName: 'ธีรพงษ์ วิศวกรเครื่องกล',
        engineerLicenseNo: 'สค. 8891',
        contractorCompany: 'บริษัท สยามเครน จำกัด',
        inspectionDate: DateTime(2026, 1, 15),
        expiryDate: DateTime(2026, 7, 15),
        overallResult: 'PASS',
        defectsFound: 'ไม่มีข้อบกพร่อง',
        correctiveActions: 'อัดจารบีประจำเดือน',
        vendorReportPdfPath: 'D:/docs/pj1_report.pdf',
        loadTestCertPdfPath: 'D:/docs/load_cert.pdf',
        engineerLicensePdfPath: 'D:/docs/eng_license.pdf',
      );

      final map = crane.toMap();
      expect(map['crane_tag'], 'CRANE-01-OH');
      expect(map['safe_working_load_ton'], 5.0);
      expect(map['test_weight_ton'], 6.25);
      expect(map['inspection_form'], 'PJ1');
      expect(map['inspection_cycle_months'], 6);

      final restored = CraneInspectionModel.fromMap(map);
      expect(restored.id, crane.id);
      expect(restored.craneTag, crane.craneTag);
      expect(restored.safeWorkingLoadTon, 5.0);
      expect(restored.testWeightTon, 6.25);
      expect(restored.engineerName, 'ธีรพงษ์ วิศวกรเครื่องกล');
      expect(restored.vendorReportPdfPath, 'D:/docs/pj1_report.pdf');
      expect(restored.inspectionFormTh, contains('ปจ.๑'));
    });

    test('Crane SLA status evaluates compliant, warning, overdue accurately', () {
      final now = DateTime.now();

      // Future expiry > 30 days -> COMPLIANT
      final compliantCrane = CraneInspectionModel(
        craneName: 'เครนปกติ',
        craneTag: 'C-01',
        craneType: 'OVERHEAD',
        inspectionForm: 'PJ1',
        locationBuilding: 'Bld 1',
        safeWorkingLoadTon: 10.0,
        engineerName: 'วิศวกร',
        engineerLicenseNo: 'สค. 1',
        inspectionDate: now,
        expiryDate: now.add(const Duration(days: 90)),
      );
      expect(compliantCrane.slaStatus, 'COMPLIANT');
      expect(compliantCrane.isExpired, isFalse);

      // Expiry within 30 days -> WARNING
      final warningCrane = CraneInspectionModel(
        craneName: 'เครนใกล้หมดอายุ',
        craneTag: 'C-02',
        craneType: 'JIB',
        inspectionForm: 'PJ1',
        locationBuilding: 'Bld 2',
        safeWorkingLoadTon: 2.0,
        engineerName: 'วิศวกร',
        engineerLicenseNo: 'สค. 2',
        inspectionDate: now.subtract(const Duration(days: 350)),
        expiryDate: now.add(const Duration(days: 15)),
      );
      expect(warningCrane.slaStatus, 'WARNING');
      expect(warningCrane.isExpired, isFalse);

      // Past expiry -> OVERDUE
      final overdueCrane = CraneInspectionModel(
        craneName: 'เครนหมดอายุ',
        craneTag: 'C-03',
        craneType: 'MOBILE',
        inspectionForm: 'PJ2',
        locationBuilding: 'Yard',
        safeWorkingLoadTon: 25.0,
        engineerName: 'วิศวกร',
        engineerLicenseNo: 'สค. 3',
        inspectionDate: now.subtract(const Duration(days: 200)),
        expiryDate: now.subtract(const Duration(days: 20)),
      );
      expect(overdueCrane.slaStatus, 'OVERDUE');
      expect(overdueCrane.isExpired, isTrue);
    });

    test('Crane Load Test 1.25x statutory rule verification', () {
      const swl = 20.0;
      final requiredTestWeight = swl * 1.25;
      expect(requiredTestWeight, 25.0);

      final crane = CraneInspectionModel(
        craneName: 'ปั้นจั่น 20 ตัน',
        craneTag: 'C-20',
        craneType: 'GANTRY',
        inspectionForm: 'PJ1',
        locationBuilding: 'Yard 1',
        safeWorkingLoadTon: swl,
        testWeightTon: requiredTestWeight,
        loadTestPercent: (requiredTestWeight / swl) * 100,
        engineerName: 'วิศวกร',
        engineerLicenseNo: 'สค. 99',
        inspectionDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
      );

      expect(crane.loadTestPercent, 125.0);
    });
  });

  group('Boiler Inspection Model Tests', () {
    test('BoilerInspectionModel toMap and fromMap serialization roundtrip', () {
      final boiler = BoilerInspectionModel(
        id: 1,
        boilerName: 'หม้อน้ำไอน้ำท่อไฟ 2 ตัน/ชม.',
        boilerTag: 'BOILER-01',
        boilerType: 'STEAM_BOILER',
        capacityTonHr: 2.0,
        locationBuilding: 'Utility',
        maxAllowableWorkingPressureBar: 10.0,
        hydroTestPressureBar: 15.0,
        hydroTestResult: 'PASS',
        safetyValveTestResult: 'PASS',
        safetyValvePopPressureBar: 10.5,
        waterTreatmentStatus: 'PASS',
        burnerControlStatus: 'PASS',
        engineerName: 'ณรงค์ศักดิ์ กว.',
        engineerLicenseNo: 'สค. 3312',
        contractorCompany: 'บริษัท บอยเลอร์ จำกัด',
        inspectionDate: DateTime(2026, 2, 1),
        expiryDate: DateTime(2027, 2, 1),
        overallResult: 'PASS',
        reportPdfPath: 'D:/docs/boiler_report.pdf',
      );

      final map = boiler.toMap();
      expect(map['boiler_tag'], 'BOILER-01');
      expect(map['max_allowable_working_pressure_bar'], 10.0);
      expect(map['hydro_test_pressure_bar'], 15.0);
      expect(map['safety_valve_pop_pressure_bar'], 10.5);

      final restored = BoilerInspectionModel.fromMap(map);
      expect(restored.id, boiler.id);
      expect(restored.boilerTag, 'BOILER-01');
      expect(restored.hydroTestPressureBar, 15.0);
      expect(restored.boilerTypeTh, contains('หม้อน้ำไอน้ำ'));
      expect(restored.overallResult, 'PASS');
    });

    test('Boiler hydro test pressure ratio standard is 1.5x MAWP', () {
      const mawp = 12.0;
      final expectedHydro = mawp * 1.5;
      expect(expectedHydro, 18.0);
    });
  });

  group('Machinery Asset Model Tests', () {
    test('MachineryAssetModel serialization and status', () {
      final asset = MachineryAssetModel(
        id: 1,
        assetTag: 'SLING-01',
        assetName: 'ลวดสลิง 4 ขา',
        category: 'SLING_WIRE',
        ratedCapacity: 'WLL 5.0 Ton',
        location: 'อาคารผลิต 1',
        manufacturerBrand: 'KISWIRE',
        serialNo: 'SN-001',
        status: 'READY',
      );

      final map = asset.toMap();
      expect(map['asset_tag'], 'SLING-01');
      expect(map['category'], 'SLING_WIRE');
      expect(map['status'], 'READY');

      final restored = MachineryAssetModel.fromMap(map);
      expect(restored.assetName, 'ลวดสลิง 4 ขา');
      expect(restored.categoryTh, contains('ลวดสลิง'));
      expect(restored.statusTh, contains('พร้อมใช้งาน'));

      // CopyWith status transition to DEFECTIVE
      final defective = restored.copyWith(status: 'DEFECTIVE', notes: 'เส้นลวดแตกขาดเกิน 10%');
      expect(defective.status, 'DEFECTIVE');
      expect(defective.statusTh, contains('ชำรุดห้ามใช้'));
      expect(defective.notes, contains('เส้นลวดแตก'));
    });
  });
}
