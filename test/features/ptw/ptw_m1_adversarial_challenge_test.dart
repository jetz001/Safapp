import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/ptw/domain/enums/energy_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/confined_role_type.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/data/models/gas_test_log_model.dart';
import 'package:safety_superapp/features/ptw/data/models/confined_role_model.dart';
import 'package:safety_superapp/features/ptw/data/models/fire_watch_model.dart';
import 'package:safety_superapp/features/ptw/data/models/loto_isolation_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_checklist_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_approval_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_kpi_summary_model.dart';
import 'package:safety_superapp/features/ptw/domain/services/ptw_safety_evaluator.dart';
import 'package:safety_superapp/features/ptw/data/repositories/ptw_repository.dart';

/// Test helper repository with injected in-memory SQLite database
class _AdversarialTestPtwRepository extends PtwRepository {
  final Database _testDb;
  _AdversarialTestPtwRepository(this._testDb);

  @override
  Future<Database> get _db async => _testDb;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('M1 Adversarial Challenge: Gas Atmospheric Boundary Limits', () {
    test('Oxygen Exact Boundary: 19.4% (FAIL), 19.5% (PASS), 23.5% (PASS), 23.6% (FAIL)', () {
      // 19.4% -> Sub-oxygen deficient -> MUST FAIL
      final res194 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 19.4,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res194.isValid, isFalse, reason: 'O2 = 19.4% must fail under กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗');
      expect(res194.errors.any((e) => e.contains('ออกซิเจนต่ำกว่าเกณฑ์')), isTrue);

      // 19.5% -> Exact Lower Statutory Bound -> MUST PASS
      final res195 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 19.5,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res195.isValid, isTrue, reason: 'O2 = 19.5% is exact lower statutory threshold and must pass');

      // 23.5% -> Exact Upper Statutory Bound -> MUST PASS
      final res235 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 23.5,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res235.isValid, isTrue, reason: 'O2 = 23.5% is exact upper statutory threshold and must pass');

      // 23.6% -> Oxygen Enriched Flammable Hazard -> MUST FAIL
      final res236 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 23.6,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res236.isValid, isFalse, reason: 'O2 = 23.6% must fail as oxygen enriched atmosphere');
      expect(res236.errors.any((e) => e.contains('ออกซิเจนสูงกว่าเกณฑ์')), isTrue);
    });

    test('Combustible Gas LEL Exact Boundary: 9.9% (PASS), 10.0% (FAIL), 10.1% (FAIL)', () {
      // 9.9% LEL -> Below 10.0% standard limit -> MUST PASS (with warning since >= 5.0%)
      final res99 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 9.9,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res99.isValid, isTrue, reason: 'LEL = 9.9% is below 10.0% limit and must pass');
      expect(res99.warnings.any((w) => w.contains('เฝ้าระวัง')), isTrue);

      // 10.0% LEL -> Exact Statutory Explosive Limit -> MUST FAIL
      final res100 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 10.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res100.isValid, isFalse, reason: 'LEL = 10.0% must fail under ข้อ ๗ (< 10.0% LEL required)');
      expect(res100.errors.any((e) => e.contains('ก๊าซหรือไอระเหยไวไฟเกินเกณฑ์')), isTrue);

      // 10.1% LEL -> Exceeded Explosive Limit -> MUST FAIL
      final res101 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 10.1,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res101.isValid, isFalse, reason: 'LEL = 10.1% must fail');
    });

    test('Carbon Monoxide (CO) Exact Boundary: 24.9 ppm (PASS), 25.0 ppm (FAIL), 25.1 ppm (FAIL)', () {
      // 24.9 ppm -> Below 25.0 ppm limit -> MUST PASS
      final res249 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 24.9,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res249.isValid, isTrue, reason: 'CO = 24.9 ppm is < 25.0 ppm and must pass');

      // 25.0 ppm -> Exact Statutory Ceiling -> MUST FAIL
      final res250 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 25.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res250.isValid, isFalse, reason: 'CO = 25.0 ppm must fail under ข้อ ๗ (< 25.0 ppm required)');
      expect(res250.errors.any((e) => e.contains('คาร์บอนมอนอกไซด์เกินเกณฑ์')), isTrue);

      // 25.1 ppm -> Toxic Atmosphere -> MUST FAIL
      final res251 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 25.1,
        hydrogenSulfidePpm: 0.0,
      );
      expect(res251.isValid, isFalse, reason: 'CO = 25.1 ppm must fail');
    });

    test('Hydrogen Sulfide (H2S) Exact Boundary: 9.9 ppm (PASS), 10.0 ppm (FAIL), 10.1 ppm (FAIL)', () {
      // 9.9 ppm -> Below 10.0 ppm limit -> MUST PASS
      final res99 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 9.9,
      );
      expect(res99.isValid, isTrue, reason: 'H2S = 9.9 ppm is < 10.0 ppm and must pass');

      // 10.0 ppm -> Exact Statutory Ceiling -> MUST FAIL
      final res100 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 10.0,
      );
      expect(res100.isValid, isFalse, reason: 'H2S = 10.0 ppm must fail under ข้อ ๗ (< 10.0 ppm required)');
      expect(res100.errors.any((e) => e.contains('ไฮโดรเจนซัลไฟด์เกินเกณฑ์')), isTrue);

      // 10.1 ppm -> Deadly H2S Poisoning -> MUST FAIL
      final res101 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 10.1,
      );
      expect(res101.isValid, isFalse, reason: 'H2S = 10.1 ppm must fail');
    });

    test('Simultaneous Multi-Parameter Boundary Violations', () {
      // Both O2 deficient (19.4%) and CO toxic (25.0 ppm)
      final multiFail = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 19.4,
        combustiblePercentLel: 10.0,
        carbonMonoxidePpm: 25.0,
        hydrogenSulfidePpm: 10.0,
      );
      expect(multiFail.isValid, isFalse);
      expect(multiFail.errors.length, 4, reason: 'All 4 statutory gas violations must be reported');
    });
  });

  group('M1 Adversarial Challenge: Confined Space Role Validation', () {
    late List<ConfinedRoleModel> baseCompliantRoles;

    setUp(() {
      baseCompliantRoles = [
        ConfinedRoleModel(
          roleAssignmentId: 'CFR-001',
          ptwNumber: 'PTW-2026-ADV-01',
          roleType: ConfinedRoleType.authorizer,
          personName: 'นายประสิทธิ์ ผู้อนุญาต',
          companyName: 'Safety Thai Co.',
          certNumber: 'AUTH-2026-001',
          certInstitute: 'DLPW Institute',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-12-31',
          contactPhone: '0811111111',
          isTrainedAndCertified: true,
        ),
        ConfinedRoleModel(
          roleAssignmentId: 'CFR-002',
          ptwNumber: 'PTW-2026-ADV-01',
          roleType: ConfinedRoleType.supervisor,
          personName: 'นายวิชัย ผู้ควบคุมงาน',
          companyName: 'Safety Thai Co.',
          certNumber: 'SUP-2026-002',
          certInstitute: 'DLPW Institute',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-12-31',
          contactPhone: '0822222222',
          isTrainedAndCertified: true,
        ),
        ConfinedRoleModel(
          roleAssignmentId: 'CFR-003',
          ptwNumber: 'PTW-2026-ADV-01',
          roleType: ConfinedRoleType.attendant,
          personName: 'นายธงชัย ผู้ช่วยเหลือ',
          companyName: 'Safety Thai Co.',
          certNumber: 'ATT-2026-003',
          certInstitute: 'DLPW Institute',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-12-31',
          contactPhone: '0833333333',
          isTrainedAndCertified: true,
        ),
        ConfinedRoleModel(
          roleAssignmentId: 'CFR-004',
          ptwNumber: 'PTW-2026-ADV-01',
          roleType: ConfinedRoleType.entrant,
          personName: 'นายสมบัติ ผู้ปฏิบัติงาน',
          companyName: 'Safety Thai Co.',
          certNumber: 'ENT-2026-004',
          certInstitute: 'DLPW Institute',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-12-31',
          contactPhone: '0844444444',
          isTrainedAndCertified: true,
        ),
      ];
    });

    test('All 4 distinct valid roles pass statutory validation', () {
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(baseCompliantRoles);
      expect(res.isValid, isTrue);
      expect(res.errors, isEmpty);
    });

    test('Missing Authorizer (ข้อ ๙) MUST FAIL', () {
      final roles = baseCompliantRoles.where((r) => r.roleType != ConfinedRoleType.authorizer).toList();
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(roles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ขาดผู้อนุญาต')), isTrue);
    });

    test('Missing Supervisor (ข้อ ๑๐) MUST FAIL', () {
      final roles = baseCompliantRoles.where((r) => r.roleType != ConfinedRoleType.supervisor).toList();
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(roles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ขาดผู้ควบคุมงาน')), isTrue);
    });

    test('Missing Attendant (ข้อ ๑๑) MUST FAIL', () {
      final roles = baseCompliantRoles.where((r) => r.roleType != ConfinedRoleType.attendant).toList();
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(roles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ขาดผู้ช่วยเหลือ')), isTrue);
    });

    test('Missing Entrant (ข้อ ๑๒) MUST FAIL', () {
      final roles = baseCompliantRoles.where((r) => r.roleType != ConfinedRoleType.entrant).toList();
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(roles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ขาดผู้ปฏิบัติงาน')), isTrue);
    });

    test('Expired Training Certificate on any role MUST FAIL', () {
      final expiredRoles = [
        baseCompliantRoles[0],
        baseCompliantRoles[1],
        baseCompliantRoles[2].copyWith(certExpiryDate: '2020-01-01'), // Expired Attendant
        baseCompliantRoles[3],
      ];
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(expiredRoles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ใบประกาศผู้ช่วยเหลือ') && e.contains('หมดอายุ')), isTrue);
    });

    test('Uncertified Role (isTrainedAndCertified = false) MUST FAIL', () {
      final uncertifiedRoles = [
        baseCompliantRoles[0],
        baseCompliantRoles[1],
        baseCompliantRoles[2],
        baseCompliantRoles[3].copyWith(isTrainedAndCertified: false),
      ];
      final res = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(uncertifiedRoles);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ใบประกาศผู้ปฏิบัติงาน')), isTrue);
    });
  });

  group('M1 Adversarial Challenge: Hot Work Fire Watch 30-min Duration & Controls', () {
    late FireWatchModel baseCompliantFw;

    setUp(() {
      baseCompliantFw = FireWatchModel(
        watchId: 'FW-ADV-01',
        ptwNumber: 'PTW-2026-ADV-01',
        fireWatcherName: 'นายเอกชัย ผู้เฝ้าระวังไฟ',
        fireWatcherPhone: '0899999999',
        fireExtinguisherType: 'Dry Chemical 15 lbs 4A-10B',
        fireExtinguisherSerial: 'EXT-HW-01',
        extinguisherInspectedReady: true,
        clearedRadiusMeters: 11.0,
        fireBlanketInstalled: true,
        combustibleMaterialProtected: true,
        sewerCovered: true,
        hotWorkEndTime: '2026-09-01T16:00:00',
        postWorkWatchStartTime: '2026-09-01T16:00:00',
        postWorkWatchEndTime: '2026-09-01T16:30:00',
        postWorkWatchDurationMinutes: 30,
        isPostWorkAreaSafe: true,
      );
    });

    test('Fire Watch Duration Boundary: 29 minutes (FAIL) vs 30 minutes (PASS)', () {
      // 29 Minutes -> Less than statutory 30 min -> MUST FAIL
      final fw29 = baseCompliantFw.copyWith(postWorkWatchDurationMinutes: 29);
      final res29 = PtwSafetyEvaluator.evaluateFireWatch(fw29);
      expect(res29.isValid, isFalse, reason: 'Fire watch of 29 minutes violates statutory 30-min rule');
      expect(res29.errors.any((e) => e.contains('ต้องไม่น้อยกว่า 30 นาที')), isTrue);
      expect(fw29.isCompliantWith30MinRule, isFalse);

      // 30 Minutes -> Exact statutory requirement -> MUST PASS
      final fw30 = baseCompliantFw.copyWith(postWorkWatchDurationMinutes: 30);
      final res30 = PtwSafetyEvaluator.evaluateFireWatch(fw30);
      expect(res30.isValid, isTrue, reason: 'Fire watch of 30 minutes meets statutory requirement');
      expect(fw30.isCompliantWith30MinRule, isTrue);

      // 45 Minutes -> Above minimum -> MUST PASS
      final fw45 = baseCompliantFw.copyWith(postWorkWatchDurationMinutes: 45);
      final res45 = PtwSafetyEvaluator.evaluateFireWatch(fw45);
      expect(res45.isValid, isTrue);
      expect(fw45.isCompliantWith30MinRule, isTrue);
    });

    test('Absent / Uninspected Fire Extinguisher MUST FAIL', () {
      final fwNoExt = baseCompliantFw.copyWith(extinguisherInspectedReady: false);
      final resNoExt = PtwSafetyEvaluator.evaluateFireWatch(fwNoExt);
      expect(resNoExt.isValid, isFalse);
      expect(resNoExt.errors.any((e) => e.contains('เครื่องดับเพลิงยังไม่ได้รับการตรวจสอบ')), isTrue);
    });

    test('Missing Fire Watcher Name MUST FAIL', () {
      final fwNoWatcher = baseCompliantFw.copyWith(fireWatcherName: '   ');
      final resNoWatcher = PtwSafetyEvaluator.evaluateFireWatch(fwNoWatcher);
      expect(resNoWatcher.isValid, isFalse);
      expect(resNoWatcher.errors.any((e) => e.contains('ต้องระบุชื่อผู้เฝ้าระวังไฟ')), isTrue);
    });

    test('Uncleared Combustible Radius (< 11m) without Fire Blanket MUST FAIL', () {
      final fwUnprotected = baseCompliantFw.copyWith(
        clearedRadiusMeters: 8.0,
        fireBlanketInstalled: false,
        combustibleMaterialProtected: false,
      );
      final resUnprotected = PtwSafetyEvaluator.evaluateFireWatch(fwUnprotected);
      expect(resUnprotected.isValid, isFalse);
      expect(resUnprotected.errors.any((e) => e.contains('รัศมีเคลียร์วัสดุติดไฟน้อยกว่า 11')), isTrue);
    });

    test('Post-Work Area Unsafe MUST FAIL', () {
      final fwUnsafeArea = baseCompliantFw.copyWith(isPostWorkAreaSafe: false);
      final resUnsafeArea = PtwSafetyEvaluator.evaluateFireWatch(fwUnsafeArea);
      expect(resUnsafeArea.isValid, isFalse);
      expect(resUnsafeArea.errors.any((e) => e.contains('พื้นที่หลังเลิกงานยังไม่ได้รับการยืนยัน')), isTrue);
    });
  });

  group('M1 Adversarial Challenge: LOTO Energy Isolation & Verification', () {
    late List<LotoIsolationModel> baseCompliantLoto;

    setUp(() {
      baseCompliantLoto = [
        LotoIsolationModel(
          isolationId: 'LOTO-ADV-01',
          ptwNumber: 'PTW-2026-ADV-01',
          equipmentTagNo: 'PUMP-FEED-01',
          equipmentName: 'High Pressure Chemical Feed Pump',
          locationArea: 'Chemical Building 2',
          energyType: EnergyType.electrical,
          isolationMethod: 'BREAKER_LOCKOUT_HASP',
          padlockTagNo: 'PAD-ELEC-401',
          lockAppliedBy: 'นายสมศักดิ์ ช่างไฟฟ้า',
          lockAppliedTimestamp: '2026-09-01T08:00:00',
          zeroEnergyTestMethod: 'Digital Multimeter Calibrated (0.0 V Residual)',
          isZeroEnergyVerified: true,
          verifiedBy: 'นายวิเชียร จป.วิชาชีพ',
          verifiedTimestamp: '2026-09-01T08:15:00',
          isDeIsolated: false,
        ),
        LotoIsolationModel(
          isolationId: 'LOTO-ADV-02',
          ptwNumber: 'PTW-2026-ADV-01',
          equipmentTagNo: 'VALVE-INLET-02',
          equipmentName: 'Inlet High Pressure Valve',
          locationArea: 'Pipe Rack Line 4',
          energyType: EnergyType.hydraulic,
          isolationMethod: 'BLIND_FLANGE_AND_CHAIN',
          padlockTagNo: 'PAD-HYD-502',
          lockAppliedBy: 'นายสมศักดิ์ ช่างกล',
          lockAppliedTimestamp: '2026-09-01T08:10:00',
          zeroEnergyTestMethod: 'Bleed Valve Open Pressure Gauge (0.0 bar)',
          isZeroEnergyVerified: true,
          verifiedBy: 'นายวิเชียร จป.วิชาชีพ',
          verifiedTimestamp: '2026-09-01T08:20:00',
          isDeIsolated: false,
        ),
      ];
    });

    test('Empty LOTO Isolation points for electrical/LOTO work MUST FAIL', () {
      final res = PtwSafetyEvaluator.evaluateLoto([]);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ต้องระบุจุดตัดแยกพลังงาน')), isTrue);
    });

    test('Unverified Zero Energy on any isolation point MUST FAIL', () {
      final unverifiedLoto = [
        baseCompliantLoto[0],
        baseCompliantLoto[1].copyWith(isZeroEnergyVerified: false),
      ];
      final res = PtwSafetyEvaluator.evaluateLoto(unverifiedLoto);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ยังไม่ได้รับการทดสอบพลังงานเป็นศูนย์')), isTrue);
    });

    test('Missing Equipment Tag or Padlock Tag MUST FAIL', () {
      final missingTagLoto = [
        baseCompliantLoto[0].copyWith(equipmentTagNo: '  '),
        baseCompliantLoto[1].copyWith(padlockTagNo: '  '),
      ];
      final res = PtwSafetyEvaluator.evaluateLoto(missingTagLoto);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.contains('ต้องระบุรหัสเครื่องจักร/อุปกรณ์')), isTrue);
      expect(res.errors.any((e) => e.contains('ต้องระบุหมายเลขแม่กุญแจ')), isTrue);
    });

    test('De-isolation check on closure: un-deisolated (FAIL) vs de-isolated (PASS)', () {
      // During work (requireDeIsolation = false) -> MUST PASS even if not de-isolated
      final resActive = PtwSafetyEvaluator.evaluateLoto(baseCompliantLoto, requireDeIsolation: false);
      expect(resActive.isValid, isTrue);

      // During permit closure (requireDeIsolation = true) -> MUST FAIL if any point is still locked
      final resClosureFail = PtwSafetyEvaluator.evaluateLoto(baseCompliantLoto, requireDeIsolation: true);
      expect(resClosureFail.isValid, isFalse);
      expect(resClosureFail.errors.any((e) => e.contains('ยังไม่ได้ทำการปลดล็อกคืนสภาพ')), isTrue);

      // When all points are de-isolated -> MUST PASS closure
      final deIsolatedList = baseCompliantLoto.map((l) => l.copyWith(
        isDeIsolated: true,
        deIsolatedBy: 'นายสมศักดิ์',
        deIsolatedTimestamp: '2026-09-01T17:00:00',
      )).toList();
      final resClosurePass = PtwSafetyEvaluator.evaluateLoto(deIsolatedList, requireDeIsolation: true);
      expect(resClosurePass.isValid, isTrue);
    });
  });

  group('M1 Adversarial Challenge: SQLite v8 Relational Schema & Persistence Stress Test', () {
    late Database testDb;
    late PtwRepository repository;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 8,
        onCreate: (db, version) async {
          // 1. Master Table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_permits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ptw_number TEXT NOT NULL UNIQUE,
              work_title TEXT NOT NULL,
              work_description TEXT NOT NULL,
              primary_risk_type TEXT NOT NULL,
              secondary_risk_types TEXT,
              status TEXT NOT NULL DEFAULT 'DRAFT',
              plant_area TEXT NOT NULL,
              specific_location TEXT NOT NULL,
              request_date TEXT NOT NULL,
              work_start_date TEXT NOT NULL,
              work_start_time TEXT NOT NULL,
              work_end_date TEXT NOT NULL,
              work_end_time TEXT NOT NULL,
              extension_hours INTEGER DEFAULT 0,
              extension_reason TEXT,
              applicant_type TEXT NOT NULL DEFAULT 'INTERNAL_EMPLOYEE',
              applicant_name TEXT NOT NULL,
              applicant_department TEXT NOT NULL,
              applicant_phone TEXT NOT NULL,
              worker_count INTEGER DEFAULT 1,
              worker_names TEXT,
              jsa_reference_no TEXT,
              emergency_rescue_plan TEXT NOT NULL,
              required_ppe_list TEXT NOT NULL,
              special_precautions TEXT,
              applicant_signature_path TEXT,
              applicant_signed_at TEXT,
              safety_officer_signature_path TEXT,
              safety_officer_name TEXT,
              safety_officer_signed_at TEXT,
              authorizer_signature_path TEXT,
              authorizer_name TEXT,
              authorizer_signed_at TEXT,
              handover_signature_path TEXT,
              handover_signed_at TEXT,
              closure_signature_path TEXT,
              closure_signed_at TEXT,
              closure_remarks TEXT,
              site_photo_paths TEXT,
              qr_code_data TEXT,
              official_pdf_path TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // 2. Gas Test Logs
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_gas_test_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              log_id TEXT NOT NULL UNIQUE,
              ptw_number TEXT NOT NULL,
              test_stage TEXT NOT NULL,
              test_timestamp TEXT NOT NULL,
              location_point TEXT NOT NULL,
              oxygen_percent REAL NOT NULL,
              combustible_percent_lel REAL NOT NULL,
              carbon_monoxide_ppm REAL NOT NULL,
              hydrogen_sulfide_ppm REAL NOT NULL,
              toxic_other_ppm REAL,
              toxic_other_name TEXT,
              tester_name TEXT NOT NULL,
              tester_cert_no TEXT,
              detector_model TEXT NOT NULL,
              detector_serial_no TEXT NOT NULL,
              last_calibration_date TEXT NOT NULL,
              is_safe INTEGER NOT NULL DEFAULT 1,
              safety_remarks TEXT,
              signature_path TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');

          // 3. Confined Roles
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_confined_roles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              role_assignment_id TEXT NOT NULL UNIQUE,
              ptw_number TEXT NOT NULL,
              role_type TEXT NOT NULL,
              person_name TEXT NOT NULL,
              national_id TEXT,
              employee_id TEXT,
              company_name TEXT NOT NULL,
              cert_number TEXT NOT NULL,
              cert_institute TEXT NOT NULL,
              cert_issue_date TEXT NOT NULL,
              cert_expiry_date TEXT NOT NULL,
              contact_phone TEXT NOT NULL,
              is_trained_and_certified INTEGER NOT NULL DEFAULT 1,
              signature_path TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');

          // 4. Fire Watches
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_fire_watches (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              watch_id TEXT NOT NULL UNIQUE,
              ptw_number TEXT NOT NULL UNIQUE,
              fire_watcher_name TEXT NOT NULL,
              fire_watcher_phone TEXT NOT NULL,
              fire_extinguisher_type TEXT NOT NULL,
              fire_extinguisher_serial TEXT NOT NULL,
              extinguisher_inspected_ready INTEGER NOT NULL DEFAULT 1,
              cleared_radius_meters REAL NOT NULL DEFAULT 11.0,
              fire_blanket_installed INTEGER NOT NULL DEFAULT 1,
              combustible_material_protected INTEGER NOT NULL DEFAULT 1,
              sewer_covered INTEGER NOT NULL DEFAULT 1,
              hot_work_end_time TEXT NOT NULL,
              post_work_watch_start_time TEXT NOT NULL,
              post_work_watch_end_time TEXT,
              post_work_watch_duration_minutes INTEGER NOT NULL DEFAULT 30,
              is_post_work_area_safe INTEGER NOT NULL DEFAULT 1,
              final_inspector_name TEXT,
              final_inspector_signature TEXT,
              notes TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');

          // 5. LOTO Isolations
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_loto_isolations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              isolation_id TEXT NOT NULL UNIQUE,
              ptw_number TEXT NOT NULL,
              equipment_tag_no TEXT NOT NULL,
              equipment_name TEXT NOT NULL,
              location_area TEXT NOT NULL,
              energy_type TEXT NOT NULL,
              isolation_method TEXT NOT NULL,
              padlock_tag_no TEXT NOT NULL,
              lock_applied_by TEXT NOT NULL,
              lock_applied_timestamp TEXT NOT NULL,
              zero_energy_test_method TEXT NOT NULL,
              is_zero_energy_verified INTEGER NOT NULL DEFAULT 1,
              verified_by TEXT NOT NULL,
              verified_timestamp TEXT,
              is_de_isolated INTEGER NOT NULL DEFAULT 0,
              de_isolated_by TEXT,
              de_isolated_timestamp TEXT,
              notes TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');

          // 6. Checklists
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_checklists (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ptw_number TEXT,
              item_id TEXT NOT NULL,
              risk_type TEXT NOT NULL,
              check_category TEXT NOT NULL,
              question_th TEXT NOT NULL,
              question_en TEXT NOT NULL,
              is_mandatory INTEGER NOT NULL DEFAULT 1,
              result TEXT NOT NULL DEFAULT 'NA',
              remarks TEXT,
              checked_by TEXT,
              checked_at TEXT,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');

          // 7. Approval Logs
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ptw_approval_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              approval_id TEXT NOT NULL UNIQUE,
              ptw_number TEXT NOT NULL,
              approval_stage TEXT NOT NULL,
              approver_role TEXT NOT NULL,
              approver_name TEXT NOT NULL,
              approver_position TEXT,
              action TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              comments TEXT,
              signature_path TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
            )
          ''');
        },
      );
      repository = _AdversarialTestPtwRepository(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Stress Test: Persistence of Complex Multi-Risk Permit with ALL 6 Child Entity Types', () async {
      const complexPtwNo = 'PTW-2026-COMPLEX-999';

      final complexPermit = PtwModel(
        ptwNumber: complexPtwNo,
        workTitle: 'งานซ่อมบำรุงระบบท่อก๊าซและเปลี่ยนมอเตอร์กวนในถังไซโลเคมี',
        workDescription: 'งานที่มีความเสี่ยงทั้ง 5 ด้าน: Confined Space, Hot Work, LOTO, Height, Excavation',
        primaryRiskType: HighRiskType.confinedSpace,
        secondaryRiskTypes: const [
          HighRiskType.hotWork,
          HighRiskType.electricalLoto,
          HighRiskType.workingAtHeight,
          HighRiskType.excavationLifting,
        ],
        status: PtwStatus.active,
        plantArea: 'Complex Chemical Processing Plant A',
        specificLocation: 'Silo Tank #5 and Underground Manhole Pipe Tunnel',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '17:00',
        extensionHours: 3,
        extensionReason: 'งานเชื่อมท่อภายในถังต้องใช้เวลาตรวจสอบ X-Ray รอยเชื่อม',
        applicantType: 'MAIN_CONTRACTOR',
        applicantName: 'นายช่างใหญ่ ผู้รับเหมา',
        applicantDepartment: 'Heavy Industrial Maintenance Division',
        applicantPhone: '089-999-8888',
        workerCount: 6,
        workerNames: const ['สมชาย', 'สมศักดิ์', 'วิชัย', 'ประเสริฐ', 'ดำรง', 'อนุชา'],
        jsaReferenceNo: 'JSA-2026-SILO-COMPLEX-01',
        emergencyRescuePlan: 'ทีมกู้ภัยฉุกเฉินระดับ 2 ประจำการพร้อม SCBA และ Tripod Winch เบอร์ 1999',
        requiredPpeList: 'Full Body Harness with Shock Absorber, SCBA, Flame-Resistant Suit, Gas Detector',
        specialPrecautions: 'ต่อสายดินป้องกันไฟฟ้าสถิต และเปิดเครื่องดูดอากาศแบบ Explosion-Proof ตลอดเวลา',
        applicantSignaturePath: '/data/signatures/app_001.png',
        applicantSignedAt: '2026-09-01T07:15:00',
        safetyOfficerSignaturePath: '/data/signatures/so_001.png',
        safetyOfficerName: 'นายวิเชียร จป.วิชาชีพ',
        safetyOfficerSignedAt: '2026-09-01T07:30:00',
        authorizerSignaturePath: '/data/signatures/auth_001.png',
        authorizerName: 'นายสมศักดิ์ ผู้จัดการโรงงาน/ผู้อนุญาต',
        authorizerSignedAt: '2026-09-01T07:45:00',
        gasTestLogs: [
          GasTestLogModel(
            logId: 'GAS-CMP-01',
            ptwNumber: complexPtwNo,
            testStage: 'PRE_ENTRY',
            testTimestamp: '2026-09-01T07:35:00',
            locationPoint: 'Manhole Entrance Top',
            oxygenPercent: 20.9,
            combustiblePercentLel: 0.0,
            carbonMonoxidePpm: 1.0,
            hydrogenSulfidePpm: 0.0,
            testerName: 'นายวิเชียร จป.วิชาชีพ',
            detectorModel: 'Dräger X-am 8000',
            detectorSerialNo: 'DR8-99881',
            lastCalibrationDate: '2026-08-15',
            isSafe: true,
          ),
          GasTestLogModel(
            logId: 'GAS-CMP-02',
            ptwNumber: complexPtwNo,
            testStage: 'CONTINUOUS',
            testTimestamp: '2026-09-01T10:00:00',
            locationPoint: 'Silo Tank Bottom Floor',
            oxygenPercent: 20.8,
            combustiblePercentLel: 1.2,
            carbonMonoxidePpm: 3.5,
            hydrogenSulfidePpm: 0.5,
            testerName: 'นายวิเชียร จป.วิชาชีพ',
            detectorModel: 'Dräger X-am 8000',
            detectorSerialNo: 'DR8-99881',
            lastCalibrationDate: '2026-08-15',
            isSafe: true,
          ),
        ],
        confinedRoles: [
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-CMP-01',
            ptwNumber: complexPtwNo,
            roleType: ConfinedRoleType.authorizer,
            personName: 'นายสมศักดิ์ ผู้จัดการโรงงาน',
            companyName: 'Chemical Plant Co.',
            certNumber: 'AUTH-DLPW-2026-01',
            certInstitute: 'Safety Training Institute Bangkok',
            certIssueDate: '2026-01-10',
            certExpiryDate: '2028-01-10',
            contactPhone: '081-111-2222',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-CMP-02',
            ptwNumber: complexPtwNo,
            roleType: ConfinedRoleType.supervisor,
            personName: 'นายวิชัย วิศวกรควบคุมงาน',
            companyName: 'Heavy Maintenance Co.',
            certNumber: 'SUP-DLPW-2026-02',
            certInstitute: 'Safety Training Institute Bangkok',
            certIssueDate: '2026-01-10',
            certExpiryDate: '2028-01-10',
            contactPhone: '082-222-3333',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-CMP-03',
            ptwNumber: complexPtwNo,
            roleType: ConfinedRoleType.attendant,
            personName: 'นายธงชัย ผู้เฝ้าระวังปากทางเข้า',
            companyName: 'Heavy Maintenance Co.',
            certNumber: 'ATT-DLPW-2026-03',
            certInstitute: 'Safety Training Institute Bangkok',
            certIssueDate: '2026-01-10',
            certExpiryDate: '2028-01-10',
            contactPhone: '083-333-4444',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-CMP-04',
            ptwNumber: complexPtwNo,
            roleType: ConfinedRoleType.entrant,
            personName: 'นายดำรง ช่างเชื่อมในที่อับอากาศ',
            companyName: 'Heavy Maintenance Co.',
            certNumber: 'ENT-DLPW-2026-04',
            certInstitute: 'Safety Training Institute Bangkok',
            certIssueDate: '2026-01-10',
            certExpiryDate: '2028-01-10',
            contactPhone: '084-444-5555',
          ),
        ],
        fireWatch: FireWatchModel(
          watchId: 'FW-CMP-01',
          ptwNumber: complexPtwNo,
          fireWatcherName: 'นายอนุชา ผู้เฝ้าระวังประกายไฟ',
          fireWatcherPhone: '085-555-6666',
          fireExtinguisherType: 'CO2 15 lbs and Foam AFFF 50 Liters',
          fireExtinguisherSerial: 'EXT-FOAM-99',
          extinguisherInspectedReady: true,
          clearedRadiusMeters: 15.0,
          fireBlanketInstalled: true,
          combustibleMaterialProtected: true,
          sewerCovered: true,
          hotWorkEndTime: '2026-09-01T16:00:00',
          postWorkWatchStartTime: '2026-09-01T16:00:00',
          postWorkWatchEndTime: '2026-09-01T16:45:00',
          postWorkWatchDurationMinutes: 45,
          isPostWorkAreaSafe: true,
        ),
        lotoIsolations: [
          LotoIsolationModel(
            isolationId: 'LOTO-CMP-01',
            ptwNumber: complexPtwNo,
            equipmentTagNo: 'AGITATOR-MTR-05',
            equipmentName: 'Silo Agitator Motor 400V 75kW',
            locationArea: 'Substation MCC Panel 3',
            energyType: EnergyType.electrical,
            isolationMethod: 'MCC_BREAKER_PADLOCK_HASP',
            padlockTagNo: 'LOCK-ELEC-881',
            lockAppliedBy: 'นายสมศักดิ์ ช่างไฟฟ้า',
            lockAppliedTimestamp: '2026-09-01T07:20:00',
            zeroEnergyTestMethod: 'Digital Multimeter Calibrated 0.0V Phase-to-Phase and Phase-to-Ground',
            isZeroEnergyVerified: true,
            verifiedBy: 'นายวิเชียร จป.วิชาชีพ',
            verifiedTimestamp: '2026-09-01T07:30:00',
            isDeIsolated: false,
          ),
          LotoIsolationModel(
            isolationId: 'LOTO-CMP-02',
            ptwNumber: complexPtwNo,
            equipmentTagNo: 'VALVE-CHEM-LINE-05',
            equipmentName: 'Acid Feed Line Valve',
            locationArea: 'Pipe Rack Level 2',
            energyType: EnergyType.chemical,
            isolationMethod: 'BLIND_FLANGE_AND_LOCKED_VALVE',
            padlockTagNo: 'LOCK-CHEM-882',
            lockAppliedBy: 'นายประเสริฐ ช่างกล',
            lockAppliedTimestamp: '2026-09-01T07:25:00',
            zeroEnergyTestMethod: 'Bleed Valve 0 bar and Flush Verification',
            isZeroEnergyVerified: true,
            verifiedBy: 'นายวิเชียร จป.วิชาชีพ',
            verifiedTimestamp: '2026-09-01T07:32:00',
            isDeIsolated: false,
          ),
        ],
        checklistItems: [
          PtwChecklistModel(
            itemId: 'CHK-CMP-01',
            ptwNumber: complexPtwNo,
            riskType: HighRiskType.confinedSpace,
            checkCategory: 'GAS_VENTILATION',
            questionTh: 'ติดตั้งพัดลมระบายอากาศแบบ Explosion-Proof',
            questionEn: 'Install explosion-proof ventilation blower',
            isMandatory: true,
            result: 'YES',
          ),
          PtwChecklistModel(
            itemId: 'CHK-CMP-02',
            ptwNumber: complexPtwNo,
            riskType: HighRiskType.hotWork,
            checkCategory: 'FIRE_PROTECTION',
            questionTh: 'จัดเตรียมถังดับเพลิงและผ้ากันไฟคลุมรัศมี 11 เมตร',
            questionEn: 'Prepare fire extinguisher and fire blanket',
            isMandatory: true,
            result: 'YES',
          ),
        ],
        approvalLogs: [
          PtwApprovalModel(
            approvalId: 'APR-CMP-01',
            ptwNumber: complexPtwNo,
            approvalStage: 'PENDING_APPROVAL',
            approverRole: 'APPLICANT',
            approverName: 'นายช่างใหญ่ ผู้รับเหมา',
            action: 'SUBMIT',
            timestamp: '2026-09-01T07:15:00',
            comments: 'ส่งคำขอใบอนุญาตทำงานความเสี่ยงสูง',
          ),
          PtwApprovalModel(
            approvalId: 'APR-CMP-02',
            ptwNumber: complexPtwNo,
            approvalStage: 'ACTIVE',
            approverRole: 'AUTHORIZER',
            approverName: 'นายสมศักดิ์ ผู้จัดการโรงงาน',
            action: 'APPROVE',
            timestamp: '2026-09-01T07:45:00',
            comments: 'อนุมัติเปิดงานหลังตรวจเช็กหน้างานเรียบร้อย',
          ),
        ],
      );

      // 1. Save complex permit to SQLite
      final savedPermit = await repository.savePermit(complexPermit);
      expect(savedPermit.id, isNotNull);

      // 2. Fetch permit back and verify all 6 child entity types are perfectly hydrated
      final fetched = await repository.getPermitByNumber(complexPtwNo);
      expect(fetched, isNotNull);
      expect(fetched!.ptwNumber, complexPtwNo);
      expect(fetched.secondaryRiskTypes.length, 4);
      expect(fetched.gasTestLogs.length, 2);
      expect(fetched.confinedRoles.length, 4);
      expect(fetched.fireWatch, isNotNull);
      expect(fetched.fireWatch!.fireWatcherName, 'นายอนุชา ผู้เฝ้าระวังประกายไฟ');
      expect(fetched.fireWatch!.postWorkWatchDurationMinutes, 45);
      expect(fetched.lotoIsolations.length, 2);
      expect(fetched.checklistItems.length, 2);
      expect(fetched.approvalLogs.length, 2);

      // 3. Test adding additional continuous gas log
      final gasLog3 = GasTestLogModel(
        logId: 'GAS-CMP-03',
        ptwNumber: complexPtwNo,
        testStage: 'CONTINUOUS',
        testTimestamp: '2026-09-01T14:00:00',
        locationPoint: 'Silo Tank Middle Level',
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 2.0,
        hydrogenSulfidePpm: 0.0,
        testerName: 'นายวิเชียร จป.วิชาชีพ',
        detectorModel: 'Dräger X-am 8000',
        detectorSerialNo: 'DR8-99881',
        lastCalibrationDate: '2026-08-15',
        isSafe: true,
      );
      await repository.addGasTestLog(complexPtwNo, gasLog3);

      final updatedGasLogs = await repository.getGasTestLogs(complexPtwNo);
      expect(updatedGasLogs.length, 3);

      // 4. Test updating status and adding approval log
      await repository.updatePermitStatus(
        complexPtwNo,
        PtwStatus.extendedHandover,
        approverName: 'นายสมศักดิ์ ผู้จัดการโรงงาน',
        comments: 'อนุมัติการต่อเวลาทำงาน 3 ชั่วโมง',
      );

      final extendedPermit = await repository.getPermitByNumber(complexPtwNo);
      expect(extendedPermit!.status, PtwStatus.extendedHandover);
      expect(extendedPermit.approvalLogs.length, 3);

      // 5. Test cascading deletion: deleting master permit removes all child entities
      final deleteCount = await repository.deletePermit(complexPtwNo);
      expect(deleteCount, 1);

      final afterDelete = await repository.getPermitByNumber(complexPtwNo);
      expect(afterDelete, isNull);

      final orphanedGas = await repository.getGasTestLogs(complexPtwNo);
      expect(orphanedGas, isEmpty, reason: 'Child gas logs must be deleted via cascade');
    });

    test('Stress Test: High-Volume Concurrent PTW Insertion and Filter Aggregation', () async {
      // Insert 25 permits across different high risk types and statuses
      for (int i = 1; i <= 25; i++) {
        final risk = HighRiskType.values[i % HighRiskType.values.length];
        final status = PtwStatus.values[i % PtwStatus.values.length];
        final ptwNo = 'PTW-STRESS-${i.toString().padLeft(3, '0')}';

        await repository.savePermit(PtwModel(
          ptwNumber: ptwNo,
          workTitle: 'Stress Test Permit #$i for ${risk.toDbCode()}',
          workDescription: 'Automated Stress Batch',
          primaryRiskType: risk,
          status: status,
          plantArea: 'Plant Area ${(i % 3) + 1}',
          specificLocation: 'Zone #$i',
          requestDate: '2026-09-01',
          workStartDate: '2026-09-01',
          workStartTime: '08:00',
          workEndDate: '2026-09-01',
          workEndTime: '17:00',
          applicantName: 'Applicant #$i',
          applicantDepartment: 'Maintenance',
          applicantPhone: '0812345678',
          emergencyRescuePlan: 'Plan 1999',
          requiredPpeList: 'Standard PPE',
        ));
      }

      // Query all permits
      final allPermits = await repository.getAllPermits();
      expect(allPermits.length, 25);

      // Query by status
      final activePermits = await repository.getAllPermits(statusFilter: PtwStatus.active);
      expect(activePermits.every((p) => p.status == PtwStatus.active), isTrue);

      // Query by primary risk
      final hotWorkPermits = await repository.getAllPermits(riskTypeFilter: HighRiskType.hotWork);
      expect(hotWorkPermits.every((p) => p.primaryRiskType == HighRiskType.hotWork), isTrue);

      // Verify KPI calculation aggregates all 25 correctly
      final kpi = await repository.getKpiSummary();
      expect(kpi.totalPermits, 25);
      expect(kpi.activeCount + kpi.pendingCount + kpi.draftCount + kpi.extendedCount + kpi.closedCount, 25);
    });
  });
}
