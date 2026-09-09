import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/audit_inspection/data/datasources/audit_master_checklist_data.dart';
import 'package:safety_superapp/features/audit_inspection/domain/models/audit_models.dart';
import 'package:safety_superapp/features/safety_manual/data/models/factory_scope_model.dart';

void main() {
  group('Audit Models & Calculations Tests', () {
    test('AuditSession initializes with correct default stats and calculates completion', () {
      const session = AuditSession(
        id: 1,
        auditNo: 'AUD-2026-001',
        auditTitle: 'การตรวจประเมินระบบการจัดการความปลอดภัยประจำปี ๒๕๖๙',
        auditDate: '2026-09-09',
        leadAuditor: 'จป.วิชาชีพ สมชาย',
        auditScope: 'INTEGRATED',
        totalItems: 24,
        conformCount: 20,
        minorNcCount: 2,
        majorNcCount: 0,
        naCount: 2,
        compliancePercentage: 90.9,
      );

      expect(session.auditNo, 'AUD-2026-001');
      expect(session.totalItems, 24);
      expect(session.conformCount, 20);
      expect(session.compliancePercentage, 90.9);
      expect(session.isCompleted, isFalse);

      final completedSession = session.copyWith(status: 'COMPLETED');
      expect(completedSession.isCompleted, isTrue);

      final map = session.toMap();
      expect(map['audit_no'], 'AUD-2026-001');
      expect(map['compliance_percentage'], 90.9);

      final fromMapSession = AuditSession.fromMap(map);
      expect(fromMapSession.auditNo, session.auditNo);
      expect(fromMapSession.compliancePercentage, session.compliancePercentage);
    });

    test('AuditChecklistItem correctly reports compliance flags', () {
      const conformItem = AuditChecklistItem(
        id: 10,
        auditSessionId: 1,
        categoryCode: 'POLICY',
        categoryTitle: '๑. นโยบายด้านความปลอดภัยฯ',
        clauseNo: 'ข้อ ๖(๑)',
        itemTitle: 'การมีส่วนร่วมของลูกจ้างในการกำหนดนโยบาย',
        requirementDescription: 'จัดให้ลูกจ้างมีส่วนร่วมกำหนดนโยบาย',
        legalReference: 'กฎกระทรวงระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕ ข้อ ๖(๑)',
        resultStatus: 'CONFORM',
      );

      expect(conformItem.isConform, isTrue);
      expect(conformItem.isNc, isFalse);
      expect(conformItem.isMinorNc, isFalse);
      expect(conformItem.isMajorNc, isFalse);
      expect(conformItem.isNa, isFalse);

      final minorNcItem = conformItem.copyWith(resultStatus: 'MINOR_NC');
      expect(minorNcItem.isMinorNc, isTrue);
      expect(minorNcItem.isNc, isTrue);

      final majorNcItem = conformItem.copyWith(resultStatus: 'MAJOR_NC');
      expect(majorNcItem.isMajorNc, isTrue);
      expect(majorNcItem.isNc, isTrue);

      final naItem = conformItem.copyWith(resultStatus: 'NA');
      expect(naItem.isNa, isTrue);
      expect(naItem.isNc, isFalse);
    });

    test('AuditFindingCapa verifies SLA and overdue logic', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final pastDateStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';

      final overdueCapa = AuditFindingCapa(
        id: 1,
        auditSessionId: 1,
        findingNo: 'CAR-2026-001',
        findingType: 'MAJOR_NC',
        clauseRef: 'ม.๑๒ ไฟฟ้า',
        problemDescription: 'ไม่มีรายงานการตรวจรับรองระบบไฟฟ้าประจำปี แบบ ๕๖๒๘๙',
        correctiveAction: 'ว่าจ้างวิศวกรไฟฟ้าเข้าดำเนินการตรวจสอบและออกใบรับรอง',
        responsiblePerson: 'ผู้จัดการฝ่ายวิศวกรรม',
        dueDate: pastDateStr,
        status: 'OPEN',
      );

      expect(overdueCapa.isOverdue, isTrue);
      expect(overdueCapa.isClosed, isFalse);

      final closedCapa = overdueCapa.copyWith(status: 'CLOSED');
      expect(closedCapa.isClosed, isTrue);
      expect(closedCapa.isOverdue, isFalse); // Closed items are not considered overdue
    });
  });

  group('Statutory SMS 2565 Master Data Tests', () {
    test('Contains exactly 54 statutory business types in schedule', () {
      expect(AuditMasterChecklistData.statutory54Industries.length, 54);
      expect(AuditMasterChecklistData.statutory54Industries.first, contains('เหมือง'));
      expect(AuditMasterChecklistData.statutory54Industries.last, contains('สวนสัตว์หรือสวนสนุก'));
    });

    test('Master checklist covers 5 core statutory pillars and cross-module checkpoints', () {
      final templates = AuditMasterChecklistData.masterTemplates;
      expect(templates.length, greaterThanOrEqualTo(20));

      final policyItems = templates.where((t) => t.categoryCode == 'POLICY').toList();
      final orgItems = templates.where((t) => t.categoryCode == 'ORGANIZATION').toList();
      final planItems = templates.where((t) => t.categoryCode == 'PLANNING').toList();
      final evalItems = templates.where((t) => t.categoryCode == 'EVALUATION').toList();
      final impItems = templates.where((t) => t.categoryCode == 'IMPROVEMENT').toList();
      final hazardItems = templates.where((t) => t.categoryCode == 'SPECIFIC_HAZARD').toList();

      expect(policyItems, isNotEmpty);
      expect(orgItems, isNotEmpty);
      expect(planItems, isNotEmpty);
      expect(evalItems, isNotEmpty);
      expect(impItems, isNotEmpty);
      expect(hazardItems, isNotEmpty);

      // Verify specific statutory clauses
      expect(policyItems.any((i) => i.legalReference.contains('ข้อ ๖(๑)')), isTrue);
      expect(orgItems.any((i) => i.legalReference.contains('ข้อ ๘(๓)')), isTrue);
      expect(evalItems.any((i) => i.legalReference.contains('ข้อ ๑๐(๑)')), isTrue);
      expect(impItems.any((i) => i.legalReference.contains('ข้อ ๑๑')), isTrue);
    });

    test('Dynamic Factory Scope correctly includes or excludes hazard checkpoints', () {
      const fullScope = FactoryScopeModel(
        hasBoiler: true,
        hasCrane: true,
        hasChemical: true,
        hasConfinedSpace: true,
        hasWorkingAtHeight: true,
        hasElectricalLoto: true,
        hasEmergencyFire: true,
        hasPpe: true,
      );

      const minimalScope = FactoryScopeModel(
        hasBoiler: false,
        hasCrane: false,
        hasChemical: false,
        hasConfinedSpace: false,
        hasWorkingAtHeight: false,
        hasElectricalLoto: true,
        hasEmergencyFire: true,
        hasPpe: true,
      );

      final allTemplates = AuditMasterChecklistData.masterTemplates;

      // In full scope, boiler and crane are included
      final boilerCraneFull = allTemplates.where((t) {
        if (t.scopeFlag == 'BOILER') return fullScope.hasBoiler;
        if (t.scopeFlag == 'CRANE') return fullScope.hasCrane;
        return false;
      }).toList();
      expect(boilerCraneFull.length, 2);

      // In minimal scope, boiler and crane are suppressed
      final boilerCraneMinimal = allTemplates.where((t) {
        if (t.scopeFlag == 'BOILER') return minimalScope.hasBoiler;
        if (t.scopeFlag == 'CRANE') return minimalScope.hasCrane;
        return false;
      }).toList();
      expect(boilerCraneMinimal.isEmpty, isTrue);
    });
  });
}
