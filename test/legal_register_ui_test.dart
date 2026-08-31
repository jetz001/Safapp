import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_master_item_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_assessment_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_capa_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_stats_model.dart';
import 'package:safety_superapp/features/legal_register/data/safety_legal_8_categories_data.dart';
import 'package:safety_superapp/features/legal_register/presentation/providers/legal_register_providers.dart';
import 'package:safety_superapp/features/legal_register/presentation/pages/legal_page.dart';
import 'package:safety_superapp/features/legal_register/presentation/widgets/legal_kpi_dashboard.dart';
import 'package:safety_superapp/features/legal_register/presentation/widgets/legal_filter_bar.dart';
import 'package:safety_superapp/features/legal_register/presentation/widgets/legal_assessment_dialog.dart';
import 'package:safety_superapp/features/legal_register/presentation/widgets/legal_capa_dialog.dart';
import 'package:safety_superapp/features/legal_register/presentation/widgets/legal_gazette_viewer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleMaster = SafetyLegal8CategoriesData.masterItems.first;
  final sampleAssessment = LegalComplianceAssessmentModel(
    id: 1,
    masterItemId: 'ITEM-OSH-001',
    requirementCode: 'ITEM-OSH-001',
    requirementTitle: 'การจัดทำนโยบายและระบบบริหารจัดการความปลอดภัย',
    requirementDetails: 'นายจ้างมีหน้าที่จัดและดูแลสถานประกอบกิจการให้ปลอดภัย',
    category: 'OSH_ACT',
    lawId: 'LAW-OSH-2554',
    lawTitleTh: 'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔',
    articleNo: 'มาตรา ๖ และ ๘',
    isApplicable: true,
    complianceStatus: 'COMPLIANT',
    actualPractice: 'มีนโยบายความปลอดภัยลงนามโดย MD แล้ว',
    evaluatedDate: '2026-08-31',
    evaluatorName: 'จป.วิชาชีพ ทดสอบ',
    riskLevel: 'HIGH',
    evidenceFilePaths: const ['/dummy/policy.pdf'],
  );

  final sampleCapa = LegalCapaModel(
    id: 1,
    assessmentId: 1,
    actionTitle: 'จัดทำฝาครอบการ์ดป้องกันสายพาน',
    rootCause: 'ไม่มีการ์ดมาตรฐานตั้งแต่ติดตั้งเครื่องจักร',
    correctiveAction: 'ติดตั้งการ์ดป้องกันทันที',
    preventiveAction: 'เพิ่มเช็กลิสต์ตรวจประจำสัปดาห์',
    picName: 'นายสมศักดิ์ ช่างซ่อม',
    picDepartment: 'ฝ่ายซ่อมบำรุง',
    targetDate: '2026-09-30',
    status: 'IN_PROGRESS',
    requirementCode: 'ITEM-OSH-001',
    requirementTitle: 'การจัดทำนโยบายและระบบบริหารจัดการความปลอดภัย',
  );

  group('1. LegalKpiDashboard Widget Tests', () {
    testWidgets('Renders KPI metrics, basic CI and risk-weighted WCI', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            legalComplianceKpiProvider.overrideWith(
              (ref) async => LegalComplianceStatsModel(
                totalItems: 32,
                applicableItems: 30,
                compliantCount: 25,
                nonCompliantCount: 3,
                inProgressCount: 2,
                notApplicableCount: 2,
                basicCompliancePercent: 83.3,
                riskWeightedCompliancePercent: 85.0,
                highRiskNonCompliantCount: 1,
                totalCapaCount: 5,
                pendingCapaCount: 2,
                inProgressCapaCount: 2,
                completedCapaCount: 1,
                overdueCapaCount: 1,
                categoryBreakdown: const [],
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LegalKpiDashboard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ดัชนีชี้วัดความสอดคล้องทางกฎหมาย'), findsOneWidget);
      expect(find.textContaining('83%'), findsOneWidget);
      expect(find.textContaining('85%'), findsOneWidget);
      expect(find.textContaining('สอดคล้อง (Compliant)'), findsOneWidget);
      expect(find.textContaining('ไม่สอดคล้อง (Non-Compliant)'), findsOneWidget);
      expect(find.textContaining('แจ้งเตือนสำคัญ'), findsOneWidget);
    });
  });

  group('2. LegalFilterBar Widget Tests', () {
    testWidgets('Renders search field, status dropdown and category chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LegalFilterBar(activeTab: 0),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('ทั้งหมด (All 8 Laws)'), findsOneWidget);
    });
  });

  group('3. LegalAssessmentDialog Widget Tests', () {
    testWidgets('Renders assessment fields, status selector and save button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LegalAssessmentDialog(
                assessment: sampleAssessment,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ITEM-OSH-001'), findsOneWidget);
      expect(find.textContaining('การจัดทำนโยบาย'), findsWidgets);
      expect(find.text('บันทึกผลการประเมิน'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('4. LegalCapaDialog Widget Tests', () {
    testWidgets('Renders CAPA form fields, root cause, PIC, and status choices', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LegalCapaDialog(
                capaItem: sampleCapa,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('แก้ไขแผนการปรับปรุงแก้ไข'), findsOneWidget);
      expect(find.text('จัดทำฝาครอบการ์ดป้องกันสายพาน'), findsOneWidget);
      expect(find.text('นายสมศักดิ์ ช่างซ่อม'), findsOneWidget);
      expect(find.text('บันทึกแผนงาน CAPA'), findsOneWidget);
    });
  });

  group('5. LegalGazetteViewerDialog Widget Tests', () {
    testWidgets('Renders gazette citations, article details, and 2 tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LegalGazetteViewerDialog(
                masterItem: sampleMaster,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(sampleMaster.itemId), findsOneWidget);
      expect(find.text('รายละเอียดข้อกฎหมาย & เกณฑ์ปฏิบัติ'), findsOneWidget);
      expect(find.text('ฉบับประกาศราชกิจจานุเบกษา'), findsOneWidget);
      expect(find.text('ประเมินความสอดคล้องข้อนี้'), findsOneWidget);
    });
  });

  group('6. LegalPage 3-Tab Main Screen Tests', () {
    testWidgets('Renders LegalPage with 3 tabs and switches tabs correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            legalAssessmentListProvider.overrideWith(
              () => _MockAssessmentNotifier([sampleAssessment]),
            ),
            legalMasterListProvider.overrideWith(
              () => _MockMasterNotifier([sampleMaster]),
            ),
            legalCapaListProvider.overrideWith(
              () => _MockCapaNotifier([sampleCapa]),
            ),
            legalComplianceKpiProvider.overrideWith(
              (ref) async => LegalComplianceStatsModel(
                totalItems: 32,
                applicableItems: 30,
                compliantCount: 25,
                nonCompliantCount: 3,
                inProgressCount: 2,
                notApplicableCount: 2,
                basicCompliancePercent: 83.3,
                riskWeightedCompliancePercent: 85.0,
                highRiskNonCompliantCount: 1,
                totalCapaCount: 1,
                pendingCapaCount: 0,
                inProgressCapaCount: 1,
                completedCapaCount: 0,
                overdueCapaCount: 0,
                categoryBreakdown: const [],
              ),
            ),
          ],
          child: const MaterialApp(
            home: LegalPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 1 active
      expect(find.textContaining('ทะเบียนและการประเมินความสอดคล้อง'), findsWidgets);
      expect(find.text('ITEM-OSH-001'), findsOneWidget);

      // Tap Tab 2
      await tester.tap(find.textContaining('คลังกฎหมายราชกิจจานุเบกษา'));
      await tester.pumpAndSettle();
      expect(find.textContaining('คลังกฎหมายความปลอดภัยราชกิจจานุเบกษา ๘ ฉบับหลัก'), findsOneWidget);

      // Tap Tab 3
      await tester.tap(find.textContaining('แผนการปรับปรุงแก้ไข (CAPA Plan)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ระบบติดตามแผนงานแก้ไขและป้องกัน'), findsOneWidget);
      expect(find.text('จัดทำฝาครอบการ์ดป้องกันสายพาน'), findsOneWidget);
      expect(find.text('เปิดแผนงาน CAPA ใหม่'), findsOneWidget);
    });
  });
}

class _MockAssessmentNotifier extends AsyncNotifier<List<LegalComplianceAssessmentModel>>
    implements LegalAssessmentListNotifier {
  final List<LegalComplianceAssessmentModel> _initial;
  _MockAssessmentNotifier(this._initial);

  @override
  Future<List<LegalComplianceAssessmentModel>> build() async => _initial;

  @override
  Future<int> saveAssessment(LegalComplianceAssessmentModel item, {List<String>? newEvidencePaths}) async => 1;

  @override
  Future<int> deleteAssessment(int id) async => 1;

  @override
  Future<void> resetDefaultAssessments() async {}
}

class _MockMasterNotifier extends AsyncNotifier<List<LegalMasterItemModel>>
    implements LegalMasterListNotifier {
  final List<LegalMasterItemModel> _initial;
  _MockMasterNotifier(this._initial);

  @override
  Future<List<LegalMasterItemModel>> build() async => _initial;
}

class _MockCapaNotifier extends AsyncNotifier<List<LegalCapaModel>>
    implements LegalCapaListNotifier {
  final List<LegalCapaModel> _initial;
  _MockCapaNotifier(this._initial);

  @override
  Future<List<LegalCapaModel>> build() async => _initial;

  @override
  Future<int> saveCapa(LegalCapaModel item, {String? newEvidencePath, bool updateParentAssessmentStatus = true}) async => 1;

  @override
  Future<int> deleteCapa(int id) async => 1;

  @override
  Future<int> closeCapa(int id, {String? completedDate, String? notes}) async => 1;
}
