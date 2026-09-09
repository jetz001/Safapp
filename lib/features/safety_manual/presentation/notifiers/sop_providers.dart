import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sop_model.dart';
import '../../data/repositories/sop_repository.dart';

final sopRepositoryProvider = Provider<SopRepository>((ref) {
  return SopRepository();
});

// ================= FILTER NOTIFIERS (Riverpod 3) =================
class SopCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  void setCategory(String cat) => state = cat;
}

final sopCategoryFilterProvider =
    NotifierProvider<SopCategoryFilterNotifier, String>(SopCategoryFilterNotifier.new);

class SopSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final sopSearchQueryProvider =
    NotifierProvider<SopSearchQueryNotifier, String>(SopSearchQueryNotifier.new);

// ================= SOP LIST ASYNC NOTIFIER =================
class SopListNotifier extends AsyncNotifier<List<SopModel>> {
  @override
  Future<List<SopModel>> build() async {
    final repo = ref.read(sopRepositoryProvider);
    final category = ref.watch(sopCategoryFilterProvider);
    final search = ref.watch(sopSearchQueryProvider);
    return await repo.getSops(category: category, searchQuery: search);
  }

  Future<void> saveSop(SopModel item) async {
    final repo = ref.read(sopRepositoryProvider);
    if (item.id == null) {
      await repo.insertSop(item);
    } else {
      await repo.updateSop(item);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteSop(int id) async {
    final repo = ref.read(sopRepositoryProvider);
    await repo.deleteSop(id);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    final repo = ref.read(sopRepositoryProvider);
    await repo.updateSopStatus(id, status);
    ref.invalidateSelf();
  }
}

final sopListProvider =
    AsyncNotifierProvider<SopListNotifier, List<SopModel>>(SopListNotifier.new);

// ================= KPI SUMMARY =================
class SopKpiSummary {
  final int totalSops;
  final int activeSops;
  final int overdueSops;
  final int warningSops;

  const SopKpiSummary({
    required this.totalSops,
    required this.activeSops,
    required this.overdueSops,
    required this.warningSops,
  });
}

final sopKpiSummaryProvider = Provider<SopKpiSummary>((ref) {
  final sops = ref.watch(sopListProvider).value ?? [];
  final active = sops.where((s) => s.status == 'ACTIVE').length;
  final overdue = sops.where((s) => s.isReviewDue).length;
  final warning = sops.where((s) => s.isReviewWarning).length;

  return SopKpiSummary(
    totalSops: sops.length,
    activeSops: active,
    overdueSops: overdue,
    warningSops: warning,
  );
});
