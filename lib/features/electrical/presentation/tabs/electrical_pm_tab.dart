import 'package:flutter/material.dart';

class ElectricalPmTab extends StatelessWidget {
  const ElectricalPmTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.handyman_rounded, color: Color(0xFF2563EB), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'การบำรุงรักษาเชิงป้องกัน & ตรวจสภาพประจำเดือน (PM Checklist)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E40AF)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'การตรวจสอบสภาพสายไฟฟ้า สวิตช์ ป้ายเตือน และอุปกรณ์ดับเพลิงประจำห้องหม้อแปลง/ตู้ MDB ก่อนรอบตรวจสอบประจำปีของวิศวกร กว.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildChecklistCategory(
          title: '๑. ห้องควบคุมไฟฟ้าและตู้สวิตช์บอร์ด (MDB / DB)',
          items: [
            'ไม่มีสิ่งของกีดขวางหน้าตู้ MDB/DB อย่างน้อย ๑ เมตร เพื่อให้เปิดสับสวิตช์ได้สะดวก',
            'แผ่นยางฉนวนไฟฟ้า (Insulating Mat) ปูหน้าตู้มีสภาพสมบูรณ์ ไม่ฉีกขาด และแห้งสนิท',
            'ป้ายเตือน "อันตรายไฟฟ้าแรงสูง" และ Single Line Diagram ติดแสดงชัดเจนหน้าตู้',
            'ระบบระบายอากาศหรือเครื่องปรับอากาศในห้องควบคุมไฟฟ้าทำงานปกติ อุณหภูมิเหมาะสม',
            'มีถังดับเพลิงชนิดก๊าซ CO2 หรือ Clean Agent (Class C) ติดตั้งพร้อมใช้งาน',
          ],
        ),
        const SizedBox(height: 14),
        _buildChecklistCategory(
          title: '๒. หม้อแปลงไฟฟ้าและการต่อลงดิน (Transformer & Grounding)',
          items: [
            'ระดับน้ำมันหม้อแปลง (Oil Level) และสารดูดความชื้น (Silica Gel) อยู่ในเกณฑ์ปกติ',
            'ขั้วต่อสายไฟไม่มีคราบขี้เกลือ คราบไหม้ หรือรอยอาร์คความร้อนผิดปกติ',
            'สายต่อลงดิน (Grounding Conductor) ยึดแน่นกับหลักดิน ไม่มีรอยขาดหรือชำรุด',
            'รั้วกั้นรอบหม้อแปลงมีประตูล็อคกุญแจแน่นหนา ป้องกันผู้ไม่มีหน้าที่เกี่ยวข้องเข้าใกล้',
          ],
        ),
        const SizedBox(height: 14),
        _buildChecklistCategory(
          title: '๓. อุปกรณ์ไฟฟ้าและเต้ารับในพื้นที่ปฏิบัติงาน',
          items: [
            'สายไฟไม่มีรอยถลอก ฉีกขาด หรือเปลือกหุ้มแตกเปราะ',
            'เต้าเสียบและเต้ารับมีสายดินครบ 3 ขา ไม่หลวมคลอน',
            'เครื่องตัดไฟรั่ว (RCD / ELCB) สำหรับพื้นที่เปียกชื้นหรือทำงานภายนอก ทำงานตัดวงจรตามมาตรฐาน',
          ],
        ),
      ],
    );
  }

  Widget _buildChecklistCategory({
    required String title,
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
            const Divider(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
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
