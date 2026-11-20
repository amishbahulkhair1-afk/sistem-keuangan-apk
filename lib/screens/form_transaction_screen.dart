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
  late String _categoryTxType;
  late int? _selectedCategoryId;
  String _metode = 'kas_tunai';
  final _nominalController = TextEditingController();
  final _namaPihakController = TextEditingController();
  final _keteranganController = TextEditingController();

  // --- Kategori Aliran Kas Keluar (Relasi Neraca Aktiva / Biaya) ---
  static const List<Map<String, dynamic>> _expenseCategories = [
    {
      'value': 'belanja_material',
      'label': 'Belanja Material Proyek',
      'badge': 'Aktiva Persediaan',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF0081A7),
      'desc': 'Masuk stok logistik gudang & persediaan aset di neraca',
    },
    {
      'value': 'upah_tukang',
      'label': 'Upah Tenaga Kerja & Tukang',
      'badge': 'Biaya / Beban',
      'icon': Icons.engineering_rounded,
      'color': Color(0xFFF59E0B),
      'desc': 'Ongkos tukang harian, borongan, atau mandor lapangan',
    },
    {
      'value': 'operasional_lapangan',
      'label': 'Operasional & Konsumsi Lapangan',
      'badge': 'Biaya / Beban',
      'icon': Icons.coffee_rounded,
      'color': Color(0xFF10B981),
      'desc': 'Konsumsi tukang, bahan bakar, dan kebutuhan operasional',
    },
    {
      'value': 'sewa_alat',
      'label': 'Sewa Alat & Mesin Proyek',
      'badge': 'Biaya / Beban',
      'icon': Icons.construction_rounded,
      'color': Color(0xFF6366F1),
      'desc': 'Sewa molen cor, scaffolding, atau armada angkut',
    },
    {
      'value': 'hutang_bayar',
      'label': 'Pelunasan Hutang ke Toko/Supplier',
      'badge': 'Passiva Kewajiban',
      'icon': Icons.payment_rounded,
      'color': Color(0xFFEF4444),
      'desc': 'Otomatis mengurangi catatan kewajiban hutang aktif di pos',
    },
    {
      'value': 'piutang_pinjam',
      'label': 'Pemberian Pinjaman / Talangan',
      'badge': 'Aktiva Piutang',
      'icon': Icons.handshake_rounded,
      'color': Color(0xFF8B5CF6),
      'desc': 'Dana ditalangkan / dipinjamkan ke pihak luar',
    },
    {
      'value': 'biaya_umum',
      'label': 'Biaya Administrasi & Umum Pos',
      'badge': 'Biaya / Beban',
      'icon': Icons.description_rounded,
      'color': Color(0xFF64748B),
      'desc': 'ATK, pelaporan, atau biaya umum pos lapangan',
    },
  ];

  // --- Kategori Aliran Kas Masuk (Relasi Neraca Passiva / Sumber Dana) ---
  static const List<Map<String, dynamic>> _incomeCategories = [
    {
      'value': 'donasi_langsung',
      'label': 'Donasi / Infaq Langsung di Pos',
      'badge': 'Sumber Dana',
      'icon': Icons.volunteer_activism_rounded,
      'color': Color(0xFF00AA13),
      'desc': 'Infaq tunai / transfer langsung dari donatur ke pos lapangan',
    },
    {
      'value': 'alokasi_pusat',
      'label': 'Drop / Alokasi Dana dari Pusat',
      'badge': 'Sumber Dana',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF0081A7),
      'desc': 'Penerimaan droping dana dari rekening bendahara pusat',
    },
    {
      'value': 'hutang_pinjam',
      'label': 'Pinjaman Baru (Hutang Pos)',
      'badge': 'Kewajiban',
      'icon': Icons.move_to_inbox_rounded,
      'color': Color(0xFFEF4444),
      'desc': 'Meminjam dana / talangan dari pihak luar atau toko',
    },
    {
      'value': 'piutang_bayar',
      'label': 'Penerimaan Pelunasan Piutang',
      'badge': 'Pengembalian Piutang',
      'icon': Icons.price_check_rounded,
      'color': Color(0xFF10B981),
      'desc': 'Pihak luar mengembalikan dana talangan / piutang',
    },
  ];

  bool get _isMaterialPurchase => _jenis == 'expense' && _categoryTxType == 'belanja_material';

  // --- Integrasi Belanja Material ---
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
    _categoryTxType = _jenis == 'income' ? 'donasi_langsung' : 'belanja_material';
    _selectedCategoryId = widget.initialCategoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);

    if (_isMaterialPurchase && _selectedCategoryId != null) {
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

    if (_isMaterialPurchase) {
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
        categoryTxType: _categoryTxType,
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
      success = await widget.apiService.createPosTransaction(
        categoryId: _selectedCategoryId!,
        transactionDate: dateStr,
        type: 'income',
        categoryTxType: _categoryTxType,
        amount: nominal,
        recipientOrSender: _namaPihakController.text.trim().isNotEmpty ? _namaPihakController.text.trim() : null,
        description: _keteranganController.text.trim().isNotEmpty ? _keteranganController.text.trim() : null,
        photoPath: _pickedImagePath,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      String msg;
      if (_isMaterialPurchase) {
        msg = 'Belanja material dicatat! Kas berkurang & persediaan logistik otomatis bertambah di Neraca.';
      } else if (_categoryTxType == 'hutang_bayar') {
        msg = 'Pelunasan hutang dicatat! Sisa hutang di modul Hutang otomatis berkurang.';
      } else if (_categoryTxType == 'piutang_pinjam') {
        msg = 'Pemberian talangan/piutang dicatat di modul Piutang & Neraca.';
      } else {
        msg = 'Transaksi kas berhasil dicatat dan masuk ke Neraca!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.primary,
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

  String _getCurrentCategoryDesc() {
    final list = _jenis == 'income' ? _incomeCategories : _expenseCategories;
    final item = list.firstWhere((e) => e['value'] == _categoryTxType, orElse: () => list.first);
    return item['desc'] as String;
  }

  String _getPihakLabel() {
    if (_jenis == 'income') {
      switch (_categoryTxType) {
        case 'donasi_langsung':
          return 'Nama Donatur / Pihak Pemberi';
        case 'alokasi_pusat':
          return 'Sumber Transfer / Alokasi Pusat';
        case 'hutang_pinjam':
          return 'Nama Pihak Pemberi Pinjaman / Toko';
        case 'piutang_bayar':
          return 'Nama Pihak yang Mengembalikan Piutang';
        default:
          return 'Nama Pihak Donatur / Pengirim';
      }
    } else {
      switch (_categoryTxType) {
        case 'belanja_material':
          return 'Nama Toko Bangunan / Supplier';
        case 'upah_tukang':
          return 'Nama Mandor / Tenaga Kerja';
        case 'operasional_lapangan':
          return 'Penyedia / Toko Konsumsi Lapangan';
        case 'sewa_alat':
          return 'Penyedia Sewa Alat & Mesin';
        case 'hutang_bayar':
          return 'Nama Toko / Kreditur yang Dilunasi';
        case 'piutang_pinjam':
          return 'Nama Peminjam / Pihak yang Ditalangi';
        case 'biaya_umum':
          return 'Penerima Pembayaran Administrasi';
        default:
          return 'Penerima Dana / Nama Pihak';
      }
    }
  }

  String _getPihakHint() {
    if (_jenis == 'income') {
      switch (_categoryTxType) {
        case 'donasi_langsung':
          return 'Misal: Hamba Allah / H. Sulaiman';
        case 'alokasi_pusat':
          return 'Misal: Droping Kas Yayasan BNI Pusat';
        case 'hutang_pinjam':
          return 'Misal: TB. Hidayah (Pinjaman baru)';
        case 'piutang_bayar':
          return 'Misal: Mandor Sholeh (Pelunasan)';
        default:
          return 'Misal: Donatur / Pihak luar';
      }
    } else {
      switch (_categoryTxType) {
        case 'belanja_material':
          return 'Misal: TB. Berkah / Toko Besi Jaya';
        case 'upah_tukang':
          return 'Misal: Mandor Sholeh (Minggu ke-2)';
        case 'operasional_lapangan':
          return 'Misal: Warung Bu Siti / SPBU';
        case 'sewa_alat':
          return 'Misal: Rental Molen Mandiri (3 Hari)';
        case 'hutang_bayar':
          return 'Misal: Toko Berkah (Otomatis potong hutang)';
        case 'piutang_pinjam':
          return 'Misal: Pak Syarif (Otomatis catat piutang)';
        case 'biaya_umum':
          return 'Misal: Fotokopi laporan / ATK pos';
        default:
          return 'Misal: Nama pihak penerima';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _jenis == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIncome ? 'Catat Kas Masuk Pos' : 'Catat Kas Keluar Pos',
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
                            _categoryTxType = 'donasi_langsung';
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
                                  'Kas Masuk',
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
                            _categoryTxType = 'belanja_material';
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
                                  'Kas Keluar',
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
                  border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
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

                    // DROPDOWN KATEGORI ALIRAN KAS (BERELASI KE NERACA)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _categoryTxType,
                      decoration: InputDecoration(
                        labelText: isIncome
                            ? 'Kategori Aliran Kas Masuk (Sumber Dana)'
                            : 'Kategori Aliran Kas Keluar (Pos Neraca / Biaya)',
                        prefixIcon: const Icon(Icons.account_tree_rounded, size: 20, color: AppTheme.primary),
                      ),
                      items: (isIncome ? _incomeCategories : _expenseCategories).map((c) {
                        return DropdownMenuItem<String>(
                          value: c['value'] as String,
                          child: Row(
                            children: [
                              Icon(c['icon'] as IconData, size: 16, color: c['color'] as Color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (c['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c['badge'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: c['color'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _categoryTxType = val;
                            if (_isMaterialPurchase && _selectedCategoryId != null && _existingMaterials.isEmpty) {
                              _loadMaterials(_selectedCategoryId);
                            }
                          });
                        }
                      },
                    ),

                    // Kapsul Keterangan Akun Neraca
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getCurrentCategoryDesc(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SECTION FORM BELANJA MATERIAL (MUNCUL OTOMATIS SAAT KATEGORI MATERIAL DIPILIH)
                    if (_isMaterialPurchase) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2_rounded, size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rincian Belanja Material Proyek',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Segment: Pilih Material vs Material Baru
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: Center(
                                      child: Text(
                                        'Pilih Katalog Pos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: !_isNewMaterial ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    selected: !_isNewMaterial,
                                    selectedColor: AppTheme.primaryLight,
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
                                    selectedColor: AppTheme.primaryLight,
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
                                    selectedColor: AppTheme.primaryLight,
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
                        labelText: _getPihakLabel(),
                        hintText: _getPihakHint(),
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
                            : 'Misal: Ongkos tukang selasar, pembelian konsumsi rapat',
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
