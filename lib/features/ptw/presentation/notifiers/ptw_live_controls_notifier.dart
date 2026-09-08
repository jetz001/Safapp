import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gas_test_log_model.dart';
import '../../data/models/fire_watch_model.dart';
import '../../domain/services/ptw_safety_evaluator.dart';
import 'ptw_list_notifier.dart';

// ============================================================================
// 1. Gas Tracker State & Notifier (Confined Space Continuous Monitoring)
// ============================================================================

class GasTrackerState {
  final String ptwNumber;
  final List<GasTestLogModel> logs;
  final double currentOxygen;
  final double currentLel;
  final double currentCo;
  final double currentH2s;
  final double? currentToxicOther;
  final String? currentToxicOtherName;
  final String locationPoint;
  final String testStage; // 'PRE_ENTRY', 'CONTINUOUS', 'POST_WORK'
  final String testerName;
  final String? testerCertNo;
  final String detectorModel;
  final String detectorSerialNo;
  final String lastCalibrationDate;
  final bool isCurrentAtmosphereSafe;
  final List<String> activeWarnings;
  final List<String> activeErrors;

  const GasTrackerState({
    this.ptwNumber = '',
    this.logs = const [],
    this.currentOxygen = 20.9,
    this.currentLel = 0.0,
    this.currentCo = 0.0,
    this.currentH2s = 0.0,
    this.currentToxicOther,
    this.currentToxicOtherName,
    this.locationPoint = 'จุดตรวจวัดหลัก (Main Entry/Working Point)',
    this.testStage = 'CONTINUOUS',
    this.testerName = '',
    this.testerCertNo,
    this.detectorModel = 'Dräger X-am 5000',
    this.detectorSerialNo = 'DR-2026-01',
    this.lastCalibrationDate = '',
    this.isCurrentAtmosphereSafe = true,
    this.activeWarnings = const [],
    this.activeErrors = const [],
  });

  GasTrackerState copyWith({
    String? ptwNumber,
    List<GasTestLogModel>? logs,
    double? currentOxygen,
    double? currentLel,
    double? currentCo,
    double? currentH2s,
    double? currentToxicOther,
    bool clearToxicOther = false,
    String? currentToxicOtherName,
    String? locationPoint,
    String? testStage,
    String? testerName,
    String? testerCertNo,
    String? detectorModel,
    String? detectorSerialNo,
    String? lastCalibrationDate,
    bool? isCurrentAtmosphereSafe,
    List<String>? activeWarnings,
    List<String>? activeErrors,
  }) {
    return GasTrackerState(
      ptwNumber: ptwNumber ?? this.ptwNumber,
      logs: logs ?? this.logs,
      currentOxygen: currentOxygen ?? this.currentOxygen,
      currentLel: currentLel ?? this.currentLel,
      currentCo: currentCo ?? this.currentCo,
      currentH2s: currentH2s ?? this.currentH2s,
      currentToxicOther: clearToxicOther ? null : (currentToxicOther ?? this.currentToxicOther),
      currentToxicOtherName: clearToxicOther ? null : (currentToxicOtherName ?? this.currentToxicOtherName),
      locationPoint: locationPoint ?? this.locationPoint,
      testStage: testStage ?? this.testStage,
      testerName: testerName ?? this.testerName,
      testerCertNo: testerCertNo ?? this.testerCertNo,
      detectorModel: detectorModel ?? this.detectorModel,
      detectorSerialNo: detectorSerialNo ?? this.detectorSerialNo,
      lastCalibrationDate: lastCalibrationDate ?? this.lastCalibrationDate,
      isCurrentAtmosphereSafe: isCurrentAtmosphereSafe ?? this.isCurrentAtmosphereSafe,
      activeWarnings: activeWarnings ?? this.activeWarnings,
      activeErrors: activeErrors ?? this.activeErrors,
    );
  }
}

class GasTrackerNotifier extends Notifier<GasTrackerState> {
  @override
  GasTrackerState build() => const GasTrackerState();

  void initForPermit(String ptwNumber, List<GasTestLogModel> existingLogs) {
    state = state.copyWith(
      ptwNumber: ptwNumber,
      logs: existingLogs,
      lastCalibrationDate: DateTime.now().toIso8601String().substring(0, 10),
    );
    _reEvaluate();
  }

  void setOxygen(double val) {
    state = state.copyWith(currentOxygen: val);
    _reEvaluate();
  }

  void setLel(double val) {
    state = state.copyWith(currentLel: val);
    _reEvaluate();
  }

  void setCo(double val) {
    state = state.copyWith(currentCo: val);
    _reEvaluate();
  }

  void setH2s(double val) {
    state = state.copyWith(currentH2s: val);
    _reEvaluate();
  }

  void setToxicOther(double? val, String? name) {
    if (val == null) {
      state = state.copyWith(clearToxicOther: true);
    } else {
      state = state.copyWith(currentToxicOther: val, currentToxicOtherName: name);
    }
    _reEvaluate();
  }

  void setLocationPoint(String loc) {
    state = state.copyWith(locationPoint: loc);
  }

  void setTestStage(String stage) {
    state = state.copyWith(testStage: stage);
  }

  void setTesterInfo({
    required String testerName,
    String? certNo,
    String? detectorModel,
    String? serialNo,
    String? calDate,
  }) {
    state = state.copyWith(
      testerName: testerName,
      testerCertNo: certNo,
      detectorModel: detectorModel ?? state.detectorModel,
      detectorSerialNo: serialNo ?? state.detectorSerialNo,
      lastCalibrationDate: calDate ?? state.lastCalibrationDate,
    );
  }

  void _reEvaluate() {
    final eval = PtwSafetyEvaluator.evaluateAtmosphere(
      oxygenPercent: state.currentOxygen,
      combustiblePercentLel: state.currentLel,
      carbonMonoxidePpm: state.currentCo,
      hydrogenSulfidePpm: state.currentH2s,
      otherToxicPpm: state.currentToxicOther,
    );

    state = state.copyWith(
      isCurrentAtmosphereSafe: eval.isValid,
      activeErrors: eval.errors,
      activeWarnings: eval.warnings,
    );
  }

  /// Record current gas reading as a permanent log entry
  Future<GasTestLogModel> recordReading({String? signaturePath}) async {
    _reEvaluate();

    final nowStr = DateTime.now().toIso8601String();
    final logId = 'GAS-${DateTime.now().millisecondsSinceEpoch}';

    final newLog = GasTestLogModel(
      logId: logId,
      ptwNumber: state.ptwNumber,
      testStage: state.testStage,
      testTimestamp: nowStr,
      locationPoint: state.locationPoint,
      oxygenPercent: state.currentOxygen,
      combustiblePercentLel: state.currentLel,
      carbonMonoxidePpm: state.currentCo,
      hydrogenSulfidePpm: state.currentH2s,
      toxicOtherPpm: state.currentToxicOther,
      toxicOtherName: state.currentToxicOtherName,
      testerName: state.testerName.isNotEmpty ? state.testerName : 'Gas Inspector',
      testerCertNo: state.testerCertNo,
      detectorModel: state.detectorModel,
      detectorSerialNo: state.detectorSerialNo,
      lastCalibrationDate: state.lastCalibrationDate.isNotEmpty
          ? state.lastCalibrationDate
          : nowStr.substring(0, 10),
      isSafe: state.isCurrentAtmosphereSafe,
      safetyRemarks: state.activeErrors.isNotEmpty
          ? state.activeErrors.join('; ')
          : (state.activeWarnings.isNotEmpty ? state.activeWarnings.join('; ') : 'ปกติ ปลอดภัย'),
      signaturePath: signaturePath,
    );

    // Save to repository if permit number is present
    if (state.ptwNumber.isNotEmpty) {
      final repo = ref.read(ptwRepositoryProvider);
      await repo.addGasTestLog(state.ptwNumber, newLog);
    }

    final updatedLogs = List<GasTestLogModel>.from(state.logs)..add(newLog);
    state = state.copyWith(logs: updatedLogs);

    return newLog;
  }
}

final gasTrackerProvider = NotifierProvider<GasTrackerNotifier, GasTrackerState>(
  GasTrackerNotifier.new,
);

// ============================================================================
// 2. Fire Watch Timer State & Notifier (Hot Work 30-Minute Monitoring)
// ============================================================================

class FireWatchTimerState {
  final String ptwNumber;
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;
  final bool hasAlert;
  final String? alertMessage;

  // Safety Controls Checkpoints
  final String fireWatcherName;
  final String fireWatcherPhone;
  final String fireExtinguisherType;
  final String fireExtinguisherSerial;
  final bool extinguisherInspectedReady;
  final double clearedRadiusMeters;
  final bool fireBlanketInstalled;
  final bool combustibleProtected;
  final bool sewerCovered;
  final bool isPostWorkAreaSafe;
  final String? finalInspectorName;
  final String? hotWorkEndTime;
  final String? postWorkWatchStartTime;
  final String? postWorkWatchEndTime;

  const FireWatchTimerState({
    this.ptwNumber = '',
    this.totalSeconds = 1800, // 30 minutes
    this.remainingSeconds = 1800,
    this.isRunning = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.hasAlert = false,
    this.alertMessage,
    this.fireWatcherName = '',
    this.fireWatcherPhone = '',
    this.fireExtinguisherType = 'Dry Chemical 15 lbs',
    this.fireExtinguisherSerial = 'EXT-HW-01',
    this.extinguisherInspectedReady = true,
    this.clearedRadiusMeters = 11.0,
    this.fireBlanketInstalled = true,
    this.combustibleProtected = true,
    this.sewerCovered = true,
    this.isPostWorkAreaSafe = false,
    this.finalInspectorName,
    this.hotWorkEndTime,
    this.postWorkWatchStartTime,
    this.postWorkWatchEndTime,
  });

  /// Formatted Remaining Time: "MM:SS"
  String get formattedRemainingTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress Fraction from 0.0 to 1.0
  double get progressPercent {
    if (totalSeconds <= 0) return 1.0;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  /// Elapsed duration in minutes
  int get elapsedMinutes => (totalSeconds - remainingSeconds) ~/ 60;

  FireWatchTimerState copyWith({
    String? ptwNumber,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isCompleted,
    bool? hasAlert,
    String? alertMessage,
    bool clearAlert = false,
    String? fireWatcherName,
    String? fireWatcherPhone,
    String? fireExtinguisherType,
    String? fireExtinguisherSerial,
    bool? extinguisherInspectedReady,
    double? clearedRadiusMeters,
    bool? fireBlanketInstalled,
    bool? combustibleProtected,
    bool? sewerCovered,
    bool? isPostWorkAreaSafe,
    String? finalInspectorName,
    String? hotWorkEndTime,
    String? postWorkWatchStartTime,
    String? postWorkWatchEndTime,
  }) {
    return FireWatchTimerState(
      ptwNumber: ptwNumber ?? this.ptwNumber,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      hasAlert: clearAlert ? false : (hasAlert ?? this.hasAlert),
      alertMessage: clearAlert ? null : (alertMessage ?? this.alertMessage),
      fireWatcherName: fireWatcherName ?? this.fireWatcherName,
      fireWatcherPhone: fireWatcherPhone ?? this.fireWatcherPhone,
      fireExtinguisherType: fireExtinguisherType ?? this.fireExtinguisherType,
      fireExtinguisherSerial: fireExtinguisherSerial ?? this.fireExtinguisherSerial,
      extinguisherInspectedReady: extinguisherInspectedReady ?? this.extinguisherInspectedReady,
      clearedRadiusMeters: clearedRadiusMeters ?? this.clearedRadiusMeters,
      fireBlanketInstalled: fireBlanketInstalled ?? this.fireBlanketInstalled,
      combustibleProtected: combustibleProtected ?? this.combustibleProtected,
      sewerCovered: sewerCovered ?? this.sewerCovered,
      isPostWorkAreaSafe: isPostWorkAreaSafe ?? this.isPostWorkAreaSafe,
      finalInspectorName: finalInspectorName ?? this.finalInspectorName,
      hotWorkEndTime: hotWorkEndTime ?? this.hotWorkEndTime,
      postWorkWatchStartTime: postWorkWatchStartTime ?? this.postWorkWatchStartTime,
      postWorkWatchEndTime: postWorkWatchEndTime ?? this.postWorkWatchEndTime,
    );
  }
}

class FireWatchTimerNotifier extends Notifier<FireWatchTimerState> {
  Timer? _timer;

  @override
  FireWatchTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const FireWatchTimerState();
  }

  void initForPermit(
    String ptwNumber, {
    int durationMinutes = 30,
    String watcherName = '',
    String watcherPhone = '',
    FireWatchModel? existingModel,
  }) {
    _timer?.cancel();
    final totalSec = durationMinutes * 60;

    if (existingModel != null) {
      state = FireWatchTimerState(
        ptwNumber: ptwNumber,
        totalSeconds: totalSec,
        remainingSeconds: existingModel.isCompliantWith30MinRule ? 0 : totalSec,
        isCompleted: existingModel.isCompliantWith30MinRule,
        fireWatcherName: existingModel.fireWatcherName,
        fireWatcherPhone: existingModel.fireWatcherPhone,
        fireExtinguisherType: existingModel.fireExtinguisherType,
        fireExtinguisherSerial: existingModel.fireExtinguisherSerial,
        extinguisherInspectedReady: existingModel.extinguisherInspectedReady,
        clearedRadiusMeters: existingModel.clearedRadiusMeters,
        fireBlanketInstalled: existingModel.fireBlanketInstalled,
        combustibleProtected: existingModel.combustibleMaterialProtected,
        sewerCovered: existingModel.sewerCovered,
        isPostWorkAreaSafe: existingModel.isPostWorkAreaSafe,
        finalInspectorName: existingModel.finalInspectorName,
        hotWorkEndTime: existingModel.hotWorkEndTime,
        postWorkWatchStartTime: existingModel.postWorkWatchStartTime,
        postWorkWatchEndTime: existingModel.postWorkWatchEndTime,
      );
    } else {
      state = FireWatchTimerState(
        ptwNumber: ptwNumber,
        totalSeconds: totalSec,
        remainingSeconds: totalSec,
        fireWatcherName: watcherName,
        fireWatcherPhone: watcherPhone,
        hotWorkEndTime: DateTime.now().toIso8601String(),
        postWorkWatchStartTime: DateTime.now().toIso8601String(),
      );
    }
  }

  void setWatcherInfo({
    required String name,
    required String phone,
    String? extinguisherType,
    String? extinguisherSerial,
    double? clearedRadius,
  }) {
    state = state.copyWith(
      fireWatcherName: name,
      fireWatcherPhone: phone,
      fireExtinguisherType: extinguisherType ?? state.fireExtinguisherType,
      fireExtinguisherSerial: extinguisherSerial ?? state.fireExtinguisherSerial,
      clearedRadiusMeters: clearedRadius ?? state.clearedRadiusMeters,
    );
  }

  void setChecklistConditions({
    bool? extinguisherReady,
    bool? blanketInstalled,
    bool? combustibleProtected,
    bool? sewerCovered,
  }) {
    state = state.copyWith(
      extinguisherInspectedReady: extinguisherReady ?? state.extinguisherInspectedReady,
      fireBlanketInstalled: blanketInstalled ?? state.fireBlanketInstalled,
      combustibleProtected: combustibleProtected ?? state.combustibleProtected,
      sewerCovered: sewerCovered ?? state.sewerCovered,
    );
  }

  void setAreaSafe(bool isSafe) {
    state = state.copyWith(isPostWorkAreaSafe: isSafe);
  }

  void startTimer() {
    if (state.isRunning) return;

    final nowStr = DateTime.now().toIso8601String();
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isCompleted: false,
      postWorkWatchStartTime: state.postWorkWatchStartTime ?? nowStr,
      clearAlert: true,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  void resumeTimer() {
    if (!state.isPaused) return;
    startTimer();
  }

  void resetTimer({int durationMinutes = 30}) {
    _timer?.cancel();
    final totalSec = durationMinutes * 60;
    state = state.copyWith(
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
      isRunning: false,
      isPaused: false,
      isCompleted: false,
      clearAlert: true,
    );
  }

  void _tick() {
    if (state.remainingSeconds > 1) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    } else {
      _timer?.cancel();
      final nowStr = DateTime.now().toIso8601String();
      state = state.copyWith(
        remainingSeconds: 0,
        isRunning: false,
        isPaused: false,
        isCompleted: true,
        hasAlert: true,
        alertMessage: 'เฝ้าระวังครบ 30 นาทีแล้ว! กรุณาตรวจสอบพื้นที่หน้างานครั้งสุดท้ายและลงนามปิดงาน',
        postWorkWatchEndTime: nowStr,
      );
    }
  }

  /// Finalize Fire Watch and create domain entity
  Future<FireWatchModel> completeWatch({
    required String inspectorName,
    String? inspectorSignature,
    String? notes,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final watchId = 'FW-${DateTime.now().millisecondsSinceEpoch}';
    final elapsedMins = state.elapsedMinutes >= 30 ? state.elapsedMinutes : (state.totalSeconds ~/ 60);

    final model = FireWatchModel(
      watchId: watchId,
      ptwNumber: state.ptwNumber,
      fireWatcherName: state.fireWatcherName.isNotEmpty ? state.fireWatcherName : 'Fire Watcher',
      fireWatcherPhone: state.fireWatcherPhone,
      fireExtinguisherType: state.fireExtinguisherType,
      fireExtinguisherSerial: state.fireExtinguisherSerial,
      extinguisherInspectedReady: state.extinguisherInspectedReady,
      clearedRadiusMeters: state.clearedRadiusMeters,
      fireBlanketInstalled: state.fireBlanketInstalled,
      combustibleMaterialProtected: state.combustibleProtected,
      sewerCovered: state.sewerCovered,
      hotWorkEndTime: state.hotWorkEndTime ?? nowStr,
      postWorkWatchStartTime: state.postWorkWatchStartTime ?? nowStr,
      postWorkWatchEndTime: state.postWorkWatchEndTime ?? nowStr,
      postWorkWatchDurationMinutes: elapsedMins,
      isPostWorkAreaSafe: state.isPostWorkAreaSafe,
      finalInspectorName: inspectorName,
      finalInspectorSignature: inspectorSignature,
      notes: notes,
    );

    if (state.ptwNumber.isNotEmpty) {
      final repo = ref.read(ptwRepositoryProvider);
      await repo.saveFireWatch(state.ptwNumber, model);
    }

    state = state.copyWith(
      isCompleted: true,
      finalInspectorName: inspectorName,
      postWorkWatchEndTime: nowStr,
    );

    return model;
  }
}

final fireWatchTimerProvider = NotifierProvider<FireWatchTimerNotifier, FireWatchTimerState>(
  FireWatchTimerNotifier.new,
);
