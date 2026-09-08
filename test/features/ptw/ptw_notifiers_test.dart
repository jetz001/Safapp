import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/ptw/domain/enums/energy_type.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/data/models/gas_test_log_model.dart';
import 'package:safety_superapp/features/ptw/data/models/fire_watch_model.dart';
import 'package:safety_superapp/features/ptw/data/models/loto_isolation_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_checklist_model.dart';
import 'package:safety_superapp/features/ptw/data/repositories/ptw_repository.dart';
import 'package:safety_superapp/features/ptw/presentation/notifiers/ptw_filter_notifier.dart';
import 'package:safety_superapp/features/ptw/presentation/notifiers/ptw_list_notifier.dart';
import 'package:safety_superapp/features/ptw/presentation/notifiers/ptw_detail_notifier.dart';
import 'package:safety_superapp/features/ptw/presentation/notifiers/ptw_live_controls_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PtwFilterNotifier Tests', () {
    test('Initial filter state is empty and not filtered', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(ptwFilterProvider);
      expect(filter.searchQuery, isEmpty);
      expect(filter.riskType, isNull);
      expect(filter.status, isNull);
      expect(filter.department, isNull);
      expect(filter.isFiltered, isFalse);
    });

    test('Updating search query, risk type, and status updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ptwFilterProvider.notifier);

      notifier.setSearchQuery('Silo');
      expect(container.read(ptwFilterProvider).searchQuery, 'Silo');
      expect(container.read(ptwFilterProvider).isFiltered, isTrue);

      notifier.setRiskType(HighRiskType.confinedSpace);
      expect(container.read(ptwFilterProvider).riskType, HighRiskType.confinedSpace);

      notifier.setStatus(PtwStatus.active);
      expect(container.read(ptwFilterProvider).status, PtwStatus.active);

      notifier.setDepartment('Engineering');
      expect(container.read(ptwFilterProvider).department, 'Engineering');

      notifier.setDateRange('2026-09-01', '2026-09-30');
      expect(container.read(ptwFilterProvider).startDate, '2026-09-01');
      expect(container.read(ptwFilterProvider).endDate, '2026-09-30');

      notifier.reset();
      expect(container.read(ptwFilterProvider).isFiltered, isFalse);
      expect(container.read(ptwFilterProvider).searchQuery, isEmpty);
      expect(container.read(ptwFilterProvider).riskType, isNull);
    });
  });

  group('GasTrackerNotifier Tests', () {
    test('Initial state is normal atmosphere (20.9% O2, 0 LEL/CO/H2S)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(gasTrackerProvider);
      expect(state.currentOxygen, 20.9);
      expect(state.currentLel, 0.0);
      expect(state.currentCo, 0.0);
      expect(state.currentH2s, 0.0);
      expect(state.isCurrentAtmosphereSafe, isTrue);
      expect(state.activeErrors, isEmpty);
    });

    test('Setting unsafe gas values triggers alert state and active errors', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(gasTrackerProvider.notifier);

      // Low O2
      notifier.setOxygen(18.0);
      var state = container.read(gasTrackerProvider);
      expect(state.isCurrentAtmosphereSafe, isFalse);
      expect(state.activeErrors.first.contains('ออกซิเจนต่ำกว่าเกณฑ์'), isTrue);

      // Reset O2, high LEL
      notifier.setOxygen(20.9);
      notifier.setLel(12.0);
      state = container.read(gasTrackerProvider);
      expect(state.isCurrentAtmosphereSafe, isFalse);
      expect(state.activeErrors.first.contains('ก๊าซหรือไอระเหยไวไฟเกินเกณฑ์'), isTrue);

      // Warning level LEL (5.0 - 9.9%)
      notifier.setLel(6.0);
      state = container.read(gasTrackerProvider);
      expect(state.isCurrentAtmosphereSafe, isTrue);
      expect(state.activeWarnings.first.contains('เฝ้าระวัง'), isTrue);
    });

    test('Recording gas reading creates GasTestLogModel in memory', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(gasTrackerProvider.notifier);
      notifier.initForPermit('PTW-TEST-001', []);
      notifier.setOxygen(20.9);
      notifier.setTesterInfo(testerName: 'Jane Safety', detectorModel: 'Dräger X-am 5000');

      final log = await notifier.recordReading();
      expect(log.ptwNumber, 'PTW-TEST-001');
      expect(log.oxygenPercent, 20.9);
      expect(log.testerName, 'Jane Safety');
      expect(log.isSafe, isTrue);
      expect(container.read(gasTrackerProvider).logs.length, 1);
    });
  });

  group('FireWatchTimerNotifier Tests', () {
    test('Initialization sets default 30-minute duration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fireWatchTimerProvider.notifier);
      notifier.initForPermit('PTW-TEST-001', durationMinutes: 30, watcherName: 'Wichai');

      final state = container.read(fireWatchTimerProvider);
      expect(state.ptwNumber, 'PTW-TEST-001');
      expect(state.totalSeconds, 1800);
      expect(state.remainingSeconds, 1800);
      expect(state.formattedRemainingTime, '30:00');
      expect(state.fireWatcherName, 'Wichai');
      expect(state.isRunning, isFalse);
      expect(state.isCompleted, isFalse);
    });

    test('Starting and pausing timer modifies running state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fireWatchTimerProvider.notifier);
      notifier.initForPermit('PTW-TEST-001');

      notifier.startTimer();
      expect(container.read(fireWatchTimerProvider).isRunning, isTrue);

      notifier.pauseTimer();
      expect(container.read(fireWatchTimerProvider).isRunning, isFalse);
      expect(container.read(fireWatchTimerProvider).isPaused, isTrue);

      notifier.resumeTimer();
      expect(container.read(fireWatchTimerProvider).isRunning, isTrue);

      notifier.resetTimer(durationMinutes: 30);
      expect(container.read(fireWatchTimerProvider).isRunning, isFalse);
      expect(container.read(fireWatchTimerProvider).remainingSeconds, 1800);
    });

    test('Completing watch creates FireWatchModel', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fireWatchTimerProvider.notifier);
      notifier.initForPermit('PTW-TEST-001', watcherName: 'Wichai', watcherPhone: '0812345678');
      notifier.setAreaSafe(true);

      final model = await notifier.completeWatch(
        inspectorName: 'Jane Safety',
        notes: 'Area thoroughly cooled down, zero embers detected.',
      );

      expect(model.ptwNumber, 'PTW-TEST-001');
      expect(model.fireWatcherName, 'Wichai');
      expect(model.isPostWorkAreaSafe, isTrue);
      expect(model.finalInspectorName, 'Jane Safety');
      expect(container.read(fireWatchTimerProvider).isCompleted, isTrue);
    });
  });
}
