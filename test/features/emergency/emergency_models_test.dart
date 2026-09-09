import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/emergency/domain/enums/hazard_type.dart';
import 'package:safety_superapp/features/emergency/domain/enums/emergency_enums.dart';
import 'package:safety_superapp/features/emergency/data/models/emergency_plan_model.dart';
import 'package:safety_superapp/features/emergency/data/models/drill_session_model.dart';
import 'package:safety_superapp/features/emergency/data/models/electrical_inspection_model.dart';
import 'package:safety_superapp/features/emergency/data/datasources/emergency_presets_data.dart';

void main() {
  group('Emergency Models Serialization Tests', () {
    test('EmergencyPlanModel toMap and fromMap roundtrip', () {
      final preset = EmergencyPresetsData.getPreset(
        hazardType: HazardType.chemicalSpill,
        businessType: BusinessType.chemicalStorage,
        companyName: 'บริษัท ทดสอบเคมี จำกัด',
      );

      final map = preset.toMap();
      final restored = EmergencyPlanModel.fromMap(map);

      expect(restored.planTitle, preset.planTitle);
      expect(restored.hazardType, HazardType.chemicalSpill);
      expect(restored.companyName, 'บริษัท ทดสอบเคมี จำกัด');
      expect(restored.inspectionPlan.items.length, preset.inspectionPlan.items.length);
      expect(restored.suppressionPlan.regularShiftTeam.length, preset.suppressionPlan.regularShiftTeam.length);
      expect(restored.evacuationPlan.assemblyPoints.length, preset.evacuationPlan.assemblyPoints.length);
      expect(restored.evacuationPlan.evacuationTeams.length, preset.evacuationPlan.evacuationTeams.length);
    });

    test('EvacuationTeam multiple teams and member lists serialization test', () {
      final team1 = EvacuationTeam(
        teamName: 'ทีมผู้นำทางหนีไฟ อาคาร 1 ชั้น 2',
        areaFloor: 'อาคาร 1 ชั้น 2',
        leaderName: 'นายสมศักดิ์ มั่นคง',
        deputyLeaderName: 'นางสาวสิริพร พิทักษ์',
        members: ['นายเอกชัย รวดเร็ว', 'นางสาวอรวรรณ สดใส', 'นายพงษ์ศักดิ์ ตั้งใจ'],
        assignedAssemblyPoint: 'จุดรวมพลที่ ๑',
        duties: 'นำทางพนักงานอพยพตามเส้นทางที่กำหนด',
      );

      final team2 = EvacuationTeam(
        teamName: 'ทีมตรวจค้นผู้ติดค้าง (Search Team)',
        areaFloor: 'ทุกอาคาร',
        leaderName: 'นายวีระพล กล้าหาญ',
        members: ['นายสมควร ขยันยิ่ง', 'นายเดชา แข็งขัน'],
        assignedAssemblyPoint: 'จุดรวมพลที่ ๒',
        duties: 'ตรวจค้นห้องน้ำและจุดอับ',
      );

      final evacuationPlan = EvacuationSubPlan(
        alarmSoundSignal: 'สัญญาณเตือนภัยต่อเนื่อง',
        evacuationTeams: [team1, team2],
        assemblyPoints: const [
          AssemblyPointItem(pointName: 'จุดรวมพลที่ ๑', location: 'ลานจอดรถ', assignedDepartments: 'ทุกแผนก'),
        ],
        headcountMethod: 'เช็คชื่อตามใบรายชื่อ',
      );

      final map = evacuationPlan.toMap();
      final restored = EvacuationSubPlan.fromMap(map);

      expect(restored.evacuationTeams.length, 2);
      expect(restored.evacuationTeams[0].teamName, 'ทีมผู้นำทางหนีไฟ อาคาร 1 ชั้น 2');
      expect(restored.evacuationTeams[0].members.length, 3);
      expect(restored.evacuationTeams[0].members, contains('นายเอกชัย รวดเร็ว'));
      expect(restored.evacuationTeams[1].teamName, 'ทีมตรวจค้นผู้ติดค้าง (Search Team)');
      expect(restored.evacuationTeams[1].members.length, 2);
    });

    test('DrillSessionModel toMap and fromMap roundtrip', () {
      final drill = DrillSessionModel(
        drillTitle: 'ทดสอบการซ้อมอพยพประจำปี',
        drillDate: '2025-11-15',
        drillYear: 2025,
        hazardType: HazardType.fire,
        totalWorkersOnSite: 150,
        participatedCount: 148,
        maleParticipants: 88,
        femaleParticipants: 60,
        participationRatePercent: 98.67,
        initialAttackTimeSec: 35,
        evacuationTimeSec: 210,
        headcountStatus: HeadcountStatus.allAccounted,
        submissionDeadline: '2025-12-15',
        spr4SubmissionStatus: Spr4SubmissionStatus.pending,
      );

      final map = drill.toMap();
      final restored = DrillSessionModel.fromMap(map);

      expect(restored.drillTitle, drill.drillTitle);
      expect(restored.drillDate, '2025-11-15');
      expect(restored.participatedCount, 148);
      expect(restored.evacuationTimeSec, 210);
      expect(restored.headcountStatus, HeadcountStatus.allAccounted);
      expect(restored.spr4SubmissionStatus, Spr4SubmissionStatus.pending);
    });

    test('Multi-Hazard Presets generation for all hazards including electrical', () {
      for (final hazard in HazardType.values) {
        final plan = EmergencyPresetsData.getPreset(
          hazardType: hazard,
          businessType: BusinessType.factory,
        );
        expect(plan.hazardType, hazard);
        expect(plan.planTitle.isNotEmpty, isTrue);
      }
    });

    test('ElectricalInspectionModel toMap and fromMap roundtrip with PDF attachments', () {
      final now = DateTime.now();
      final inspection = ElectricalInspectionModel(
        companyName: 'บริษัท ทดสอบระบบไฟฟ้า จำกัด',
        inspectionDate: DateTime(2025, 5, 10),
        expiryDate: DateTime(2026, 5, 10),
        inspectorName: 'นายวิศวะ ไฟฟ้าสยาม',
        inspectorLicenseNo: 'ภฟก. 998877',
        contractorCompany: 'บริษัท เอ็นจิเนียริ่ง เทสท์ จำกัด',
        voltageSystem: 'HIGH_AND_LOW_VOLTAGE',
        transformerCount: 2,
        mdbPanelCount: 5,
        groundingResistanceOhm: 3.2,
        overallResult: 'PASS',
        defectsFound: 'ไม่มีข้อบกพร่องสำคัญ',
        correctiveActions: 'บำรุงรักษาตามรอบปกติ',
        vendorReportPdfPath: 'D:\\docs\\vendor_report_2025.pdf',
        thermoscanReportPath: 'D:\\docs\\thermoscan_2025.pdf',
        engineerLicenseDocPath: 'D:\\docs\\engineer_license.pdf',
      );

      final map = inspection.toMap();
      final restored = ElectricalInspectionModel.fromMap(map);

      expect(restored.companyName, 'บริษัท ทดสอบระบบไฟฟ้า จำกัด');
      expect(restored.inspectorName, 'นายวิศวะ ไฟฟ้าสยาม');
      expect(restored.inspectorLicenseNo, 'ภฟก. 998877');
      expect(restored.contractorCompany, 'บริษัท เอ็นจิเนียริ่ง เทสท์ จำกัด');
      expect(restored.transformerCount, 2);
      expect(restored.mdbPanelCount, 5);
      expect(restored.groundingResistanceOhm, 3.2);
      expect(restored.isGroundingStandardPass, isTrue);
      expect(restored.vendorReportPdfPath, 'D:\\docs\\vendor_report_2025.pdf');
      expect(restored.thermoscanReportPath, 'D:\\docs\\thermoscan_2025.pdf');
      expect(restored.engineerLicenseDocPath, 'D:\\docs\\engineer_license.pdf');
    });

    test('ElectricalInspectionModel SLA status correctly differentiates compliant, warning, overdue', () {
      final today = DateTime.now();

      // Overdue (expired 10 days ago)
      final overdueRecord = ElectricalInspectionModel(
        inspectionDate: today.subtract(const Duration(days: 375)),
        expiryDate: today.subtract(const Duration(days: 10)),
        inspectorName: 'ช่างทดสอบ 1',
        inspectorLicenseNo: '111',
      );
      expect(overdueRecord.isOverdue, isTrue);
      expect(overdueRecord.slaStatus, ElectricalInspectionStatus.overdue);

      // Warning (expires in 30 days)
      final warningRecord = ElectricalInspectionModel(
        inspectionDate: today.subtract(const Duration(days: 335)),
        expiryDate: today.add(const Duration(days: 30)),
        inspectorName: 'ช่างทดสอบ 2',
        inspectorLicenseNo: '222',
      );
      expect(warningRecord.isOverdue, isFalse);
      expect(warningRecord.isExpiringSoon, isTrue);
      expect(warningRecord.slaStatus, ElectricalInspectionStatus.warning);

      // Compliant (expires in 200 days)
      final compliantRecord = ElectricalInspectionModel(
        inspectionDate: today.subtract(const Duration(days: 165)),
        expiryDate: today.add(const Duration(days: 200)),
        inspectorName: 'ช่างทดสอบ 3',
        inspectorLicenseNo: '333',
      );
      expect(compliantRecord.isOverdue, isFalse);
      expect(compliantRecord.isExpiringSoon, isFalse);
      expect(compliantRecord.slaStatus, ElectricalInspectionStatus.compliant);
    });

    test('ElectricalInspectionModel grounding resistance evaluates <= 5 ohm limit', () {
      final pass = ElectricalInspectionModel(
        inspectionDate: DateTime.now(),
        inspectorName: 'วิศวกร',
        inspectorLicenseNo: '123',
        groundingResistanceOhm: 4.8,
      );
      expect(pass.isGroundingStandardPass, isTrue);

      final fail = ElectricalInspectionModel(
        inspectionDate: DateTime.now(),
        inspectorName: 'วิศวกร',
        inspectorLicenseNo: '123',
        groundingResistanceOhm: 6.5,
      );
      expect(fail.isGroundingStandardPass, isFalse);
    });
  });
}
