import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/risk_matrix_criteria.dart';
import '../providers/risk_assessment_providers.dart';
import '../widgets/hazard_item_editor_dialog.dart';
import '../widgets/session_edit_dialog.dart';
import 'official_report_preview_page.dart';

class WorkstationHazardEditorPage extends ConsumerStatefulWidget {
  final int sessionId;

  const WorkstationHazardEditorPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  ConsumerState<WorkstationHazardEditorPage> createState() => _WorkstationHazardEditorPageState();
}

class _WorkstationHazardEditorPageState extends ConsumerState<WorkstationHazardEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<WorkStation> _workstations = [];
  WorkStation? _selectedStation;

  List<WorkStepItem> _steps = [];
  WorkStepItem? _selectedStep;

  List<HazardEvaluationPor1> _hazards = [];
  Map<int, RiskControlPlanPor2?> _plansByHazardId = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != 0) {
        ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(riskAssessmentRepoProvider);

    final stations = await repo.getWorkstationsBySession(widget.sessionId);
    _workstations = stations;

    if (_selectedStation == null && stations.isNotEmpty) {
      _selectedStation = stations.first;
    } else if (_selectedStation != null) {
      final exists = stations.any((s) => s.id == _selectedStation!.id);
      if (!exists && stations.isNotEmpty) _selectedStation = stations.first;
      if (!exists && stations.isEmpty) _selectedStation = null;
    }

    if (_selectedStation != null) {
      await _loadStepsForStation(_selectedStation!.id!);
    } else {
      _steps = [];
      _selectedStep = null;
      _hazards = [];
      _plansByHazardId = {};
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadStepsForStation(int stationId) async {
    final repo = ref.read(riskAssessmentRepoProvider);
    final steps = await repo.getStepsByWorkstation(stationId);

    WorkStepItem? nextStep;
    if (_selectedStep == null && steps.isNotEmpty) {
      nextStep = steps.first;
    } else if (_selectedStep != null) {
      final exists = steps.any((st) => st.id == _selectedStep!.id);
      if (exists) {
        nextStep = _selectedStep;
      } else if (steps.isNotEmpty) {
        nextStep = steps.first;
      } else {
        nextStep = null;
      }
    }

    List<HazardEvaluationPor1> hazards = [];
    final Map<int, RiskControlPlanPor2?> plans = {};
    if (nextStep != null && nextStep.id != null) {
      hazards = await repo.getHazardsByStep(nextStep.id!);
      for (final h in hazards) {
        if (h.requiresPor2 && h.id != null) {
          final plan = await repo.getPlanByHazard(h.id!);
          plans[h.id!] = plan;
        }
      }
    }

    if (mounted) {
      setState(() {
        _steps = steps;
        _selectedStep = nextStep;
        _hazards = hazards;
        _plansByHazardId = plans;
      });
    }
  }

  Future<void> _loadHazardsForStep(int stepId) async {
    final repo = ref.read(riskAssessmentRepoProvider);
    final hazards = await repo.getHazardsByStep(stepId);

    final Map<int, RiskControlPlanPor2?> plans = {};
    for (final h in hazards) {
      if (h.requiresPor2 && h.id != null) {
        final plan = await repo.getPlanByHazard(h.id!);
        plans[h.id!] = plan;
      }
    }

    if (mounted) {
      setState(() {
        _hazards = hazards;
        _plansByHazardId = plans;
      });
    }
  }

  // --------------------------------------------------------------------------
  // WORKSTATION CRUD
  // --------------------------------------------------------------------------
  Future<void> _showAddWorkstationDialog({WorkStation? existing}) async {
    final deptController = TextEditingController(text: existing?.departmentName ?? '');
    final nameController = TextEditingController(text: existing?.stationName ?? '');
    final countController = TextEditingController(text: '${existing?.employeeCount ?? 1}');
    final descController = TextEditingController(text: existing?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'เพิ่มสถานีงาน / กระบวนการ' : 'แก้ไขสถานีงาน'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'ฝ่าย / แผนก *',
                  hintText: 'เช่น ฝ่ายผลิต, แผนกซ่อมบำรุง, แผนกคลังสินค้า',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสถานีงาน / พื้นที่ปฏิบัติงาน *',
                  hintText: 'เช่น สถานีตัดเหล็ก, สถานีผสมสารเคมี, ลานโหลดสินค้า',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนลูกจ้างประจำสถานี (คน)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดเพิ่มเติม / สภาพแวดล้อม',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (deptController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result == true) {
      final repo = ref.read(riskAssessmentRepoProvider);
      final station = WorkStation(
        id: existing?.id,
        sessionId: widget.sessionId,
        departmentName: deptController.text.trim(),
        stationName: nameController.text.trim(),
        employeeCount: int.tryParse(countController.text.trim()) ?? 1,
        description: descController.text.trim(),
      );
      await repo.saveWorkstation(station);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      await _loadData();
    }
  }

  Future<void> _deleteWorkstation(WorkStation station) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบสถานีงาน'),
        content: Text('ต้องการลบสถานีงาน "${station.stationName}" และขั้นตอน/รายการประเมินทั้งหมดในสถานีนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && station.id != null) {
      final repo = ref.read(riskAssessmentRepoProvider);
      await repo.deleteWorkstation(station.id!);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      await _loadData();
    }
  }

  // --------------------------------------------------------------------------
  // WORK STEP / MACHINERY CRUD
  // --------------------------------------------------------------------------
  Future<void> _showAddStepDialog({WorkStepItem? existing}) async {
    if (_selectedStation == null) return;

    final nameController = TextEditingController(text: existing?.stepName ?? '');
    final machineController = TextEditingController(text: existing?.relatedMachineryEquipment ?? '');
    final numberController = TextEditingController(text: '${existing?.stepNumber ?? (_steps.length + 1)}');
    final descController = TextEditingController(text: existing?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'เพิ่มขั้นตอนการทำงาน / เครื่องจักร' : 'แก้ไขขั้นตอนการทำงาน'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ลำดับขั้น',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ขั้นตอนและวิธีการปฏิบัติงาน *',
                        hintText: 'เช่น ป้อนชิ้นงานเข้าเครื่องปั๊ม, ถ่ายเทกรดไฮโดรคลอริก',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: machineController,
                decoration: const InputDecoration(
                  labelText: 'เครื่องจักร / เครื่องมือ / อุปกรณ์ที่เกี่ยวข้อง',
                  hintText: 'เช่น เครื่องปั๊มไฮดรอลิก 50T, ปั๊มสารเคมี, รถ Forklift',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดวิธีปฏิบัติ / มาตรฐานที่เกี่ยวข้อง',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result == true && _selectedStation?.id != null) {
      final repo = ref.read(riskAssessmentRepoProvider);
      final step = WorkStepItem(
        id: existing?.id,
        workstationId: _selectedStation!.id!,
        stepNumber: int.tryParse(numberController.text.trim()) ?? (_steps.length + 1),
        stepName: nameController.text.trim(),
        relatedMachineryEquipment: machineController.text.trim(),
        description: descController.text.trim(),
      );
      await repo.saveWorkStep(step);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      await _loadStepsForStation(_selectedStation!.id!);
      setState(() {});
    }
  }

  Future<void> _deleteStep(WorkStepItem step) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบขั้นตอน'),
        content: Text('ต้องการลบขั้นตอน "${step.stepName}" และรายการประเมินความเสี่ยงทั้งหมดในขั้นตอนนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && step.id != null && _selectedStation?.id != null) {
      final repo = ref.read(riskAssessmentRepoProvider);
      await repo.deleteWorkStep(step.id!);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      await _loadStepsForStation(_selectedStation!.id!);
      setState(() {});
    }
  }

  // --------------------------------------------------------------------------
  // HAZARD & POR 1 / POR 2 CRUD
  // --------------------------------------------------------------------------
  Future<void> _openHazardEditor({HazardEvaluationPor1? existingHazard}) async {
    if (_selectedStep == null) return;

    final plan = existingHazard != null ? _plansByHazardId[existingHazard.id] : null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HazardItemEditorDialog(
        stepId: _selectedStep!.id!,
        stepName: _selectedStep!.stepName,
        existingHazard: existingHazard,
        existingPlan: plan,
      ),
    );

    if (result == true) {
      await _loadHazardsForStep(_selectedStep!.id!);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      setState(() {});
    }
  }

  Future<void> _deleteHazard(HazardEvaluationPor1 hazard) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบรายการประเมิน'),
        content: Text('ต้องการลบรายการอันตราย "${hazard.hazardItemTitle}" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && hazard.id != null && _selectedStep?.id != null) {
      final repo = ref.read(riskAssessmentRepoProvider);
      await repo.deleteHazardPor1(hazard.id!);
      ref.invalidate(sessionReportRowsProvider(widget.sessionId));
      ref.invalidate(riskSessionsProvider);
      await _loadHazardsForStep(_selectedStep!.id!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: sessionAsync.when(
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s?.sessionTitle ?? 'ระบบประเมินอันตราย (ปอ.๑ & ปอ.๒)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'วันที่ประเมิน: ${s?.assessmentDate ?? "-"}  |  วิธี: ${s?.hazardIdMethod ?? "-"}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          loading: () => const Text('กำลังโหลด...'),
          error: (err, _) => const Text('เกิดข้อผิดพลาด'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: () async {
              await _loadData();
              ref.invalidate(sessionReportRowsProvider(widget.sessionId));
              ref.invalidate(sessionDetailProvider(widget.sessionId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('รีเฟรชข้อมูลเรียบร้อยแล้ว'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('แก้ไขข้อมูลชุดประเมิน'),
            onPressed: () async {
              final s = sessionAsync.value;
              if (s != null) {
                await showDialog(
                  context: context,
                  builder: (ctx) => SessionEditDialog(existingSession: s),
                );
                ref.invalidate(sessionDetailProvider(widget.sessionId));
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('พรีวิว & ส่งออกรายงานทางการ (PDF / Excel)'),
            onPressed: () {
              ref.invalidate(sessionReportRowsProvider(widget.sessionId));
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OfficialReportPreviewPage(sessionId: widget.sessionId),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade800,
          indicatorWeight: 3,
          onTap: (index) {
            ref.invalidate(sessionReportRowsProvider(widget.sessionId));
            if (index == 0) {
              _loadData();
            }
          },
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_rounded, size: 20), text: 'โครงสร้างสถานีงาน & ชี้บ่งอันตราย'),
            Tab(icon: Icon(Icons.table_chart_rounded, size: 20), text: 'ตารางผลการประเมินอันตราย (แบบ ปอ. ๑)'),
            Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 20), text: 'ตารางแผนควบคุมความเสี่ยง (แบบ ปอ. ๒)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHierarchyEditorTab(),
                _buildPor1TableTab(),
                _buildPor2TableTab(),
              ],
            ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: 4-LEVEL HIERARCHY EDITOR
  // --------------------------------------------------------------------------
  Widget _buildHierarchyEditorTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Left Column: Workstations & Processes List
        SizedBox(
          width: 300,
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business_center_rounded, color: Colors.blue.shade800, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '๑. สถานีงาน / กระบวนการ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                        tooltip: 'เพิ่มสถานีงาน',
                        onPressed: () => _showAddWorkstationDialog(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _workstations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_business_outlined, size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'ยังไม่มีสถานีงาน\nกดปุ่ม + เพื่อเพิ่มสถานีงานแรก',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _workstations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            if (idx >= _workstations.length) return const SizedBox.shrink();
                            final st = _workstations[idx];
                            final isSelected = _selectedStation?.id == st.id;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50.withValues(alpha: 0.5),
                              title: Text(
                                st.stationName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${st.departmentName} (${st.employeeCount} คน)',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                    onPressed: () => _showAddWorkstationDialog(existing: st),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                    onPressed: () => _deleteWorkstation(st),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedStation = st;
                                });
                                _loadStepsForStation(st.id!);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // 2. Middle Column: Work Steps & Machinery
        SizedBox(
          width: 320,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing_rounded, color: Colors.amber.shade900, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '๒. ขั้นตอนงาน / เครื่องจักร',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.amber, size: 20),
                        tooltip: 'เพิ่มขั้นตอนงาน',
                        onPressed: _selectedStation == null ? null : () => _showAddStepDialog(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedStation == null
                      ? const Center(child: Text('กรุณาเลือกสถานีงานทางซ้ายก่อน', style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : _steps.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.playlist_add_rounded, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ยังไม่มีขั้นตอนการทำงาน\nกดปุ่ม + เพื่อเพิ่มขั้นตอน/เครื่องจักร',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _steps.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                if (idx >= _steps.length) return const SizedBox.shrink();
                                final stp = _steps[idx];
                                final isSelected = _selectedStep?.id == stp.id;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: Colors.amber.shade50.withValues(alpha: 0.5),
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.amber.shade200,
                                    child: Text(
                                      '${stp.stepNumber}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  ),
                                  title: Text(
                                    stp.stepName,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  subtitle: stp.relatedMachineryEquipment != null && stp.relatedMachineryEquipment!.isNotEmpty
                                      ? Text('เครื่องจักร: ${stp.relatedMachineryEquipment}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey))
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                        onPressed: () => _showAddStepDialog(existing: stp),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                        onPressed: () => _deleteStep(stp),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedStep = stp;
                                    });
                                    _loadHazardsForStep(stp.id!);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),

        // 3. Right Pane: Hazard Evaluations (ปอ.๑) & Control Plans (ปอ.๒)
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red.shade800, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selectedStep == null
                            ? '๓. รายการชี้บ่งอันตราย & แผนควบคุม'
                            : '๓. รายการอันตราย: ${_selectedStep!.stepName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ชี้บ่งและประเมินอันตราย (ปอ.๑)', style: TextStyle(fontSize: 12)),
                        onPressed: _selectedStep == null ? null : () => _openHazardEditor(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedStep == null
                      ? const Center(child: Text('กรุณาเลือกขั้นตอนการทำงานตรงกลางก่อน', style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : _hazards.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.security_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'ยังไม่มีรายการชี้บ่งอันตรายในขั้นตอนนี้',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'กดปุ่ม "+ ชี้บ่งและประเมินอันตราย" เพื่อระบุสิ่งอันตราย ประเมินคะแนน 3x3 และจัดทำแผน ปอ.๒',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _hazards.length,
                              itemBuilder: (ctx, idx) {
                                if (idx >= _hazards.length) return const SizedBox.shrink();
                                final h = _hazards[idx];
                                final plan = _plansByHazardId[h.id];
                                final eval = RiskMatrixCriteria.evaluate(h.likelihoodScore, h.severityScore);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: eval.color.withValues(alpha: 0.5), width: 1.2),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Hazard Title & Risk Badge
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                h.hazardItemTitle,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: eval.color,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${eval.thaiName} (${eval.score} คะแนน)',
                                                style: TextStyle(
                                                  color: eval.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                              onPressed: () => _openHazardEditor(existingHazard: h),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                              onPressed: () => _deleteHazard(h),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('● ผลกระทบ: ${h.potentialConsequences}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        if (h.existingControlMeasures != null && h.existingControlMeasures!.isNotEmpty)
                                          Text('● มาตรการป้องกันเดิม: ${h.existingControlMeasures}', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                        if (h.recommendation != null && h.recommendation!.isNotEmpty)
                                          Text('● ข้อเสนอแนะ: ${h.recommendation}', style: const TextStyle(fontSize: 11, color: Colors.indigo)),

                                        // Por 2 Plan Section if applicable
                                        if (h.requiresPor2) ...[
                                          const Divider(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.amber.shade400),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.assignment_turned_in, size: 14, color: Colors.amber.shade900),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'แผน ปอ.๒: ${plan?.controlPlanDescription ?? h.recommendation ?? "ยังไม่ได้ระบุมาตรการ"}',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ผู้รับผิดชอบ: ${plan?.responsiblePerson ?? "-"} | ผู้ตรวจติดตาม: ${plan?.supervisorMonitor ?? "-"} | ระยะเวลา: ${plan?.startDate ?? "-"} ถึง ${plan?.endDate ?? "-"}',
                                                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: POR 1 TABLE VIEW
  // --------------------------------------------------------------------------
  Widget _buildPor1TableTab() {
    final rowsAsync = ref.watch(sessionReportRowsProvider(widget.sessionId));

    return rowsAsync.when(
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('ยังไม่มีรายการประเมินในชุดนี้'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แบบรายงานผลการประเมินอันตรายและการศึกษาผลกระทบของสภาพแวดล้อมในการทำงาน (แบบ ปอ. ๑)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('ลำดับ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('พื้นที่ปฏิบัติงาน (แผนก) / ลูกจ้าง', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ขั้นตอนการทำงาน / เครื่องจักร', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('สิ่งและลักษณะอันตราย', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ผลกระทบที่อาจเกิดขึ้น', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('มาตรการป้องกันเดิม', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ข้อเสนอแนะ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('โอกาส (L)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('รุนแรง (S)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('คะแนน', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ระดับอันตราย', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: rows.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final r = entry.value;
                        final eval = RiskMatrixCriteria.evaluate(r.hazard.likelihoodScore, r.hazard.severityScore);
                        final machineText = (r.stepItem.relatedMachineryEquipment != null && r.stepItem.relatedMachineryEquipment!.isNotEmpty)
                            ? '\n[เครื่อง: ${r.stepItem.relatedMachineryEquipment}]'
                            : '';

                        return DataRow(
                          cells: [
                            DataCell(Text('$idx')),
                            DataCell(Text('${r.workstation.stationName}\n(${r.workstation.departmentName} / ${r.workstation.employeeCount} คน)')),
                            DataCell(Text('${r.stepItem.stepName}$machineText')),
                            DataCell(Text(r.hazard.hazardItemTitle)),
                            DataCell(Text(r.hazard.potentialConsequences)),
                            DataCell(Text(r.hazard.existingControlMeasures ?? '-')),
                            DataCell(Text(r.hazard.recommendation ?? '-')),
                            DataCell(Text('${r.hazard.likelihoodScore}')),
                            DataCell(Text('${r.hazard.severityScore}')),
                            DataCell(Text('${r.hazard.riskScore}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: eval.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  eval.thaiName,
                                  style: TextStyle(color: eval.textColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: POR 2 TABLE VIEW
  // --------------------------------------------------------------------------
  Widget _buildPor2TableTab() {
    final rowsAsync = ref.watch(sessionReportRowsProvider(widget.sessionId));

    return rowsAsync.when(
      data: (rows) {
        final por2Rows = rows.where((r) => r.hazard.requiresPor2).toList();

        if (por2Rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 56, color: Colors.green.shade600),
                const SizedBox(height: 12),
                const Text(
                  'ไม่มีรายการอันตรายที่ต้องจัดทำแบบ ปอ. ๒',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ทุกรายการอยู่ในระดับต่ำมากหรือระดับต่ำ ซึ่งเป็นระดับที่ยอมรับได้ตามกฎหมาย',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'แบบรายงานแผนดำเนินงานด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (แบบ ปอ. ๒)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'รวม ${por2Rows.length} มาตรการที่ต้องควบคุม',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.amber.shade50),
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('ลำดับ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('พื้นที่ปฏิบัติงาน (แผนก) / ลูกจ้าง', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ขั้นตอนการทำงาน', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ระดับอันตราย', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('แผนดำเนินงานเพื่อลดและควบคุมอันตราย', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ระยะเวลาดำเนินการ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ผู้รับผิดชอบ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ผู้ตรวจติดตาม', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: por2Rows.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final r = entry.value;
                        final plan = r.plan;
                        final eval = RiskMatrixCriteria.evaluate(r.hazard.likelihoodScore, r.hazard.severityScore);

                        return DataRow(
                          cells: [
                            DataCell(Text('$idx')),
                            DataCell(Text('${r.workstation.stationName}\n(${r.workstation.departmentName} / ${r.workstation.employeeCount} คน)')),
                            DataCell(Text(r.stepItem.stepName)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: eval.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${eval.thaiName} (${eval.score})',
                                  style: TextStyle(color: eval.textColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(Text(plan?.controlPlanDescription ?? r.hazard.recommendation ?? '-')),
                            DataCell(Text('${plan?.startDate ?? "-"} ถึง\n${plan?.endDate ?? "-"}')),
                            DataCell(Text(plan?.responsiblePerson ?? '-')),
                            DataCell(Text(plan?.supervisorMonitor ?? '-')),
                            DataCell(Text(plan?.status ?? 'PLANNED')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
    );
  }
}
