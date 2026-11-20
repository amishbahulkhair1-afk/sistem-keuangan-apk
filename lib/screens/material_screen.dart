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

  void _showAddUsageDialog() {
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada katalog material di pos ini')),
      );
      return;
    }

    int selectedMatId = _materials.first.id;
    final qtyController = TextEditingController();
    final usageController = TextEditingController();

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
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Catat Pemakaian Material',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedMatId,
                    decoration: const InputDecoration(labelText: 'Pilih Material Lapangan'),
                    items: _materials.map((m) {
                      return DropdownMenuItem<int>(
                        value: m.id,
                        child: Text('${m.name} (Sisa: ${m.currentStock} ${m.unit})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMatId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Pemakaian (${currentMat.unit})',
                      hintText: 'Misal: 10',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usageController,
                    decoration: const InputDecoration(
                      labelText: 'Keperluan / Area Pengerjaan',
                      hintText: 'Misal: Pengecoran dak lantai 2 / plester',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.glowShadow(AppTheme.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final qty = double.tryParse(qtyController.text) ?? 0.0;
                          if (qty <= 0) return;
                          Navigator.pop(ctx);

                          final success = await widget.apiService.createMaterialTransaction(
                            materialId: selectedMatId,
                            categoryId: widget.selectedCategoryId ?? currentMat.categoryId,
                            type: 'keluar',
                            quantity: qty,
                            usageFor: usageController.text.trim(),
                          );

                          if (!mounted) return;
                          if (success) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Text('Pemakaian ${currentMat.name} berhasil dicatat!'),
                              ),
                            );
                          }
                        },
                        child: Center(
                          child: Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logistik & Material Lapangan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.handyman_rounded, size: 20),
        label: Text('Catat Pakai', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        onPressed: _showAddUsageDialog,
      ),
      body: Column(
        children: [
          // Modern Segmented Tab
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              tabs: const [
                Tab(text: 'Katalog Stok'),
                Tab(text: 'Riwayat Mutasi'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Tab Stok
                      _materials.isEmpty
                          ? Center(
                              child: Text('Belum ada katalog material di pos ini',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                            )
                          : RefreshIndicator(
                              color: AppTheme.primary,
                              onRefresh: _loadData,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _materials.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final m = _materials[index];
                                  final isLow = m.currentStock <= 5;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                      boxShadow: AppTheme.cardShadow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                m.name,
                                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isLow ? AppTheme.expenseBg : AppTheme.incomeBg,
                                                borderRadius: BorderRadius.circular(20),
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
                                        const SizedBox(height: 6),
                                        Text(
                                          'Kode: ${m.code} • Estimasi: ${Formatters.formatCurrency(m.unitPrice)}/${m.unit}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceMuted,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Masuk: +${m.totalMasuk} ${m.unit}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.income, fontWeight: FontWeight.w600)),
                                              Text('Pakai: -${m.totalKeluar} ${m.unit}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.expense, fontWeight: FontWeight.w600)),
                                              Text('Aset: ${Formatters.formatCurrency(m.totalValue)}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                      // 2. Tab Riwayat Mutasi
                      _transactions.isEmpty
                          ? Center(
                              child: Text('Belum ada mutasi material',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                            )
                          : RefreshIndicator(
                              color: AppTheme.primary,
                              onRefresh: _loadData,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _transactions.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  final isMasuk = tx.isMasuk;

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                      boxShadow: AppTheme.cardShadow,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMasuk ? AppTheme.incomeBg : AppTheme.warningBg,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            isMasuk ? Icons.add_shopping_cart_rounded : Icons.construction_rounded,
                                            color: isMasuk ? AppTheme.income : AppTheme.warning,
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
                                                    ? (tx.supplierOrSource != null ? 'Dari: ${tx.supplierOrSource}' : 'Penerimaan Material')
                                                    : (tx.usageFor != null ? 'Untuk: ${tx.usageFor}' : 'Pemakaian Lapangan'),
                                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          tx.tanggal,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textLight),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
