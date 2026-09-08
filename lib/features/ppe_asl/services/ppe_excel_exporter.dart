import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/ppe_item_model.dart';
import '../domain/models/ppe_transaction_model.dart';
import '../domain/models/asl_supplier_model.dart';

class PpeExcelExporter {
  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// 1. ส่งออกทะเบียนอุปกรณ์ PPE (Master Catalog)
  static Future<void> exportPpeCatalog(List<PpeItem> items, BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'ทะเบียนอุปกรณ์ PPE';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      // Header Row
      sheet.appendRow([
        TextCellValue('รหัสอุปกรณ์'),
        TextCellValue('ชื่ออุปกรณ์ PPE'),
        TextCellValue('หมวดหมู่อุปกรณ์'),
        TextCellValue('มาตรฐานรับรอง (มอก./EN/ANSI)'),
        TextCellValue('ยอดคงเหลือ'),
        TextCellValue('จุดเตือนสั่งซื้อ (Min)'),
        TextCellValue('หน่วยนับ'),
        TextCellValue('ราคาต่อหน่วย (บาท)'),
        TextCellValue('มูลค่ารวม (บาท)'),
        TextCellValue('สถานที่จัดเก็บ'),
        TextCellValue('รอบการเปลี่ยน (วัน)'),
        TextCellValue('ผู้จัดจำหน่ายหลัก'),
        TextCellValue('สถานะสต็อก'),
      ]);

      for (final it in items) {
        final totalVal = it.currentStock * it.unitCost;
        final stockStatus = it.isOutOfStock ? 'สินค้าหมด' : it.isLowStock ? 'สต็อกต่ำกว่าเกณฑ์' : 'ปกติ';

        sheet.appendRow([
          TextCellValue(it.code),
          TextCellValue(it.name),
          TextCellValue(it.category.labelTh),
          TextCellValue(it.standardCert),
          IntCellValue(it.currentStock),
          IntCellValue(it.minStock),
          TextCellValue(it.unit),
          DoubleCellValue(it.unitCost),
          DoubleCellValue(totalVal),
          TextCellValue(it.storageLocation ?? '-'),
          it.replacementCycleDays != null ? IntCellValue(it.replacementCycleDays!) : TextCellValue('-'),
          TextCellValue(it.preferredSupplierName ?? '-'),
          TextCellValue(stockStatus),
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        final dirPath = await _getExportDirectory();
        final fileName = 'PPE_Catalog_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File(p.join(dirPath, fileName));
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ส่งออกไฟล์ Excel สำเร็จ: ${file.path}'),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 2. ส่งออก Stock Card รายการเคลื่อนไหวรับเข้า-เบิกจ่าย
  static Future<void> exportStockCard(List<PpeTransaction> txs, BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'ประวัติ Stock Card';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('เลขที่รายการ'),
        TextCellValue('วันที่ทำรายการ'),
        TextCellValue('ประเภทรายการ'),
        TextCellValue('รหัสอุปกรณ์'),
        TextCellValue('ชื่ออุปกรณ์ PPE'),
        TextCellValue('จำนวน'),
        TextCellValue('ยอดคงเหลือหลังทำรายการ'),
        TextCellValue('ประเภทผู้รับ'),
        TextCellValue('ชื่อผู้รับมอบ / ผู้จำหน่าย'),
        TextCellValue('รหัสพนักงาน'),
        TextCellValue('แผนก / ฝ่าย'),
        TextCellValue('อ้างอิงมติ คปอ.'),
        TextCellValue('อ้างอิงใบ PTW'),
        TextCellValue('หมายเหตุ'),
        TextCellValue('ผู้บันทึก'),
      ]);

      for (final tx in txs) {
        sheet.appendRow([
          TextCellValue(tx.transactionNo),
          TextCellValue(tx.transactionDate),
          TextCellValue(tx.transactionType.labelTh),
          TextCellValue(tx.ppeCode),
          TextCellValue(tx.ppeName),
          IntCellValue(tx.quantity),
          IntCellValue(tx.balanceAfter),
          TextCellValue(tx.recipientType ?? '-'),
          TextCellValue(tx.recipientName ?? tx.supplierName ?? '-'),
          TextCellValue(tx.recipientId ?? '-'),
          TextCellValue(tx.department ?? '-'),
          TextCellValue(tx.cpoMeetingRef ?? '-'),
          TextCellValue(tx.ptwRef ?? '-'),
          TextCellValue(tx.notes ?? '-'),
          TextCellValue(tx.recordedBy ?? '-'),
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        final dirPath = await _getExportDirectory();
        final fileName = 'PPE_StockCard_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File(p.join(dirPath, fileName));
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ส่งออก Stock Card สำเร็จ: ${file.path}'),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 3. ส่งออกทำเนียบคู่ค้า ASL (Approved Supplier List)
  static Future<void> exportAslDirectory(List<AslSupplier> suppliers, BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'ทำเนียบคู่ค้า ASL';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('รหัสคู่ค้า'),
        TextCellValue('ชื่อบริษัท / ผู้จัดจำหน่าย'),
        TextCellValue('เลขประจำตัวผู้เสียภาษี'),
        TextCellValue('ผู้ติดต่อหลัก'),
        TextCellValue('เบอร์โทรศัพท์'),
        TextCellValue('อีเมล'),
        TextCellValue('ที่อยู่'),
        TextCellValue('หมวดหมู่อุปกรณ์ที่ส่งมอบ'),
        TextCellValue('มาตรฐานรับรอง (Certificates)'),
        TextCellValue('คะแนนประเมิน (Rating)'),
        TextCellValue('สถานะการรับรอง'),
        TextCellValue('วันที่รับรอง'),
        TextCellValue('รับรองถึงวันที่'),
        TextCellValue('หมายเหตุ'),
      ]);

      for (final sup in suppliers) {
        sheet.appendRow([
          TextCellValue(sup.code),
          TextCellValue(sup.companyName),
          TextCellValue(sup.taxId ?? '-'),
          TextCellValue(sup.contactPerson ?? '-'),
          TextCellValue(sup.phone ?? '-'),
          TextCellValue(sup.email ?? '-'),
          TextCellValue(sup.address ?? '-'),
          TextCellValue(sup.suppliedCategories),
          TextCellValue(sup.standardCertificates ?? '-'),
          DoubleCellValue(sup.rating),
          TextCellValue(sup.evaluationStatus.labelTh),
          TextCellValue(sup.approvedDate ?? '-'),
          TextCellValue(sup.validUntil ?? '-'),
          TextCellValue(sup.notes ?? '-'),
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        final dirPath = await _getExportDirectory();
        final fileName = 'ASL_Suppliers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File(p.join(dirPath, fileName));
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ส่งออกทำเนียบคู่ค้า ASL สำเร็จ: ${file.path}'),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
