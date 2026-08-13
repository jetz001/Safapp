import 'package:flutter/material.dart';

class SmsSetupPage extends StatefulWidget {
  const SmsSetupPage({Key? key}) : super(key: key);

  @override
  State<SmsSetupPage> createState() => _SmsSetupPageState();
}

class _SmsSetupPageState extends State<SmsSetupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ข้อมูลองค์กร (SMS Context)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ตั้งค่าระบบการจัดการความปลอดภัย (Safety Management System)', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Basic Info
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'ข้อมูลทั่วไปของสถานประกอบการ',
                        icon: Icons.business,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Icon(Icons.domain, size: 48, color: Colors.grey),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                      onPressed: () {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField('ชื่อบริษัท / สถานประกอบการ', Icons.business_center),
                          const SizedBox(height: 16),
                          _buildTextField('เลขประจำตัวผู้เสียภาษี', Icons.tag),
                          const SizedBox(height: 16),
                          _buildTextField('ที่ตั้งสำนักงาน / โรงงาน', Icons.location_on, maxLines: 3),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('จำนวนพนักงาน (คน)', Icons.people)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('พื้นที่ (ตารางเมตร)', Icons.square_foot)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column - Policy & Goals
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'นโยบายและเป้าหมายความปลอดภัย',
                        icon: Icons.policy,
                        children: [
                          _buildTextField('คำประกาศนโยบายความปลอดภัย (Safety Policy)', Icons.article, maxLines: 5),
                          const SizedBox(height: 24),
                          const Text('เป้าหมายด้านความปลอดภัย (Safety Objectives)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155))),
                          const SizedBox(height: 16),
                          _buildGoalItem('เป้าหมายอุบัติเหตุถึงขั้นหยุดงาน (LTI)', '0 ครั้ง/ปี'),
                          const SizedBox(height: 12),
                          _buildGoalItem('เป้าหมายการฝึกอบรม', '100% ของพนักงาน'),
                          const SizedBox(height: 12),
                          _buildGoalItem('ความถี่ในการตรวจพื้นที่ (Audit)', 'สัปดาห์ละ 1 ครั้ง'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('เพิ่มเป้าหมาย'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
                            child: const Text('ยกเลิก', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลองค์กรเรียบร้อยแล้ว'), backgroundColor: Colors.green));
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('บันทึกข้อมูลองค์กร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade400) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildGoalItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF475569))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
