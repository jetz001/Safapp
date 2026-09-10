/// ฐานข้อมูลที่อยู่ประเทศไทย (จังหวัด -> อำเภอ/เขต -> ตำบล/แขวง -> รหัสไปรษณีย์)
/// รองรับการกรองแบบ Cascading Dropdown / Autocomplete
class ThaiAddressModel {
  final String province;
  final String district; // อำเภอ / เขต
  final String subdistrict; // ตำบล / แขวง
  final String zipCode; // รหัสไปรษณีย์

  const ThaiAddressModel({
    required this.province,
    required this.district,
    required this.subdistrict,
    required this.zipCode,
  });
}

class ThaiAddressRepository {
  static const List<String> provinces = [
    'กรุงเทพมหานคร',
    'กระบี่',
    'กาญจนบุรี',
    'กาฬสินธุ์',
    'กำแพงเพชร',
    'ขอนแก่น',
    'จันทบุรี',
    'ฉะเชิงเทรา',
    'ชลบุรี',
    'ชัยนาท',
    'ชัยภูมิ',
    'ชุมพร',
    'เชียงราย',
    'เชียงใหม่',
    'ตรัง',
    'ตราด',
    'ตาก',
    'นครนายก',
    'นครปฐม',
    'นครพนม',
    'นครราชสีมา',
    'นครศรีธรรมราช',
    'นครสวรรค์',
    'นนทบุรี',
    'นราธิวาส',
    'น่าน',
    'บึงกาฬ',
    'บุรีรัมย์',
    'ปทุมธานี',
    'ประจวบคีรีขันธ์',
    'ปราจีนบุรี',
    'ปัตตานี',
    'พระนครศรีอยุธยา',
    'พะเยา',
    'พังงา',
    'พัทลุง',
    'พิจิตร',
    'พิษณุโลก',
    'เพชรบุรี',
    'เพชรบูรณ์',
    'แพร่',
    'ภูเก็ต',
    'มหาสารคาม',
    'มุกดาหาร',
    'แม่ฮ่องสอน',
    'ยโสธร',
    'ยะลา',
    'ร้อยเอ็ด',
    'ระนอง',
    'ระยอง',
    'ราชบุรี',
    'ลพบุรี',
    'ลำปาง',
    'ลำพูน',
    'เลย',
    'ศรีสะเกษ',
    'สกลนคร',
    'สงขลา',
    'สตูล',
    'สมุทรปราการ',
    'สมุทรสงคราม',
    'สมุทรสาคร',
    'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อำนาจเจริญ',
    'อุดรธานี',
    'อุตรดิตถ์',
    'อุทัยธานี',
    'อุบลราชธานี',
  ];

  // ข้อมูลอำเภอ ตำบล และรหัสไปรษณีย์ทั่วประเทศ
  static final List<ThaiAddressModel> _addressData = [
    // กรุงเทพมหานคร
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'พระนคร', subdistrict: 'พระบรมมหาราชวัง', zipCode: '10200'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'พระนคร', subdistrict: 'วังบูรพาภิรมย์', zipCode: '10200'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'พระนคร', subdistrict: 'วัดราชบพิธ', zipCode: '10200'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ดุสิต', subdistrict: 'ดุสิต', zipCode: '10300'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ดุสิต', subdistrict: 'วชิรพยาบาล', zipCode: '10300'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ปทุมวัน', subdistrict: 'รองเมือง', zipCode: '10330'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ปทุมวัน', subdistrict: 'ลุมพินี', zipCode: '10330'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางรัก', subdistrict: 'มหาพฤฒาราม', zipCode: '10500'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางรัก', subdistrict: 'สีลม', zipCode: '10500'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางเขน', subdistrict: 'อนุสาวรีย์', zipCode: '10220'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางเขน', subdistrict: 'ท่าแร้ง', zipCode: '10220'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางกะปิ', subdistrict: 'คลองจั่น', zipCode: '10240'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางกะปิ', subdistrict: 'หัวหมาก', zipCode: '10240'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'จตุจักร', subdistrict: 'ลาดยาว', zipCode: '10900'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'จตุจักร', subdistrict: 'เสนานิคม', zipCode: '10900'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'จตุจักร', subdistrict: 'จันทรเกษม', zipCode: '10900'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'คลองเตย', subdistrict: 'คลองเตย', zipCode: '10110'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'คลองเตย', subdistrict: 'คลองตัน', zipCode: '10110'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'วัฒนา', subdistrict: 'คลองเตยเหนือ', zipCode: '10110'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'วัฒนา', subdistrict: 'คลองตันเหนือ', zipCode: '10110'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ห้วยขวาง', subdistrict: 'ห้วยขวาง', zipCode: '10310'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ดินแดง', subdistrict: 'ดินแดง', zipCode: '10400'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ลาดกระบัง', subdistrict: 'ลาดกระบัง', zipCode: '10520'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'มีนบุรี', subdistrict: 'มีนบุรี', zipCode: '10510'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางขุนเทียน', subdistrict: 'ท่าข้าม', zipCode: '10150'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางขุนเทียน', subdistrict: 'แสมดำ', zipCode: '10150'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ภาษีเจริญ', subdistrict: 'บางหว้า', zipCode: '10160'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางแค', subdistrict: 'บางแค', zipCode: '10160'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'ตลิ่งชัน', subdistrict: 'คลองชักพระ', zipCode: '10170'),
    const ThaiAddressModel(province: 'กรุงเทพมหานคร', district: 'บางพลัด', subdistrict: 'บางพลัด', zipCode: '10700'),

    // สมุทรปราการ
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'เมืองสมุทรปราการ', subdistrict: 'ปากน้ำ', zipCode: '10270'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'เมืองสมุทรปราการ', subdistrict: 'สำโรงเหนือ', zipCode: '10270'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'เมืองสมุทรปราการ', subdistrict: 'บางเมือง', zipCode: '10270'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'เมืองสมุทรปราการ', subdistrict: 'แพรกษา', zipCode: '10280'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'บางพลี', subdistrict: 'บางพลีใหญ่', zipCode: '10540'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'บางพลี', subdistrict: 'ราชาเทวะ', zipCode: '10540'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'บางพลี', subdistrict: 'บางแก้ว', zipCode: '10540'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'บางเสาธง', subdistrict: 'บางเสาธง', zipCode: '10570'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'พระประแดง', subdistrict: 'ตลาด', zipCode: '10130'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'พระประแดง', subdistrict: 'บางพึ่ง', zipCode: '10130'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'พระสมุทรเจดีย์', subdistrict: 'แหลมฟ้าผ่า', zipCode: '10290'),
    const ThaiAddressModel(province: 'สมุทรปราการ', district: 'บางบ่อ', subdistrict: 'บางบ่อ', zipCode: '10560'),

    // นนทบุรี
    const ThaiAddressModel(province: 'นนทบุรี', district: 'เมืองนนทบุรี', subdistrict: 'สวนใหญ่', zipCode: '11000'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'เมืองนนทบุรี', subdistrict: 'บางเขน', zipCode: '11000'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'เมืองนนทบุรี', subdistrict: 'ท่าทราย', zipCode: '11000'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'ปากเกร็ด', subdistrict: 'ปากเกร็ด', zipCode: '11120'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'ปากเกร็ด', subdistrict: 'บางพูด', zipCode: '11120'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'ปากเกร็ด', subdistrict: 'คลองเกลือ', zipCode: '11120'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'บางกรวย', subdistrict: 'บางกรวย', zipCode: '11130'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'บางใหญ่', subdistrict: 'บางใหญ่', zipCode: '11140'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'บางบัวทอง', subdistrict: 'บางบัวทอง', zipCode: '11110'),
    const ThaiAddressModel(province: 'นนทบุรี', district: 'ไทรน้อย', subdistrict: 'ไทรน้อย', zipCode: '11150'),

    // ปทุมธานี
    // อำเภอลาดหลุมแก้ว (ครบทั้ง ๗ ตำบล รหัสไปรษณีย์ 12140)
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'ระแหง', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'ลาดหลุมแก้ว', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'คูบางหลวง', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'คูขวาง', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'คลองพระอุดม', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'บ่อเงิน', zipCode: '12140'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลาดหลุมแก้ว', subdistrict: 'หน้าไม้', zipCode: '12140'),

    // อำเภอเมืองปทุมธานี
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางปรอก', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บ้านใหม่', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บ้านกลาง', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บ้านฉาง', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บ้านกระแชง', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางขะแยง', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางคูวัด', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางหลวง', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางเดื่อ', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางพูด', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางพูน', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'บางกะดี', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'สวนพริกไทย', zipCode: '12000'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'เมืองปทุมธานี', subdistrict: 'หลักหก', zipCode: '12000'),

    // อำเภอคลองหลวง
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองหนึ่ง', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองสอง', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองสาม', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองสี่', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองห้า', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองหก', zipCode: '12120'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'คลองหลวง', subdistrict: 'คลองเจ็ด', zipCode: '12120'),

    // อำเภอธัญบุรี
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'ประชาธิปัตย์', zipCode: '12130'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'บึงยี่โถ', zipCode: '12130'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'รังสิต', zipCode: '12110'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'ลำผักกูด', zipCode: '12110'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'บึงสนั่น', zipCode: '12110'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ธัญบุรี', subdistrict: 'บึงน้ำรักษ์', zipCode: '12110'),

    // อำเภอลำลูกกา
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'คูคต', zipCode: '12130'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'ลาดสวาย', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'บึงคำพร้อย', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'ลำลูกกา', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'บึงทองหลาง', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'ลำไทร', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'บึงคอไห', zipCode: '12150'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'ลำลูกกา', subdistrict: 'พืชอุดม', zipCode: '12150'),

    // อำเภอสามโคก
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'บางเตย', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'คลองควาย', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'สามโคก', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'กระแชง', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'บางโพธิ์เหนือ', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'เชียงรากใหญ่', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'เชียงรากน้อย', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'บ้านปทุม', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'บ้านงิ้ว', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'บางกระบือ', zipCode: '12160'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'สามโคก', subdistrict: 'ท้ายเกาะ', zipCode: '12160'),

    // อำเภอหนองเสือ
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'บึงบา', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'บึงบอน', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'บึงชำอ้อ', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'บึงกาสาม', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'ศาลาครุ', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'หนองเสือ', zipCode: '12170'),
    const ThaiAddressModel(province: 'ปทุมธานี', district: 'หนองเสือ', subdistrict: 'นพรัตน์', zipCode: '12170'),

    // ชลบุรี
    const ThaiAddressModel(province: 'ชลบุรี', district: 'เมืองชลบุรี', subdistrict: 'บางปลาสร้อย', zipCode: '20000'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'เมืองชลบุรี', subdistrict: 'แสนสุข', zipCode: '20130'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'เมืองชลบุรี', subdistrict: 'ดอนหัวฬ่อ', zipCode: '20000'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'ศรีราชา', subdistrict: 'ศรีราชา', zipCode: '20110'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'ศรีราชา', subdistrict: 'แหลมฉบัง', zipCode: '20230'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'ศรีราชา', subdistrict: 'บ่อวิน', zipCode: '20230'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'บางละมุง', subdistrict: 'หนองปรือ', zipCode: '20150'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'บางละมุง', subdistrict: 'พัทยา', zipCode: '20150'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'พานทอง', subdistrict: 'พานทอง', zipCode: '20160'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'บ้านบึง', subdistrict: 'บ้านบึง', zipCode: '20170'),
    const ThaiAddressModel(province: 'ชลบุรี', district: 'สัตหีบ', subdistrict: 'สัตหีบ', zipCode: '20180'),

    // ระยอง
    const ThaiAddressModel(province: 'ระยอง', district: 'เมืองระยอง', subdistrict: 'ท่าประดู่', zipCode: '21000'),
    const ThaiAddressModel(province: 'ระยอง', district: 'เมืองระยอง', subdistrict: 'มาบตาพุด', zipCode: '21150'),
    const ThaiAddressModel(province: 'ระยอง', district: 'เมืองระยอง', subdistrict: 'เนินพระ', zipCode: '21150'),
    const ThaiAddressModel(province: 'ระยอง', district: 'ปลวกแดง', subdistrict: 'ปลวกแดง', zipCode: '21140'),
    const ThaiAddressModel(province: 'ระยอง', district: 'ปลวกแดง', subdistrict: 'มาบยางพร', zipCode: '21140'),
    const ThaiAddressModel(province: 'ระยอง', district: 'บ้านฉาง', subdistrict: 'บ้านฉาง', zipCode: '21130'),
    const ThaiAddressModel(province: 'ระยอง', district: 'นิคมพัฒนา', subdistrict: 'นิคมพัฒนา', zipCode: '21180'),

    // สมุทรสาคร
    const ThaiAddressModel(province: 'สมุทรสาคร', district: 'เมืองสมุทรสาคร', subdistrict: 'มหาชัย', zipCode: '74000'),
    const ThaiAddressModel(province: 'สมุทรสาคร', district: 'เมืองสมุทรสาคร', subdistrict: 'ท่าทราย', zipCode: '74000'),
    const ThaiAddressModel(province: 'สมุทรสาคร', district: 'กระทุ่มแบน', subdistrict: 'ตลาดกระทุ่มแบน', zipCode: '74110'),
    const ThaiAddressModel(province: 'สมุทรสาคร', district: 'กระทุ่มแบน', subdistrict: 'อ้อมน้อย', zipCode: '74130'),
    const ThaiAddressModel(province: 'สมุทรสาคร', district: 'บ้านแพ้ว', subdistrict: 'บ้านแพ้ว', zipCode: '74120'),

    // พระนครศรีอยุธยา
    const ThaiAddressModel(province: 'พระนครศรีอยุธยา', district: 'พระนครศรีอยุธยา', subdistrict: 'ประตูชัย', zipCode: '13000'),
    const ThaiAddressModel(province: 'พระนครศรีอยุธยา', district: 'บางปะอิน', subdistrict: 'บ้านเลน', zipCode: '13160'),
    const ThaiAddressModel(province: 'พระนครศรีอยุธยา', district: 'บางปะอิน', subdistrict: 'คลองจิก', zipCode: '13160'),
    const ThaiAddressModel(province: 'พระนครศรีอยุธยา', district: 'อุทัย', subdistrict: 'อุทัย', zipCode: '13210'),
    const ThaiAddressModel(province: 'พระนครศรีอยุธยา', district: 'วังน้อย', subdistrict: 'วังน้อย', zipCode: '13170'),

    // ฉะเชิงเทรา
    const ThaiAddressModel(province: 'ฉะเชิงเทรา', district: 'เมืองฉะเชิงเทรา', subdistrict: 'หน้าเมือง', zipCode: '24000'),
    const ThaiAddressModel(province: 'ฉะเชิงเทรา', district: 'บางปะกง', subdistrict: 'บางปะกง', zipCode: '24130'),
    const ThaiAddressModel(province: 'ฉะเชิงเทรา', district: 'บางปะกง', subdistrict: 'ท่าสะอ้าน', zipCode: '24130'),
    const ThaiAddressModel(province: 'ฉะเชิงเทรา', district: 'บ้านโพธิ์', subdistrict: 'บ้านโพธิ์', zipCode: '24140'),
    const ThaiAddressModel(province: 'ฉะเชิงเทรา', district: 'แปลงยาว', subdistrict: 'แปลงยาว', zipCode: '24190'),

    // สระบุรี
    const ThaiAddressModel(province: 'สระบุรี', district: 'เมืองสระบุรี', subdistrict: 'ปากเพรียว', zipCode: '18000'),
    const ThaiAddressModel(province: 'สระบุรี', district: 'แก่งคอย', subdistrict: 'แก่งคอย', zipCode: '18110'),
    const ThaiAddressModel(province: 'สระบุรี', district: 'หนองแค', subdistrict: 'หนองแค', zipCode: '18140'),

    // นครราชสีมา
    const ThaiAddressModel(province: 'นครราชสีมา', district: 'เมืองนครราชสีมา', subdistrict: 'ในเมือง', zipCode: '30000'),
    const ThaiAddressModel(province: 'นครราชสีมา', district: 'ปากช่อง', subdistrict: 'ปากช่อง', zipCode: '30130'),
    const ThaiAddressModel(province: 'นครราชสีมา', district: 'สีคิ้ว', subdistrict: 'สีคิ้ว', zipCode: '30140'),

    // ขอนแก่น
    const ThaiAddressModel(province: 'ขอนแก่น', district: 'เมืองขอนแก่น', subdistrict: 'ในเมือง', zipCode: '40000'),
    const ThaiAddressModel(province: 'ขอนแก่น', district: 'น้ำพอง', subdistrict: 'น้ำพอง', zipCode: '40140'),

    // เชียงใหม่
    const ThaiAddressModel(province: 'เชียงใหม่', district: 'เมืองเชียงใหม่', subdistrict: 'ศรีภูมิ', zipCode: '50200'),
    const ThaiAddressModel(province: 'เชียงใหม่', district: 'เมืองเชียงใหม่', subdistrict: 'สุเทพ', zipCode: '50200'),
    const ThaiAddressModel(province: 'เชียงใหม่', district: 'หางดง', subdistrict: 'หางดง', zipCode: '50230'),
    const ThaiAddressModel(province: 'เชียงใหม่', district: 'สันทราย', subdistrict: 'สันทรายหลวง', zipCode: '50210'),

    // สงขลา
    const ThaiAddressModel(province: 'สงขลา', district: 'เมืองสงขลา', subdistrict: 'บ่อยาง', zipCode: '90000'),
    const ThaiAddressModel(province: 'สงขลา', district: 'หาดใหญ่', subdistrict: 'หาดใหญ่', zipCode: '90110'),
    const ThaiAddressModel(province: 'สงขลา', district: 'สะเดา', subdistrict: 'สะเดา', zipCode: '90120'),

    // ภูเก็ต
    const ThaiAddressModel(province: 'ภูเก็ต', district: 'เมืองภูเก็ต', subdistrict: 'ตลาดใหญ่', zipCode: '83000'),
    const ThaiAddressModel(province: 'ภูเก็ต', district: 'กะทู้', subdistrict: 'ป่าตอง', zipCode: '83150'),
    const ThaiAddressModel(province: 'ภูเก็ต', district: 'ถลาง', subdistrict: 'เทพกระษัตรี', zipCode: '83110'),
  ];

  /// ดึงรายชื่ออำเภอทั้งหมดในจังหวัดที่เลือก
  static List<String> getDistricts(String province) {
    if (province.isEmpty) return [];
    final districts = _addressData
        .where((item) => item.province == province)
        .map((item) => item.district)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  /// ดึงรายชื่อตำบลทั้งหมดในอำเภอและจังหวัดที่เลือก
  static List<String> getSubdistricts(String province, String district) {
    if (province.isEmpty || district.isEmpty) return [];
    final subdistricts = _addressData
        .where((item) => item.province == province && item.district == district)
        .map((item) => item.subdistrict)
        .toSet()
        .toList();
    subdistricts.sort();
    return subdistricts;
  }

  /// ค้นหารหัสไปรษณีย์อัตโนมัติจาก ตำบล อำเภอ และจังหวัด
  static String? getZipCode(String province, String district, String subdistrict) {
    try {
      final match = _addressData.firstWhere(
        (item) =>
            item.province == province &&
            item.district == district &&
            item.subdistrict == subdistrict,
      );
      return match.zipCode;
    } catch (_) {
      return null;
    }
  }

  /// เพิ่มหรือลงทะเบียนข้อมูลที่อยู่ใหม่เข้า Memory ถ้าผู้ใช้พิมพ์เอง
  static void registerCustomAddress({
    required String province,
    required String district,
    required String subdistrict,
    required String zipCode,
  }) {
    if (province.isNotEmpty && district.isNotEmpty && subdistrict.isNotEmpty) {
      final exists = _addressData.any((item) =>
          item.province == province &&
          item.district == district &&
          item.subdistrict == subdistrict);
      if (!exists) {
        _addressData.add(ThaiAddressModel(
          province: province,
          district: district,
          subdistrict: subdistrict,
          zipCode: zipCode,
        ));
      }
    }
  }
}
