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
                              return DropdownButtonFormField<String>(
                                value: _selectedSessionId,
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
                            DropdownButtonFormField<String>(
                              value: _selectedLightStdCode,
                              decoration: const InputDecoration(
                                labelText: 'เลือกประเภทงาน / มาตรฐานความเข้มแสงสว่าง',
                                border: OutlineInputBorder(),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: EnvironmentalStandardsData.lightingStandards.map((std) {
                                return DropdownMenuItem<String>(
                                  value: std.standardCode,
                                  child: Text('${std.taskDescription} (${std.standardLimit} Lux)', style: const TextStyle(fontSize: 12.5)),
                                );
                              }).toList(),
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
                                  child: Text(t.labelTh),
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
                                    decoration: const InputDecoration(
                                      labelText: 'สภาพแดด / สูตร WBGT *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: HeatSolarExposure.values.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s.labelTh, style: const TextStyle(fontSize: 12)),
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
                                    decoration: const InputDecoration(
                                      labelText: 'ลักษณะภาระงาน (Workload) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: WorkloadLevel.values.map((w) {
                                      return DropdownMenuItem(
                                        value: w,
                                        child: Text('${w.labelTh} (<= ${w.standardLimitWbgt}°C)'),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
