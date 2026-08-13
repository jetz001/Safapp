import 'package:flutter/material.dart';

class ChemicalsPage extends StatelessWidget {
  const ChemicalsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('การจัดการสารเคมีอันตราย (Chemical & SDS)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('ขึ้นทะเบียนสารเคมีใหม่'),
            ),
          )
        ],
      ),
      body: Center(
        child: Text('รายการสารเคมี และสถานะการหมดอายุของ SDS จะแสดงที่นี่', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
