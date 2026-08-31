import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/legal_master_item_model.dart';
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../../domain/models/legal_capa_model.dart';
import '../../data/safety_legal_8_categories_data.dart';
import '../providers/legal_register_providers.dart';
import '../widgets/legal_kpi_dashboard.dart';
import '../widgets/legal_filter_bar.dart';
import '../widgets/legal_assessment_dialog.dart';
import '../widgets/legal_capa_dialog.dart';
import '../widgets/legal_gazette_viewer_dialog.dart';

/// Main screen for the SAFAPP Legal Register module featuring 3 statutory interactive tabs:
/// - Tab 1: ทะเบียนและการประเมินความสอดคล้อง (Legal Register & Compliance Assessment)
/// - Tab 2: คลังกฎหมายราชกิจจานุเบกษา (Royal Gazette Legal Repository - 8 Laws & 32 Items)
/// - Tab 3: แผนการปรับปรุงแก้ไข (CAPA Action Plan Tracker)
class LegalPage extends ConsumerStatefulWidget {
  const LegalPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends ConsumerState<LegalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref.read(legalSelectedTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Dialog Openers
  // --------------------------------------------------------------------------

  void _openAssessmentDialog(LegalComplianceAssessmentModel item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LegalAssessmentDialog(
        assessment: item,
        onSaved: (_) {
          ref.invalidate(legalAssessmentListProvider);
          ref.invalidate(legalComplianceKpiProvider);
        },
        onCreateCapa: (assessedItem) {
          _openCreateCapaDialog(linkedAssessment: assessedItem);
        },
      ),
    );
  }

  void _openCreateCapaDialog({LegalComplianceAssessmentModel? linkedAssessment}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LegalCapaDialog(
        linkedAssessment: linkedAssessment,
        onSaved: (_) {
          ref.invalidate(legalCapaListProvider);
          ref.invalidate(legalAssessmentListProvider);
          ref.invalidate(legalComplianceKpiProvider);
        },
      ),
    );
  }

  void _openEditCapaDialog(LegalCapaModel capa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LegalCapaDialog(
        capaItem: capa,
        onSaved: (_) {
          ref.invalidate(legalCapaListProvider);
          ref.invalidate(legalAssessmentListProvider);
          ref.invalidate(legalComplianceKpiProvider);
        },
      ),
    );
  }

  void _openGazetteViewer(LegalMasterItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => LegalGazetteViewerDialog(
        masterItem: item,
      ),
    );
  }

  void _openGazetteViewerFromAssessment(LegalComplianceAssessmentModel assessment) async {
    final repo = ref.read(legalRepoProvider);
    final master = await repo.getMasterItemById(assessment.masterItemId);
    if (master != null && mounted) {
      _openGazetteViewer(master);
    } else {
      // Fallback find in dataset
      final fallback = SafetyLegal8CategoriesData.findByItemId(assessment.requirementCode);
      if (fallback != null && mounted) {
        _openGazetteViewer(fallback);
      }
    }
  }

  void _confirmCloseCapa(LegalCapaModel capa) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text('ยืนยันปิดงาน CAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการปิดแผนงาน "${capa.actionTitle}" ใช่หรือไม่?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'ระบุหมายเหตุการปิดงาน / การทวนสอบผล...',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(legalCapaListProvider.notifier).closeCapa(
                    capa.id!,
                    notes: notesController.text.trim(),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ปิดงาน CAPA สำเร็จ'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('ยืนยันปิดงาน'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCapa(LegalCapaModel capa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('ยืนยันการลบ CAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('คุณต้องการลบแผนงาน "${capa.actionTitle}" หรือไม่? การกระทำนี้ไม่สามารถเรียกคืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(legalCapaListProvider.notifier).deleteCapa(capa.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบแผนงาน CAPA แล้ว'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaultAssessments() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('คืนค่าข้อกำหนดเริ่มต้น 32 รายการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('ระบบจะทำการโหลดชุดข้อกำหนดกฎหมายมาตรฐาน ๘ ฉบับ (32 ข้อกำหนด) ใหม่ทั้งหมด คุณต้องการดำเนินการต่อหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(legalAssessmentListProvider.notifier).resetDefaultAssessments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('คืนค่าข้อกำหนด 32 รายการเริ่มต้นเรียบร้อยแล้ว'), backgroundColor: Color(0xFF0D9488)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ทะเบียนกฎหมายความปลอดภัยและการประเมินความสอดคล้อง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
                Text(
                  'Thai OSH Legislation & Royal Gazette Statutory Register (8 Core Regulations)',
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
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'คืนค่าเริ่มต้น 32 ข้อกำหนด',
            onPressed: _confirmResetDefaultAssessments,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0D9488),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0D9488),
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.fact_check_rounded, size: 18),
                  text: 'ทะเบียนและการประเมินความสอดคล้อง (Legal Register)',
                ),
                Tab(
                  icon: Icon(Icons.menu_book_rounded, size: 18),
                  text: 'คลังกฎหมายราชกิจจานุเบกษา (Gazette Library)',
                ),
                Tab(
                  icon: Icon(Icons.assignment_turned_in_rounded, size: 18),
                  text: 'แผนการปรับปรุงแก้ไข (CAPA Plan)',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Legal Register & Compliance Assessment
          _buildTab1AssessmentRegister(),

          // Tab 2: Royal Gazette Repository (8 Laws)
          _buildTab2GazetteRepository(),

          // Tab 3: CAPA Action Plan Tracker
          _buildTab3CapaTracker(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateCapaDialog(),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('เปิดแผนงาน CAPA ใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ==========================================================================
  // TAB 1: Legal Register & Compliance Assessments
  // ==========================================================================
  Widget _buildTab1AssessmentRegister() {
    final assessmentsAsync = ref.watch(legalAssessmentListProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // KPI Dashboard at Top
        const LegalKpiDashboard(),

        // Search & Filter Toolbar
        const LegalFilterBar(activeTab: 0),

        const SizedBox(height: 8),

        // Assessment Items List
        assessmentsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState(
                title: 'ไม่พบรายการข้อกำหนดกฎหมายที่ค้นหา',
                subtitle: 'ลองเปลี่ยนคำค้นหา ปรับตัวกรอง หรือคืนค่าข้อกำหนดเริ่มต้น 32 รายการ',
                onReset: () {
                  ref.read(legalSearchQueryProvider.notifier).clear();
                  ref.read(legalCategoryFilterProvider.notifier).reset();
                  ref.read(legalStatusFilterProvider.notifier).reset();
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildAssessmentCard(item);
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentCard(LegalComplianceAssessmentModel item) {
    final catEnum = item.categoryEnum;
    final riskEnum = item.riskLevelEnum;
    final statusEnum = item.statusEnum;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag Bar: Category, Requirement Code, Risk, Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: catEnum.primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(catEnum.icon, size: 16, color: catEnum.primaryColor),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: catEnum.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.requirementCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    catEnum.titleTh,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: catEnum.primaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskEnum.bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: riskEnum.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    riskEnum.labelTh,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskEnum.color),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusEnum.bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusEnum.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusEnum.icon, size: 14, color: statusEnum.color),
                      const SizedBox(width: 4),
                      Text(
                        statusEnum.labelTh,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: statusEnum.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Law title and article
                Text(
                  '${item.lawTitleTh} (${item.articleNo})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  item.requirementTitle,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  item.requirementDetails,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Actual Practice Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0D9488)),
                          const SizedBox(width: 4),
                          const Text(
                            'การปฏิบัติตามจริงในสถานประกอบการ:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.actualPractice != null && item.actualPractice!.isNotEmpty
                            ? item.actualPractice!
                            : '(ยังไม่ได้บันทึกรายละเอียดการปฏิบัติตามจริง)',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.actualPractice != null && item.actualPractice!.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                          fontStyle: item.actualPractice != null && item.actualPractice!.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Evaluator, Date, Evidence metadata
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'ผู้ประเมิน: ${item.evaluatorName}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'ประเมินเมื่อ: ${item.evaluatedDate}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (item.hasEvidence) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 2),
                            Text(
                              '${item.evidenceFilePaths.length} ไฟล์หลักฐาน',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Action Buttons Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openGazetteViewerFromAssessment(item),
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text('ดูราชกิจจานุเบกษา'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    if (item.requiresCapa) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openCreateCapaDialog(linkedAssessment: item),
                        icon: const Icon(Icons.add_task_rounded, size: 16),
                        label: const Text('เปิด CAPA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openAssessmentDialog(item),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('ประเมินความสอดคล้อง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: Royal Gazette Repository (8 Core Laws)
  // ==========================================================================
  Widget _buildTab2GazetteRepository() {
    final masterAsync = ref.watch(legalMasterListProvider);
    final activeCategory = ref.watch(legalCategoryFilterProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 8 Regulations Scope Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คลังกฎหมายความปลอดภัยราชกิจจานุเบกษา ๘ ฉบับหลัก',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'รวบรวมพระราชบัญญัติและกฎกระทรวงคุ้มครองแรงงาน (DLPW) พร้อมบทกำหนดโทษและเกณฑ์การตรวจประเมิน',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mini Law Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LegalCategoryEnum.values.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          cat.titleTh,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Filter Bar for Tab 2
        const LegalFilterBar(activeTab: 1),

        const SizedBox(height: 14),

        // Master Statutory Items List
        masterAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState(
                title: 'ไม่พบข้อกำหนดกฎหมายราชกิจจานุเบกษา',
                subtitle: 'ลองค้นหาด้วยคำอื่น หรือเลือกแสดงหมวดหมู่ทั้งหมด',
                onReset: () {
                  ref.read(legalMasterSearchQueryProvider.notifier).clear();
                  ref.read(legalCategoryFilterProvider.notifier).reset();
                },
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMasterItemCard(item);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterItemCard(LegalMasterItemModel item) {
    final catEnum = item.categoryEnum;
    final riskEnum = item.riskLevelEnum;
    final gazette = item.gazetteReference;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(catEnum.icon, size: 16, color: const Color(0xFF5EEAD4)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.itemId,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.lawNameTh,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gazette.formattedCitation,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF99F6E4)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.articleNo,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskEnum.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        riskEnum.labelTh,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskEnum.color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Compliance Criteria & Penalty Preview
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เกณฑ์การปฏิบัติตาม: ${item.complianceCriteria}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'บทกำหนดโทษ: ${item.penaltySummary}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'หน่วยงานกำกับดูแล: ${item.governingAuthority}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openGazetteViewer(item),
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: const Text('อ่านฉบับเต็ม / ราชกิจจาฯ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF93C5FD)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(legalRepoProvider);
                            final existing = await repo.getAssessmentByRequirementCode(item.itemId);
                            if (existing != null) {
                              _openAssessmentDialog(existing);
                            } else {
                              final newAss = LegalComplianceAssessmentModel(
                                masterItemId: item.itemId,
                                requirementCode: item.itemId,
                                requirementTitle: item.title,
                                requirementDetails: item.complianceCriteria,
                                category: item.category,
                                lawId: item.lawId,
                                lawTitleTh: item.lawNameTh,
                                articleNo: item.articleNo,
                                riskLevel: item.riskLevel,
                                penaltySummary: item.penaltySummary,
                                evaluatedDate: DateTime.now().toIso8601String().substring(0, 10),
                                evaluatorName: 'จป.วิชาชีพ',
                              );
                              _openAssessmentDialog(newAss);
                            }
                          },
                          icon: const Icon(Icons.fact_check_rounded, size: 16),
                          label: const Text('เริ่มประเมินข้อนี้'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: CAPA Action Plan Tracker
  // ==========================================================================
  Widget _buildTab3CapaTracker() {
    final capasAsync = ref.watch(legalCapaListProvider);
    final statsAsync = ref.watch(legalComplianceKpiProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // CAPA Summary Header Banner
        statsAsync.when(
          data: (stats) => _buildCapaSummaryBanner(stats),
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Search & Filter Toolbar for CAPA
        const LegalFilterBar(activeTab: 2),

        const SizedBox(height: 8),

        // CAPA Items List
        capasAsync.when(
          data: (capas) {
            if (capas.isEmpty) {
              return _buildEmptyState(
                title: 'ไม่พบรายการแผนงาน CAPA',
                subtitle: 'สามารถเปิดแผนงานปรับปรุงแก้ไขใหม่ได้โดยกดปุ่ม "+ เปิดแผนงาน CAPA ใหม่"',
                onReset: () {
                  ref.read(legalCapaSearchQueryProvider.notifier).clear();
                  ref.read(legalCapaStatusFilterProvider.notifier).reset();
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: capas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final capa = capas[index];
                  return _buildCapaCard(capa);
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapaSummaryBanner(dynamic stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ระบบติดตามแผนงานแก้ไขและป้องกัน (CAPA Action Plans)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ติดตามการปิดข้อบกพร่องทางกฎหมายตามกำหนดเวลาเพื่อยกระดับความปลอดภัย',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // KPI Counter Badges
          Row(
            children: [
              _buildCapaCountPill('ทั้งหมด', stats.totalCapaCount, Colors.white, Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 8),
              _buildCapaCountPill('รอดำเนินการ', stats.pendingCapaCount, const Color(0xFF93C5FD), const Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              _buildCapaCountPill('กำลังทำ', stats.inProgressCapaCount, const Color(0xFFFDE68A), const Color(0xFF78350F)),
              const SizedBox(width: 8),
              _buildCapaCountPill('เสร็จสิ้น', stats.completedCapaCount, const Color(0xFF86EFAC), const Color(0xFF065F46)),
              if (stats.overdueCapaCount > 0) ...[
                const SizedBox(width: 8),
                _buildCapaCountPill('เกินกำหนด', stats.overdueCapaCount, const Color(0xFFFCA5A5), const Color(0xFF7F1D1D)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapaCountPill(String label, int count, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapaCard(LegalCapaModel capa) {
    final statusEnum = capa.effectiveStatusEnum;
    final isOverdue = capa.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFF87171) : Colors.grey.shade200,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusEnum.bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(bottom: BorderSide(color: statusEnum.color.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                if (capa.requirementCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      capa.requirementCode!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    capa.actionTitle,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusEnum.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusEnum.icon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusEnum.labelTh,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Root Cause & Actions Grid
                if (capa.rootCause.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology_alt_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'สาเหตุที่แท้จริง (Root Cause): ${capa.rootCause}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'มาตรการแก้ไข: ${capa.correctiveAction}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                      if (capa.preventiveAction != null && capa.preventiveAction!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'มาตรการป้องกัน: ${capa.preventiveAction}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // PIC, Target Date, Days countdown
                Row(
                  children: [
                    Icon(Icons.person_pin_rounded, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'PIC: ${capa.picName} (${capa.picDepartment ?? "-"})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                    const Spacer(),
                    Icon(Icons.event_rounded, size: 16, color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0D9488)),
                    const SizedBox(width: 4),
                    Text(
                      'กำหนดเสร็จ: ${capa.targetDate}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? const Color(0xFFDC2626) : Colors.grey.shade800,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'เกินกำหนด ${-capa.daysRemaining} วัน',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ] else if (!capa.isCompleted && capa.daysRemaining >= 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(เหลือ ${capa.daysRemaining} วัน)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),

                if (capa.isCompleted && capa.completedDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'เสร็จสิ้นเมื่อ: ${capa.completedDate}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                      if (capa.notes != null && capa.notes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '- ${capa.notes}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Card Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (capa.evidenceFilePath != null && capa.evidenceFilePath!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF0D9488)),
                            const SizedBox(width: 4),
                            Text(
                              p.basename(capa.evidenceFilePath!),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                          tooltip: 'ลบ CAPA',
                          onPressed: () => _confirmDeleteCapa(capa),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: () => _openEditCapaDialog(capa),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('แก้ไข'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF93C5FD)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (!capa.isCompleted) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _confirmCloseCapa(capa),
                            icon: const Icon(Icons.task_alt_rounded, size: 16),
                            label: const Text('ปิดงาน (Close)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required VoidCallback onReset,
  }) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('รีเซ็ตตัวกรอง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
