import 'package:flutter/material.dart';

class ElectricalLegalTab extends StatelessWidget {
  const ElectricalLegalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Color(0xFF475569), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'คลังกฎหมาย & ประกาศมาตรฐานความปลอดภัยเกี่ยวกับไฟฟ้า',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'รวบรวมกฎกระทรวงและประกาศกรมสวัสดิการและคุ้มครองแรงงานสำหรับอ้างอิงและการตรวจรับรอง',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLawCard(
          title: '๑. กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัยฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘',
          number: 'ข้อ ๑๒',
          summary: 'นายจ้างต้องจัดให้มีการตรวจสอบและบำรุงรักษาระบบไฟฟ้าและบริภัณฑ์ไฟฟ้าเป็นประจำทุกปี อย่างน้อยปีละ ๑ ครั้ง และจัดทำบันทึกผลการตรวจสอบไว้เป็นหลักฐานพร้อมที่จะให้พนักงานตรวจความปลอดภัยตรวจสอบได้ (แบบ ๕๖๒๘๙)',
        ),
        const SizedBox(height: 12),
        _buildLawCard(
          title: '๒. กฎกระทรวงฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ (คุณสมบัติผู้ตรวจสอบ)',
          number: 'ข้อ ๑๓',
          summary: 'การตรวจสอบและบำรุงรักษาตามข้อ ๑๒ ต้องกระทำโดยผู้ซึ่งได้รับใบอนุญาตประกอบวิชาชีพวิศวกรรมควบคุม (กว.) หรือบุคคล/นิติบุคคลที่ขึ้นทะเบียนตามมาตรา ๙ หรือมาตรา ๑๑ แห่ง พ.ร.บ. ความปลอดภัยฯ พ.ศ. ๒๕๕๔',
        ),
        const SizedBox(height: 12),
        _buildLawCard(
          title: '๓. กฎกระทรวงฯ เกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ (ระบบสายดิน & มาตรฐาน วสท.)',
          number: 'ข้อ ๑๖',
          summary: 'ระบบสายดิน (Grounding System) ต้องมีค่าความต้านทานการต่อลงดินไม่เกิน ๕ โอห์ม (<= 5.0 Ohm) ตามมาตรฐานสมาคมวิศวกรรมสถานแห่งประเทศไทยในพระบรมราชูปถัมภ์ (วสท.)',
        ),
        const SizedBox(height: 12),
        _buildLawCard(
          title: '๔. ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการ และเงื่อนไขการฝึกอบรมฯ ไฟฟ้า',
          number: 'ข้อ ๒๔',
          summary: 'นายจ้างต้องจัดให้ลูกจ้างซึ่งปฏิบัติงานเกี่ยวกับไฟฟ้าได้รับการฝึกอบรมความปลอดภัยในการทำงานเกี่ยวกับไฟฟ้าตามหลักสูตรที่อธิบดีประกาศกำหนด',
        ),
      ],
    );
  }

  Widget _buildLawCard({
    required String title,
    required String number,
    required String summary,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
