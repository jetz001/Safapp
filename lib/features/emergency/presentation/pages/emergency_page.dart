import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/emergency_dashboard_tab.dart';
import '../tabs/erp_builder_tab.dart';
import '../tabs/drill_management_tab.dart';
import '../tabs/emergency_legal_tab.dart';

class EmergencyPage extends ConsumerStatefulWidget {
  const EmergencyPage({super.key});

  @override
  ConsumerState<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends ConsumerState<EmergencyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _navigateToTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'การจัดการเหตุฉุกเฉิน (Emergency Response Management)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFDC2626),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFFDC2626),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              text: 'แดชบอร์ดความพร้อม (Readiness)',
            ),
            Tab(
              icon: Icon(Icons.assignment_turned_in_outlined, size: 20),
              text: 'ตัวสร้างแผนฉุกเฉิน (ERP Builder)',
            ),
            Tab(
              icon: Icon(Icons.run_circle_outlined, size: 20),
              text: 'การฝึกซ้อมและ สปร. ๔ (Drills)',
            ),
            Tab(
              icon: Icon(Icons.menu_book_outlined, size: 20),
              text: 'คลังกฎหมาย & เครื่องคำนวณ (Legal)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EmergencyDashboardTab(
            onNavigateToBuilder: () => _navigateToTab(1),
            onNavigateToDrills: () => _navigateToTab(2),
          ),
          const ErpBuilderTab(),
          const DrillManagementTab(),
          const EmergencyLegalTab(),
        ],
      ),
    );
  }
}
