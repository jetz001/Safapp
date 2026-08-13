import 'package:flutter/material.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ตรวจสอบและประเมิน (Audit & Inspection)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Center(
        child: Text('แบบฟอร์มการตรวจประเมินความปลอดภัย (Checklist)', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
