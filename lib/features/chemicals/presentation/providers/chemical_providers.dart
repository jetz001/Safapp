import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chemical_repository.dart';
import '../../domain/models/chemical_inventory_model.dart';
import '../../domain/models/chemical_sds_sor1_model.dart';
import '../../domain/models/chemical_measurement_sor3_model.dart';
import '../../domain/models/chemical_laws_model.dart';
import '../../domain/models/chemical_master_model.dart';
import '../../domain/models/chemical_tlv_model.dart';

/// Provider for the ChemicalRepository singleton.
final chemicalRepoProvider = Provider<ChemicalRepository>((ref) {
  return ChemicalRepository();
});

// ----------------------------------------------------------------------------
// Filter State Providers (Riverpod 3 NotifierProvider)
// ----------------------------------------------------------------------------

class ChemicalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}
final chemicalSearchQueryProvider = NotifierProvider<ChemicalSearchQueryNotifier, String>(ChemicalSearchQueryNotifier.new);

class ChemicalStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}
final chemicalStatusFilterProvider = NotifierProvider<ChemicalStatusFilterNotifier, String>(ChemicalStatusFilterNotifier.new);

class ChemicalLocationFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}
final chemicalLocationFilterProvider = NotifierProvider<ChemicalLocationFilterNotifier, String>(ChemicalLocationFilterNotifier.new);

class ChemicalSdsExpiryFilterNotifier extends Notifier<SdsExpiryStatus?> {
  @override
  SdsExpiryStatus? build() => null;
  @override
  set state(SdsExpiryStatus? val) => super.state = val;
}
final chemicalSdsExpiryFilterProvider = NotifierProvider<ChemicalSdsExpiryFilterNotifier, SdsExpiryStatus?>(ChemicalSdsExpiryFilterNotifier.new);

class ChemicalSelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  @override
  set state(int val) => super.state = val;
}
final chemicalSelectedTabProvider = NotifierProvider<ChemicalSelectedTabNotifier, int>(ChemicalSelectedTabNotifier.new);

class ChemicalLawSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}
final chemicalLawSearchQueryProvider = NotifierProvider<ChemicalLawSearchQueryNotifier, String>(ChemicalLawSearchQueryNotifier.new);

// Form สอ.๑ Filters
class ChemicalSor1SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}
final chemicalSor1SearchQueryProvider = NotifierProvider<ChemicalSor1SearchQueryNotifier, String>(ChemicalSor1SearchQueryNotifier.new);

class ChemicalSor1StatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}
final chemicalSor1StatusFilterProvider = NotifierProvider<ChemicalSor1StatusFilterNotifier, String>(ChemicalSor1StatusFilterNotifier.new);

// Form สอ.๓ Filters
class ChemicalSor3SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}
final chemicalSor3SearchQueryProvider = NotifierProvider<ChemicalSor3SearchQueryNotifier, String>(ChemicalSor3SearchQueryNotifier.new);

class ChemicalSor3ResultFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';
  @override
  set state(String val) => super.state = val;
}
final chemicalSor3ResultFilterProvider = NotifierProvider<ChemicalSor3ResultFilterNotifier, String>(ChemicalSor3ResultFilterNotifier.new);

// ----------------------------------------------------------------------------
// Chemical Inventory Notifier & Provider (Tab 1)
// ----------------------------------------------------------------------------

class ChemicalInventoryNotifier extends AsyncNotifier<List<ChemicalInventoryItem>> {
  @override
  Future<List<ChemicalInventoryItem>> build() async {
    final repo = ref.watch(chemicalRepoProvider);
    final query = ref.watch(chemicalSearchQueryProvider);
    final status = ref.watch(chemicalStatusFilterProvider);
    final location = ref.watch(chemicalLocationFilterProvider);
    final expiryFilter = ref.watch(chemicalSdsExpiryFilterProvider);

    return await repo.getAllInventory(
      query: query,
      status: status,
      location: location,
      expiryFilter: expiryFilter,
    );
  }

  Future<int> saveInventory(
    ChemicalInventoryItem item, {
    String? newSdsPath,
    String? newLabelPath,
  }) async {
    final repo = ref.read(chemicalRepoProvider);
    final id = await repo.saveInventory(
      item,
      newSdsPath: newSdsPath,
      newLabelPath: newLabelPath,
    );
    ref.invalidateSelf();
    ref.invalidate(chemicalKpiStatsProvider);
    ref.invalidate(chemicalStorageLocationsProvider);
    return id;
  }

  Future<int> deleteInventory(int id) async {
    final repo = ref.read(chemicalRepoProvider);
    final count = await repo.deleteInventory(id);
    ref.invalidateSelf();
    ref.invalidate(chemicalKpiStatsProvider);
    ref.invalidate(chemicalStorageLocationsProvider);
    return count;
  }
}

final chemicalInventoryProvider =
    AsyncNotifierProvider<ChemicalInventoryNotifier, List<ChemicalInventoryItem>>(
  ChemicalInventoryNotifier.new,
);

// ----------------------------------------------------------------------------
// Form สอ.๑ (SDS 16 Sections) Notifier & Provider (Tab 2)
// ----------------------------------------------------------------------------

class ChemicalSdsSor1Notifier extends AsyncNotifier<List<ChemicalSdsSor1Model>> {
  @override
  Future<List<ChemicalSdsSor1Model>> build() async {
    final repo = ref.watch(chemicalRepoProvider);
    final query = ref.watch(chemicalSor1SearchQueryProvider);
    final status = ref.watch(chemicalSor1StatusFilterProvider);

    return await repo.getAllSdsSor1(
      query: query,
      status: status,
    );
  }

  Future<int> saveSdsSor1(ChemicalSdsSor1Model item) async {
    final repo = ref.read(chemicalRepoProvider);
    final id = await repo.saveSdsSor1(item);
    ref.invalidateSelf();
    return id;
  }

  Future<int> deleteSdsSor1(int id) async {
    final repo = ref.read(chemicalRepoProvider);
    final count = await repo.deleteSdsSor1(id);
    ref.invalidateSelf();
    return count;
  }
}

final chemicalSdsSor1ListProvider =
    AsyncNotifierProvider<ChemicalSdsSor1Notifier, List<ChemicalSdsSor1Model>>(
  ChemicalSdsSor1Notifier.new,
);

final chemicalSdsSor1DetailProvider =
    FutureProvider.family<ChemicalSdsSor1Model?, int>((ref, id) async {
  final repo = ref.watch(chemicalRepoProvider);
  return await repo.getSdsSor1ById(id);
});

// ----------------------------------------------------------------------------
// Form สอ.๓ (Atmospheric Measurement 2022) Notifier & Provider (Tab 3)
// ----------------------------------------------------------------------------

class ChemicalMeasurementSor3Notifier extends AsyncNotifier<List<ChemicalMeasurementSor3Model>> {
  @override
  Future<List<ChemicalMeasurementSor3Model>> build() async {
    final repo = ref.watch(chemicalRepoProvider);
    final query = ref.watch(chemicalSor3SearchQueryProvider);
    final resultFilter = ref.watch(chemicalSor3ResultFilterProvider);

    return await repo.getAllMeasurementSor3(
      query: query,
      resultFilter: resultFilter,
    );
  }

  Future<int> saveMeasurementSor3(
    ChemicalMeasurementSor3Model item, {
    String? newCertPath,
  }) async {
    final repo = ref.read(chemicalRepoProvider);
    final id = await repo.saveMeasurementSor3(item, newCertPath: newCertPath);
    ref.invalidateSelf();
    ref.invalidate(chemicalMeasurementKpiProvider);
    return id;
  }

  Future<int> deleteMeasurementSor3(int id) async {
    final repo = ref.read(chemicalRepoProvider);
    final count = await repo.deleteMeasurementSor3(id);
    ref.invalidateSelf();
    ref.invalidate(chemicalMeasurementKpiProvider);
    return count;
  }
}

final chemicalMeasurementSor3ListProvider =
    AsyncNotifierProvider<ChemicalMeasurementSor3Notifier, List<ChemicalMeasurementSor3Model>>(
  ChemicalMeasurementSor3Notifier.new,
);

final chemicalMeasurementKpiProvider = FutureProvider<
    ({
      int total,
      int passCount,
      int actionLevelCount,
      int failCount,
    })>((ref) async {
  final repo = ref.watch(chemicalRepoProvider);
  return await repo.getMeasurementKpiStats();
});

final chemicalMeasurementSor3DetailProvider =
    FutureProvider.family<ChemicalMeasurementSor3Model?, int>((ref, id) async {
  final repo = ref.watch(chemicalRepoProvider);
  return await repo.getMeasurementSor3ById(id);
});

// ----------------------------------------------------------------------------
// KPI Stats & Dropdown Filter Providers
// ----------------------------------------------------------------------------

final chemicalKpiStatsProvider = FutureProvider<
    ({
      int total,
      int validSds,
      int nearExpiry,
      int expired,
      double totalQtySolidKg,
      double totalQtyLiquidL,
    })>((ref) async {
  final repo = ref.watch(chemicalRepoProvider);
  return await repo.getInventoryKpiStats();
});

final chemicalStorageLocationsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(chemicalRepoProvider);
  return await repo.getDistinctStorageLocations();
});

// ----------------------------------------------------------------------------
// Legal Reference Library Providers (Tab 4)
// ----------------------------------------------------------------------------

final chemicalLawsListProvider = Provider<List<ChemicalLawItem>>((ref) {
  final repo = ref.watch(chemicalRepoProvider);
  final query = ref.watch(chemicalLawSearchQueryProvider);
  if (query.trim().isEmpty) {
    return repo.getAllLaws();
  }
  return repo.searchLaws(query);
});

// ----------------------------------------------------------------------------
// Master Data Autocomplete Search Provider
// ----------------------------------------------------------------------------

final chemicalMasterSearchProvider =
    Provider.family<List<ChemicalMasterItem>, String>((ref, query) {
  final repo = ref.watch(chemicalRepoProvider);
  return repo.searchMasterChemicals(query, limit: 25);
});

final chemicalTlvSearchProvider =
    Provider.family<List<ChemicalTlvItem>, String>((ref, query) {
  final repo = ref.watch(chemicalRepoProvider);
  return repo.searchTlv(query, limit: 20);
});
