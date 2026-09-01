import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_session_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_kpi_summary.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/data/environmental_gazette_data.dart';
import 'package:safety_superapp/features/environment/presentation/providers/environment_providers.dart';
import 'package:safety_superapp/features/environment/presentation/pages/environment_page.dart';
import 'package:safety_superapp/features/environment/presentation/tabs/environment_dashboard_tab.dart';
import 'package:safety_superapp/features/environment/presentation/tabs/environment_points_tab.dart';
import 'package:safety_superapp/features/environment/presentation/tabs/environment_capa_tab.dart';
import 'package:safety_superapp/features/environment/presentation/tabs/environment_gazette_tab.dart';
import 'package:safety_superapp/features/environment/presentation/widgets/add_edit_session_dialog.dart';
import 'package:safety_superapp/features/environment/presentation/widgets/add_edit_point_dialog.dart';
import 'package:safety_superapp/features/environment/presentation/widgets/add_edit_capa_dialog.dart';
import 'package:safety_superapp/features/environment/presentation/widgets/attachment_preview_dialog.dart';
import 'package:safety_superapp/features/environment/presentation/widgets/gazette_detail_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSession = const EnvironmentSessionModel(
    id: 1,
    sessionId: 'ENV-SESS-2026-001',
    sessionTitle: 'ตรวจวัดสภาพแวดล้อมประจำปี 2569',
    sessionYearBe: 2569,
    sessionYearAd: 2026,
    measurementDate: '2026-09-01',
    reportReceivedDate: '2026-09-05',
    postingDeadline: '2026-09-16',
    submissionDeadline: '2026-10-01',
    locationPlant: 'โรงงานหลัก 1',
    workplaceName: 'บริษัท โรงงานตัวอย่าง จำกัด (มหาชน)',
    workplaceAddress: '123/45 นิคมอุตสาหกรรม จ.ปทุมธานี',
    objective: 'ตรวจวัดตามกฎหมายความปลอดภัยประจำปี',
    subcontractorType: SubcontractorType.section11Juristic,
    subcontractorCompanyName: 'บริษัท สิ่งแวดล้อมปลอดภัยตรวจวัด จำกัด',
    subcontractorRegNumber: 'บ. 0045-12/2565',
    surveyorName: 'นายตรวจวัด ชำนาญการ',
    surveyorLicenseNo: 'ENV-TECH-001',
    certifierName: 'นายวิศวกร สิ่งแวดล้อม',
    certifierRegNo: 'บ. 0045-12/2565',
    pdfReportPath: '/dummy/report.pdf',
    calibrationCertPaths: ['/dummy/cal1.pdf'],
    subcontractorLicensePath: '/dummy/license.pdf',
    sitePhotoPaths: ['/dummy/photo1.jpg'],
    status: EnvironmentSessionStatus.measured,
  );

  final sampleLightPoint = const EnvironmentPointModel(
    id: 1,
    pointId: 'PT-ENV-LIGHT-001',
    sessionId: 'ENV-SESS-2026-001',
    factorType: EnvironmentFactorType.light,
    department: 'ฝ่ายผลิต',
    locationName: 'โต๊ะประกอบ 1',
    taskOrMachineName: 'งานประกอบทั่วไป',
    evaluationStatus: EnvironmentEvaluationStatus.pass,
    lightCategoryCode: 'LIGHT-CAT2-04',
    lightTaskDescription: 'งานประกอบชิ้นส่วน',
    lightMeasuredLux: 350.0,
    lightStandardMinLux: 300.0,
    lightSurroundingLux: 200.0,
    lightIsCompliant: true,
  );

  final sampleNoisePoint = const EnvironmentPointModel(
    id: 2,
    pointId: 'PT-ENV-NOISE-001',
    sessionId: 'ENV-SESS-2026-001',
    factorType: EnvironmentFactorType.noise,
    department: 'ฝ่ายผลิต',
    locationName: 'เครื่องปั๊มโลหะ 1',
    taskOrMachineName: 'ปั๊มขึ้นรูปชิ้นงาน',
    evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
    noiseMeasurementType: NoiseMeasurementType.leq8hrTwa,
    noiseMeasuredDba: 85.5,
    noiseStandardTwaLimit: 86.0,
    noiseActionLevelThreshold: 85.0,
    noiseIsHcpRequired: true,
  );

  final sampleHeatPoint = const EnvironmentPointModel(
    id: 3,
    pointId: 'PT-ENV-HEAT-001',
    sessionId: 'ENV-SESS-2026-001',
    factorType: EnvironmentFactorType.heat,
    department: 'ฝ่ายหลอมโลหะ',
    locationName: 'หน้าเตาหลอม',
    taskOrMachineName: 'เตาหลอมความร้อนสูง',
    evaluationStatus: EnvironmentEvaluationStatus.fail,
    heatSolarExposure: HeatSolarExposure.indoorNoSolar,
    heatNwbCelsius: 31.0,
    heatGtCelsius: 40.0,
    heatDbCelsius: 38.0,
    heatCalculatedWbgt: 33.7,
    heatWorkloadType: WorkloadLevel.heavy,
    heatStandardLimitWbgt: 30.0,
    heatIsCompliant: false,
  );

  final sampleCapa = const EnvironmentCapaModel(
    id: 1,
    capaId: 'CAPA-ENV-2026-001',
    pointId: 'PT-ENV-NOISE-001',
    sessionId: 'ENV-SESS-2026-001',
    factorType: EnvironmentFactorType.noise,
    actionTitle: 'ขึ้นทะเบียนโครงการอนุรักษ์การได้ยินและปรับปรุงเสียง',
    hazardDescription: 'ระดับเสียง 85.5 dBA อยู่ในระดับเฝ้าระวัง Action Level',
    rootCause: 'เสียงจากการทำงานของเครื่องปั๊มโลหะ',
    engineeringControl: 'ติดตั้งแผ่นซับเสียงรอบตัวเครื่อง',
    administrativeControl: 'อบรมโครงการอนุรักษ์การได้ยินและตรวจสมรรถภาพการได้ยิน',
    ppeControl: 'บังคับสวมใส่ที่อุดหู Earplugs NRR 25',
    picName: 'น.ส.ดาราวรรณ จป.วิชาชีพ',
    picDepartment: 'ฝ่ายความปลอดภัย',
    targetDate: '2026-09-30',
    status: 'IN_PROGRESS',
    hearingProgramEnrolled: true,
  );

  final sampleKpi = EnvironmentKpiSummary.calculate(
    points: [sampleLightPoint, sampleNoisePoint, sampleHeatPoint],
    capas: [sampleCapa],
  );

  group('1. EnvironmentDashboardTab Widget Tests', () {
    testWidgets('Renders KPI metrics, progress bars, session cards and attachments', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envKpiSummaryProvider.overrideWith((ref) async => sampleKpi),
            envSessionListProvider.overrideWith(() => _MockSessionListNotifier([sampleSession])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnvironmentDashboardTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ดัชนีสรุปผลการตรวจวัดสภาพแวดล้อม'), findsOneWidget);
      expect(find.text('33.3%'), findsOneWidget); // 1 passed out of 3
      expect(find.text('ผ่านเกณฑ์มาตรฐาน'), findsWidgets);
      expect(find.text('เฝ้าระวัง Action Level'), findsWidgets);
      expect(find.text('เกินเกณฑ์มาตรฐาน'), findsWidgets);
      expect(find.text('แสงสว่าง (Lighting)'), findsWidgets);
      expect(find.text('เสียง (Noise)'), findsWidgets);
      expect(find.text('ความร้อน (Heat WBGT)'), findsWidgets);
      expect(find.textContaining('ENV-SESS-2026-001'), findsWidgets);
      expect(find.textContaining('การรับรองผู้ให้บริการตรวจวัด'), findsOneWidget);
      expect(find.textContaining('กำหนดเวลาตามกฎหมาย (Section 15)'), findsOneWidget);
      expect(find.textContaining('เอกสารอ้างอิงและหลักฐานประกอบการตรวจวัด'), findsOneWidget);
    });
  });

  group('2. EnvironmentPointsTab Widget Tests', () {
    testWidgets('Renders points filter bar, status chips and measurement point cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envPointListProvider.overrideWith(
              () => _MockPointListNotifier([sampleLightPoint, sampleNoisePoint, sampleHeatPoint]),
            ),
            envSessionListProvider.overrideWith(() => _MockSessionListNotifier([sampleSession])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnvironmentPointsTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('เพิ่มจุดตรวจวัดใหม่'), findsOneWidget);
      expect(find.text('ทั้งหมด'), findsWidgets);
      expect(find.text('แสงสว่าง (Light)'), findsWidgets);
      expect(find.text('เสียง (Noise)'), findsWidgets);
      expect(find.text('ความร้อน (Heat)'), findsWidgets);

      // Points cards
      expect(find.text('PT-ENV-LIGHT-001'), findsOneWidget);
      expect(find.text('PT-ENV-NOISE-001'), findsOneWidget);
      expect(find.text('PT-ENV-HEAT-001'), findsOneWidget);

      expect(find.text('ผ่านเกณฑ์มาตรฐาน'), findsOneWidget);
      expect(find.textContaining('เฝ้าระวัง'), findsWidgets);
      expect(find.textContaining('เกินเกณฑ์'), findsWidgets);
    });
  });

  group('3. EnvironmentCapaTab Widget Tests', () {
    testWidgets('Renders HCP enrollment banner, CAPA cards and hierarchy of controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envPointListProvider.overrideWith(
              () => _MockPointListNotifier([sampleNoisePoint]),
            ),
            envCapaListProvider.overrideWith(
              () => _MockCapaListNotifier([sampleCapa]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnvironmentCapaTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('โครงการอนุรักษ์การได้ยิน (Hearing Conservation Program - HCP)'), findsOneWidget);
      expect(find.textContaining('PT-ENV-NOISE-001'), findsWidgets);
      expect(find.text('CAPA-ENV-2026-001'), findsOneWidget);
      expect(find.textContaining('ลำดับขั้นความปลอดภัย'), findsOneWidget);
      expect(find.text('เปิดแผน CAPA ใหม่'), findsOneWidget);
      expect(find.text('ปิดงาน CAPA'), findsOneWidget);
    });
  });

  group('4. EnvironmentGazetteTab Widget Tests', () {
    testWidgets('Renders Royal Gazette repository, category chips and law cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnvironmentGazetteTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('คลังกฎหมายสิ่งแวดล้อมราชกิจจานุเบกษา'), findsOneWidget);
      expect(find.text('LAW-OSH-2554'), findsOneWidget);
      expect(find.text('LAW-ENV-REG-2559'), findsOneWidget);
      expect(find.text('LAW-LIGHT-NOTIF-2561'), findsOneWidget);
      expect(find.text('LAW-NOISE-NOTIF-2561'), findsOneWidget);
      expect(find.text('LAW-HEAT-NOTIF-2563'), findsOneWidget);
      expect(find.text('LAW-REPORT-NOTIF-2563'), findsOneWidget);
      expect(find.textContaining('เปิดอ่านฉบับเต็ม / รายละเอียด'), findsWidgets);
    });
  });

  group('5. Dialogs Widget Tests', () {
    testWidgets('AddEditSessionDialog renders fields and handles save', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEditSessionDialog(
                session: sampleSession,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('แก้ไขรอบการตรวจวัด'), findsOneWidget);
      expect(find.text('ENV-SESS-2026-001'), findsOneWidget);
      expect(find.text('บันทึกการแก้ไข'), findsOneWidget);
    });

    testWidgets('AddEditPointDialog renders with live auto-evaluation for Light, Noise and Heat', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envSessionListProvider.overrideWith(() => _MockSessionListNotifier([sampleSession])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AddEditPointDialog(
                point: sampleLightPoint,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ประเมินผลอัตโนมัติตามกฎหมาย'), findsOneWidget);
      expect(find.text('PT-ENV-LIGHT-001'), findsOneWidget);
      expect(find.text('บันทึกการแก้ไข'), findsOneWidget);
    });

    testWidgets('AddEditCapaDialog renders hierarchy of controls form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddEditCapaDialog(
                capaItem: sampleCapa,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('แก้ไขแผนงาน CAPA'), findsOneWidget);
      expect(find.text('CAPA-ENV-2026-001'), findsOneWidget);
      expect(find.textContaining('ลำดับขั้นการควบคุมความปลอดภัย'), findsOneWidget);
      expect(find.text('บันทึกการแก้ไข'), findsOneWidget);
    });

    testWidgets('AttachmentPreviewDialog renders file preview modal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttachmentPreviewDialog(
              title: 'เล่มรายงานผลการตรวจวัดฉบับเต็ม',
              filePath: '/dummy/report.pdf',
              category: 'เล่มรายงานผล',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('เล่มรายงานผลการตรวจวัดฉบับเต็ม'), findsOneWidget);
      expect(find.text('ปิดหน้าต่าง'), findsOneWidget);
    });

    testWidgets('GazetteDetailDialog renders statutory metadata and key articles', (tester) async {
      final gazetteItem = EnvironmentalGazetteData.gazetteList.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GazetteDetailDialog(item: gazetteItem),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(gazetteItem.lawId), findsOneWidget);
      expect(find.textContaining('สรุปสาระสำคัญตามกฎหมาย'), findsOneWidget);
      expect(find.textContaining('ข้อกำหนดและมาตราสำคัญ'), findsOneWidget);
      expect(find.text('ปิดหน้าต่าง'), findsOneWidget);
    });
  });

  group('6. EnvironmentPage 4-Tab Main Screen Tests', () {
    testWidgets('Renders EnvironmentPage with 4 tabs and navigates correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envKpiSummaryProvider.overrideWith((ref) async => sampleKpi),
            envSessionListProvider.overrideWith(() => _MockSessionListNotifier([sampleSession])),
            envPointListProvider.overrideWith(
              () => _MockPointListNotifier([sampleLightPoint, sampleNoisePoint, sampleHeatPoint]),
            ),
            envCapaListProvider.overrideWith(
              () => _MockCapaListNotifier([sampleCapa]),
            ),
          ],
          child: const MaterialApp(
            home: EnvironmentPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 0 active: Dashboard
      expect(find.textContaining('ระบบตรวจวัดสภาพแวดล้อมในการทำงาน'), findsOneWidget);
      expect(find.text('ส่งออก PDF (สสค.)'), findsOneWidget);
      expect(find.text('ส่งออก Excel'), findsOneWidget);
      expect(find.textContaining('ดัชนีสรุปผลการตรวจวัดสภาพแวดล้อม'), findsOneWidget);

      // Tap Tab 1: Measurements Points
      await tester.tap(find.textContaining('ผลตรวจวัดรายจุด'));
      await tester.pumpAndSettle();
      expect(find.text('PT-ENV-LIGHT-001'), findsOneWidget);

      // Tap Tab 2: CAPA & HCP
      await tester.tap(find.textContaining('แผน CAPA & อนุรักษ์การได้ยิน'));
      await tester.pumpAndSettle();
      expect(find.text('CAPA-ENV-2026-001'), findsOneWidget);

      // Tap Tab 3: Gazette
      await tester.tap(find.textContaining('คลังกฎหมายราชกิจจานุเบกษา'));
      await tester.pumpAndSettle();
      expect(find.textContaining('คลังกฎหมายสิ่งแวดล้อมราชกิจจานุเบกษา'), findsOneWidget);
    });
  });
}

class _MockSessionListNotifier extends AsyncNotifier<List<EnvironmentSessionModel>>
    implements EnvironmentSessionListNotifier {
  final List<EnvironmentSessionModel> _initial;
  _MockSessionListNotifier(this._initial);

  @override
  Future<List<EnvironmentSessionModel>> build() async => _initial;

  @override
  Future<void> saveSession(EnvironmentSessionModel session) async {}

  @override
  Future<void> deleteSession(String sessionId) async {}
}

class _MockPointListNotifier extends AsyncNotifier<List<EnvironmentPointModel>>
    implements EnvironmentPointListNotifier {
  final List<EnvironmentPointModel> _initial;
  _MockPointListNotifier(this._initial);

  @override
  Future<List<EnvironmentPointModel>> build() async => _initial;

  @override
  Future<void> savePoint(EnvironmentPointModel point) async {}

  @override
  Future<void> saveBatchPoints(List<EnvironmentPointModel> points) async {}

  @override
  Future<void> deletePoint(String pointId) async {}
}

class _MockCapaListNotifier extends AsyncNotifier<List<EnvironmentCapaModel>>
    implements EnvironmentCapaListNotifier {
  final List<EnvironmentCapaModel> _initial;
  _MockCapaListNotifier(this._initial);

  @override
  Future<List<EnvironmentCapaModel>> build() async => _initial;

  @override
  Future<void> saveCapa(EnvironmentCapaModel capa) async {}

  @override
  Future<void> deleteCapa(String capaId) async {}
}
