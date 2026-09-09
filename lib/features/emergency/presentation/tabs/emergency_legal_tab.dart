import 'package:flutter/material.dart';
import '../../domain/services/emergency_evaluator.dart';

class EmergencyLegalTab extends StatefulWidget {
  const EmergencyLegalTab({super.key});

  @override
  State<EmergencyLegalTab> createState() => _EmergencyLegalTabState();
}

class _EmergencyLegalTabState extends State<EmergencyLegalTab> {
  // Calculator 1: Basic Fire Training Quota
  final _empCountCtrl = TextEditingController(text: '120');
  final _trainedCountCtrl = TextEditingController(text: '52');
  TrainingQuotaResult? _quotaResult;

  // Calculator 2: Fire Extinguishers
  final _areaCtrl = TextEditingController(text: '1200');
  String _hazardLevel = 'MEDIUM';
  ExtinguisherCalcResult? _extinguisherResult;

  @override
  void initState() {
    super.initState();
    _calcQuota();
    _calcExtinguisher();
  }

  @override
  void dispose() {
    _empCountCtrl.dispose();
    _trainedCountCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _calcQuota() {
    final total = int.tryParse(_empCountCtrl.text) ?? 0;
    final trained = int.tryParse(_trainedCountCtrl.text) ?? 0;
    setState(() {
      _quotaResult = EmergencyEvaluator.evaluateBasicFireTraining(
        totalEmployees: total,
        currentlyTrained: trained,
      );
    });
  }

  void _calcExtinguisher() {
    final area = double.tryParse(_areaCtrl.text) ?? 0.0;
    setState(() {
      _extinguisherResult = EmergencyEvaluator.evaluateExtinguishers(
        areaSqm: area,
        hazardLevel: _hazardLevel,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFFDC2626), size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คลังกฎหมายอัคคีภัยและเครื่องคำนวณตามเกณฑ์มาตรฐาน',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'รวบรวมข้อกำหนดราชกิจจานุเบกษา คำสั่งกรมสวัสดิการฯ พร้อมตัวคำนวณโควตาและอุปกรณ์ตามกฎหมาย',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Calculators Row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calculator 1: 40% Basic Fire Training
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.school, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 8),
                          Text('คำนวณโควตาอบรมดับเพลิงขั้นต้น (๔๐%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('ตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๒๗', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _empCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'พนักงานทั้งหมด (คน)', border: OutlineInputBorder()),
                              onChanged: (_) => _calcQuota(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _trainedCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'อบรมแล้ว (คน)', border: OutlineInputBorder()),
                              onChanged: (_) => _calcQuota(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_quotaResult != null) _buildQuotaResultView(_quotaResult!),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Calculator 2: Fire Extinguishers
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.fire_extinguisher, color: Color(0xFFDC2626), size: 20),
                          SizedBox(width: 8),
                          Text('คำนวณจำนวนเครื่องดับเพลิงและระยะติดตั้ง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('ตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๑๑ & ประกาศกรมฯ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _areaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'พื้นที่อาคาร/ชั้น (ตร.ม.)', border: OutlineInputBorder()),
                              onChanged: (_) => _calcExtinguisher(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _hazardLevel,
                              decoration: const InputDecoration(labelText: 'ระดับความเสี่ยงอัคคีภัย', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'LIGHT', child: Text('อันตรายน้อย (สำนักงาน)')),
                                DropdownMenuItem(value: 'MEDIUM', child: Text('อันตรายปานกลาง (โรงงาน/คลัง)')),
                                DropdownMenuItem(value: 'HIGH', child: Text('อันตรายมาก (สารเคมี/ไม้)')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  _hazardLevel = v;
                                  _calcExtinguisher();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_extinguisherResult != null) _buildExtinguisherResultView(_extinguisherResult!),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Legal Regulations Viewer ──
          const Text(
            'เอกสารกฎหมายและประกาศราชกิจจานุเบกษาหลัก',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          _buildLawCard(
            title: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕',
            gazetteRef: 'ราชกิจจานุเบกษา เล่ม ๑๓๐ ตอนที่ ๒ ก ลงวันที่ ๙ มกราคม ๒๕๕๖',
            keyPoints: [
              'ข้อ ๔: สถานประกอบกิจการที่มีลูกจ้างตั้งแต่ ๑๐ คนขึ้นไป ต้องจัดให้มีแผนป้องกันและระงับอัคคีภัย (๖ แผนย่อย: ตรวจตรา, อบรม, รณรงค์, ดับเพลิง, อพยพ, บรรเทาทุกข์)',
              'ข้อ ๑๑: การจัดให้มีเครื่องดับเพลิงแบบเคลื่อนย้ายได้ ระยะห่างไม่เกิน ๒๐ เมตร และส่วนบนสุดสูงจากพื้นไม่เกิน ๑.๕๐ เมตร',
              'ข้อ ๒๗: นายจ้างต้องจัดให้ลูกจ้างไม่น้อยกว่าร้อยละ ๔๐ ของจำนวนลูกจ้างในแต่ละแผนกรับการฝึกอบรมการดับเพลิงขั้นต้น',
              'ข้อ ๓๐: นายจ้างต้องจัดให้ลูกจ้างทุกคนฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟพร้อมกันอย่างน้อยปีละหนึ่งครั้ง และรายงานผลตามแบบที่อธิบดีกำหนด (สปร. ๔) ภายใน ๓๐ วัน',
            ],
          ),
          const SizedBox(height: 14),
          _buildLawCard(
            title: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง กำหนดแบบรายงานผลการฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟ (แบบ สปร. ๔)',
            gazetteRef: 'ราชกิจจานุเบกษา เล่ม ๑๓๐ ตอนพิเศษ ๓๒ ง ลงวันที่ ๑๑ มีนาคม ๒๕๕๖',
            keyPoints: [
              'กำหนดแบบฟอร์ม สปร. ๔ สำหรับส่งพนักงานตรวจความปลอดภัย ณ สำนักงานสวัสดิการและคุ้มครองแรงงานจังหวัด/พื้นที่',
              'ต้องแนบรายละเอียด: สถานการณ์จำลอง, เวลาที่ใช้ดับเพลิงขั้นต้น, เวลาที่ใช้อพยพทุกคนถึงจุดรวมพล, ผลตรวจนับยอด, ปัญหาอุปสรรค และภาพถ่าย',
            ],
          ),
          const SizedBox(height: 14),
          _buildLawCard(
            title: 'แนวทางการพิจารณาให้ความเห็นชอบแผนการฝึกซ้อม กรณีนายจ้างจัดให้มีการฝึกซ้อมเอง',
            gazetteRef: 'สำนักความปลอดภัยแรงงาน กรมสวัสดิการและคุ้มครองแรงงาน (ตามข้อ ๓๐ วรรคสอง)',
            keyPoints: [
              'กรณีนายจ้างไม่ใช้หน่วยงานที่ขึ้นทะเบียนตามมาตรา ๑๑ นายจ้างต้องส่งแผนและรายละเอียดให้ความเห็นชอบก่อนการฝึกซ้อมไม่น้อยกว่า ๓๐ วัน',
              'วิทยากรผู้ทำการฝึกซ้อมต้องมีคุณสมบัติผ่านการอบรมครูฝึกดับเพลิงและขึ้นทะเบียนอย่างถูกต้อง',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaResultView(TrainingQuotaResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: res.isCompliant ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: res.isCompliant ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(res.isCompliant ? Icons.check_circle : Icons.warning_rounded,
                size: 18, color: res.isCompliant ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              Text(
                res.isCompliant ? 'ผ่านเกณฑ์ตามกฎหมาย (Compliant)' : 'ต่ำกว่าเกณฑ์กฎหมาย (Non-Compliant)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: res.isCompliant ? const Color(0xFF059669) : const Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('• โควตาขั้นต่ำตามกฎหมาย (๔๐%): ${res.requiredQuota} คน (จากพนักงานทั้งหมด ${res.totalEmployees} คน)', style: const TextStyle(fontSize: 11)),
          Text('• ปัจจุบันผ่านการอบรมแล้ว: ${res.currentlyTrained} คน (${res.currentPercent.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11)),
          if (res.shortfall > 0)
            Text('• ขาดพนักงานที่ต้องส่งอบรมเพิ่ม: ${res.shortfall} คน', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        ],
      ),
    );
  }

  Widget _buildExtinguisherResultView(ExtinguisherCalcResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ผลการคำนวณอุปกรณ์ขั้นต่ำ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(4)),
                child: Text('${res.recommendedUnits} เครื่อง', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('• ระยะทางเดินเข้าถึงสูงสุด: ไม่เกิน ${res.maxTravelDistanceMeters.toStringAsFixed(0)} เมตร', style: const TextStyle(fontSize: 11)),
          Text('• ความสูงส่วนบนสุดของถัง: สูงจากพื้นไม่เกิน ${res.maxInstallationHeightMeters.toStringAsFixed(2)} เมตร', style: const TextStyle(fontSize: 11)),
          Text('• พิกัดประสิทธิภาพ (Fire Rating): ขั้นต่ำ ${res.minFireRating}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLawCard({
    required String title,
    required String gazetteRef,
    required List<String> keyPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(gazetteRef, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          ...keyPoints.map((kp) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Expanded(child: Text(kp, style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
