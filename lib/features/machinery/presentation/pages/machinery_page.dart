import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../tabs/machinery_crane_tab.dart';
import '../tabs/machinery_boiler_tab.dart';
import '../tabs/machinery_assets_tab.dart';
import '../tabs/machinery_legal_tab.dart';

class MachineryPage extends ConsumerStatefulWidget {
  const MachineryPage({super.key});

  @override
  ConsumerState<MachineryPage> createState() => _MachineryPageState();
}

class _MachineryPageState extends ConsumerState<MachineryPage> with SingleTickerProviderStateMixin {
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
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ระบบความปลอดภัยเครื่องจักร ปั้นจั่น & หม้อน้ำ',
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
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'กฎกระทรวง พ.ศ. ๒๕๖๔',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'การตรวจสอบรับรองปั้นจั่น (แบบ ปจ.๑ / ปจ.๒) • การทดสอบพิกัดยก Load Test • ตรวจรับรองหม้อน้ำ & ภาชนะรับแรงดัน • ทะเบียนอุปกรณ์ช่วยยก & การ์ด',
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
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.precision_manufacturing_outlined, size: 18),
                      text: 'ตรวจรับรองปั้นจั่น (ปจ.๑/ปจ.๒)',
                    ),
                    Tab(
                      icon: Icon(Icons.water_damage_outlined, size: 18),
                      text: 'ตรวจรับรองหม้อน้ำ (Boiler)',
                    ),
                    Tab(
                      icon: Icon(Icons.handyman_outlined, size: 18),
                      text: 'ทะเบียนอุปกรณ์ช่วยยก & การ์ด',
                    ),
                    Tab(
                      icon: Icon(Icons.gavel_outlined, size: 18),
                      text: 'คลังกฎหมาย & เกณฑ์ทดสอบ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // TabBarView
              Expanded(
                child: GlassContainer(
                  blur: 20,
                  opacity: 0.55,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      MachineryCraneTab(),
                      MachineryBoilerTab(),
                      MachineryAssetsTab(),
                      MachineryLegalTab(),
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
