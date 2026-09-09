import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../tabs/electrical_annual_tab.dart';
import '../tabs/electrical_isolation_tab.dart';
import '../tabs/electrical_pm_tab.dart';
import '../tabs/electrical_legal_tab.dart';

class ElectricalPage extends ConsumerStatefulWidget {
  const ElectricalPage({super.key});

  @override
  ConsumerState<ElectricalPage> createState() => _ElectricalPageState();
}

class _ElectricalPageState extends ConsumerState<ElectricalPage> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              GlassContainer(
                blur: 20,
                opacity: 0.6,
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ระบบความปลอดภัยทางไฟฟ้า',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'กฎกระทรวง พ.ศ. ๒๕๕๘ ข้อ ๑๒',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'การตรวจสอบรับรองประจำปี (แบบ ๕๖๒๘๙) • แผนผังวงจร LOTO • การบำรุงรักษาเชิงป้องกัน • จัดการเอกสารผู้รับเหมา & กว.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // TabBar
              GlassContainer(
                blur: 15,
                opacity: 0.5,
                padding: const EdgeInsets.all(6),
                borderRadius: BorderRadius.circular(16),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.verified_outlined, size: 18),
                      text: 'ตรวจรับรองประจำปี (ม.๑๒)',
                    ),
                    Tab(
                      icon: Icon(Icons.lock_clock_outlined, size: 18),
                      text: 'ตัดแยกพลังงาน & LOTO',
                    ),
                    Tab(
                      icon: Icon(Icons.handyman_outlined, size: 18),
                      text: 'ตรวจสภาพ & PM',
                    ),
                    Tab(
                      icon: Icon(Icons.gavel_outlined, size: 18),
                      text: 'คลังกฎหมาย & ประกาศ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // TabView
              Expanded(
                child: GlassContainer(
                  blur: 20,
                  opacity: 0.55,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      ElectricalInspectionTab(),
                      ElectricalIsolationTab(),
                      ElectricalPmTab(),
                      ElectricalLegalTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
