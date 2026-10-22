import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/environmental_standards_data.dart';
import '../../domain/models/environment_point_model.dart';
import '../../domain/models/environment_standard_model.dart';
import '../../domain/services/environmental_evaluator.dart';
import '../providers/environment_providers.dart';

/// Interactive modal for creating or editing an Environmental Sampling Point
/// with live real-time auto-evaluation according to statutory regulations.
class AddEditPointDialog extends ConsumerStatefulWidget {
  final EnvironmentPointModel? point;
  final String? defaultSessionId;
  final ValueChanged<EnvironmentPointModel>? onSaved;

  const AddEditPointDialog({
    Key? key,
    this.point,
    this.defaultSessionId,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<AddEditPointDialog> createState() => _AddEditPointDialogState();
}

class _AddEditPointDialogState extends ConsumerState<AddEditPointDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _pointIdCtrl;
  late TextEditingController _departmentCtrl;
  late TextEditingController _locationNameCtrl;
  late TextEditingController _taskOrMachineCtrl;
  late TextEditingController _notesCtrl;

  late EnvironmentFactorType _selectedFactor;
  String? _selectedSessionId;

  // --- Light Controllers ---
  late TextEditingController _lightMeasuredCtrl;
  late TextEditingController _lightMinStdCtrl;
  late TextEditingController _lightSurroundingCtrl;
  String? _selectedLightStdCode;

  // --- Noise Controllers ---
  late TextEditingController _noiseMeasuredCtrl;
  late TextEditingController _noisePeakCtrl;
  late TextEditingController _noiseDurationCtrl;
  late NoiseMeasurementType _selectedNoiseType;

  // --- Heat Controllers ---
  late TextEditingController _heatNwbCtrl;
  late TextEditingController _heatGtCtrl;
  late TextEditingController _heatDbCtrl;
  late HeatSolarExposure _selectedSolarExposure;
  late WorkloadLevel _selectedWorkload;

  @override
  void initState() {
    super.initState();
    final p = widget.point;

    final now = DateTime.now();
    final defaultId = p?.pointId ?? 'PT-ENV-${now.millisecondsSinceEpoch % 10000}';

    _pointIdCtrl = TextEditingController(text: defaultId);
    _departmentCtrl = TextEditingController(text: p?.department ?? 'ฝ่ายผลิต (Production)');
    _locationNameCtrl = TextEditingController(text: p?.locationName ?? 'สายการประกอบ 1');
    _taskOrMachineCtrl = TextEditingController(text: p?.taskOrMachineName ?? p?.lightTaskDescription ?? 'งานประกอบชิ้นส่วน');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');

    _selectedFactor = p?.factorType ?? EnvironmentFactorType.light;
    _selectedSessionId = p?.sessionId ?? widget.defaultSessionId ?? 'ENV-SESS-2026-001';

    // Light
    _lightMeasuredCtrl = TextEditingController(text: p?.lightMeasuredLux?.toString() ?? '350');
    _lightMinStdCtrl = TextEditingController(text: p?.lightStandardMinLux?.toString() ?? '300');
    _lightSurroundingCtrl = TextEditingController(text: p?.lightSurroundingLux?.toString() ?? '200');
    _selectedLightStdCode = p?.lightCategoryCode ?? 'LIGHT-CAT2-04';

    // Noise
    _noiseMeasuredCtrl = TextEditingController(text: p?.noiseMeasuredDba?.toString() ?? '82.5');
    _noisePeakCtrl = TextEditingController(text: p?.noisePeakDb?.toString() ?? '120.0');
    _noiseDurationCtrl = TextEditingController(text: p?.noiseExposureDurationHours?.toString() ?? '8.0');
    _selectedNoiseType = p?.noiseMeasurementType ?? NoiseMeasurementType.leq8hrTwa;

    // Heat
    _heatNwbCtrl = TextEditingController(text: p?.heatNwbCelsius?.toString() ?? '26.5');
    _heatGtCtrl = TextEditingController(text: p?.heatGtCelsius?.toString() ?? '34.0');
    _heatDbCtrl = TextEditingController(text: p?.heatDbCelsius?.toString() ?? '32.0');
    _selectedSolarExposure = p?.heatSolarExposure ?? HeatSolarExposure.indoorNoSolar;
    _selectedWorkload = p?.heatWorkloadType ?? WorkloadLevel.moderate;
  }

  @override
  void dispose() {
    _pointIdCtrl.dispose();
    _departmentCtrl.dispose();
    _locationNameCtrl.dispose();
    _taskOrMachineCtrl.dispose();
    _notesCtrl.dispose();
    _lightMeasuredCtrl.dispose();
    _lightMinStdCtrl.dispose();
    _lightSurroundingCtrl.dispose();
    _noiseMeasuredCtrl.dispose();
    _noisePeakCtrl.dispose();
    _noiseDurationCtrl.dispose();
    _heatNwbCtrl.dispose();
    _heatGtCtrl.dispose();
    _heatDbCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Live Evaluation Getters
  // --------------------------------------------------------------------------

  EnvironmentEvaluationStatus get _liveStatus {
    switch (_selectedFactor) {
      case EnvironmentFactorType.light:
        final meas = double.tryParse(_lightMeasuredCtrl.text.trim()) ?? 0.0;
        final std = double.tryParse(_lightMinStdCtrl.text.trim()) ?? 300.0;
        return meas >= std ? EnvironmentEvaluationStatus.pass : EnvironmentEvaluationStatus.fail;

      case EnvironmentFactorType.noise:
        if (_selectedNoiseType == NoiseMeasurementType.peakSoundLevel) {
          final peak = double.tryParse(_noisePeakCtrl.text.trim()) ?? 0.0;
          return peak <= 140.0 ? EnvironmentEvaluationStatus.pass : EnvironmentEvaluationStatus.fail;
        }
        final dba = double.tryParse(_noiseMeasuredCtrl.text.trim()) ?? 0.0;
        if (dba > 86.0) return EnvironmentEvaluationStatus.fail;
        if (dba >= 85.0) return EnvironmentEvaluationStatus.actionLevel;
        return EnvironmentEvaluationStatus.pass;

      case EnvironmentFactorType.heat:
        final wbgt = _calculatedWbgt;
        final limit = _selectedWorkload.standardLimitWbgt;
        return wbgt <= limit ? EnvironmentEvaluationStatus.pass : EnvironmentEvaluationStatus.fail;
    }
  }

  double get _calculatedWbgt {
    final nwb = double.tryParse(_heatNwbCtrl.text.trim()) ?? 0.0;
    final gt = double.tryParse(_heatGtCtrl.text.trim()) ?? 0.0;
    final db = double.tryParse(_heatDbCtrl.text.trim()) ?? 0.0;

    return EnvironmentalEvaluator.calculateWbgt(
      nwb: nwb,
      gt: gt,
      db: db,
      isOutdoor: _selectedSolarExposure == HeatSolarExposure.outdoorWithSolar,
    );
  }

  bool get _liveHcpRequired {
    if (_selectedFactor != EnvironmentFactorType.noise) return false;
    if (_selectedNoiseType == NoiseMeasurementType.peakSoundLevel) return false;
    final dba = double.tryParse(_noiseMeasuredCtrl.text.trim()) ?? 0.0;
    return dba >= 85.0;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final pointId = _pointIdCtrl.text.trim();
    final dept = _departmentCtrl.text.trim();
    final loc = _locationNameCtrl.text.trim();
    final task = _taskOrMachineCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final status = _liveStatus;

    EnvironmentPointModel point;

    if (_selectedFactor == EnvironmentFactorType.light) {
      final measLux = double.tryParse(_lightMeasuredCtrl.text.trim()) ?? 0.0;
      final minStd = double.tryParse(_lightMinStdCtrl.text.trim()) ?? 300.0;
      final surrLux = double.tryParse(_lightSurroundingCtrl.text.trim());
      final isCompliant = measLux >= minStd;

      point = EnvironmentPointModel(
        id: widget.point?.id,
        pointId: pointId,
        sessionId: _selectedSessionId ?? 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.light,
        department: dept,
        locationName: loc,
        taskOrMachineName: task,
        evaluationStatus: status,
        notes: notes,
        lightCategoryCode: _selectedLightStdCode,
        lightTaskDescription: task,
        lightMeasuredLux: measLux,
        lightStandardMinLux: minStd,
        lightSurroundingLux: surrLux,
        lightIsCompliant: isCompliant,
      );
    } else if (_selectedFactor == EnvironmentFactorType.noise) {
      final measDba = double.tryParse(_noiseMeasuredCtrl.text.trim());
      final peakDb = double.tryParse(_noisePeakCtrl.text.trim());
      final duration = double.tryParse(_noiseDurationCtrl.text.trim()) ?? 8.0;
      final isHcp = _liveHcpRequired;

      point = EnvironmentPointModel(
        id: widget.point?.id,
        pointId: pointId,
        sessionId: _selectedSessionId ?? 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.noise,
        department: dept,
        locationName: loc,
        taskOrMachineName: task,
        evaluationStatus: status,
        notes: notes,
        noiseMeasurementType: _selectedNoiseType,
        noiseMeasuredDba: measDba,
        noisePeakDb: peakDb,
        noiseExposureDurationHours: duration,
        noiseIsHcpRequired: isHcp,
      );
    } else {
      // Heat
      final nwb = double.tryParse(_heatNwbCtrl.text.trim()) ?? 0.0;
      final gt = double.tryParse(_heatGtCtrl.text.trim()) ?? 0.0;
      final db = double.tryParse(_heatDbCtrl.text.trim()) ?? 0.0;
      final wbgt = _calculatedWbgt;
      final limit = _selectedWorkload.standardLimitWbgt;
      final isCompliant = wbgt <= limit;

      point = EnvironmentPointModel(
        id: widget.point?.id,
        pointId: pointId,
        sessionId: _selectedSessionId ?? 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.heat,
        department: dept,
        locationName: loc,
        taskOrMachineName: task,
        evaluationStatus: status,
        notes: notes,
        heatSolarExposure: _selectedSolarExposure,
        heatNwbCelsius: nwb,
        heatGtCelsius: gt,
        heatDbCelsius: db,
        heatCalculatedWbgt: wbgt,
        heatWorkloadType: _selectedWorkload,
        heatStandardLimitWbgt: limit,
        heatIsCompliant: isCompliant,
      );
    }

    ref.read(envPointListProvider.notifier).savePoint(point);
    if (widget.onSaved != null) {
      widget.onSaved!(point);
    }
    Navigator.of(context).pop();
  }

  void _exportAndOpenPrintCard() {
    try {
      final factor = _selectedFactor.name;
      final pointId = _pointIdCtrl.text.trim();
      final dept = _departmentCtrl.text.trim();
      final loc = _locationNameCtrl.text.trim();
      final task = _taskOrMachineCtrl.text.trim();
      final notes = _notesCtrl.text.trim();

      String measuredVal = '0';
      String unit = '';
      String stdLimit = '';
      String statusText = 'ผ่านเกณฑ์มาตรฐาน';

      if (_selectedFactor == EnvironmentFactorType.heat) {
        try {
          final isPass = _calculatedWbgt <= _selectedWorkload.standardLimitWbgt;
          String empName = 'คุณเพ็ญศรี มูลพันธ์';
          if (task.contains('(')) {
            final parts = task.split('(');
            if (parts.length > 1) {
              empName = parts[1].replaceAll(')', '').trim();
            }
          }
          final taskDesc = task.split('(').first.trim();
          final metAvg = _selectedWorkload == WorkloadLevel.heavy ? '400' : (_selectedWorkload == WorkloadLevel.light ? '150' : '204');
          final rss1Js = '''
window.RSS1_DATA = {
  date: "30 มีนาคม 2569",
  location: "$loc",
  employee: "$empName",
  time: "8.50-10.50",
  nwb: "${double.tryParse(_heatNwbCtrl.text.trim())?.toStringAsFixed(1) ?? '27.9'}",
  db: "${double.tryParse(_heatDbCtrl.text.trim())?.toStringAsFixed(1) ?? '34.2'}",
  gt: "${double.tryParse(_heatGtCtrl.text.trim())?.toStringAsFixed(1) ?? '35.2'}",
  solar: "${_selectedSolarExposure == HeatSolarExposure.outdoorWithSolar ? 'out' : 'in'}",
  wbgt: "${_calculatedWbgt.toStringAsFixed(1)}",
  task: "$taskDesc",
  workload: "${_selectedWorkload.labelTh}",
  metAvg: "$metAvg",
  evaluation: "${isPass ? 'ไม่เกินเกณฑ์' : 'เกินเกณฑ์'}",
  capa: "-"
};
''';
          for (final p in [
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss1_current.js',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss1_current.js',
            r'D:\DEV\Safapp\bin\สวล69\2026\rss1_current.js',
          ]) {
            try {
              File(p).writeAsStringSync(rss1Js);
            } catch (_) {}
          }
        } catch (_) {}

        Process.run('cmd.exe', [
          '/c',
          'start',
          '',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss1.html',
        ]);
        return;
      }

      if (_selectedFactor == EnvironmentFactorType.light) {
        if (_selectedLightStdCode == 'AREA') {
          try {
            final luxVal = double.tryParse(_lightMeasuredCtrl.text.trim()) ?? 517.0;
            final luxMin = (luxVal * 0.96).round();
            final isPass = luxVal >= (double.tryParse(_lightMinStdCtrl.text.trim()) ?? 0);
            final rss2AreaJs = '''
window.RSS2_AREA_DATA = {
  date: "30 มีนาคม 2569",
  location: "$loc",
  task: "${task.isNotEmpty ? task : 'พื้นที่ทำงาน'}",
  luxAvg: "${luxVal.toStringAsFixed(0)}",
  luxMin: "$luxMin",
  evaluation: "${isPass ? 'เป็นไปตามเกณฑ์' : 'ไม่เป็นไปตามเกณฑ์'}",
  capa: "-"
};
''';
            for (final p in [
              r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss2_area_current.js',
              r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss2_area_current.js',
              r'D:\DEV\Safapp\bin\สวล69\2026\rss2_area_current.js',
            ]) {
              try {
                File(p).writeAsStringSync(rss2AreaJs);
              } catch (_) {}
            }
          } catch (_) {}

          Process.run('cmd.exe', [
            '/c',
            'start',
            '',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss2_area.html',
          ]);
          return;
        } else {
          try {
            final luxVal = double.tryParse(_lightMeasuredCtrl.text.trim()) ?? 448.0;
            final isPass = luxVal >= (double.tryParse(_lightMinStdCtrl.text.trim()) ?? 0);
            final surround = _lightSurroundingCtrl.text.trim().isNotEmpty ? _lightSurroundingCtrl.text.trim() : '-';
            final empInfo = '$dept<br>$loc';
            final taskDesc = task.isNotEmpty ? task : 'คอมพิวเตอร์ (งานละเอียดเล็กน้อย)';
            final rss2SpotJs = '''
window.RSS2_SPOT_DATA = {
  date: "30 มีนาคม 2569",
  employee: "$empInfo",
  task: "$taskDesc",
  luxSpot: "${luxVal.toStringAsFixed(0)}",
  surround1: "$surround",
  surround2: "-",
  evaluation: "${isPass ? 'เป็นไปตามเกณฑ์' : 'ไม่เป็นไปตามเกณฑ์'}",
  capa: "-"
};
''';
            for (final p in [
              r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss2_spot_current.js',
              r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss2_spot_current.js',
              r'D:\DEV\Safapp\bin\สวล69\2026\rss2_spot_current.js',
            ]) {
              try {
                File(p).writeAsStringSync(rss2SpotJs);
              } catch (_) {}
            }
          } catch (_) {}

          Process.run('cmd.exe', [
            '/c',
            'start',
            '',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss2_spot.html',
          ]);
          return;
        }
      }

      if (_selectedFactor == EnvironmentFactorType.noise) {
        try {
          final dba = double.tryParse(_noiseMeasuredCtrl.text.trim()) ?? 73.4;
          final isPass = dba <= 86.0;
          final emp = task.replaceAll(RegExp(r'\s*\([^)]*\)'), '').isNotEmpty ? task.replaceAll(RegExp(r'\s*\([^)]*\)'), '') : 'Ms. Nant Mya Thaw';
          final hours = '${double.tryParse(_noiseDurationCtrl.text.trim())?.toStringAsFixed(0) ?? '8'} ชั่วโมง';
          final rss3Js = '''
window.RSS3_DATA = {
  date: "30 มีนาคม 2569",
  location: "$loc",
  employee: "$emp",
  workDuration: "$hours",
  workArea: "-",
  noiseDba: "${dba.toStringAsFixed(1)}",
  measDuration: "$hours",
  twa: "${dba.round()}",
  evaluation: "${isPass ? 'ไม่เกินเกณฑ์' : 'เกินเกณฑ์'}",
  capa: "-"
};
''';
          for (final p in [
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss3_current.js',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss3_current.js',
            r'D:\DEV\Safapp\bin\สวล69\2026\rss3_current.js',
          ]) {
            try {
              File(p).writeAsStringSync(rss3Js);
            } catch (_) {}
          }
        } catch (_) {}

        Process.run('cmd.exe', [
          '/c',
          'start',
          '',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss3.html',
        ]);
        return;
      }

      measuredVal = '0';
      unit = '';
      stdLimit = '-';
      statusText = 'ผ่านเกณฑ์มาตรฐาน';

      final jsContent = '''
window.CURRENT_POINT_DATA = {
  factor: "$factor",
  pointId: "$pointId",
  dept: "$dept",
  location: "$loc",
  task: "$task",
  date: "18 ก.พ. 2569",
  measuredValue: "$measuredVal",
  measuredUnit: "$unit",
  standardLimit: "$stdLimit",
  statusText: "$statusText",
  notes: "$notes"
};
''';

      final file = File(r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\point_current.js');
      file.writeAsStringSync(jsContent);
    } catch (_) {}

    Process.run('cmd.exe', [
      '/c',
      'start',
      '',
      r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\point_print_card.html',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.point != null;
    final sessionsAsync = ref.watch(envSessionListProvider);
    final liveStatus = _liveStatus;

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    switch (liveStatus) {
      case EnvironmentEvaluationStatus.pass:
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        badgeIcon = Icons.check_circle_rounded;
        badgeLabel = 'ผ่านเกณฑ์มาตรฐานกฎหมาย (PASS)';
        break;
      case EnvironmentEvaluationStatus.actionLevel:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        badgeIcon = Icons.warning_amber_rounded;
        badgeLabel = 'เฝ้าระวัง Action Level >= 85 dBA (ต้องทำ HCP)';
        break;
      case EnvironmentEvaluationStatus.fail:
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFF991B1B);
        badgeIcon = Icons.cancel_rounded;
        badgeLabel = 'เกินเกณฑ์มาตรฐาน (FAIL - ต้องจัดทำแผน CAPA)';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 740),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'แก้ไขจุดตรวจวัด (${widget.point!.pointId})' : 'บันทึกผลตรวจวัดสภาพแวดล้อมรายจุด',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Factor Type Selector Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: EnvironmentFactorType.values.map((f) {
                          final isSel = _selectedFactor == f;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFactor = f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSel
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      f == EnvironmentFactorType.light
                                          ? Icons.lightbulb_outline_rounded
                                          : (f == EnvironmentFactorType.noise
                                              ? Icons.volume_up_rounded
                                              : Icons.thermostat_rounded),
                                      size: 18,
                                      color: isSel ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      f.labelTh,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? const Color(0xFF1E3A8A) : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Auto-Evaluation Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(badgeIcon, color: badgeText, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ประเมินผลอัตโนมัติตามกฎหมาย (Live Auto-Evaluation):',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeText),
                                ),
                                Text(
                                  badgeLabel,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeText),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedFactor == EnvironmentFactorType.heat)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeText.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'WBGT: ${_calculatedWbgt.toStringAsFixed(2)} °C',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeText),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Point ID & Session Dropdown
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _pointIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'รหัสจุดตรวจวัด (Point ID) *',
                              hintText: 'PT-ENV-LIGHT-001',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัสจุด' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: sessionsAsync.when(
                            data: (sessions) {
                              final hasSession = sessions.any((s) => s.sessionId == _selectedSessionId);
                              final sessionVal = hasSession
                                  ? _selectedSessionId
                                  : (sessions.isNotEmpty ? sessions.first.sessionId : null);

                              return DropdownButtonFormField<String>(
                                value: sessionVal,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'รอบการตรวจวัด (Session)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: sessions.map((s) {
                                  return DropdownMenuItem(
                                    value: s.sessionId,
                                    child: Text('${s.sessionId} (${s.sessionYearBe})', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedSessionId = v),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location & Department
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _departmentCtrl,
                            decoration: const InputDecoration(
                              labelText: 'แผนก / ฝ่าย *',
                              hintText: 'ฝ่ายผลิต (Production)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุแผนก' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _locationNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'พื้นที่ / ตำแหน่งจุดตรวจวัด *',
                              hintText: 'โต๊ะตรวจสอบคุณภาพ QC Line 1',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุตำแหน่งจุด' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Factor Specific Dynamic Section
                    if (_selectedFactor == EnvironmentFactorType.light) ...[
                      // --- LIGHTING SECTION ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เกณฑ์มาตรฐานความเข้มแสงสว่าง (ประกาศกรมฯ ๒๕๖๑)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final hasMatchingStd = EnvironmentalStandardsData.lightingStandards.any(
                                  (std) => std.standardCode == _selectedLightStdCode,
                                );

                                final lightDropdownItems = <DropdownMenuItem<String>>[
                                  if (_selectedLightStdCode != null && !hasMatchingStd)
                                    DropdownMenuItem<String>(
                                      value: _selectedLightStdCode,
                                      child: Text(
                                        'ประเภทเดิม: $_selectedLightStdCode (${_lightMinStdCtrl.text} Lux)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ...EnvironmentalStandardsData.lightingStandards.map((std) {
                                    return DropdownMenuItem<String>(
                                      value: std.standardCode,
                                      child: Text(
                                        '${std.taskDescription} (${std.standardLimit} Lux)',
                                        style: const TextStyle(fontSize: 12.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ];

                                return DropdownButtonFormField<String>(
                                  value: _selectedLightStdCode,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'เลือกประเภทงาน / มาตรฐานความเข้มแสงสว่าง',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: lightDropdownItems,
                                  onChanged: (code) {
                                    if (code != null) {
                                      final match = EnvironmentalStandardsData.findStandardByCode(code);
                                      setState(() {
                                        _selectedLightStdCode = code;
                                        if (match != null) {
                                          _lightMinStdCtrl.text = match.standardLimit.toStringAsFixed(0);
                                          _taskOrMachineCtrl.text = match.taskDescription;
                                        }
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _lightMeasuredCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'ความเข้มแสงที่วัดได้ (Lux) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุค่า Lux' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lightMinStdCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'เกณฑ์มาตรฐานต่ำสุด (Lux) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุเกณฑ์มาตรฐาน' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lightSurroundingCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'แสงสว่างบริเวณรอบ (Lux)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedFactor == EnvironmentFactorType.noise) ...[
                      // --- NOISE SECTION ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เกณฑ์มาตรฐานระดับเสียง (กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๑)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<NoiseMeasurementType>(
                              value: _selectedNoiseType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'ประเภทการตรวจวัดระดับเสียง *',
                                border: OutlineInputBorder(),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: NoiseMeasurementType.values.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.labelTh,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedNoiseType = v);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (_selectedNoiseType != NoiseMeasurementType.peakSoundLevel) ...[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _noiseMeasuredCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'ระดับเสียงที่วัดได้ (dBA) *',
                                        hintText: '84.5',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'ระบุระดับเสียง dBA' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _noiseDurationCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'ระยะเวลาทำงาน (ชม.)',
                                        hintText: '8.0',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: TextFormField(
                                      controller: _noisePeakCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'ระดับเสียงกระทบ/กระแทก (Peak dB) *',
                                        hintText: '135.0',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'ระบุ Peak dB' : null,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_liveHcpRequired) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD8B4FE)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.hearing_rounded, color: Color(0xFF6B21A8), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ระดับเสียงตั้งแต่ 85 dBA ขึ้นไป ต้องจัดทำโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program) ตามข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF6B21A8), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // --- HEAT SECTION ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เกณฑ์มาตรฐานระดับความร้อน WBGT (กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<HeatSolarExposure>(
                                    value: _selectedSolarExposure,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'สภาพแดด / สูตร WBGT *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return HeatSolarExposure.values.map((s) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            s.labelTh,
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: HeatSolarExposure.values.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s.labelTh,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedSolarExposure = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<WorkloadLevel>(
                                    value: _selectedWorkload,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'ลักษณะภาระงาน (Workload) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return WorkloadLevel.values.map((w) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${w.labelTh} (<= ${w.standardLimitWbgt}°C)',
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: WorkloadLevel.values.map((w) {
                                      return DropdownMenuItem(
                                        value: w,
                                        child: Text(
                                          '${w.labelTh} (<= ${w.standardLimitWbgt}°C)',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedWorkload = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heatNwbCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'NWB กระเปาะเปียก (°C) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุ NWB' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heatGtCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'GT โกลบ 150mm (°C) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุ GT' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heatDbCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'DB กระเปาะแห้ง (°C)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Task or Machine Description
                    TextFormField(
                      controller: _taskOrMachineCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ลักษณะงาน / เครื่องจักร / กิจกรรมที่ตรวจวัด *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุลักษณะงาน' : null,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุ / ข้อสังเกตเพิ่มเติม',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  if (isEdit) ...[
                    OutlinedButton.icon(
                      onPressed: _exportAndOpenPrintCard,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('พิมพ์การ์ดประจำจุดตรวจ (Print Card)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกจุดตรวจวัด'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
