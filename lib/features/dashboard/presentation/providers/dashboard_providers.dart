import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/models/dashboard_models.dart';

final dashboardRepoProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardChartMetricNotifier extends Notifier<DashboardChartMetric> {
  @override
  DashboardChartMetric build() => DashboardChartMetric.trir;

  void setMetric(DashboardChartMetric metric) => state = metric;
}

final dashboardChartMetricProvider =
    NotifierProvider<DashboardChartMetricNotifier, DashboardChartMetric>(
        DashboardChartMetricNotifier.new);

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepoProvider);
  return await repo.getDashboardData();
});
