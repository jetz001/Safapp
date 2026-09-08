import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gas_test_log_model.dart';
import '../../domain/services/ptw_safety_evaluator.dart';
import '../notifiers/ptw_live_controls_notifier.dart';

/// Interactive Live Gas Level Logger & Real-Time Evaluator Card
/// Evaluates atmosphere against Ministerial Regulation on Confined Space B.E. 2562 (ข้อ ๗)
class GasTestLoggerCard extends ConsumerStatefulWidget {
  final String ptwNumber;
  final List<GasTestLogModel> existingLogs;
  final Function(GasTestLogModel newLog)? onLogSaved;
  final bool isReadOnly;

  const GasTestLoggerCard({
    super.key,
    required this.ptwNumber,
    this.existingLogs = const [],
    this.onLogSaved,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<GasTestLoggerCard> createState() => _GasTestLoggerCardState();
}

class _GasTestLoggerCardState extends ConsumerState<GasTestLoggerCard> {
  final TextEditingController _o2Controller = TextEditingController(text: '20.9');
  final TextEditingController _lelController = TextEditingController(text: '0.0');
  final TextEditingController _coController = TextEditingController(text: '0.0');
  final TextEditingController _h2sController = TextEditingController(text: '0.0');
  final TextEditingController _locationController = TextEditingController(text: 'จุดตรวจวัดหลัก (Main Entry)');
  final TextEditingController _testerController = TextEditingController(text: 'จป.วิชาชีพ ผู้ตรวจวัด');
  final TextEditingController _certController = TextEditingController(text: 'GAS-CERT-2026-01');
  final TextEditingController _modelController = TextEditingController(text: 'Dräger X-am 5000');
  final TextEditingController _serialController = TextEditingController(text: 'DR-2026-99');

  String _selectedStage = 'PRE_ENTRY';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gasTrackerProvider.notifier).initForPermit(widget.ptwNumber, widget.existingLogs);
    });
  }

  @override
  void dispose() {
    _o2Controller.dispose();
    _lelController.dispose();
    _coController.dispose();
    _h2sController.dispose();
    _locationController.dispose();
    _testerController.dispose();
    _certController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _syncValuesToNotifier() {
    final o2 = double.tryParse(_o2Controller.text) ?? 20.9;
    final lel = double.tryParse(_lelController.text) ?? 0.0;
    final co = double.tryParse(_coController.text) ?? 0.0;
    final h2s = double.tryParse(_h2sController.text) ?? 0.0;

    final notifier = ref.read(gasTrackerProvider.notifier);
    notifier.setOxygen(o2);
    notifier.setLel(lel);
    notifier.setCo(co);
    notifier.setH2s(h2s);
    notifier.setLocationPoint(_locationController.text.trim());
    notifier.setTestStage(_selectedStage);
    notifier.setTesterInfo(
      testerName: _testerController.text.trim(),
      certNo: _certController.text.trim(),
      detectorModel: _modelController.text.trim(),
      serialNo: _serialController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gasState = ref.watch(gasTrackerProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: Color(0xFFEDE9FE))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ระบบบันทึกและประเมินผลก๊าซในที่อับอากาศ (Live Gas Testing)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                      ),
                      Text(
                        'กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗: O2 (19.5-23.5%), LEL (<10%), CO (<25 ppm), H2S (<10 ppm)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Safety Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gasState.isCurrentAtmosphereSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gasState.isCurrentAtmosphereSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gasState.isCurrentAtmosphereSafe ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: gasState.isCurrentAtmosphereSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gasState.isCurrentAtmosphereSafe ? 'บรรยากาศปลอดภัย (PASS)' : 'บรรยากาศอันตราย (DANGER)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: gasState.isCurrentAtmosphereSafe ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error / Warning Callout if any
                if (gasState.activeErrors.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'แจ้งเตือนค่าก๊าซเกินเกณฑ์มาตรฐานตามกฎหมาย (ห้ามลงปฏิบัติงาน):',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              ...gasState.activeErrors.map(
                                (err) => Text('• $err', style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 4 Statutory Gas Gauges Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildGasInputTile(
                        label: 'ออกซิเจน (O₂)',
                        unit: '%',
                        standardText: 'เกณฑ์: 19.5 - 23.5%',
                        controller: _o2Controller,
                        currentValue: gasState.currentOxygen,
                        isSafe: gasState.currentOxygen >= 19.5 && gasState.currentOxygen <= 23.5,
                        icon: Icons.air,
                        accentColor: const Color(0xFF0284C7),
                        onChanged: (val) {
                          _syncValuesToNotifier();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGasInputTile(
                        label: 'ก๊าซไวไฟ (LEL)',
                        unit: '%',
                        standardText: 'เกณฑ์: < 10.0%',
                        controller: _lelController,
                        currentValue: gasState.currentLel,
                        isSafe: gasState.currentLel < 10.0,
                        icon: Icons.local_fire_department,
                        accentColor: const Color(0xFFEA580C),
                        onChanged: (val) {
                          _syncValuesToNotifier();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGasInputTile(
                        label: 'คาร์บอนมอนอกไซด์ (CO)',
                        unit: 'ppm',
                        standardText: 'เกณฑ์: < 25.0 ppm',
                        controller: _coController,
                        currentValue: gasState.currentCo,
                        isSafe: gasState.currentCo < 25.0,
                        icon: Icons.bubble_chart,
                        accentColor: const Color(0xFF8B5CF6),
                        onChanged: (val) {
                          _syncValuesToNotifier();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGasInputTile(
                        label: 'ไฮโดรเจนซัลไฟด์ (H₂S)',
                        unit: 'ppm',
                        standardText: 'เกณฑ์: < 10.0 ppm',
                        controller: _h2sController,
                        currentValue: gasState.currentH2s,
                        isSafe: gasState.currentH2s < 10.0,
                        icon: Icons.science,
                        accentColor: const Color(0xFFEAB308),
                        onChanged: (val) {
                          _syncValuesToNotifier();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Additional Info & Detector Metadata Inputs
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStage,
                        decoration: InputDecoration(
                          labelText: 'ขั้นตอนการตรวจวัด (Test Stage)',
                          prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PRE_ENTRY', child: Text('ก่อนเข้าทำงาน (Pre-entry)')),
                          DropdownMenuItem(value: 'CONTINUOUS', child: Text('ระหว่างทำงานต่อเนื่อง (Continuous)')),
                          DropdownMenuItem(value: 'POST_WORK', child: Text('หลังเลิกงาน (Post-work)')),
                        ],
                        onChanged: widget.isReadOnly
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedStage = val);
                                  _syncValuesToNotifier();
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _locationController,
                        readOnly: widget.isReadOnly,
                        decoration: InputDecoration(
                          labelText: 'ตำแหน่งจุดตรวจวัด (Sampling Location Point)',
                          hintText: 'e.g. ก้นถังไซโล จุดที่ 1 (ระดับลึก 3 เมตร)',
                          prefixIcon: const Icon(Icons.place_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => _syncValuesToNotifier(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testerController,
                        readOnly: widget.isReadOnly,
                        decoration: InputDecoration(
                          labelText: 'ชื่อผู้ตรวจวัด (Tester Name)',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => _syncValuesToNotifier(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _modelController,
                        readOnly: widget.isReadOnly,
                        decoration: InputDecoration(
                          labelText: 'รุ่นเครื่องตรวจวัด (Detector Model)',
                          prefixIcon: const Icon(Icons.devices_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => _syncValuesToNotifier(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _serialController,
                        readOnly: widget.isReadOnly,
                        decoration: InputDecoration(
                          labelText: 'หมายเลขเครื่อง (Serial No.)',
                          prefixIcon: const Icon(Icons.tag_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => _syncValuesToNotifier(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Record Action Button
                if (!widget.isReadOnly) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              _syncValuesToNotifier();
                              final newLog = await ref.read(gasTrackerProvider.notifier).recordReading();
                              widget.onLogSaved?.call(newLog);
                              setState(() => _isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('บันทึกผลการตรวจวัดก๊าซ (${newLog.logId}) เรียบร้อย'),
                                    backgroundColor: newLog.isSafe ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text('บันทึกผลการตรวจวัด (Record Log)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],

                // Logs History Table
                if (gasState.logs.isNotEmpty) ...[
                  const Divider(height: 32, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ประวัติการตรวจวัดก๊าซ (${gasState.logs.length} รายการ)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'บันทึกล่าสุด: ${gasState.logs.last.testTimestamp.replaceFirst('T', ' ').substring(0, 16)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.4),
                          2: FlexColumnWidth(1.0),
                          3: FlexColumnWidth(1.0),
                          4: FlexColumnWidth(1.0),
                          5: FlexColumnWidth(1.0),
                          6: FlexColumnWidth(1.2),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              _buildHeaderCell('เวลาตรวจวัด'),
                              _buildHeaderCell('ขั้นตอน / จุดตรวจ'),
                              _buildHeaderCell('O₂ (%)'),
                              _buildHeaderCell('LEL (%)'),
                              _buildHeaderCell('CO (ppm)'),
                              _buildHeaderCell('H₂S (ppm)'),
                              _buildHeaderCell('ผลประเมิน'),
                            ],
                          ),
                          ...gasState.logs.map((log) {
                            final timeStr = log.testTimestamp.contains('T')
                                ? log.testTimestamp.split('T').last.substring(0, 5)
                                : log.testTimestamp;
                            return TableRow(
                              decoration: BoxDecoration(
                                color: log.isSafe ? Colors.white : const Color(0xFFFEF2F2),
                                border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                              ),
                              children: [
                                _buildDataCell(timeStr),
                                _buildDataCell('${log.testStage}\n${log.locationPoint}', isSmall: true),
                                _buildDataCell('${log.oxygenPercent.toStringAsFixed(1)}%', isBold: true),
                                _buildDataCell('${log.combustiblePercentLel.toStringAsFixed(1)}%', isBold: true),
                                _buildDataCell('${log.carbonMonoxidePpm.toStringAsFixed(1)}', isBold: true),
                                _buildDataCell('${log.hydrogenSulfidePpm.toStringAsFixed(1)}', isBold: true),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: log.isSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        log.isSafe ? 'ปลอดภัย' : 'อันตราย',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: log.isSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGasInputTile({
    required String label,
    required String unit,
    required String standardText,
    required TextEditingController controller,
    required double currentValue,
    required bool isSafe,
    required IconData icon,
    required Color accentColor,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSafe ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSafe ? const Color(0xFFE2E8F0) : const Color(0xFFEF4444),
          width: isSafe ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isSafe ? accentColor : const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? const Color(0xFF334155) : const Color(0xFF991B1B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  readOnly: widget.isReadOnly,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            standardText,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isSafe ? const Color(0xFF64748B) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
