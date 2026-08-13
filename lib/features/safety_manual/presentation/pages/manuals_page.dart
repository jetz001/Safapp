import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ManualsPage extends StatefulWidget {
  const ManualsPage({Key? key}) : super(key: key);
  @override
  State<ManualsPage> createState() => _ManualsPageState();
}

class _ManualsPageState extends State<ManualsPage> {
  String? _pdfPath;

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('คู่มือและมาตรฐานความปลอดภัย (SOPs)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('เปิดไฟล์คู่มือ PDF', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, 
                foregroundColor: Colors.white, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
      body: _pdfPath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('ยังไม่ได้เลือกไฟล์คู่มือ', style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('กดปุ่ม "เปิดไฟล์คู่มือ PDF" ที่มุมขวาบนเพื่ออ่านเอกสารในแอป', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : SfPdfViewer.file(File(_pdfPath!)),
    );
  }
}
