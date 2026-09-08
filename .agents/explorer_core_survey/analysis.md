# PTW Core & Models Architectural Analysis & Survey Report

**Agent**: Explorer 1 (Core & Models Specialist)  
**Date**: 2026-09-01  
**Target Workspace**: `d:\DEV\SAFAPP`  
**Working Directory**: `d:\DEV\SAFAPP\.agents\explorer_core_survey`

---

## 1. Executive Summary

This survey analyzes the existing SAFAPP codebase (`d:\DEV\SAFAPP\lib`), examines architectural conventions, database structures, state management patterns, and statutory mandates from the Royal Thai Government Gazette (ราชกิจจานุเบกษา) to design a rock-solid, production-grade **Permit to Work (PTW) High-Risk Work Safety System**.

### Key Findings & Recommendations Overview:
1. **State Management**: Standardized on `flutter_riverpod: ^3.3.2` using `NotifierProvider` for synchronous UI filters/tabs and `AsyncNotifierProvider` for reactive CRUD, validation, and auto-invalidation.
2. **Persistence Architecture**: SQLite via `sqflite_common_ffi: ^2.4.0+3` with Database version bump from 7 to 8, establishing dedicated relational tables for `ptw_permits`, `ptw_gas_test_logs`, `ptw_confined_roles`, `ptw_loto_isolations`, and `ptw_checklists`.
3. **Legal Compliance**: Full codification of:
   - พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ (ม.๘, ๑๔, ๑๖, ๒๒, ๒๓, ๓๒)
   - กฎกระทรวงที่อับอากาศ ๒๕๖๒ (ข้อ ๔, ๕, ๖, ๗, ๙-๑๒, ๑๓, ๑๗-๑๘)
   - กฎกระทรวงอัคคีภัย ๒๕๕๕ (Hot Work & 30-min Fire Watch)
   - กฎกระทรวงไฟฟ้า ๒๕๕๘ (LOTO & Zero-Energy Verification)
   - กฎกระทรวงงานบนที่สูงและงานดินขุด ๒๕๖๔ (Height $\ge 2\text{ m}$, Trench $\ge 1.5\text{ m}$)
   - ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบหนังสืออนุญาตทำงานในที่อับอากาศ
4. **Data Modeling**: Complete specification of Dart immutable domain models, enums with database serialization (`toDbCode()`, `fromDbCode()`, `labelTh`, badge styling), mathematical validation algorithms, and JSON serializers.

---

## 2. Existing Codebase Analysis & Conventions

### 2.1 State Management Patterns
In `d:\DEV\SAFAPP\lib\features\environment` and `chemicals`:
- **Providers Architecture**: Riverpod 3 notifier pattern without code-gen overhead for maximum reliability and testability.
- **UI State Notifiers**: `Notifier<T>` used for filter state (e.g. `PtwRiskFilterNotifier`, `PtwStatusFilterNotifier`, `PtwSearchQueryNotifier`, `PtwSelectedTabNotifier`).
- **Async Data Notifiers**: `AsyncNotifier<List<PtwModel>>` encapsulates fetching from SQLite repository, optimistic/async CRUD updates, and cascade cache invalidation (`ref.invalidateSelf()`, `ref.invalidate(ptwKpiSummaryProvider)`).
- **Repository Injection**: `Provider<PtwRepository>((ref) => PtwRepository(dbHelper: DatabaseHelper()))`.

### 2.2 Persistence & Database Architecture
- **Database Engine**: `sqflite_common_ffi` with desktop compatibility (`sqfliteFfiInit()`).
- **File System Storage**: Stored in `getApplicationDocumentsDirectory() / SafetySuperapp / safety_superapp_v1.db`.
- **Database Migration**: `DatabaseHelper` currently on Version 7.
  - Upgrade path to **Version 8**: Add `_createPtwTables(db)` in `_onCreate`, `_onUpgrade (oldVersion < 8)`, and `_onOpen`.
- **Attachments & Digital Signatures**: Raw image/signature PNG files stored in dedicated application directory `SafetySuperapp/ptw/signatures/` and `SafetySuperapp/ptw/attachments/` with absolute or relative paths saved in SQLite.

### 2.3 Existing Modules & Code Structure
SAFAPP uses a feature-first modular Clean Architecture:
```
lib/
├── core/
│   ├── database/database_helper.dart      # SQLite schema, versioning, migrations
│   ├── providers/database_provider.dart   # Riverpod DB instance provider
│   └── widgets/glass_container.dart       # Core Glassmorphic UI styling
└── features/
    └── ptw/
        ├── data/
        │   ├── datasources/ptw_statutory_master_data.dart # Seed checklists & laws
        │   └── repositories/ptw_repository.dart           # SQLite CRUD & Queries
        ├── domain/
        │   ├── models/
        │   │   ├── ptw_enums.dart                         # HighRiskType, PtwStatus, etc.
        │   │   ├── ptw_model.dart                         # Master PTW entity
        │   │   ├── gas_test_log_model.dart                # Confined space gas monitoring
        │   │   ├── confined_role_model.dart               # 4-role registration
        │   │   ├── fire_watch_model.dart                  # Hot work 30-min fire watch
        │   │   ├── loto_isolation_model.dart              # LOTO energy isolation
        │   │   ├── ptw_checklist_model.dart               # Pre-work safety checks
        │   │   └── ptw_kpi_summary_model.dart             # Dashboard metrics
        │   └── services/
        │       ├── ptw_safety_evaluator.dart              # Statutory rules engine
        │       └── ptw_state_machine.dart                 # Workflow transitions
        ├── presentation/
        │   ├── pages/ptw_page.dart                        # Main 4-Tab Screen
        │   ├── providers/ptw_providers.dart               # Riverpod State Notifiers
        │   ├── tabs/
        │   │   ├── ptw_dashboard_tab.dart                 # KPI & PTW Register
        │   │   ├── ptw_wizard_tab.dart                    # Multi-step Create/Edit Wizard
        │   │   ├── ptw_live_controls_tab.dart             # Live Gas & Fire Watch Site Tools
        │   │   └── ptw_legal_library_tab.dart             # Thai Royal Gazette Previewer
        │   └── widgets/
        │       ├── digital_signature_pad_dialog.dart      # Canvas Signature Capture
        │       ├── gas_test_gauge_widget.dart             # Realtime O2/LEL/CO/H2S status
        │       ├── fire_watch_countdown_widget.dart       # 30-Minute Live Timer
        │       └── ptw_status_badge.dart                  # Color-coded status chip
        └── services/
            ├── ptw_official_pdf_service.dart              # DLPW Form + QR Code PDF
            └── ptw_excel_export_service.dart              # PTW Summary Excel Report
```

---

## 3. Detailed Data Models & Enums Specification

### 3.1 Enums

#### `HighRiskType` (5 Core High-Risk Work Types)
```dart
enum HighRiskType {
  hotWork,            // งานประกายไฟ/ความร้อน (เชื่อม, ตัด, เจียร, พ่นทราย)
  confinedSpace,      // งานในที่อับอากาศ (ถัง, ไซโล, บ่อพัก, ท่อ, ห้องใต้ดิน)
  workingAtHeight,    // งานบนที่สูง (เกิน 2 เมตร, นั่งร้าน, หลังคา, กระเช้า)
  electricalLoto,     // งานไฟฟ้าและการตัดแยกพลังงาน (แรงดันสูง/ต่ำ, LOTO)
  excavationLifting;  // งานขุดเจาะและยกเคลื่อนย้าย (ขุดลึก > 1.5 ม., ปั้นจั่น, เครน)

  String toDbCode() {
    switch (this) {
      case HighRiskType.hotWork: return 'HOT_WORK';
      case HighRiskType.confinedSpace: return 'CONFINED_SPACE';
      case HighRiskType.workingAtHeight: return 'WORKING_AT_HEIGHT';
      case HighRiskType.electricalLoto: return 'ELECTRICAL_LOTO';
      case HighRiskType.excavationLifting: return 'EXCAVATION_LIFTING';
    }
  }

  static HighRiskType fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'HOT_WORK': return HighRiskType.hotWork;
      case 'CONFINED_SPACE': return HighRiskType.confinedSpace;
      case 'WORKING_AT_HEIGHT': return HighRiskType.workingAtHeight;
      case 'ELECTRICAL_LOTO': return HighRiskType.electricalLoto;
      case 'EXCAVATION_LIFTING': return HighRiskType.excavationLifting;
      default: return HighRiskType.hotWork;
    }
  }

  String get labelTh {
    switch (this) {
      case HighRiskType.hotWork: return 'งานประกายไฟ/ความร้อน (Hot Work)';
      case HighRiskType.confinedSpace: return 'งานในที่อับอากาศ (Confined Space)';
      case HighRiskType.workingAtHeight: return 'งานบนที่สูง (Working at Height)';
      case HighRiskType.electricalLoto: return 'งานไฟฟ้าและตัดแยกพลังงาน (Electrical & LOTO)';
      case HighRiskType.excavationLifting: return 'งานขุดเจาะและยกย้าย (Excavation & Lifting)';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case HighRiskType.hotWork: return 'Hot Work';
      case HighRiskType.confinedSpace: return 'ที่อับอากาศ';
      case HighRiskType.workingAtHeight: return 'งานบนที่สูง';
      case HighRiskType.electricalLoto: return 'ไฟฟ้า & LOTO';
      case HighRiskType.excavationLifting: return 'ขุดเจาะ/ยกย้าย';
    }
  }

  IconData get icon {
    switch (this) {
      case HighRiskType.hotWork: return Icons.local_fire_department;
      case HighRiskType.confinedSpace: return Icons.sensor_door;
      case HighRiskType.workingAtHeight: return Icons.height;
      case HighRiskType.electricalLoto: return Icons.bolt;
      case HighRiskType.excavationLifting: return Icons.construction;
    }
  }

  Color get color {
    switch (this) {
      case HighRiskType.hotWork: return const Color(0xFFEF4444); // Red
      case HighRiskType.confinedSpace: return const Color(0xFF8B5CF6); // Purple
      case HighRiskType.workingAtHeight: return const Color(0xFF3B82F6); // Blue
      case HighRiskType.electricalLoto: return const Color(0xFFF59E0B); // Amber
      case HighRiskType.excavationLifting: return const Color(0xFF10B981); // Emerald
    }
  }
}
```

#### `PtwStatus` (5-Stage Approval & Lifecycle Workflow)
```dart
enum PtwStatus {
  draft,             // 1. ร่างคำขอ (ผู้ขอ/หัวหน้างาน/ผู้รับเหมา)
  pendingApproval,   // 2. รอตรวจสอบ JSA และอนุมัติ (จป.วิชาชีพ / ผู้อนุญาต)
  active,            // 3. เปิดงาน/กำลังปฏิบัติงาน (มีผลบังคับใช้ตามช่วงเวลา)
  extendedHandover,  // 4. ต่อเวลา / ส่งมอบงานระหว่างกะ
  closedCancelled;   // 5. ปิดงานสมบูรณ์ / ยกเลิก

  String toDbCode() {
    switch (this) {
      case PtwStatus.draft: return 'DRAFT';
      case PtwStatus.pendingApproval: return 'PENDING_APPROVAL';
      case PtwStatus.active: return 'ACTIVE';
      case PtwStatus.extendedHandover: return 'EXTENDED_HANDOVER';
      case PtwStatus.closedCancelled: return 'CLOSED_CANCELLED';
    }
  }

  static PtwStatus fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'DRAFT': return PtwStatus.draft;
      case 'PENDING_APPROVAL':
      case 'PENDING': return PtwStatus.pendingApproval;
      case 'ACTIVE':
      case 'APPROVED': return PtwStatus.active;
      case 'EXTENDED_HANDOVER':
      case 'EXTENDED': return PtwStatus.extendedHandover;
      case 'CLOSED_CANCELLED':
      case 'CLOSED':
      case 'CANCELLED': return PtwStatus.closedCancelled;
      default: return PtwStatus.draft;
    }
  }

  String get labelTh {
    switch (this) {
      case PtwStatus.draft: return 'ร่างคำขอ (Draft)';
      case PtwStatus.pendingApproval: return 'รออนุมัติ (Pending Approval)';
      case PtwStatus.active: return 'กำลังปฏิบัติงาน (Active)';
      case PtwStatus.extendedHandover: return 'ต่อเวลา/ส่งมอบกะ (Extended/Handover)';
      case PtwStatus.closedCancelled: return 'ปิดงาน/ยกเลิก (Closed/Cancelled)';
    }
  }

  Color get badgeColor {
    switch (this) {
      case PtwStatus.draft: return const Color(0xFF6B7280); // Gray
      case PtwStatus.pendingApproval: return const Color(0xFFF59E0B); // Amber
      case PtwStatus.active: return const Color(0xFF10B981); // Green
      case PtwStatus.extendedHandover: return const Color(0xFF3B82F6); // Blue
      case PtwStatus.closedCancelled: return const Color(0xFF4B5563); // Dark Gray
    }
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case PtwStatus.draft: return const Color(0xFFF3F4F6);
      case PtwStatus.pendingApproval: return const Color(0xFFFFFBEB);
      case PtwStatus.active: return const Color(0xFFECFDF5);
      case PtwStatus.extendedHandover: return const Color(0xFFEFF6FF);
      case PtwStatus.closedCancelled: return const Color(0xFFF3F4F6);
    }
  }
}
```

---

### 3.2 Gas Testing Model (`GasTestLogModel`)

#### Statutory Thresholds (กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๗):
- **Oxygen ($O_2$)**: $19.5\% \le O_2 \le 23.5\%$ (Optimal: $20.9\%$)
- **Flammable Gas ($LEL$)**: $< 10\%$ Lower Explosive Limit
- **Carbon Monoxide ($CO$)**: $< 25\text{ ppm}$
- **Hydrogen Sulfide ($H_2S$)**: $< 10\text{ ppm}$

```dart
class GasTestLogModel {
  final int? id;
  final String logId;               // e.g. "GAS-PTW-2026-001-01"
  final String ptwNumber;           // Reference to PtwModel.ptwNumber
  final String testStage;           // 'PRE_ENTRY', 'CONTINUOUS', 'POST_WORK'
  final String testTimestamp;       // ISO 8601 String e.g. "2026-09-01T08:30:00"
  final String locationPoint;       // e.g. "ก้นถังไซโล จุดตรวจที่ 1 (ระดับลึก 3 เมตร)"
  final double oxygenPercent;       // O2 (%) - standard: 19.5 - 23.5%
  final double combustiblePercentLel; // LEL (%) - standard: < 10%
  final double carbonMonoxidePpm;   // CO (ppm) - standard: < 25 ppm
  final double hydrogenSulfidePpm;  // H2S (ppm) - standard: < 10 ppm
  final double? toxicOtherPpm;      // Other toxic gases (optional)
  final String? toxicOtherName;     // Name of other gas e.g. "NH3", "SO2"
  final String testerName;          // ชื่อผู้ตรวจวัด
  final String? testerCertNo;       // เลขที่ใบรับรองผู้ตรวจวัดบรรยากาศ
  final String detectorModel;       // ยี่ห้อ/รุ่นเครื่องตรวจวัด e.g. "Dräger X-am 5000"
  final String detectorSerialNo;    // หมายเลขเครื่องตรวจวัด
  final String lastCalibrationDate; // วันที่สอบเทียบล่าสุด (YYYY-MM-DD)
  final bool isSafe;                // Evaluated result
  final String? safetyRemarks;      // หมายเหตุ/คำเตือน
  final String? signaturePath;      // ลายเซ็นผู้ตรวจวัด

  const GasTestLogModel({
    this.id,
    required this.logId,
    required this.ptwNumber,
    required this.testStage,
    required this.testTimestamp,
    required this.locationPoint,
    required this.oxygenPercent,
    required this.combustiblePercentLel,
    required this.carbonMonoxidePpm,
    required this.hydrogenSulfidePpm,
    this.toxicOtherPpm,
    this.toxicOtherName,
    required this.testerName,
    this.testerCertNo,
    required this.detectorModel,
    required this.detectorSerialNo,
    required this.lastCalibrationDate,
    required this.isSafe,
    this.safetyRemarks,
    this.signaturePath,
  });

  // Statutory Validation Rule
  static bool evaluateSafety({
    required double o2,
    required double lel,
    required double co,
    required double h2s,
    double? otherToxic,
    double otherToxicLimit = 0.0,
  }) {
    final bool o2Safe = (o2 >= 19.5 && o2 <= 23.5);
    final bool lelSafe = (lel < 10.0);
    final bool coSafe = (co < 25.0);
    final bool h2sSafe = (h2s < 10.0);
    final bool otherSafe = (otherToxic == null || otherToxicLimit <= 0.0 || otherToxic < otherToxicLimit);
    return o2Safe && lelSafe && coSafe && h2sSafe && otherSafe;
  }

  List<String> get hazardWarnings {
    final List<String> warnings = [];
    if (oxygenPercent < 19.5) {
      warnings.add('ออกซิเจนต่ำเกินไป (${oxygenPercent.toStringAsFixed(1)}% < 19.5%): เสี่ยงหมดสติ/ขาดอากาศหายใจ');
    } else if (oxygenPercent > 23.5) {
      warnings.add('ออกซิเจนสูงเกินไป (${oxygenPercent.toStringAsFixed(1)}% > 23.5%): เพิ่มความเสี่ยงเพลิงไหม้รุนแรง');
    }
    if (combustiblePercentLel >= 10.0) {
      warnings.add('ก๊าซไวไฟเกินเกณฑ์ (${combustiblePercentLel.toStringAsFixed(1)}% LEL >= 10%): เสี่ยงต่อการระเบิด');
    }
    if (carbonMonoxidePpm >= 25.0) {
      warnings.add('คาร์บอนมอนอกไซด์เกินเกณฑ์ (${carbonMonoxidePpm.toStringAsFixed(1)} ppm >= 25 ppm): เสี่ยงพิษเฉียบพลัน');
    }
    if (hydrogenSulfidePpm >= 10.0) {
      warnings.add('ไฮโดรเจนซัลไฟด์เกินเกณฑ์ (${hydrogenSulfidePpm.toStringAsFixed(1)} ppm >= 10 ppm): เสี่ยงก๊าซไข่เน่าเป็นพิษ');
    }
    return warnings;
  }
}
```

---

### 3.3 Confined Space 4-Role Model (`ConfinedRoleModel`)

#### Statutory Roles (กฎกระทรวงอับอากาศ ๒๕๖๒ ข้อ ๙-๑๒):
1. **ผู้อนุญาต (Authorizer)**: ผู้มีอำนาจตัดสินใจ อนุมัติ และควบคุมการอนุญาต
2. **ผู้ควบคุมงาน (Supervisor)**: ผู้บังคับบัญชาควบคุมหน้างานตามแผนงาน
3. **ผู้ช่วยเหลือ (Attendant / Standby Person)**: ผู้เฝ้าระวังหน้าทางเข้า-ออก และเตรียมพร้อมช่วยเหลือฉุกเฉิน
4. **ผู้ปฏิบัติงาน (Entrant)**: ผู้เข้าไปปฏิบัติงานภายในที่อับอากาศ

```dart
enum ConfinedRoleType {
  authorizer,  // ผู้อนุญาต (ม.๙)
  supervisor,  // ผู้ควบคุมงาน (ม.๑๐)
  attendant,   // ผู้ช่วยเหลือ/ผู้เฝ้าระวังทางเข้าออก (ม.๑๑)
  entrant;     // ผู้ปฏิบัติงานในที่อับอากาศ (ม.๑๒)

  String toDbCode() {
    switch (this) {
      case ConfinedRoleType.authorizer: return 'AUTHORIZER';
      case ConfinedRoleType.supervisor: return 'SUPERVISOR';
      case ConfinedRoleType.attendant: return 'ATTENDANT';
      case ConfinedRoleType.entrant: return 'ENTRANT';
    }
  }

  static ConfinedRoleType fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'AUTHORIZER': return ConfinedRoleType.authorizer;
      case 'SUPERVISOR': return ConfinedRoleType.supervisor;
      case 'ATTENDANT':
      case 'STANDBY': return ConfinedRoleType.attendant;
      case 'ENTRANT': return ConfinedRoleType.entrant;
      default: return ConfinedRoleType.entrant;
    }
  }

  String get labelTh {
    switch (this) {
      case ConfinedRoleType.authorizer: return 'ผู้อนุญาต (Authorizer)';
      case ConfinedRoleType.supervisor: return 'ผู้ควบคุมงาน (Supervisor)';
      case ConfinedRoleType.attendant: return 'ผู้ช่วยเหลือ/เฝ้าระวัง (Attendant)';
      case ConfinedRoleType.entrant: return 'ผู้ปฏิบัติงานในที่อับอากาศ (Entrant)';
    }
  }
}

class ConfinedRoleModel {
  final int? id;
  final String roleAssignmentId;   // e.g. "CFR-PTW-2026-001-01"
  final String ptwNumber;
  final ConfinedRoleType roleType;
  final String personName;
  final String? nationalId;
  final String? employeeId;
  final String companyName;        // บริษัทต้นสังกัด / ผู้รับเหมา
  final String certNumber;         // เลขที่ใบประกาศผ่านการอบรมที่อับอากาศ
  final String certInstitute;      // หน่วยงานที่จัดฝึกอบรม
  final String certIssueDate;      // วันที่ออกใบรับรอง
  final String certExpiryDate;     // วันหมดอายุใบรับรอง (ถ้ามี)
  final String contactPhone;
  final bool isTrainedAndCertified;
  final String? signaturePath;

  const ConfinedRoleModel({
    this.id,
    required this.roleAssignmentId,
    required this.ptwNumber,
    required this.roleType,
    required this.personName,
    this.nationalId,
    this.employeeId,
    required this.companyName,
    required this.certNumber,
    required this.certInstitute,
    required this.certIssueDate,
    required this.certExpiryDate,
    required this.contactPhone,
    this.isTrainedAndCertified = true,
    this.signaturePath,
  });

  /// Check if certificate is still valid
  bool get isCertificateValid {
    if (!isTrainedAndCertified || certNumber.trim().isEmpty) return false;
    if (certExpiryDate.isEmpty) return true;
    try {
      final exp = DateTime.parse(certExpiryDate);
      return DateTime.now().isBefore(exp);
    } catch (_) {
      return true;
    }
  }
}
```

---

### 3.4 Fire Watch Model (`FireWatchModel`)

#### Statutory Mandate (กฎกระทรวงอัคคีภัย ๒๕๕๕):
- พื้นที่รัศมีปลอดภัย: เคลียร์วัสดุติดไฟ $\ge 11\text{ เมตร}$ (35 ฟุต)
- การเฝ้าระวังหลังงาน: ตรวจสอบความปลอดภัยต่อเนื่องไม่น้อยกว่า 30 นาทีหลังงานเชื่อม/ตัดเสร็จสิ้น ($t_{\text{post\_watch}} \ge 30\text{ min}$)

```dart
class FireWatchModel {
  final int? id;
  final String watchId;                   // e.g. "FW-PTW-2026-001"
  final String ptwNumber;
  final String fireWatcherName;           // ชื่อผู้เฝ้าระวังไฟ
  final String fireWatcherPhone;
  final String fireExtinguisherType;      // ชนิดถังดับเพลิง (e.g. Dry Chemical 15 lbs, CO2)
  final String fireExtinguisherSerial;    // หมายเลขถังดับเพลิง
  final bool extinguisherInspectedReady;  // ตรวจสอบเกจวัดแรงดันพร้อมใช้งาน
  final double clearedRadiusMeters;       // รัศมีเคลียร์วัสดุติดไฟ (มาตรฐาน >= 11 เมตร)
  final bool fireBlanketInstalled;        // ติดตั้งผ้ากันสะเก็ดไฟ
  final bool combustibleMaterialProtected;// คลุมหรือเคลื่อนย้ายสารไวไฟ
  final bool sewerCovered;                // ปิดฝาท่อระบายน้ำ/ช่องเปิดป้องกันสะเก็ดไฟ
  final String hotWorkEndTime;            // เวลาสิ้นสุดงานประกายไฟ (ISO 8601)
  final String postWorkWatchStartTime;    // เวลาเริ่มเฝ้าระวังหลังเลิกงาน
  final String? postWorkWatchEndTime;     // เวลาสิ้นสุดการเฝ้าระวัง
  final int postWorkWatchDurationMinutes; // ระยะเวลาเฝ้าระวังจริง (ต้อง >= 30 นาที)
  final bool isPostWorkAreaSafe;          // ยืนยันไม่มีความร้อนคุกรุ่น/สะเก็ดไฟหลงเหลือ
  final String? finalInspectorName;       // ผู้ตรวจสอบปิดงานไฟ
  final String? finalInspectorSignature;  // ลายเซ็นผู้ตรวจสอบ
  final String? notes;

  const FireWatchModel({
    this.id,
    required this.watchId,
    required this.ptwNumber,
    required this.fireWatcherName,
    required this.fireWatcherPhone,
    required this.fireExtinguisherType,
    required this.fireExtinguisherSerial,
    required this.extinguisherInspectedReady,
    required this.clearedRadiusMeters,
    required this.fireBlanketInstalled,
    required this.combustibleMaterialProtected,
    required this.sewerCovered,
    required this.hotWorkEndTime,
    required this.postWorkWatchStartTime,
    this.postWorkWatchEndTime,
    this.postWorkWatchDurationMinutes = 30,
    required this.isPostWorkAreaSafe,
    this.finalInspectorName,
    this.finalInspectorSignature,
    this.notes,
  });

  bool get isCompliantWith30MinRule =>
      postWorkWatchDurationMinutes >= 30 && isPostWorkAreaSafe;
}
```

---

### 3.5 LOTO Energy Isolation Model (`LotoIsolationModel`)

#### Statutory Mandate (กฎกระทรวงไฟฟ้า ๒๕๕๘):
- การตัดแยกพลังงานอันตราย (Electrical, Mechanical, Hydraulic, Pneumatic, Thermal, Chemical)
- แม่กุญแจส่วนบุคคล (Safety Padlock) & ป้ายเตือนอันตราย (LOTO Tag)
- การทดสอบพลังงานเป็นศูนย์ (Zero Energy Verification)

```dart
enum EnergyType {
  electrical,     // ไฟฟ้า (High/Low Voltage)
  pneumatic,      // ลม/ก๊าซอัดความดัน
  hydraulic,      // น้ำมันไฮดรอลิก
  chemicalFluid,  // สารเคมี/ของเหลวในท่อ
  thermal,        // ความร้อน/ไอน้ำ (Steam)
  mechanical;     // พลังงานกล/สปริง/ความโน้มถ่วง

  String toDbCode() {
    switch (this) {
      case EnergyType.electrical: return 'ELECTRICAL';
      case EnergyType.pneumatic: return 'PNEUMATIC';
      case EnergyType.hydraulic: return 'HYDRAULIC';
      case EnergyType.chemicalFluid: return 'CHEMICAL_FLUID';
      case EnergyType.thermal: return 'THERMAL';
      case EnergyType.mechanical: return 'MECHANICAL';
    }
  }

  static EnergyType fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'ELECTRICAL': return EnergyType.electrical;
      case 'PNEUMATIC': return EnergyType.pneumatic;
      case 'HYDRAULIC': return EnergyType.hydraulic;
      case 'CHEMICAL_FLUID': return EnergyType.chemicalFluid;
      case 'THERMAL': return EnergyType.thermal;
      case 'MECHANICAL': return EnergyType.mechanical;
      default: return EnergyType.electrical;
    }
  }

  String get labelTh {
    switch (this) {
      case EnergyType.electrical: return 'ไฟฟ้า (Electrical)';
      case EnergyType.pneumatic: return 'ลม/ก๊าซอัด (Pneumatic)';
      case EnergyType.hydraulic: return 'ไฮดรอลิก (Hydraulic)';
      case EnergyType.chemicalFluid: return 'สารเคมี/ท่อส่ง (Chemical/Fluid)';
      case EnergyType.thermal: return 'ความร้อน/ไอน้ำ (Thermal/Steam)';
      case EnergyType.mechanical: return 'กลไก/แรงโน้มถ่วง (Mechanical)';
    }
  }
}

class LotoIsolationModel {
  final int? id;
  final String isolationId;              // e.g. "LOTO-PTW-2026-001-01"
  final String ptwNumber;
  final String equipmentTagNo;           // e.g. "PUMP-101-M", "MCC-PNL-04"
  final String equipmentName;            // e.g. "ปั๊มสูบจ่ายสารเคมีหลัก ชุดที่ 1"
  final String locationArea;             // e.g. "อาคารควบคุมระบบไฟฟ้า ชั้น 1"
  final EnergyType energyType;
  final String isolationMethod;          // 'BREAKER_LOCK', 'VALVE_LOCKOUT', 'BLIND_FLANGE', 'FUSE_REMOVAL'
  final String padlockTagNo;             // หมายเลขแม่กุญแจ LOTO
  final String lockAppliedBy;            // ผู้ใส่กุญแจและป้ายเตือน
  final String lockAppliedTimestamp;     // วันเวลาที่ทำการล็อก
  final String zeroEnergyTestMethod;     // วิธีทดสอบพลังงานศูนย์ e.g. "โวลต์มิเตอร์วัดไฟ 0V", "เปิดวาล์วเดรนแรงดัน 0 bar"
  final bool isZeroEnergyVerified;       // ยืนยันสถานะพลังงานตกค้างเป็นศูนย์
  final String verifiedBy;               // ผู้ทดสอบและยืนยัน
  final String? verifiedTimestamp;
  final bool isDeIsolated;               // ปลดล็อกคืนสภาพเมื่อปิดงาน
  final String? deIsolatedBy;
  final String? deIsolatedTimestamp;
  final String? notes;

  const LotoIsolationModel({
    this.id,
    required this.isolationId,
    required this.ptwNumber,
    required this.equipmentTagNo,
    required this.equipmentName,
    required this.locationArea,
    required this.energyType,
    required this.isolationMethod,
    required this.padlockTagNo,
    required this.lockAppliedBy,
    required this.lockAppliedTimestamp,
    required this.zeroEnergyTestMethod,
    required this.isZeroEnergyVerified,
    required this.verifiedBy,
    this.verifiedTimestamp,
    this.isDeIsolated = false,
    this.deIsolatedBy,
    this.deIsolatedTimestamp,
    this.notes,
  });
}
```

---

### 3.6 Safety Checklist Model (`PtwChecklistModel` & `PtwChecklistItem`)

```dart
class PtwChecklistItem {
  final String itemId;           // e.g. "CHK-HOT-01"
  final HighRiskType riskType;
  final String checkCategory;     // e.g. "PPE", "EQUIPMENT", "ENVIRONMENT", "EMERGENCY"
  final String questionTh;
  final String questionEn;
  final bool isMandatory;         // ข้อบังคับทางกฎหมาย (ต้องผ่านเท่านั้น)
  final String result;            // 'YES', 'NO', 'NA'
  final String? remarks;

  const PtwChecklistItem({
    required this.itemId,
    required this.riskType,
    required this.checkCategory,
    required this.questionTh,
    required this.questionEn,
    this.isMandatory = true,
    this.result = 'NA',
    this.remarks,
  });

  bool get isCompliant => result == 'YES' || (result == 'NA' && !isMandatory);

  Map<String, dynamic> toMap() => {
    'item_id': itemId,
    'risk_type': riskType.toDbCode(),
    'check_category': checkCategory,
    'question_th': questionTh,
    'question_en': questionEn,
    'is_mandatory': isMandatory ? 1 : 0,
    'result': result,
    'remarks': remarks,
  };

  factory PtwChecklistItem.fromMap(Map<String, dynamic> map) => PtwChecklistItem(
    itemId: map['item_id'] ?? '',
    riskType: HighRiskType.fromDbCode(map['risk_type']),
    checkCategory: map['check_category'] ?? '',
    questionTh: map['question_th'] ?? '',
    questionEn: map['question_en'] ?? '',
    isMandatory: (map['is_mandatory'] as num?)?.toInt() == 1,
    result: map['result'] ?? 'NA',
    remarks: map['remarks'],
  );
}
```

---

### 3.7 Master PTW Model (`PtwModel`)

```dart
class PtwModel {
  final int? id;
  final String ptwNumber;               // e.g. "PTW-20260901-001"
  final String workTitle;               // ชื่องานที่ขออนุญาต
  final String workDescription;         // รายละเอียดงาน
  final HighRiskType primaryRiskType;    // ประเภทความเสี่ยงหลัก
  final List<HighRiskType> secondaryRiskTypes; // ความเสี่ยงร่วม (เช่น ทำงานบนที่สูงในที่อับอากาศ)
  final PtwStatus status;
  final String plantArea;               // โรงงาน / อาคาร / แผนก
  final String specificLocation;        // ตำแหน่งเฉพาะเจาะจง
  final String requestDate;             // วันที่ยื่นคำขอ (YYYY-MM-DD)
  final String workStartDate;           // วันที่เริ่มปฏิบัติงาน
  final String workStartTime;           // เวลาเริ่ม (HH:mm)
  final String workEndDate;             // วันที่สิ้นสุด
  final String workEndTime;             // เวลาสิ้นสุด (HH:mm)
  final int extensionHours;             // จำนวนชั่วโมงที่ขอต่อเวลา (ถ้ามี)
  final String? extensionReason;        // เหตุผลการขอต่อเวลา
  
  // Organization & Contractor Details
  final String applicantType;           // 'INTERNAL_EMPLOYEE' or 'CONTRACTOR'
  final String applicantName;           // ผู้ขออนุญาต
  final String applicantDepartment;     // แผนก / บริษัทผู้รับเหมา
  final String applicantPhone;
  final int workerCount;                // จำนวนผู้ปฏิบัติงานทั้งหมด
  final List<String> workerNames;       // รายชื่อผู้ปฏิบัติงาน
  
  // Safety Controls & Risk Assessment
  final String? jsaReferenceNo;         // เลขที่เอกสาร JSA/Risk Assessment ที่เกี่ยวข้อง
  final String emergencyRescuePlan;     // สรุปแผนฉุกเฉินและเบอร์ติดต่อกู้ภัย
  final String requiredPpeList;         // รายการ PPE ที่ต้องสวมใส่
  final String specialPrecautions;      // มาตรการควบคุมพิเศษเฉพาะหน้างาน
  
  // Digital Signatures (4 Parties)
  final String? applicantSignaturePath;       // 1. ผู้ขออนุญาต
  final String? applicantSignedAt;
  final String? safetyOfficerSignaturePath;   // 2. จป.วิชาชีพ ผู้ตรวจสอบ
  final String? safetyOfficerName;
  final String? safetyOfficerSignedAt;
  final String? authorizerSignaturePath;      // 3. ผู้อนุญาตตามกฎหมาย
  final String? authorizerName;
  final String? authorizerSignedAt;
  final String? handoverSignaturePath;        // 4. ผู้รับมอบงาน / ส่งต่อกะ
  final String? handoverSignedAt;
  final String? closureSignaturePath;         // 5. ผู้ตรวจสอบปิดงาน
  final String? closureSignedAt;
  final String? closureRemarks;
  
  // Embedded Child Datasets (Populated or stored in DB)
  final List<GasTestLogModel> gasTestLogs;
  final List<ConfinedRoleModel> confinedRoles;
  final FireWatchModel? fireWatch;
  final List<LotoIsolationModel> lotoIsolations;
  final List<PtwChecklistItem> checklistItems;
  final List<String> sitePhotoPaths;

  final String? qrCodeData;
  final String? officialPdfPath;
  final String? createdAt;
  final String? updatedAt;

  const PtwModel({
    this.id,
    required this.ptwNumber,
    required this.workTitle,
    required this.workDescription,
    required this.primaryRiskType,
    this.secondaryRiskTypes = const [],
    this.status = PtwStatus.draft,
    required this.plantArea,
    required this.specificLocation,
    required this.requestDate,
    required this.workStartDate,
    required this.workStartTime,
    required this.workEndDate,
    required this.workEndTime,
    this.extensionHours = 0,
    this.extensionReason,
    required this.applicantType,
    required this.applicantName,
    required this.applicantDepartment,
    required this.applicantPhone,
    this.workerCount = 1,
    this.workerNames = const [],
    this.jsaReferenceNo,
    required this.emergencyRescuePlan,
    required this.requiredPpeList,
    this.specialPrecautions = '',
    this.applicantSignaturePath,
    this.applicantSignedAt,
    this.safetyOfficerSignaturePath,
    this.safetyOfficerName,
    this.safetyOfficerSignedAt,
    this.authorizerSignaturePath,
    this.authorizerName,
    this.authorizerSignedAt,
    this.handoverSignaturePath,
    this.handoverSignedAt,
    this.closureSignaturePath,
    this.closureSignedAt,
    this.closureRemarks,
    this.gasTestLogs = const [],
    this.confinedRoles = const [],
    this.fireWatch,
    this.lotoIsolations = const [],
    this.checklistItems = const [],
    this.sitePhotoPaths = const [],
    this.qrCodeData,
    this.officialPdfPath,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if permit has exceeded allowed work time window
  bool get isOverdue {
    if (status != PtwStatus.active && status != PtwStatus.extendedHandover) return false;
    try {
      final endDateTimeStr = '$workEndDate $workEndTime:00';
      final endDateTime = DateTime.parse(endDateTimeStr).add(Duration(hours: extensionHours));
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  /// Check if all mandatory checklists have been answered 'YES'
  bool get isChecklistComplete {
    if (checklistItems.isEmpty) return false;
    return checklistItems.where((c) => c.isMandatory).every((c) => c.result == 'YES');
  }

  /// Check if confined space 4 roles are fully satisfied
  bool get isConfinedSpaceCompliant {
    if (primaryRiskType != HighRiskType.confinedSpace && !secondaryRiskTypes.contains(HighRiskType.confinedSpace)) {
      return true;
    }
    final hasAuth = confinedRoles.any((r) => r.roleType == ConfinedRoleType.authorizer && r.isCertificateValid);
    final hasSup = confinedRoles.any((r) => r.roleType == ConfinedRoleType.supervisor && r.isCertificateValid);
    final hasAtt = confinedRoles.any((r) => r.roleType == ConfinedRoleType.attendant && r.isCertificateValid);
    final hasEnt = confinedRoles.any((r) => r.roleType == ConfinedRoleType.entrant && r.isCertificateValid);
    return hasAuth && hasSup && hasAtt && hasEnt;
  }

  /// Check if gas test is safe
  bool get isPreEntryGasTestSafe {
    if (primaryRiskType != HighRiskType.confinedSpace && !secondaryRiskTypes.contains(HighRiskType.confinedSpace)) {
      return true;
    }
    final preEntryLogs = gasTestLogs.where((g) => g.testStage == 'PRE_ENTRY').toList();
    if (preEntryLogs.isEmpty) return false;
    return preEntryLogs.last.isSafe;
  }

  /// Check if LOTO is zero-energy verified
  bool get isLotoVerified {
    if (primaryRiskType != HighRiskType.electricalLoto && !secondaryRiskTypes.contains(HighRiskType.electricalLoto)) {
      return true;
    }
    if (lotoIsolations.isEmpty) return false;
    return lotoIsolations.every((l) => l.isZeroEnergyVerified);
  }
}
```

---

## 4. SQLite Schema & Migration Design (Database Version 8)

### Table 1: `ptw_permits` (Master Table)
```sql
CREATE TABLE IF NOT EXISTS ptw_permits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ptw_number TEXT NOT NULL UNIQUE,
  work_title TEXT NOT NULL,
  work_description TEXT NOT NULL,
  primary_risk_type TEXT NOT NULL,
  secondary_risk_types TEXT, -- JSON List
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
  worker_names TEXT, -- JSON List
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
  site_photo_paths TEXT, -- JSON List
  qr_code_data TEXT,
  official_pdf_path TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ptw_number ON ptw_permits(ptw_number);
CREATE INDEX IF NOT EXISTS idx_ptw_status ON ptw_permits(status);
CREATE INDEX IF NOT EXISTS idx_ptw_risk ON ptw_permits(primary_risk_type);
CREATE INDEX IF NOT EXISTS idx_ptw_date ON ptw_permits(work_start_date);
```

### Table 2: `ptw_gas_test_logs`
```sql
CREATE TABLE IF NOT EXISTS ptw_gas_test_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  log_id TEXT NOT NULL UNIQUE,
  ptw_number TEXT NOT NULL,
  test_stage TEXT NOT NULL, -- 'PRE_ENTRY', 'CONTINUOUS', 'POST_WORK'
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
);

CREATE INDEX IF NOT EXISTS idx_gas_ptw ON ptw_gas_test_logs(ptw_number);
CREATE INDEX IF NOT EXISTS idx_gas_stage ON ptw_gas_test_logs(test_stage);
```

### Table 3: `ptw_confined_roles`
```sql
CREATE TABLE IF NOT EXISTS ptw_confined_roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  role_assignment_id TEXT NOT NULL UNIQUE,
  ptw_number TEXT NOT NULL,
  role_type TEXT NOT NULL, -- 'AUTHORIZER', 'SUPERVISOR', 'ATTENDANT', 'ENTRANT'
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
);

CREATE INDEX IF NOT EXISTS idx_cfr_ptw ON ptw_confined_roles(ptw_number);
CREATE INDEX IF NOT EXISTS idx_cfr_role ON ptw_confined_roles(role_type);
```

### Table 4: `ptw_fire_watches`
```sql
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
);

CREATE INDEX IF NOT EXISTS idx_fw_ptw ON ptw_fire_watches(ptw_number);
```

### Table 5: `ptw_loto_isolations`
```sql
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
);

CREATE INDEX IF NOT EXISTS idx_loto_ptw ON ptw_loto_isolations(ptw_number);
```

### Table 6: `ptw_checklists`
```sql
CREATE TABLE IF NOT EXISTS ptw_checklists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ptw_number TEXT NOT NULL,
  item_id TEXT NOT NULL,
  risk_type TEXT NOT NULL,
  check_category TEXT NOT NULL,
  question_th TEXT NOT NULL,
  question_en TEXT NOT NULL,
  is_mandatory INTEGER NOT NULL DEFAULT 1,
  result TEXT NOT NULL DEFAULT 'NA', -- 'YES', 'NO', 'NA'
  remarks TEXT,
  FOREIGN KEY (ptw_number) REFERENCES ptw_permits(ptw_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_chk_ptw ON ptw_checklists(ptw_number);
```

---

## 5. Workflow State Machine & Transition Rules

```
     [1. Draft]
         │
         │  (Submit: Validates JSA, Complete Checklists, Applicant Signature)
         ▼
 [2. Pending Approval]
         │
         │  (Approve: Safety Officer Sign-off + Authorizer Sign-off
         │            + Pre-entry Gas Safe + LOTO Zero Energy Verified)
         ▼
     [3. Active] ◄────────────────────────┐
         │                                │
         ├── (Extend / Shift Handover) ───┤
         ▼                                │
 [4. Extended / Handover] ────────────────┘
         │
         │  (Close/Cancel: Post-work site check + 30-min Fire Watch
         │                 + LOTO De-isolation + Closure Signature)
         ▼
[5. Closed / Cancelled]
```

### Transition Guard Rules:
1. **Draft $\rightarrow$ PendingApproval**:
   - `workTitle`, `plantArea`, `specificLocation`, `workStartDate`, `workStartTime`, `workEndDate`, `workEndTime` must not be empty.
   - `applicantSignaturePath` must be present.
   - All `mandatory` items in safety checklist must be answered.
2. **PendingApproval $\rightarrow$ Active**:
   - `safetyOfficerSignaturePath` AND `authorizerSignaturePath` must both be present.
   - If `ConfinedSpace`: Pre-entry gas test must be performed and evaluate to `isSafe == true`, and 4 roles must be assigned.
   - If `ElectricalLoto`: All isolation points must have `isZeroEnergyVerified == true`.
3. **Active $\rightarrow$ ExtendedHandover**:
   - Current time must not exceed work end date/time by more than grace period.
   - Requires `handoverSignaturePath` and specified `extensionHours` / reason.
4. **Active / ExtendedHandover $\rightarrow$ ClosedCancelled**:
   - If `HotWork`: Fire watch must record `postWorkWatchDurationMinutes >= 30` and `isPostWorkAreaSafe == true`.
   - If `ElectricalLoto`: All locks de-isolated (`isDeIsolated == true`).
   - `closureSignaturePath` must be present.

---

## 6. Integration Architecture (PDF, QR Code, Excel, Agent Skill)

1. **PDF Generation (`features/ptw/services/ptw_official_pdf_service.dart`)**:
   - Produces official DLPW Form (แบบหนังสืออนุญาตทำงานในที่อับอากาศ/ที่สูง/ประกายไฟ).
   - Generates and embeds QR Code containing verification URL/JSON payload (`ptwNumber`, `status`, `validUntil`, `verifierUrl`).
   - Embeds high-resolution PNG signatures for all 4 authorized parties.
2. **Excel Summary Export (`features/ptw/services/ptw_excel_export_service.dart`)**:
   - Aggregates PTW registry by date range, department, risk type, compliance score, and gas test history into formatted multi-tab spreadsheets.
3. **Agent Skill `thai-ptw-safety-law` (`D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py` & `.gemini/config/skills/thai-ptw-safety-law`)**:
   - Provides CLI subcommands:
     - `validate-ptw`: Verifies PTW JSON against Thai statutory rules.
     - `eval-gas`: Evaluates $O_2, LEL, CO, H_2S$ values.
     - `verify-confined-roles`: Validates 4 required roles.
     - `get-checklist`: Returns standard checklist per high risk type.
     - `get-ptw-law`: Returns statutory articles and penalty clauses.

---

## 7. Recommended Implementation Sequence

1. **Step 1: Database Migration & Models (Domain & Data Layer)**
   - Create `lib/features/ptw/domain/models/` (Enums, PtwModel, GasTestLogModel, ConfinedRoleModel, FireWatchModel, LotoIsolationModel, PtwChecklistModel, KPI).
   - Create `lib/features/ptw/data/datasources/ptw_statutory_master_data.dart` (Checklists, Thai law articles).
   - Update `lib/core/database/database_helper.dart` to version 8 with PTW tables creation and indexes.
   - Create `lib/features/ptw/data/repositories/ptw_repository.dart` (CRUD & Filter queries).
2. **Step 2: Domain Services & Evaluation Engine**
   - Create `ptw_safety_evaluator.dart` and `ptw_state_machine.dart`.
3. **Step 3: Riverpod State Notifiers & Providers**
   - Create `lib/features/ptw/presentation/providers/ptw_providers.dart`.
4. **Step 4: Presentation UI Widgets & 4 Main Tabs**
   - Implement `ptw_page.dart` with 4 Tabs:
     - Tab 1: `PtwDashboardTab` (KPI Cards + PTW Data Table + Filters).
     - Tab 2: `PtwWizardTab` (Create/Edit Multi-Step Form with Signature Pad).
     - Tab 3: `PtwLiveControlsTab` (Live Gas Test Logger, 30-min Fire Watch Timer, LOTO check).
     - Tab 4: `PtwLegalLibraryTab` (Gazette Laws & PDF Viewers).
5. **Step 5: Reporting Services (PDF + QR Code & Excel)**
   - Implement `ptw_official_pdf_service.dart` and `ptw_excel_export_service.dart`.
6. **Step 6: Agent Skill & CLI Tool**
   - Implement `thai-ptw-safety-law` skill in `.gemini/config/skills/thai-ptw-safety-law/` and `D:\DEV\AgentResearch\Scripts\thai_ptw_helper.py`.
7. **Step 7: Testing & Verification**
   - Write comprehensive unit tests in `test/features/ptw/ptw_safety_evaluator_test.dart` and `test/features/ptw/ptw_state_machine_test.dart`.
   - Run `flutter test` to ensure 100% test pass rate.
