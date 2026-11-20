import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/category_model.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class FormTransactionScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? initialCategoryId;
  final String initialType;

  const FormTransactionScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.initialCategoryId,
    this.initialType = 'income',
  });

  @override
  State<FormTransactionScreen> createState() => _FormTransactionScreenState();
}

class _FormTransactionScreenState extends State<FormTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _jenis;
  late int? _selectedCategoryId;
  String _metode = 'kas_tunai';
  final _nominalController = TextEditingController();
  final _namaPihakController = TextEditingController();
  final _keteranganController = TextEditingController();

  // --- Integrasi Belanja Material ---
  bool _isMaterialPurchase = false;
  bool _isNewMaterial = false;
  int? _selectedMaterialId;
  String _selectedUnit = 'Sak';
  List<MaterialItemModel> _existingMaterials = [];
  bool _isLoadingMaterials = false;
  static const List<String> _quickUnits = ['Sak', 'Batang', 'm³', 'Truk', 'Kg', 'Lembar', 'Pcs', 'Lainnya'];

  final _materialNameController = TextEditingController();
  final _materialBrandController = TextEditingController();
  final _materialQtyController = TextEditingController();
  final _materialPriceController = TextEditingController();
  final _customUnitController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _pickedImagePath;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _jenis = widget.initialType;
    _selectedCategoryId = widget.initialCategoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    if (_jenis == 'expense' && _selectedCategoryId != null) {
      _loadMaterials(_selectedCategoryId);
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _namaPihakController.dispose();
    _keteranganController.dispose();
    _materialNameController.dispose();
    _materialBrandController.dispose();
    _materialQtyController.dispose();
    _materialPriceController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials(int? catId) async {
    if (catId == null) return;
    setState(() => _isLoadingMaterials = true);
    final list = await widget.apiService.getMaterials(categoryId: catId);
    if (!mounted) return;
    setState(() {
      _existingMaterials = list;
      _isLoadingMaterials = false;
      if (list.isNotEmpty && _selectedMaterialId == null) {
        _selectedMaterialId = list.first.id;
        _selectedUnit = list.first.unit;
        if (list.first.unitPrice > 0 && _materialPriceController.text.isEmpty) {
          _materialPriceController.text = list.first.unitPrice.toInt().toString();
        }
        _recalculateMaterialTotal();
        _updateMaterialDesc();
      } else if (list.isEmpty) {
        _isNewMaterial = true;
      }
    });
  }

  void _recalculateMaterialTotal() {
    if (!_isMaterialPurchase) return;
    final qty = double.tryParse(_materialQtyController.text.replaceAll(',', '.')) ?? 0.0;
    final price = double.tryParse(_materialPriceController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    if (qty > 0 && price > 0) {
      final total = qty * price;
      _nominalController.text = total.toInt().toString();
    }
  }

  void _updateMaterialDesc() {
    if (!_isMaterialPurchase) return;
    String name = '';
    if (!_isNewMaterial && _selectedMaterialId != null) {
      final m = _existingMaterials.firstWhere((e) => e.id == _selectedMaterialId, orElse: () => _existingMaterials.first);
      name = m.name;
    } else {
      final rawName = _materialNameController.text.trim();
      final rawBrand = _materialBrandController.text.trim();
      name = rawBrand.isNotEmpty ? '$rawName $rawBrand' : rawName;
    }
    final qty = _materialQtyController.text.trim();
    final unit = _selectedUnit == 'Lainnya' ? _customUnitController.text.trim() : _selectedUnit;
    if (name.isNotEmpty) {
      final qtyStr = qty.isNotEmpty ? ' $qty $unit' : '';
      _keteranganController.text = 'Beli $name$qtyStr'.trim();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() {
        _pickedImagePath = file.path;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pos program terlebih dahulu')),
      );
      return;
    }

    if (_isMaterialPurchase && _jenis == 'expense') {
      if (!_isNewMaterial && _selectedMaterialId == null && _existingMaterials.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih material dari katalog pos')),
        );
        return;
      }
      if (_isNewMaterial && _materialNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama material baru wajib diisi')),
        );
        return;
      }
      final q = double.tryParse(_materialQtyController.text.replaceAll(',', '.')) ?? 0.0;
      if (q <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah kuantitas material harus lebih dari 0')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final nominal = double.tryParse(_nominalController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    bool success = false;

    if (_jenis == 'expense') {
      final qty = double.tryParse(_materialQtyController.text.replaceAll(',', '.')) ?? 1.0;
      final price = double.tryParse(_materialPriceController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      final unit = _selectedUnit == 'Lainnya'
          ? (_customUnitController.text.trim().isNotEmpty ? _customUnitController.text.trim() : 'Pcs')
          : _selectedUnit;

      success = await widget.apiService.createPosTransaction(
        categoryId: _selectedCategoryId!,
        transactionDate: dateStr,
        type: 'expense',
        categoryTxType: _isMaterialPurchase ? 'belanja_material' : 'operasional_lapangan',
        amount: nominal > 0 ? nominal : (qty * price),
        recipientOrSender: _namaPihakController.text.trim().isNotEmpty ? _namaPihakController.text.trim() : null,
        description: _keteranganController.text.trim().isNotEmpty ? _keteranganController.text.trim() : null,
        photoPath: _pickedImagePath,
        materialId: (_isMaterialPurchase && !_isNewMaterial) ? _selectedMaterialId : null,
        materialName: (_isMaterialPurchase && _isNewMaterial) ? _materialNameController.text.trim() : null,
        materialBrand: (_isMaterialPurchase && _isNewMaterial && _materialBrandController.text.trim().isNotEmpty)
            ? _materialBrandController.text.trim()
            : null,
        materialQuantity: _isMaterialPurchase ? qty : null,
        materialPrice: _isMaterialPurchase ? (price > 0 ? price : (nominal / (qty > 0 ? qty : 1.0))) : null,
        materialUnit: _isMaterialPurchase ? unit : null,
      );
    } else {
      success = await widget.apiService.createTransaction(
        tanggal: dateStr,
        jenis: _jenis,
        metode: _metode,
        categoryId: _selectedCategoryId!,
        nominal: nominal,
        keterangan: _keteranganController.text.trim(),
        namaDonatur: _namaPihakController.text.trim(),
        photoPath: _pickedImagePath,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final msg = (_jenis == 'expense' && _isMaterialPurchase)
          ? 'Belanja material berhasil dicatat! Kas pos berkurang & stok logistik otomatis bertambah.'
          : 'Transaksi berhasil dicatat ke sistem!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0D9488),
          content: Text(msg),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Gagal menyimpan transaksi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _jenis == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIncome ? 'Catat Kas Masuk (Donasi)' : 'Catat Kas Keluar (Belanja)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modern Segmented Control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _jenis = 'income';
                            _isMaterialPurchase = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isIncome ? AppTheme.cardShadow : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.south_west_rounded, size: 16, color: isIncome ? AppTheme.income : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Pemasukan (Masuk)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: isIncome ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12,
                                    color: isIncome ? AppTheme.income : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _jenis = 'expense';
                            if (_selectedCategoryId != null && _existingMaterials.isEmpty) {
                              _loadMaterials(_selectedCategoryId);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: !isIncome ? AppTheme.cardShadow : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.north_east_rounded, size: 16, color: !isIncome ? AppTheme.expense : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Pengeluaran (Keluar)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: !isIncome ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12,
                                    color: !isIncome ? AppTheme.expense : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Container
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tanggal Selector Row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanggal Transaksi', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDate(_selectedDate),
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pos Program Selector
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Pos Program / Akun Proyek'),
                      items: widget.categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text('[${c.code}] ${c.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          if (_isMaterialPurchase && val != null) {
                            _selectedMaterialId = null;
                            _loadMaterials(val);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // TOGGLE BELANJA MATERIAL (HANYA MUNCUL DI PENGELUARAN)
                    if (!isIncome) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isMaterialPurchase ? const Color(0xFFEFF6FF) : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isMaterialPurchase ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                            width: _isMaterialPurchase ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _isMaterialPurchase ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Belanja Material Proyek',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _isMaterialPurchase ? const Color(0xFF1E3A8A) : AppTheme.textMain,
                                          ),
                                        ),
                                        Text(
                                          'Otomatis tambah stok logistik',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: _isMaterialPurchase ? const Color(0xFF2563EB) : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _isMaterialPurchase,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (val) {
                                    setState(() {
                                      _isMaterialPurchase = val;
                                      if (val && _existingMaterials.isEmpty && _selectedCategoryId != null) {
                                        _loadMaterials(_selectedCategoryId);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),

                            if (_isMaterialPurchase) ...[
                              const Divider(height: 24),

                              // Toggle: Pilih Material vs Material Baru
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Center(
                                        child: Text(
                                          'Pilih Material Pos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: !_isNewMaterial ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      selected: !_isNewMaterial,
                                      selectedColor: const Color(0xFFDBEAFE),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _isNewMaterial = false;
                                            _updateMaterialDesc();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Center(
                                        child: Text(
                                          '+ Material Baru',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: _isNewMaterial ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      selected: _isNewMaterial,
                                      selectedColor: const Color(0xFFDBEAFE),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _isNewMaterial = true;
                                            _updateMaterialDesc();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (!_isNewMaterial) ...[
                                if (_isLoadingMaterials)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  )
                                else if (_existingMaterials.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade800),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Belum ada katalog material di pos ini. Silakan pilih tab "+ Material Baru" di atas.',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.amber.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: _selectedMaterialId,
                                    decoration: const InputDecoration(
                                      labelText: 'Pilih Material Lapangan',
                                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                                    ),
                                    items: _existingMaterials.map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m.id,
                                        child: Text('${m.name} (Stok: ${m.currentStock} ${m.unit})', overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedMaterialId = val;
                                        if (val != null) {
                                          final m = _existingMaterials.firstWhere((x) => x.id == val);
                                          _selectedUnit = m.unit;
                                          if (m.unitPrice > 0 && _materialPriceController.text.isEmpty) {
                                            _materialPriceController.text = m.unitPrice.toInt().toString();
                                          }
                                          _recalculateMaterialTotal();
                                          _updateMaterialDesc();
                                        }
                                      });
                                    },
                                  ),
                              ] else ...[
                                TextFormField(
                                  controller: _materialNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Material Baru',
                                    hintText: 'Misal: Semen Gresik 50kg, Besi 10mm',
                                    prefixIcon: Icon(Icons.add_shopping_cart_rounded, size: 20),
                                  ),
                                  onChanged: (_) => _updateMaterialDesc(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _materialBrandController,
                                  decoration: const InputDecoration(
                                    labelText: 'Merek / Spesifikasi (Opsional)',
                                    hintText: 'Misal: Gresik / SNI / Holcim',
                                    prefixIcon: Icon(Icons.branding_watermark_rounded, size: 20),
                                  ),
                                  onChanged: (_) => _updateMaterialDesc(),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Pilih Satuan Barang',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _quickUnits.map((u) {
                                    final isSelected = _selectedUnit == u;
                                    return ChoiceChip(
                                      label: Text(u, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFFDBEAFE),
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() {
                                            _selectedUnit = u;
                                            _updateMaterialDesc();
                                          });
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                                if (_selectedUnit == 'Lainnya') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _customUnitController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ketik Satuan Lainnya',
                                      hintText: 'Misal: Roll, Drum, Lembar',
                                    ),
                                    onChanged: (_) => _updateMaterialDesc(),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 14),

                              // Kuantitas & Harga Satuan Row
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      controller: _materialQtyController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Jumlah (${_selectedUnit == 'Lainnya' ? (_customUnitController.text.isNotEmpty ? _customUnitController.text : 'Unit') : _selectedUnit})',
                                        hintText: 'Misal: 10',
                                      ),
                                      onChanged: (_) {
                                        _recalculateMaterialTotal();
                                        _updateMaterialDesc();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 6,
                                    child: TextFormField(
                                      controller: _materialPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Harga Satuan (Rp)',
                                        prefixText: 'Rp ',
                                        hintText: 'Misal: 65.000',
                                      ),
                                      onChanged: (_) => _recalculateMaterialTotal(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Nominal Field
                    TextFormField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: _isMaterialPurchase ? 'Total Belanja Material (Rp)' : 'Nominal Transaksi (Rp)',
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        helperText: _isMaterialPurchase ? 'Otomatis dihitung dari (Jumlah × Harga Satuan)' : null,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nominal wajib diisi';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Metode Akun Selector
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _metode,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                      items: const [
                        DropdownMenuItem(value: 'kas_tunai', child: Text('Kas Tunai Lapangan', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'bank_bni', child: Text('Transfer Bank (BNI / Rekening)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'piutang', child: Text('Talangan / Piutang', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setState(() => _metode = val ?? 'kas_tunai'),
                    ),

                    const SizedBox(height: 16),

                    // Nama Donatur / Penerima / Toko
                    TextFormField(
                      controller: _namaPihakController,
                      decoration: InputDecoration(
                        labelText: isIncome
                            ? 'Nama Donatur / Pengirim'
                            : (_isMaterialPurchase ? 'Nama Toko / Supplier Bangunan' : 'Penerima Dana / Nama Toko'),
                        hintText: isIncome
                            ? 'Hamba Allah'
                            : (_isMaterialPurchase ? 'Toko Bangunan Berkah / TB Maju' : 'Toko Besi / Mandor Tukang'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Keterangan
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Keterangan Transaksi',
                        hintText: _isMaterialPurchase
                            ? 'Otomatis terisi nama material & kuantitas'
                            : 'Misal: Konsumsi tukang, pembelian paku',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lampiran Foto Bukti Nota
                    Text(
                      'Foto Bukti / Nota Transaksi',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 10),

                    if (_pickedImagePath != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_pickedImagePath!),
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: InkWell(
                              onTap: () => setState(() => _pickedImagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primary),
                            label: Text('Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppTheme.primary),
                            label: Text('Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: isIncome ? AppTheme.primaryGradient : const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.glowShadow(isIncome ? AppTheme.primary : AppTheme.expense),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isLoading ? null : _submit,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              'Simpan Transaksi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
