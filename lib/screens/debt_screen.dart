import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class DebtScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;

  const DebtScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.selectedCategoryId,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DebtPartyRecap> _hutangList = [];
  List<DebtPartyRecap> _piutangList = [];
  List<DebtTransactionModel> _transactions = [];
  double _totalHutang = 0.0;
  double _totalPiutang = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DebtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recap = await widget.apiService.getDebtsRecap(categoryId: widget.selectedCategoryId);
    final txs = await widget.apiService.getDebts(categoryId: widget.selectedCategoryId);
    if (!mounted) return;
    setState(() {
      _hutangList = recap['hutang_list'] ?? [];
      _piutangList = recap['piutang_list'] ?? [];
      _totalHutang = recap['total_sisa_hutang'] ?? 0.0;
      _totalPiutang = recap['total_sisa_piutang'] ?? 0.0;
      _transactions = txs;
      _isLoading = false;
    });
  }

  void _showAddDebtDialog() {
    String type = 'hutang_pinjam';
    final partyController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
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
                    Text('Catat Hutang / Piutang', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Jenis Transaksi'),
                  items: const [
                    DropdownMenuItem(value: 'hutang_pinjam', child: Text('Hutang Baru (Pinjam ke Pihak Luar)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'hutang_bayar', child: Text('Bayar Hutang (Pelunasan ke Pihak Luar)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'piutang_pinjam', child: Text('Piutang Baru (Pinjamkan ke Pihak Lain)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'piutang_bayar', child: Text('Terima Piutang (Pihak Lain Membayar)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => type = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: partyController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pihak / Toko / Person',
                    hintText: 'Misal: Toko Hidayah / Kak Affan',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal (Rp)',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Tambahan',
                    hintText: 'Misal: Talangan belanja keramik',
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
                      onTap: () async {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0 || partyController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);

                        final success = await widget.apiService.createDebt(
                          categoryId: widget.selectedCategoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : 1),
                          type: type,
                          partyName: partyController.text.trim(),
                          amount: amount,
                          description: descController.text.trim(),
                        );

                        if (!mounted) return;
                        if (success) {
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Text('Transaksi hutang/piutang berhasil disimpan!'),
                            ),
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'Simpan Transaksi',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Hutang & Piutang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Catat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        onPressed: _showAddDebtDialog,
      ),
      body: Column(
        children: [
          // Modern Segmented Tab Bar
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
                Tab(text: 'Rekap Pihak'),
                Tab(text: 'Riwayat Transaksi'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Tab Rekap
                      RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Summary Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.expenseBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.expense.withValues(alpha: 0.15)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Hutang Pos', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(
                                            Formatters.formatCurrency(_totalHutang),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: AppTheme.expense,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.incomeBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.income.withValues(alpha: 0.15)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Piutang Pos', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(
                                            Formatters.formatCurrency(_totalPiutang),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: AppTheme.income,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Hutang List
                              Text(
                                'Kewajiban Hutang ke Pihak Luar',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
                              ),
                              const SizedBox(height: 10),
                              if (_hutangList.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                  child: Text('Tidak ada hutang aktif', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12)),
                                )
                              else
                                ..._hutangList.map((h) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                        boxShadow: AppTheme.cardShadow,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(h.partyName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Pinjam: ${Formatters.formatCurrency(h.totalPinjam)} • Bayar: ${Formatters.formatCurrency(h.totalBayar)}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            Formatters.formatCurrency(h.saldo),
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.expense),
                                          ),
                                        ],
                                      ),
                                    )),

                              const SizedBox(height: 24),

                              // Piutang List
                              Text(
                                'Daftar Piutang di Pihak Luar',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
                              ),
                              const SizedBox(height: 10),
                              if (_piutangList.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                  child: Text('Tidak ada piutang aktif', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12)),
                                )
                              else
                                ..._piutangList.map((p) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                        boxShadow: AppTheme.cardShadow,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p.partyName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Dipinjam: ${Formatters.formatCurrency(p.totalPinjam)} • Dibayar: ${Formatters.formatCurrency(p.totalBayar)}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            Formatters.formatCurrency(p.saldo),
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.income),
                                          ),
                                        ],
                                      ),
                                    )),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // 2. Tab Riwayat
                      _transactions.isEmpty
                          ? Center(
                              child: Text('Belum ada transaksi hutang/piutang',
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
                                  final isHutang = tx.isHutang;

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
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isHutang ? AppTheme.expenseBg : AppTheme.incomeBg,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            isHutang ? Icons.money_off_rounded : Icons.attach_money_rounded,
                                            color: isHutang ? AppTheme.expense : AppTheme.income,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.partyName,
                                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${tx.type.replaceAll('_', ' ').toUpperCase()} • ${tx.description ?? "-"}',
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
                                              Formatters.formatCurrency(tx.amount),
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain),
                                            ),
                                            Text(tx.tanggal, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight)),
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
          ),
        ],
      ),
    );
  }
}
