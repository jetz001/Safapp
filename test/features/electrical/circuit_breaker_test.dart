import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/electrical/data/models/circuit_breaker_model.dart';

void main() {
  group('CircuitBreakerModel and LOTO Unit Tests', () {
    test('CircuitBreakerModel toMap and fromMap serialization roundtrip', () {
      final breaker = CircuitBreakerModel(
        id: 1,
        equipmentTag: 'MDB-01-ACB',
        equipmentName: 'ตู้สวิตช์บอร์ดหลัก อาคารผลิต 1',
        locationBuilding: 'อาคารผลิต 1',
        locationFloor: 'ชั้น 1 ห้อง MDB',
        breakerType: 'ACB',
        ratedCurrentAmp: 1600.0,
        voltageLevel: 'LOW_VOLTAGE',
        upstreamSource: 'หม้อแปลง TR-01 (1,000 kVA)',
        isLocked: true,
        lockoutTagNo: 'LOTO-MDB-2026-001',
        lockedBy: 'สมชาย ช่างไฟ',
        lockedAt: '2026-09-09T10:30:00',
        zeroEnergyVerified: true,
        authorizedOperator: 'วิศวกรไฟฟ้า สถ.1234',
        singleLineDiagramRef: 'SLD-PLANT-01 Rev.D',
        notes: 'ปิดซ่อมบำรุงประจำปี',
        createdAt: '2026-09-01T00:00:00',
        updatedAt: '2026-09-09T00:00:00',
      );

      final map = breaker.toMap();
      expect(map['equipment_tag'], 'MDB-01-ACB');
      expect(map['is_locked'], 1);
      expect(map['zero_energy_verified'], 1);
      expect(map['rated_current_amp'], 1600.0);

      final restored = CircuitBreakerModel.fromMap(map);
      expect(restored.id, breaker.id);
      expect(restored.equipmentTag, breaker.equipmentTag);
      expect(restored.isLocked, isTrue);
      expect(restored.lockoutTagNo, 'LOTO-MDB-2026-001');
      expect(restored.lockedBy, 'สมชาย ช่างไฟ');
      expect(restored.zeroEnergyVerified, isTrue);
      expect(restored.upstreamSource, breaker.upstreamSource);
      expect(restored.voltageLevel, 'LOW_VOLTAGE');
    });

    test('LOTO Lock transition sets lock tags, operator, and timestamp', () {
      final normalBreaker = CircuitBreakerModel(
        id: 2,
        equipmentTag: 'MCCB-PUMP-02',
        equipmentName: 'เบรกเกอร์ปั๊มน้ำหล่อเย็น',
        locationBuilding: 'อาคาร Utility',
        breakerType: 'MCCB',
        isLocked: false,
      );

      expect(normalBreaker.isLocked, isFalse);
      expect(normalBreaker.lockoutTagNo, isNull);

      final lockTimeStr = DateTime.now().toIso8601String();
      final lockedBreaker = normalBreaker.copyWith(
        isLocked: true,
        lockoutTagNo: 'TAG-PUMP-002',
        lockedBy: 'กิตติพงษ์ จป.วิชาชีพ',
        lockedAt: lockTimeStr,
        zeroEnergyVerified: true,
      );

      expect(lockedBreaker.isLocked, isTrue);
      expect(lockedBreaker.lockoutTagNo, 'TAG-PUMP-002');
      expect(lockedBreaker.lockedBy, 'กิตติพงษ์ จป.วิชาชีพ');
      expect(lockedBreaker.zeroEnergyVerified, isTrue);
      expect(lockedBreaker.lockedAt, lockTimeStr);

      final unlockedBreaker = lockedBreaker.copyWith(
        isLocked: false,
        lockoutTagNo: null,
        lockedBy: null,
        lockedAt: null,
        zeroEnergyVerified: false,
      );

      expect(unlockedBreaker.isLocked, isFalse);
      expect(unlockedBreaker.zeroEnergyVerified, isFalse);
    });

    test('High Voltage Breaker detection and safety criteria', () {
      final hvBreaker = CircuitBreakerModel(
        equipmentTag: 'VCB-RMU-22KV',
        equipmentName: 'Ring Main Unit 22 kV',
        locationBuilding: 'สถานีย่อย Substation',
        breakerType: 'VCB',
        voltageLevel: 'HIGH_VOLTAGE',
        ratedCurrentAmp: 630.0,
      );

      expect(hvBreaker.voltageLevel, 'HIGH_VOLTAGE');
      expect(hvBreaker.isLocked, isFalse);
    });
  });
}
