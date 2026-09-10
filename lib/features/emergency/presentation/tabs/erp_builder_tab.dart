import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';
import '../../data/models/emergency_plan_model.dart';
import '../../data/datasources/emergency_presets_data.dart';
import '../../services/erp_pdf_exporter.dart';
import '../../services/emergency_excel_exporter.dart';
import '../notifiers/emergency_providers.dart';
import '../widgets/erp_plan_editor_dialog.dart';

class ErpBuilderTab extends ConsumerStatefulWidget {
  final EmergencyPlanModel? initialPlan;

  const ErpBuilderTab({super.key, this.initialPlan});

  @override
  ConsumerState<ErpBuilderTab> createState() => _ErpBuilderTabState();
}

class _ErpBuilderTabState extends ConsumerState<ErpBuilderTab> {
  String _searchQuery = '';
  HazardType? _filterHazard;
  PlanStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    // If initial plan was supplied or selected, open it in editor dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = widget.initialPlan ?? ref.read(selectedErpPlanProvider);
      if (selected != null && mounted) {
        _openEditDialog(context, selected);
      }
    });
  }

  void _openEditDialog(BuildContext context, EmergencyPlanModel? plan, {int initialStep = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ErpPlanEditorDialog(
        existingPlan: plan,
        initialStep: initialStep,
      ),
    );
  }

  Future<void> _confirmDeletePlan(EmergencyPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบแผนฉุกเฉิน', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'คุณต้องการลบเล่มแผนฉุกเฉิน "${plan.planTitle}" (ID: #${plan.id}) ออกจากระบบหรือไม่?\n\n'
          '⚠️ โครงสร้างทั้ง ๖ แผนย่อย รายชื่อทีม และข้อมูลจุดตรวจทั้งหมดในเล่มนี้จะถูกลบอย่างถาวร',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบเล่มแผน'),
          ),
        ],
      ),
    );

    if (confirmed == true && plan.id != null) {
      await ref.read(emergencyPlanListProvider.notifier).deletePlan(plan.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบแผนฉุกเฉิน "${plan.planTitle}" ออกจากระบบเรียบร้อยแล้ว'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _exportPdf(EmergencyPlanModel plan) async {
    try {
      final exporter = ErpPdfExporter();
      final path = await exporter.savePdf(plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งออกเล่มแผนฉุกเฉิน A4 สำเร็จ:\n$path'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งออก PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel(EmergencyPlanModel plan) async {
    try {
      await EmergencyExcelExporter.exportPlanDetails(plan, context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(emergencyPlanListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════════════
          // 1. FILTER & SEARCH CONTROL BAR (แบบ คปอ)
          // ══════════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // 1. Hazard Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<HazardType?>(
                    value: _filterHazard,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.layers_outlined, size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('แสดงทุกประเภทภัย', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      ...HazardType.values.map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Row(
                            children: [
                              Icon(h.icon, size: 16, color: h.color),
                              const SizedBox(width: 6),
                              Text(h.shortTitle, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _filterHazard = val),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Search Box
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'ค้นหาเล่มแผนฉุกเฉิน (ชื่อแผน, สถานประกอบการ, ผู้บัญชาการ)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<PlanStatus?>(
                    value: _filterStatus,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('ทุกสถานะ', style: TextStyle(fontSize: 13))),
                      ...PlanStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _filterStatus = val),
                  ),
                ),
                const SizedBox(width: 14),

                // 4. Create Plan Button
                ElevatedButton.icon(
                  onPressed: () => _openEditDialog(context, null),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('สร้างแผนฉุกเฉินใหม่', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ══════════════════════════════════════════════════════════════════
          // 2. STATUTORY TEMPLATE BANNER (แบบ คปอ)
          // ══════════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'โครงสร้าง ๖ แผนย่อยตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๔ (ERP Standard Framework)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '๑.ตรวจตรา  •  ๒.ฝึกอบรม (๔๐%)  •  ๓.รณรงค์ป้องกัน  •  ๔.ดับเพลิงระงับเหตุ  •  ๕.อพยพหนีไฟ  •  ๖.บรรเทาทุกข์และฟื้นฟู (BCP)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = await ref.read(emergencyPlanListProvider.notifier).loadMissingPresets();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              count > 0
                                  ? 'โหลดแม่แบบเพิ่ม $count แผน (ครบทั้ง ๕ ประเภทภัย) เรียบร้อยแล้ว'
                                  : 'ระบบมีแม่แบบครบทั้ง ๕ ประเภทภัยแล้ว',
                            ),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      },
                      icon: const Icon(Icons.playlist_add, size: 15),
                      label: const Text('โหลดครบ ๕ ภัย', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 13, color: Color(0xFFDC2626)),
                      label: const Text('+ อัคคีภัย', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                      onPressed: () {
                        final preset = EmergencyPresetsData.getPreset(hazardType: HazardType.fire, businessType: BusinessType.factory);
                        _openEditDialog(context, preset);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 13, color: Color(0xFF7C3AED)),
                      label: const Text('+ สารเคมี HAZMAT', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED))),
                      onPressed: () {
                        final preset = EmergencyPresetsData.getPreset(hazardType: HazardType.chemicalSpill, businessType: BusinessType.chemicalStorage);
                        _openEditDialog(context, preset);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 13, color: Color(0xFF0284C7)),
                      label: const Text('+ น้ำท่วม', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                      onPressed: () {
                        final preset = EmergencyPresetsData.getPreset(hazardType: HazardType.flood, businessType: BusinessType.factory);
                        _openEditDialog(context, preset);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 13, color: Color(0xFFD97706)),
                      label: const Text('+ แผ่นดินไหว', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                      onPressed: () {
                        final preset = EmergencyPresetsData.getPreset(hazardType: HazardType.earthquake, businessType: BusinessType.office);
                        _openEditDialog(context, preset);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 13, color: Color(0xFFCA8A04)),
                      label: const Text('+ ไฟฟ้า', style: TextStyle(fontSize: 11, color: Color(0xFFCA8A04))),
                      onPressed: () {
                        final preset = EmergencyPresetsData.getPreset(hazardType: HazardType.electrical, businessType: BusinessType.factory);
                        _openEditDialog(context, preset);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ══════════════════════════════════════════════════════════════════
          // 3. LIST OF BIG CARDS (การ์ดใหญ่ละแผน)
          // ══════════════════════════════════════════════════════════════════
          plansAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e', style: const TextStyle(color: Colors.red))),
            data: (plans) {
              // Apply local filters
              var filtered = plans;
              if (_filterHazard != null) {
                filtered = filtered.where((p) => p.hazardType == _filterHazard).toList();
              }
              if (_filterStatus != null) {
                filtered = filtered.where((p) => p.status == _filterStatus).toList();
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered.where((p) =>
                  p.planTitle.toLowerCase().contains(q) ||
                  p.companyName.toLowerCase().contains(q) ||
                  p.fireCommanderName.toLowerCase().contains(q)
                ).toList();
              }

              if (filtered.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final plan = filtered[index];
                  return _buildBigPlanCard(context, plan);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_late_outlined, size: 48, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่พบเล่มแผนฉุกเฉินในระบบ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'คุณสามารถสร้างเล่มแผนฉุกเฉินใหม่จากพรีเซ็ตมาตรฐานตามกฎหมายอัคคีภัยได้ทันที',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(emergencyPlanListProvider.notifier).loadMissingPresets();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('โหลดแม่แบบแผนฉุกเฉินครบทั้ง ๕ ประเภทภัย สำเร็จแล้ว'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('โหลดแม่แบบมาตรฐานครบ ๕ ภัย'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openEditDialog(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('จัดทำแผนฉบับใหม่'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BIG PLAN CARD (การ์ดใหญ่ละแผน แบบ คปอ)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBigPlanCard(BuildContext context, EmergencyPlanModel plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: plan.hazardType.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(plan.hazardType.icon, color: plan.hazardType.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.planTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.hazardType.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.hazardType.shortTitle,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: plan.hazardType.color),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.status.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: plan.status.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ฉบับที่: ${plan.version}  |  สถานประกอบการ: ${plan.companyName}  |  วันที่มีผล: ${plan.effectiveDate}  |  ทบทวนล่าสุด: ${plan.reviewDate.isEmpty ? "-" : plan.reviewDate}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                OutlinedButton.icon(
                  onPressed: () => _exportExcel(plan),
                  icon: const Icon(Icons.table_view_outlined, size: 14),
                  label: const Text('Excel', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _exportPdf(plan),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                  label: const Text('PDF เล่มแผน', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E3A8A)),
                  tooltip: 'แก้ไขรายละเอียดแผนฉุกเฉิน',
                  onPressed: () => _openEditDialog(context, plan, initialStep: 0),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'ลบเล่มแผนนี้',
                  onPressed: () => _confirmDeletePlan(plan),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Quick Metrics Summary Row ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildInfoMetric(Icons.people_outline, 'พนักงานทั้งหมด', '${plan.totalEmployees} คน (ช ${plan.maleCount} / ญ ${plan.femaleCount})'),
                  const SizedBox(width: 20),
                  _buildInfoMetric(Icons.local_fire_department_outlined, 'ผู้อำนวยการสั่งการ', plan.fireCommanderName),
                  const SizedBox(width: 20),
                  _buildInfoMetric(Icons.phone_in_talk_outlined, 'สายด่วน 24 ชม.', plan.commanderPhone),
                  const SizedBox(width: 20),
                  _buildInfoMetric(Icons.business_outlined, 'ประเภทกิจการ', plan.businessType.label),
                  const Spacer(),
                  Text(
                    'โครงสร้าง ๖ แผนย่อยตามกฎหมาย (กฎกระทรวงฯ ข้อ ๔):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── การ์ดเล็กในแผน ๖ ใบ (Horizontal Workflow Sub-Cards แบบ คปอ) ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Inspection Sub-Card
                  _buildSubCard(
                    stepNum: '๑',
                    title: 'แผนการตรวจตรา',
                    subtitle: 'Inspection Plan',
                    icon: Icons.search_outlined,
                    primaryColor: const Color(0xFFD97706),
                    badgeText: '${plan.inspectionPlan.items.length} จุดตรวจตรา',
                    line1: 'ความถี่: ${plan.inspectionPlan.frequencyDescription.isEmpty ? "รายเดือน (MONTHLY)" : plan.inspectionPlan.frequencyDescription}',
                    line2: 'ขั้นตอน: ${plan.inspectionPlan.reportingProcedure.isEmpty ? "ตรวจอุปกรณ์ตามมาตรฐาน ปจ.๑" : plan.inspectionPlan.reportingProcedure}',
                    onTap: () => _openEditDialog(context, plan, initialStep: 1),
                  ),
                  const SizedBox(width: 12),

                  // 2. Training Sub-Card
                  _buildSubCard(
                    stepNum: '๒',
                    title: 'แผนการฝึกอบรม',
                    subtitle: 'Training Plan',
                    icon: Icons.school_outlined,
                    primaryColor: const Color(0xFF2563EB),
                    badgeText: 'โควตา ${plan.trainingPlan.basicFireQuotaPercent}% (ข้อ ๒๗)',
                    line1: 'หลักสูตร: ${plan.trainingPlan.courses.length} คอร์สตามกฎหมาย',
                    line2: 'ซ้อมใหญ่ประจำปี: เดือน ${plan.trainingPlan.annualDrillTargetMonth}',
                    onTap: () => _openEditDialog(context, plan, initialStep: 2),
                  ),
                  const SizedBox(width: 12),

                  // 3. Campaign Sub-Card
                  _buildSubCard(
                    stepNum: '๓',
                    title: 'แผนรณรงค์ป้องกัน',
                    subtitle: 'Campaign Plan',
                    icon: Icons.campaign_outlined,
                    primaryColor: const Color(0xFF059669),
                    badgeText: '${plan.campaignPlan.activities.length} กิจกรรมรณรงค์',
                    line1: 'นโยบาย 5ส & ควบคุมพื้นที่สูบบุหรี่',
                    line2: 'มาตรการความปลอดภัยงาน Hot Work',
                    onTap: () => _openEditDialog(context, plan, initialStep: 3),
                  ),
                  const SizedBox(width: 12),

                  // 4. Suppression Sub-Card
                  _buildSubCard(
                    stepNum: '๔',
                    title: 'แผนดับเพลิงระงับเหตุ',
                    subtitle: 'Suppression Plan',
                    icon: Icons.local_fire_department_outlined,
                    primaryColor: const Color(0xFFDC2626),
                    badgeText: '${plan.suppressionPlan.regularShiftTeam.length + plan.suppressionPlan.offHoursTeam.length} ตำแหน่งหน้าที่',
                    line1: 'กะปกติ ${plan.suppressionPlan.regularShiftTeam.length} คน  |  นอกเวลา ${plan.suppressionPlan.offHoursTeam.length} คน',
                    line2: 'เผชิญเหตุ: ${plan.suppressionPlan.initialResponseProtocol.isNotEmpty ? "ระบุขั้นตอนแล้ว" : "ยังไม่ได้ระบุ"}',
                    onTap: () => _openEditDialog(context, plan, initialStep: 4),
                  ),
                  const SizedBox(width: 12),

                  // 5. Evacuation Sub-Card
                  _buildSubCard(
                    stepNum: '๕',
                    title: 'แผนอพยพหนีไฟ',
                    subtitle: 'Evacuation Plan',
                    icon: Icons.directions_run_outlined,
                    primaryColor: const Color(0xFF7C3AED),
                    badgeText: '${plan.evacuationPlan.evacuationTeams.length} ทีมนำทางอพยพ',
                    line1: 'สัญญาณ: ${plan.evacuationPlan.alarmSoundSignal.isEmpty ? "สัญญาณกริ่งเตือนภัย" : plan.evacuationPlan.alarmSoundSignal}',
                    line2: 'จุดรวมพล: ${plan.evacuationPlan.assemblyPoints.length} จุด (${plan.evacuationPlan.headcountMethod.isEmpty ? "ตรวจนับที่จุดรวมพล" : plan.evacuationPlan.headcountMethod})',
                    onTap: () => _openEditDialog(context, plan, initialStep: 5),
                  ),
                  const SizedBox(width: 12),

                  // 6. Relief Sub-Card
                  _buildSubCard(
                    stepNum: '๖',
                    title: 'แผนบรรเทาทุกข์/BCP',
                    subtitle: 'Relief & Recovery',
                    icon: Icons.healing_outlined,
                    primaryColor: const Color(0xFF0D9488),
                    badgeText: '${plan.reliefPlan.governmentContacts.length} หน่วยงานฉุกเฉิน',
                    line1: 'ประสานงาน 199 / รพ. / ตำรวจ',
                    line2: 'แผนฟื้นฟูความต่อเนื่องทางธุรกิจ (BCP)',
                    onTap: () => _openEditDialog(context, plan, initialStep: 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════

  Widget _buildInfoMetric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildSubCard({
    required String stepNum,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required String badgeText,
    required String line1,
    required String line2,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 235,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Card Header
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(
                  stepNum,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(subtitle, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(icon, size: 16, color: primaryColor),
            ],
          ),
          const SizedBox(height: 8),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
          const SizedBox(height: 8),

          // Detail Lines
          Text(
            line1,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), height: 1.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            line2,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 30,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.edit_note, size: 15, color: primaryColor),
              label: Text('ตรวจดู / แก้ไข', style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
