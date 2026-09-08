import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/ptw_dashboard_tab.dart';
import '../tabs/ptw_wizard_tab.dart';
import '../tabs/ptw_live_controls_tab.dart';
import '../tabs/ptw_gazette_tab.dart';

/// Main PTW Page — 4-Tab module for the complete Permit to Work system
class PtwPage extends ConsumerStatefulWidget {
  const PtwPage({super.key});

  @override
  ConsumerState<PtwPage> createState() => _PtwPageState();
}

class _PtwPageState extends ConsumerState<PtwPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_TabDef> _tabs = [
    _TabDef(Icons.dashboard, 'แดชบอร์ด', 'Dashboard'),
    _TabDef(Icons.assignment_add, 'ขอใบอนุญาต', 'PTW Wizard'),
    _TabDef(Icons.sensors, 'ควบคุมหน้างาน', 'Live Controls'),
    _TabDef(Icons.gavel, 'คลังกฎหมาย', 'Regulations'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToCreatePermit() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabController.index;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'ระบบใบอนุญาตทำงาน (PTW)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _goToCreatePermit,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('ขอใบอนุญาต (Create PTW)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.orange.shade700,
              indicatorWeight: 3,
              labelColor: Colors.orange.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              tabs: _tabs.map((tab) {
                final isActive = _tabs.indexOf(tab) == currentIndex;
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, size: 22, color: isActive ? Colors.orange.shade700 : Colors.grey.shade500),
                      const SizedBox(height: 2),
                      Text(tab.labelTh),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Tab 0: Dashboard
          PtwDashboardTab(
            onCreatePermitRequested: _goToCreatePermit,
          ),

          // Tab 1: PTW Wizard
          PtwWizardTab(
            onPermitSaved: () => _tabController.animateTo(0),
          ),

          // Tab 2: Live Controls
          const PtwLiveControlsTab(),

          // Tab 3: Legal Gazette
          const PtwGazetteTab(),
        ],
      ),
    );
  }
}

/// Tab definition helper class
class _TabDef {
  final IconData icon;
  final String labelTh;
  final String labelEn;

  const _TabDef(this.icon, this.labelTh, this.labelEn);
}
