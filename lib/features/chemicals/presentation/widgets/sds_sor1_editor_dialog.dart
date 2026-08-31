import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/chemical_sds_sor1_model.dart';
import '../../domain/models/chemical_master_model.dart';
import 'chemical_autocomplete_field.dart';
import 'ghs_pictogram_selector.dart';
import 'nfpa_diamond_widget.dart';

/// Interactive Multi-Section Editor Dialog for Form สอ.๑ (SDS 16 Sections)
/// Conforming to DLPW Notification B.E. 2556.
class SdsSor1EditorDialog extends StatefulWidget {
  final ChemicalSdsSor1Model? initialItem;
  final Future<void> Function(ChemicalSdsSor1Model) onSave;

  const SdsSor1EditorDialog({
    Key? key,
    this.initialItem,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SdsSor1EditorDialog> createState() => _SdsSor1EditorDialogState();
}

class _SdsSor1EditorDialogState extends State<SdsSor1EditorDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // General & Section 1: Identification
  late TextEditingController _tradeNameController;
  late TextEditingController _chemicalFormulaController;
  late TextEditingController _casNumberController;
  late TextEditingController _unNumberController;
  late TextEditingController _manufacturerInfoController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _recommendedUseController;

  // Section 2: Hazards
  late TextEditingController _ghsClassificationController;
  late TextEditingController _hazardStatementsController;
  late TextEditingController _precautionaryStatementsController;
  String _signalWord = 'DANGER';
  List<String> _selectedGhsPictograms = [];
  int _nfpaHealth = 0;
  int _nfpaFlammability = 0;
  int _nfpaInstability = 0;
  String _nfpaSpecial = '';

  // Section 3: Ingredients
  List<SdsIngredientItem> _ingredients = [];

  // Section 4: First Aid
  late TextEditingController _inhalationController;
  late TextEditingController _skinContactController;
  late TextEditingController _eyeContactController;
  late TextEditingController _ingestionController;
  late TextEditingController _symptomsController;
  late TextEditingController _specialMedicalController;

  // Section 5: Fire Fighting
  late TextEditingController _suitableMediaController;
  late TextEditingController _unsuitableMediaController;
  late TextEditingController _fireHazardsController;
  late TextEditingController _protectiveEquipFireController;

  // Section 6: Spill
  late TextEditingController _personalPrecautionsController;
  late TextEditingController _environmentalPrecautionsController;
  late TextEditingController _containmentCleanUpController;

  // Section 7: Handling & Storage
  late TextEditingController _handlingPrecautionsController;
  late TextEditingController _storageConditionsController;
  late TextEditingController _storageTemperatureController;

  // Section 8: Exposure Controls & PPE
  late TextEditingController _exposureLimitsController;
  late TextEditingController _engineeringControlsController;
  late TextEditingController _respiratoryProtectionController;
  late TextEditingController _eyeProtectionController;
  late TextEditingController _skinProtectionController;

  // Section 9: Physical & Chemical
  late TextEditingController _appearanceController;
  late TextEditingController _odorController;
  late TextEditingController _phValueController;
  late TextEditingController _boilingPointController;
  late TextEditingController _flashPointController;
  late TextEditingController _flammabilityLimitsController;
  late TextEditingController _vaporPressureController;
  late TextEditingController _relativeDensityController;
  late TextEditingController _solubilityController;

  // Section 10: Stability & Reactivity
  late TextEditingController _reactivityController;
  late TextEditingController _chemicalStabilityController;
  late TextEditingController _conditionsToAvoidController;
  late TextEditingController _incompatibleMaterialsController;
  late TextEditingController _hazardousDecompositionController;

  // Section 11: Toxicological
  late TextEditingController _acuteToxicityController;
  late TextEditingController _skinCorrosionController;
  late TextEditingController _seriousEyeController;
  late TextEditingController _carcinogenicityController;
  late TextEditingController _reproductiveToxicityController;
  late TextEditingController _targetOrganController;

  // Section 12: Ecological
  late TextEditingController _ecotoxicityController;
  late TextEditingController _persistenceController;
  late TextEditingController _bioaccumulationController;
  late TextEditingController _mobilityInSoilController;

  // Section 13: Disposal
  late TextEditingController _wasteTreatmentController;
  late TextEditingController _contaminatedPackagingController;

  // Section 14: Transport
  late TextEditingController _shippingNameController;
  late TextEditingController _transportHazardClassController;
  late TextEditingController _packingGroupController;
  late TextEditingController _marinePollutantController;
  late TextEditingController _transportPrecautionsController;

  // Section 15: Regulatory
  late TextEditingController _safetyHealthRegsController;
  late TextEditingController _substanceTypeController;

  // Section 16: Other
  late TextEditingController _revisionDateController;
  late TextEditingController _versionNoController;
  late TextEditingController _preparedByController;
  late TextEditingController _referencesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final it = widget.initialItem;

    _tradeNameController = TextEditingController(text: it?.tradeName ?? '');
    _chemicalFormulaController = TextEditingController(text: it?.chemicalFormula ?? '');
    _casNumberController = TextEditingController(text: it?.casNumber ?? '');
    _unNumberController = TextEditingController(text: it?.unNumber ?? '');
    _manufacturerInfoController = TextEditingController(text: it?.manufacturerImporterInfo ?? '');
    _emergencyPhoneController = TextEditingController(text: it?.emergencyPhone ?? '');
    _recommendedUseController = TextEditingController(text: it?.recommendedUse ?? '');

    _ghsClassificationController = TextEditingController(text: it?.ghsClassification ?? '');
    _hazardStatementsController = TextEditingController(text: it?.hazardStatements.join('\n') ?? '');
    _precautionaryStatementsController = TextEditingController(text: it?.precautionaryStatements.join('\n') ?? '');
    _signalWord = it?.signalWord ?? 'DANGER';
    _selectedGhsPictograms = List.from(it?.ghsPictograms ?? []);
    _nfpaHealth = it?.nfpaHealth ?? 0;
    _nfpaFlammability = it?.nfpaFlammability ?? 0;
    _nfpaInstability = it?.nfpaInstability ?? 0;
    _nfpaSpecial = it?.nfpaSpecial ?? '';

    _ingredients = List.from(it?.ingredients ?? []);

    _inhalationController = TextEditingController(text: it?.inhalationFirstAid ?? '');
    _skinContactController = TextEditingController(text: it?.skinContactFirstAid ?? '');
    _eyeContactController = TextEditingController(text: it?.eyeContactFirstAid ?? '');
    _ingestionController = TextEditingController(text: it?.ingestionFirstAid ?? '');
    _symptomsController = TextEditingController(text: it?.symptomsEffects ?? '');
    _specialMedicalController = TextEditingController(text: it?.specialMedicalAttention ?? '');

    _suitableMediaController = TextEditingController(text: it?.suitableExtinguishingMedia ?? '');
    _unsuitableMediaController = TextEditingController(text: it?.unsuitableExtinguishingMedia ?? '');
    _fireHazardsController = TextEditingController(text: it?.specificFireHazards ?? '');
    _protectiveEquipFireController = TextEditingController(text: it?.protectiveEquipmentFirefighters ?? '');

    _personalPrecautionsController = TextEditingController(text: it?.personalPrecautions ?? '');
    _environmentalPrecautionsController = TextEditingController(text: it?.environmentalPrecautions ?? '');
    _containmentCleanUpController = TextEditingController(text: it?.containmentCleanUp ?? '');

    _handlingPrecautionsController = TextEditingController(text: it?.handlingPrecautions ?? '');
    _storageConditionsController = TextEditingController(text: it?.storageConditions ?? '');
    _storageTemperatureController = TextEditingController(text: it?.storageTemperature ?? '');

    _exposureLimitsController = TextEditingController(text: it?.exposureLimits ?? '');
    _engineeringControlsController = TextEditingController(text: it?.engineeringControls ?? '');
    _respiratoryProtectionController = TextEditingController(text: it?.respiratoryProtection ?? '');
    _eyeProtectionController = TextEditingController(text: it?.eyeProtection ?? '');
    _skinProtectionController = TextEditingController(text: it?.skinHandProtection ?? '');

    _appearanceController = TextEditingController(text: it?.appearance ?? '');
    _odorController = TextEditingController(text: it?.odor ?? '');
    _phValueController = TextEditingController(text: it?.phValue ?? '');
    _boilingPointController = TextEditingController(text: it?.boilingPoint ?? '');
    _flashPointController = TextEditingController(text: it?.flashPoint ?? '');
    _flammabilityLimitsController = TextEditingController(text: it?.flammabilityLimits ?? '');
    _vaporPressureController = TextEditingController(text: it?.vaporPressure ?? '');
    _relativeDensityController = TextEditingController(text: it?.relativeDensity ?? '');
    _solubilityController = TextEditingController(text: it?.solubility ?? '');

    _reactivityController = TextEditingController(text: it?.reactivity ?? '');
    _chemicalStabilityController = TextEditingController(text: it?.chemicalStability ?? '');
    _conditionsToAvoidController = TextEditingController(text: it?.conditionsToAvoid ?? '');
    _incompatibleMaterialsController = TextEditingController(text: it?.incompatibleMaterials ?? '');
    _hazardousDecompositionController = TextEditingController(text: it?.hazardousDecompositionProducts ?? '');

    _acuteToxicityController = TextEditingController(text: it?.acuteToxicity ?? '');
    _skinCorrosionController = TextEditingController(text: it?.skinCorrosionIrritation ?? '');
    _seriousEyeController = TextEditingController(text: it?.seriousEyeDamage ?? '');
    _carcinogenicityController = TextEditingController(text: it?.carcinogenicity ?? '');
    _reproductiveToxicityController = TextEditingController(text: it?.reproductiveToxicity ?? '');
    _targetOrganController = TextEditingController(text: it?.targetOrganToxicity ?? '');

    _ecotoxicityController = TextEditingController(text: it?.ecotoxicity ?? '');
    _persistenceController = TextEditingController(text: it?.persistenceDegradability ?? '');
    _bioaccumulationController = TextEditingController(text: it?.bioaccumulativePotential ?? '');
    _mobilityInSoilController = TextEditingController(text: it?.mobilityInSoil ?? '');

    _wasteTreatmentController = TextEditingController(text: it?.wasteTreatmentMethods ?? '');
    _contaminatedPackagingController = TextEditingController(text: it?.contaminatedPackaging ?? '');

    _shippingNameController = TextEditingController(text: it?.unProperShippingName ?? '');
    _transportHazardClassController = TextEditingController(text: it?.transportHazardClass ?? '');
    _packingGroupController = TextEditingController(text: it?.packingGroup ?? '');
    _marinePollutantController = TextEditingController(text: it?.marinePollutant ?? '');
    _transportPrecautionsController = TextEditingController(text: it?.specialPrecautionsTransport ?? '');

    _safetyHealthRegsController = TextEditingController(text: it?.safetyHealthRegulations ?? '');
    _substanceTypeController = TextEditingController(text: it?.hazardousSubstanceType ?? '');

    _revisionDateController = TextEditingController(text: it?.revisionDate ?? DateTime.now().toIso8601String().substring(0, 10));
    _versionNoController = TextEditingController(text: it?.versionNo ?? '1.0');
    _preparedByController = TextEditingController(text: it?.preparedBy ?? '');
    _referencesController = TextEditingController(text: it?.referencesList ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tradeNameController.dispose();
    _chemicalFormulaController.dispose();
    _casNumberController.dispose();
    _unNumberController.dispose();
    _manufacturerInfoController.dispose();
    _emergencyPhoneController.dispose();
    _recommendedUseController.dispose();
    _ghsClassificationController.dispose();
    _hazardStatementsController.dispose();
    _precautionaryStatementsController.dispose();
    _inhalationController.dispose();
    _skinContactController.dispose();
    _eyeContactController.dispose();
    _ingestionController.dispose();
    _symptomsController.dispose();
    _specialMedicalController.dispose();
    _suitableMediaController.dispose();
    _unsuitableMediaController.dispose();
    _fireHazardsController.dispose();
    _protectiveEquipFireController.dispose();
    _personalPrecautionsController.dispose();
    _environmentalPrecautionsController.dispose();
    _containmentCleanUpController.dispose();
    _handlingPrecautionsController.dispose();
    _storageConditionsController.dispose();
    _storageTemperatureController.dispose();
    _exposureLimitsController.dispose();
    _engineeringControlsController.dispose();
    _respiratoryProtectionController.dispose();
    _eyeProtectionController.dispose();
    _skinProtectionController.dispose();
    _appearanceController.dispose();
    _odorController.dispose();
    _phValueController.dispose();
    _boilingPointController.dispose();
    _flashPointController.dispose();
    _flammabilityLimitsController.dispose();
    _vaporPressureController.dispose();
    _relativeDensityController.dispose();
    _solubilityController.dispose();
    _reactivityController.dispose();
    _chemicalStabilityController.dispose();
    _conditionsToAvoidController.dispose();
    _incompatibleMaterialsController.dispose();
    _hazardousDecompositionController.dispose();
    _acuteToxicityController.dispose();
    _skinCorrosionController.dispose();
    _seriousEyeController.dispose();
    _carcinogenicityController.dispose();
    _reproductiveToxicityController.dispose();
    _targetOrganController.dispose();
    _ecotoxicityController.dispose();
    _persistenceController.dispose();
    _bioaccumulationController.dispose();
    _mobilityInSoilController.dispose();
    _wasteTreatmentController.dispose();
    _contaminatedPackagingController.dispose();
    _shippingNameController.dispose();
    _transportHazardClassController.dispose();
    _packingGroupController.dispose();
    _marinePollutantController.dispose();
    _transportPrecautionsController.dispose();
    _safetyHealthRegsController.dispose();
    _substanceTypeController.dispose();
    _revisionDateController.dispose();
    _versionNoController.dispose();
    _preparedByController.dispose();
    _referencesController.dispose();
    super.dispose();
  }

  void _onChemicalSelected(ChemicalMasterItem chem) {
    setState(() {
      _tradeNameController.text = chem.thaiName;
      _casNumberController.text = chem.casNumber;
      if (chem.unNumber != null && chem.unNumber!.isNotEmpty) {
        _unNumberController.text = chem.unNumber!;
      }
      if (chem.chemicalFormula != null && chem.chemicalFormula!.isNotEmpty) {
        _chemicalFormulaController.text = chem.chemicalFormula!;
      }
      if (chem.hazardCategory != null && chem.hazardCategory!.isNotEmpty) {
        _ghsClassificationController.text = chem.hazardCategory!;
      }
    });
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(
        const SdsIngredientItem(
          chemicalName: '',
          casNumber: '',
          percentage: 0.0,
        ),
      );
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final hList = _hazardStatementsController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final pList = _precautionaryStatementsController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final model = ChemicalSdsSor1Model(
        id: widget.initialItem?.id,
        inventoryId: widget.initialItem?.inventoryId,
        tradeName: _tradeNameController.text.trim(),
        chemicalFormula: _chemicalFormulaController.text.trim().isEmpty ? null : _chemicalFormulaController.text.trim(),
        casNumber: _casNumberController.text.trim(),
        unNumber: _unNumberController.text.trim().isEmpty ? null : _unNumberController.text.trim(),
        manufacturerImporterInfo: _manufacturerInfoController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        recommendedUse: _recommendedUseController.text.trim().isEmpty ? null : _recommendedUseController.text.trim(),
        ghsClassification: _ghsClassificationController.text.trim().isEmpty ? null : _ghsClassificationController.text.trim(),
        ghsPictograms: _selectedGhsPictograms,
        signalWord: _signalWord,
        hazardStatements: hList,
        precautionaryStatements: pList,
        nfpaHealth: _nfpaHealth,
        nfpaFlammability: _nfpaFlammability,
        nfpaInstability: _nfpaInstability,
        nfpaSpecial: _nfpaSpecial.trim().isEmpty ? null : _nfpaSpecial.trim(),
        ingredients: _ingredients,
        inhalationFirstAid: _inhalationController.text.trim().isEmpty ? null : _inhalationController.text.trim(),
        skinContactFirstAid: _skinContactController.text.trim().isEmpty ? null : _skinContactController.text.trim(),
        eyeContactFirstAid: _eyeContactController.text.trim().isEmpty ? null : _eyeContactController.text.trim(),
        ingestionFirstAid: _ingestionController.text.trim().isEmpty ? null : _ingestionController.text.trim(),
        symptomsEffects: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
        specialMedicalAttention: _specialMedicalController.text.trim().isEmpty ? null : _specialMedicalController.text.trim(),
        suitableExtinguishingMedia: _suitableMediaController.text.trim().isEmpty ? null : _suitableMediaController.text.trim(),
        unsuitableExtinguishingMedia: _unsuitableMediaController.text.trim().isEmpty ? null : _unsuitableMediaController.text.trim(),
        specificFireHazards: _fireHazardsController.text.trim().isEmpty ? null : _fireHazardsController.text.trim(),
        protectiveEquipmentFirefighters: _protectiveEquipFireController.text.trim().isEmpty ? null : _protectiveEquipFireController.text.trim(),
        personalPrecautions: _personalPrecautionsController.text.trim().isEmpty ? null : _personalPrecautionsController.text.trim(),
        environmentalPrecautions: _environmentalPrecautionsController.text.trim().isEmpty ? null : _environmentalPrecautionsController.text.trim(),
        containmentCleanUp: _containmentCleanUpController.text.trim().isEmpty ? null : _containmentCleanUpController.text.trim(),
        handlingPrecautions: _handlingPrecautionsController.text.trim().isEmpty ? null : _handlingPrecautionsController.text.trim(),
        storageConditions: _storageConditionsController.text.trim().isEmpty ? null : _storageConditionsController.text.trim(),
        storageTemperature: _storageTemperatureController.text.trim().isEmpty ? null : _storageTemperatureController.text.trim(),
        exposureLimits: _exposureLimitsController.text.trim().isEmpty ? null : _exposureLimitsController.text.trim(),
        engineeringControls: _engineeringControlsController.text.trim().isEmpty ? null : _engineeringControlsController.text.trim(),
        respiratoryProtection: _respiratoryProtectionController.text.trim().isEmpty ? null : _respiratoryProtectionController.text.trim(),
        eyeProtection: _eyeProtectionController.text.trim().isEmpty ? null : _eyeProtectionController.text.trim(),
        skinHandProtection: _skinProtectionController.text.trim().isEmpty ? null : _skinProtectionController.text.trim(),
        appearance: _appearanceController.text.trim().isEmpty ? null : _appearanceController.text.trim(),
        odor: _odorController.text.trim().isEmpty ? null : _odorController.text.trim(),
        phValue: _phValueController.text.trim().isEmpty ? null : _phValueController.text.trim(),
        boilingPoint: _boilingPointController.text.trim().isEmpty ? null : _boilingPointController.text.trim(),
        flashPoint: _flashPointController.text.trim().isEmpty ? null : _flashPointController.text.trim(),
        flammabilityLimits: _flammabilityLimitsController.text.trim().isEmpty ? null : _flammabilityLimitsController.text.trim(),
        vaporPressure: _vaporPressureController.text.trim().isEmpty ? null : _vaporPressureController.text.trim(),
        relativeDensity: _relativeDensityController.text.trim().isEmpty ? null : _relativeDensityController.text.trim(),
        solubility: _solubilityController.text.trim().isEmpty ? null : _solubilityController.text.trim(),
        reactivity: _reactivityController.text.trim().isEmpty ? null : _reactivityController.text.trim(),
        chemicalStability: _chemicalStabilityController.text.trim().isEmpty ? null : _chemicalStabilityController.text.trim(),
        conditionsToAvoid: _conditionsToAvoidController.text.trim().isEmpty ? null : _conditionsToAvoidController.text.trim(),
        incompatibleMaterials: _incompatibleMaterialsController.text.trim().isEmpty ? null : _incompatibleMaterialsController.text.trim(),
        hazardousDecompositionProducts: _hazardousDecompositionController.text.trim().isEmpty ? null : _hazardousDecompositionController.text.trim(),
        acuteToxicity: _acuteToxicityController.text.trim().isEmpty ? null : _acuteToxicityController.text.trim(),
        skinCorrosionIrritation: _skinCorrosionController.text.trim().isEmpty ? null : _skinCorrosionController.text.trim(),
        seriousEyeDamage: _seriousEyeController.text.trim().isEmpty ? null : _seriousEyeController.text.trim(),
        carcinogenicity: _carcinogenicityController.text.trim().isEmpty ? null : _carcinogenicityController.text.trim(),
        reproductiveToxicity: _reproductiveToxicityController.text.trim().isEmpty ? null : _reproductiveToxicityController.text.trim(),
        targetOrganToxicity: _targetOrganController.text.trim().isEmpty ? null : _targetOrganController.text.trim(),
        ecotoxicity: _ecotoxicityController.text.trim().isEmpty ? null : _ecotoxicityController.text.trim(),
        persistenceDegradability: _persistenceController.text.trim().isEmpty ? null : _persistenceController.text.trim(),
        bioaccumulativePotential: _bioaccumulationController.text.trim().isEmpty ? null : _bioaccumulationController.text.trim(),
        mobilityInSoil: _mobilityInSoilController.text.trim().isEmpty ? null : _mobilityInSoilController.text.trim(),
        wasteTreatmentMethods: _wasteTreatmentController.text.trim().isEmpty ? null : _wasteTreatmentController.text.trim(),
        contaminatedPackaging: _contaminatedPackagingController.text.trim().isEmpty ? null : _contaminatedPackagingController.text.trim(),
        unProperShippingName: _shippingNameController.text.trim().isEmpty ? null : _shippingNameController.text.trim(),
        transportHazardClass: _transportHazardClassController.text.trim().isEmpty ? null : _transportHazardClassController.text.trim(),
        packingGroup: _packingGroupController.text.trim().isEmpty ? null : _packingGroupController.text.trim(),
        marinePollutant: _marinePollutantController.text.trim().isEmpty ? null : _marinePollutantController.text.trim(),
        specialPrecautionsTransport: _transportPrecautionsController.text.trim().isEmpty ? null : _transportPrecautionsController.text.trim(),
        safetyHealthRegulations: _safetyHealthRegsController.text.trim().isEmpty ? null : _safetyHealthRegsController.text.trim(),
        hazardousSubstanceType: _substanceTypeController.text.trim().isEmpty ? null : _substanceTypeController.text.trim(),
        revisionDate: _revisionDateController.text.trim(),
        versionNo: _versionNoController.text.trim(),
        preparedBy: _preparedByController.text.trim().isEmpty ? null : _preparedByController.text.trim(),
        referencesList: _referencesController.text.trim().isEmpty ? null : _referencesController.text.trim(),
        status: 'COMPLETED',
      );

      await widget.onSave(model);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 1000,
        height: 780,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab1GeneralHazardsComposition(),
                    _buildTab2FirstAidFireSpillStorage(),
                    _buildTab3ExposurePhysicalToxicity(),
                    _buildTab4EcologicalTransportRegulatory(),
                  ],
                ),
              ),
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialItem == null ? 'จัดทำข้อมูลความปลอดภัยสารเคมีอันตราย (แบบ สอ.๑ - SDS 16 หัวข้อ)' : 'แก้ไขข้อมูลความปลอดภัย แบบ สอ.๑: ${_tradeNameController.text}',
                  style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'ตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัย (แบบ สอ.๑)',
                  style: GoogleFonts.prompt(fontSize: 11, color: Colors.blue.shade100),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF1E3A8A),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.prompt(fontSize: 12),
        tabs: const [
          Tab(text: 'หมวด ๑ - ๓: ข้อมูลทั่วไป, อันตราย & ส่วนประกอบ'),
          Tab(text: 'หมวด ๔ - ๗: ปฐมพยาบาล, ผจญเพลิง, รั่วไหล & จัดเก็บ'),
          Tab(text: 'หมวด ๘ - ๑๑: การควบคุม PPE, กายภาพ & พิษวิทยา'),
          Tab(text: 'หมวด ๑๒ - ๑๖: นิเวศ, กำจัด, ขนส่ง & กฎหมาย'),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: Sections 1 - 3
  // --------------------------------------------------------------------------
  Widget _buildTab1GeneralHazardsComposition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('หมวด ๑: ข้อมูลเกี่ยวกับสารเคมีและบริษัทผู้ผลิต / ผู้จำหน่าย', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          ChemicalAutocompleteField(
            initialValue: _tradeNameController.text.isNotEmpty ? _tradeNameController.text : null,
            onSelected: _onChemicalSelected,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tradeNameController,
            decoration: const InputDecoration(labelText: 'ชื่อทางการค้า / ชื่อผลิตภัณฑ์ (Trade Name) *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อทางการค้า' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _casNumberController,
                  decoration: const InputDecoration(labelText: 'CAS Number *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุ CAS No.' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _unNumberController,
                  decoration: const InputDecoration(labelText: 'UN Number (เช่น UN 1294)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _chemicalFormulaController,
                  decoration: const InputDecoration(labelText: 'สูตรเคมี (Formula)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _manufacturerInfoController,
                  decoration: const InputDecoration(labelText: 'ผู้ผลิต / ผู้นำเข้า / ผู้จำหน่าย (ชื่อ, ที่อยู่)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _emergencyPhoneController,
                  decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์ฉุกเฉิน 24 ชม.', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๒: การบ่งชี้ความเป็นอันตราย (GHS & NFPA 704)', Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ghsClassificationController,
                      decoration: const InputDecoration(labelText: 'การจำแนกประเภทความเป็นอันตราย GHS', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _signalWord,
                      decoration: const InputDecoration(labelText: 'คำสัญญาณ (Signal Word)', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'DANGER', child: Text('อันตราย (DANGER) 🔴')),
                        DropdownMenuItem(value: 'WARNING', child: Text('ระวัง (WARNING) 🟡')),
                        DropdownMenuItem(value: 'NONE', child: Text('ไม่มี (NONE) ⚪')),
                      ],
                      onChanged: (v) => setState(() => _signalWord = v ?? 'DANGER'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // NFPA Diamond Interactive Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text('NFPA 704 Diamond', style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    NfpaDiamondWidget(
                      health: _nfpaHealth,
                      flammability: _nfpaFlammability,
                      instability: _nfpaInstability,
                      special: _nfpaSpecial,
                      size: 64,
                      editable: true,
                      onChanged: (h, f, i, s) {
                        setState(() {
                          _nfpaHealth = h;
                          _nfpaFlammability = f;
                          _nfpaInstability = i;
                          _nfpaSpecial = s;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GhsPictogramSelector(
            selectedCodes: _selectedGhsPictograms,
            onChanged: (codes) => setState(() => _selectedGhsPictograms = codes),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hazardStatementsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ข้อความแสดงความเป็นอันตราย (Hazard Statements - H-Codes)',
                    hintText: 'H225: ของเหลวและไอระเหยไวไฟสูง\nH315: ระคายเคืองต่อผิวหนัง',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _precautionaryStatementsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ข้อควรระวัง (Precautionary Statements - P-Codes)',
                    hintText: 'P210: เก็บให้ห่างจากความร้อน ประกายไฟ\nP280: สวมถุงมือและแว่นตานิรภัย',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๓: ส่วนประกอบและข้อมูลเกี่ยวกับส่วนผสม (Ingredients & Components)', Icons.pie_chart_outline_rounded),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รายการสารเคมีที่เป็นส่วนผสมในสารเดี่ยวหรือสารผสม:', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey.shade700)),
              TextButton.icon(
                onPressed: _addIngredientRow,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('เพิ่มส่วนประกอบ'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_ingredients.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text('ยังไม่มีรายการส่วนประกอบ (กดปุ่ม "เพิ่มส่วนประกอบ" เพื่อระบุส่วนผสม)', style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey.shade500)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final ing = _ingredients[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: ing.chemicalName,
                          decoration: const InputDecoration(labelText: 'ชื่อสารเคมีส่วนประกอบ', isDense: true, border: OutlineInputBorder()),
                          onChanged: (v) => _ingredients[idx] = ing.copyWith(chemicalName: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: ing.casNumber,
                          decoration: const InputDecoration(labelText: 'CAS No.', isDense: true, border: OutlineInputBorder()),
                          onChanged: (v) => _ingredients[idx] = ing.copyWith(casNumber: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: ing.percentage.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'สัดส่วน %wt', isDense: true, border: OutlineInputBorder()),
                          onChanged: (v) => _ingredients[idx] = ing.copyWith(percentage: double.tryParse(v) ?? 0.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => _removeIngredientRow(idx),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: Sections 4 - 7
  // --------------------------------------------------------------------------
  Widget _buildTab2FirstAidFireSpillStorage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('หมวด ๔: มาตรการปฐมพยาบาล (First-Aid Measures)', Icons.medical_services_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inhalationController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'กรณีสูดดม (Inhalation)', hintText: 'ย้ายผู้ป่วยไปยังที่อากาศบริสุทธิ์ ให้ออกซิเจนหากหายใจลำบาก', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _skinContactController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'กรณีสัมผัสผิวหนัง (Skin Contact)', hintText: 'ล้างออกทันทีด้วยน้ำสะอาดปริมาณมากอย่างน้อย 15 นาที', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _eyeContactController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'กรณีสัมผัสดวงตา (Eye Contact)', hintText: 'ล้างตาทันทีด้วยน้ำสะอาดอย่างน้อย 15 นาที เปิดเปลือกตาบนและล่าง', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ingestionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'กรณีกลืนกิน (Ingestion)', hintText: 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาดและนำส่งแพทย์ทันที', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๕: มาตรการผจญเพลิง (Fire-Fighting Measures)', Icons.local_fire_department_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _suitableMediaController,
                  decoration: const InputDecoration(labelText: 'สารดับเพลิงที่เหมาะสม', hintText: 'ผงเคมีแห้ง (Dry Chemical), คาร์บอนไดออกไซด์ (CO2), โฟมทนแอลกอฮอล์', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _unsuitableMediaController,
                  decoration: const InputDecoration(labelText: 'สารดับเพลิงที่ไม่เหมาะสม / ห้ามใช้', hintText: 'ห้ามใช้น้ำฉีดเป็นลำตรง (Water Jet)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _fireHazardsController,
                  decoration: const InputDecoration(labelText: 'อันตรายเฉพาะที่เกิดจากสารเคมี', hintText: 'ไอระเหยหนักกว่าอากาศ อาจไหลไปสู่แหล่งจุดติดไฟได้', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _protectiveEquipFireController,
                  decoration: const InputDecoration(labelText: 'อุปกรณ์ป้องกันสำหรับนักผจญเพลิง', hintText: 'ชุดผจญเพลิงเต็มรูปแบบ พร้อมเครื่องช่วยหายใจ SCBA', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๖: มาตรการจัดการเมื่อหกรั่วไหล (Accidental Release Measures)', Icons.cleaning_services_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _personalPrecautionsController,
                  decoration: const InputDecoration(labelText: 'ข้อควรระวังส่วนบุคคลและอุปกรณ์ป้องกัน', hintText: 'อพยพผู้ไม่เกี่ยวข้อง สวมชุดและหน้ากากป้องกัน กำจัดประกายไฟ', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _containmentCleanUpController,
                  decoration: const InputDecoration(labelText: 'วิธีการกักเก็บและทำความสะอาด', hintText: 'ดูดซับด้วยทรายแห้งหรือเวอร์มิคูไลท์ เก็บในภาชนะปิดสนิท', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๗: การขนถ่าย เคลื่อนย้าย และการจัดเก็บ (Handling & Storage)', Icons.warehouse_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _handlingPrecautionsController,
                  decoration: const InputDecoration(labelText: 'ข้อควรระวังในการขนถ่ายและการใช้งาน', hintText: 'ใช้งานในที่ที่มีการระบายอากาศดี ต่อสายดินป้องกันไฟฟ้าสถิต', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _storageConditionsController,
                  decoration: const InputDecoration(labelText: 'เงื่อนไขและสถานที่จัดเก็บ', hintText: 'เก็บในที่แห้ง เย็น อากาศถ่ายเท ห่างจากความร้อนและกรด', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: Sections 8 - 11
  // --------------------------------------------------------------------------
  Widget _buildTab3ExposurePhysicalToxicity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('หมวด ๘: การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล (Exposure Controls & PPE)', Icons.masks_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _exposureLimitsController,
                  decoration: const InputDecoration(labelText: 'ค่าขีดจำกัดความเข้มข้น (TLV-TWA / PEL)', hintText: 'TWA: 50 ppm, STEL: 100 ppm', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _engineeringControlsController,
                  decoration: const InputDecoration(labelText: 'การควบคุมทางวิศวกรรม', hintText: 'ระบบระบายอากาศเฉพาะที่ (Local Exhaust Ventilation)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _respiratoryProtectionController,
                  decoration: const InputDecoration(labelText: 'อุปกรณ์ป้องกันระบบหายใจ', hintText: 'หน้ากากไส้กรองไอระเหยสารอินทรีย์ (Organic Vapor)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _skinProtectionController,
                  decoration: const InputDecoration(labelText: 'การป้องกันผิวหนังและมือ', hintText: 'ถุงมือ Nitrile หรือ Neoprene เสื้อกาวน์ทนสารเคมี', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _eyeProtectionController,
                  decoration: const InputDecoration(labelText: 'การป้องกันดวงตาและใบหน้า', hintText: 'แว่นครอบตานิรภัย (Goggles) หรือกระบังหน้า', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๙: คุณสมบัติทางกายภาพและเคมี (Physical & Chemical Properties)', Icons.science_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _appearanceController,
                  decoration: const InputDecoration(labelText: 'ลักษณะภายนอก / สถานะ', hintText: 'ของเหลวใส ไม่มีสี', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _odorController,
                  decoration: const InputDecoration(labelText: 'กลิ่น', hintText: 'กลิ่นเฉพาะตัวคล้ายน้ำมันเบนซิน', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phValueController,
                  decoration: const InputDecoration(labelText: 'ค่า pH', hintText: 'N/A หรือ 6.5 - 7.5', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _boilingPointController,
                  decoration: const InputDecoration(labelText: 'จุดเดือด (°C)', hintText: '110.6 °C', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _flashPointController,
                  decoration: const InputDecoration(labelText: 'จุดวาบไฟ (°C)', hintText: '4.4 °C (Closed cup)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _relativeDensityController,
                  decoration: const InputDecoration(labelText: 'ความถ่วงจำเพาะ / ความหนาแน่น', hintText: '0.867 g/cm³', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๑๐ & ๑๑: ความเสถียร & ข้อมูลด้านพิษวิทยา (Stability & Toxicology)', Icons.biotech_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chemicalStabilityController,
                  decoration: const InputDecoration(labelText: 'ความคงตัวทางเคมี', hintText: 'เสถียรภายใต้สภาวะการจัดเก็บและการใช้งานปกติ', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _incompatibleMaterialsController,
                  decoration: const InputDecoration(labelText: 'สารที่เข้ากันไม่ได้', hintText: 'สารออกซิไดซ์เข้มข้น, กรดแก่, ฮาโลเจน', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _acuteToxicityController,
                  decoration: const InputDecoration(labelText: 'ความเป็นพิษเฉียบพลัน (LD50/LC50)', hintText: 'LD50 ทางปาก (หนู) = 5,580 mg/kg', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _carcinogenicityController,
                  decoration: const InputDecoration(labelText: 'การก่อมะเร็ง (IARC / ACGIH)', hintText: 'IARC Group 3 (ไม่จัดเป็นสารก่อมะเร็งในมนุษย์)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: Sections 12 - 16
  // --------------------------------------------------------------------------
  Widget _buildTab4EcologicalTransportRegulatory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('หมวด ๑๒ & ๑๓: ผลกระทบนิเวศน์ & การกำจัด (Ecological & Disposal)', Icons.eco_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ecotoxicityController,
                  decoration: const InputDecoration(labelText: 'ความเป็นพิษต่อระบบนิเวศน์ทางน้ำ', hintText: 'LC50 ปลา (96 ชม.) = 5.5 mg/L', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wasteTreatmentController,
                  decoration: const InputDecoration(labelText: 'วิธีกำจัดของเสียสารเคมี', hintText: 'เผาทำลายในเตาเผาขยะอันตรายที่ได้รับอนุญาตจากกรมโรงงานฯ', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๑๔: ข้อมูลการขนส่ง (Transport Information)', Icons.local_shipping_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _shippingNameController,
                  decoration: const InputDecoration(labelText: 'ชื่อที่ถูกต้องในการขนส่ง (Proper Shipping Name)', hintText: 'TOLUENE', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _transportHazardClassController,
                  decoration: const InputDecoration(labelText: 'Class ขนส่ง (Class 1-9)', hintText: 'Class 3 (ของเหลวไวไฟ)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _packingGroupController,
                  decoration: const InputDecoration(labelText: 'กลุ่มการบรรจุ (Packing Group)', hintText: 'PG II', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('หมวด ๑๕ & ๑๖: ข้อมูลกฎหมาย & ข้อมูลอื่นๆ (Regulatory & Other Info)', Icons.gavel_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _safetyHealthRegsController,
                  decoration: const InputDecoration(labelText: 'กฎหมายความปลอดภัยที่เกี่ยวข้อง', hintText: 'กฎกระทรวงสารเคมีอันตราย ๒๕๕๖, พ.ร.บ. วัตถุอันตราย', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _substanceTypeController,
                  decoration: const InputDecoration(labelText: 'ประเภทวัตถุอันตราย', hintText: 'วัตถุอันตรายชนิดที่ ๓ (กรมโรงงานอุตสาหกรรม)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _revisionDateController,
                  decoration: const InputDecoration(labelText: 'วันที่จัดทำ / ทบทวนล่าสุด (YYYY-MM-DD)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _versionNoController,
                  decoration: const InputDecoration(labelText: 'ครั้งที่แก้ไข (Revision)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _preparedByController,
                  decoration: const InputDecoration(labelText: 'ผู้จัดทำ / เจ้าหน้าที่ความปลอดภัย', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _isSaving ? 'กำลังบันทึก...' : 'บันทึกแบบ สอ.๑ (SDS 16 หัวข้อ)',
              style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
