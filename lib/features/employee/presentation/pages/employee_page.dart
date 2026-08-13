import 'package:flutter/material.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ทะเบียนพนักงานและการฝึกอบรม', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Excel Import
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังเปิด File Picker เพื่อนำเข้า Excel...')),
                );
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import Excel', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // สีเขียวสไตล์ Excel
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีข้อมูลพนักงาน',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'กรุณากดปุ่ม Import Excel ที่มุมขวาบนเพื่อนำเข้าข้อมูล',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
