import 'package:flutter/material.dart';

class ElectricalIsolationTab extends StatelessWidget {
  const ElectricalIsolationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'การตัดแยกพลังงานไฟฟ้า & แผนผังวงจร (LOTO & Isolation Map)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'จัดทำแผนผังจุดตัดไฟหลัก (Main Circuit Breaker), หม้อแปลง และขั้นตอน Lockout/Tagout ตามกฎกระทรวงความปลอดภัยเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๒๐',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'จุดตัดแยกกระแสไฟฟ้าหลัก (Main Circuit Breakers)',
          subtitle: 'ระบุตำแหน่งตู้ควบคุมและผู้มีอำนาจสับปลดวงจร',
          icon: Icons.power_settings_new_rounded,
          items: [
            'ตู้ MDB อาคารผลิต 1: หม้อแปลง 1,000 kVA (เบรกเกอร์ ACB 1600A) - วิศวกรไฟฟ้า/ช่างเทคนิคอาวุโส',
            'ตู้ MDB อาคารสำนักงาน: เบรกเกอร์ MCCB 400A - หัวหน้าช่างอาคาร',
            'ตู้ Sub-DB ห้อง Server: เบรกเกอร์ MCCB 100A พร้อมระบบ UPS Cut-in อัตโนมัติ',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'ขั้นตอนความปลอดภัย Lockout / Tagout (LOTO)',
          subtitle: 'กฎเหล็ก 6 ขั้นตอนก่อนปฏิบัติงานใกล้ชิดหรือซ่อมบำรุงระบบไฟฟ้า',
          icon: Icons.shield_rounded,
          items: [
            '1. แจ้งเตือนผู้เกี่ยวข้องและขอนุญาตเปิดใบงานไฟฟ้า (Hot Work / Electrical PTW)',
            '2. ปิดสวิตช์และสับปลดวงจร (De-energize)',
            '3. คล้องกุญแจล็อค (Lockout) และแขวนป้ายเตือนอันตราย (Tagout)',
            '4. ตรวจวัดและคายประจุตกค้าง (Verify Zero Energy ด้วยโวลต์มิเตอร์/อุปกรณ์วัดแรงดัน)',
            '5. ปฏิบัติงานด้วยอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE กันไฟฟ้าแรงสูง)',
            '6. ตรวจสอบความพร้อม ปลดกุญแจ และจ่ายกระแสไฟคืนสู่ระบบอย่างปลอดภัย',
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
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
                CircleAvatar(
                  backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFFD97706),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
