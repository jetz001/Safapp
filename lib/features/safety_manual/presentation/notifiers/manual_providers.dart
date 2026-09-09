import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../data/models/factory_scope_model.dart';
import '../../data/models/manual_chapter_model.dart';
import '../../data/repositories/manual_repository.dart';

final manualRepositoryProvider = Provider<ManualRepository>((ref) {
  return ManualRepository();
});

// ================= FACTORY SCOPE ASYNC NOTIFIER =================
class FactoryScopeNotifier extends AsyncNotifier<FactoryScopeModel> {
  @override
  Future<FactoryScopeModel> build() async {
    final repo = ref.read(manualRepositoryProvider);
    return await repo.getFactoryScope();
  }

  Future<void> updateScope(FactoryScopeModel scope) async {
    final repo = ref.read(manualRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repo.saveFactoryScope(scope);
      state = AsyncValue.data(scope);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleField(String field, bool value) async {
    final current = state.value ?? const FactoryScopeModel();
    FactoryScopeModel updated;
    switch (field) {
      case 'hasBoiler':
        updated = current.copyWith(hasBoiler: value);
        break;
      case 'hasCrane':
        updated = current.copyWith(hasCrane: value);
        break;
      case 'hasChemical':
        updated = current.copyWith(hasChemical: value);
        break;
      case 'hasConfinedSpace':
        updated = current.copyWith(hasConfinedSpace: value);
        break;
      case 'hasWorkingAtHeight':
      case 'hasWorkAtHeight':
        updated = current.copyWith(hasWorkingAtHeight: value);
        break;
      case 'hasElectricalLoto':
      case 'hasElectrical':
        updated = current.copyWith(hasElectricalLoto: value);
        break;
      case 'hasEmergencyFire':
      case 'hasFireEmergency':
        updated = current.copyWith(hasEmergencyFire: value);
        break;
      case 'hasPpe':
        updated = current.copyWith(hasPpe: value);
        break;
      default:
        return;
    }
    await updateScope(updated);
  }
}

final factoryScopeProvider =
    AsyncNotifierProvider<FactoryScopeNotifier, FactoryScopeModel>(
  FactoryScopeNotifier.new,
);

// ================= DYNAMIC 3-TIER MANUAL PROVIDERS =================

/// Master Safety Manual (เล่มรวมข้อบังคับความปลอดภัย)
final masterManualChaptersProvider = Provider<List<ManualChapterModel>>((ref) {
  final repo = ref.watch(manualRepositoryProvider);
  final scope = ref.watch(factoryScopeProvider).value ?? const FactoryScopeModel();
  final companyProfile = ref.watch(companyProfileNotifierProvider).value;

  final companyName = (companyProfile?.companyName != null &&
          companyProfile!.companyName.trim().isNotEmpty)
      ? companyProfile.companyName
      : 'สถานประกอบการ';
  final policy = companyProfile?.safetyPolicy;
  final safetyOfficer = companyProfile?.safetyExpertName;

  return repo.buildMasterChapters(
    scope,
    companyName: companyName,
    safetyPolicy: policy,
    safetyOfficerName: safetyOfficer,
  );
});

/// Employee Safety Handbook / Pocket Guide (คู่มือความปลอดภัยฉบับพนักงาน)
final employeeHandbookChaptersProvider =
    Provider<List<ManualChapterModel>>((ref) {
  final repo = ref.watch(manualRepositoryProvider);
  final scope = ref.watch(factoryScopeProvider).value ?? const FactoryScopeModel();
  final companyProfile = ref.watch(companyProfileNotifierProvider).value;

  final companyName = (companyProfile?.companyName != null &&
          companyProfile!.companyName.trim().isNotEmpty)
      ? companyProfile.companyName
      : 'สถานประกอบการ';

  return repo.buildEmployeeHandbookChapters(
    scope,
    companyName: companyName,
  );
});

/// 1-Page Safety Induction Leaflet (ใบสรุปความปลอดภัย 1 หน้า พนักงานใหม่/ผู้รับเหมา)
final safetyInductionLeafletProvider = Provider<ManualChapterModel>((ref) {
  final repo = ref.watch(manualRepositoryProvider);
  final scope = ref.watch(factoryScopeProvider).value ?? const FactoryScopeModel();
  final companyProfile = ref.watch(companyProfileNotifierProvider).value;

  final companyName = (companyProfile?.companyName != null &&
          companyProfile!.companyName.trim().isNotEmpty)
      ? companyProfile.companyName
      : 'สถานประกอบการ';

  return repo.buildSafetyInductionLeaflet(
    scope,
    companyName: companyName,
  );
});
