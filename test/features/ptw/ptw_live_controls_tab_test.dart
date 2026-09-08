import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/presentation/notifiers/ptw_list_notifier.dart';
import 'package:safety_superapp/features/ptw/presentation/tabs/ptw_live_controls_tab.dart';

class FakePtwListNotifier extends PtwListNotifier {
  final List<PtwModel> mockData;
  FakePtwListNotifier(this.mockData);

  @override
  Future<List<PtwModel>> build() async => mockData;
}

PtwModel createSample({
  required String ptwNumber,
  required PtwStatus status,
  required HighRiskType riskType,
}) {
  return PtwModel(
    ptwNumber: ptwNumber,
    workTitle: 'Test work ',
    workDescription: 'Description',
    primaryRiskType: riskType,
    status: status,
    plantArea: 'Plant 1',
    specificLocation: 'Area A',
    requestDate: '2026-09-07',
    workStartDate: '2026-09-07',
    workStartTime: '08:00',
    workEndDate: '2026-09-07',
    workEndTime: '17:00',
    applicantName: 'Somchai',
    applicantDepartment: 'Safety',
    applicantPhone: '0812345678',
    emergencyRescuePlan: 'Plan 1',
    requiredPpeList: 'Helmet',
  );
}

void main() {
  testWidgets('PtwLiveControlsTab renders empty state safely when permits list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ptwListProvider.overrideWith(() => FakePtwListNotifier([])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PtwLiveControlsTab()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(PtwLiveControlsTab), findsOneWidget);
    expect(find.text('ไม่มีใบอนุญาตทำงานที่กำลังปฏิบัติงาน'), findsOneWidget);
  });

  testWidgets('PtwLiveControlsTab renders safely when no active permits exist', (tester) async {
    final draftPermit = createSample(
      ptwNumber: 'PTW-2026-001',
      status: PtwStatus.draft,
      riskType: HighRiskType.hotWork,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ptwListProvider.overrideWith(() => FakePtwListNotifier([draftPermit])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PtwLiveControlsTab()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(PtwLiveControlsTab), findsOneWidget);
    expect(find.text('ไม่มีใบอนุญาตทำงานที่กำลังปฏิบัติงาน'), findsOneWidget);
  });

  testWidgets('PtwLiveControlsTab renders safely and selects single active permit', (tester) async {
    final activePermit = createSample(
      ptwNumber: 'PTW-2026-002',
      status: PtwStatus.active,
      riskType: HighRiskType.confinedSpace,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ptwListProvider.overrideWith(() => FakePtwListNotifier([activePermit])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PtwLiveControlsTab()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(PtwLiveControlsTab), findsOneWidget);
    expect(find.text('PTW-2026-002'), findsAtLeastNWidgets(1));
  });
}
