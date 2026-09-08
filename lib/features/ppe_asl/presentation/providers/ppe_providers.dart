import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ppe_repository.dart';
import '../../domain/models/ppe_item_model.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../../domain/models/asl_supplier_model.dart';

final ppeRepositoryProvider = Provider<PpeRepository>((ref) {
  return PpeRepository();
});

// ── PPE Catalog Filters ──
class PpeCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
  void reset() => super.state = 'ALL';
}

final ppeCategoryFilterProvider =
    NotifierProvider<PpeCategoryFilterNotifier, String>(PpeCategoryFilterNotifier.new);

class PpeSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
  void clear() => super.state = '';
}

final ppeSearchQueryProvider =
    NotifierProvider<PpeSearchQueryNotifier, String>(PpeSearchQueryNotifier.new);

class PpeLowStockFilterNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  @override
  set state(bool val) => super.state = val;
}

final ppeLowStockFilterProvider =
    NotifierProvider<PpeLowStockFilterNotifier, bool>(PpeLowStockFilterNotifier.new);

// ── PPE Items List ──
final ppeItemsProvider = FutureProvider<List<PpeItem>>((ref) async {
  final repo = ref.watch(ppeRepositoryProvider);
  final category = ref.watch(ppeCategoryFilterProvider);
  final search = ref.watch(ppeSearchQueryProvider);
  final lowStock = ref.watch(ppeLowStockFilterProvider);

  return repo.getAllPpeItems(
    category: category,
    searchQuery: search,
    lowStockOnly: lowStock,
  );
});

// ── Transactions Filters & List ──
class PpeTxTypeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}

final ppeTxTypeFilterProvider =
    NotifierProvider<PpeTxTypeFilterNotifier, String>(PpeTxTypeFilterNotifier.new);

class PpeTxSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}

final ppeTxSearchQueryProvider =
    NotifierProvider<PpeTxSearchQueryNotifier, String>(PpeTxSearchQueryNotifier.new);

class PpeTxSelectedPpeIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  @override
  set state(int? val) => super.state = val;
}

final ppeTxSelectedPpeIdProvider =
    NotifierProvider<PpeTxSelectedPpeIdNotifier, int?>(PpeTxSelectedPpeIdNotifier.new);

final ppeTransactionsProvider = FutureProvider<List<PpeTransaction>>((ref) async {
  final repo = ref.watch(ppeRepositoryProvider);
  final type = ref.watch(ppeTxTypeFilterProvider);
  final search = ref.watch(ppeTxSearchQueryProvider);
  final ppeId = ref.watch(ppeTxSelectedPpeIdProvider);

  return repo.getTransactions(
    type: type,
    searchQuery: search,
    ppeId: ppeId,
  );
});

// ── ASL Filters & List ──
class AslStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}

final aslStatusFilterProvider =
    NotifierProvider<AslStatusFilterNotifier, String>(AslStatusFilterNotifier.new);

class AslSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}

final aslSearchQueryProvider =
    NotifierProvider<AslSearchQueryNotifier, String>(AslSearchQueryNotifier.new);

final aslSuppliersProvider = FutureProvider<List<AslSupplier>>((ref) async {
  final repo = ref.watch(ppeRepositoryProvider);
  final status = ref.watch(aslStatusFilterProvider);
  final search = ref.watch(aslSearchQueryProvider);

  return repo.getAllSuppliers(
    status: status,
    searchQuery: search,
  );
});

// ── Dashboard Metrics ──
final ppeDashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(ppeRepositoryProvider);
  return repo.getDashboardMetrics();
});
