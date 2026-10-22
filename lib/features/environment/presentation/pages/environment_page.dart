import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final repo = ref.read(environmentRepoProvider);
    final points = await repo.getPoints(sessionId: activeSession.sessionId);
    final capas = await repo.getCapas(sessionId: activeSession.sessionId);
    final kpi = await repo.getSessionKpi(activeSession.sessionId);
    final chemMeasurements = await repo.getChemicalSor3Measurements();

    if (mounted) {
      await EnvironmentPdfExporter.printOrShare(
        context,
        session: activeSession,
        points: points,
        capas: capas,
        kpi: kpi,
        chemicalMeasurements: chemMeasurements,
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

    final repo = ref.read(environmentRepoProvider);
    final points = await repo.getPoints(sessionId: activeSession.sessionId);
    final capas = await repo.getCapas(sessionId: activeSession.sessionId);
    final kpi = await repo.getSessionKpi(activeSession.sessionId);

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
        toolbarHeight: 70,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.thermostat_rounded, color: Color(0xFF1E3A8A), size: 24),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ระบบตรวจวัดสภาพแวดล้อมในการทำงาน (Environmental Monitoring)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'แสงสว่าง • เสียง • ความร้อน WBGT • สารเคมี (กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
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
