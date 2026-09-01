import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/environmental_gazette_data.dart';
import '../providers/environment_providers.dart';
import '../widgets/gazette_detail_dialog.dart';

/// Tab 3: Royal Thai Government Gazette Statutory Repository (Act 2554, Reg 2559, Light 2561, Noise 2561, Heat 2563, Reporting Form 2563).
class EnvironmentGazetteTab extends ConsumerStatefulWidget {
  const EnvironmentGazetteTab({Key? key}) : super(key: key);

  @override
  ConsumerState<EnvironmentGazetteTab> createState() => _EnvironmentGazetteTabState();
}

class _EnvironmentGazetteTabState extends ConsumerState<EnvironmentGazetteTab> {
  String _selectedCategory = 'ALL';

  void _openDetailDialog(EnvironmentalGazetteItem item) {
    showDialog(
      context: context,
      builder: (ctx) => GazetteDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(envGazetteSearchQueryProvider);

    var items = EnvironmentalGazetteData.search(query);
    if (_selectedCategory != 'ALL') {
      items = items.where((e) => e.category == _selectedCategory).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Top Banner
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
              BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
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
                          'คลังกฎหมายสิ่งแวดล้อมราชกิจจานุเบกษา (Royal Gazette Repository)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'รวบรวม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวงฯ ๒๕๕๙ และประกาศกรมสวัสดิการและคุ้มครองแรงงานทุกฉบับ',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatutoryTag('พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ (ม.๘, ๙, ๑๑, ๑๕)'),
                  _buildStatutoryTag('กฎกระทรวงความร้อน แสงสว่าง เสียง ๒๕๕๙'),
                  _buildStatutoryTag('มาตรฐานแสงสว่าง ๒๕๖๑'),
                  _buildStatutoryTag('มาตรฐานระดับเสียง ๒๕๖๑'),
                  _buildStatutoryTag('การคำนวณ WBGT ๒๕๖๓'),
                  _buildStatutoryTag('แบบรายงาน สสค. ๒๕๖๓'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search & Category Filter Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหากฎหมาย, ประกาศกรมฯ, มาตรา, หรือเกณฑ์มาตรฐาน...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (v) {
                  ref.read(envGazetteSearchQueryProvider.notifier).state = v;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text('หมวดหมู่กฎหมาย:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildCategoryChip('ทั้งหมด (${EnvironmentalGazetteData.gazetteList.length})', 'ALL'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('พระราชบัญญัติ (Acts)', 'PRIMARY_ACT'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('กฎกระทรวง (Regulations)', 'MINISTERIAL_REGULATION'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('ประกาศกรมฯ (DLPW Notifications)', 'DLPW_NOTIFICATION'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gazette Items Cards
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('ไม่พบเอกสารกฎหมายที่ค้นหา', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ลองใช้คำค้นอื่น หรือเลือกแสดงทุกหมวดหมู่', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return _buildGazetteCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildStatutoryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String code) {
    final isSelected = _selectedCategory == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = code),
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildGazetteCard(EnvironmentalGazetteItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.lawId,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.category == 'PRIMARY_ACT'
                      ? 'พระราชบัญญัติแม่บท'
                      : (item.category == 'MINISTERIAL_REGULATION' ? 'กฎกระทรวง' : 'ประกาศกรมฯ'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                const Spacer(),
                Text(
                  'ประกาศ: ${item.publishedDate}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
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
                Text(
                  item.titleTh,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  item.titleEn,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'ราชกิจจานุเบกษา: ${item.gazetteVolume} ${item.gazettePart} ${item.gazettePage}  |  หน่วยงาน: ${item.governingAuthority}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    item.summaryTh,
                    style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF334155)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'บทกำหนดโทษ: ${item.penaltySummary}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openDetailDialog(item),
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text('เปิดอ่านฉบับเต็ม / รายละเอียด'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
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
}
