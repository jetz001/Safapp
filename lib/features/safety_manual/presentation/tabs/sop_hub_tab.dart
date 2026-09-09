import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sop_model.dart';
import '../notifiers/sop_providers.dart';
import '../widgets/sop_editor_dialog.dart';
import '../widgets/sop_reader_dialog.dart';

class SopHubTab extends ConsumerStatefulWidget {
  const SopHubTab({super.key});

  @override
  ConsumerState<SopHubTab> createState() => _SopHubTabState();
}

class _SopHubTabState extends ConsumerState<SopHubTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSopDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SopEditorDialog(
        onSave: (newSop) {
          ref.read(sopListProvider.notifier).saveSop(newSop);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกขั้นตอนการปฏิบัติงาน "${newSop.docCode}" เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showReaderDialog(SopModel sop) {
    showDialog(
      context: context,
      builder: (ctx) => SopReaderDialog(
        sop: sop,
        onUpdate: (updated) {
          ref.read(sopListProvider.notifier).saveSop(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัปเดตข้อมูล "${updated.docCode}" เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onDelete: (id) {
          ref.read(sopListProvider.notifier).deleteSop(id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบเอกสารเรียบร้อยแล้ว'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sopsAsync = ref.watch(sopListProvider);
    final kpi = ref.watch(sopKpiSummaryProvider);
    final selectedCategory = ref.watch(sopCategoryFilterProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action Bar Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'คลังขั้นตอนปฏิบัติงานความปลอดภัย (SOPs Hub)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Standard Operating Procedures จัดการ แก้ไข ค้นหา และทบทวนตามรอบเวลา',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddSopDialog,
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('สร้างคู่มือ SOP ใหม่ (+)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // KPI Metric Cards
        Row(
          children: [
            _buildMetricCard('เอกสารทั้งหมด', '${kpi.totalSops} ฉบับ', Icons.folder_open, const Color(0xFF0284C7)),
            const SizedBox(width: 12),
            _buildMetricCard('ใช้งานอยู่ (Active)', '${kpi.activeSops} ฉบับ', Icons.check_circle_outline, const Color(0xFF16A34A)),
            const SizedBox(width: 12),
            _buildMetricCard('ถึงกำหนดทบทวน (Overdue)', '${kpi.overdueSops} ฉบับ', Icons.warning_amber_rounded, const Color(0xFFDC2626)),
            const SizedBox(width: 12),
            _buildMetricCard('เตือนทบทวน (ใน 30 วัน)', '${kpi.warningSops} ฉบับ', Icons.access_time, const Color(0xFFD97706)),
          ],
        ),
        const SizedBox(height: 16),

        // Search & Filter Box
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาด้วยรหัสเอกสาร (เช่น SOP-MCH), ชื่อเรื่อง, หรือข้อควรระวัง...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(sopSearchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => ref.read(sopSearchQueryProvider.notifier).setQuery(v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('ทั้งหมด', 'ALL', Icons.all_inclusive, selectedCategory),
                      _buildCategoryChip('เครื่องจักร & ปั้นจั่น', 'MACHINERY', Icons.precision_manufacturing, selectedCategory),
                      _buildCategoryChip('ระบบไฟฟ้า & LOTO', 'ELECTRICAL', Icons.bolt, selectedCategory),
                      _buildCategoryChip('สารเคมีอันตราย', 'CHEMICAL', Icons.science, selectedCategory),
                      _buildCategoryChip('ที่อับอากาศ', 'CONFINED_SPACE', Icons.door_front_door, selectedCategory),
                      _buildCategoryChip('ทำงานบนที่สูง', 'HEIGHTS', Icons.stairs, selectedCategory),
                      _buildCategoryChip('ระงับอัคคีภัย & ฉุกเฉิน', 'EMERGENCY', Icons.local_fire_department, selectedCategory),
                      _buildCategoryChip('อุปกรณ์ PPE', 'PPE', Icons.health_and_safety, selectedCategory),
                      _buildCategoryChip('ทั่วไป', 'GENERAL', Icons.menu_book, selectedCategory),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // SOP List View
        sopsAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
          ),
          error: (err, _) => Center(
            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (sops) {
            if (sops.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        selectedCategory == 'ALL'
                            ? 'ยังไม่มีคู่มือขั้นตอนการปฏิบัติงาน (SOP) ในระบบ'
                            : 'ไม่มีเอกสารในหมวดหมู่ที่เลือก (โรงงานอาจไม่มีงานส่วนนี้)',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กดปุ่ม "สร้างคู่มือ SOP ใหม่ (+)" เพื่อเริ่มเขียนขั้นตอนการทำงาน',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sops.length,
              itemBuilder: (ctx, i) {
                final sop = sops[i];
                return _buildSopCard(sop);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, IconData icon, String selectedValue) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blueGrey),
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF0284C7),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) {
          ref.read(sopCategoryFilterProvider.notifier).setCategory(value);
        },
      ),
    );
  }

  Widget _buildSopCard(SopModel sop) {
    final hasPdf = sop.pdfFilePath != null && sop.pdfFilePath!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReaderDialog(sop),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sop.categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(sop.categoryIcon, color: sop.categoryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text(sop.docCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sop.categoryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sop.categoryTh,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sop.categoryColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(sop.revision, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const Spacer(),
                            if (hasPdf) ...[
                              Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text('มีไฟล์ PDF', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                            ],
                            _buildCardReviewBadge(sop),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sop.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        if (sop.purpose != null && sop.purpose!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            sop.purpose!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_list_numbered, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${sop.steps.length} ขั้นตอน', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${sop.requiredPpeList.length} อุปกรณ์ PPE', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      if (sop.author != null && sop.author!.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'ผู้จัดทำ: ${sop.author}',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'วันที่: ${sop.effectiveDate.toIso8601String().substring(0, 10)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardReviewBadge(SopModel sop) {
    if (sop.isReviewDue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade200)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 12, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text('เกินกำหนดทบทวน', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (sop.isReviewWarning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade300)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: Colors.amber.shade800),
            const SizedBox(width: 4),
            Text('ใกล้ครบกำหนด', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text('ใช้งานปกติ', style: TextStyle(color: Colors.green.shade800, fontSize: 11)),
    );
  }
}
