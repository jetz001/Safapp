import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ptw_legal_gazette_data.dart';
import '../../data/datasources/ptw_statutory_master_data.dart';

/// Tab 4: Legal Gazette Library — Thai Safety Regulations Reference
class PtwGazetteTab extends ConsumerStatefulWidget {
  const PtwGazetteTab({super.key});

  @override
  ConsumerState<PtwGazetteTab> createState() => _PtwGazetteTabState();
}

class _PtwGazetteTabState extends ConsumerState<PtwGazetteTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'ALL';

  List<PtwLegalGazetteItem> get _filteredRegulations {
    final all = PtwLegalGazetteData.regulations;
    return all.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.titleTh.contains(_searchQuery) ||
          r.titleEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.summaryTh.contains(_searchQuery) ||
          r.lawId.contains(_searchQuery);
      final matchesCategory = _categoryFilter == 'ALL' || r.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRegulations;

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหากฎหมาย / Search regulations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip('ALL', 'ทั้งหมด', Icons.list),
                    const SizedBox(width: 8),
                    _categoryChip('ACT', 'พ.ร.บ.', Icons.gavel),
                    const SizedBox(width: 8),
                    _categoryChip('MINISTERIAL_REGULATION', 'กฎกระทรวง', Icons.account_balance),
                    const SizedBox(width: 8),
                    _categoryChip('DEPARTMENT_NOTIFICATION', 'ประกาศกรม', Icons.announcement),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Count Bar
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text('พบ ${filtered.length} ฉบับ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('แตะเพื่อดูรายละเอียดกฎหมาย', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),

        // Regulation List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('ไม่พบกฎหมายที่ตรงกัน', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _buildRegulationCard(context, filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _categoryChip(String value, String label, IconData icon) {
    final isSelected = _categoryFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade700)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _categoryFilter = value),
      selectedColor: Colors.orange.shade700,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      showCheckmark: false,
    );
  }

  Widget _buildRegulationCard(BuildContext context, PtwLegalGazetteItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRegulationDetail(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.themeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.themeColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _categoryBadgeColor(item.category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _categoryLabel(item.category),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.titleTh,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.titleEn,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),

              // Gazette Reference
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.gazetteBookVolume}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.announcementDate,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Summary
              Text(
                item.summaryTh,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Key Highlights Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.mandatoryChecklistHighlights.take(3).map((h) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.themeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(h, style: TextStyle(fontSize: 10, color: item.themeColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegulationDetail(BuildContext context, PtwLegalGazetteItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: item.themeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.titleTh,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.titleEn, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gazette Reference Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _gazetteRow('เล่มราชกิจจานุเบกษา', item.gazetteBookVolume),
                            _gazetteRow('วันประกาศ', item.announcementDate),
                            _gazetteRow('วันมีผลบังคับใช้', item.effectiveDate),
                            _gazetteRow('รหัสกฎหมาย', item.lawId),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      const Text('สรุปสาระสำคัญ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(item.summaryTh, style: const TextStyle(fontSize: 13, height: 1.6)),
                      const SizedBox(height: 16),

                      // Key Articles
                      const Text('มาตราและข้อบังคับสำคัญ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ...item.keyArticles.map((article) => _buildArticleCard(article, item.themeColor)),
                      const SizedBox(height: 16),

                      // Mandatory Checklist Highlights
                      const Text('ข้อกำหนดที่ต้องตรวจสอบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ...item.mandatoryChecklistHighlights.map((h) => _buildChecklistHighlight(h, item.themeColor)),
                      const SizedBox(height: 16),

                      // Safety Checklist (expandable)
                      if (item.primaryRiskType != null) _buildChecklistExpansion(item),
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

  Widget _gazetteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildArticleCard(PtwStatutoryArticle article, Color themeColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: themeColor.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(article.articleNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(article.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(article.content, style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.play_arrow, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('การนำไปใช้: ${article.practicalApplication}',
                        style: const TextStyle(fontSize: 11, color: Colors.blue)),
                  ),
                ],
              ),
            ),
            if (article.penaltyNotice != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(article.penaltyNotice!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistHighlight(String highlight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(highlight, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildChecklistExpansion(PtwLegalGazetteItem item) {
    final checklists = PtwStatutoryMasterData.getStandardChecklistForRiskType(item.primaryRiskType!);
    return ExpansionTile(
      leading: Icon(Icons.checklist, color: item.themeColor),
      title: const Text('รายการตรวจสอบตามกฎหมาย', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${checklists.length} รายการ | ${checklists.where((c) => c.isMandatory).length} รายการบังคับ',
          style: const TextStyle(fontSize: 12)),
      children: checklists.map((c) {
        return ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: item.themeColor.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(c.itemId, style: TextStyle(fontSize: 10, color: item.themeColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(c.questionTh, style: const TextStyle(fontSize: 12)),
          subtitle: Text(c.questionEn, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          trailing: c.isMandatory
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                  child: const Text('บังคับ', style: TextStyle(fontSize: 10, color: Colors.red)),
                )
              : null,
        );
      }).toList(),
    );
  }

  Color _categoryBadgeColor(String category) {
    switch (category) {
      case 'ACT':
        return const Color(0xFF1E3A8A);
      case 'MINISTERIAL_REGULATION':
        return const Color(0xFF7C3AED);
      case 'DEPARTMENT_NOTIFICATION':
        return const Color(0xFF065F46);
      default:
        return Colors.grey;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'ACT':
        return 'พ.ร.บ.';
      case 'MINISTERIAL_REGULATION':
        return 'กฎกระทรวง';
      case 'DEPARTMENT_NOTIFICATION':
        return 'ประกาศกรมฯ';
      default:
        return category;
    }
  }
}
