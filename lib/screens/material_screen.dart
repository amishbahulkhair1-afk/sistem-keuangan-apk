import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class MaterialScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;

  const MaterialScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.selectedCategoryId,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MaterialItemModel> _materials = [];
  List<MaterialTransactionModel> _transactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _historyFilter = 'all'; // 'all', 'masuk', 'keluar'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MaterialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final mats = await widget.apiService.getMaterials(categoryId: widget.selectedCategoryId);
    final txs = await widget.apiService.getMaterialTransactions(categoryId: widget.selectedCategoryId);
    if (!mounted) return;
    setState(() {
      _materials = mats;
      _transactions = txs;
      _isLoading = false;
    });
  }

  void _showAddUsageDialog([int? preSelectedMaterialId]) {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Belum ada katalog material di pos ini'),
        ),
      );
      return;
    }

    int selectedMatId = preSelectedMaterialId ?? _materials.first.id;
    if (!_materials.any((m) => m.id == selectedMatId)) {
      selectedMatId = _materials.first.id;
    }

    final qtyController = TextEditingController();
    final usageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentMat = _materials.firstWhere((m) => m.id == selectedMatId, orElse: () => _materials.first);

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.handyman_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Catat Pemakaian Material',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedMatId,
                    decoration: InputDecoration(
                      labelText: 'Pilih Material Lapangan',
                      prefixIcon: const Icon(Icons.inventory_2_rounded, size: 20, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _materials.map((m) {
                      return DropdownMenuItem<int>(
                        value: m.id,
                        child: Text('${m.name} (Sisa: ${m.currentStock.toStringAsFixed(1)} ${m.unit})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMatId = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sisa Stok Tersedia:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          '${currentMat.currentStock.toStringAsFixed(1)} ${currentMat.unit}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: currentMat.currentStock <= 5 ? AppTheme.expense : AppTheme.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Jumlah Pemakaian (${currentMat.unit})',
                      hintText: 'Misal: 5',
                      prefixIcon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppTheme.expense),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: usageController,
                    decoration: InputDecoration(
                      labelText: 'Keperluan / Area Pengerjaan',
                      hintText: 'Misal: Pengecoran tiang selasar / perbaikan atap',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.glowShadow(AppTheme.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final qty = double.tryParse(qtyController.text) ?? 0.0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Masukkan jumlah pemakaian yang valid')),
                                  );
                                  return;
                                }
                                if (qty > currentMat.currentStock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Jumlah melebihi sisa stok (${currentMat.currentStock} ${currentMat.unit})')),
                                  );
                                  return;
                                }

                                setDialogState(() => isSubmitting = true);
                                final success = await widget.apiService.createMaterialTransaction(
                                  materialId: selectedMatId,
                                  categoryId: widget.selectedCategoryId ?? currentMat.categoryId,
                                  type: 'keluar',
                                  quantity: qty,
                                  usageFor: usageController.text.trim(),
                                );

                                if (!mounted) return;
                                Navigator.pop(ctx);

                                if (success) {
                                  _loadData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      content: Text('Pemakaian ${currentMat.name} berhasil dicatat!'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.expense,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      content: const Text('Gagal mencatat pemakaian material'),
                                    ),
                                  );
                                }
                              },
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  'Simpan Pemakaian',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProofDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Container(
                        height: 180,
                        color: AppTheme.surfaceMuted,
                        child: const Center(child: Text('Foto bukti tidak dapat dimuat')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = widget.categories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => widget.categories.isNotEmpty ? widget.categories.first : CategoryModel(id: 0, code: '-', name: 'Semua Pos'),
    );

    final totalMaterialValue = _materials.fold<double>(0.0, (s, m) => s + m.totalValue);
    final lowStockCount = _materials.where((m) => m.currentStock <= 5).length;

    final filteredMaterials = _materials.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) || m.code.toLowerCase().contains(q);
    }).toList();

    final filteredTransactions = _transactions.where((t) {
      if (_historyFilter == 'masuk') return t.isMasuk;
      if (_historyFilter == 'keluar') return !t.isMasuk;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logistik & Material Lapangan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.handyman_rounded, size: 20),
        label: Text('Catat Pemakaian', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
        onPressed: () => _showAddUsageDialog(),
      ),
      body: Column(
        children: [
          // Pos Header Banner & Asset Metric Card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Pos: [${currentCat.code}] ${currentCat.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (lowStockCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.expenseBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$lowStockCount Menipis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.expense,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Katalog Material', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              '${_materials.length} Macam',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimasi Nilai Aset', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(totalMaterialValue),
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Modern Segmented Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              labelColor: AppTheme.textMain,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(text: 'Katalog Stok (${_materials.length})'),
                Tab(text: 'Riwayat Mutasi (${_transactions.length})'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Tab Katalog Stok
                      _buildStockTab(filteredMaterials),

                      // 2. Tab Riwayat Mutasi
                      _buildHistoryTab(filteredTransactions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab(List<MaterialItemModel> list) {
    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textLight.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Belum ada katalog material di pos ini', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadData,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBF2)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kode material...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Material Items List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('Tidak ada material yang cocok dengan pencarian', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    itemCount: list.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = list[index];
                      final isLow = m.currentStock <= 5;
                      final double ratio = m.totalMasuk > 0 ? (m.currentStock / m.totalMasuk).clamp(0.0, 1.0) : 1.0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.hardware_rounded, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppTheme.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Kode: ${m.code} • Satuan: ${m.unit}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isLow ? AppTheme.expenseBg : AppTheme.incomeBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isLow ? AppTheme.expense.withValues(alpha: 0.2) : AppTheme.income.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '${m.currentStock.toStringAsFixed(1)} ${m.unit}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isLow ? AppTheme.expense : AppTheme.income,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Stock progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLow ? AppTheme.expense : AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Metric breakdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Masuk: +${m.totalMasuk.toStringAsFixed(1)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.income, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Pakai: -${m.totalKeluar.toStringAsFixed(1)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.expense, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Aset: ${Formatters.formatCurrency(m.totalValue)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Quick Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => _showAddUsageDialog(m.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.handyman_outlined, size: 14, color: AppTheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Catat Pakai',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<MaterialTransactionModel> list) {
    return Column(
      children: [
        // Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildHistoryFilterPill('Semua', 'all'),
              const SizedBox(width: 8),
              _buildHistoryFilterPill('Penerimaan (Masuk)', 'masuk'),
              const SizedBox(width: 8),
              _buildHistoryFilterPill('Pemakaian (Keluar)', 'keluar'),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Belum ada riwayat mutasi material', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    itemCount: list.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = list[index];
                      final isMasuk = tx.isMasuk;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMasuk ? AppTheme.incomeBg : AppTheme.expenseBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isMasuk ? Icons.add_shopping_cart_rounded : Icons.construction_rounded,
                                color: isMasuk ? AppTheme.income : AppTheme.expense,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${isMasuk ? '+' : '-'}${tx.quantity} ${tx.unit} ${tx.materialName}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isMasuk ? AppTheme.income : AppTheme.expense,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMasuk
                                        ? (tx.supplierOrSource != null && tx.supplierOrSource!.isNotEmpty
                                            ? 'Sumber: ${tx.supplierOrSource}'
                                            : 'Penerimaan / Drop Material')
                                        : (tx.usageFor != null && tx.usageFor!.isNotEmpty
                                            ? 'Untuk: ${tx.usageFor}'
                                            : 'Pemakaian Lapangan'),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  tx.tanggal,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                                ),
                                if (tx.buktiFoto != null && tx.buktiFoto!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  InkWell(
                                    onTap: () => _showProofDialog('${widget.apiService.authService.baseUrl}${tx.buktiFoto}', tx.materialName),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.receipt_rounded, size: 12, color: AppTheme.primary),
                                        Text(' Nota', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilterPill(String label, String value) {
    final isSelected = _historyFilter == value;
    return InkWell(
      onTap: () => setState(() => _historyFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.primary) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}
