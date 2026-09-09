import 'dart:io';
import 'package:flutter/material.dart';

class MachineryLegalTab extends StatelessWidget {
  const MachineryLegalTab({super.key});

  Future<void> _openFile(BuildContext context, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบไฟล์เอกสาร: $filePath'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } else {
        await Process.run('open', [filePath]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statutory Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คลังกฎหมาย & ประกาศมาตรฐาน: เครื่องจักร ปั้นจั่น และหม้อน้ำ',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'รวบรวมกฎกระทรวง พ.ศ. ๒๕๖๔, แบบฟอร์มราชการ แบบ ปจ.๑ / ปจ.๒, และประกาศกรมสวัสดิการฯ เรื่องการทดสอบพิกัดยก (Load Test)',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Statutory Summary Table: Inspection Cycle Matrix
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart_outlined, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('เกณฑ์กำหนดรอบเวลาการตรวจทดสอบตามกฎกระทรวง พ.ศ. ๒๕๖๔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                    columns: const [
                      DataColumn(label: Text('ประเภทอุปกรณ์', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('พิกัด / เงื่อนไข', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('รอบเวลาตรวจตามกฎหมาย', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('แบบรายงานราชการ', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('คุณสมบัติผู้ตรวจรับรอง', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: const [
                      DataRow(cells: [
                        DataCell(Text('ปั้นจั่นขนาดใหญ่ (> 50 ตัน)')),
                        DataCell(Text('ขนาดมากกว่า ๕๐ ตันขึ้นไป')),
                        DataCell(Text('อย่างน้อยทุก ๓ เดือน', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        DataCell(Text('แบบ ปจ.๑ / ปจ.๒')),
                        DataCell(Text('สามัญวิศวกรเครื่องกล กว.')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('ปั้นจั่นขนาดกลาง (3 - 50 ตัน)')),
                        DataCell(Text('ขนาดมากกว่า ๓ ตัน ถึง ๕๐ ตัน')),
                        DataCell(Text('อย่างน้อยทุก ๖ เดือน', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                        DataCell(Text('แบบ ปจ.๑ / ปจ.๒')),
                        DataCell(Text('สามัญวิศวกรเครื่องกล กว.')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('ปั้นจั่นขนาดเล็ก (1 - 3 ตัน)')),
                        DataCell(Text('ขนาดมากกว่า ๑ ตัน ถึง ๓ ตัน')),
                        DataCell(Text('อย่างน้อยทุก ๑ ปี', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                        DataCell(Text('แบบ ปจ.๑ / ปจ.๒')),
                        DataCell(Text('วิศวกรเครื่องกล (สามัญ/ภาคีพิเศษ)')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('หม้อน้ำ (Boiler)')),
                        DataCell(Text('หม้อน้ำไอน้ำ / หม้อต้มน้ำมันนำความร้อน')),
                        DataCell(Text('อย่างน้อยปีละ ๑ ครั้ง (Hydro 1.5x)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                        DataCell(Text('แบบรายงานตรวจหม้อน้ำ')),
                        DataCell(Text('สามัญวิศวกรเครื่องกล กว.')),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Official PDF Documents from bin/ปัั้นจั่น หม้อน้ำ
        const Text(
          'เอกสารราชการและแบบฟอร์มดาวน์โหลด (Official Gazettes & Forms):',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        _buildDocCard(
          context: context,
          title: 'กฎกระทรวงกำหนดมาตรฐานเกี่ยวกับเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔',
          subtitle: 'ราชกิจจานุเบกษา ฉบับหลักบังคับใช้ความปลอดภัยเครื่องจักร การ์ด ลิฟต์ ปั้นจั่น หม้อน้ำ',
          fileName: 'machine-2564.pdf',
          filePath: r'D:\DEV\Safapp\bin\ปัั้นจั่น หม้อน้ำ\machine-2564.pdf',
          tag: 'กฎกระทรวงหลัก ๒๕๖๔',
          tagColor: const Color(0xFF0284C7),
        ),
        _buildDocCard(
          context: context,
          title: 'แบบ ปจ.๑: แบบรายงานผลการตรวจและทดสอบปั้นจั่น (ชนิดอยู่กับที่)',
          subtitle: 'สำหรับปั้นจั่นเหนือศีรษะ (Overhead), ปั้นจั่นขาสูง (Gantry), ปั้นจั่นหมุน (Jib Crane)',
          fileName: '44481.pdf',
          filePath: r'D:\DEV\Safapp\bin\ปัั้นจั่น หม้อน้ำ\44481.pdf',
          tag: 'แบบฟอร์มราชการ แบบ ปจ.๑',
          tagColor: Colors.purple,
        ),
        _buildDocCard(
          context: context,
          title: 'แบบ ปจ.๒: แบบรายงานผลการตรวจและทดสอบปั้นจั่น (ชนิดเคลื่อนที่)',
          subtitle: 'สำหรับรถปั้นจั่น (Mobile Crane), ปั้นจั่นตีนตะขาบ (Crawler Crane), รถเฮี๊ยบ',
          fileName: '44490.pdf',
          filePath: r'D:\DEV\Safapp\bin\ปัั้นจั่น หม้อน้ำ\44490.pdf',
          tag: 'แบบฟอร์มราชการ แบบ ปจ.๒',
          tagColor: Colors.indigo,
        ),
        _buildDocCard(
          context: context,
          title: 'ประกาศกรมสวัสดิการฯ: การทดสอบส่วนประกอบและอุปกรณ์ปั้นจั่น (Load Test ๒๕๖๕)',
          subtitle: 'หลักเกณฑ์การทดสอบน้ำหนักพิกัดยก ๑.๒๕ เท่า (Dynamic / Static Load Test)',
          fileName: 'crane-test-65.pdf',
          filePath: r'D:\DEV\Safapp\bin\ปัั้นจั่น หม้อน้ำ\crane-test-65.pdf',
          tag: 'เกณฑ์ทดสอบ Load Test',
          tagColor: const Color(0xFFD97706),
        ),
        _buildDocCard(
          context: context,
          title: 'ประกาศกรมสวัสดิการฯ: การตรวจและทดสอบหม้อน้ำและภาชนะรับแรงดัน',
          subtitle: 'การทดสอบความดันไฮโดรสแตติก การตรวจลิ้นนิรภัย และความปลอดภัยหม้อต้ม',
          fileName: '56292.pdf',
          filePath: r'D:\DEV\Safapp\bin\ปัั้นจั่น หม้อน้ำ\56292.pdf',
          tag: 'มาตรฐานหม้อน้ำ & ไฮโดร',
          tagColor: const Color(0xFF16A34A),
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String fileName,
    required String filePath,
    required String tag,
    required Color tagColor,
  }) {
    final fileExists = File(filePath).existsSync();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26),
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
                        decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(tag, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: tagColor)),
                      ),
                      const SizedBox(width: 8),
                      Text(fileName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: fileExists ? () => _openFile(context, filePath) : null,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(fileExists ? 'เปิดไฟล์ PDF' : 'ไม่พบไฟล์'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
