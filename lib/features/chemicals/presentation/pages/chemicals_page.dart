import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/chemical_inventory_model.dart';
import '../../domain/models/chemical_sds_sor1_model.dart';
import '../../domain/models/chemical_measurement_sor3_model.dart';
import '../../domain/models/chemical_laws_model.dart';
import '../../domain/models/chemical_tlv_model.dart';
import '../../data/datasources/chemical_324_tlv_data.dart';
import '../providers/chemical_providers.dart';
import '../widgets/chemical_inventory_form_dialog.dart';
import '../widgets/chemical_doc_viewer_dialog.dart';
import '../widgets/ghs_pictogram_selector.dart';
import '../widgets/nfpa_diamond_widget.dart';
import '../widgets/sds_sor1_editor_dialog.dart';
import '../widgets/sds_sor3_measurement_dialog.dart';
import '../../services/chemical_sor1_pdf_service.dart';
import '../../services/chemical_sor3_pdf_service.dart';

/// Main screen for the Chemical & SDS Management module featuring 4 statutory tabs:
/// - Tab 1: ทะเบียนสารเคมี & ติดตามสถานะ SDS (Chemical Register & SDS Tracking)
/// - Tab 2: ข้อมูลความปลอดภัยสารเคมี (แบบ สอ.๑ - SDS 16 หัวข้อ)
/// - Tab 3: รายงานผลการตรวจวัดในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕) & TLV Evaluator
/// - Tab 4: คลังเอกสารกฎหมายอ้างอิงราชกิจจานุเบกษา (Legal Reference Library)
class ChemicalsPage extends ConsumerStatefulWidget {
  const ChemicalsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ChemicalsPage> createState() => _ChemicalsPageState();
}

class _ChemicalsPageState extends ConsumerState<ChemicalsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TLV Quick Checker State (Tab 3)
  ChemicalTlvItem? _selectedTlvChemical;
  final TextEditingController _measuredValController = TextEditingController(text: '10.0');
  String _selectedSamplingType = 'TWA_8HR';
  String _selectedUnit = 'ppm';
  TlvEvaluationResult? _tlvQuickResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref.read(chemicalSelectedTabProvider.notifier).state = _tabController.index;
      }
    });

    // Default TLV chemical for interactive demo in Tab 3
    _selectedTlvChemical = Chemical324TlvData.findBySequence(38) ?? Chemical324TlvData.tlvList.first;
    _runTlvEvaluation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _measuredValController.dispose();
    super.dispose();
  }

  void _runTlvEvaluation() {
    if (_selectedTlvChemical == null) return;
    final val = double.tryParse(_measuredValController.text) ?? 0.0;
    setState(() {
      _tlvQuickResult = TlvEvaluationEngine.evaluateWithTlvItem(
        tlvItem: _selectedTlvChemical!,
        samplingType: _selectedSamplingType,
        unit: _selectedUnit,
        measuredValue: val,
      );
    });
  }

  // --------------------------------------------------------------------------
  // Tab 1 Dialogs & Actions
  // --------------------------------------------------------------------------
  void _openAddChemicalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChemicalInventoryFormDialog(
        onSave: (item, newSds, newLabel) async {
          await ref.read(chemicalInventoryProvider.notifier).saveInventory(
                item,
                newSdsPath: newSds,
                newLabelPath: newLabel,
              );
        },
      ),
    );
  }

  void _openEditChemicalDialog(ChemicalInventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChemicalInventoryFormDialog(
        initialItem: item,
        onSave: (updatedItem, newSds, newLabel) async {
          await ref.read(chemicalInventoryProvider.notifier).saveInventory(
                updatedItem,
                newSdsPath: newSds,
                newLabelPath: newLabel,
              );
        },
      ),
    );
  }

  void _confirmDeleteChemical(ChemicalInventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบรายการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('คุณต้องการลบ "${item.tradeName}" (CAS: ${item.casNumber}) ออกจากทะเบียนสารเคมีหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (item.id != null) {
                await ref.read(chemicalInventoryProvider.notifier).deleteInventory(item.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(String filePath, String title, {String? subtitle, String? casNumber}) {
    showDialog(
      context: context,
      builder: (ctx) => ChemicalDocViewerDialog(
        filePath: filePath,
        title: title,
        subtitle: subtitle,
        casNumber: casNumber,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 2 (Form สอ.๑) Dialogs & Actions
  // --------------------------------------------------------------------------
  void _openAddSdsSor1Dialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SdsSor1EditorDialog(
        onSave: (item) async {
          await ref.read(chemicalSdsSor1ListProvider.notifier).saveSdsSor1(item);
        },
      ),
    );
  }

  void _openEditSdsSor1Dialog(ChemicalSdsSor1Model item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SdsSor1EditorDialog(
        initialItem: item,
        onSave: (updated) async {
          await ref.read(chemicalSdsSor1ListProvider.notifier).saveSdsSor1(updated);
        },
      ),
    );
  }

  void _confirmDeleteSdsSor1(ChemicalSdsSor1Model item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบแบบ สอ.๑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('คุณต้องการลบข้อมูลความปลอดภัย แบบ สอ.๑ สำหรับ "${item.tradeName}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (item.id != null) {
                await ref.read(chemicalSdsSor1ListProvider.notifier).deleteSdsSor1(item.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 3 (Form สอ.๓ ๒๕๖๕) Dialogs & Actions
  // --------------------------------------------------------------------------
  void _openAddMeasurementSor3Dialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SdsSor3MeasurementDialog(
        onSave: (item, certPath) async {
          await ref.read(chemicalMeasurementSor3ListProvider.notifier).saveMeasurementSor3(item, newCertPath: certPath);
        },
      ),
    );
  }

  void _openEditMeasurementSor3Dialog(ChemicalMeasurementSor3Model item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SdsSor3MeasurementDialog(
        initialItem: item,
        onSave: (updated, certPath) async {
          await ref.read(chemicalMeasurementSor3ListProvider.notifier).saveMeasurementSor3(updated, newCertPath: certPath);
        },
      ),
    );
  }

  void _confirmDeleteMeasurementSor3(ChemicalMeasurementSor3Model item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบรายงาน สอ.๓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('คุณต้องการลบรายงานการตรวจวัดในบรรยากาศ เลขที่ "${item.documentNo}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (item.id != null) {
                await ref.read(chemicalMeasurementSor3ListProvider.notifier).deleteMeasurementSor3(item.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab1InventoryRegister(),
          _buildTab2SorOr1(),
          _buildTab3SorOr3Measurement(),
          _buildTab4LegalLibrary(),
        ],
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddChemicalDialog,
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('ขึ้นทะเบียนสารเคมีใหม่', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
            )
          : tabIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: _openAddSdsSor1Dialog,
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text('จัดทำแบบ สอ.๑ ใหม่', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                )
              : tabIndex == 2
                  ? FloatingActionButton.extended(
                      onPressed: _openAddMeasurementSor3Dialog,
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.speed_rounded),
                      label: Text('บันทึกรายงาน สอ.๓ ใหม่', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                    )
                  : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'การจัดการสารเคมีอันตรายและ SDS (Chemical & SDS Management)',
                style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                'มาตรฐานราชกิจจานุเบกษา: ๑,๕๑๖ สารเคมี • ๓๒๔ TLV • แบบ สอ.๑ • แบบ สอ.๓ ๒๕๖๕',
                style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF1E3A8A),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(icon: Icon(Icons.inventory_rounded, size: 18), text: 'ทะเบียนสารเคมี & SDS'),
          Tab(icon: Icon(Icons.description_rounded, size: 18), text: 'ข้อมูลความปลอดภัย (สอ.๑)'),
          Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'ตรวจวัดในบรรยากาศ (สอ.๓)'),
          Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'คลังเอกสารกฎหมาย'),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: ทะเบียนสารเคมี & SDS Tracking
  // ==========================================================================
  Widget _buildTab1InventoryRegister() {
    final kpiAsync = ref.watch(chemicalKpiStatsProvider);
    final inventoryAsync = ref.watch(chemicalInventoryProvider);
    final locationsAsync = ref.watch(chemicalStorageLocationsProvider);

    final currentQuery = ref.watch(chemicalSearchQueryProvider);
    final currentExpiryFilter = ref.watch(chemicalSdsExpiryFilterProvider);
    final currentLocationFilter = ref.watch(chemicalLocationFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chemicalInventoryProvider);
        ref.invalidate(chemicalKpiStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Metric Summary Cards
            kpiAsync.when(
              data: (stats) => _buildKpiRow(stats),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),

            // Search & Filter Toolbar
            _buildSearchAndFilterBar(locationsAsync, currentQuery, currentExpiryFilter, currentLocationFilter),
            const SizedBox(height: 16),

            // Chemical Cards List
            inventoryAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyInventoryState();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildChemicalInventoryCard(item);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(({int total, int validSds, int nearExpiry, int expired, double totalQtySolidKg, double totalQtyLiquidL}) stats) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'สารเคมีในครอบครอง',
            value: '${stats.total}',
            subtitle: 'รายการทั้งหมด',
            icon: Icons.science_rounded,
            color: const Color(0xFF1E3A8A),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            title: 'เอกสาร SDS ปกติ',
            value: '${stats.validSds}',
            subtitle: 'อายุเอกสารสมบูรณ์',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            title: 'ใกล้หมดอายุ (<=90 วัน)',
            value: '${stats.nearExpiry}',
            subtitle: 'ต้องเตรียมทบทวน',
            icon: Icons.access_time_filled_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            title: 'SDS หมดอายุแล้ว',
            value: '${stats.expired}',
            subtitle: 'ต้องปรับปรุงทันที',
            icon: Icons.warning_rounded,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  title,
                  style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    AsyncValue<List<String>> locationsAsync,
    String currentQuery,
    SdsExpiryStatus? currentExpiryFilter,
    String currentLocationFilter,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) {
                ref.read(chemicalSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อการค้า, ชื่อทางเคมี, CAS No., สถานที่...',
                hintStyle: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF1E3A8A)),
                suffixIcon: currentQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => ref.read(chemicalSearchQueryProvider.notifier).state = '',
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<SdsExpiryStatus?>(
              value: currentExpiryFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'สถานะอายุ SDS',
                labelStyle: GoogleFonts.prompt(fontSize: 11),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('ทุกสถานะ SDS', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SdsExpiryStatus.normal, child: Text('🟢 ปกติ (>90 วัน)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SdsExpiryStatus.near90, child: Text('🟡 ใกล้หมดอายุ (90 วัน)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SdsExpiryStatus.near60, child: Text('🟠 ใกล้หมดอายุ (60 วัน)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SdsExpiryStatus.near30, child: Text('🔴 ใกล้หมดอายุ (30 วัน)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SdsExpiryStatus.expired, child: Text('⛔ หมดอายุแล้ว', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) {
                ref.read(chemicalSdsExpiryFilterProvider.notifier).state = val;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: locationsAsync.when(
              data: (locations) {
                final items = ['ALL', ...locations];
                final sel = items.contains(currentLocationFilter) ? currentLocationFilter : 'ALL';
                return DropdownButtonFormField<String>(
                  value: sel,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'สถานที่จัดเก็บ',
                    labelStyle: GoogleFonts.prompt(fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: items.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(loc == 'ALL' ? 'ทุกสถานที่จัดเก็บ' : loc, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    ref.read(chemicalLocationFilterProvider.notifier).state = val ?? 'ALL';
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalInventoryCard(ChemicalInventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isExpired ? Colors.red.shade200 : Colors.grey.shade200,
          width: item.isExpired ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.physicalState.toUpperCase() == 'GAS'
                      ? Icons.propane_tank_rounded
                      : item.physicalState.toUpperCase() == 'SOLID'
                          ? Icons.grain_rounded
                          : Icons.water_drop_rounded,
                  color: const Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.tradeName,
                            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'CAS: ${item.casNumber}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontFamily: 'monospace'),
                          ),
                        ),
                        if (item.unNumber != null && item.unNumber!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.unNumber!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.chemicalNameTh} • ${item.chemicalNameEn}',
                      style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.sdsBadgeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item.sdsBadgeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.sdsBadgeIcon, size: 14, color: item.sdsBadgeColor),
                    const SizedBox(width: 6),
                    Text(
                      item.sdsBadgeText,
                      style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold, color: item.sdsBadgeColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openEditChemicalDialog(item);
                  } else if (val == 'delete') {
                    _confirmDeleteChemical(item);
                  } else if (val == 'sds' && item.sdsFilePath != null) {
                    _viewDocument(
                      item.sdsFilePath!,
                      'เอกสาร SDS: ${item.tradeName}',
                      subtitle: 'จัดทำเมื่อ: ${item.sdsIssueDate} (รอบทบทวน ${item.sdsExpiryYears} ปี)',
                      casNumber: item.casNumber,
                    );
                  } else if (val == 'label' && item.labelImagePath != null) {
                    _viewDocument(
                      item.labelImagePath!,
                      'รูปถ่ายฉลาก: ${item.tradeName}',
                      subtitle: item.storageLocation,
                      casNumber: item.casNumber,
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  if (item.sdsFilePath != null)
                    const PopupMenuItem(
                      value: 'sds',
                      child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.blue), SizedBox(width: 8), Text('ดูเอกสาร SDS')]),
                    ),
                  if (item.labelImagePath != null)
                    const PopupMenuItem(
                      value: 'label',
                      child: Row(children: [Icon(Icons.image_rounded, size: 18, color: Colors.teal), SizedBox(width: 8), Text('ดูรูปฉลากสารเคมี')]),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Colors.indigo), SizedBox(width: 8), Text('แก้ไขข้อมูล')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('ลบรายการ')]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          item.storageLocation,
                          style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('ปริมาณ: ', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade600)),
                        Text('${item.quantity} ${item.unit}', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        if (item.maxCapacity != null && item.maxCapacity! > 0) ...[
                          Text(' / ความจุ ${item.maxCapacity} ${item.unit}', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade500)),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สัญลักษณ์อันตราย GHS:', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    GhsPictogramsDisplayRow(codes: item.ghsPictograms, iconSize: 20),
                  ],
                ),
              ),
              NfpaDiamondWidget(
                health: item.nfpaHealth ?? 0,
                flammability: item.nfpaFlammability ?? 0,
                instability: item.nfpaInstability ?? 0,
                special: item.nfpaSpecial,
                size: 56,
              ),
              const SizedBox(width: 12),
              if (item.sdsFilePath != null)
                ElevatedButton.icon(
                  onPressed: () {
                    _viewDocument(
                      item.sdsFilePath!,
                      'เอกสาร SDS: ${item.tradeName}',
                      subtitle: 'จัดทำเมื่อ: ${item.sdsIssueDate}',
                      casNumber: item.casNumber,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('ดู SDS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _openEditChemicalDialog(item),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('แนบ SDS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventoryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('ยังไม่มีรายการสารเคมีอันตรายในทะเบียน', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(height: 6),
          Text(
            'ค้นหาจากฐานข้อมูล ๑,๕๑๖ สารเคมีตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน แล้วกดขึ้นทะเบียนสารเคมี',
            style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddChemicalDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('ขึ้นทะเบียนสารเคมีแรก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: แบบ สอ.๑ (SDS 16 หัวข้อ)
  // ==========================================================================
  Widget _buildTab2SorOr1() {
    final sor1ListAsync = ref.watch(chemicalSdsSor1ListProvider);
    final searchQuery = ref.watch(chemicalSor1SearchQueryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(chemicalSdsSor1ListProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แบบ สอ.๑: บัญชีรายชื่อสารเคมีอันตรายและข้อมูลความปลอดภัย ๑๖ หัวข้อ (SDS)',
                          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัย (แบบ สอ.๑)',
                          style: GoogleFonts.prompt(fontSize: 12, color: Colors.blue.shade100),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddSdsSor1Dialog,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('จัดทำแบบ สอ.๑'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search Filter
            TextField(
              onChanged: (val) {
                ref.read(chemicalSor1SearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'ค้นหาแบบ สอ.๑ ตามชื่อการค้า, CAS No., สูตรเคมี...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => ref.read(chemicalSor1SearchQueryProvider.notifier).state = '',
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),

            // Live Sor.Or.1 List
            sor1ListAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptySor1State();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildSor1Card(item);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล สอ.๑: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 16 GHS Headings Summary
            Text('โครงสร้างมาตรฐาน ๑๖ หมวดหมู่ตามระบบ GHS (UN GHS Rev.8):', style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSor1SectionCard('๑. ข้อมูลสารเคมีและผู้ผลิต', 'ชื่อการค้า, สูตร, CAS, UN, ผู้ผลิต, เบอร์ฉุกเฉิน 24 ชม.'),
                _buildSor1SectionCard('๒. การบ่งชี้ความเป็นอันตราย', 'GHS Classification, รูปสัญลักษณ์ ๙ แบบ, คำสัญญาณ, H/P Statements'),
                _buildSor1SectionCard('๓. ส่วนผสมและสารประกอบ', 'CAS Number, ร้อยละโดยน้ำหนัก (%wt), TLV/PEL, LD50'),
                _buildSor1SectionCard('๔. มาตรการปฐมพยาบาล', 'สูดดม, สัมผัสผิวหนัง, สัมผัสตา, กลืนกิน, การดูแลพิเศษ'),
                _buildSor1SectionCard('๕. มาตรการผจญเพลิง', 'สารดับเพลิงที่เหมาะสม/ห้ามใช้, ความเสี่ยงเฉพาะ, อุปกรณ์ SCBA'),
                _buildSor1SectionCard('๖. การจัดการเมื่อหกรั่วไหล', 'ข้อควรระวังส่วนบุคคล, วิธีดูดซับ/กักเก็บ, การป้องกันสิ่งแวดล้อม'),
                _buildSor1SectionCard('๗. การขนถ่ายและจัดเก็บ', 'การปฏิบัติงานปลอดภัย, เงื่อนไขจัดเก็บ, สารที่เข้ากันไม่ได้'),
                _buildSor1SectionCard('๘. การควบคุมการรับสัมผัส/PPE', 'ค่ามาตรฐาน TLV/PEL, วิศวกรรมระบายอากาศ, แว่นตา, ถุงมือ, หน้ากาก'),
                _buildSor1SectionCard('๙. คุณสมบัติทางกายภาพและเคมี', 'สถานะ, สี, กลิ่น, pH, จุดเดือด, จุดวาบไฟ, ความดันไอ, ความถ่วงจำเพาะ'),
                _buildSor1SectionCard('๑๐. ความเสถียรและความไวต่อปฏิกิริยา', 'ความคงตัวทางเคมี, สภาวะที่ต้องหลีกเลี่ยง, สารสลายตัวอันตราย'),
                _buildSor1SectionCard('๑๑. ข้อมูลด้านพิษวิทยา', 'LD50/LC50, สารก่อมะเร็ง IARC/ACGIH, พิษต่อระบบสืบพันธุ์/อวัยวะเป้าหมาย'),
                _buildSor1SectionCard('๑๒. ข้อมูลผลกระทบต่อระบบนิเวศน์', 'ความเป็นพิษต่อสิ่งแวดล้อมทางน้ำ (LC50/EC50), การย่อยสลาย, Bioaccumulation'),
                _buildSor1SectionCard('๑๓. ข้อพิจารณาในการกำจัด', 'วิธีกำจัดของเสียสารเคมี, บรรจุภัณฑ์ปนเปื้อน, กฎหมายกรมโรงงานฯ'),
                _buildSor1SectionCard('๑๔. ข้อมูลการขนส่ง', 'UN Number, Proper Shipping Name, Class 1-9, Packing Group'),
                _buildSor1SectionCard('๑๕. ข้อมูลกฎหมายและข้อบังคับ', 'พ.ร.บ. วัตถุอันตราย, กฎกระทรวงสารเคมี ๒๕๕๖, พ.ร.บ. โรงงาน'),
                _buildSor1SectionCard('๑๖. ข้อมูลอื่นๆ', 'NFPA 704 Diamond, วันจัดทำ/ทบทวน SDS, เอกสารอ้างอิง'),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSor1Card(ChemicalSdsSor1Model item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.tradeName,
                            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'CAS: ${item.casNumber}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontFamily: 'monospace'),
                          ),
                        ),
                        if (item.unNumber != null && item.unNumber!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF475569).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(item.unNumber!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ผู้ผลิต/จำหน่าย: ${item.manufacturerImporterInfo.isNotEmpty ? item.manufacturerImporterInfo : "-"} • ทบทวนเมื่อ: ${item.revisionDate ?? "-"} (Rev. ${item.versionNo ?? "1.0"})',
                      style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text('ครบ ๑๖ หมวดหมู่', style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openEditSdsSor1Dialog(item);
                  } else if (val == 'delete') {
                    _confirmDeleteSdsSor1(item);
                  } else if (val == 'pdf') {
                    ChemicalSor1PdfService.printOrShare(context, item);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.blue), SizedBox(width: 8), Text('ส่งออก PDF (สอ.๑)')]),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Colors.indigo), SizedBox(width: 8), Text('แก้ไขข้อมูล')]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('ลบรายการ')]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Detail row with Pictograms & NFPA
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สัญลักษณ์อันตราย GHS:', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    GhsPictogramsDisplayRow(codes: item.ghsPictograms, iconSize: 22),
                  ],
                ),
              ),
              if (item.ingredients.isNotEmpty) ...[
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ส่วนประกอบ (${item.ingredients.length} สาร):', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      Text(
                        item.ingredients.map((i) => '${i.chemicalName} (${i.percentage}%)').join(', '),
                        style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF334155)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              NfpaDiamondWidget(
                health: item.nfpaHealth,
                flammability: item.nfpaFlammability,
                instability: item.nfpaInstability,
                special: item.nfpaSpecial,
                size: 56,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => ChemicalSor1PdfService.printOrShare(context, item),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('พิมพ์ / ส่งออก PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySor1State() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('ยังไม่มีการจัดทำข้อมูลความปลอดภัยสารเคมี แบบ สอ.๑', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(height: 4),
          Text('กดปุ่ม "จัดทำแบบ สอ.๑" ด้านบนเพื่อบันทึกข้อมูลความปลอดภัยสารเคมี ๑๖ หัวข้อตามกฎหมาย', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddSdsSor1Dialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('จัดทำแบบ สอ.๑ ฉบับแรก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSor1SectionCard(String title, String desc) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF475569))),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: แบบ สอ.๓ ๒๕๖๕ & TLV Evaluator
  // ==========================================================================
  Widget _buildTab3SorOr3Measurement() {
    final sor3ListAsync = ref.watch(chemicalMeasurementSor3ListProvider);
    final kpiAsync = ref.watch(chemicalMeasurementKpiProvider);
    final resultFilter = ref.watch(chemicalSor3ResultFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chemicalMeasurementSor3ListProvider);
        ref.invalidate(chemicalMeasurementKpiProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แบบ สอ.๓: รายงานผลการตรวจวัดระดับความเข้มข้นสารเคมีในบรรยากาศ (พ.ศ. ๒๕๖๕)',
                          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'รองรับการบันทึกผู้ตรวจวัดขึ้นทะเบียนตาม มาตรา ๙ (นิติบุคคล) และ มาตรา ๑๑ (บุคคลธรรมดา) แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔',
                          style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFFA7F3D0)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddMeasurementSor3Dialog,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('บันทึกรายงาน สอ.๓'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF065F46),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Measurement KPI Summary Cards
            kpiAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'การตรวจวัดทั้งหมด',
                      value: '${stats.total}',
                      subtitle: 'รายงานทั้งหมด',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF065F46),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'ผ่านเกณฑ์มาตรฐาน',
                      value: '${stats.passCount}',
                      subtitle: 'ไม่เกิน 50% TLV',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'ระดับปฏิบัติการ (Action Level)',
                      value: '${stats.actionLevelCount}',
                      subtitle: '50% - 100% TLV',
                      icon: Icons.warning_rounded,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'เกินเกณฑ์มาตรฐาน (Fail)',
                      value: '${stats.failCount}',
                      subtitle: 'ต้องปรับปรุงด่วน',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),

            // Live Sor.Or.3 Reports List
            Text('รายการรายงานผลการตรวจวัดในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕):', style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            sor3ListAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptySor3State();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildSor3Card(item);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล สอ.๓: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Interactive TLV Auto-Evaluation Engine Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      Text(
                        'เครื่องมือคำนวณและประเมินผลค่าขีดจำกัดความเข้มข้นตามกฎหมาย (๓๒๔ สารเคมี)',
                        style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Controls
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<int>(
                          value: _selectedTlvChemical?.sequenceNo,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'เลือกสารเคมีมาตรฐาน TLV (324 รายการ)',
                            labelStyle: GoogleFonts.prompt(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: Chemical324TlvData.tlvList.map((item) {
                            return DropdownMenuItem(
                              value: item.sequenceNo,
                              child: Text(
                                '#${item.sequenceNo} ${item.thaiName} (${item.englishName}) [${item.casNumber ?? "No CAS"}]',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (seq) {
                            if (seq != null) {
                              setState(() {
                                _selectedTlvChemical = Chemical324TlvData.findBySequence(seq);
                              });
                              _runTlvEvaluation();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _measuredValController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _runTlvEvaluation(),
                          decoration: InputDecoration(
                            labelText: 'ค่าที่ตรวจวัดได้',
                            labelStyle: GoogleFonts.prompt(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'หน่วยวัด',
                            labelStyle: GoogleFonts.prompt(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ppm', child: Text('ppm (ส่วนในล้านส่วน)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'mg/m3', child: Text('mg/m³ (มก./ลบ.ม.)', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (u) {
                            setState(() => _selectedUnit = u ?? 'ppm');
                            _runTlvEvaluation();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedSamplingType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'ประเภทการวัด',
                            labelStyle: GoogleFonts.prompt(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TWA_8HR', child: Text('TWA (เฉลี่ย 8 ชม.)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'STEL_15MIN', child: Text('STEL (15 นาที)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'CEILING', child: Text('Ceiling (เพดานสูงสุด)', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (t) {
                            setState(() => _selectedSamplingType = t ?? 'TWA_8HR');
                            _runTlvEvaluation();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Evaluation Result Box
                  if (_tlvQuickResult != null && _selectedTlvChemical != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _tlvQuickResult!.statusBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _tlvQuickResult!.statusColor.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(_tlvQuickResult!.statusIcon, size: 36, color: _tlvQuickResult!.statusColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _tlvQuickResult!.statusBadgeLabelTh,
                                      style: GoogleFonts.prompt(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _tlvQuickResult!.statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'ค่ามาตรฐานกฎหมาย: ${_tlvQuickResult!.standardLimit != null ? "${_tlvQuickResult!.standardLimit} ${_tlvQuickResult!.unit}" : "ไม่มีขีดจำกัดเฉพาะ"}',
                                      style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tlvQuickResult!.messageTh,
                                  style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSor3Card(ChemicalMeasurementSor3Model item) {
    final isSec9 = item.surveyorType == 'SECTION_9';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.statusBadgeColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.statusBadgeBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.speed_rounded, color: item.statusBadgeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'เลขที่: ${item.documentNo}',
                          style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'วันที่ตรวจวัด: ${item.assessmentDate}',
                            style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF0D9488), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSec9 ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSec9 ? 'ม.๙: ${item.serviceProviderM9RegNo ?? "นิติบุคคล"}' : 'ม.๑๑: ${item.serviceProviderM11CertNo ?? "บุคคลธรรมดา"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSec9 ? const Color(0xFF1D4ED8) : const Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'สารเคมี: ${item.chemicalName} (CAS: ${item.casNumber}) • แผนก/พื้นที่: ${item.workplaceArea}',
                      style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.statusBadgeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item.statusBadgeColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  item.statusBadgeLabelTh,
                  style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold, color: item.statusBadgeColor),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openEditMeasurementSor3Dialog(item);
                  } else if (val == 'delete') {
                    _confirmDeleteMeasurementSor3(item);
                  } else if (val == 'pdf') {
                    ChemicalSor3PdfService.printOrShare(context, item);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.blue), SizedBox(width: 8), Text('ส่งออก PDF (สอ.๓)')]),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Colors.indigo), SizedBox(width: 8), Text('แก้ไขข้อมูล')]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('ลบรายงาน')]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Values comparison row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'ค่าที่ตรวจวัดได้: ${item.measuredValue} ${item.unit} (มาตรฐาน: ${item.tlvStandardValue} ${item.unit})  |  สัดส่วน: ${item.ratioPercentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ผู้ตรวจวัด: ${item.serviceProviderName}',
                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => ChemicalSor3PdfService.printOrShare(context, item),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('พิมพ์ / ส่งออก PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF065F46),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySor3State() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.speed_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('ยังไม่มีรายงานการตรวจวัดในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕)', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(height: 4),
          Text('กดปุ่ม "บันทึกรายงาน สอ.๓" ด้านบนเพื่อบันทึกผลการตรวจวัดและเปรียบเทียบกับขีดจำกัดความเข้มข้นตามกฎหมาย', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddMeasurementSor3Dialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('บันทึกรายงาน สอ.๓ ฉบับแรก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF065F46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: คลังเอกสารกฎหมายอ้างอิงราชกิจจานุเบกษา
  // ==========================================================================
  Widget _buildTab4LegalLibrary() {
    final laws = ref.watch(chemicalLawsListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คลังเอกสารกฎหมายความปลอดภัยสารเคมีอันตราย (ราชกิจจานุเบกษา)',
                        style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รวบรวมพระราชบัญญัติ กฎกระทรวง และประกาศกรมสวัสดิการและคุ้มครองแรงงานฉบับสมบูรณ์',
                        style: GoogleFonts.prompt(fontSize: 12, color: Colors.indigo.shade100),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search Box
          TextField(
            onChanged: (val) {
              ref.read(chemicalLawSearchQueryProvider.notifier).state = val;
            },
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อกฎหมาย, ประกาศกรมฯ, เลขราชกิจจานุเบกษา...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Laws Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: laws.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final law = laws[index];
              return _buildLawCard(law);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLawCard(ChemicalLawItem law) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: law.categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(law.categoryIcon, color: law.categoryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: law.categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            law.categoryLabelTh,
                            style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.bold, color: law.categoryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          law.gazetteCitation,
                          style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      law.titleTh,
                      style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      law.titleEn,
                      style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              law.summary,
              style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF334155), height: 1.4),
            ),
          ),
          if (law.keyProvisions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('สาระสำคัญและข้อกำหนดตามกฎหมาย:', style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            ...law.keyProvisions.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                    Expanded(
                      child: Text(p, style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF475569))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
