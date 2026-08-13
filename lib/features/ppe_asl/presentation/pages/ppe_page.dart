import 'package:flutter/material.dart';

class PpePage extends StatelessWidget {
  const PpePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ทะเบียนอุปกรณ์ (PPE) และผู้รับเหมา (ASL)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Center(
        child: Text('ระบบจัดการสต๊อกอุปกรณ์ PPE และ Approved Supplier List', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
