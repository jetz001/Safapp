import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_superapp/core/providers/database_provider.dart';

// ---------------------------------------------------------
// 1. Domain Entities & State Models
// ---------------------------------------------------------
class ActionItem {
  final String description;
  final String responsiblePerson;
  final DateTime dueDate;
  ActionItem({required this.description, required this.responsiblePerson, required this.dueDate});
}

class NearMissFormState {
  final String description;
  final String riskLevel;
  final String? imagePath;
  final List<ActionItem> actions;

  NearMissFormState({
    this.description = '',
    this.riskLevel = 'Low',
    this.imagePath,
    this.actions = const [],
  });

  NearMissFormState copyWith({
    String? description, String? riskLevel, String? imagePath, List<ActionItem>? actions,
  }) {
    return NearMissFormState(
      description: description ?? this.description,
      riskLevel: riskLevel ?? this.riskLevel,
      imagePath: imagePath ?? this.imagePath,
      actions: actions ?? this.actions,
    );
  }
}

// ---------------------------------------------------------
// 2. Riverpod State Notifier
// ---------------------------------------------------------
class NearMissFormProvider extends Notifier<NearMissFormState> {
  @override
  NearMissFormState build() {
    return NearMissFormState();
  }
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updateRiskLevel(String value) => state = state.copyWith(riskLevel: value);
  void attachImage(String path) => state = state.copyWith(imagePath: path);
  void addActionItem(ActionItem item) {
    state = state.copyWith(actions: [...state.actions, item]);
  }
  Future<void> submitForm() async {
    if (state.description.isEmpty) return; // Basic validation
    
    final db = await ref.read(databaseProvider.future);
    
    // 1. Insert Near Miss Event
    final eventId = await db.insert('safety_events', {
      'event_type': 'NEAR_MISS',
      'event_date': DateTime.now().toIso8601String(),
      'description': state.description,
      'initial_risk_level': state.riskLevel,
      'image_path': state.imagePath,
      'status': 'OPEN',
    });

    // 2. Insert Action Trackers
    for (var action in state.actions) {
      await db.insert('action_trackers', {
        'source_module': 'SAFETY_EVENT',
        'source_id': eventId,
        'action_description': action.description,
        'responsible_person': action.responsiblePerson,
        'due_date': action.dueDate.toIso8601String(),
        'status': 'OPEN',
      });
    }

    debugPrint('✅ [บันทึกสำเร็จ] Near Miss ID: $eventId, Actions: ${state.actions.length}');
    
    // Reset Form
    state = NearMissFormState();
  }
}

final nearMissFormProvider = NotifierProvider<NearMissFormProvider, NearMissFormState>(() {
  return NearMissFormProvider();
});

// ---------------------------------------------------------
// 3. Presentation (Premium Desktop UI)
// ---------------------------------------------------------
class NearMissFormPage extends ConsumerWidget {
  const NearMissFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(nearMissFormProvider);
    final formController = ref.read(nearMissFormProvider.notifier);

    // Color Palette สำหรับ Light Theme
    const bgColor = Color(0xFFF3F4F6); // พื้นหลังแอป สีเทาอ่อนมาก
    const primaryColor = Color(0xFF1E3A8A); // สีหลัก น้ำเงินเข้มองค์กร
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('บันทึกรายงาน Near Miss', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cardColor,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // จำกัดความกว้างสำหรับ Desktop
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            children: [
              // --- Card 1: รายละเอียดเหตุการณ์ ---
              _buildSectionCard(
                title: 'รายละเอียดเหตุการณ์',
                icon: Icons.description_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        hintText: 'อธิบายเหตุการณ์ที่เกือบเกิดอุบัติเหตุอย่างละเอียด...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      onChanged: formController.updateDescription,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => formController.attachImage(r'C:\Users\Desktop\img_01.jpg'),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                          label: const Text('แนบภาพประกอบ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade700,
                            elevation: 0,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (formState.imagePath != null)
                          Expanded(
                            child: Text(
                              '📎 ${formState.imagePath}',
                              style: TextStyle(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Card 2: ประเมินความเสี่ยงเบื้องต้น ---
              _buildSectionCard(
                title: 'ประเมินความเสี่ยงเบื้องต้น (Initial Risk)',
                icon: Icons.warning_amber_rounded,
                child: Row(
                  children: [
                    _buildRiskButton('Low', 'ต่ำ', Colors.green, formState.riskLevel, formController),
                    const SizedBox(width: 12),
                    _buildRiskButton('Medium', 'ปานกลาง', Colors.orange, formState.riskLevel, formController),
                    const SizedBox(width: 12),
                    _buildRiskButton('High', 'สูง', Colors.red, formState.riskLevel, formController),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Card 3: Action Tracker (CAPA) ---
              _buildSectionCard(
                title: 'มาตรการแก้ไข / ป้องกัน (CAPA)',
                icon: Icons.track_changes_outlined,
                actionWidget: TextButton.icon(
                  onPressed: () => _showAddActionDialog(context, formController),
                  icon: const Icon(Icons.add, color: primaryColor),
                  label: const Text('เพิ่มมาตรการ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                child: formState.actions.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: const Text(
                          'ยังไม่มีมาตรการแก้ไข กด "เพิ่มมาตรการ" เพื่อสร้างงานส่งเข้า Action Tracker',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formState.actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final action = formState.actions[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE0F2FE),
                                child: Icon(Icons.assignment_turned_in, color: Color(0xFF0284C7), size: 20),
                              ),
                              title: Text(action.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('👤 ${action.responsiblePerson}   📅 เสร็จสิ้นภายใน: ${action.dueDate.toIso8601String().split('T')[0]}'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 32),

              // --- ปุ่มบันทึกหลัก ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    formController.submitForm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('บันทึกสำเร็จ')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text('บันทึกและส่งรายงาน (Submit Report)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Helper: สำหรับสร้าง Card แต่ละ Section ---
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? actionWidget}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey.shade700, size: 24),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
          const Divider(height: 32, thickness: 1),
          child,
        ],
      ),
    );
  }

  // --- Widget Helper: ปุ่มเลือกระดับความเสี่ยง ---
  Widget _buildRiskButton(String value, String label, MaterialColor color, String currentValue, NearMissFormProvider controller) {
    final isSelected = value == currentValue;
    return Expanded(
      child: InkWell(
        onTap: () => controller.updateRiskLevel(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? color.shade800 : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog Mock 
  void _showAddActionDialog(BuildContext context, NearMissFormProvider controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มมาตรการแก้ไข'),
        content: const Text('จำลองการกรอกข้อมูลมาตรการ...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              controller.addActionItem(ActionItem(description: 'ปรับปรุงพื้นที่แสงสว่างน้อย', responsiblePerson: 'ทีมช่างไฟ', dueDate: DateTime.now().add(const Duration(days: 2))));
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }
}
