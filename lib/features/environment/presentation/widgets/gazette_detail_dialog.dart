import 'package:flutter/material.dart';
import '../../data/environmental_gazette_data.dart';

/// Modal dialog displaying full statutory details of a Royal Gazette legislation item.
class GazetteDetailDialog extends StatelessWidget {
  final EnvironmentalGazetteItem item;

  const GazetteDetailDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.lawId,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.titleTh,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // English Title
                  Text(
                    item.titleEn,
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),

                  // Metadata Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaRow('หน่วยงานที่กำกับดูแล:', item.governingAuthority, Icons.corporate_fare_rounded),
                        const Divider(height: 16),
                        _buildMetaRow('การประกาศราชกิจจานุเบกษา:', '${item.gazetteVolume} ${item.gazettePart} ${item.gazettePage}', Icons.menu_book_rounded),
                        const Divider(height: 16),
                        _buildMetaRow('วันที่ประกาศ & มีผลบังคับใช้:', 'ประกาศ ${item.publishedDate} (มีผล: ${item.effectiveDate})', Icons.calendar_today_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Summary Section
                  const Text(
                    'สรุปสาระสำคัญตามกฎหมาย (Summary of Statutory Requirements):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      item.summaryTh,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Key Articles Section
                  const Text(
                    'ข้อกำหนดและมาตราสำคัญ (Key Statutory Articles):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 8),
                  ...item.keyArticles.map((article) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              article,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),

                  // Mandatory Forms & Penalty Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Forms
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 16, color: Color(0xFF166534)),
                                  SizedBox(width: 6),
                                  Text(
                                    'แบบฟอร์มที่ต้องใช้:',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...item.mandatoryForms.map((f) => Text('• $f', style: const TextStyle(fontSize: 12, color: Color(0xFF166534)))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Penalty
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.gavel_rounded, size: 16, color: Color(0xFF991B1B)),
                                  SizedBox(width: 6),
                                  Text(
                                    'บทกำหนดโทษ (Penalties):',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item.penaltySummary, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ปิดหน้าต่าง'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
