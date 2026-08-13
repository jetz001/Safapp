import 'package:flutter/material.dart';

class PtwPage extends StatelessWidget {
  const PtwPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ระบบใบอนุญาตทำงาน (Permit to Work - PTW)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.description),
              label: const Text('ขอใบอนุญาต (Create PTW)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
      body: Center(
        child: Text('รายการใบอนุญาตทำงาน (Hot Work, Confined Space) LOTO', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
      ),
    );
  }
}
