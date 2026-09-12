import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/ppe_catalog_tab.dart';
import '../tabs/ppe_stock_card_tab.dart';
import '../tabs/asl_supplier_tab.dart';
import '../tabs/ppe_dashboard_tab.dart';
import '../providers/ppe_providers.dart';

class PpePage extends ConsumerStatefulWidget {
  const PpePage({Key? key}) : super(key: key);

  @override
  ConsumerState<PpePage> createState() => _PpePageState();
}

class _PpePageState extends ConsumerState<PpePage> with SingleTickerProviderStateMixin {
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
    const primaryColor = Color(0xFF2563EB); // Royal Blue
    final metricsAsync = ref.watch(ppeDashboardMetricsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 74,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ทะเบียนอุปกรณ์ (PPE) และผู้รับเหมา/คู่ค้า (ASL)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    'ตาม พ.ร.บ. ความปลอดภัยฯ พ.ศ. ๒๕๕๔ มาตรา ๒๒ และ Approved Supplier List',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Quick Low Stock Alert Badge in Header
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6, right: 16),
            child: metricsAsync.when(
            data: (m) {
              final lowCount = (m['lowStockCount'] as int?) ?? 0;
              if (lowCount == 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('สต็อกปกติทุกรายการ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text('$lowCount รายการใกล้หมด', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'คลังและทะเบียน PPE',
                ),
                Tab(
                  icon: Icon(Icons.swap_horiz_outlined, size: 18),
                  text: 'บันทึกรับเข้า-เบิกจ่าย (Stock Card)',
                ),
                Tab(
                  icon: Icon(Icons.business_outlined, size: 18),
                  text: 'คู่ค้าที่ผ่านการรับรอง (ASL)',
                ),
                Tab(
                  icon: Icon(Icons.dashboard_outlined, size: 18),
                  text: 'สรุปภาพรวม & แจ้งเตือน',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PpeCatalogTab(),
          PpeStockCardTab(),
          AslSupplierTab(),
          PpeDashboardTab(),
        ],
      ),
    );
  }
}
