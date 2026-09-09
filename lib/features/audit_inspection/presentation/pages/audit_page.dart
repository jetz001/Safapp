import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../data/datasources/audit_master_checklist_data.dart';
import '../../domain/models/audit_models.dart';
import '../notifiers/audit_providers.dart';
import '../widgets/audit_capa_dialog.dart';
import '../widgets/new_audit_dialog.dart';
import '../../services/safety_audit_excel_exporter.dart';
import '../../services/safety_audit_pdf_exporter.dart';

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});

  @override
  ConsumerState<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _checklistFilterCategory = 'ALL';
  String _checklistFilterStatus = 'ALL';
  String _searchQuery = '';
  String _capaFilterStatus = 'ALL';
  String _industrySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNewAuditDialog() async {
    final result = await showDialog<AuditSession>(
      context: context,
      builder: (context) => const NewAuditDialog(),
    );
    if (result != null) {
      ref.read(activeSessionIdProvider.notifier).setSessionId(result.id);
      _tabController.animateTo(1);
    }
  }

  void _openCapaDialog({AuditChecklistItem? item, AuditFindingCapa? existingFinding}) async {
    final activeSession = ref.read(activeAuditSessionProvider);
    if (activeSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรอบการตรวจประเมินก่อนเปิด CAR'), backgroundColor: Colors.orange),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AuditCapaDialog(
        auditSessionId: activeSession.id!,
        checklistItem: item,
        existingFinding: existingFinding,
      ),
    );
  }

  Future<void> _exportPdf(AuditSession session) async {
    final repo = ref.read(auditRepositoryProvider);
    final items = await repo.getChecklistItems(session.id!);
    final findings = await repo.getFindings(session.id!);
    final profile = ref.read(companyProfileNotifierProvider).asData?.value;

    try {
      final bytes = await SafetyAuditPdfExporter.generateAuditReportPdfBytes(
        session: session,
        items: items,
        findings: findings,
        companyName: profile?.companyName ?? 'สถานประกอบกิจการ',
        employerName: profile?.employerName,
        safetyOfficerName: profile?.safetyOfficerName,
      );

      await SafetyAuditPdfExporter.printOrPreviewPdf(
        bytes,
        'Audit_Report_${session.auditNo}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel(AuditSession session) async {
    final repo = ref.read(auditRepositoryProvider);
    final items = await repo.getChecklistItems(session.id!);
    final findings = await repo.getFindings(session.id!);
    final profile = ref.read(companyProfileNotifierProvider).asData?.value;

    try {
      final path = await SafetyAuditExcelExporter.exportAuditSessionToExcel(
        session: session,
        items: items,
        findings: findings,
        companyName: profile?.companyName ?? 'สถานประกอบกิจการ',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งออก Excel สำเร็จ:\n$path'), backgroundColor: Colors.green.shade800),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(auditSessionsProvider);
    final activeSession = ref.watch(activeAuditSessionProvider);
    final kpiAsync = ref.watch(auditKpiStatsProvider);
    final evidenceAsync = ref.watch(crossModuleEvidenceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // 1. STATUTORY HERO BANNER
          // -------------------------------------------------------------------
          _buildHeroBanner(),

          // -------------------------------------------------------------------
          // 2. SEGMENTED TAB BAR
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12.5),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.dashboard_rounded, size: 18),
                    text: '๑. แดชบอร์ด & รายการตรวจ (${sessionsAsync.asData?.value.length ?? 0})',
                  ),
                  Tab(
                    icon: const Icon(Icons.checklist_rtl_rounded, size: 18),
                    text: activeSession != null
                        ? '๒. บันทึกตรวจ: ${activeSession.auditNo} (${activeSession.compliancePercentage}%)'
                        : '๒. บันทึกการตรวจประเมิน (Checklist)',
                  ),
                  Tab(
                    icon: const Icon(Icons.assignment_late_outlined, size: 18),
                    text: '๓. ติดตามมาตรการ CAR/CAPA',
                  ),
                  Tab(
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    text: '๔. คลังกฎหมาย SMS & ๕๔ กิจการ',
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 3. TAB VIEWS CONTENT
          // -------------------------------------------------------------------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Dashboard & Sessions
                _buildDashboardTab(sessionsAsync, kpiAsync, evidenceAsync),
                // Tab 2: Smart Checklist & Live Evidence
                _buildChecklistTab(activeSession, sessionsAsync),
                // Tab 3: CAR / CAPA Tracker
                _buildCapaTrackerTab(),
                // Tab 4: Statutory Legal SMS 2565 & 54 Industries
                _buildLegalAnd54IndustriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO BANNER
  // ===========================================================================
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            child: const Icon(Icons.verified_outlined, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ศูนย์ตรวจประเมินความปลอดภัยอัจฉริยะ (Smart Safety Audit & Inspection Hub)',
                  style: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ตรวจประเมิน ๕ องค์ประกอบหลักตามกฎกระทรวงระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕ (บังคับ ๕๔ กิจการ ลูกจ้าง ๕๐ คนขึ้นไป) ผสานหลักฐานจริงข้ามโมดูลตามบริบทโรงงาน',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _openNewAuditDialog,
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: const Text('เริ่มรอบการตรวจใหม่ (New Audit)', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ===========================================================================
  // TAB 1: DASHBOARD & SESSIONS
  // ===========================================================================
  Widget _buildDashboardTab(
    AsyncValue<List<AuditSession>> sessionsAsync,
    AsyncValue<AuditKpiStats> kpiAsync,
    AsyncValue<CrossModuleEvidenceSummary> evidenceAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Row
          kpiAsync.when(
            data: (stats) => _buildKpiCards(stats),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Cross-Module Evidence Badges Bar
          evidenceAsync.when(
            data: (ev) => _buildCrossModuleSummaryBar(ev),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Sessions List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ประวัติและรอบการตรวจประเมิน (Audit Sessions)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: _openNewAuditDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('เปิดรอบการตรวจใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sessions Cards
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'ยังไม่มีรอบการตรวจประเมินความปลอดภัย',
                  subtitle: 'กดปุ่ม "เริ่มรอบการตรวจใหม่" ด้านบน เพื่อสร้างการตรวจประเมินระบบการจัดการฯ ตามกฎกระทรวง พ.ศ. ๒๕๖๕',
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) => _buildSessionCard(sessions[idx]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(AuditKpiStats stats) {
    return Row(
      children: [
        _buildKpiCard('ความสอดคล้องเฉลี่ย', '${stats.averageComplianceRate}%', Icons.pie_chart_outline_rounded, const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        _buildKpiCard('รอบการตรวจทั้งหมด', '${stats.totalSessions} รอบ', Icons.history_rounded, Colors.indigo.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('ข้อสอดคล้องสะสม', '${stats.totalConform} ข้อ', Icons.check_circle_outline_rounded, Colors.green.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('ข้อบกพร่องที่พบ (NC)', '${stats.totalMinorNc + stats.totalMajorNc} รายการ', Icons.warning_amber_rounded, Colors.orange.shade800),
        const SizedBox(width: 10),
        _buildKpiCard('CAR รอแก้ไขเสร็จ', '${stats.totalOpenCapa} ข้อ', Icons.assignment_late_outlined, stats.totalOpenCapa > 0 ? Colors.red.shade700 : Colors.teal.shade700),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildCrossModuleSummaryBar(CrossModuleEvidenceSummary ev) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: Color(0xFF1E3A8A), size: 20),
          const SizedBox(width: 8),
          const Text('สถานะหลักฐานกลางในระบบ Safapp:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEvidencePill('⚡ ไฟฟ้า: ${ev.electricalInspectionCount} รายการ', ev.electricalInspectionCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🏗️ ปั้นจั่น: ${ev.craneInspectionCount} ตัว', ev.craneInspectionCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🔥 หม้อน้ำ: ${ev.boilerInspectionCount} ลูก', ev.boilerInspectionCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🧪 สารเคมี: ${ev.chemicalCount} ชนิด', ev.chemicalCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('📋 PTW: ${ev.ptwActiveCount} ฉบับ', ev.ptwActiveCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🌡️ แสง/เสียง/ร้อน: ${ev.environmentSurveyCount}', ev.environmentSurveyCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🚒 ซ้อมหนีไฟ: มีข้อมูล', ev.emergencyPlanCount > 0),
                  const SizedBox(width: 6),
                  _buildEvidencePill('🛡️ เหตุการณ์: ${ev.incidentCount} เคส', ev.incidentCount > 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencePill(String label, bool hasData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasData ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: hasData ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: hasData ? Colors.green.shade900 : Colors.grey.shade600, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSessionCard(AuditSession session) {
    final activeId = ref.watch(activeSessionIdProvider);
    final isActive = activeId == session.id;

    Color badgeColor = session.isCompleted ? Colors.green.shade700 : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade200, width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Circular / Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: session.totalItems > 0 ? (session.conformCount / (session.totalItems - session.naCount).clamp(1, 999)) : 0,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade200,
                  color: session.compliancePercentage >= 80 ? Colors.green.shade600 : Colors.orange.shade700,
                ),
              ),
              Text(
                '${session.compliancePercentage.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(session.auditNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        session.isCompleted ? 'ตรวจเสร็จสมบูรณ์' : 'กำลังดำเนินการ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'วันที่: ${session.auditDate}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  session.auditTitle,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'หัวหน้าผู้ตรวจ: ${session.leadAuditor}  •  ขอบเขต: ${session.auditScope == "INTEGRATED" ? "SMS ๒๕๖๕ + บริบทโรงงาน" : "SMS ๒๕๖๕ เฉพาะระบบ"}  •  ข้อตรวจ: ${session.totalItems} ข้อ (Conform: ${session.conformCount}, Minor: ${session.minorNcCount}, Major: ${session.majorNcCount}, N/A: ${session.naCount})',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(activeSessionIdProvider.notifier).setSessionId(session.id);
                  _tabController.animateTo(1);
                },
                icon: Icon(isActive ? Icons.check_circle : Icons.edit_note, size: 16),
                label: Text(isActive ? 'กำลังตรวจ' : 'เปิดตรวจประเมิน'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade800,
                  side: BorderSide(color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 20),
                tooltip: 'พิมพ์รายงาน PDF ทางการ',
                onPressed: () => _exportPdf(session),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, color: Colors.green, size: 20),
                tooltip: 'ส่งออกไฟล์ Excel',
                onPressed: () => _exportExcel(session),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                tooltip: 'ลบรอบการตรวจ',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: Text('คุณต้องการลบรอบการตรวจ ${session.auditNo} ใช่หรือไม่?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(auditSessionsProvider.notifier).deleteSession(session.id!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SMART CHECKLIST & LIVE EVIDENCE
  // ===========================================================================
  Widget _buildChecklistTab(AuditSession? activeSession, AsyncValue<List<AuditSession>> sessionsAsync) {
    if (activeSession == null) {
      return _buildEmptyState(
        icon: Icons.checklist_rtl_rounded,
        title: 'ยังไม่ได้เลือกรอบการตรวจประเมิน',
        subtitle: 'กรุณาเลือกรอบการตรวจจากแท็บ "๑. แดชบอร์ด" หรือกดเลือกจากรายการด้านบน เพื่อเริ่มทำแบบตรวจ Checklist',
      );
    }

    final itemsAsync = ref.watch(activeChecklistNotifierProvider);

    return Column(
      children: [
        // Active Session Context Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text(
                'รอบการตรวจ: ${activeSession.auditNo}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 8),
              Text('• ${activeSession.auditTitle}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
              const Spacer(),
              _buildMiniScore('ความสอดคล้อง', '${activeSession.compliancePercentage}%', const Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              _buildMiniScore('Conform', '${activeSession.conformCount}', Colors.green.shade700),
              const SizedBox(width: 8),
              _buildMiniScore('Minor NC', '${activeSession.minorNcCount}', Colors.orange.shade800),
              const SizedBox(width: 8),
              _buildMiniScore('Major NC', '${activeSession.majorNcCount}', Colors.red.shade700),
              const SizedBox(width: 8),
              _buildMiniScore('N/A', '${activeSession.naCount}', Colors.grey.shade700),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openCapaDialog(),
                icon: const Icon(Icons.add_alert, size: 14),
                label: const Text('เปิด CAR', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        // Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาข้อกำหนด, กฎหมาย, หัวข้อการตรวจ...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _checklistFilterCategory,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('หมวดหมู่ทั้งหมด')),
                  DropdownMenuItem(value: 'POLICY', child: Text('๑. นโยบาย (ข้อ ๖-๗)')),
                  DropdownMenuItem(value: 'ORGANIZATION', child: Text('๒. การจัดองค์กร (ข้อ ๘)')),
                  DropdownMenuItem(value: 'PLANNING', child: Text('๓. แผนงาน & ปฏิบัติ (ข้อ ๙)')),
                  DropdownMenuItem(value: 'EVALUATION', child: Text('๔. ประเมินผล & ทบทวน (ข้อ ๑๐)')),
                  DropdownMenuItem(value: 'IMPROVEMENT', child: Text('๕. ปรับปรุง & พัฒนา (ข้อ ๑๑-๑๒)')),
                  DropdownMenuItem(value: 'SPECIFIC_HAZARD', child: Text('๖. บริบทโรงงาน (ไฟฟ้า/เครื่องจักร/เคมี/PTW)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _checklistFilterCategory = v);
                },
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _checklistFilterStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('สถานะผลตรวจทั้งหมด')),
                  DropdownMenuItem(value: 'UNAUDITED', child: Text('⚪ ยังไม่ตรวจ')),
                  DropdownMenuItem(value: 'CONFORM', child: Text('🟢 สอดคล้อง (Conform)')),
                  DropdownMenuItem(value: 'MINOR_NC', child: Text('🟡 Minor NC')),
                  DropdownMenuItem(value: 'MAJOR_NC', child: Text('🔴 Major NC')),
                  DropdownMenuItem(value: 'NA', child: Text('⚪ N/A')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _checklistFilterStatus = v);
                },
              ),
            ],
          ),
        ),

        // Checklist Items List
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              var filtered = items;
              if (_checklistFilterCategory != 'ALL') {
                filtered = filtered.where((i) => i.categoryCode == _checklistFilterCategory).toList();
              }
              if (_checklistFilterStatus != 'ALL') {
                filtered = filtered.where((i) => i.resultStatus == _checklistFilterStatus).toList();
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered.where((i) =>
                    i.itemTitle.toLowerCase().contains(q) ||
                    i.requirementDescription.toLowerCase().contains(q) ||
                    i.legalReference.toLowerCase().contains(q)).toList();
              }

              if (filtered.isEmpty) {
                return const Center(child: Text('ไม่พบรายการข้อตรวจตามเงื่อนไขที่ค้นหา'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) => _buildChecklistItemCard(filtered[idx]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniScore(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, color: col)),
          Text(val, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }

  Widget _buildChecklistItemCard(AuditChecklistItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isConform
              ? Colors.green.shade200
              : item.isMajorNc
                  ? Colors.red.shade300
                  : item.isMinorNc
                      ? Colors.orange.shade300
                      : Colors.grey.shade200,
          width: item.isNc ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category, Clause, Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                child: Text(item.clauseNo, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.itemTitle,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              if (item.sourceModule != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('โมดูล: ${item.sourceModule}', style: TextStyle(fontSize: 10, color: Colors.blue.shade900)),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Requirement & Law
          Text(
            item.requirementDescription,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            'กฎหมายอ้างอิง: ${item.legalReference}',
            style: TextStyle(fontSize: 10.5, color: Colors.blue.shade800, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),

          // Live Evidence Badge (if found in Safapp)
          if (item.evidenceSummary != null && item.evidenceSummary!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.evidenceSummary!,
                      style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Auditor Notes / Evidence Entry
          if (item.auditorNotes != null && item.auditorNotes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('บันทึกผู้ตรวจ: ${item.auditorNotes}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Evaluation Button Bar (4 Buttons)
          Row(
            children: [
              _buildEvalChoiceButton(item, 'CONFORM', '🟢 สอดคล้อง (Conform)', Colors.green.shade700, Colors.green.shade50),
              const SizedBox(width: 6),
              _buildEvalChoiceButton(item, 'MINOR_NC', '🟡 Minor NC', Colors.orange.shade800, Colors.orange.shade50),
              const SizedBox(width: 6),
              _buildEvalChoiceButton(item, 'MAJOR_NC', '🔴 Major NC', Colors.red.shade700, Colors.red.shade50),
              const SizedBox(width: 6),
              _buildEvalChoiceButton(item, 'NA', '⚪ N/A', Colors.grey.shade700, Colors.grey.shade100),
              const Spacer(),

              // Quick Note button
              TextButton.icon(
                onPressed: () => _editNotesDialog(item),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('ใส่บันทึก/หลักฐาน', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),

              // Open CAR button if NC
              if (item.isNc) ...[
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () => _openCapaDialog(item: item),
                  icon: const Icon(Icons.add_alert, size: 14),
                  label: const Text('เปิด CAR ทันที', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvalChoiceButton(AuditChecklistItem item, String statusKey, String label, Color fg, Color bg) {
    final isSelected = item.resultStatus == statusKey;

    return InkWell(
      onTap: () async {
        await ref.read(activeChecklistNotifierProvider.notifier).updateItemStatus(item, statusKey);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? fg : bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? fg : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : fg,
          ),
        ),
      ),
    );
  }

  void _editNotesDialog(AuditChecklistItem item) async {
    final noteCtrl = TextEditingController(text: item.auditorNotes ?? '');
    final actionCtrl = TextEditingController(text: item.suggestedAction ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('บันทึกผลการตรวจ: ${item.clauseNo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'หลักฐานการตรวจ / บันทึกของผู้ตรวจประเมิน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: actionCtrl,
              decoration: const InputDecoration(
                labelText: 'ข้อเสนอแนะในการปรับปรุง',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
        ],
      ),
    );

    if (save == true) {
      await ref.read(activeChecklistNotifierProvider.notifier).updateItemStatus(
            item,
            item.resultStatus,
            notes: noteCtrl.text.trim(),
            suggestedAction: actionCtrl.text.trim(),
          );
    }
  }

  // ===========================================================================
  // TAB 3: CAR / CAPA TRACKER
  // ===========================================================================
  Widget _buildCapaTrackerTab() {
    final findingsAsync = ref.watch(allAuditFindingsProvider);

    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            children: [
              const Text('ทะเบียนใบสั่งการแก้ไขข้อบกพร่อง (CAR / CAPA Tracker)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const Spacer(),
              DropdownButton<String>(
                value: _capaFilterStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('สถานะทั้งหมด')),
                  DropdownMenuItem(value: 'OPEN', child: Text('🔴 OPEN (รอเริ่มดำเนินการ)')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 IN_PROGRESS (กำลังแก้ไข)')),
                  DropdownMenuItem(value: 'CLOSED', child: Text('🟢 CLOSED (ปิดประเด็นแล้ว)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _capaFilterStatus = v);
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openCapaDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('สร้าง CAR ใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Findings List
        Expanded(
          child: findingsAsync.when(
            data: (findings) {
              var list = findings;
              if (_capaFilterStatus != 'ALL') {
                list = list.where((f) => f.status == _capaFilterStatus).toList();
              }

              if (list.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'ไม่พบรายการข้อบกพร่อง CAR/CAPA',
                  subtitle: 'ยังไม่มีข้อบกพร่อง หรือทุกรายการได้รับการแก้ไขและปิดประเด็นเรียบร้อยแล้ว',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) => _buildCapaCard(list[idx]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCapaCard(AuditFindingCapa f) {
    Color statusColor = f.status == 'CLOSED' ? Colors.green : (f.status == 'IN_PROGRESS' ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(f.findingNo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade900)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text(f.findingType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('อ้างอิง: ${f.clauseRef}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  f.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(f.problemDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          if (f.rootCause != null && f.rootCause!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('สาเหตุรากเหง้า: ${f.rootCause}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('มาตรการแก้ไข: ${f.correctiveAction}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('ผู้รับผิดชอบ: ${f.responsiblePerson}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(width: 16),
              Icon(Icons.event_outlined, size: 14, color: f.isOverdue ? Colors.red : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'กำหนดเสร็จ: ${f.dueDate}${f.isOverdue ? " (เลยกำหนด)" : ""}',
                style: TextStyle(fontSize: 11, color: f.isOverdue ? Colors.red : const Color(0xFF64748B), fontWeight: f.isOverdue ? FontWeight.bold : FontWeight.normal),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openCapaDialog(existingFinding: f),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('แก้ไข / บันทึกผลปิดประเด็น', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: STATUTORY LEGAL SMS 2565 & 54 INDUSTRIES
  // ===========================================================================
  Widget _buildLegalAnd54IndustriesTab() {
    final filteredIndustries = _industrySearchQuery.isEmpty
        ? AuditMasterChecklistData.statutory54Industries
        : AuditMasterChecklistData.statutory54Industries
            .where((i) => i.toLowerCase().contains(_industrySearchQuery.toLowerCase()))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Color(0xFF1E3A8A), size: 24),
                    SizedBox(width: 10),
                    Text('กฎกระทรวง กำหนดมาตรฐานเกี่ยวกับระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'ประกาศในราชกิจจานุเบกษา เล่ม ๑๓๙ ตอนที่ ๒๒ ก วันที่ ๑๑ เมษายน ๒๕๖๕ • ออกตามความในมาตรา ๕ และมาตรา ๘ แห่ง พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Divider(height: 20),
                const Text(
                  'สาระสำคัญของกฎหมาย:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• ข้อ ๔: นายจ้างของสถานประกอบกิจการตามบัญชีท้าย ๕๔ ประเภท ที่มีลูกจ้างตั้งแต่ ๕๐ คนขึ้นไป ต้องจัดให้มีระบบการจัดการด้านความปลอดภัยภายใน ๖๐ วัน\n'
                  '• ข้อ ๕: ระบบการจัดการด้านความปลอดภัย อย่างน้อยต้องประกอบด้วย ๕ องค์ประกอบ: (๑) นโยบาย (๒) การจัดองค์กร (๓) แผนงานและการนำไปปฏิบัติ (๔) การประเมินผลและการทบทวนระบบ (๕) การปรับปรุงและพัฒนา\n'
                  '• ข้อ ๘(๓): จัดทำเอกสารระบบการจัดการฯ ให้เป็นปัจจุบัน เก็บไว้ในสถานประกอบกิจการไม่น้อยกว่า ๒ ปี ในรูปแบบอิเล็กทรอนิกส์ได้ และพร้อมให้พนักงานตรวจความปลอดภัยตรวจสอบ\n'
                  '• ข้อ ๑๐: นายจ้างต้องจัดให้มีการตรวจติดตามและประเมินผลทบทวนระบบอย่างน้อยปีละ ๑ ครั้ง\n'
                  '• ข้อ ๑๓: สถานประกอบกิจการที่มีมาตรฐาน ISO 45001, ILO-OSH, OSHA, ANSI, BSI ถือว่าได้จัดให้มีระบบการจัดการตามกฎกระทรวงนี้แล้ว',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 54 Industries Section
          Row(
            children: [
              const Text(
                'บัญชีท้ายกฎกระทรวง: ๕๔ ประเภทสถานประกอบกิจการที่ต้องมีระบบการจัดการฯ',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาประเภทอุตสาหกรรม...',
                    hintStyle: const TextStyle(fontSize: 11),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (v) => setState(() => _industrySearchQuery = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid of 54 Industries
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
              childAspectRatio: 6.5,
            ),
            itemCount: filteredIndustries.length,
            itemBuilder: (ctx, idx) {
              final ind = filteredIndustries[idx];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.factory_outlined, size: 16, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ind,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
