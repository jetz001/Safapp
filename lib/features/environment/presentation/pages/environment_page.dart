import 'package:flutter/material.dart';

class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ตรวจวัดสภาพแวดล้อม (Environmental Monitoring)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Center(
        child: Text('แผนการตรวจวัด (แสง เสียง ความร้อน) และผลประเมินตามกฎหมาย', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
