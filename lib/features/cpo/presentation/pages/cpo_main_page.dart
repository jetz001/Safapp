import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/cpo_dashboard_tab.dart';
import '../tabs/cpo_election_tab.dart';
import '../tabs/cpo_meetings_tab.dart';
import '../tabs/cpo_action_tracker_tab.dart';

class CpoMainPage extends ConsumerStatefulWidget {
  const CpoMainPage({super.key});

  @override
  ConsumerState<CpoMainPage> createState() => _CpoMainPageState();
}

class _CpoMainPageState extends ConsumerState<CpoMainPage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D9488); // Teal 600

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบบริหารจัดการคณะกรรมการความปลอดภัยฯ (โมดูล คปอ.)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'ตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕ และคู่มือแบบฟอร์ม กสร. ๑/๒๕๖๑',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard_outlined, size: 18),
                  text: 'ภาพรวม',
                ),
                Tab(
                  icon: Icon(Icons.how_to_vote_outlined, size: 18),
                  text: 'การเลือกตั้ง & คณะกรรมการ คปอ.',
                ),
                Tab(
                  icon: Icon(Icons.event_note_outlined, size: 18),
                  text: 'การประชุม คปอ. (๖ วาระ)',
                ),
                Tab(
                  icon: Icon(Icons.checklist_rounded, size: 18),
                  text: 'มติที่ประชุม & ติดตามงาน',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CpoDashboardTab(),
          CpoElectionTab(),
          CpoMeetingsTab(),
          CpoActionTrackerTab(),
        ],
      ),
    );
  }
}
