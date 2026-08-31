import 'package:flutter/material.dart';

/// Metadata for the 9 standard UN / Thai GHS Pictograms.
class GhsPictogramInfo {
  final String code; // e.g. GHS01, GHS02
  final String nameTh;
  final String nameEn;
  final IconData icon;
  final Color primaryColor;
  final String description;

  const GhsPictogramInfo({
    required this.code,
    required this.nameTh,
    required this.nameEn,
    required this.icon,
    required this.primaryColor,
    required this.description,
  });
}

class GhsPictograms {
  static const List<GhsPictogramInfo> all = [
    GhsPictogramInfo(
      code: 'GHS01',
      nameTh: 'วัตถุระเบิด',
      nameEn: 'Exploding Bomb',
      icon: Icons.brightness_high_rounded,
      primaryColor: Color(0xFFDC2626),
      description: 'สารระเบิดได้ สารที่ทำปฏิกิริยาได้เอง สารอินทรีย์เปอร์ออกไซด์',
    ),
    GhsPictogramInfo(
      code: 'GHS02',
      nameTh: 'สารไวไฟ',
      nameEn: 'Flame',
      icon: Icons.local_fire_department_rounded,
      primaryColor: Color(0xFFEA580C),
      description: 'ก๊าซ ของเหลว ของแข็งไวไฟ สารที่ติดไฟได้เอง สารที่สัมผัสน้ำแล้วให้ก๊าซไวไฟ',
    ),
    GhsPictogramInfo(
      code: 'GHS03',
      nameTh: 'สารออกซิไดซ์',
      nameEn: 'Flame over Circle',
      icon: Icons.album_rounded,
      primaryColor: Color(0xFFD97706),
      description: 'ก๊าซ ของเหลว หรือของแข็งออกซิไดซ์ เร่งให้เกิดการลุกไหม้รุนแรง',
    ),
    GhsPictogramInfo(
      code: 'GHS04',
      nameTh: 'ก๊าซบรรจุภายใต้ความดัน',
      nameEn: 'Gas Cylinder',
      icon: Icons.propane_tank_rounded,
      primaryColor: Color(0xFF0284C7),
      description: 'ก๊าซอัด ก๊าซเหลว ก๊าซละลายภายใต้ความดัน ก๊าซเหลวอุณหภูมิต่ำยิ่งยวด',
    ),
    GhsPictogramInfo(
      code: 'GHS05',
      nameTh: 'สารกัดกร่อน',
      nameEn: 'Corrosion',
      icon: Icons.science_rounded,
      primaryColor: Color(0xFF475569),
      description: 'สารกัดกร่อนโลหะ กัดกร่อนผิวหนัง และทำลายดวงตาอย่างรุนแรง',
    ),
    GhsPictogramInfo(
      code: 'GHS06',
      nameTh: 'ความเป็นพิษเฉียบพลัน',
      nameEn: 'Skull and Crossbones',
      icon: Icons.dangerous_rounded,
      primaryColor: Color(0xFF991B1B),
      description: 'สารพิษเฉียบพลันร้ายแรง (ประเภท ๑-๓) อาจถึงแก่ชีวิตเมื่อสูดดม กลืนกิน หรือสัมผัส',
    ),
    GhsPictogramInfo(
      code: 'GHS07',
      nameTh: 'อันตรายต่อสุขภาพ / ระคายเคือง',
      nameEn: 'Exclamation Mark',
      icon: Icons.priority_high_rounded,
      primaryColor: Color(0xFFD97706),
      description: 'สารระคายเคืองตา/ผิวหนัง ความเป็นพิษเฉียบพลันระดับต่ำ สารก่อภูมิแพ้ผิวหนัง',
    ),
    GhsPictogramInfo(
      code: 'GHS08',
      nameTh: 'อันตรายต่อสุขภาพระยะยาว',
      nameEn: 'Health Hazard',
      icon: Icons.healing_rounded,
      primaryColor: Color(0xFFB91C1C),
      description: 'สารก่อมะเร็ง สารก่อการกลายพันธุ์ สารพิษต่อระบบสืบพันธุ์ สารก่อโรคหอบหืด',
    ),
    GhsPictogramInfo(
      code: 'GHS09',
      nameTh: 'อันตรายต่อสิ่งแวดล้อม',
      nameEn: 'Environment',
      icon: Icons.park_rounded,
      primaryColor: Color(0xFF15803D),
      description: 'ความเป็นพิษเฉียบพลันหรือเรื้อรังต่อระบบนิเวศทางน้ำ',
    ),
  ];

  static GhsPictogramInfo? getByCode(String code) {
    try {
      return all.firstWhere((p) => p.code.toUpperCase() == code.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}

/// Interactive selector widget allowing users to select 1 or more of the 9 GHS pictograms.
class GhsPictogramSelector extends StatelessWidget {
  final List<String> selectedCodes;
  final ValueChanged<List<String>> onChanged;
  final bool readOnly;

  const GhsPictogramSelector({
    Key? key,
    required this.selectedCodes,
    required this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  void _toggle(String code) {
    if (readOnly) return;
    final list = List<String>.from(selectedCodes);
    if (list.contains(code)) {
      list.remove(code);
    } else {
      list.add(code);
    }
    onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF1E293B)),
            const SizedBox(width: 8),
            const Text(
              'รูปสัญลักษณ์แสดงความเป็นอันตรายตามระบบ GHS (9 Pictograms)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            if (selectedCodes.isNotEmpty && !readOnly)
              TextButton.icon(
                onPressed: () => onChanged([]),
                icon: const Icon(Icons.clear_all_rounded, size: 14),
                label: const Text('ล้างทั้งหมด', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GhsPictograms.all.map((item) {
            final isSelected = selectedCodes.contains(item.code);
            return Tooltip(
              message: '${item.code}: ${item.nameTh} (${item.nameEn})\n${item.description}',
              preferBelow: false,
              child: InkWell(
                onTap: readOnly ? null : () => _toggle(item.code),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? item.primaryColor.withValues(alpha: 0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? item.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? item.primaryColor : Colors.white,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? item.primaryColor : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: isSelected ? Colors.white : item.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nameTh,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? item.primaryColor : const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            item.code,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? item.primaryColor.withValues(alpha: 0.8) : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, size: 16, color: item.primaryColor),
                      ]
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Compact badge row for displaying selected GHS pictograms in lists/cards.
class GhsPictogramsDisplayRow extends StatelessWidget {
  final List<String> codes;
  final double iconSize;

  const GhsPictogramsDisplayRow({
    Key? key,
    required this.codes,
    this.iconSize = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (codes.isEmpty) {
      return const Text('ไม่มีรูปสัญลักษณ์', style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: codes.map((c) {
        final info = GhsPictograms.getByCode(c);
        if (info == null) return const SizedBox.shrink();
        return Tooltip(
          message: '${info.code}: ${info.nameTh} (${info.nameEn})',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(info.icon, size: iconSize, color: const Color(0xFFDC2626)),
          ),
        );
      }).toList(),
    );
  }
}
