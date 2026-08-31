import 'package:flutter/material.dart';
import '../../domain/models/risk_matrix_criteria.dart';

/// วิดเจ็ตเมทริกซ์ความเสี่ยง 3x3 ตามเกณฑ์ประกาศกระทรวงแรงงาน (๒๕๖๗)
class InteractiveRiskMatrixWidget extends StatelessWidget {
  final int selectedLikelihood;
  final int selectedSeverity;
  final Function(int likelihood, int severity) onSelectionChanged;

  const InteractiveRiskMatrixWidget({
    Key? key,
    required this.selectedLikelihood,
    required this.selectedSeverity,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = RiskMatrixCriteria.evaluate(selectedLikelihood, selectedSeverity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score & Level Badge Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: result.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: result.color, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: result.color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${result.score}',
                  style: TextStyle(color: result.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          result.thaiName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: result.color.withOpacity(1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (result.requiresPor2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ต้องจัดทำแบบ ปอ.๒',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ยอมรับได้ (ไม่ต้องมี ปอ.๒)',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.meaning,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3x3 Matrix Grid Table
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-Axis Title (โอกาส Likelihood)
            RotatedBox(
              quarterTurns: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'โอกาส (Likelihood)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Grid Content
            Expanded(
              child: Column(
                children: [
                  // X-Axis Header (ความรุนแรง Severity)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'ความรุนแรง (Severity)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 80), // Offset for Y-labels
                      _buildHeaderCell('น้อย (๑)'),
                      _buildHeaderCell('ปานกลาง (๒)'),
                      _buildHeaderCell('มาก (๓)'),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rows for Likelihood 3, 2, 1
                  _buildMatrixRow(likelihood: 3, likelihoodLabel: 'มาก (๓)'),
                  _buildMatrixRow(likelihood: 2, likelihoodLabel: 'ปานกลาง (๒)'),
                  _buildMatrixRow(likelihood: 1, likelihoodLabel: 'น้อย (๑)'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected Criteria Details Card (คำอธิบายเกณฑ์ของกระทรวงแรงงาน)
        _buildCriteriaDetailsBox(selectedLikelihood, selectedSeverity),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMatrixRow({required int likelihood, required String likelihoodLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              likelihoodLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          _buildMatrixCell(likelihood, 1),
          const SizedBox(width: 4),
          _buildMatrixCell(likelihood, 2),
          const SizedBox(width: 4),
          _buildMatrixCell(likelihood, 3),
        ],
      ),
    );
  }

  Widget _buildMatrixCell(int l, int s) {
    final eval = RiskMatrixCriteria.evaluate(l, s);
    final isSelected = selectedLikelihood == l && selectedSeverity == s;

    return Expanded(
      child: InkWell(
        onTap: () => onSelectionChanged(l, s),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? eval.color : eval.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.black87 : eval.color,
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: eval.color.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${eval.score}',
                style: TextStyle(
                  color: isSelected ? eval.textColor : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                eval.thaiName.replaceFirst('ระดับ', ''),
                style: TextStyle(
                  color: isSelected ? eval.textColor : Colors.black87,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaDetailsBox(int l, int s) {
    final lInfo = RiskMatrixCriteria.likelihoodCriteria[l];
    final sInfo = RiskMatrixCriteria.severityCriteria[s];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              const Text(
                'เกณฑ์การพิจารณาตามประกาศกระทรวงแรงงาน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
              children: [
                TextSpan(
                  text: '● โอกาส (L=${lInfo?["title"]}): ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                TextSpan(text: '${lInfo?["description"]}\n'),
                TextSpan(
                  text: '● ความรุนแรง (S=${sInfo?["title"]}): ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                TextSpan(text: '${sInfo?["description"]}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
