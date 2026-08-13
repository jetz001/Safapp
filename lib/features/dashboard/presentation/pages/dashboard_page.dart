import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Lighter, modern background
      appBar: AppBar(
        title: const Text('ภาพรวมความปลอดภัย (Safety Dashboard)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
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
            const Text('สรุปข้อมูลประจำวัน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 2.2,
              children: [
                _buildPremiumStatCard('อุบัติเหตุสะสมปีนี้', '0', Icons.health_and_safety, const Color(0xFF10B981)),
                _buildPremiumStatCard('Near Miss รอดำเนินการ', '3', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
                _buildPremiumStatCard('PTW วันนี้', '5', Icons.assignment_turned_in, const Color(0xFF3B82F6)),
                _buildPremiumStatCard('พนักงานที่ถึงกำหนดอบรม', '12', Icons.people, const Color(0xFFEF4444)),
                _buildPremiumStatCard('ผู้รับเหมาในพื้นที่', '45', Icons.engineering, const Color(0xFF8B5CF6)),
                _buildPremiumStatCard('คะแนนประเมิน JSA', '95%', Icons.fact_check, const Color(0xFF14B8A6)),
              ],
            ),
            const SizedBox(height: 40),
            const Text('สถิติการเกิดอุบัติเหตุรายเดือน (TRIR)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 24),
            Container(
              height: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(months[value.toInt()], style: const TextStyle(color: Color(0xFF64748B))),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                        FlSpot(5, 1),
                        FlSpot(6, 0),
                      ],
                      isCurved: true,
                      color: const Color(0xFF1E3A8A),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
