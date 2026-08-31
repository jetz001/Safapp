import 'package:flutter/material.dart';
import '../../domain/models/chemical_master_model.dart';
import '../../data/datasources/chemical_1516_master_data.dart';

/// Autocomplete Search Field for looking up chemicals from the 1,516 statutory master list.
/// Supports search by Thai Name, English Name, CAS Number, and Seq No with sub-50ms latency.
class ChemicalAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<ChemicalMasterItem> onSelected;
  final String labelText;
  final String hintText;
  final bool isRequired;

  const ChemicalAutocompleteField({
    Key? key,
    this.initialValue,
    required this.onSelected,
    this.labelText = 'ค้นหาและเลือกสารเคมีอันตราย (1,516 รายการ)',
    this.hintText = 'พิมพ์ชื่อภาษาไทย, English หรือ CAS No. เช่น Toluene, 108-88-3, กรดเกลือ...',
    this.isRequired = true,
  }) : super(key: key);

  @override
  State<ChemicalAutocompleteField> createState() => _ChemicalAutocompleteFieldState();
}

class _ChemicalAutocompleteFieldState extends State<ChemicalAutocompleteField> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<ChemicalMasterItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue ?? '');
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _search(_textController.text);
      } else {
        _removeOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChemicalAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && widget.initialValue != _textController.text && !_focusNode.hasFocus) {
      _textController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    final results = Chemical1516MasterData.search(query, limit: 20);
    setState(() {
      _suggestions = results;
    });

    if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 6.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1.2),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return InkWell(
                    onTap: () {
                      _textController.text = '${item.thaiName} (${item.englishName})';
                      widget.onSelected(item);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${item.sequenceNo}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.thaiName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.englishName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'CAS: ${item.casNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        onChanged: _search,
        validator: widget.isRequired
            ? (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุหรือเลือกสารเคมี' : null
            : null,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _textController.clear();
                    _search('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.8),
          ),
        ),
      ),
    );
  }
}
