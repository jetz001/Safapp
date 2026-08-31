import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accident_models.dart';
import '../providers/accident_providers.dart';

class AccidentInvestigationWizardDialog extends ConsumerStatefulWidget {
  final AccidentInvestigation investigation;

  const AccidentInvestigationWizardDialog({
    Key? key,
    required this.investigation,
  }) : super(key: key);

  @override
  ConsumerState<AccidentInvestigationWizardDialog> createState() => _AccidentInvestigationWizardDialogState();
}

class _AccidentInvestigationWizardDialogState extends ConsumerState<AccidentInvestigationWizardDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // 1. 5W 1H & Timeline
  late TextEditingController _desc5w1hController;
  late TextEditingController _machineController;
  late TextEditingController _chemicalController;
  late TextEditingController _workProcessController;
  late TextEditingController _witnessController;
  final List<AccidentTimelineItem> _timeline = [];
  final TextEditingController _newTimelineTimeController = TextEditingController();
  final TextEditingController _newTimelineActionController = TextEditingController();

  // 2. Causation 3 Factors
  final List<String> _unsafeActs = [];
  final List<String> _unsafeConditions = [];
  final List<String> _managementErrors = [];
  final TextEditingController _customActController = TextEditingController();
  final TextEditingController _customCondController = TextEditingController();
  final TextEditingController _customMgmtController = TextEditingController();
  late TextEditingController _rootCauseController;

  // 3. Loss & Medical
  late TextEditingController _daysLostController;
  late TextEditingController _medicalExpenseController;
  late TextEditingController _propertyDamageController;
  late TextEditingController _wageController;
  late TextEditingController _ageController;

  // 4. Laws & Sign-off
  final List<String> _applicableLaws = [];
  late TextEditingController _inspectorNameController;
  late TextEditingController _inspectorPositionController;
  String _status = 'INVESTIGATING';
  bool _isSaving = false;

  final List<String> _presetUnsafeActs = [
    'ปฏิบัติงานโดยไม่สวมใส่อุปกรณ์ PPE ที่กำหนด',
    'ซ่อมแซม/ทำความสะอาดเครื่องจักรขณะเครื่องกำลังหมุนโดยไม่ตัดไฟ/LOTO',
    'ก้าวพลาด / ทรงตัวบนพื้นที่ไม่มั่นคง / ใช้อุปกรณ์ผิดประเภท',
    'ปฏิบัติงานข้ามขั้นตอนตามมาตรฐาน SOP / ทำงานด้วยความรีบเร่ง',
    'ปฏิบัติงานในตำแหน่งที่ไม่มีหน้าที่รับผิดชอบโดยตรง',
    'ยกสิ่งของหนักเกินเกณฑ์มาตรฐาน หรือท่าทางการยกไม่ถูกต้อง',
    'หยอกล้อ หรือขาดความระมัดระวังขณะปฏิบัติหน้าที่',
  ];

  final List<String> _presetUnsafeConditions = [
    'เครื่องจักรไม่มีฝาครอบปิดคลุมจุดหมุน/สายพาน (Machine Guarding)',
    'ไม่มีปุ่มหยุดเครื่องจักรฉุกเฉิน (Emergency Stop) หรือปุ่มชำรุด',
    'พื้นทางเดินเปียก ลื่น มีน้ำมันหรือเศษวัสดุตกหล่น',
    'สภาพแสงสว่างไม่เพียงพอ หรือมีการระบายอากาศไม่เหมาะสม',
    'ขุดดิน/บ่อลึกเกิน ๒ เมตร โดยไม่มีค้ำยันหรือทำมุมลาดเอียงป้องกันดินพัง',
    'นั่งร้านหรือบันไดทำงานบนที่สูงไม่มั่นคงแข็งแรง / ไม่มีราวกั้น',
    'ระบบไฟฟ้า/สายไฟชำรุด หรือไม่มีระบบตัดไฟรั่ว (RCD)',
  ];

  final List<String> _presetManagementErrors = [
    'ขาดขั้นตอนการปฏิบัติงานที่ปลอดภัย (SOP / JSA) เป็นลายลักษณ์อักษร',
    'ขาดการฝึกอบรมความปลอดภัยเฉพาะทางก่อนมอบหมายงาน',
    'หัวหน้างานขาดการกำกับดูแลและตรวจสอบความปลอดภัยประจำวัน',
    'ไม่มีการประเมินความเสี่ยงจากอันตราย (Hazard Identification) ครอบคลุม',
    'ขาดระบบการบำรุงรักษาเชิงป้องกัน (Preventive Maintenance)',
    'การจัดอัตรากำลังคนไม่เพียงพอกับภาระงาน',
  ];

  final List<String> _presetLaws = [
    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๑๔ (แจ้งอันตรายและแจกคู่มือปฏิบัติงาน)',
    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๑๖ (จัดฝึกอบรมความปลอดภัยลูกจ้าง)',
    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๓๒ (ประเมินอันตรายและจัดทำแผนความปลอดภัย)',
    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๓๔ (แจ้งอุบัติภัยร้ายแรงต่อพนักงานตรวจฯ ภายใน ๗ วัน)',
    'กฎกระทรวงเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๕๒ (การปิดคลุมส่วนที่หมุนได้)',
    'กฎกระทรวงงานก่อสร้าง พ.ศ. ๒๕๕๑ (งานขุดเจาะ ค้ำยัน และการป้องกันดินพัง)',
    'กฎกระทรวงความปลอดภัยเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘',
    'กฎกระทรวงป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final inv = widget.investigation;

    _desc5w1hController = TextEditingController(text: inv.description5w1h ?? '');
    _machineController = TextEditingController(text: inv.machineInvolved ?? '');
    _chemicalController = TextEditingController(text: inv.chemicalInvolved ?? '');
    _workProcessController = TextEditingController(text: inv.workProcessInvolved ?? '');
    _witnessController = TextEditingController(text: inv.witnessNames ?? '');
    _timeline.addAll(inv.timelineEvents);

    _unsafeActs.addAll(inv.unsafeActs);
    _unsafeConditions.addAll(inv.unsafeConditions);
    _managementErrors.addAll(inv.managementErrors);
    _rootCauseController = TextEditingController(text: inv.rootCauseSummary ?? '');

    _daysLostController = TextEditingController(text: '${inv.daysLost}');
    _medicalExpenseController = TextEditingController(text: '${inv.medicalExpense}');
    _propertyDamageController = TextEditingController(text: '${inv.propertyDamageCost}');
    _wageController = TextEditingController(text: inv.injuredPersonWage != null ? '${inv.injuredPersonWage}' : '15000');
    _ageController = TextEditingController(text: inv.injuredPersonAge != null ? '${inv.injuredPersonAge}' : '30');

    _applicableLaws.addAll(inv.applicableLaws);
    _inspectorNameController = TextEditingController(text: inv.inspectorName ?? 'จป.วิชาชีพ ประจำโรงงาน');
    _inspectorPositionController = TextEditingController(text: inv.inspectorPosition ?? 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ');
    _status = inv.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _desc5w1hController.dispose();
    _machineController.dispose();
    _chemicalController.dispose();
    _workProcessController.dispose();
    _witnessController.dispose();
    _newTimelineTimeController.dispose();
    _newTimelineActionController.dispose();
    _customActController.dispose();
    _customCondController.dispose();
    _customMgmtController.dispose();
    _rootCauseController.dispose();
    _daysLostController.dispose();
    _medicalExpenseController.dispose();
    _propertyDamageController.dispose();
    _wageController.dispose();
    _ageController.dispose();
    _inspectorNameController.dispose();
    _inspectorPositionController.dispose();
    super.dispose();
  }

  void _addTimelineItem() {
    if (_newTimelineTimeController.text.isEmpty || _newTimelineActionController.text.isEmpty) return;
    setState(() {
      _timeline.add(AccidentTimelineItem(
        time: _newTimelineTimeController.text.trim(),
        action: _newTimelineActionController.text.trim(),
      ));
      _newTimelineTimeController.clear();
      _newTimelineActionController.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.investigation.copyWith(
        description5w1h: _desc5w1hController.text.trim(),
        machineInvolved: _machineController.text.trim().isEmpty ? null : _machineController.text.trim(),
        chemicalInvolved: _chemicalController.text.trim().isEmpty ? null : _chemicalController.text.trim(),
        workProcessInvolved: _workProcessController.text.trim().isEmpty ? null : _workProcessController.text.trim(),
        witnessNames: _witnessController.text.trim().isEmpty ? null : _witnessController.text.trim(),
        timelineEvents: _timeline,
        unsafeActs: _unsafeActs,
        unsafeConditions: _unsafeConditions,
        managementErrors: _managementErrors,
        rootCauseSummary: _rootCauseController.text.trim().isEmpty ? null : _rootCauseController.text.trim(),
        daysLost: int.tryParse(_daysLostController.text.trim()) ?? 0,
        medicalExpense: double.tryParse(_medicalExpenseController.text.trim()) ?? 0.0,
        propertyDamageCost: double.tryParse(_propertyDamageController.text.trim()) ?? 0.0,
        injuredPersonWage: double.tryParse(_wageController.text.trim()),
        injuredPersonAge: int.tryParse(_ageController.text.trim()),
        applicableLaws: _applicableLaws,
        inspectorName: _inspectorNameController.text.trim().isEmpty ? null : _inspectorNameController.text.trim(),
        inspectorPosition: _inspectorPositionController.text.trim().isEmpty ? null : _inspectorPositionController.text.trim(),
        status: _status,
      );

      await ref.read(accidentInvestigationsProvider.notifier).saveInvestigation(updated);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('บันทึกผลการสอบสวนและวิเคราะห์อุบัติเหตุเรียบร้อยแล้ว'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.investigation;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Container(
        width: 880,
        height: 750,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.manage_search_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แบบบันทึกการสอบสวนและวิเคราะห์สาเหตุอุบัติเหตุ (${inv.eventNo})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${inv.incidentTitle}  |  ${inv.eventTypeLabel}  |  ผู้ประสบเหตุ: ${inv.injuredPersonName ?? "ไม่มีผู้บาดเจ็บ"}',
                          style: TextStyle(fontSize: 11.5, color: Colors.blue.shade100),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            // Tabs Bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.format_list_numbered, size: 18), text: '๑. ลำดับเหตุการณ์ 5W1H'),
                Tab(icon: Icon(Icons.psychology, size: 18), text: '๒. วิเคราะห์ ๓ ปัจจัยสาเหตุ'),
                Tab(icon: Icon(Icons.medical_services_outlined, size: 18), text: '๓. ความสูญเสีย & การรักษา'),
                Tab(icon: Icon(Icons.gavel_rounded, size: 18), text: '๔. ข้อกฎหมาย & ลงนาม'),
              ],
            ),
            const Divider(height: 1),

            // Tab Body
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab1Timeline5w1h(),
                    _buildTab2CausationAnalysis(),
                    _buildTab3LossesAndMedical(),
                    _buildTab4LawsAndSignoff(),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'INVESTIGATING', child: Text('🟡 กำลังสอบสวน (Investigating)')),
                      DropdownMenuItem(value: 'CAPA_PENDING', child: Text('🟠 รอมาตรการแก้ไข (CAPA Pending)')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('🟢 ปิดการสอบสวนสมบูรณ์ (Closed)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกผลการสอบสวน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: 5W1H & TIMELINE
  // --------------------------------------------------------------------------
  Widget _buildTab1Timeline5w1h() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. ข้อมูลสภาพแวดล้อม เครื่องจักร และกระบวนการทำงาน'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _machineController,
                  decoration: _inputDecoration('เครื่องจักร / เครื่องมือที่เกี่ยวข้อง', icon: Icons.precision_manufacturing),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _chemicalController,
                  decoration: _inputDecoration('สารเคมี / วัตถุอันตราย (ถ้ามี)', icon: Icons.science_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _workProcessController,
            decoration: _inputDecoration('ขั้นตอนและกระบวนการทำงานขณะเกิดเหตุ', icon: Icons.account_tree_outlined),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. รายละเอียดการเกิดอุบัติเหตุตามหลัก 5W 1H'),
          TextFormField(
            controller: _desc5w1hController,
            maxLines: 4,
            decoration: _inputDecoration('อธิบาย Who (ใคร), What (อะไร), Where (ที่ไหน), When (เมื่อไร), Why (ทำไม), How (อย่างไร) *', icon: Icons.description),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _witnessController,
            decoration: _inputDecoration('พยานบุคคลที่เห็นเหตุการณ์ / ผู้ร่วมงาน', icon: Icons.group),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๓. ลำดับเหตุการณ์ตามเวลา (Timeline Events)'),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _newTimelineTimeController,
                  decoration: _inputDecoration('เวลา (น.)', icon: Icons.access_time),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _newTimelineActionController,
                  decoration: _inputDecoration('เหตุการณ์ / การกระทำที่เกิดขึ้น'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _addTimelineItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('เพิ่ม'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
          if (_timeline.isNotEmpty) ...[
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeline.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (ctx, idx) {
                final item = _timeline[idx];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text('${item.time} น.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.action, style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _timeline.removeAt(idx)),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: CAUSATION ANALYSIS (3 FACTORS)
  // --------------------------------------------------------------------------
  Widget _buildTab2CausationAnalysis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Unsafe Acts
          _buildSectionHeader('๑. ปัจจัยด้านบุคคล / การกระทำที่ไม่ปลอดภัย (Unsafe Acts / Substandard Acts)'),
          ..._presetUnsafeActs.map((act) {
            final isChecked = _unsafeActs.contains(act);
            return CheckboxListTile(
              dense: true,
              title: Text(act, style: const TextStyle(fontSize: 12)),
              value: isChecked,
              activeColor: Colors.red.shade700,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _unsafeActs.add(act);
                  } else {
                    _unsafeActs.remove(act);
                  }
                });
              },
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customActController,
                  decoration: _inputDecoration('ระบุการกระทำที่ไม่ปลอดภัยเพิ่มเติม'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  if (_customActController.text.trim().isNotEmpty) {
                    setState(() {
                      _unsafeActs.add(_customActController.text.trim());
                      _customActController.clear();
                    });
                  }
                },
                child: const Text('เพิ่ม'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Unsafe Conditions
          _buildSectionHeader('๒. ปัจจัยด้านสภาพแวดล้อม / เครื่องจักร / สภาพที่ไม่ปลอดภัย (Unsafe Conditions)'),
          ..._presetUnsafeConditions.map((cond) {
            final isChecked = _unsafeConditions.contains(cond);
            return CheckboxListTile(
              dense: true,
              title: Text(cond, style: const TextStyle(fontSize: 12)),
              value: isChecked,
              activeColor: Colors.orange.shade800,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _unsafeConditions.add(cond);
                  } else {
                    _unsafeConditions.remove(cond);
                  }
                });
              },
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customCondController,
                  decoration: _inputDecoration('ระบุสภาพที่ไม่ปลอดภัยเพิ่มเติม'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  if (_customCondController.text.trim().isNotEmpty) {
                    setState(() {
                      _unsafeConditions.add(_customCondController.text.trim());
                      _customCondController.clear();
                    });
                  }
                },
                child: const Text('เพิ่ม'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Management Errors
          _buildSectionHeader('๓. ปัจจัยด้านการบริหารจัดการ / ระบบควบคุม (Management Errors / Lack of Control)'),
          ..._presetManagementErrors.map((mgmt) {
            final isChecked = _managementErrors.contains(mgmt);
            return CheckboxListTile(
              dense: true,
              title: Text(mgmt, style: const TextStyle(fontSize: 12)),
              value: isChecked,
              activeColor: const Color(0xFF1E3A8A),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _managementErrors.add(mgmt);
                  } else {
                    _managementErrors.remove(mgmt);
                  }
                });
              },
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customMgmtController,
                  decoration: _inputDecoration('ระบุข้อบกพร่องด้านบริหารจัดการเพิ่มเติม'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  if (_customMgmtController.text.trim().isNotEmpty) {
                    setState(() {
                      _managementErrors.add(_customMgmtController.text.trim());
                      _customMgmtController.clear();
                    });
                  }
                },
                child: const Text('เพิ่ม'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๔. สรุปสาเหตุรากเหง้า (Root Cause Summary)'),
          TextFormField(
            controller: _rootCauseController,
            maxLines: 3,
            decoration: _inputDecoration('สรุปสาเหตุรากเหง้าที่แท้จริงตาม Loss Causation Model / Swiss Cheese Model', icon: Icons.lightbulb_outline),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: LOSSES & MEDICAL
  // --------------------------------------------------------------------------
  Widget _buildTab3LossesAndMedical() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. ข้อมูลลูกจ้างสำหรับแบบ กท. ๑๖ และ กท. ๔๔'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('อายุผู้ประสบเหตุ (ปี)', icon: Icons.cake_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('อัตราค่าจ้าง (บาท/เดือน)', icon: Icons.monetization_on_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. การหยุดงานและความสูญเสียทางเศรษฐศาสตร์'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _daysLostController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('จำนวนวันหยุดงาน (วัน)', icon: Icons.event_busy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicalExpenseController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ค่ารักษาพยาบาล (บาท)', icon: Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _propertyDamageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ทรัพย์สินเสียหาย (บาท)', icon: Icons.car_crash_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: LAWS & SIGN-OFF
  // --------------------------------------------------------------------------
  Widget _buildTab4LawsAndSignoff() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. กฎหมายความปลอดภัยที่เกี่ยวข้อง (สำหรับรายงานทางการ และ สปร. ๕)'),
          ..._presetLaws.map((law) {
            final isChecked = _applicableLaws.contains(law);
            return CheckboxListTile(
              dense: true,
              title: Text(law, style: const TextStyle(fontSize: 12)),
              value: isChecked,
              activeColor: const Color(0xFF1E3A8A),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _applicableLaws.add(law);
                  } else {
                    _applicableLaws.remove(law);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. ข้อมูลผู้สอบสวนและผู้ลงนามรับรอง'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inspectorNameController,
                  decoration: _inputDecoration('ชื่อ - นามสกุล ผู้สอบสวน (จป.)', icon: Icons.person_pin),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _inspectorPositionController,
                  decoration: _inputDecoration('ตำแหน่งผู้สอบสวน', icon: Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
    );
  }
}
