import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Statutory Factory Chemical Inventory & Form สอ.๑ Seed Generator
/// Specifically tailored for carton manufacturing facilities (Boss Carton Co., Ltd.)
/// under the Ministry of Labour statutory regulations.
class ChemicalDefaultSeeds {
  static Future<void> seedIfEmpty(Database db) async {
    final invRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM chemical_inventory');
    final inventoryCount = invRes.isNotEmpty ? (invRes.first['cnt'] as int? ?? 0) : 0;

    if (inventoryCount == 0) {
      final chems = [
        {
          'seq_no': 639,
          'trade_name': 'ไอโซโพรพิล แอลกอฮอล์ (IPA 99.8%)',
          'chemical_name_th': 'ไอโซโพรพิล แอลกอฮอล์',
          'chemical_name_en': 'Isopropyl Alcohol',
          'cas_number': '67-63-0',
          'un_number': 'UN 1219',
          'storage_location': 'ไลน์ผลิต (สถานีเครื่องพิมพ์ 6 สี)',
          'physical_state': 'LIQUID',
          'quantity': 200.0,
          'unit': 'ลิตร (L)',
          'max_capacity': 400.0,
          'container_type': 'ถังเหล็ก 200 ลิตร (Steel Drum)',
          'manufacturer_supplier': 'บจก. บางกอก โซลเวนท์ เคมีคอล',
          'hazard_class': 'Flammable Liquid Cat. 2, Eye Irrit. Cat. 2',
          'ghs_pictograms': jsonEncode(['GHS02', 'GHS07']),
          'register_date': '2026-01-10',
          'sds_issue_date': '2025-06-15',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 1,
          'nfpa_flammability': 3,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'notes': 'น้ำยาเช็ดล้างทำความสะอาดลูกกลิ้งยางและเพลทพิมพ์กล่องลูกฟูก',
          'status': 'ACTIVE',
        },
        {
          'seq_no': null,
          'trade_name': 'หมึกพิมพ์กล่องลูกฟูกสูตรน้ำ (Water-based Flexo Ink)',
          'chemical_name_th': 'หมึกพิมพ์เฟล็กโซสูตรน้ำ',
          'chemical_name_en': 'Water-based Flexographic Printing Ink',
          'cas_number': '1333-86-4',
          'un_number': 'N/A',
          'storage_location': 'ไลน์ผลิต (ห้องเตรียมหมึกพิมพ์)',
          'physical_state': 'LIQUID',
          'quantity': 500.0,
          'unit': 'ลิตร (L)',
          'max_capacity': 1000.0,
          'container_type': 'ถังพลาสติก 25 ลิตร x 20 ถัง',
          'manufacturer_supplier': 'บจก. สยาม อิงค์ แอนด์ เคมิคอล',
          'hazard_class': 'Skin Sens. Cat. 1, Eye Irrit. Cat. 2B',
          'ghs_pictograms': jsonEncode(['GHS07']),
          'register_date': '2026-01-15',
          'sds_issue_date': '2025-08-20',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 1,
          'nfpa_flammability': 1,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'notes': 'หมึกพิมพ์กล่องลูกฟูกและกล่องประกบเครื่องพิมพ์ดิจิทัลและเฟล็กโซ 6 สี',
          'status': 'ACTIVE',
        },
        {
          'seq_no': null,
          'trade_name': 'กาวน้ำติดกล่องลูกฟูก (PVAc Carton Adhesive)',
          'chemical_name_th': 'กาวโพลีไวนิลอะซีเตต',
          'chemical_name_en': 'Polyvinyl Acetate Emulsion Glue',
          'cas_number': '9002-89-5',
          'un_number': 'N/A',
          'storage_location': 'ไลน์ผลิต (สถานีงานปะกาว / สถานี Packing)',
          'physical_state': 'LIQUID',
          'quantity': 1000.0,
          'unit': 'ลิตร (L)',
          'max_capacity': 2000.0,
          'container_type': 'ถัง IBC Tank 1,000 ลิตร',
          'manufacturer_supplier': 'บจก. นครหลวง แอดฮีซีฟ',
          'hazard_class': 'Mild Skin Irritation Cat. 3',
          'ghs_pictograms': jsonEncode(['GHS07']),
          'register_date': '2026-01-10',
          'sds_issue_date': '2025-10-05',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 1,
          'nfpa_flammability': 0,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'notes': 'กาวสูตรน้ำสำหรับขึ้นรูปและประกบกล่องกระดาษลูกฟูก เครื่องปะกาวอัตโนมัติ',
          'status': 'ACTIVE',
        },
        {
          'seq_no': null,
          'trade_name': 'น้ำมันไฮดรอลิกอุตสาหกรรม (Hydraulic Oil ISO VG 68)',
          'chemical_name_th': 'น้ำมันหล่อลื่นไฮดรอลิก',
          'chemical_name_en': 'Hydraulic Fluid ISO VG 68',
          'cas_number': '64742-54-7',
          'un_number': 'N/A',
          'storage_location': 'ห้องช่างซ่อมบำรุง / สถานีเครื่องผ่า',
          'physical_state': 'LIQUID',
          'quantity': 400.0,
          'unit': 'ลิตร (L)',
          'max_capacity': 800.0,
          'container_type': 'ถังเหล็ก 200 ลิตร (Steel Drum)',
          'manufacturer_supplier': 'บจก. ปตท. น้ำมันและการค้าปลีก (OR)',
          'hazard_class': 'Asp. Tox. Cat. 1, Aquatic Chronic Cat. 4',
          'ghs_pictograms': jsonEncode(['GHS08']),
          'register_date': '2026-01-12',
          'sds_issue_date': '2025-04-18',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 1,
          'nfpa_flammability': 1,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'notes': 'น้ำมันขับเคลื่อนระบบไฮดรอลิกแท่นปั๊มไดคัทและเครื่องผ่ากระดาษ',
          'status': 'ACTIVE',
        },
        {
          'seq_no': 1251,
          'trade_name': 'โซเดียมไฮดรอกไซด์ 50% (Caustic Soda 50%)',
          'chemical_name_th': 'โซเดียมไฮดรอกไซด์',
          'chemical_name_en': 'Sodium Hydroxide 50% Solution',
          'cas_number': '1310-73-2',
          'un_number': 'UN 1824',
          'storage_location': 'สาธารณูปโภค (ระบบบำบัดน้ำเสีย)',
          'physical_state': 'LIQUID',
          'quantity': 500.0,
          'unit': 'ลิตร (L)',
          'max_capacity': 1000.0,
          'container_type': 'ถัง IBC Tank ทนด่าง 1,000 ลิตร',
          'manufacturer_supplier': 'บมจ. อดิตยา บิอร์ล่า เคมีคัลส์',
          'hazard_class': 'Skin Corr. Cat. 1A, Eye Dam. Cat. 1, Met. Corr. Cat. 1',
          'ghs_pictograms': jsonEncode(['GHS05']),
          'register_date': '2026-01-20',
          'sds_issue_date': '2025-05-12',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 3,
          'nfpa_flammability': 0,
          'nfpa_instability': 1,
          'nfpa_special': 'COR',
          'notes': 'ใช้ปรับค่าความเป็นกรด-ด่าง (pH) ในระบบบำบัดน้ำเสียและล้างคราบกาว',
          'status': 'ACTIVE',
        },
        {
          'seq_no': 718,
          'trade_name': 'ก๊าซปิโตรเลียมเหลว (LPG Bulk)',
          'chemical_name_th': 'ก๊าซปิโตรเลียมเหลว',
          'chemical_name_en': 'Liquefied Petroleum Gas (LPG)',
          'cas_number': '68476-85-7',
          'un_number': 'UN 1075',
          'storage_location': 'สถานีหม้อไอน้ำ (Boiler House)',
          'physical_state': 'GAS',
          'quantity': 2000.0,
          'unit': 'กิโลกรัม (kg)',
          'max_capacity': 5000.0,
          'container_type': 'ถังก๊าซแรงดันสูงขนาดใหญ่ (Bulk Tank)',
          'manufacturer_supplier': 'บมจ. สยามแก๊ส แอนด์ ปิโตรเคมีคัลส์',
          'hazard_class': 'Flam. Gas Cat. 1, Press. Gas',
          'ghs_pictograms': jsonEncode(['GHS02', 'GHS04']),
          'register_date': '2026-01-05',
          'sds_issue_date': '2025-03-10',
          'sds_expiry_years': 3,
          'sds_file_path': '',
          'label_image_path': '',
          'nfpa_health': 1,
          'nfpa_flammability': 4,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'notes': 'เชื้อเพลิงผลิตไอน้ำสำหรับเครื่องทำลอนลูกฟูก (Corrugator) 2.5 ตัน/ชม.',
          'status': 'ACTIVE',
        },
      ];

      for (final chem in chems) {
        await db.insert('chemical_inventory', chem);
      }
    }

    final sorRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM chemical_sds_sor1');
    final sor1Count = sorRes.isNotEmpty ? (sorRes.first['cnt'] as int? ?? 0) : 0;

    if (sor1Count == 0) {
      final sor1Items = [
        {
          'inventory_id': 1,
          'trade_name': 'ไอโซโพรพิล แอลกอฮอล์ (IPA 99.8%)',
          'chemical_formula': 'C3H8O',
          'cas_number': '67-63-0',
          'un_number': 'UN 1219',
          'manufacturer_importer_info': 'บริษัท บางกอก โซลเวนท์ เคมีคอล จำกัด โทร. 02-123-4567',
          'ghs_classification': 'ของเหลวไวไฟ ประเภทย่อย 2, การระคายเคืองต่อดวงตา ประเภทย่อย 2',
          'ghs_pictograms': jsonEncode(['GHS02', 'GHS07']),
          'signal_word': 'อันตราย',
          'hazard_statements': jsonEncode([
            'H225 ของเหลวและไอระเหยไวไฟสูง',
            'H319 ระคายเคืองต่อดวงตาอย่างรุนแรง',
            'H336 อาจทำให้ง่วงซึมหรือมึนงง',
          ]),
          'precautionary_statements': jsonEncode([
            'P210 เก็บให้ห่างจากความร้อน/ประกายไฟ/เปลวไฟ',
            'P280 สวมถุงมือป้องกันและอุปกรณ์ปกป้องดวงตา',
            'P305+P351+P338 หากเข้าตาให้ล้างออกด้วยน้ำสะอาดปริมาณมากหลายๆ นาที',
          ]),
          'ingredients_json': jsonEncode([
            {'name': 'Isopropyl Alcohol', 'cas': '67-63-0', 'percentage': '99.8%'},
          ]),
          'first_aid_json': jsonEncode({
            'inhalation': 'ย้ายผู้ป่วยไปที่อากาศบริสุทธิ์',
            'skin': 'ล้างออกด้วยสบู่และน้ำ',
            'eye': 'ล้างด้วยน้ำสะอาดต่อเนื่องอย่างน้อย 15 นาที',
            'ingestion': 'ห้ามทำให้อาเจียน รีบนำส่งแพทย์',
          }),
          'fire_fighting_json': jsonEncode({
            'extinguishing_media': 'โฟมทนแอลกอฮอล์ ผงเคมีแห้ง คาร์บอนไดออกไซด์',
            'specific_hazards': 'ไอระเหยหนักกว่าอากาศอาจสะสมตามพื้น',
          }),
          'accidental_release_json': jsonEncode({
            'personal_precautions': 'สวมหน้ากากกรองไอระเหยสารอินทรีย์ ถุงมือไนไตรล์',
            'clean_up': 'ดูดซับด้วยทรายหรือวัสดุดูดซับที่ไม่ติดไฟ',
          }),
          'handling_storage_json': jsonEncode({
            'handling': 'ใช้ในที่ที่มีการระบายอากาศดี หลีกเลี่ยงไฟฟ้าสถิต',
            'storage': 'เก็บในคลังสารเคมีที่มีระบบต่อสายดิน อุณหภูมิต่ำกว่า 30 องศาเซลเซียส',
          }),
          'exposure_controls_json': jsonEncode({
            'tlv': 'TWA 200 ppm, STEL 400 ppm (กสร. ๒๕๖๐)',
            'ppe': 'แว่นตานิรภัยครอบตากันสารเคมี, ถุงมือยางไนไตรล์, หน้ากากกรองไอระเหยอินทรีย์ OV',
          }),
          'physical_chemical_json': jsonEncode({
            'appearance': 'ของเหลวใส ไม่มีสี กลิ่นแอลกอฮอล์',
            'boiling_point': '82.5 °C',
            'flash_point': '11.7 °C (Closed Cup)',
          }),
          'stability_reactivity_json': jsonEncode({
            'stability': 'เสถียรภายใต้สภาวะปกติ',
            'incompatible': 'สารออกซิไดซ์รุนแรง กรดแก่ โลหะอัลคาไล',
          }),
          'toxicological_json': jsonEncode({
            'oral_ld50': '5045 mg/kg (Rat)',
            'inhalation_lc50': '16000 ppm/8h (Rat)',
          }),
          'ecological_json': jsonEncode({
            'ecotoxicity': 'เป็นพิษต่ำต่อสิ่งมีชีวิตในน้ำ LC50 > 100 mg/L (96h Fathead minnow)',
          }),
          'disposal_json': jsonEncode({
            'disposal_method': 'ส่งเผาทำลายในเตาเผาอุณหภูมิสูงที่ได้รับอนุญาตจากกรมโรงงานอุตสาหกรรม',
          }),
          'transport_json': jsonEncode({
            'un_number': 'UN 1219',
            'proper_shipping_name': 'ISOPROPANOL (ISOPROPYL ALCOHOL)',
            'class': '3',
            'packing_group': 'II',
          }),
          'regulatory_json': jsonEncode({
            'regulations': 'พ.ร.บ.วัตถุอันตราย, ประกาศกระทรวงแรงงานเรื่องสารเคมีอันตราย พ.ศ. ๒๕๕๖ ลำดับที่ ๖๓๙',
          }),
          'other_info_json': jsonEncode({
            'revision_date': '2025-06-15',
            'prepared_by': 'ฝ่ายความปลอดภัยและอาชีวอนามัย บจก.บอส คาร์ตัน',
          }),
          'nfpa_health': 1,
          'nfpa_flammability': 3,
          'nfpa_instability': 0,
          'nfpa_special': '',
          'status': 'COMPLETED',
        },
        {
          'inventory_id': 5,
          'trade_name': 'โซเดียมไฮดรอกไซด์ 50% (Caustic Soda 50%)',
          'chemical_formula': 'NaOH',
          'cas_number': '1310-73-2',
          'un_number': 'UN 1824',
          'manufacturer_importer_info': 'บริษัท อดิตยา บิอร์ล่า เคมีคัลส์ (ประเทศไทย) จำกัด โทร. 038-123-456',
          'ghs_classification': 'การกัดกร่อนต่อผิวหนัง ประเภทย่อย 1A, การทำลายดวงตาอย่างรุนแรง ประเภทย่อย 1',
          'ghs_pictograms': jsonEncode(['GHS05']),
          'signal_word': 'อันตราย',
          'hazard_statements': jsonEncode([
            'H314 ทำให้ผิวหนังไหม้อย่างรุนแรงและทำลายดวงตา',
            'H290 อาจกัดกร่อนโลหะ',
          ]),
          'precautionary_statements': jsonEncode([
            'P260 ห้ามสูดดมไอระเหย/ละออง',
            'P280 สวมถุงมือป้องกัน/ชุดป้องกัน/อุปกรณ์ปกป้องดวงตา/อุปกรณ์ปกป้องใบหน้า',
            'P301+P330+P331 หากกลืนกิน: ล้างปาก อย่าทำให้อาเจียน',
          ]),
          'ingredients_json': jsonEncode([
            {'name': 'Sodium Hydroxide', 'cas': '1310-73-2', 'percentage': '50.0%'},
            {'name': 'Water', 'cas': '7732-18-5', 'percentage': '50.0%'},
          ]),
          'first_aid_json': jsonEncode({
            'inhalation': 'ย้ายสู่ที่อากาศบริสุทธิ์ นำส่งแพทย์ทันที',
            'skin': 'ถอดเสื้อผ้าที่เปื้อน ล้างผิวหนังด้วยน้ำสะอาดไหลผ่านอย่างน้อย 15 นาที',
            'eye': 'ล้างด้วยน้ำสะอาดต่อเนื่องอย่างน้อย 30 นาที รีบพบจักษุแพทย์',
            'ingestion': 'ห้ามทำให้อาเจียน ให้ดื่มน้ำหรือนม นำส่งโรงพยาบาลทันที',
          }),
          'fire_fighting_json': jsonEncode({
            'extinguishing_media': 'ใช้สารดับเพลิงที่เหมาะสมกับไฟโดยรอบ เช่น ละอองน้ำ ผงเคมี',
            'specific_hazards': 'เมื่อสัมผัสน้ำหรือความชื้นอาจเกิดความร้อนสูง สัมผัสโลหะอาจให้ก๊าซไฮโดรเจน',
          }),
          'accidental_release_json': jsonEncode({
            'personal_precautions': 'สวมแผ่นกระบังหน้า ชุดป้องกันสารเคมี ถุงมือยางนีโอพรีน รองเท้าบู๊ทยาง',
            'clean_up': 'กักเก็บของเหลว เจือจางและปรับสภาพด้วยกรดเจือจางอย่างระมัดระวัง',
          }),
          'handling_storage_json': jsonEncode({
            'handling': 'ป้องกันการสัมผัสกับผิวหนังและดวงตา มีอ่างล้างตาฉุกเฉินและฝักบัวฉุกเฉินใกล้จุดทำงาน',
            'storage': 'เก็บในภาชนะพลาสติกทนด่าง ห้ามเก็บในถังอลูมิเนียม สังกะสี หรือดีบุก',
          }),
          'exposure_controls_json': jsonEncode({
            'tlv': 'Ceiling 2 mg/m³ (กสร. ๒๕๖๐)',
            'ppe': 'กระบังหน้าป้องกันสารเคมี, เอี๊ยมกันสารเคมี PVC, ถุงมือยางนีโอพรีน, รองเท้านิรภัยบู๊ทยาง',
          }),
          'physical_chemical_json': jsonEncode({
            'appearance': 'ของเหลวใส มีความหนืด ไม่มีกลิ่น',
            'boiling_point': '140 °C',
            'flash_point': 'ไม่ติดไฟ',
          }),
          'stability_reactivity_json': jsonEncode({
            'stability': 'เสถียรภายใต้สภาวะปกติ คายความร้อนสูงเมื่อเจือจางน้ำ',
            'incompatible': 'กรดแก่, อลูมิเนียม, สังกะสี, โลหะเบา',
          }),
          'toxicological_json': jsonEncode({
            'skin_corrosion': 'กัดกร่อนรุนแรงระดับเนื้อตาย (Necrosis)',
            'eye_damage': 'ทำให้ตาบอดถาวรได้',
          }),
          'ecological_json': jsonEncode({
            'ecotoxicity': 'ทำให้ค่า pH ของแหล่งน้ำสูง เป็นอันตรายต่อสัตว์น้ำ',
          }),
          'disposal_json': jsonEncode({
            'disposal_method': 'ปรับสภาพค่า pH ให้เป็นกลาง (pH 6-9) ก่อนส่งระบบบำบัดน้ำเสีย',
          }),
          'transport_json': jsonEncode({
            'un_number': 'UN 1824',
            'proper_shipping_name': 'SODIUM HYDROXIDE SOLUTION',
            'class': '8',
            'packing_group': 'II',
          }),
          'regulatory_json': jsonEncode({
            'regulations': 'วัตถุอันตรายชนิดที่ ๑ (กรมโรงงานอุตสาหกรรม), สารเคมีอันตราย กสร. ลำดับที่ ๑๒๕๑',
          }),
          'other_info_json': jsonEncode({
            'revision_date': '2025-05-12',
            'prepared_by': 'ฝ่ายความปลอดภัยและอาชีวอนามัย บจก.บอส คาร์ตัน',
          }),
          'nfpa_health': 3,
          'nfpa_flammability': 0,
          'nfpa_instability': 1,
          'nfpa_special': 'COR',
          'status': 'COMPLETED',
        },
      ];

      for (final item in sor1Items) {
        await db.insert('chemical_sds_sor1', item);
      }
    }
  }
}
