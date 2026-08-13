import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _backupPath;

  Future<void> _selectBackupFolder() async {
    String? result = await FilePicker.getDirectoryPath(
      dialogTitle: 'เลือกโฟลเดอร์สำหรับสำรองข้อมูล',
    );
    if (result != null) {
      setState(() {
        _backupPath = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ตั้งค่าที่เก็บข้อมูลสำรองเรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบและการสำรองข้อมูล', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backup & Restore (สำรองข้อมูลฐานข้อมูล)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectBackupFolder,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('เลือกโฟลเดอร์ Backup'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(_backupPath ?? 'ยังไม่ได้เลือกโฟลเดอร์สำรองข้อมูล', style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _backupPath == null ? null : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('จำลองการคัดลอกไฟล์ .db ไปยังโฟลเดอร์ Backup สำเร็จ!')),
                        );
                      },
                      icon: const Icon(Icons.backup),
                      label: const Text('เริ่มสำรองข้อมูลเดี๋ยวนี้ (Backup Now)'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    )
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
