import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ทะเบียนกฎหมายความปลอดภัย (Legal Register)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Center(
        child: Text('รายการประเมินความสอดคล้องตามกฎหมายราชกิจจานุเบกษา', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
