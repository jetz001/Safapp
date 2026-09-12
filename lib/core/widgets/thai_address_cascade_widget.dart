import 'package:flutter/material.dart';
import '../data/thai_address_data.dart';

class ThaiAddressCascadeWidget extends StatefulWidget {
  final TextEditingController addressNumberController;
  final TextEditingController mooController;
  final TextEditingController soiController;
  final TextEditingController roadController;
  final TextEditingController subdistrictController;
  final TextEditingController districtController;
  final TextEditingController provinceController;
  final TextEditingController postalCodeController;
  final TextEditingController? phoneController;
  final TextEditingController? faxController;
  final TextEditingController? mobileController;
  final bool showContactFields;
  final bool showCountry;

  const ThaiAddressCascadeWidget({
    super.key,
    required this.addressNumberController,
    required this.mooController,
    required this.soiController,
    required this.roadController,
    required this.subdistrictController,
    required this.districtController,
    required this.provinceController,
    required this.postalCodeController,
    this.phoneController,
    this.faxController,
    this.mobileController,
    this.showContactFields = true,
    this.showCountry = true,
  });

  @override
  State<ThaiAddressCascadeWidget> createState() => _ThaiAddressCascadeWidgetState();
}

class _ThaiAddressCascadeWidgetState extends State<ThaiAddressCascadeWidget> {
  String _selectedCountry = 'ประเทศไทย (Thailand)';

  List<String> _districts = [];
  List<String> _subdistricts = [];

  @override
  void initState() {
    super.initState();
    _updateCascades();
    widget.provinceController.addListener(_onExternalAddressChanged);
  }

  @override
  void dispose() {
    widget.provinceController.removeListener(_onExternalAddressChanged);
    super.dispose();
  }

  void _onExternalAddressChanged() {
    if (mounted) {
      _updateCascades();
    }
  }

  void _updateCascades() {
    final prov = widget.provinceController.text.trim();
    final dist = widget.districtController.text.trim();

    if (prov.isNotEmpty) {
      _districts = ThaiAddressRepository.getDistricts(prov);
    } else {
      _districts = [];
    }

    if (prov.isNotEmpty && dist.isNotEmpty) {
      _subdistricts = ThaiAddressRepository.getSubdistricts(prov, dist);
    } else {
      _subdistricts = [];
    }
    setState(() {});
  }

  void _onProvinceSelected(String? province) {
    if (province == null) return;
    setState(() {
      widget.provinceController.text = province;
      widget.districtController.clear();
      widget.subdistrictController.clear();
      widget.postalCodeController.clear();

      _districts = ThaiAddressRepository.getDistricts(province);
      _subdistricts = [];
    });
  }

  void _onDistrictSelected(String? district) {
    if (district == null) return;
    final prov = widget.provinceController.text.trim();
    setState(() {
      widget.districtController.text = district;
      widget.subdistrictController.clear();
      widget.postalCodeController.clear();

      _subdistricts = ThaiAddressRepository.getSubdistricts(prov, district);
    });
  }

  void _onSubdistrictSelected(String? subdistrict) {
    if (subdistrict == null) return;
    final prov = widget.provinceController.text.trim();
    final dist = widget.districtController.text.trim();

    setState(() {
      widget.subdistrictController.text = subdistrict;

      // Auto-lookup Zip Code
      final zip = ThaiAddressRepository.getZipCode(prov, dist, subdistrict);
      if (zip != null) {
        widget.postalCodeController.text = zip;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentProv = widget.provinceController.text.trim();
    final currentDist = widget.districtController.text.trim();
    final currentSubdist = widget.subdistrictController.text.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 580;

        final provinceField = DropdownButtonFormField<String>(
          isExpanded: true,
          value: ThaiAddressRepository.provinces.contains(currentProv) ? currentProv : null,
          decoration: _inputDecoration('จังหวัด (Province) *', icon: Icons.flag),
          items: ThaiAddressRepository.provinces.map((p) {
            return DropdownMenuItem<String>(
              value: p,
              child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: _onProvinceSelected,
        );

        final districtList = List<String>.from(_districts);
        if (currentDist.isNotEmpty && !districtList.contains(currentDist)) {
          districtList.add(currentDist);
        }

        final districtField = districtList.isNotEmpty
            ? DropdownButtonFormField<String>(
                isExpanded: true,
                value: districtList.contains(currentDist) ? currentDist : null,
                decoration: _inputDecoration('อำเภอ / เขต *', icon: Icons.map),
                items: districtList.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: _onDistrictSelected,
              )
            : TextFormField(
                controller: widget.districtController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration('อำเภอ / เขต', icon: Icons.map, hint: 'กรุณาเลือกจังหวัดก่อน'),
                onChanged: (v) => _updateCascades(),
              );

        final subdistrictList = List<String>.from(_subdistricts);
        if (currentSubdist.isNotEmpty && !subdistrictList.contains(currentSubdist)) {
          subdistrictList.add(currentSubdist);
        }

        final subdistrictField = subdistrictList.isNotEmpty
            ? DropdownButtonFormField<String>(
                isExpanded: true,
                value: subdistrictList.contains(currentSubdist) ? currentSubdist : null,
                decoration: _inputDecoration('ตำบล / แขวง *', icon: Icons.location_city),
                items: subdistrictList.map((sd) {
                  return DropdownMenuItem<String>(
                    value: sd,
                    child: Text(sd, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: _onSubdistrictSelected,
              )
            : TextFormField(
                controller: widget.subdistrictController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration('ตำบล / แขวง', icon: Icons.location_city, hint: 'กรุณาเลือกอำเภอก่อน'),
                onChanged: (v) => _updateCascades(),
              );

        final postalCodeField = TextFormField(
          controller: widget.postalCodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
          decoration: _inputDecoration('รหัสไปรษณีย์', icon: Icons.markunread_mailbox, hint: 'Auto-fill'),
        );

        final addressNoField = TextFormField(
          controller: widget.addressNumberController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('เลขที่', icon: Icons.home),
        );

        final mooField = TextFormField(
          controller: widget.mooController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('หมู่ที่', icon: Icons.holiday_village),
        );

        final soiField = TextFormField(
          controller: widget.soiController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('ตรอก / ซอย', icon: Icons.signpost),
        );

        final roadField = TextFormField(
          controller: widget.roadController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('ถนน', icon: Icons.add_road),
        );

        final phoneField = TextFormField(
          controller: widget.phoneController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('โทรศัพท์', icon: Icons.phone),
        );

        final faxField = TextFormField(
          controller: widget.faxController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('โทรสาร', icon: Icons.fax),
        );

        final mobileField = TextFormField(
          controller: widget.mobileController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration('โทรศัพท์มือถือ', icon: Icons.phone_android),
        );

        final countryField = DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedCountry,
          decoration: _inputDecoration('ประเทศ (Country)', icon: Icons.public),
          items: const [
            DropdownMenuItem(
              value: 'ประเทศไทย (Thailand)',
              child: Text('ประเทศไทย (Thailand)', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedCountry = v);
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. ค้นหาด่วน (Quick Address Autocomplete: ลดขั้นตอนการเลือก จังหวัด/อำเภอ/ตำบล/รหัสไปรษณีย์ ให้เหลือขั้นตอนเดียว)
            _buildQuickSearchField(),
            const SizedBox(height: 12),

            // 1. ประเทศ (แสดงเฉพาะเมื่อเปิดใช้งาน)
            if (widget.showCountry) ...[
              if (isCompact)
                countryField
              else
                Row(
                  children: [
                    SizedBox(width: 280, child: countryField),
                  ],
                ),
              const SizedBox(height: 12),
            ],

            // 2. จังหวัด / อำเภอ / ตำบล / รหัสไปรษณีย์
            if (isCompact) ...[
              Row(
                children: [
                  Expanded(child: provinceField),
                  const SizedBox(width: 8),
                  Expanded(child: districtField),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: subdistrictField),
                  const SizedBox(width: 8),
                  Expanded(child: postalCodeField),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(flex: 3, child: provinceField),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: districtField),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: subdistrictField),
                  const SizedBox(width: 8),
                  SizedBox(width: 130, child: postalCodeField),
                ],
              ),
            const SizedBox(height: 12),

            // 3. เลขที่ / หมู่ / ซอย / ถนน
            if (isCompact) ...[
              Row(
                children: [
                  Expanded(child: addressNoField),
                  const SizedBox(width: 8),
                  Expanded(child: mooField),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: soiField),
                  const SizedBox(width: 8),
                  Expanded(child: roadField),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(flex: 2, child: addressNoField),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: mooField),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: soiField),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: roadField),
                ],
              ),

            // 4. โทรศัพท์ / โทรสาร / มือถือ (ถ้าเปิดใช้งาน)
            if (widget.showContactFields && (widget.phoneController != null || widget.mobileController != null)) ...[
              const SizedBox(height: 12),
              if (isCompact) ...[
                Row(
                  children: [
                    Expanded(child: phoneField),
                    const SizedBox(width: 8),
                    Expanded(child: faxField),
                  ],
                ),
                const SizedBox(height: 10),
                mobileField,
              ] else
                Row(
                  children: [
                    Expanded(child: phoneField),
                    const SizedBox(width: 8),
                    Expanded(child: faxField),
                    const SizedBox(width: 8),
                    Expanded(child: mobileField),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuickSearchField() {
    return Autocomplete<ThaiAddressModel>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<ThaiAddressModel>.empty();
        }
        return ThaiAddressRepository.searchAddress(textEditingValue.text);
      },
      displayStringForOption: (ThaiAddressModel option) =>
          '${option.subdistrict.isNotEmpty ? "ต.${option.subdistrict} " : ""}อ.${option.district} จ.${option.province} ${option.zipCode}'.trim(),
      onSelected: (ThaiAddressModel selection) {
        setState(() {
          widget.provinceController.text = selection.province;
          widget.districtController.text = selection.district;
          widget.subdistrictController.text = selection.subdistrict;
          if (selection.zipCode.isNotEmpty) {
            widget.postalCodeController.text = selection.zipCode;
          }
          _updateCascades();
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: '⚡ ค้นหาด่วน: ตำบล / อำเภอ / จังหวัด / รหัสไปรษณีย์ (คลิกเลือกเพื่อกรอกครบอัตโนมัติ)',
              labelStyle: const TextStyle(color: Color(0xFF4338CA), fontSize: 12, fontWeight: FontWeight.bold),
              hintText: 'พิมพ์ เช่น ปากน้ำ, 10270, บางพลี, เมือง นนทบุรี, ศรีราชา...',
              hintStyle: TextStyle(color: Colors.indigo.shade300, fontSize: 12),
              prefixIcon: const Icon(Icons.flash_on_rounded, color: Color(0xFF4F46E5), size: 20),
              suffixIcon: textEditingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Color(0xFF6366F1)),
                      onPressed: () => textEditingController.clear(),
                    )
                  : null,
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5), size: 18),
                    title: Text(
                      '${option.subdistrict.isNotEmpty ? "ต.${option.subdistrict} " : ""}อ.${option.district} จ.${option.province}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: option.zipCode.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Text(option.zipCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                          )
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.7),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }
}
