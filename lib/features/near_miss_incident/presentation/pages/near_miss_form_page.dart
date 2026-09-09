import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accident_models.dart';
import '../providers/accident_providers.dart';
import '../widgets/incident_quick_report_dialog.dart';
import '../widgets/accident_investigation_wizard_dialog.dart';
import '../widgets/capa_action_dialog.dart';
import '../widgets/official_form_selector_dialog.dart';

class NearMissFormPage extends ConsumerStatefulWidget {
  const NearMissFormPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NearMissFormPage> createState() => _NearMissFormPageState();
}

class _NearMissFormPageState extends ConsumerState<NearMissFormPage> {
  int _selectedTab = 0; // 0 = Register, 1 = Causation Analysis, 2 = CAPA, 3 = Official Forms
  String _selectedSeverityFilter = 'ALL';
  String _searchQuery = '';
  String _selectedCapaHierarchyFilter = 'ALL';

  void _openQuickReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const IncidentQuickReportDialog(),
    );
  }

  void _openInvestigationWizard(AccidentInvestigation investigation) {
    showDialog(
      context: context,
      builder: (ctx) => AccidentInvestigationWizardDialog(investigation: investigation),
    );
  }

  void _openCapaDialog({required int investigationId, AccidentCapaAction? existingAction}) {
    showDialog(
      context: context,
      builder: (ctx) => CapaActionDialog(
        investigationId: investigationId,
        existingAction: existingAction,
      ),
    );
  }

  void _openOfficialFormSelector(AccidentInvestigation investigation) {
    showDialog(
      context: context,
      builder: (ctx) => OfficialFormSelectorDialog(investigation: investigation),
    );
  }

  void _deleteInvestigation(AccidentInvestigation investigation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบรายงานอุบัติเหตุ'),
        content: Text('คุณต้องการลบรายงานเลขที่ "${investigation.eventNo}" หรือไม่? ข้อมูลมาตรการแก้ไขที่เกี่ยวข้องจะถูกลบด้วย'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (investigation.id != null) {
                await ref.read(accidentInvestigationsProvider.notifier).deleteInvestigation(investigation.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final investigationsAsync = ref.watch(accidentInvestigationsProvider);
    final capaAsync = ref.watch(accidentCapaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // 1. Hero Header Banner
            // ----------------------------------------------------------------
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 2. Summary KPI Metrics
            // ----------------------------------------------------------------
            investigationsAsync.when(
              data: (list) => _buildKpiRow(list, capaAsync.asData?.value ?? []),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 3. Segmented 4-Tab Navigation
            // ----------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: '📊 ทะเบียนอุบัติเหตุ & Near Miss',
                      count: investigationsAsync.asData?.value.length ?? 0,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: '🔍 บันทึกสอบสวน 5W1H & วิเคราะห์ ๓ ปัจจัย',
                      count: investigationsAsync.asData?.value.where((i) => i.unsafeActs.isNotEmpty || i.unsafeConditions.isNotEmpty).length ?? 0,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: '📋 มาตรการแก้ไขป้องกัน (CAPA ๔ ระดับ)',
                      count: capaAsync.asData?.value.length ?? 0,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 3,
                      label: '🖨️ คลังแบบฟอร์มราชการ (สปร.๕/กท.๔๔/กท.๑๖)',
                      count: 4,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 4. Tab Body Content
            // ----------------------------------------------------------------
            if (_selectedTab == 0)
              _buildRegisterTab(investigationsAsync)
            else if (_selectedTab == 1)
              _buildCausationAnalysisTab(investigationsAsync)
            else if (_selectedTab == 2)
              _buildCapaTab(investigationsAsync, capaAsync)
            else
              _buildOfficialFormsTab(investigationsAsync),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HERO BANNER
  // ==========================================================================
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบสอบสวนและวิเคราะห์อุบัติเหตุจากการทำงาน (Accident Investigation System)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'สอบสวนหาสาเหตุ 5W1H, วิเคราะห์ ๓ ปัจจัย (Unsafe Act / Condition / Management), มาตรการแก้ไขป้องกัน ๔ ระดับ และแบบฟอร์มราชการ สปร.๕, กท.๔๔, กท.๑๖',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _openQuickReportDialog,
            icon: const Icon(Icons.add_alert_rounded, size: 18),
            label: const Text('แจ้งเหตุด่วน (Flash Report / กท.๔๔)', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // KPI ROW
  // ==========================================================================
  Widget _buildKpiRow(List<AccidentInvestigation> investigations, List<AccidentCapaAction> capaList) {
    final total = investigations.length;
    final nearMiss = investigations.where((i) => i.eventType == 'NEAR_MISS').length;
    final lti = investigations.where((i) => i.eventType == 'LOST_TIME' || i.eventType == 'DISABILITY' || i.eventType == 'FATALITY').length;
    final totalDaysLost = investigations.fold<int>(0, (sum, i) => sum + i.daysLost);
    final completedCapa = capaList.where((a) => a.status == 'COMPLETED').length;

    return Row(
      children: [
        _buildKpiCard('เหตุการณ์ทั้งหมด', '$total รายการ', Icons.history_rounded, const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        _buildKpiCard('Near Miss (เกือบเกิดเหตุ)', '$nearMiss รายการ', Icons.warning_amber_rounded, Colors.teal.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('อุบัติเหตุถึงขั้นหยุดงาน (LTI)', '$lti รายการ', Icons.personal_injury_rounded, lti > 0 ? Colors.red.shade700 : Colors.grey.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('วันสูญเสียการทำงานสะสม', '$totalDaysLost วัน', Icons.event_busy_rounded, Colors.orange.shade800),
        const SizedBox(width: 10),
        _buildKpiCard('มาตรการ CAPA สำเร็จ', '$completedCapa / ${capaList.length} ข้อ', Icons.task_alt_rounded, Colors.green.shade700),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required int count, required Color color}) {
    final isSelected = _selectedTab == index;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: INCIDENT REGISTER
  // ==========================================================================
  Widget _buildRegisterTab(AsyncValue<List<AccidentInvestigation>> investigationsAsync) {
    return investigationsAsync.when(
      data: (investigations) {
        var filtered = investigations;
        if (_selectedSeverityFilter != 'ALL') {
          filtered = filtered.where((i) => i.eventType == _selectedSeverityFilter).toList();
        }
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((i) =>
              i.eventNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              i.incidentTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (i.injuredPersonName ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
              i.incidentLocation.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาเลขที่เหตุการณ์, ชื่องาน, ผู้ประสบเหตุ, สถานที่...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedSeverityFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ระดับความรุนแรงทั้งหมด')),
                      DropdownMenuItem(value: 'NEAR_MISS', child: Text('⚠️ Near Miss')),
                      DropdownMenuItem(value: 'FIRST_AID', child: Text('🩹 First Aid (ปฐมพยาบาล)')),
                      DropdownMenuItem(value: 'LOST_TIME', child: Text('🏥 Lost Time (หยุดงาน)')),
                      DropdownMenuItem(value: 'DISABILITY', child: Text('🦽 Disability (สูญเสียอวัยวะ)')),
                      DropdownMenuItem(value: 'FATALITY', child: Text('⚰️ Fatality (เสียชีวิต)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSeverityFilter = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              _buildEmptyState(
                icon: Icons.shield_outlined,
                title: 'ไม่พบรายการอุบัติเหตุ / Near Miss',
                subtitle: 'กดปุ่ม "แจ้งเหตุด่วน" ด้านบน เพื่อเริ่มบันทึกรายงานเหตุการณ์แรก',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) => _buildIncidentCard(filtered[idx]),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  Widget _buildIncidentCard(AccidentInvestigation inv) {
    Color severityBg;
    Color severityFg;
    IconData severityIcon;

    switch (inv.eventType) {
      case 'FATALITY':
        severityBg = Colors.black;
        severityFg = Colors.white;
        severityIcon = Icons.dangerous_rounded;
        break;
      case 'DISABILITY':
        severityBg = Colors.purple.shade50;
        severityFg = Colors.purple.shade900;
        severityIcon = Icons.accessible_forward_rounded;
        break;
      case 'LOST_TIME':
        severityBg = Colors.red.shade50;
        severityFg = Colors.red.shade800;
        severityIcon = Icons.personal_injury_rounded;
        break;
      case 'FIRST_AID':
        severityBg = Colors.amber.shade50;
        severityFg = Colors.amber.shade900;
        severityIcon = Icons.healing_rounded;
        break;
      case 'NEAR_MISS':
      default:
        severityBg = Colors.teal.shade50;
        severityFg = Colors.teal.shade900;
        severityIcon = Icons.warning_amber_rounded;
        break;
    }

    final isNearMiss = inv.eventType == 'NEAR_MISS';
    final hasPerson = inv.injuredPersonName != null && inv.injuredPersonName!.isNotEmpty;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Status Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: severityBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(severityIcon, color: severityFg, size: 24),
            ),
            const SizedBox(width: 14),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(inv.eventNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: severityBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(inv.eventTypeLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: severityFg)),
                      ),
                      const SizedBox(width: 8),
                      _buildInvestigationStatusBadge(inv.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inv.incidentTitle,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'วันที่เกิดเหตุ: ${inv.incidentDate} เวลา ${inv.incidentTime} น.  |  สถานที่: ${inv.incidentLocation}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  ),
                  if (hasPerson && !isNearMiss) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'ผู้ประสบเหตุ: ${inv.injuredPersonName} (${inv.injuredPersonDepartment ?? "-"} / ${inv.injuredPersonPosition ?? "-"})',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (inv.injuryNature != null)
                          Text('อาการ: ${inv.injuryNature}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Bottom badges (Days lost, CAPA progress)
                  Row(
                    children: [
                      if (inv.daysLost > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text('หยุดงาน: ${inv.daysLost} วัน', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'มาตรการ CAPA: ${inv.completedCapaCount}/${inv.capaCount} ข้อ',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
                        ),
                      ),
                      if (inv.unsafeActs.isNotEmpty || inv.unsafeConditions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                          child: const Text('✓ วิเคราะห์สาเหตุแล้ว', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Right Actions
            Wrap(
              spacing: 6,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openInvestigationWizard(inv),
                  icon: const Icon(Icons.manage_search_rounded, size: 16),
                  label: const Text('สอบสวน 5W1H'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openOfficialFormSelector(inv),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('พิมพ์เอกสาร'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'investigate') {
                      _openInvestigationWizard(inv);
                    } else if (val == 'forms') {
                      _openOfficialFormSelector(inv);
                    } else if (val == 'add_capa') {
                      if (inv.id != null) _openCapaDialog(investigationId: inv.id!);
                    } else if (val == 'delete') {
                      _deleteInvestigation(inv);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'investigate', child: Text('แก้ไขบันทึกสอบสวน 5W1H')),
                    const PopupMenuItem(value: 'forms', child: Text('พิมพ์แบบฟอร์มราชการ (สปร.๕/กท.๔๔/กท.๑๖)')),
                    const PopupMenuItem(value: 'add_capa', child: Text('เพิ่มมาตรการแก้ไขป้องกัน (CAPA)')),
                    const PopupMenuItem(value: 'delete', child: Text('ลบรายการนี้', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: CAUSATION ANALYSIS (5W1H & 3 FACTORS)
  // ==========================================================================
  Widget _buildCausationAnalysisTab(AsyncValue<List<AccidentInvestigation>> investigationsAsync) {
    return investigationsAsync.when(
      data: (investigations) {
        if (investigations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.psychology_outlined,
            title: 'ยังไม่มีข้อมูลการวิเคราะห์สาเหตุ',
            subtitle: 'บันทึกเหตุการณ์อุบัติเหตุเพื่อเริ่มต้นวิเคราะห์ ๓ ปัจจัย',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: investigations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final inv = investigations[idx];
            final hasAnalysis = inv.unsafeActs.isNotEmpty || inv.unsafeConditions.isNotEmpty || inv.managementErrors.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('${inv.eventNo} - ${inv.incidentTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          const SizedBox(width: 8),
                          _buildInvestigationStatusBadge(inv.status),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openInvestigationWizard(inv),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: Text(hasAnalysis ? 'ปรับปรุงการวิเคราะห์' : 'เริ่มวิเคราะห์ ๓ ปัจจัย'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('5W 1H Narrative: ${inv.description5w1h ?? "ยังไม่มีการระบุข้อความ 5W1H"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 12),

                  // 3 Factor Summary Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCausationBox(
                          title: '๑. การกระทำที่ไม่ปลอดภัย (Unsafe Acts)',
                          items: inv.unsafeActs,
                          color: Colors.red.shade700,
                          bg: Colors.red.shade50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCausationBox(
                          title: '๒. สภาพที่ไม่ปลอดภัย (Unsafe Conditions)',
                          items: inv.unsafeConditions,
                          color: Colors.orange.shade900,
                          bg: Colors.orange.shade50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCausationBox(
                          title: '๓. ระบบบริหารจัดการ (Management Errors)',
                          items: inv.managementErrors,
                          color: const Color(0xFF1E3A8A),
                          bg: Colors.blue.shade50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  Widget _buildCausationBox({required String title, required List<String> items, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          if (items.isEmpty)
            Text('- ยังไม่ระบุ -', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500))
          else
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $i', style: const TextStyle(fontSize: 10.5, color: Color(0xFF1E293B))),
                )),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: CAPA TRACKER
  // ==========================================================================
  Widget _buildCapaTab(
    AsyncValue<List<AccidentInvestigation>> investigationsAsync,
    AsyncValue<List<AccidentCapaAction>> capaAsync,
  ) {
    return capaAsync.when(
      data: (actions) {
        var filtered = actions;
        if (_selectedCapaHierarchyFilter != 'ALL') {
          filtered = filtered.where((a) => a.controlHierarchy == _selectedCapaHierarchyFilter).toList();
        }

        final investigations = investigationsAsync.asData?.value ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Text('กรองตามระดับการควบคุม (Hierarchy): ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCapaHierarchyFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ทั้งหมด ๔ ระดับ')),
                      DropdownMenuItem(value: 'ENGINEERING', child: Text('🛠️ ๑. ด้านวิศวกรรม (Engineering)')),
                      DropdownMenuItem(value: 'ADMINISTRATIVE', child: Text('📋 ๒. ด้านบริหารจัดการ (Administrative)')),
                      DropdownMenuItem(value: 'TRAINING', child: Text('🎓 ๓. ด้านการฝึกอบรม (Training)')),
                      DropdownMenuItem(value: 'PPE', child: Text('🦺 ๔. อุปกรณ์ PPE')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCapaHierarchyFilter = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              _buildEmptyState(
                icon: Icons.task_alt_outlined,
                title: 'ยังไม่มีมาตรการแก้ไขป้องกัน (CAPA)',
                subtitle: 'ไปที่แท็บทะเบียนอุบัติเหตุ แล้วกด "เพิ่ม CAPA" บนเหตุการณ์ที่ต้องการ',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final a = filtered[idx];
                  final relatedInv = investigations.firstWhere((i) => i.id == a.investigationId, orElse: () => AccidentInvestigation(eventNo: '-', eventType: 'NEAR_MISS', incidentTitle: '-', incidentDate: '-', incidentTime: '-', incidentLocation: '-'));

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: a.status == 'COMPLETED' ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              a.status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                              color: a.status == 'COMPLETED' ? Colors.green.shade700 : Colors.amber.shade900,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(a.hierarchyLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('เหตุการณ์: ${relatedInv.eventNo}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(a.actionDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(
                                  'ผู้รับผิดชอบ: ${a.responsiblePerson}  |  กำหนดเสร็จ: ${a.targetDate}  ${a.completedDate != null ? "| วันที่ปิดงาน: ${a.completedDate}" : ""}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                            onPressed: () => _openCapaDialog(investigationId: a.investigationId, existingAction: a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () async {
                              if (a.id != null) {
                                await ref.read(accidentCapaProvider.notifier).deleteAction(a.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 4: OFFICIAL FORMS HUB
  // ==========================================================================
  Widget _buildOfficialFormsTab(AsyncValue<List<AccidentInvestigation>> investigationsAsync) {
    return investigationsAsync.when(
      data: (investigations) {
        if (investigations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.print_outlined,
            title: 'ยังไม่มีข้อมูลสำหรับออกเอกสารราชการ',
            subtitle: 'กรุณาบันทึกรายงานอุบัติเหตุในแท็บแรกก่อนสั่งพิมพ์แบบฟอร์ม',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ศูนย์รวมแบบฟอร์มราชการและเอกสารทางการ (Official Safety & Compensation Forms)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('เลือกเหตุการณ์ที่ต้องการพิมพ์รายงาน จากนั้นกดปุ่มพิมพ์แบบฟอร์มที่ต้องการใช้งานได้ทันที', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: investigations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final inv = investigations[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF6366F1), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${inv.eventNo} - ${inv.incidentTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text(
                              'วันที่เกิดเหตุ: ${inv.incidentDate}  |  ผู้ประสบเหตุ: ${inv.injuredPersonName ?? "ไม่มีผู้บาดเจ็บ"} (${inv.eventTypeLabel})',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _openOfficialFormSelector(inv),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('เลือกพิมพ์แบบฟอร์ม'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  Widget _buildInvestigationStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'CLOSED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = '🟢 ปิดการสอบสวน';
        break;
      case 'CAPA_PENDING':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        label = '🟠 รอมาตรการ CAPA';
        break;
      case 'INVESTIGATING':
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade900;
        label = '🟡 กำลังสอบสวน';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
