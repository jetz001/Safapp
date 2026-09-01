import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_session_model.dart';
import '../../services/environment_pdf_exporter.dart';
import '../../services/environment_excel_exporter.dart';
import '../providers/environment_providers.dart';
import '../tabs/environment_dashboard_tab.dart';
import '../tabs/environment_points_tab.dart';
import '../tabs/environment_capa_tab.dart';
import '../tabs/environment_gazette_tab.dart';
import '../widgets/add_edit_session_dialog.dart';

/// Main screen for Environmental Monitoring Module (การตรวจวัดสภาพแวดล้อม: แสงสว่าง, เสียง, ความร้อน WBGT)
/// featuring 4 statutory interactive tabs:
/// - Tab 0: แดชบอร์ด & รอบตรวจวัด (Dashboard & Sessions)
/// - Tab 1: ตารางผลตรวจวัดรายจุด (Measurement Points)
/// - Tab 2: แผนการปรับปรุงแก้ไข & อนุรักษ์การได้ยิน (CAPA & Hearing Conservation)
/// - Tab 3: คลังกฎหมายราชกิจจานุเบกษา (Royal Gazette Repository)
class EnvironmentPage extends ConsumerStatefulWidget {
  const EnvironmentPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends ConsumerState<EnvironmentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref.read(envSelectedTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exportPdf() async {
    final sessions = await ref.read(envSessionListProvider.future);
    if (sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาสร้างรอบการตรวจวัดก่อนส่งออกรายงาน'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final selectedSessionId = ref.read(envSelectedSessionIdProvider);
    final activeSession = sessions.firstWhere(
      (s) => s.sessionId == selectedSessionId,
      orElse: () => sessions.first,
    );

    final points = await ref.read(envPointListProvider.future);
    final capas = await ref.read(envCapaListProvider.future);
    final kpi = await ref.read(envKpiSummaryProvider.future);

    if (mounted) {
      await EnvironmentPdfExporter.printOrShare(
        context,
        session: activeSession,
        points: points,
        capas: capas,
        kpi: kpi,
      );
    }
  }

  void _exportExcel() async {
    final sessions = await ref.read(envSessionListProvider.future);
    if (sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาสร้างรอบการตรวจวัดก่อนส่งออกรายงาน'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final selectedSessionId = ref.read(envSelectedSessionIdProvider);
    final activeSession = sessions.firstWhere(
      (s) => s.sessionId == selectedSessionId,
      orElse: () => sessions.first,
    );

    final points = await ref.read(envPointListProvider.future);
    final capas = await ref.read(envCapaListProvider.future);
    final kpi = await ref.read(envKpiSummaryProvider.future);

    final exportedPath = await EnvironmentExcelExporter.exportToExcelFile(
      session: activeSession,
      points: points,
      capas: capas,
      kpi: kpi,
    );

    if (mounted) {
      if (exportedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งออกไฟล์ Excel เรียบร้อยแล้ว:\n$exportedPath'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถสร้างไฟล์ Excel ได้'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCreateSessionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditSessionDialog(
        onSaved: (s) {
          ref.read(envSelectedSessionIdProvider.notifier).state = s.sessionId;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsAsync = ref.watch(envSessionListProvider);
    final selectedSessionId = ref.watch(envSelectedSessionIdProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.thermostat_rounded, color: Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบตรวจวัดสภาพแวดล้อมในการทำงาน (Environmental Monitoring)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
                Text(
                  'แสงสว่าง • เสียง • ความร้อน WBGT (กฎกระทรวงฯ ๒๕๕๙ & แบบ สสค. ๒๕๖๓)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          // Session Selector Dropdown in AppBar
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) return const SizedBox();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSessionId,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1E3A8A)),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('ทุกรอบตรวจวัด (All Sessions)', style: TextStyle(fontSize: 12.5))),
                      ...sessions.map((s) => DropdownMenuItem(
                            value: s.sessionId,
                            child: Text('${s.sessionId} (${s.sessionYearBe})', style: const TextStyle(fontSize: 12.5)),
                          )),
                    ],
                    onChanged: (v) {
                      if (v != null) ref.read(envSelectedSessionIdProvider.notifier).state = v;
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),

          // Export PDF Button
          OutlinedButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFDC2626)),
            label: const Text('ส่งออก PDF (สสค.)', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // Export Excel Button
          ElevatedButton.icon(
            onPressed: _exportExcel,
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('ส่งออก Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 3,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard_rounded, size: 18),
                  text: 'แดชบอร์ด & รอบตรวจวัด (Dashboard)',
                ),
                Tab(
                  icon: Icon(Icons.fact_check_rounded, size: 18),
                  text: 'ผลตรวจวัดรายจุด (Measurements)',
                ),
                Tab(
                  icon: Icon(Icons.assignment_turned_in_rounded, size: 18),
                  text: 'แผน CAPA & อนุรักษ์การได้ยิน (HCP)',
                ),
                Tab(
                  icon: Icon(Icons.menu_book_rounded, size: 18),
                  text: 'คลังกฎหมายราชกิจจานุเบกษา (Gazette)',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Dashboard & Sessions
          EnvironmentDashboardTab(
            onNavigateToPoints: () => _tabController.animateTo(1),
            onNavigateToCapa: () => _tabController.animateTo(2),
          ),

          // Tab 1: Points Table
          const EnvironmentPointsTab(),

          // Tab 2: CAPA & HCP
          const EnvironmentCapaTab(),

          // Tab 3: Gazette Repository
          const EnvironmentGazetteTab(),
        ],
      ),
    );
  }
}
